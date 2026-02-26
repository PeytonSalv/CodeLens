# CodeLens — Claude Code Feature Timeline Visualizer

A desktop application that visualizes the features Claude Code has worked on across a repository, showing a rich timeline of features, functions modified, logic changes, and the prompts that drove them. CodeLens reads Claude Code's local session logs in real-time — **you don't even need to commit** for CodeLens to know what you're building.

---

## Table of Contents

1. [Project Vision](#project-vision)
2. [Live Session Intelligence](#live-session-intelligence)
3. [Architecture Overview](#architecture-overview)
4. [Technology Stack](#technology-stack)
5. [Directory Structure](#directory-structure)
6. [Module 1: Git Scanning Pipeline](#module-1-git-scanning-pipeline)
7. [Module 2: Claude Code Session Parser](#module-2-claude-code-session-parser)
8. [Module 3: Prompt-to-Code Correlation](#module-3-prompt-to-code-correlation)
9. [Module 4: Claude Semantic Layer](#module-4-claude-semantic-layer)
10. [Module 5: Tauri Desktop Application](#module-5-tauri-desktop-application)
11. [Data Models & Schemas](#data-models--schemas)
12. [Claude Code JSONL Format](#claude-code-jsonl-format)
13. [IPC & Communication Protocol](#ipc--communication-protocol)
14. [Setup & Installation](#setup--installation)
15. [Build & Run](#build--run)
16. [Development Workflow](#development-workflow)
17. [Roadmap](#roadmap)

---

## Project Vision

Modern AI-assisted development with Claude Code generates rich, complex histories across codebases. But understanding *what* was built, *how* it evolved, and *why* specific decisions were made requires sifting through hundreds of commits, diffs, and scattered session logs.

**CodeLens** solves this by:

- **Watching Claude Code sessions in real-time** — parsing `~/.claude/projects/` JSONL logs as they're written, so you see what's happening *before* anything is committed
- **Correlating prompts to code** — linking what you asked ("add user auth") to exactly which files, functions, and commits resulted from that prompt
- **Parsing git history** — scanning commit logs, file diffs, and Co-Authored-By markers to identify Claude Code contributions
- **Visualizing everything** in a beautiful, interactive desktop timeline built with Tauri + React
- **Summarizing** features and extracting intent using the Claude API (optional, for semantic enrichment)

The result: open any repo, and instantly see a rich, navigable map of every feature Claude Code helped build — the prompts used, the functions touched, the logic patterns, and how it all connects. Even work-in-progress that hasn't been committed yet.

---

## Live Session Intelligence

The killer feature of CodeLens is that **it doesn't depend on git commits**. Claude Code writes detailed session logs to disk in real-time as conversations happen. CodeLens watches these files and can show you:

- **Active sessions** — what prompt is Claude working on right now?
- **Files being touched** — which files has Claude read, written, or edited in the current session?
- **Tool activity** — bash commands run, files created, searches performed
- **Uncommitted work** — cross-reference session file touches with `git status` to show in-progress changes
- **Token usage** — how many tokens each session consumed
- **Session history** — browse all past sessions for a project, even ones that never resulted in a commit

This means a developer can open CodeLens alongside Claude Code and get a live dashboard of what's happening, what was asked, and what's being built — all without waiting for a `git commit`.

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
│                              │                                      │
│                    ┌─────────┴──────────┐                           │
│                    │  Rust Backend      │                           │
│                    │  (Tauri Commands)  │                           │
│                    └────┬─────────┬─────┘                           │
└─────────────────────────┼─────────┼─────────────────────────────────┘
                          │         │
              ┌───────────┘         └───────────┐
              │                                 │
   ┌──────────┴──────────┐          ┌──────────┴──────────┐
   │  Git Repository     │          │  Claude Code Logs   │
   │                     │          │  ~/.claude/projects/ │
   │  • git log          │          │                     │
   │  • git diff-tree    │          │  • Session JSONL    │
   │  • Co-Author tags   │          │  • Tool calls       │
   │                     │          │  • Prompt text       │
   └─────────────────────┘          │  • File touches     │
                                    │  • Token usage       │
                                    └─────────────────────┘
```

### Data Flow

```
Path A — Git History Scan (on "Open Repository"):
  1. User points CodeLens at a git repository
  2. Rust backend runs git log + git diff-tree
  3. Parses commits, classifies change types, detects Claude Code co-author markers
  4. Groups commits into features by 4-hour time windows
  5. Computes analytics (most modified files, change type distribution, velocity)
  6. Returns full ProjectData to frontend → renders Timeline, Features, Analytics

Path B — Live Session Monitoring (real-time, no commits needed):
  1. Rust backend watches ~/.claude/projects/<project-hash>/ for JSONL changes
  2. Parses session logs as they're written — extracts prompts, tool calls, file touches
  3. Cross-references file touches with git status (uncommitted changes)
  4. Streams live session data to frontend via Tauri events
  5. Renders in "Live Sessions" view — shows active prompts, files being modified, progress

Path C — Prompt-to-Code Correlation (connects A + B):
  1. For each Claude Code session, extract: prompt text, timestamps, files written/edited
  2. Match sessions to commits by: timestamp overlap + file path intersection
  3. Link PromptSession → CommitData[] with confidence scores
  4. Display in Prompt Explorer: "You asked X → Claude produced commits Y, Z"
```

---

## Technology Stack

| Layer                  | Technology                | Purpose                                                                                 |
| ---------------------- | ------------------------- | --------------------------------------------------------------------------------------- |
| **Backend**            | Rust (Tauri 2.x)         | Git parsing, JSONL session log parsing, file watching, orchestration                     |
| **Local ML Inference** | Mojo + MAX Engine         | CodeBERT ONNX embeddings, SIMD-accelerated similarity computation                       |
| **Local ML Algorithms**| Pure Mojo                 | K-means, cosine similarity, DBSCAN clustering — native Mojo for max throughput           |
| **Session Parsing**    | Rust (`serde_json`)       | Parse Claude Code JSONL logs from `~/.claude/projects/`                                  |
| **File Watching**      | Rust (`notify` crate)     | Real-time monitoring of Claude Code session files as they're written                     |
| **Semantic Layer**     | Claude API (Sonnet)       | Natural language summarization, intent extraction, cross-feature connections              |
| **Frontend UI**        | React + TypeScript        | Rich interactive timeline with a familiar developer experience                           |
| **State Management**   | Zustand                   | Lightweight, minimal-boilerplate state management                                        |
| **Styling**            | Tailwind CSS              | Rapid, consistent UI development                                                         |
| **IPC**                | Tauri Commands (Rust-JS)  | Type-safe communication between frontend and backend                                     |

### Version Requirements

- **Mojo**: Latest stable (`modular install mojo`) — for ML pipeline (Phase 3+)
- **MAX Engine**: Latest stable (`modular install max`) — for ONNX model inference
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

## Module 1: Git Scanning Pipeline

### Purpose

The Rust-native git scanner is the entry point for repository analysis. It takes a git repo path and produces a full `ProjectData` structure with commits, features, and analytics — no external dependencies beyond `git`.

### Implementation (`src-tauri/src/commands/scan.rs`)

**Input:** Path to a git repository
**Output:** `ProjectData` (commits, features, analytics)

Pipeline:
1. Validate `.git/` directory exists
2. Run `git log --format=%H%x01%an%x01%ae%x01%aI%x01%s%x01%b%x00 --no-merges`
3. Parse output into `CommitData` structs
4. Run `git diff-tree --numstat` per commit for file-level stats
5. Classify change type by commit message keywords (`fix` → `bug_fix`, `feat` → `new_feature`, etc.)
6. Detect Claude Code commits by `Co-Authored-By: Claude` markers in commit body
7. Group commits into features by 4-hour time window gaps
8. Compute analytics: most modified files, change type distribution, Claude %, weekly velocity
9. Detect languages from file extensions
10. Return full `ProjectData` to frontend

---

## Module 2: Claude Code Session Parser

### Purpose

This is the core differentiator. Claude Code writes detailed JSONL session logs to `~/.claude/projects/` **in real-time** as conversations happen. CodeLens parses these logs to extract prompts, tool calls, and file touches — **even before any code is committed**.

### Session Log Location

```
~/.claude/projects/
├── -Users-username-path-to-repo/          # Project directory (path-encoded)
│   ├── <session-uuid>.jsonl               # One file per conversation session
│   ├── <session-uuid>/
│   │   └── subagents/
│   │       └── agent-<id>.jsonl           # Subagent/parallel task logs
│   └── <another-session>.jsonl
```

### What We Extract

From each JSONL session file:

| Data                | Source                                           |
| ------------------- | ------------------------------------------------ |
| **Prompt text**     | Lines with `type: "user"`, `message.role: "user"`, where `content` is a string |
| **Files written**   | `tool_use` blocks where `name: "Write"` → `input.file_path` |
| **Files edited**    | `tool_use` blocks where `name: "Edit"` → `input.file_path` |
| **Files read**      | `tool_use` blocks where `name: "Read"` → `input.file_path` |
| **Bash commands**   | `tool_use` blocks where `name: "Bash"` → `input.command` |
| **Timestamps**      | `timestamp` field on every message (ISO 8601)    |
| **Model used**      | `message.model` on assistant messages            |
| **Token usage**     | `message.usage.input_tokens` + `output_tokens`   |
| **Session ID**      | `sessionId` field (UUID)                         |
| **Errors**          | `tool_result` blocks where `is_error: true`      |

### Live Monitoring

Using the Rust `notify` crate, CodeLens watches the project's session directory for:
- **New `.jsonl` files** → new session started
- **File modifications** → session in progress, new messages being written
- **File size changes** → read new lines appended since last check

This enables a real-time "Live Sessions" view that updates as you talk to Claude Code.

---

## Module 3: Prompt-to-Code Correlation

### Purpose

Connect the *intent* layer (what you asked Claude to do) with the *output* layer (what code actually changed). This works in two modes:

### Mode A: Pre-Commit (Live)

Before any commits exist:
1. Parse active session JSONL for prompts and `Write`/`Edit` tool calls
2. Extract file paths touched by Claude in the session
3. Run `git diff --name-only` to get current uncommitted changes
4. Cross-reference: files in both sets are "in-progress work from this prompt"
5. Display: **"Prompt: 'add user auth' → modifying: src/auth.ts, src/middleware.ts (uncommitted)"**

### Mode B: Post-Commit (Historical)

After commits land:
1. Parse all session JSONL files for the project
2. For each session, extract: prompt text, timestamps, files written/edited
3. For each Claude-authored commit (has `Co-Authored-By: Claude`), note: timestamp, files changed
4. **Timestamp matching**: session active during `[commit_time - 5min, commit_time]` → likely match
5. **File overlap**: intersection of session file touches and commit file changes → confidence boost
6. Link `PromptSession` → `CommitData[]` with correlation confidence score
7. Display in Prompt Explorer: **"You asked 'fix login bug' → produced commit abc123 (src/auth.ts +15 -3)"**

### Correlation Confidence

```
score = 0.0

# Timestamp overlap (session was active when commit was made)
if session.time_start <= commit.timestamp <= session.time_end + 5min:
    score += 0.5

# File overlap (session touched same files as commit)
overlap = len(session.files_touched & commit.files_changed) / len(commit.files_changed)
score += overlap * 0.4

# Co-author marker present
if commit.is_claude_code:
    score += 0.1
```

---

## Module 4: Claude Semantic Layer

### Purpose

Use the Claude API only for tasks requiring genuine language understanding — narratives, intent extraction, and cross-feature connections. Keeps API costs low and the app fast.

- **Feature Narrative Generation:** For each feature cluster, Claude generates a title, summary, and key technical decisions
- **Intent Extraction:** Extracts the developer's high-level goal, requirements, and constraints from each prompt
- **Cross-Feature Connections:** Identifies dependencies, iterations, patterns, and technical debt across features
- **Caching:** All responses cached in SQLite keyed by `(cluster_id, data_hash)`

Model: `claude-sonnet-4-5-20250929` with rate limiting (max 5 concurrent requests, exponential backoff).

---

## Module 5: Tauri Desktop Application

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

## Claude Code JSONL Format

CodeLens parses Claude Code's native session log format. Each session is a `.jsonl` file where every line is a self-contained JSON object representing one conversation turn.

### Message Types

**User Prompt (what you typed):**
```json
{
  "type": "user",
  "sessionId": "1eae501e-e74d-4ded-861a-0f7e45886116",
  "timestamp": "2026-02-25T23:17:53.198Z",
  "cwd": "/path/to/repo",
  "message": {
    "role": "user",
    "content": "add user authentication with JWT"
  },
  "uuid": "15abb5a3-b022-404b-9479-166ae0858f64",
  "parentUuid": null
}
```

**Assistant Tool Call (Claude writing/editing files):**
```json
{
  "type": "assistant",
  "timestamp": "2026-02-25T23:17:59.020Z",
  "message": {
    "role": "assistant",
    "model": "claude-opus-4-6",
    "content": [
      {
        "type": "tool_use",
        "id": "toolu_017Q8yGwpcphTjuAgbbQyMEQ",
        "name": "Write",
        "input": {
          "file_path": "/path/to/repo/src/auth.ts",
          "content": "..."
        }
      }
    ],
    "usage": {
      "input_tokens": 3,
      "output_tokens": 250,
      "cache_read_input_tokens": 18792
    }
  }
}
```

**Tool Result:**
```json
{
  "type": "user",
  "timestamp": "2026-02-25T23:17:59.399Z",
  "message": {
    "role": "user",
    "content": [
      {
        "type": "tool_result",
        "tool_use_id": "toolu_017Q8yGwpcphTjuAgbbQyMEQ",
        "content": "File written successfully",
        "is_error": false
      }
    ]
  }
}
```

### Key Tool Names to Track

| Tool Name | What It Means | Data Extracted |
| --------- | ------------- | -------------- |
| `Write`   | Claude created a new file | `input.file_path`, `input.content` |
| `Edit`    | Claude modified an existing file | `input.file_path`, `input.old_string`, `input.new_string` |
| `Read`    | Claude read a file for context | `input.file_path` |
| `Bash`    | Claude ran a shell command | `input.command`, `input.description` |
| `Glob`    | Claude searched for files | `input.pattern` |
| `Grep`    | Claude searched file contents | `input.pattern`, `input.path` |
| `Task`    | Claude spawned a subagent | `input.prompt` (subagent has its own JSONL) |

### Session Identification

- **Session ID**: UUID in `sessionId` field, also the filename (`<uuid>.jsonl`)
- **Project**: Derived from directory name (path-encoded, e.g., `-Users-me-project` → `/Users/me/project`)
- **Conversation thread**: `parentUuid` links messages into a chain; `isSidechain: true` marks subagent turns

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

| Phase | Focus                     | Key Deliverables                                                     |
| ----- | ------------------------- | -------------------------------------------------------------------- |
| 1     | Foundation (done)         | Tauri + React scaffold, git parser, timeline, features, analytics    |
| 2     | Session Intelligence      | JSONL parser, live session monitoring, file watcher                   |
| 3     | Prompt Correlation        | Prompt-to-commit linking, uncommitted work tracking, prompt explorer  |
| 4     | Mojo ML Pipeline          | MAX Engine integration, code embeddings, DBSCAN clustering, similarity scoring |
| 5     | Claude Enrichment         | API client, feature narratives, intent extraction, caching            |
| 6     | Polish & Distribution     | Search, keyboard nav, export, bundled installers                      |

---

## Roadmap

### Now (In Progress)
- [x] Git history scanning — parse commits, classify change types, detect Claude Code co-authors
- [x] Feature grouping — cluster commits into features by time windows
- [x] Timeline view — color-coded commits with Claude Code badges
- [x] Feature list — grouped feature cards with stats
- [x] Analytics dashboard — most modified files, change type distribution, velocity
- [ ] Claude Code session parser — read JSONL logs from `~/.claude/projects/`
- [ ] Prompt-to-code correlation — link prompts to commits/file changes
- [ ] Live session monitoring — file watcher on session directory

### Next
- Live Sessions view — real-time dashboard of active Claude Code sessions
- Uncommitted work tracker — cross-reference session file touches with `git status`
- Token usage analytics — per-session and per-project token consumption
- Session timeline — overlay prompts on the commit timeline
- Prompt search — full-text search across all session prompts

### Future
- Mojo ML pipeline — CodeBERT embeddings via MAX Engine, DBSCAN feature clustering, prompt-to-code similarity scoring
- Claude API enrichment — generate feature narratives and intent summaries
- Multi-repo support — compare Claude Code usage across projects
- Team view — see which team members use Claude Code and how
- Export — generate Markdown/PDF reports of feature history
- VS Code extension — lightweight version that runs inside VS Code
- Plugin system — support for other AI coding tools (Cursor, Copilot, etc.)
- Git blame integration — Claude Code contribution percentage per file/function

---

## License

MIT

---

## Contributing

This is currently a personal project by Peyton Salvant. If you're interested in contributing, open an issue to discuss.

---

*Built with Mojo, Rust, Tauri, React, and Claude Code itself.*
