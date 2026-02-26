use rusqlite::params;

use super::db::Database;

impl Database {
    pub fn cache_get(&self, key: &str) -> Option<String> {
        self.conn()
            .query_row(
                "SELECT value FROM cache WHERE key = ?1",
                params![key],
                |row| row.get(0),
            )
            .ok()
    }

    pub fn cache_set(&self, key: &str, value: &str) -> Result<(), String> {
        self.conn()
            .execute(
                "INSERT OR REPLACE INTO cache (key, value, created_at) VALUES (?1, ?2, datetime('now'))",
                params![key, value],
            )
            .map_err(|e| format!("Cache write failed: {}", e))?;
        Ok(())
    }
}
