# CodeLens — Claude Code Feature Timeline Visualizer

A desktop application that visualizes the features Claude Code has worked on across a repository, showing a rich timeline of features, functions modified, logic changes, and the prompts that drove them — powered by **Mojo** for high-performance local ML preprocessing and **Claude API** for semantic summarization.

---

## Table of Contents

1. [Project Vision](#project-vision)
2. [Architecture Overview](#architecture-overview)
3. [Technology Stack](#technology-stack)
4. [Directory Structure](#directory-structure)
5. [Module 1: Mojo Preprocessing Engine](#module-1-mojo-preprocessing-engine)
6. [Module 2: Local ML Pipeline (Mojo + MAX Engine)](#module-2-local-ml-pipeline-mojo--max-engine)
7. [Module 3: Claude Semantic Layer](#module-3-claude-semantic-layer)
8. [Module 4: Tauri Desktop Application](#module-4-tauri-desktop-application)
9. [Data Models & Schemas](#data-models--schemas)
10. [IPC & Communication Protocol](#ipc--communication-protocol)
11. [Setup & Installation](#setup--installation)
12. [Build & Run](#build--run)
13. [Development Workflow](#development-workflow)
14. [Roadmap](#roadmap)

---

## Project Vision

Modern AI-assisted development with Claude Code generates rich, complex histories across codebases. But understanding *what* was built, *how* it evolved, and *why* specific decisions were made requires sifting through hundreds of commits, diffs, and scattered session logs.

**CodeLens** solves this by:

- **Parsing** git history and Claude Code session data at blazing speed using Mojo
- **Embedding and clustering** code changes locally using MAX Engine + small ML models (no API calls for the heavy compute)
- **Summarizing** features and extracting intent using the Claude API (only for what requires an LLM)
- **Visualizing** everything in a beautiful, interactive desktop timeline built with Tauri + React

The result: open any repo, and instantly see a rich, navigable map of every feature Claude Code helped build — the prompts used, the functions touched, the logic patterns, and how it all connects.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CodeLens Desktop App                         │
│                         (Tauri + React)                             │
│                                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐  ┌───────────┐ │
│  │  Timeline    │  │  Feature     │  │  Function   │  │  Prompt   │ │
│  │  View        │  │  Cards       │  │  Explorer   │  │  Viewer   │ │
│  └──────┬──────┘  └──────┬───────┘  └─────┬──────┘  └─────┬─────┘ │
│         └────────────────┴────────────────┴──────────────┘         │
│                              │ reads                                │
│                     enriched_data.json                              │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                   ┌──────────┴──────────┐
                   │  Claude API Layer   │  Semantic enrichment:
                   │  (TypeScript/Rust)  │  • Feature narratives
                   │                     │  • Intent extraction
                   │                     │  • Cross-feature links
                   └──────────┬──────────┘
                              │ reads
                   ┌──────────┴──────────┐
                   │  Mojo Engine        │  Local preprocessing:
                   │  (Mojo + MAX)       │  • Git parsing
                   │                     │  • Diff extraction
                   │                     │  • Code embeddings
                   │                     │  • Feature clustering
                   │                     │  • Change classification
                   └──────────┬──────────┘
                              │ reads
                   ┌──────────┴──────────┐
                   │  Git Repository     │
                   │  + Claude Code      │
                   │    session logs     │
                   └─────────────────────┘
```

### Data Flow

```
Step 1: User points CodeLens at a git repository
Step 2: Mojo Engine runs (fast, local, offline):
        a. Parse all git log output (commits, authors, timestamps, messages)
        b. Extract diffs per commit (files changed, lines added/removed)
        c. Parse function-level changes from diffs (AST-light extraction)
        d. Detect Claude Code markers in commit messages / session logs
        e. Extract prompts associated with each coding session
        f. Generate code embeddings via MAX Engine (local CodeBERT ONNX)
        g. Cluster related commits into "features" via k-means / DBSCAN
        h. Classify each change: bug_fix | new_feature | refactor | perf | style
        i. Compute prompt-to-output similarity scores
        j. Output: preprocessed.json (structured, ML-enriched data)
Step 3: Claude API Layer runs (selective, semantic):
        a. Read preprocessed.json
        b. For each feature cluster: generate plain-English narrative
        c. For each prompt: extract developer intent
        d. Identify cross-feature dependencies and connections
        e. Output: enriched_data.json (final data for UI)
Step 4: Tauri app loads enriched_data.json and renders the UI
```

---

## Technology Stack

| Layer                  | Technology                | Purpose                                                                                 |
| ---------------------- | ------------------------- | --------------------------------------------------------------------------------------- |
| **Preprocessing**      | Mojo                      | High-performance git parsing with SIMD vectorization and zero-cost abstractions          |
| **Local ML Inference** | MAX Engine (Mojo API)     | Load ONNX models natively in Mojo. Runs on Apple Silicon, NVIDIA, AMD                   |
| **Local ML Algorithms**| Pure Mojo                 | K-means, cosine similarity, DBSCAN — native Mojo for max throughput                     |
| **Semantic Layer**     | Claude API (Sonnet)       | Natural language summarization, intent extraction                                        |
| **Desktop Shell**      | Tauri 2.x (Rust)         | Lightweight native desktop app with easy Mojo binary invocation                          |
| **Frontend UI**        | React + TypeScript        | Rich interactive timeline with a familiar developer experience                           |
| **Visualization**      | D3.js + Recharts          | Timeline rendering, dependency graphs, heatmaps                                         |
| **State Management**   | Zustand                   | Lightweight, minimal-boilerplate state management                                        |
| **Styling**            | Tailwind CSS              | Rapid, consistent UI development                                                         |
| **IPC**                | Tauri Commands (Rust-JS)  | Type-safe communication between frontend and backend                                     |
| **Data Format**        | JSON (intermediate)       | Universal interchange between Mojo, Rust, and React layers                               |

### Version Requirements

- **Mojo**: Latest stable (`modular install mojo`)
- **MAX Engine**: Latest stable (`modular install max`)
- **Rust**: 1.75+
- **Node.js**: 20+
- **Tauri CLI**: 2.x (`cargo install tauri-cli`)

---

## Directory Structure

```
codelens/
├── README.md
├── DEPENDENCIES.md
├── .gitignore
│
├── mojo-engine/                    # Mojo preprocessing + local ML
│   ├── src/
│   │   ├── main.mojo              # CLI entry point
│   │   ├── git_parser.mojo        # Git log + diff parsing
│   │   ├── diff_extractor.mojo    # Function-level change extraction
│   │   ├── prompt_detector.mojo   # Claude Code session/prompt detection
│   │   ├── embeddings.mojo        # MAX Engine: code embedding generation
│   │   ├── clustering.mojo        # K-means / DBSCAN feature clustering
│   │   ├── classifier.mojo        # Change type classification
│   │   ├── similarity.mojo        # Prompt-to-output cosine similarity
│   │   ├── models/
│   │   │   ├── codebert.onnx      # Pre-downloaded CodeBERT ONNX model
│   │   │   └── classifier.onnx    # Fine-tuned change classifier model
│   │   ├── utils/
│   │   │   ├── json_writer.mojo   # JSON serialization utilities
│   │   │   ├── tokenizer.mojo     # Basic code tokenizer for embeddings
│   │   │   └── math_ops.mojo      # SIMD math: cosine sim, distances, norms
│   │   └── types/
│   │       ├── commit.mojo        # Commit data structures
│   │       ├── feature.mojo       # Feature cluster structures
│   │       └── embedding.mojo     # Embedding vector types
│   ├── tests/
│   │   ├── test_git_parser.mojo
│   │   ├── test_clustering.mojo
│   │   └── test_similarity.mojo
│   ├── mojoproject.toml           # Mojo project config
│   └── scripts/
│       ├── download_models.sh     # Script to download ONNX models
│       └── benchmark.sh           # Performance benchmarking
│
├── src-tauri/                      # Tauri Rust backend
│   ├── Cargo.toml
│   ├── src/
│   │   ├── main.rs                # Tauri app entry point
│   │   ├── lib.rs                 # Module declarations
│   │   ├── commands/
│   │   │   ├── mod.rs
│   │   │   ├── scan.rs            # Invoke Mojo engine on a repo
│   │   │   ├── enrich.rs          # Run Claude API enrichment
│   │   │   ├── project.rs         # Manage saved projects/repos
│   │   │   └── settings.rs        # App settings (API key, etc.)
│   │   ├── claude/
│   │   │   ├── mod.rs
│   │   │   ├── client.rs          # Claude API HTTP client
│   │   │   ├── prompts.rs         # System prompts for feature summarization
│   │   │   └── types.rs           # API request/response types
│   │   ├── mojo_bridge/
│   │   │   ├── mod.rs
│   │   │   ├── runner.rs          # Spawn Mojo binary, capture stdout
│   │   │   └── parser.rs          # Parse Mojo JSON output
│   │   ├── storage/
│   │   │   ├── mod.rs
│   │   │   ├── db.rs              # SQLite for caching processed repos
│   │   │   └── cache.rs           # Embedding cache to avoid re-processing
│   │   └── types/
│   │       ├── mod.rs
│   │       ├── commit.rs          # Commit types (mirrors Mojo types)
│   │       ├── feature.rs         # Feature types
│   │       └── enriched.rs        # Claude-enriched output types
│   ├── tauri.conf.json            # Tauri configuration
│   └── icons/                     # App icons
│
├── src/                            # React frontend
│   ├── main.tsx                   # React entry point
│   ├── App.tsx                    # Root component + routing
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx        # Repo selector, navigation
│   │   │   ├── Header.tsx         # Search bar, view toggles
│   │   │   └── StatusBar.tsx      # Processing status, progress
│   │   ├── timeline/
│   │   │   ├── Timeline.tsx       # Main timeline view
│   │   │   ├── TimelineNode.tsx   # Individual commit/feature node
│   │   │   ├── TimelineBranch.tsx # Feature branch visualization
│   │   │   ├── TimelineZoom.tsx   # Zoom controls
│   │   │   └── TimelineFilter.tsx # Filter by type, author, date range
│   │   ├── features/
│   │   │   ├── FeatureCard.tsx    # Expanded feature detail card
│   │   │   ├── FeatureList.tsx    # Sortable feature list view
│   │   │   ├── FeatureGraph.tsx   # D3 dependency graph
│   │   │   └── FeatureNarrative.tsx # Claude-generated feature story
│   │   ├── functions/
│   │   │   ├── FunctionTree.tsx   # Tree view of modified functions
│   │   │   ├── FunctionDiff.tsx   # Side-by-side diff viewer
│   │   │   ├── FunctionHistory.tsx # Function change history
│   │   │   └── FunctionHeatmap.tsx # Heatmap of most-changed functions
│   │   ├── prompts/
│   │   │   ├── PromptExplorer.tsx # Browse all prompts used
│   │   │   ├── PromptDetail.tsx   # Single prompt + its output
│   │   │   ├── PromptScore.tsx    # Similarity badge
│   │   │   └── PromptTimeline.tsx # Prompts overlaid on timeline
│   │   ├── analytics/
│   │   │   ├── Dashboard.tsx      # Overview stats and charts
│   │   │   ├── ClusterView.tsx    # 2D/3D embedding cluster visualization
│   │   │   ├── ChangeTypeChart.tsx # Change type distribution chart
│   │   │   └── VelocityChart.tsx  # Features shipped over time
│   │   └── shared/
│   │       ├── CodeBlock.tsx      # Syntax-highlighted code viewer
│   │       ├── SearchBar.tsx      # Global search component
│   │       ├── LoadingSpinner.tsx
│   │       └── EmptyState.tsx
│   ├── hooks/
│   │   ├── useProject.ts         # Manage current repo/project state
│   │   ├── useTimeline.ts        # Timeline data + navigation
│   │   ├── useFeatures.ts        # Feature data + filtering
│   │   └── useTauriCommand.ts    # Generic Tauri command invoker
│   ├── store/
│   │   ├── projectStore.ts       # Zustand: project/repo state
│   │   ├── timelineStore.ts      # Zustand: timeline view state
│   │   └── settingsStore.ts      # Zustand: app settings
│   ├── lib/
│   │   ├── types.ts              # TypeScript types (mirrors Rust types)
│   │   ├── constants.ts          # App constants, colors, config
│   │   └── utils.ts              # Utility functions
│   ├── styles/
│   │   └── globals.css           # Tailwind imports + custom styles
│   └── assets/
│       └── logo.svg
│
├── package.json                   # Node dependencies
├── tsconfig.json
├── tailwind.config.js
├── vite.config.ts                 # Vite bundler config for Tauri
└── scripts/
    ├── setup.sh                   # Full project setup script
    ├── dev.sh                     # Start dev mode (Tauri + Vite)
    └── build.sh                   # Production build
```

---

## Module 1: Mojo Preprocessing Engine

### Purpose

The Mojo engine is the performance backbone. It takes a raw git repository and produces a fully structured, ML-enriched JSON file that contains everything the UI needs (minus the natural language summaries from Claude).

### 1.1 Git Parser (`git_parser.mojo`)

**Input:** Path to a git repository
**Output:** Structured list of `CommitData` objects

Responsibilities:
- Execute `git log` via subprocess and parse the output using SIMD string operations
- Extract commit hash, author, timestamp, subject, body, and files changed
- Detect Claude Code commit patterns (auto-generated messages, session markers)
- Look for `.claude/` directory or session JSON files in the repo

**Performance Target:** Parse 10,000 commits in < 500ms

```mojo
struct CommitData:
    var hash: String
    var author_name: String
    var author_email: String
    var timestamp: Int64
    var subject: String
    var body: String
    var files_changed: List[FileChange]
    var is_claude_code: Bool
    var session_id: Optional[String]

struct FileChange:
    var path: String
    var lines_added: Int
    var lines_removed: Int
    var change_type: String  # "added", "modified", "deleted", "renamed"
```

### 1.2 Diff Extractor (`diff_extractor.mojo`)

**Input:** List of `CommitData` + repository path
**Output:** Enriched commits with function-level changes

Parses unified diffs to extract hunks, function context from `@@` headers, and builds `FunctionChange` records per function touched. Supports Python, TypeScript/JavaScript, Rust, Go, Mojo, Java, C/C++, Swift, and Kotlin.

**Performance Target:** Extract function-level changes from 10,000 commits in < 2 seconds

### 1.3 Prompt Detector (`prompt_detector.mojo`)

**Input:** Repository path + commit data
**Output:** List of `PromptSession` linking prompts to commits

Searches for Claude Code session data in `.claude/`, `CLAUDE.md`, commit messages, and session JSON files. Links prompts to commits by timestamp proximity, file overlap, and session ID matching.

---

## Module 2: Local ML Pipeline (Mojo + MAX Engine)

### Purpose

Run all compute-intensive ML operations locally for speed and offline capability.

### 2.1 Code Embeddings (`embeddings.mojo`)

Uses CodeBERT (ONNX format) via MAX Engine to generate 768-dimensional embedding vectors for function diffs, commit messages, and prompt text. Supports batch processing for throughput.

**Performance Target:** Embed 5,000 code snippets in < 10 seconds on Apple Silicon

**Fallback:** TF-IDF vectorization in pure Mojo when ONNX models are unavailable.

### 2.2 Feature Clustering (`clustering.mojo`)

Two-phase approach: DBSCAN for initial density-based clustering, then K-means refinement on large clusters. Uses SIMD-accelerated cosine distance computation.

### 2.3 Change Type Classifier (`classifier.mojo`)

Two modes:
- **Rule-based:** Keyword matching on commit messages + diff pattern analysis
- **ONNX model:** Fine-tuned DistilBERT classifier via MAX Engine

Classifies commits as: `new_feature`, `bug_fix`, `refactor`, `performance`, `style`, `test`, or `documentation`.

### 2.4 Prompt-to-Output Similarity (`similarity.mojo`)

Scores how well Claude Code's output matched the developer's prompt intent using cosine similarity between prompt embeddings and commit diff embeddings.

### 2.5 JSON Output

The Mojo engine writes `preprocessed.json` containing all extracted and ML-enriched data — the contract between the Mojo engine and the Tauri/Claude layer. See [Data Models](#data-models--schemas) for the full schema.

---

## Module 3: Claude Semantic Layer

### Purpose

Use the Claude API only for tasks requiring genuine language understanding — narratives, intent extraction, and cross-feature connections. Keeps API costs low and the app fast.

- **Feature Narrative Generation:** For each feature cluster, Claude generates a title, summary, and key technical decisions
- **Intent Extraction:** Extracts the developer's high-level goal, requirements, and constraints from each prompt
- **Cross-Feature Connections:** Identifies dependencies, iterations, patterns, and technical debt across features
- **Caching:** All responses cached in SQLite keyed by `(cluster_id, data_hash)`

Model: `claude-sonnet-4-5-20250929` with rate limiting (max 5 concurrent requests, exponential backoff).

---

## Module 4: Tauri Desktop Application

### Views

- **Home:** Project selector with previously scanned repos and quick stats
- **Timeline:** Horizontal scrollable timeline with zoom levels (Day/Week/Month/Feature), color-coded by change type, filterable by author, date, and type
- **Feature Detail:** Claude-generated narrative, commit timeline, function diffs, associated prompts, and dependency links
- **Function Explorer:** Tree view by file/function with modification history and heatmap overlay
- **Prompt Explorer:** Chronological prompt list with similarity scores and before/after code preview
- **Analytics Dashboard:** Velocity charts, change type distribution, most-modified files/functions, embedding cluster visualization

### Design Principles

- Dark mode first
- High information density with drill-down
- Keyboard navigation throughout
- Resizable panels and smooth animations

### Color System

| Change Type     | Color                        |
| --------------- | ---------------------------- |
| `new_feature`   | Emerald green (`#10B981`)    |
| `bug_fix`       | Red (`#EF4444`)              |
| `refactor`      | Blue (`#3B82F6`)             |
| `performance`   | Amber (`#F59E0B`)            |
| `style`         | Gray (`#6B7280`)             |
| `test`          | Purple (`#8B5CF6`)           |
| `documentation` | Teal (`#14B8A6`)             |
| Claude Code     | Anthropic orange (`#E07A5F`) |

---

## Data Models & Schemas

### TypeScript Types (Frontend)

```typescript
interface Project {
  id: string;
  name: string;
  path: string;
  lastScanned: string;
  totalCommits: number;
  totalFeatures: number;
  claudeCodePercentage: number;
}

interface Commit {
  hash: string;
  authorName: string;
  authorEmail: string;
  timestamp: string;
  subject: string;
  body: string;
  isClaudeCode: boolean;
  sessionId: string | null;
  changeType: ChangeType;
  changeTypeConfidence: number;
  clusterId: number;
  filesChanged: FileChange[];
}

interface FileChange {
  path: string;
  linesAdded: number;
  linesRemoved: number;
  functions: FunctionChange[];
}

interface FunctionChange {
  name: string;
  linesAdded: number;
  linesRemoved: number;
  diffText: string;
}

interface Feature {
  clusterId: number;
  title: string;
  autoLabel: string;
  narrative: string | null;
  intent: string | null;
  keyDecisions: string[];
  commitHashes: string[];
  timeStart: string;
  timeEnd: string;
  functionsTouched: string[];
  totalLinesAdded: number;
  totalLinesRemoved: number;
  primaryFiles: string[];
  changeTypeDistribution: Record<ChangeType, number>;
  dependencies: number[];
}

interface PromptSession {
  sessionId: string;
  promptText: string;
  timestamp: string;
  associatedCommitHashes: string[];
  similarityScore: number;
  scopeMatch: number;
  intent: string | null;
}

type ChangeType =
  | 'new_feature'
  | 'bug_fix'
  | 'refactor'
  | 'performance'
  | 'style'
  | 'test'
  | 'documentation';

interface Analytics {
  totalFeatures: number;
  totalFunctionsModified: number;
  totalPromptsDetected: number;
  claudeCodeCommitPercentage: number;
  avgPromptSimilarity: number;
  mostModifiedFiles: string[];
  mostModifiedFunctions: string[];
  changeTypeTotals: Record<ChangeType, number>;
  velocityByWeek: { week: string; features: number; commits: number }[];
}
```

---

## IPC & Communication Protocol

### Mojo to Tauri

The Mojo engine runs as a compiled binary invoked by Tauri via `std::process::Command`. Progress is streamed via JSON lines on stdout:

```json
{"stage": "git_parse", "progress": 0.0, "message": "Parsing git history..."}
{"stage": "embedding", "progress": 0.5, "message": "Generating embeddings (2500/5000)..."}
{"stage": "complete", "progress": 1.0, "message": "Done. 23 features detected."}
```

### Tauri to React

Standard Tauri v2 invoke pattern with event-based progress for long-running operations:

```typescript
import { invoke } from '@tauri-apps/api/core';
import { listen } from '@tauri-apps/api/event';

await listen('scan-progress', (event) => {
  const { stage, progress, message } = event.payload;
  updateProgressBar(stage, progress, message);
});

await invoke('scan_repository', { path: '/path/to/repo' });
```

### Tauri Commands

| Command               | Description                               |
| ---------------------- | ----------------------------------------- |
| `scan_repository`      | Invoke Mojo engine on a repo              |
| `enrich_features`      | Run Claude API enrichment                 |
| `get_project_data`     | Return full enriched data for UI          |
| `list_projects`        | List previously scanned repos             |
| `get_feature_detail`   | Get expanded detail for a single feature  |
| `search`               | Full-text search across all data          |
| `get_function_history` | Complete modification history of a function |
| `update_settings`      | Save API key and preferences              |
| `export_report`        | Export feature report as Markdown or HTML  |

---

## Setup & Installation

### Prerequisites

```bash
# 1. Install Modular (Mojo + MAX)
curl -ssL https://magic.modular.com | bash
modular install mojo
modular install max

# 2. Install Rust (1.75+)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 3. Install Node.js (20+)
nvm install 20

# 4. Install Tauri CLI
cargo install tauri-cli

# 5. System dependencies (macOS)
xcode-select --install

# 5. System dependencies (Linux)
sudo apt update
sudo apt install -y libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev patchelf
```

### Project Setup

```bash
git clone https://github.com/your-username/codelens.git
cd codelens

# Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh

# Or manually:
npm install

# Download ML models
chmod +x mojo-engine/scripts/download_models.sh
./mojo-engine/scripts/download_models.sh

# Build Mojo engine
cd mojo-engine
mojo build src/main.mojo -o build/codelens-engine
cd ..

# Configure environment
cp .env.example .env
# Edit .env to add your ANTHROPIC_API_KEY
```

### Configuration

```env
ANTHROPIC_API_KEY=sk-ant-...
CLAUDE_MODEL=claude-sonnet-4-5-20250929
MAX_CONCURRENT_API_CALLS=5
EMBEDDING_BATCH_SIZE=32
CLUSTERING_EPS=0.3
CLUSTERING_MIN_SAMPLES=2
```

---

## Build & Run

### Development

```bash
npm run tauri dev
```

### Production

```bash
npm run tauri build
```

Outputs platform-specific installers (`.dmg`, `.AppImage`, `.msi`).

### Mojo Engine Only

```bash
cd mojo-engine
mojo build src/main.mojo -o build/codelens-engine
./build/codelens-engine --repo /path/to/repo --output ./test_output.json
```

---

## Development Workflow

| Phase | Focus                 | Key Deliverables                                               |
| ----- | --------------------- | -------------------------------------------------------------- |
| 1     | Foundation            | Tauri + React scaffold, git parser, diff extractor, basic timeline |
| 2     | Local ML              | MAX Engine integration, embeddings, clustering, classifier     |
| 3     | Claude Integration    | API client, feature narratives, intent extraction, caching     |
| 4     | Prompt Explorer       | Prompt detection, similarity scoring, prompt UI                |
| 5     | Analytics & Polish    | Dashboard, function explorer, search, keyboard nav, dark mode  |
| 6     | Distribution          | Bundled installers for macOS, Linux, Windows                   |

---

## Roadmap (Post-MVP)

- Real-time mode — watch a repo and update timeline as new commits land
- Multi-repo support — compare Claude Code usage across projects
- Team view — see which team members use Claude Code and how
- Plugin system — custom preprocessors for other AI coding tools
- Export — generate Markdown/PDF reports of feature history
- Embedding explorer — interactive 3D visualization of code embedding space
- Custom model training — fine-tune the change classifier on user's labeled data
- Git blame integration — Claude Code contribution percentage per file/function
- VS Code extension — lightweight version that runs inside VS Code

---

## License

MIT

---

## Contributing

This is currently a personal project by Peyton Salvant. If you're interested in contributing, open an issue to discuss.

---

*Built with Mojo, Claude, Tauri, and React.*
