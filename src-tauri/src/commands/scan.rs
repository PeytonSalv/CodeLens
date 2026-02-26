use crate::types::ScanProgress;

#[tauri::command]
pub async fn scan_repository(path: String) -> Result<ScanProgress, String> {
    // TODO: Invoke Mojo engine binary on the target repo
    Ok(ScanProgress {
        stage: "pending".to_string(),
        progress: 0.0,
        message: format!("Ready to scan: {}", path),
    })
}
