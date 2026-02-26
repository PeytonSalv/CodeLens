use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};

use serde_json::Value;

use crate::types::{PromptSession, TokenUsage};

/// Find the Claude Code project directory for a given repo path.
/// Claude Code encodes paths by replacing `/` with `-`, e.g.:
///   /Users/me/project → -Users-me-project
fn find_claude_project_dir(repo_path: &str) -> Option<PathBuf> {
    let home = dirs::home_dir()?;
    let claude_projects = home.join(".claude").join("projects");

    if !claude_projects.exists() {
        return None;
    }

    // Encode the repo path the way Claude Code does: replace / with -
    let encoded = repo_path.replace('/', "-");

    let project_dir = claude_projects.join(&encoded);
    if project_dir.exists() {
        return Some(project_dir);
    }

    // Also try without trailing slash variations
    let trimmed = repo_path.trim_end_matches('/');
    let encoded_trimmed = trimmed.replace('/', "-");
    let project_dir_trimmed = claude_projects.join(&encoded_trimmed);
    if project_dir_trimmed.exists() {
        return Some(project_dir_trimmed);
    }

    None
}

/// Parse all Claude Code session JSONL files for a given repo path.
/// Returns a list of PromptSession — one per user prompt found.
pub fn parse_sessions_for_repo(repo_path: &str) -> Vec<PromptSession> {
    let project_dir = match find_claude_project_dir(repo_path) {
        Some(d) => d,
        None => {
            log::info!(
                "No Claude Code project directory found for: {}",
                repo_path
            );
            return vec![];
        }
    };

    let mut all_sessions: Vec<PromptSession> = Vec::new();

    // Read all .jsonl files in the project directory
    let entries = match fs::read_dir(&project_dir) {
        Ok(e) => e,
        Err(_) => return vec![],
    };

    for entry in entries.flatten() {
        let path = entry.path();
        if path.extension().and_then(|e| e.to_str()) == Some("jsonl") {
            let session_id = path
                .file_stem()
                .and_then(|s| s.to_str())
                .unwrap_or("unknown")
                .to_string();

            let mut sessions = parse_session_file(&path, &session_id);
            all_sessions.append(&mut sessions);
        }
    }

    // Sort by timestamp (newest first)
    all_sessions.sort_by(|a, b| b.timestamp.cmp(&a.timestamp));
    all_sessions
}

/// Parse a single JSONL session file into PromptSession entries.
/// Each user prompt becomes one PromptSession, accumulating all tool calls
/// and file touches that happen between it and the next user prompt.
fn parse_session_file(path: &Path, session_id: &str) -> Vec<PromptSession> {
    let content = match fs::read_to_string(path) {
        Ok(c) => c,
        Err(_) => return vec![],
    };

    let mut sessions: Vec<PromptSession> = Vec::new();
    let mut current_prompt: Option<PromptBuilder> = None;

    for line in content.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }

        let value: Value = match serde_json::from_str(line) {
            Ok(v) => v,
            Err(_) => continue,
        };

        let msg_type = value.get("type").and_then(|t| t.as_str()).unwrap_or("");

        match msg_type {
            "user" => {
                let message = match value.get("message") {
                    Some(m) => m,
                    None => continue,
                };

                let content = message.get("content");
                let timestamp = value
                    .get("timestamp")
                    .and_then(|t| t.as_str())
                    .unwrap_or("")
                    .to_string();

                // Determine if this is a real user prompt or a tool result
                if let Some(content_val) = content {
                    if content_val.is_string() {
                        // Real user prompt — finalize previous prompt and start a new one
                        if let Some(builder) = current_prompt.take() {
                            sessions.push(builder.build(session_id));
                        }

                        let prompt_text = content_val.as_str().unwrap_or("").to_string();

                        // Skip empty prompts
                        if prompt_text.trim().is_empty() {
                            continue;
                        }

                        current_prompt = Some(PromptBuilder {
                            prompt_text,
                            timestamp,
                            time_end: None,
                            files_touched: HashSet::new(),
                            files_written: HashSet::new(),
                            tool_call_count: 0,
                            model: None,
                            input_tokens: 0,
                            output_tokens: 0,
                            cache_read_tokens: 0,
                        });
                    } else if content_val.is_array() {
                        // Check if it's a user prompt with array content (image blocks, etc.)
                        // vs a tool result
                        let arr = content_val.as_array().unwrap();
                        let is_tool_result = arr
                            .iter()
                            .any(|item| item.get("type").and_then(|t| t.as_str()) == Some("tool_result"));

                        if !is_tool_result {
                            // This is a user prompt with structured content (e.g., with images)
                            // Extract text from text blocks
                            let prompt_text: String = arr
                                .iter()
                                .filter_map(|item| {
                                    if item.get("type").and_then(|t| t.as_str()) == Some("text") {
                                        item.get("text").and_then(|t| t.as_str())
                                    } else {
                                        None
                                    }
                                })
                                .collect::<Vec<&str>>()
                                .join("\n");

                            if !prompt_text.trim().is_empty() {
                                if let Some(builder) = current_prompt.take() {
                                    sessions.push(builder.build(session_id));
                                }

                                current_prompt = Some(PromptBuilder {
                                    prompt_text,
                                    timestamp: timestamp.clone(),
                                    time_end: None,
                                    files_touched: HashSet::new(),
                                    files_written: HashSet::new(),
                                    tool_call_count: 0,
                                    model: None,
                                    input_tokens: 0,
                                    output_tokens: 0,
                                    cache_read_tokens: 0,
                                });
                            }
                        }
                        // tool_result lines: just update time_end
                        if let Some(ref mut builder) = current_prompt {
                            if !timestamp.is_empty() {
                                builder.time_end = Some(timestamp);
                            }
                        }
                    }
                }
            }
            "assistant" => {
                if let Some(ref mut builder) = current_prompt {
                    let message = match value.get("message") {
                        Some(m) => m,
                        None => continue,
                    };

                    let timestamp = value
                        .get("timestamp")
                        .and_then(|t| t.as_str())
                        .unwrap_or("")
                        .to_string();

                    if !timestamp.is_empty() {
                        builder.time_end = Some(timestamp);
                    }

                    // Extract model
                    if builder.model.is_none() {
                        if let Some(model) = message.get("model").and_then(|m| m.as_str()) {
                            builder.model = Some(model.to_string());
                        }
                    }

                    // Extract token usage
                    if let Some(usage) = message.get("usage") {
                        builder.input_tokens += usage
                            .get("input_tokens")
                            .and_then(|v| v.as_u64())
                            .unwrap_or(0);
                        builder.output_tokens += usage
                            .get("output_tokens")
                            .and_then(|v| v.as_u64())
                            .unwrap_or(0);
                        builder.cache_read_tokens += usage
                            .get("cache_read_input_tokens")
                            .and_then(|v| v.as_u64())
                            .unwrap_or(0);
                    }

                    // Extract tool calls from content array
                    if let Some(content_arr) = message.get("content").and_then(|c| c.as_array()) {
                        for block in content_arr {
                            if block.get("type").and_then(|t| t.as_str()) != Some("tool_use") {
                                continue;
                            }

                            builder.tool_call_count += 1;

                            let tool_name =
                                block.get("name").and_then(|n| n.as_str()).unwrap_or("");
                            let input = block.get("input");

                            match tool_name {
                                "Write" => {
                                    if let Some(fp) =
                                        input.and_then(|i| i.get("file_path")).and_then(|p| p.as_str())
                                    {
                                        builder.files_written.insert(fp.to_string());
                                        builder.files_touched.insert(fp.to_string());
                                    }
                                }
                                "Edit" => {
                                    if let Some(fp) =
                                        input.and_then(|i| i.get("file_path")).and_then(|p| p.as_str())
                                    {
                                        builder.files_written.insert(fp.to_string());
                                        builder.files_touched.insert(fp.to_string());
                                    }
                                }
                                "Read" => {
                                    if let Some(fp) =
                                        input.and_then(|i| i.get("file_path")).and_then(|p| p.as_str())
                                    {
                                        builder.files_touched.insert(fp.to_string());
                                    }
                                }
                                "NotebookEdit" => {
                                    if let Some(fp) = input
                                        .and_then(|i| i.get("notebook_path"))
                                        .and_then(|p| p.as_str())
                                    {
                                        builder.files_written.insert(fp.to_string());
                                        builder.files_touched.insert(fp.to_string());
                                    }
                                }
                                "Bash" => {
                                    // Track bash commands but they don't map to specific files
                                    // Could parse command for file paths in the future
                                }
                                "Glob" | "Grep" => {
                                    // Search tools — tracked as tool calls but no specific file touch
                                }
                                _ => {}
                            }
                        }
                    }
                }
            }
            _ => {
                // file-history-snapshot, progress, etc. — skip
            }
        }
    }

    // Finalize last prompt
    if let Some(builder) = current_prompt.take() {
        sessions.push(builder.build(session_id));
    }

    sessions
}

/// Builder to accumulate data for a single prompt session
struct PromptBuilder {
    prompt_text: String,
    timestamp: String,
    time_end: Option<String>,
    files_touched: HashSet<String>,
    files_written: HashSet<String>,
    tool_call_count: u32,
    model: Option<String>,
    input_tokens: u64,
    output_tokens: u64,
    cache_read_tokens: u64,
}

impl PromptBuilder {
    fn build(self, session_id: &str) -> PromptSession {
        let mut files_touched: Vec<String> = self.files_touched.into_iter().collect();
        files_touched.sort();
        let mut files_written: Vec<String> = self.files_written.into_iter().collect();
        files_written.sort();

        PromptSession {
            session_id: session_id.to_string(),
            prompt_text: self.prompt_text,
            timestamp: self.timestamp,
            associated_commit_hashes: vec![], // populated during correlation
            associated_feature_ids: vec![],   // populated during feature linking
            similarity_score: 0.0,
            scope_match: 0.0,
            intent: None,
            files_touched,
            files_written,
            tool_call_count: self.tool_call_count,
            model: self.model,
            token_usage: TokenUsage {
                input_tokens: self.input_tokens,
                output_tokens: self.output_tokens,
                cache_read_tokens: self.cache_read_tokens,
            },
            time_end: self.time_end,
        }
    }
}

/// Tauri command: parse Claude Code sessions for a repo and return prompt sessions.
#[tauri::command]
pub async fn get_sessions(path: String) -> Result<Vec<PromptSession>, String> {
    Ok(parse_sessions_for_repo(&path))
}

/// Tauri command: delete all Claude Code session JSONL files for a repo.
#[tauri::command]
pub async fn delete_sessions(path: String) -> Result<u32, String> {
    let project_dir = match find_claude_project_dir(&path) {
        Some(d) => d,
        None => return Ok(0),
    };

    let entries = match fs::read_dir(&project_dir) {
        Ok(e) => e,
        Err(_) => return Ok(0),
    };

    let mut deleted = 0u32;
    for entry in entries.flatten() {
        let entry_path = entry.path();
        if entry_path.extension().and_then(|e| e.to_str()) == Some("jsonl") {
            if fs::remove_file(&entry_path).is_ok() {
                deleted += 1;
            }
            // Also remove the corresponding session directory if it exists
            let session_dir = entry_path.with_extension("");
            if session_dir.is_dir() {
                let _ = fs::remove_dir_all(&session_dir);
            }
        }
    }

    Ok(deleted)
}
