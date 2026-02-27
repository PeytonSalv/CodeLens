use std::collections::HashMap;

use crate::claude::client::ClaudeClient;
use crate::claude::prompts::FEATURE_NARRATIVE_SYSTEM;
use crate::types::FeatureCluster;

/// Response from Claude API for feature enrichment.
#[derive(Debug, serde::Deserialize)]
pub struct FeatureEnrichment {
    pub title: String,
    pub narrative: String,
    pub key_decisions: Vec<String>,
}

/// Enrich a single feature cluster using Claude API.
pub async fn enrich_feature(
    client: &ClaudeClient,
    feature: &FeatureCluster,
    commit_details: &str,
) -> Result<FeatureEnrichment, String> {
    let user_message = format!(
        "Feature #{} — {} commits, {} lines added, {} lines removed\n\
         Time range: {} to {}\n\
         Primary files: {}\n\
         Auto-label: {}\n\n\
         Commit details:\n{}",
        feature.cluster_id,
        feature.commit_hashes.len(),
        feature.total_lines_added,
        feature.total_lines_removed,
        feature.time_start,
        feature.time_end,
        feature.primary_files.join(", "),
        feature.auto_label,
        commit_details,
    );

    let response = client
        .send_message(FEATURE_NARRATIVE_SYSTEM, &user_message, 1024)
        .await?;

    // Parse JSON response from Claude
    serde_json::from_str::<FeatureEnrichment>(&response).map_err(|e| {
        // If JSON parsing fails, try to extract from markdown code block
        if let Some(json_start) = response.find('{') {
            if let Some(json_end) = response.rfind('}') {
                let json_str = &response[json_start..=json_end];
                return serde_json::from_str::<FeatureEnrichment>(json_str)
                    .map_err(|e2| format!("Failed to parse enrichment response: {}", e2))
                    .err()
                    .unwrap_or_else(|| format!("Parse error: {}", e));
            }
        }
        format!("Failed to parse enrichment response: {}", e)
    })
}

/// Enrich multiple features with rate limiting (max concurrent calls).
pub async fn enrich_features_batch(
    client: &ClaudeClient,
    features: &mut [FeatureCluster],
    commit_subjects: &HashMap<String, String>,
    max_concurrent: usize,
) -> Result<u32, String> {
    use tokio::sync::Semaphore;
    use std::sync::Arc;

    let semaphore = Arc::new(Semaphore::new(max_concurrent));
    let mut enriched_count: u32 = 0;

    // Process features sequentially with semaphore for rate limiting
    for feature in features.iter_mut() {
        // Skip already enriched features
        if feature.title.is_some() {
            continue;
        }

        let _permit = semaphore
            .acquire()
            .await
            .map_err(|e| format!("Semaphore error: {}", e))?;

        // Build commit details string
        let mut details = String::new();
        for hash in &feature.commit_hashes {
            if let Some(subject) = commit_subjects.get(hash) {
                details.push_str(&format!("- {} {}\n", &hash[..7.min(hash.len())], subject));
            }
        }

        match enrich_feature(client, feature, &details).await {
            Ok(enrichment) => {
                feature.title = Some(enrichment.title);
                feature.narrative = Some(enrichment.narrative);
                feature.key_decisions = enrichment.key_decisions;
                enriched_count += 1;
            }
            Err(e) => {
                log::warn!(
                    "Failed to enrich feature #{}: {}",
                    feature.cluster_id,
                    e
                );
            }
        }
    }

    Ok(enriched_count)
}
