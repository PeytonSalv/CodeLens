import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { PatternStatus } from "../lib/types";

interface PatternEntry {
  status: PatternStatus;
  updatedAt: number;
}

interface PatternState {
  statuses: Record<string, PatternEntry>;
  setStatus: (id: string, status: PatternStatus) => void;
  getStatus: (id: string) => PatternStatus;
}

export const usePatternStore = create<PatternState>()(
  persist(
    (set, get) => ({
      statuses: {},
      setStatus: (id, status) =>
        set((state) => ({
          statuses: {
            ...state.statuses,
            [id]: { status, updatedAt: Date.now() },
          },
        })),
      getStatus: (id) => get().statuses[id]?.status ?? "detected",
    }),
    { name: "codelens-patterns" }
  )
);
