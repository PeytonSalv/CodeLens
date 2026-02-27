# CodeLens — Claude Code Feature Timeline Visualizer

A desktop application that visualizes the features Claude Code has worked on across a repository. Shows a rich timeline of features, functions modified, logic changes, and the prompts that drove them. CodeLens reads Claude Code's local session logs in real-time — **you don't even need to commit** for CodeLens to know what you're building.

Unique: a hybrid Rust + Mojo architecture where Rust orchestrates and handles I/O, while Mojo + MAX Engine runs SIMD-accelerated ML inference (CodeBERT embeddings, DBSCAN clustering, semantic classification) locally on your machine.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Technology Stack](#technology-stack)
3. [Directory Structure](#directory-structure)
4. [Scanning Pipeline](#scanning-pipeline)
5. [Mojo ML Engine](#mojo-ml-engine)
6. [Claude API Enrichment](#claude-api-enrichment)
7. [Session Parsing](#session-parsing)
8. [Frontend Views](#frontend-views)
9. [Data Models](#data-models)
10. [Setup & Installation](#setup--installation)
11. [Build & Run](#build--run)
12. [Configuration](#configuration)
13. [Scripts](#scripts)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CodeLens Desktop App                            │
│                          (Tauri 2 + React 19)                           │
│                                                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ ┌───────┐ ┌──────┐ │
│  │ Timeline │ │ Features │ │ Prompts  │ │ Intent │ │Patterns│ │Analyt│ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └───┬────┘ └───┬───┘ └──┬───┘ │
│       └─────────────┴────────────┴───────────┴──────────┴────────┘     │
│                              │ Tauri IPC                                │
│                    ┌─────────┴──────────┐                               │
│                    │   Rust Backend     │                               │
│                    │   (Orchestrator)   │                               │
│                    └──┬──────────┬──────┘                               │
└───────────────────────┼──────────┼──────────────────────────────────────┘
                        │          │
         ┌──────────────┘          └──────────────┐
         │                                        │
┌────────┴────────┐  ┌───────────────┐  ┌────────┴─────────┐
│ Mojo ML Engine  │  │ Claude API    │  │ Claude Code Logs │
│ (Sidecar Binary)│  │ (Optional)    │  │ ~/.claude/       │
│                 │  │               │  │                  │
│ • CodeBERT ONNX│  │ • Narratives  │  │ • Session JSONL  │
│ • DBSCAN       │  │ • Titles      │  │ • Tool calls     │
│ • Classifier   │  │ • Decisions   │  │ • Prompt text    │
│ • Patterns     │  │               │  │ • File touches   │
│ • Intent       │  │               │  │ • Token usage    │
└─────────────────┘  └───────────────┘  └──────────────────┘
         │
┌────────┴────────┐
│ Git Repository  │
│                 │
│ • git log       │
│ • git diff-tree │
│ • Co-Author tags│
└─────────────────┘
```

### Data Flow

1. User opens a repository in CodeLens
2. Rust backend tries the **Mojo engine** first (compiled sidecar binary)
3. If Mojo engine unavailable, **falls back to pure-Rust pipeline** (heuristic-based)
4. Both paths produce `ProjectData` JSON (commits, features, analytics)
5. Rust augments with **Claude Code session parsing** (JSONL logs from `~/.claude/`)
6. Rust correlates **prompts to commits** (timestamp + file overlap + semantic similarity)
7. Optionally enriches features via **Claude API** (titles, narratives, key decisions)
8. Frontend renders 7 interactive views

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | React 19 + TypeScript | 7 interactive views |
| **State** | Zustand 5 | Lightweight store (project, timeline, settings) |
| **Styling** | Tailwind CSS 4.1 | Dark-mode-first UI |
| **Visualization** | Recharts + D3 | Charts, heatmaps, graphs |
| **Desktop** | Tauri 2 (Rust) | Native app shell, IPC, file system access |
| **Git Parsing** | Rust (`std::process::Command`) | `git log`, `git diff-tree` |
| **Session Parsing** | Rust (`serde_json`) | Claude Code JSONL logs |
| **ML Inference** | Mojo + MAX Engine | CodeBERT ONNX, SIMD-accelerated |
| **ML Algorithms** | Pure Mojo | DBSCAN, cosine similarity, classification |
| **Intent Analysis** | Mojo | Session reconstruction, gap analysis, re-prompt detection |
| **Pattern Detection** | Mojo | Temporal tracking, file couplings, developer profiles |
| **Semantic Enrichment** | Claude API (optional) | Feature narratives, intent extraction |
| **Storage** | SQLite (rusqlite) | Caching (planned) |

### Version Requirements

- **Mojo** 0.26.2+ with **MAX Engine** 26.2+ (for ML pipeline)
- **Rust** 1.75+
- **Node.js** 20+
- **Tauri CLI** 2.x
- **pixi** (for Mojo environment management)

---

## Directory Structure

```
CodeLens/
├── src/                               # React frontend
│   ├── App.tsx                        # Root: routes 7 views
│   ├── main.tsx                       # React entry point
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx            # 7-view nav (shortcuts 1-7)
│   │   │   ├── Header.tsx             # Search, settings
│   │   │   └── StatusBar.tsx          # Scan progress
│   │   ├── timeline/
│   │   │   └── Timeline.tsx           # Commit timeline with zoom
│   │   ├── features/
│   │   │   └── FeatureList.tsx        # Feature cards with sub-features
│   │   ├── functions/
│   │   │   └── FunctionTree.tsx       # File/function tree
│   │   ├── prompts/
│   │   │   └── PromptExplorer.tsx     # Prompt browser
│   │   ├── intent/
│   │   │   └── IntentDashboard.tsx    # Intent vs outcome analysis
│   │   ├── patterns/
│   │   │   ├── PatternDashboard.tsx   # Temporal heatmaps, file couplings
│   │   │   └── ProfileCard.tsx        # Developer profile summary
│   │   ├── analytics/
│   │   │   └── Dashboard.tsx          # 9 stat cards + charts
│   │   └── shared/
│   │       ├── CodeBlock.tsx, EmptyState.tsx, LoadingSpinner.tsx, SearchBar.tsx
│   ├── hooks/
│   │   ├── useProject.ts             # scanRepository, sessions
│   │   ├── useTimeline.ts            # Filtered commits
│   │   ├── useFeatures.ts            # Feature data
│   │   └── useTauriCommand.ts        # Generic IPC
│   ├── store/
│   │   ├── projectStore.ts           # Active project, scan state
│   │   ├── timelineStore.ts          # Zoom, filters, selection
│   │   └── settingsStore.ts          # API key, model
│   └── lib/
│       ├── types.ts                   # All TypeScript interfaces
│       ├── constants.ts               # Colors, labels, view keys
│       └── utils.ts                   # cn(), formatNumber(), truncate()
│
├── src-tauri/                         # Rust backend
│   ├── Cargo.toml                     # Rust deps
│   ├── tauri.conf.json                # Tauri config + sidecar
│   ├── src/
│   │   ├── main.rs                    # Entry point
│   │   ├── lib.rs                     # 11 Tauri commands registered
│   │   ├── commands/
│   │   │   ├── scan.rs                # Main pipeline (Mojo → fallback Rust)
│   │   │   ├── sessions.rs            # Claude Code JSONL parser
│   │   │   ├── enrich.rs              # Claude API enrichment
│   │   │   ├── claude_api.rs          # Claude API client logic
│   │   │   ├── project.rs             # Project management (TODO)
│   │   │   └── settings.rs            # App settings
│   │   ├── claude/
│   │   │   ├── client.rs              # HTTP client for Claude API
│   │   │   ├── prompts.rs             # System prompts (narrative, intent, cross-feature)
│   │   │   └── types.rs               # API request/response types
│   │   ├── mojo_bridge/
│   │   │   ├── runner.rs              # Spawn Mojo binary, stream progress
│   │   │   └── parser.rs              # Parse Mojo JSON output → ProjectData
│   │   ├── storage/
│   │   │   ├── db.rs                  # SQLite (TODO)
│   │   │   └── cache.rs               # Embedding cache (TODO)
│   │   └── types/
│   │       ├── commit.rs              # CommitData, FileChange, FunctionChange
│   │       ├── feature.rs             # FeatureCluster, SubFeature, PromptSession, IntentAnalysis
│   │       └── enriched.rs            # ProjectData, Analytics, DeveloperProfile
│
├── mojo-engine/                       # Mojo ML engine (26 source files)
│   ├── pixi.toml                      # Mojo 0.26.2 + MAX Engine deps
│   ├── src/
│   │   ├── main.mojo                  # CLI entry: 8-stage pipeline
│   │   ├── git_parser.mojo            # Git log parsing, classification, feature grouping
│   │   ├── diff_extractor.mojo        # git diff-tree → FileChange
│   │   ├── embeddings.mojo            # CodeBERT ONNX via MAX Engine (768-dim)
│   │   ├── clustering.mojo            # DBSCAN on cosine distance matrix
│   │   ├── classifier.mojo            # Linear head on embeddings → 7 change types
│   │   ├── similarity.mojo            # Prompt-to-commit semantic correlation
│   │   ├── prompt_embedder.mojo       # Embed prompt text via CodeBERT
│   │   ├── types/
│   │   │   ├── commit.mojo            # CommitData, FileChange, FunctionChange + JSON
│   │   │   ├── feature.mojo           # FeatureCluster, SubFeature + JSON
│   │   │   └── project.mojo           # ProjectData, Analytics, ScanProgress + JSON
│   │   ├── utils/
│   │   │   └── json_writer.mojo       # Write ProjectData to JSON file
│   │   ├── intent/                    # Phase 5: Intent verification
│   │   │   ├── session_reconstructor.mojo  # JSONL → ordered event timeline
│   │   │   ├── edit_delta.mojo        # Per-file edit tracking
│   │   │   ├── reprompt_detector.mojo # Detect re-prompts (similarity > 0.85)
│   │   │   ├── outcome_classifier.mojo # completed/partial/abandoned/reworked
│   │   │   ├── intent_embedder.mojo   # Intent vs outcome similarity
│   │   │   └── gap_analyzer.mojo      # Files mentioned but not touched
│   │   └── patterns/                  # Phase 6: Pattern detection
│   │       ├── temporal_tracker.mojo  # Hour/day distributions, peak hours
│   │       ├── pattern_detector.mojo  # File couplings, commit granularity
│   │       └── profile_generator.mojo # DeveloperProfile + claude_context.md
│   ├── tests/
│   │   └── test_git_parser.mojo       # Unit tests
│   └── scripts/
│       └── download_models.sh         # Download CodeBERT ONNX + classifier weights
│
├── scripts/
│   ├── build-mojo.sh                  # Compile Mojo engine via pixi
│   └── bundle.sh                      # Full release: Mojo build → sidecar copy → Tauri build
│
├── package.json                       # npm deps (React 19, Zustand 5, Tailwind 4.1, etc.)
├── vite.config.ts                     # Vite 7 with Tauri + Tailwind
├── tsconfig.json
└── .claude/settings.local.json        # Claude Code permission allowlist
```

---

## Scanning Pipeline

When you open a repository, `scan_repository` in `scan.rs` runs this pipeline:

### With Mojo Engine (ML-powered)

```
1. try_mojo_engine()
   ├── Spawn: ./mojo-engine/build/codelens-engine --repo <path> --output <tmp.json>
   ├── Stage: git_parser.parse_git_log()
   │   ├── git log --format=%H%x01%an%x01%ae%x01%aI%x01%s%x01%b%x00 --no-merges
   │   ├── classify_change_type() — keyword matching on subject
   │   └── detect Claude Code — Co-Authored-By markers
   ├── Stage: diff_extractor.extract_file_stats()
   │   └── git diff-tree --numstat per commit
   ├── Stage: group_into_features() — 4-hour time window clustering
   ├── Stage: embeddings (if models available)
   │   ├── Load CodeBERT ONNX via MAX Engine
   │   └── Generate 768-dim vector per commit
   ├── Stage: DBSCAN semantic clustering (replaces time-window)
   │   └── eps=0.3, min_samples=2 on cosine distance
   ├── Stage: ML classification (replaces keyword heuristic)
   │   └── Linear head on embeddings → 7 classes
   ├── Stage: prompt correlation (if sessions_dir provided)
   │   └── 0.4×semantic + 0.3×file + 0.2×time + 0.1×marker
   ├── Stage: intent analysis (session reconstruction, gap detection)
   ├── Stage: pattern detection (temporal, file couplings, profile)
   │   └── Writes developer_profile.json + claude_context.md
   └── Stage: write output JSON
2. Rust augments with Claude Code session data
   ├── parse_sessions_for_repo() — JSONL from ~/.claude/projects/
   ├── correlate_prompts_to_commits() — timestamp + file overlap
   └── link_prompts_to_features() — build SubFeature entries
3. Optional: enrich_project_features() via Claude API
```

### Without Mojo Engine (Rust fallback)

```
1. git log → parse commits → classify by keywords → detect Claude Code
2. git diff-tree → file stats per commit
3. group_into_features() — 4-hour time window
4. compute_analytics() — files, functions, velocity, change types
5. parse_sessions_for_repo() — JSONL from ~/.claude/
6. correlate_prompts_to_commits() — timestamp + file overlap
7. link_prompts_to_features() — build SubFeature entries
8. Optional: Claude API enrichment
```

The Rust fallback ensures the app always works even without Mojo/MAX installed.

---

## Mojo ML Engine

The Mojo engine is a compiled binary that runs as a Tauri sidecar. It communicates via JSON lines on stdout (progress) and a JSON output file (results).

### Pipeline Stages

| Stage | Module | What It Does |
|-------|--------|-------------|
| Parsing | `git_parser.mojo` | `git log` + `git diff-tree`, classify change types, detect Claude Code |
| Diff | `diff_extractor.mojo` | Populate FileChange with lines_added/removed per file per commit |
| Clustering | `git_parser.mojo` | 4-hour time-window feature grouping (heuristic baseline) |
| Embeddings | `embeddings.mojo` | Load CodeBERT ONNX via MAX Engine, generate 768-dim vectors |
| Semantic Clustering | `clustering.mojo` | DBSCAN on cosine distance — replaces time-window with semantic groups |
| Classification | `classifier.mojo` | Linear head on embeddings → 7 change types with confidence scores |
| Correlation | `similarity.mojo` | Prompt-to-commit scoring: 0.4 semantic + 0.3 file + 0.2 time + 0.1 marker |
| Intent | `intent/*.mojo` | Session reconstruction, re-prompt detection, outcome classification, gap analysis |
| Patterns | `patterns/*.mojo` | Temporal tracking, file couplings, developer profile generation |

### Graceful Fallback

Every ML stage has a fallback:
- **No CodeBERT model** → skip embeddings, use time-window clustering + keyword classification
- **No classifier weights** → use keyword heuristic (confidence = 0.7)
- **No sessions dir** → skip prompt correlation and intent analysis
- **Any exception** → log error, continue with heuristic results

### Progress Protocol

The engine emits JSON progress lines to stdout:

```json
{"stage": "parsing", "progress": 0.3, "message": "Parsed 150 commits"}
{"stage": "embeddings", "progress": 0.72, "message": "Generating CodeBERT embeddings..."}
{"stage": "complete", "progress": 1.0, "message": "Analysis complete. 150 commits, 12 features."}
```

The Rust bridge (`mojo_bridge/runner.rs`) streams these to the frontend via Tauri events.

---

## Claude API Enrichment

Optional. Requires `ANTHROPIC_API_KEY` environment variable.

For each feature cluster, sends commit details to Claude and receives:
- **Title**: 5-10 word feature name
- **Narrative**: 2-3 paragraph summary of what was built and why
- **Key Decisions**: List of significant technical choices

Implementation:
- `claude/client.rs` — HTTP client for Claude Messages API
- `claude/prompts.rs` — System prompts (feature narrative, intent extraction, cross-feature analysis)
- `commands/claude_api.rs` — Batch enrichment with semaphore rate limiting (default: 3 concurrent)
- `commands/enrich.rs` — Tauri command + integration into scan pipeline

Enrichment runs automatically at the end of `scan_repository` when the API key is set.

---

## Session Parsing

CodeLens reads Claude Code's native JSONL session logs from `~/.claude/projects/`.

### Location

```
~/.claude/projects/
├── -Users-peyton-Desktop-personal-CodeLens/    # Path-encoded project dir
│   ├── <session-uuid>.jsonl                     # One file per conversation
│   └── ...
```

### What's Extracted

| Data | Source in JSONL |
|------|----------------|
| Prompt text | `type: "user"` with string content |
| Files written | `tool_use` name="Write" or "Edit" → `input.file_path` |
| Files read | `tool_use` name="Read" → `input.file_path` |
| Tool call count | Count of all `tool_use` blocks |
| Timestamps | `timestamp` field on each message |
| Model | `message.model` on assistant turns |
| Token usage | `message.usage.{input_tokens, output_tokens, cache_read_input_tokens}` |

### Correlation Algorithm

```
For each Claude Code commit:
  score = 0.5 (timestamp in session window + 5min buffer)
        + 0.4 × (file name overlap fraction)
        + 0.1 (co-author marker present)

  if score ≥ 0.5: link commit to session
```

With ML models loaded, the formula becomes:
```
  score = 0.4 × cosine_similarity(prompt_embedding, diff_embedding)
        + 0.3 × file_overlap
        + 0.2 × timestamp_overlap
        + 0.1 × co_author_marker
```

---

## Frontend Views

7 views accessible via sidebar navigation (keyboard shortcuts 1-7):

### Timeline (1)
Vertical commit timeline with zoom levels (day/week/month/feature). Color-coded by change type. Claude Code commits show a badge. Filterable by author, date, type.

### Features (2)
Expandable feature cards. Each shows: auto-label, commit count, lines added/removed, primary files. Expands to show sub-features (one per prompt that contributed).

### Functions (3)
File and function tree view. Shows modification history per function with line counts.

### Prompts (4)
Browse all Claude Code prompt sessions. Shows prompt text, files written, tool call count, model, token usage. Linked to associated commits and features.

### Intent (5)
**New.** Shows each prompt's outcome classification:
- **Completed** (green): Files written, no re-prompt
- **Partial** (amber): Some tool calls but limited writes
- **Abandoned** (red): No tool calls or writes
- **Reworked** (blue): Files edited but user re-prompted

Stats: total prompts, completion rate, re-prompt count, avg tool calls. Expandable prompt list with files written/touched details.

### Patterns (6)
**New.** Developer behavior analysis:
- **Profile Card**: Languages, peak hours, commit granularity, Claude Code %, session count
- **Hour Heatmap**: 24-hour commit activity distribution
- **Day Chart**: Weekly commit distribution (Mon-Sun)
- **File Couplings**: Files frequently edited together (minimum 3 co-edits)

### Analytics (7)
Enhanced dashboard with 9 stat cards:
- Primary: Features, Functions Modified, Prompts Detected, Claude Code %, Avg Match %
- ML: Intent Completion, Re-prompt Rate, Patterns Found, ML Coverage
- Velocity chart (last 12 weeks)
- Change type distribution with color-coded bars
- Most modified files and functions

---

## Data Models

### Core Types (shared between Rust, Mojo, and TypeScript)

```typescript
// 7 change types
type ChangeType = "new_feature" | "bug_fix" | "refactor" | "performance"
                | "style" | "test" | "documentation"

interface Commit {
  hash, authorName, authorEmail, timestamp, subject, body: string
  isClaudeCode: boolean
  changeType: ChangeType
  changeTypeConfidence: number    // 0-1, higher with ML
  clusterId: number               // which feature this belongs to
  filesChanged: FileChange[]
}

interface Feature {
  clusterId: number
  title: string | null            // Claude API enriched
  autoLabel: string               // from first commit subject
  narrative: string | null        // Claude API enriched
  keyDecisions: string[]          // Claude API enriched
  commitHashes: string[]
  timeStart, timeEnd: string
  totalLinesAdded, totalLinesRemoved: number
  primaryFiles: string[]          // top 10 by frequency
  changeTypeDistribution: Record<ChangeType, number>
  subFeatures: SubFeature[]       // one per prompt that contributed
}

interface PromptSession {
  sessionId, promptText, timestamp: string
  associatedCommitHashes: string[]
  similarityScore: number         // 0-1 correlation confidence
  filesTouched, filesWritten: string[]
  toolCallCount: number
  model: string | null
  tokenUsage: { inputTokens, outputTokens, cacheReadTokens: number }
}

interface Analytics {
  totalFeatures, totalFunctionsModified, totalPromptsDetected: number
  claudeCodeCommitPercentage, avgPromptSimilarity: number
  mostModifiedFiles, mostModifiedFunctions: string[]
  changeTypeTotals: Record<ChangeType, number>
  velocityByWeek: { week, features, commits }[]
  // Extended (from ML pipeline)
  avgIntentCompletion?, repromptRate?, patternCount?, embeddingCoverage?: number
}

interface IntentAnalysis {
  promptText, sessionId: string
  completionScore: number
  repromptCount: number
  gaps: string[]                  // files mentioned but not touched
  outcome: "completed" | "partial" | "abandoned" | "reworked"
}

interface DeveloperProfile {
  preferredLanguages: string[]
  peakHours: number[]
  avgCommitGranularity: number    // files per commit
  repromptRate: number
  fileCouplings: { fileA, fileB: string; count: number }[]
}
```

### Color System

| Change Type | Color | Hex |
|-------------|-------|-----|
| new_feature | Emerald | `#34d399` |
| bug_fix | Red | `#f87171` |
| refactor | Blue | `#60a5fa` |
| performance | Amber | `#fbbf24` |
| style | Gray | `#71717a` |
| test | Purple | `#a78bfa` |
| documentation | Teal | `#2dd4bf` |

---

## Setup & Installation

### Prerequisites

```bash
# Rust 1.75+
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Node.js 20+
nvm install 20

# Tauri CLI
cargo install tauri-cli

# pixi (for Mojo environment)
curl -fsSL https://pixi.sh/install.sh | bash

# macOS only
xcode-select --install
```

### Project Setup

```bash
git clone <repo-url>
cd CodeLens

# Install frontend dependencies
npm install

# (Optional) Download ML models for Mojo engine
cd mojo-engine
pixi install
./scripts/download_models.sh
cd ..

# (Optional) Build Mojo engine
./scripts/build-mojo.sh
```

### Environment

```bash
# Optional: for Claude API enrichment
export ANTHROPIC_API_KEY=sk-ant-...

# Optional: model selection
export CLAUDE_MODEL=claude-sonnet-4-5-20250929
export CLAUDE_MAX_CONCURRENT=3

# Optional: ML models path
export CODELENS_MODELS_DIR=./mojo-engine/src/models
```

---

## Build & Run

### Development

```bash
npm run tauri dev
```

Starts Vite dev server (port 1420) + Tauri Rust backend with hot reload.

### Production Build

```bash
# Full build with Mojo engine bundled as sidecar
./scripts/bundle.sh

# Or without Mojo (Rust-only fallback)
npm run tauri build
```

Outputs platform-specific installers in `src-tauri/target/release/bundle/`.

### Mojo Engine Only

```bash
cd mojo-engine
pixi run build
./build/codelens-engine --repo /path/to/repo --output /tmp/output.json
```

### Run Tests

```bash
cd mojo-engine
pixi run test
```

---

## Configuration

### Tauri Commands (11 registered)

| Command | Status | Description |
|---------|--------|-------------|
| `scan_repository` | Implemented | Main pipeline: Mojo → Rust fallback → sessions → enrichment |
| `enrich_features` | Implemented | Claude API enrichment trigger |
| `get_sessions` | Implemented | Parse Claude Code JSONL sessions |
| `delete_sessions` | Implemented | Remove session logs |
| `update_settings` | Implemented | Save API key and preferences |
| `get_project_data` | Stub | Load project from storage |
| `list_projects` | Stub | List previously scanned repos |
| `get_feature_detail` | Stub | Feature detail view |
| `search` | Stub | Full-text search |
| `get_function_history` | Stub | Function modification history |
| `export_report` | Stub | Markdown/HTML export |

### Sidecar Configuration

`tauri.conf.json` includes:
```json
{
  "bundle": {
    "externalBin": ["binaries/codelens-engine"]
  }
}
```

The Mojo binary is looked up in this order:
1. `<resource_dir>/binaries/codelens-engine-<target-triple>` (production)
2. `./mojo-engine/build/codelens-engine` (development)
3. `<exe_dir>/codelens-engine` (relative to executable)

---

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/build-mojo.sh` | Compile Mojo engine via `pixi run build` |
| `scripts/bundle.sh` | Full release: build Mojo → copy sidecar → `npm run tauri build` |
| `mojo-engine/scripts/download_models.sh` | Download CodeBERT ONNX + initialize classifier weights |

---

## License

MIT

---

*Built with Mojo, Rust, Tauri, React, and Claude Code itself.*
