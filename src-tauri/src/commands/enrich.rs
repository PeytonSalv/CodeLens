use crate::types::ScanProgress;

#[tauri::command]
pub async fn enrich_features(project_id: String) -> Result<ScanProgress, String> {
    // TODO: Run Claude API enrichment on preprocessed data
    Ok(ScanProgress {
        stage: "pending".to_string(),
        progress: 0.0,
        message: format!("Ready to enrich project: {}", project_id),
    })
}
