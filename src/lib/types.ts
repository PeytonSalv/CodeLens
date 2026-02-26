export type ChangeType =
  | "new_feature"
  | "bug_fix"
  | "refactor"
  | "performance"
  | "style"
  | "test"
  | "documentation";

export interface Project {
  id: string;
  name: string;
  path: string;
  lastScanned: string;
  totalCommits: number;
  totalFeatures: number;
  claudeCodePercentage: number;
}

export interface Commit {
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

export interface FileChange {
  path: string;
  linesAdded: number;
  linesRemoved: number;
  functions: FunctionChange[];
}

export interface FunctionChange {
  name: string;
  linesAdded: number;
  linesRemoved: number;
  diffText: string;
}

export interface Feature {
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
  subFeatures: SubFeature[];
}

export interface SubFeature {
  promptText: string;
  sessionId: string;
  promptIndex: number;
  timestamp: string;
  timeEnd: string | null;
  commitHashes: string[];
  filesWritten: string[];
  linesAdded: number;
  linesRemoved: number;
  changeType: ChangeType;
  model: string | null;
}

export interface PromptSession {
  sessionId: string;
  promptText: string;
  timestamp: string;
  associatedCommitHashes: string[];
  associatedFeatureIds: number[];
  similarityScore: number;
  scopeMatch: number;
  intent: string | null;
  filesTouched: string[];
  filesWritten: string[];
  toolCallCount: number;
  model: string | null;
  tokenUsage: TokenUsage;
  timeEnd: string | null;
}

export interface TokenUsage {
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
}

export interface Analytics {
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

export interface ProjectData {
  repository: {
    path: string;
    name: string;
    totalCommits: number;
    dateRange: { start: string; end: string };
    languagesDetected: string[];
  };
  commits: Commit[];
  features: Feature[];
  promptSessions: PromptSession[];
  analytics: Analytics;
}

export interface ScanProgress {
  stage: string;
  progress: number;
  message: string;
}
