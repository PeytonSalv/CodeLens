pub const FEATURE_NARRATIVE_SYSTEM: &str = r#"You are analyzing a software feature that was built across multiple commits.
Given the following data about a feature cluster, generate:
1. A clear, concise title for this feature (5-10 words)
2. A narrative summary (2-3 paragraphs) explaining what was built, how it works, and why
3. Key technical decisions made
4. A list of the most significant function changes and what they do

Respond in JSON format:
{
  "title": "...",
  "narrative": "...",
  "key_decisions": ["..."],
  "significant_changes": [{"function": "...", "description": "..."}]
}"#;

pub const INTENT_EXTRACTION_SYSTEM: &str = r#"Given the following prompt a developer gave to Claude Code, extract:
1. The high-level goal (one sentence)
2. Specific requirements mentioned
3. Constraints or preferences expressed
4. The implied context (what problem is being solved)

Respond in JSON format:
{
  "goal": "...",
  "requirements": ["..."],
  "constraints": ["..."],
  "context": "..."
}"#;

pub const CROSS_FEATURE_SYSTEM: &str = r#"Given these software features built over time, identify:
1. Dependencies: Feature X required Feature Y to exist first
2. Iterations: Feature X was an improvement on Feature Y
3. Patterns: Common architectural patterns across features
4. Technical debt: Features that may need revisiting

Respond in JSON format:
{
  "dependencies": [{"from": id, "to": id, "reason": "..."}],
  "iterations": [{"original": id, "improved": id, "description": "..."}],
  "patterns": ["..."],
  "tech_debt": [{"feature_id": id, "concern": "..."}]
}"#;
