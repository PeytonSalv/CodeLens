import type { ChangeType } from "./types";

export const CHANGE_TYPE_COLORS: Record<ChangeType, string> = {
  new_feature: "#34d399",
  bug_fix: "#f87171",
  refactor: "#60a5fa",
  performance: "#fbbf24",
  style: "#71717a",
  test: "#a78bfa",
  documentation: "#2dd4bf",
};

export const CHANGE_TYPE_LABELS: Record<ChangeType, string> = {
  new_feature: "Feature",
  bug_fix: "Bug Fix",
  refactor: "Refactor",
  performance: "Performance",
  style: "Style",
  test: "Test",
  documentation: "Docs",
};

export const VIEWS = {
  TIMELINE: "timeline",
  FEATURES: "features",
  FUNCTIONS: "functions",
  PROMPTS: "prompts",
  ANALYTICS: "analytics",
} as const;

export type ViewType = (typeof VIEWS)[keyof typeof VIEWS];
