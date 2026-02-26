use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
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
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PromptSession {
    pub session_id: String,
    pub prompt_text: String,
    pub timestamp: String,
    pub associated_commit_hashes: Vec<String>,
    pub similarity_score: f32,
    pub scope_match: f32,
    pub intent: Option<String>,
}
