use std::io::{BufRead, BufReader};
use std::process::{Command, Stdio};

use crate::types::ScanProgress;

pub fn run_mojo_engine(
    repo_path: &str,
    output_path: &str,
    models_dir: &str,
    on_progress: impl Fn(ScanProgress),
) -> Result<(), String> {
    let mut child = Command::new("./mojo-engine/build/codelens-engine")
        .arg("--repo")
        .arg(repo_path)
        .arg("--output")
        .arg(output_path)
        .arg("--models-dir")
        .arg(models_dir)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to start Mojo engine: {}", e))?;

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
