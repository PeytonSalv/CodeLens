mod commands;
mod claude;
mod mojo_bridge;
mod storage;
mod types;

use commands::{
    delete_sessions, enrich_features, export_report, get_feature_detail, get_function_history,
    get_project_data, get_sessions, list_projects, scan_repository, search, update_settings,
};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info"))
        .init();

    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            scan_repository,
            enrich_features,
            get_project_data,
            get_sessions,
            delete_sessions,
            list_projects,
            get_feature_detail,
            search,
            get_function_history,
            update_settings,
            export_report,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
