import { create } from "zustand";

interface SettingsState {
  apiKey: string;
  claudeModel: string;
  maxConcurrentApiCalls: number;
  showSettings: boolean;
  setApiKey: (key: string) => void;
  setClaudeModel: (model: string) => void;
  setMaxConcurrentApiCalls: (n: number) => void;
  toggleSettings: () => void;
}

export const useSettingsStore = create<SettingsState>((set) => ({
  apiKey: "",
  claudeModel: "claude-sonnet-4-5-20250929",
  maxConcurrentApiCalls: 5,
  showSettings: false,
  setApiKey: (key) => set({ apiKey: key }),
  setClaudeModel: (model) => set({ claudeModel: model }),
  setMaxConcurrentApiCalls: (n) => set({ maxConcurrentApiCalls: n }),
  toggleSettings: () => set((s) => ({ showSettings: !s.showSettings })),
}));
