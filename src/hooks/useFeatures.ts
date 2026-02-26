import { useMemo } from "react";
import { useProjectStore } from "../store/projectStore";

export function useFeatures() {
  const activeProject = useProjectStore((s) => s.activeProject);

  const features = useMemo(() => {
    if (!activeProject) return [];
    return [...activeProject.features].sort(
      (a, b) => new Date(b.timeStart).getTime() - new Date(a.timeStart).getTime()
    );
  }, [activeProject]);

  return { features };
}
