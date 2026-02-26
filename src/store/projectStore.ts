import { create } from "zustand";
import type { Project, ProjectData } from "../lib/types";

interface ProjectState {
  projects: Project[];
  activeProject: ProjectData | null;
  isScanning: boolean;
  scanProgress: number;
  scanMessage: string;
  setProjects: (projects: Project[]) => void;
  setActiveProject: (data: ProjectData | null) => void;
  setScanProgress: (progress: number, message: string) => void;
  setIsScanning: (scanning: boolean) => void;
}

export const useProjectStore = create<ProjectState>((set) => ({
  projects: [],
  activeProject: null,
  isScanning: false,
  scanProgress: 0,
  scanMessage: "",
  setProjects: (projects) => set({ projects }),
  setActiveProject: (data) => set({ activeProject: data }),
  setScanProgress: (progress, message) =>
    set({ scanProgress: progress, scanMessage: message }),
  setIsScanning: (scanning) => set({ isScanning: scanning }),
}));
