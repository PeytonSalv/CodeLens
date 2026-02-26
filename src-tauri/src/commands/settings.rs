use crate::types::AppSettings;

#[tauri::command]
pub async fn update_settings(settings: AppSettings) -> Result<(), String> {
    // TODO: Persist settings to disk
    log::info!("Settings updated: model={}", settings.claude_model);
    Ok(())
}
