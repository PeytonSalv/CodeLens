use reqwest::Client;

use super::types::{Message, MessageRequest, MessageResponse};

const API_URL: &str = "https://api.anthropic.com/v1/messages";
const API_VERSION: &str = "2023-06-01";

pub struct ClaudeClient {
    client: Client,
    api_key: String,
    model: String,
}

impl ClaudeClient {
    pub fn new(api_key: String, model: String) -> Self {
        Self {
            client: Client::new(),
            api_key,
            model,
        }
    }

    pub async fn send_message(
        &self,
        system: &str,
        user_message: &str,
        max_tokens: u32,
    ) -> Result<String, String> {
        let request = MessageRequest {
            model: self.model.clone(),
            max_tokens,
            system: system.to_string(),
            messages: vec![Message {
                role: "user".to_string(),
                content: user_message.to_string(),
            }],
        };

        let response = self
            .client
            .post(API_URL)
            .header("x-api-key", &self.api_key)
            .header("anthropic-version", API_VERSION)
            .header("content-type", "application/json")
            .json(&request)
            .send()
            .await
            .map_err(|e| format!("Request failed: {}", e))?;

        if !response.status().is_success() {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            return Err(format!("API error {}: {}", status, body));
        }

        let msg: MessageResponse = response
            .json()
            .await
            .map_err(|e| format!("Parse error: {}", e))?;

        msg.content
            .first()
            .and_then(|block| block.text.clone())
            .ok_or_else(|| "Empty response".to_string())
    }
}
