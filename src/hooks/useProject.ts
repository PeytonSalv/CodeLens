import { useCallback } from "react";
import { invoke } from "@tauri-apps/api/core";
import { useProjectStore } from "../store/projectStore";
import type { Project, ProjectData } from "../lib/types";

export function useProject() {
  const { setProjects, setActiveProject, setIsScanning, setScanProgress } =
    useProjectStore();

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
        await invoke("scan_repository", { path });
      } catch (err) {
        console.error("Scan failed:", err);
      } finally {
        setIsScanning(false);
      }
    },
    [setIsScanning, setScanProgress]
  );

  return { loadProjects, openProject, scanRepository };
}
