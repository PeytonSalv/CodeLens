use std::fs;
use std::path::Path;

use crate::types::ProjectData;

pub fn parse_preprocessed_output(path: &Path) -> Result<ProjectData, String> {
    let content =
        fs::read_to_string(path).map_err(|e| format!("Failed to read output file: {}", e))?;

    serde_json::from_str(&content).map_err(|e| format!("Failed to parse JSON output: {}", e))
}
