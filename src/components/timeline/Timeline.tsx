import { useTimeline } from "../../hooks/useTimeline";
import { useTimelineStore } from "../../store/timelineStore";
import { CHANGE_TYPE_COLORS } from "../../lib/constants";
import { cn } from "../../lib/utils";

export function Timeline() {
  const { filteredCommits } = useTimeline();
  const { selectedCommitHash, selectCommit, zoomLevel, setZoomLevel } =
    useTimelineStore();

  const zoomLevels = ["day", "week", "month", "feature"] as const;

  return (
    <div className="flex h-full flex-col">
      <div className="flex items-center justify-between border-b border-[var(--color-border)] px-4 py-2">
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {filteredCommits.length} commits
        </span>
        <div className="flex gap-0.5 rounded-md border border-[var(--color-border)] p-0.5">
          {zoomLevels.map((level) => (
            <button
              key={level}
              onClick={() => setZoomLevel(level)}
              className={cn(
                "rounded px-2 py-0.5 text-[11px] capitalize transition-colors",
                zoomLevel === level
                  ? "bg-[var(--color-surface-3)] text-[var(--color-text-primary)]"
                  : "text-[var(--color-text-muted)] hover:text-[var(--color-text-secondary)]"
              )}
            >
              {level}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 overflow-auto p-4">
        <div className="relative ml-3 border-l border-[var(--color-border-subtle)]">
          {filteredCommits.map((commit) => (
            <button
              key={commit.hash}
              onClick={() => selectCommit(commit.hash)}
              className={cn(
                "group relative flex w-full items-start gap-3 py-2 pl-5 text-left transition-colors hover:bg-[var(--color-surface-1)]",
                selectedCommitHash === commit.hash && "bg-[var(--color-surface-1)]"
              )}
            >
              <div
                className="absolute -left-[5px] top-3 h-2.5 w-2.5 rounded-full border-2 border-[var(--color-surface-0)]"
                style={{
                  backgroundColor:
                    CHANGE_TYPE_COLORS[commit.changeType] ?? "#71717a",
                }}
              />
              <div className="min-w-0 flex-1">
                <p className="truncate text-[13px] text-[var(--color-text-primary)]">
                  {commit.subject}
                </p>
                <div className="mt-0.5 flex items-center gap-2">
                  <span className="text-[11px] text-[var(--color-text-muted)] font-mono">
                    {commit.hash.slice(0, 7)}
                  </span>
                  <span className="text-[11px] text-[var(--color-text-muted)]">
                    {commit.authorName}
                  </span>
                  {commit.isClaudeCode && (
                    <span className="rounded-sm bg-[var(--color-accent-muted)] px-1 py-px text-[10px] text-[var(--color-accent)]">
                      claude
                    </span>
                  )}
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
