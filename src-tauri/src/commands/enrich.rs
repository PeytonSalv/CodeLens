use std::collections::HashMap;

use crate::claude::client::ClaudeClient;
use crate::types::{ProjectData, ScanProgress};

use super::claude_api::enrich_features_batch;

/// Enrich features in a ProjectData with Claude API-generated titles, narratives,
/// and key decisions. Requires ANTHROPIC_API_KEY environment variable.
#[tauri::command]
pub async fn enrich_features(project_id: String) -> Result<ScanProgress, String> {
    // Check for API key
    let api_key = std::env::var("ANTHROPIC_API_KEY").map_err(|_| {
        "ANTHROPIC_API_KEY not set. Set it to enable Claude API enrichment.".to_string()
    })?;

    let model =
        std::env::var("CLAUDE_MODEL").unwrap_or_else(|_| "claude-sonnet-4-5-20250929".to_string());

    let _client = ClaudeClient::new(api_key, model);

    // TODO: Load project data from storage by project_id
    // For now, return a pending status indicating enrichment is ready
    Ok(ScanProgress {
        stage: "enrichment_ready".to_string(),
        progress: 0.0,
        message: format!(
            "Enrichment ready for project: {}. Call scan_repository with enrichment enabled.",
            project_id
        ),
    })
}

/// Enrich features within a scan pipeline. Called by scan_repository when
/// Claude API key is available.
pub async fn enrich_project_features(project: &mut ProjectData) -> Result<u32, String> {
    let api_key = match std::env::var("ANTHROPIC_API_KEY") {
        Ok(key) if !key.is_empty() => key,
        _ => return Ok(0), // No API key — skip enrichment silently
    };

    let model =
        std::env::var("CLAUDE_MODEL").unwrap_or_else(|_| "claude-sonnet-4-5-20250929".to_string());

    let max_concurrent: usize = std::env::var("CLAUDE_MAX_CONCURRENT")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(3);

    let client = ClaudeClient::new(api_key, model);

    // Build commit subject lookup
    let commit_subjects: HashMap<String, String> = project
        .commits
        .iter()
        .map(|c| (c.hash.clone(), c.subject.clone()))
        .collect();

    enrich_features_batch(
        &client,
        &mut project.features,
        &commit_subjects,
        max_concurrent,
    )
    .await
}
