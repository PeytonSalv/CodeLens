use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommitData {
    pub hash: String,
    pub author_name: String,
    pub author_email: String,
    pub timestamp: String,
    pub subject: String,
    pub body: String,
    pub is_claude_code: bool,
    pub session_id: Option<String>,
    pub change_type: String,
    pub change_type_confidence: f32,
    pub cluster_id: i32,
    pub files_changed: Vec<FileChange>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileChange {
    pub path: String,
    pub lines_added: u32,
    pub lines_removed: u32,
    pub functions: Vec<FunctionChange>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionChange {
    pub name: String,
    pub lines_added: u32,
    pub lines_removed: u32,
    pub diff_text: String,
}
