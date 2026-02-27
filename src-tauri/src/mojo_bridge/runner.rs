use std::io::{BufRead, BufReader};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::thread;

use tauri::Manager;

use crate::types::ScanProgress;

/// Resolve the path to the Mojo engine binary.
///
/// Lookup order:
/// 1. Tauri sidecar: <resource_dir>/binaries/codelens-engine
/// 2. Development: ./mojo-engine/build/codelens-engine
/// 3. Relative to executable
fn resolve_engine_path(app_handle: Option<&tauri::AppHandle>) -> Option<PathBuf> {
    // 1. Try Tauri resource directory (production sidecar)
    if let Some(handle) = app_handle {
        let path_resolver = handle.path();
        if let Ok(resource_dir) = path_resolver.resource_dir() {
            let sidecar_path = resource_dir.join("binaries").join("codelens-engine");
            if sidecar_path.exists() {
                return Some(sidecar_path);
            }

            // Also check with platform-target suffix (Tauri sidecar convention)
            #[cfg(all(target_os = "macos", target_arch = "aarch64"))]
            let target = "aarch64-apple-darwin";
            #[cfg(all(target_os = "macos", target_arch = "x86_64"))]
            let target = "x86_64-apple-darwin";
            #[cfg(all(target_os = "linux", target_arch = "x86_64"))]
            let target = "x86_64-unknown-linux-gnu";
            #[cfg(not(any(
                all(target_os = "macos", target_arch = "aarch64"),
                all(target_os = "macos", target_arch = "x86_64"),
                all(target_os = "linux", target_arch = "x86_64"),
            )))]
            let target = "unknown";

            let suffixed = resource_dir
                .join("binaries")
                .join(format!("codelens-engine-{}", target));
            if suffixed.exists() {
                return Some(suffixed);
            }
        }
    }

    // 2. Development path
    let dev_path = PathBuf::from("./mojo-engine/build/codelens-engine");
    if dev_path.exists() {
        return Some(dev_path);
    }

    // 3. Relative to current executable
    if let Ok(exe_dir) = std::env::current_exe() {
        if let Some(parent) = exe_dir.parent() {
            let rel_path = parent.join("codelens-engine");
            if rel_path.exists() {
                return Some(rel_path);
            }
        }
    }

    None
}

/// Run the Mojo engine as a subprocess, streaming progress to the callback.
///
/// Falls back gracefully if the engine binary is not found.
pub fn run_mojo_engine(
    repo_path: &str,
    output_path: &str,
    models_dir: &str,
    verbose: bool,
    on_progress: impl Fn(ScanProgress),
    app_handle: Option<&tauri::AppHandle>,
) -> Result<(), String> {
    let engine_path = resolve_engine_path(app_handle).ok_or_else(|| {
        "Mojo engine binary not found. Falling back to Rust pipeline.".to_string()
    })?;

    let mut cmd = Command::new(&engine_path);
    cmd.arg("--repo")
        .arg(repo_path)
        .arg("--output")
        .arg(output_path)
        .arg("--models-dir")
        .arg(models_dir);

    if verbose {
        cmd.arg("--verbose");
    }

    let mut child = cmd
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to start Mojo engine at {:?}: {}", engine_path, e))?;

    // Spawn a thread to read stderr and forward to log::debug!
    if let Some(stderr) = child.stderr.take() {
        thread::spawn(move || {
            let reader = BufReader::new(stderr);
            for line in reader.lines().flatten() {
                log::debug!("{}", line);
            }
        });
    }

    if let Some(stdout) = child.stdout.take() {
        let reader = BufReader::new(stdout);
        for line in reader.lines() {
            if let Ok(line) = line {
                if let Ok(progress) = serde_json::from_str::<ScanProgress>(&line) {
                    on_progress(progress);
                }
            }
        }
    }

    let status = child
        .wait()
        .map_err(|e| format!("Mojo engine failed: {}", e))?;

    if !status.success() {
        return Err(format!("Mojo engine exited with status: {}", status));
    }

    Ok(())
}

/// Check if the Mojo engine binary is available.
pub fn is_engine_available(app_handle: Option<&tauri::AppHandle>) -> bool {
    resolve_engine_path(app_handle).is_some()
}
