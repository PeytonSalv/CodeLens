use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use super::{CommitData, FeatureCluster, PromptSession};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RepositoryInfo {
    pub path: String,
    pub name: String,
    pub total_commits: u32,
    pub date_range: DateRange,
    pub languages_detected: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DateRange {
    pub start: String,
    pub end: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProjectData {
    pub repository: RepositoryInfo,
    pub commits: Vec<CommitData>,
    pub features: Vec<FeatureCluster>,
    pub prompt_sessions: Vec<PromptSession>,
    pub analytics: Analytics,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WeekVelocity {
    pub week: String,
    pub features: u32,
    pub commits: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Analytics {
    pub total_features: u32,
    pub total_functions_modified: u32,
    pub total_prompts_detected: u32,
    pub claude_code_commit_percentage: f32,
    pub avg_prompt_similarity: f32,
    pub most_modified_files: Vec<String>,
    pub most_modified_functions: Vec<String>,
    pub change_type_totals: HashMap<String, u32>,
    pub velocity_by_week: Vec<WeekVelocity>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProjectSummary {
    pub id: String,
    pub name: String,
    pub path: String,
    pub last_scanned: String,
    pub total_commits: u32,
    pub total_features: u32,
    pub claude_code_percentage: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ScanProgress {
    pub stage: String,
    pub progress: f32,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SearchResults {
    pub commits: Vec<CommitData>,
    pub features: Vec<FeatureCluster>,
    pub prompts: Vec<PromptSession>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FunctionHistory {
    pub function_name: String,
    pub file_path: String,
    pub modifications: Vec<CommitData>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AppSettings {
    pub api_key: Option<String>,
    pub claude_model: String,
    pub max_concurrent_api_calls: u32,
    pub embedding_batch_size: u32,
    pub clustering_eps: f32,
    pub clustering_min_samples: u32,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            api_key: None,
            claude_model: "claude-sonnet-4-5-20250929".to_string(),
            max_concurrent_api_calls: 5,
            embedding_batch_size: 32,
            clustering_eps: 0.3,
            clustering_min_samples: 2,
        }
    }
}
