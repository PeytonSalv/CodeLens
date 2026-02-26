use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FeatureCluster {
    pub cluster_id: i32,
    pub title: Option<String>,
    pub auto_label: String,
    pub narrative: Option<String>,
    pub intent: Option<String>,
    pub key_decisions: Vec<String>,
    pub commit_hashes: Vec<String>,
    pub time_start: String,
    pub time_end: String,
    pub functions_touched: Vec<String>,
    pub total_lines_added: u32,
    pub total_lines_removed: u32,
    pub primary_files: Vec<String>,
    pub change_type_distribution: HashMap<String, u32>,
    pub dependencies: Vec<i32>,
    pub sub_features: Vec<SubFeature>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SubFeature {
    pub prompt_text: String,
    pub session_id: String,
    pub prompt_index: u32,
    pub timestamp: String,
    pub time_end: Option<String>,
    pub commit_hashes: Vec<String>,
    pub files_written: Vec<String>,
    pub lines_added: u32,
    pub lines_removed: u32,
    pub change_type: String,
    pub model: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PromptSession {
    pub session_id: String,
    pub prompt_text: String,
    pub timestamp: String,
    pub associated_commit_hashes: Vec<String>,
    pub associated_feature_ids: Vec<i32>,
    pub similarity_score: f32,
    pub scope_match: f32,
    pub intent: Option<String>,
    pub files_touched: Vec<String>,
    pub files_written: Vec<String>,
    pub tool_call_count: u32,
    pub model: Option<String>,
    pub token_usage: TokenUsage,
    pub time_end: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct TokenUsage {
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub cache_read_tokens: u64,
}
