import { useMemo } from "react";
import { useProjectStore } from "../store/projectStore";
import { useTimelineStore } from "../store/timelineStore";
import type { Commit } from "../lib/types";

export function useTimeline() {
  const activeProject = useProjectStore((s) => s.activeProject);
  const { filterAuthor, filterChangeTypes, filterDateRange, filterClaudeOnly } =
    useTimelineStore();

  const filteredCommits = useMemo(() => {
    if (!activeProject) return [];

    return activeProject.commits.filter((commit: Commit) => {
      if (filterAuthor && commit.authorName !== filterAuthor) return false;
      if (
        filterChangeTypes.length > 0 &&
        !filterChangeTypes.includes(commit.changeType)
      )
        return false;
      if (filterClaudeOnly && !commit.isClaudeCode) return false;
      if (filterDateRange.start && commit.timestamp < filterDateRange.start)
        return false;
      if (filterDateRange.end && commit.timestamp > filterDateRange.end)
        return false;
      return true;
    });
  }, [
    activeProject,
    filterAuthor,
    filterChangeTypes,
    filterClaudeOnly,
    filterDateRange,
  ]);

  return { filteredCommits };
}
