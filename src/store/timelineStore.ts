import { create } from "zustand";
import type { ChangeType } from "../lib/types";

type ZoomLevel = "day" | "week" | "month" | "feature";

interface TimelineState {
  zoomLevel: ZoomLevel;
  selectedCommitHash: string | null;
  selectedFeatureId: number | null;
  filterAuthor: string | null;
  filterChangeTypes: ChangeType[];
  filterDateRange: { start: string | null; end: string | null };
  filterClaudeOnly: boolean;
  setZoomLevel: (level: ZoomLevel) => void;
  selectCommit: (hash: string | null) => void;
  selectFeature: (id: number | null) => void;
  setFilterAuthor: (author: string | null) => void;
  setFilterChangeTypes: (types: ChangeType[]) => void;
  setFilterDateRange: (start: string | null, end: string | null) => void;
  setFilterClaudeOnly: (only: boolean) => void;
  resetFilters: () => void;
}

export const useTimelineStore = create<TimelineState>((set) => ({
  zoomLevel: "week",
  selectedCommitHash: null,
  selectedFeatureId: null,
  filterAuthor: null,
  filterChangeTypes: [],
  filterDateRange: { start: null, end: null },
  filterClaudeOnly: false,
  setZoomLevel: (level) => set({ zoomLevel: level }),
  selectCommit: (hash) => set({ selectedCommitHash: hash }),
  selectFeature: (id) => set({ selectedFeatureId: id }),
  setFilterAuthor: (author) => set({ filterAuthor: author }),
  setFilterChangeTypes: (types) => set({ filterChangeTypes: types }),
  setFilterDateRange: (start, end) =>
    set({ filterDateRange: { start, end } }),
  setFilterClaudeOnly: (only) => set({ filterClaudeOnly: only }),
  resetFilters: () =>
    set({
      filterAuthor: null,
      filterChangeTypes: [],
      filterDateRange: { start: null, end: null },
      filterClaudeOnly: false,
    }),
}));
