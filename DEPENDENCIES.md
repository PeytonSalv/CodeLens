# CodeLens — Dependencies

Complete list of all dependencies required to build and run CodeLens.

---

## System-Level Dependencies

| Dependency          | Version   | Purpose                                  | Install                                            |
| ------------------- | --------- | ---------------------------------------- | -------------------------------------------------- |
| Mojo                | Latest    | Preprocessing engine language            | `curl -ssL https://magic.modular.com \| bash && modular install mojo` |
| MAX Engine          | Latest    | Local ML inference runtime               | `modular install max`                              |
| Rust                | 1.75+     | Tauri backend                            | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| Node.js             | 20+       | React frontend tooling                   | `nvm install 20`                                   |
| Git                 | 2.x       | Repository analysis (must be on PATH)    | Pre-installed on most systems                      |

### macOS Only

| Dependency          | Purpose                        | Install                    |
| ------------------- | ------------------------------ | -------------------------- |
| Xcode Command Line Tools | C/C++ compiler, system headers | `xcode-select --install` |

### Linux Only

| Dependency            | Purpose                    | Install                                                                     |
| --------------------- | -------------------------- | --------------------------------------------------------------------------- |
| libwebkit2gtk-4.1-dev | Tauri webview              | `sudo apt install libwebkit2gtk-4.1-dev`                                    |
| libappindicator3-dev  | System tray support        | `sudo apt install libappindicator3-dev`                                     |
| librsvg2-dev          | SVG rendering for icons    | `sudo apt install librsvg2-dev`                                             |
| patchelf              | Binary patching for builds | `sudo apt install patchelf`                                                 |

---

## Rust Crates (src-tauri/Cargo.toml)

| Crate              | Purpose                                        |
| ------------------- | ---------------------------------------------- |
| `tauri`             | Desktop application framework (v2.x)          |
| `tauri-build`       | Tauri build scripts                            |
| `serde`             | Serialization/deserialization                  |
| `serde_json`        | JSON parsing and generation                    |
| `reqwest`           | HTTP client for Claude API calls               |
| `tokio`             | Async runtime                                  |
| `rusqlite`          | SQLite database for caching                    |
| `chrono`            | Date/time handling                             |
| `uuid`              | Unique ID generation for projects              |
| `thiserror`         | Error type definitions                         |
| `log`               | Logging facade                                 |
| `env_logger`        | Logging implementation                         |
| `dotenv`            | Environment variable loading                   |

---

## Node.js Packages (package.json)

### Runtime Dependencies

| Package                    | Purpose                                    |
| -------------------------- | ------------------------------------------ |
| `react`                    | UI framework                               |
| `react-dom`                | React DOM rendering                        |
| `react-router-dom`         | Client-side routing                        |
| `@tauri-apps/api`          | Tauri frontend API (invoke, events, etc.)  |
| `@tauri-apps/plugin-shell` | Shell command integration                  |
| `@tauri-apps/plugin-dialog`| Native file/folder picker dialogs          |
| `@tauri-apps/plugin-fs`    | File system access                         |
| `zustand`                  | State management                           |
| `d3`                       | Data-driven visualizations (timeline, graphs) |
| `recharts`                 | Chart components (bar, pie, line charts)   |
| `framer-motion`            | Animations and transitions                 |
| `react-syntax-highlighter` | Syntax-highlighted code blocks             |
| `diff2html`                | Diff rendering (side-by-side view)         |
| `date-fns`                 | Date formatting and manipulation           |
| `clsx`                     | Conditional CSS class composition          |

### Dev Dependencies

| Package                       | Purpose                                 |
| ----------------------------- | --------------------------------------- |
| `typescript`                  | Type checking                           |
| `vite`                        | Build tool and dev server               |
| `@vitejs/plugin-react`        | React support for Vite                  |
| `tailwindcss`                 | Utility-first CSS framework             |
| `postcss`                     | CSS processing                          |
| `autoprefixer`                | CSS vendor prefixing                    |
| `@types/react`                | React type definitions                  |
| `@types/react-dom`            | React DOM type definitions              |
| `@types/d3`                   | D3 type definitions                     |
| `eslint`                      | Code linting                            |
| `eslint-plugin-react-hooks`   | React hooks linting rules               |
| `@tauri-apps/cli`             | Tauri CLI for development               |

---

## ML Models (mojo-engine/src/models/)

Downloaded via `mojo-engine/scripts/download_models.sh`.

| Model                          | Format | Size    | Purpose                                    |
| ------------------------------ | ------ | ------- | ------------------------------------------ |
| `microsoft/codebert-base`      | ONNX   | ~450 MB | Code embedding generation (768-dim vectors)|
| Change type classifier         | ONNX   | ~250 MB | Commit change type classification          |

---

## External Services

| Service          | Required | Purpose                                         | Notes                              |
| ---------------- | -------- | ----------------------------------------------- | ---------------------------------- |
| Claude API       | Optional | Feature narrative generation, intent extraction  | User provides their own API key    |

The app works offline for all preprocessing and ML tasks. Claude API is only needed for semantic enrichment (narratives, intent extraction, cross-feature connections).

---

## Full Install (Quick Reference)

```bash
# System tools
curl -ssL https://magic.modular.com | bash
modular install mojo
modular install max
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
nvm install 20
cargo install tauri-cli

# macOS
xcode-select --install

# Linux
sudo apt install -y libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev patchelf

# Project
npm install
./mojo-engine/scripts/download_models.sh
cd mojo-engine && mojo build src/main.mojo -o build/codelens-engine && cd ..
```
