import { useCallback } from "react";
import { invoke } from "@tauri-apps/api/core";
import { useProjectStore } from "../store/projectStore";
import type { Project, ProjectData, PromptSession } from "../lib/types";

export function useProject() {
  const {
    activeProject,
    setProjects,
    setActiveProject,
    setIsScanning,
    setScanProgress,
  } = useProjectStore();

  const loadProjects = useCallback(async () => {
    try {
      const projects = await invoke<Project[]>("list_projects");
      setProjects(projects);
    } catch (err) {
      console.error("Failed to load projects:", err);
    }
  }, [setProjects]);

  const openProject = useCallback(
    async (projectId: string) => {
      try {
        const data = await invoke<ProjectData>("get_project_data", {
          projectId,
        });
        setActiveProject(data);
      } catch (err) {
        console.error("Failed to open project:", err);
      }
    },
    [setActiveProject]
  );

  const scanRepository = useCallback(
    async (path: string) => {
      setIsScanning(true);
      setScanProgress(0, "Starting scan...");
      try {
        const data = await invoke<ProjectData>("scan_repository", { path });
        setActiveProject(data);
      } catch (err) {
        console.error("Scan failed:", err);
      } finally {
        setIsScanning(false);
      }
    },
    [setIsScanning, setScanProgress, setActiveProject]
  );

  const refreshSessions = useCallback(async () => {
    if (!activeProject) return;
    try {
      const sessions = await invoke<PromptSession[]>("get_sessions", {
        path: activeProject.repository.path,
      });
      setActiveProject({
        ...activeProject,
        promptSessions: sessions,
        analytics: {
          ...activeProject.analytics,
          totalPromptsDetected: sessions.length,
        },
      });
    } catch (err) {
      console.error("Failed to refresh sessions:", err);
    }
  }, [activeProject, setActiveProject]);

  const deleteSessions = useCallback(async () => {
    if (!activeProject) return;
    try {
      const deleted = await invoke<number>("delete_sessions", {
        path: activeProject.repository.path,
      });
      console.log(`Deleted ${deleted} session files`);
      setActiveProject({
        ...activeProject,
        promptSessions: [],
        analytics: {
          ...activeProject.analytics,
          totalPromptsDetected: 0,
        },
      });
    } catch (err) {
      console.error("Failed to delete sessions:", err);
    }
  }, [activeProject, setActiveProject]);

  return {
    loadProjects,
    openProject,
    scanRepository,
    refreshSessions,
    deleteSessions,
  };
}
