import { useMemo, useState } from "react";
import { useProjectStore } from "../../store/projectStore";
import { useProject } from "../../hooks/useProject";
import { cn } from "../../lib/utils";
import type { PromptSession } from "../../lib/types";

type GroupBy = "hour" | "day" | "week" | "month";

function getGroupKey(timestamp: string, groupBy: GroupBy): string {
  const d = new Date(timestamp);
  switch (groupBy) {
    case "hour": {
      const hour = d.toLocaleDateString(undefined, {
        month: "short",
        day: "numeric",
      });
      const h = d.getHours();
      const ampm = h >= 12 ? "PM" : "AM";
      const h12 = h % 12 || 12;
      return `${hour}, ${h12} ${ampm}`;
    }
    case "day":
      return d.toLocaleDateString(undefined, {
        weekday: "short",
        month: "short",
        day: "numeric",
        year: "numeric",
      });
    case "week": {
      const startOfWeek = new Date(d);
      startOfWeek.setDate(d.getDate() - d.getDay());
      const endOfWeek = new Date(startOfWeek);
      endOfWeek.setDate(startOfWeek.getDate() + 6);
      const fmt = (dt: Date) =>
        dt.toLocaleDateString(undefined, { month: "short", day: "numeric" });
      return `Week of ${fmt(startOfWeek)} - ${fmt(endOfWeek)}`;
    }
    case "month":
      return d.toLocaleDateString(undefined, {
        month: "long",
        year: "numeric",
      });
  }
}

function groupSessions(
  sessions: PromptSession[],
  groupBy: GroupBy
): [string, PromptSession[]][] {
  const groups = new Map<string, PromptSession[]>();
  for (const session of sessions) {
    const key = getGroupKey(session.timestamp, groupBy);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key)!.push(session);
  }
  return Array.from(groups.entries());
}

export function PromptExplorer() {
  const activeProject = useProjectStore((s) => s.activeProject);
  const { refreshSessions, deleteSessions } = useProject();
  const sessions = activeProject?.promptSessions ?? [];

  const [groupBy, setGroupBy] = useState<GroupBy>("day");
  const [cleared, setCleared] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const grouped = useMemo(
    () => groupSessions(sessions, groupBy),
    [sessions, groupBy]
  );

  const handleRefresh = async () => {
    setRefreshing(true);
    await refreshSessions();
    setRefreshing(false);
    setCleared(false);
  };

  const handleDeleteAll = async () => {
    await deleteSessions();
    setShowDeleteConfirm(false);
  };

  if (sessions.length === 0 && !cleared) {
    return (
      <div className="flex h-full flex-col">
        <div className="flex items-center justify-end border-b border-[var(--color-border)] px-4 py-2 gap-2">
          <button
            onClick={handleRefresh}
            disabled={refreshing}
            className="rounded px-2 py-1 text-[11px] text-[var(--color-text-muted)] hover:text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-2)] transition-colors disabled:opacity-50"
          >
            {refreshing ? "Refreshing..." : "Refresh"}
          </button>
        </div>
        <div className="flex flex-1 items-center justify-center">
          <div className="text-center">
            <p className="text-sm text-[var(--color-text-muted)]">
              No prompts detected.
            </p>
            <p className="mt-1 text-xs text-[var(--color-text-muted)]">
              Click Refresh to scan for Claude Code sessions.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-full flex-col">
      {/* Toolbar */}
      <div className="flex items-center justify-between border-b border-[var(--color-border)] px-4 py-2">
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {cleared
            ? "Cleared"
            : `${sessions.length} prompts across ${new Set(sessions.map((s) => s.sessionId)).size} sessions`}
        </span>

        <div className="flex items-center gap-2">
          {/* Group by selector */}
          <div className="flex gap-0.5 rounded-md border border-[var(--color-border)] p-0.5">
            {(["hour", "day", "week", "month"] as const).map((level) => (
              <button
                key={level}
                onClick={() => setGroupBy(level)}
                className={cn(
                  "rounded px-2 py-0.5 text-[11px] capitalize transition-colors",
                  groupBy === level
                    ? "bg-[var(--color-surface-3)] text-[var(--color-text-primary)]"
                    : "text-[var(--color-text-muted)] hover:text-[var(--color-text-secondary)]"
                )}
              >
                {level}
              </button>
            ))}
          </div>

          {/* Refresh */}
          <button
            onClick={handleRefresh}
            disabled={refreshing}
            className="rounded px-2 py-1 text-[11px] text-[var(--color-text-muted)] hover:text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-2)] transition-colors disabled:opacity-50"
          >
            {refreshing ? "..." : "Refresh"}
          </button>

          {/* Clear temp */}
          <button
            onClick={() => setCleared((c) => !c)}
            className="rounded px-2 py-1 text-[11px] text-[var(--color-text-muted)] hover:text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-2)] transition-colors"
          >
            {cleared ? "Restore" : "Clear"}
          </button>

          {/* Delete all */}
          <button
            onClick={() => setShowDeleteConfirm(true)}
            className="rounded px-2 py-1 text-[11px] text-red-400/70 hover:text-red-400 hover:bg-red-400/10 transition-colors"
          >
            Delete All
          </button>
        </div>
      </div>

      {/* Delete confirmation */}
      {showDeleteConfirm && (
        <div className="flex items-center justify-between border-b border-red-500/20 bg-red-500/5 px-4 py-2">
          <span className="text-xs text-red-400">
            This will permanently delete all session JSONL files for this
            project. This cannot be undone.
          </span>
          <div className="flex gap-2">
            <button
              onClick={() => setShowDeleteConfirm(false)}
              className="rounded px-3 py-1 text-[11px] text-[var(--color-text-muted)] hover:bg-[var(--color-surface-2)] transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleDeleteAll}
              className="rounded bg-red-500/20 px-3 py-1 text-[11px] text-red-400 hover:bg-red-500/30 transition-colors"
            >
              Confirm Delete
            </button>
          </div>
        </div>
      )}

      {/* Content */}
      {cleared ? (
        <div className="flex flex-1 items-center justify-center">
          <div className="text-center">
            <p className="text-sm text-[var(--color-text-muted)]">
              Prompts cleared from view.
            </p>
            <p className="mt-1 text-xs text-[var(--color-text-muted)]">
              Click Restore to bring them back, or Refresh to reload from disk.
            </p>
          </div>
        </div>
      ) : (
        <div className="flex-1 overflow-auto">
          {grouped.map(([groupLabel, groupSessions]) => (
            <div key={groupLabel}>
              {/* Group header */}
              <div className="sticky top-0 z-10 border-b border-[var(--color-border)] bg-[var(--color-surface-0)] px-4 py-1.5">
                <span className="text-[11px] font-medium text-[var(--color-text-secondary)]">
                  {groupLabel}
                </span>
                <span className="ml-2 text-[10px] text-[var(--color-text-muted)]">
                  ({groupSessions.length})
                </span>
              </div>

              {/* Prompts in group */}
              <div className="p-4 space-y-2">
                {groupSessions.map((session, idx) => {
                  const key = `${session.sessionId}-${idx}-${session.timestamp}`;
                  const isExpanded = expandedId === key;
                  const truncatedPrompt =
                    session.promptText.length > 200
                      ? session.promptText.slice(0, 200) + "..."
                      : session.promptText;

                  const totalTokens =
                    session.tokenUsage.inputTokens +
                    session.tokenUsage.outputTokens;

                  return (
                    <div
                      key={key}
                      className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] transition-colors hover:border-[var(--color-border-focus)]"
                    >
                      <button
                        onClick={() =>
                          setExpandedId(isExpanded ? null : key)
                        }
                        className="w-full p-4 text-left"
                      >
                        <p
                          className={cn(
                            "text-[13px] text-[var(--color-text-primary)] whitespace-pre-wrap",
                            !isExpanded && "line-clamp-3"
                          )}
                        >
                          {isExpanded ? session.promptText : truncatedPrompt}
                        </p>

                        <div className="mt-2 flex flex-wrap items-center gap-3 text-[11px] text-[var(--color-text-muted)]">
                          {session.model && (
                            <span className="rounded-sm bg-[var(--color-surface-2)] px-1.5 py-0.5 font-mono">
                              {session.model}
                            </span>
                          )}
                          <span>{session.toolCallCount} tool calls</span>
                          <span>
                            {session.filesWritten.length} files written
                          </span>
                          <span>
                            {session.filesTouched.length} files touched
                          </span>
                          {totalTokens > 0 && (
                            <span className="tabular-nums">
                              {totalTokens.toLocaleString()} tokens
                            </span>
                          )}
                          {session.associatedCommitHashes.length > 0 && (
                            <span className="rounded-sm bg-emerald-500/10 px-1.5 py-0.5 text-emerald-400">
                              {session.associatedCommitHashes.length} commit
                              {session.associatedCommitHashes.length !== 1
                                ? "s"
                                : ""}
                            </span>
                          )}
                          {session.associatedFeatureIds.length > 0 && (
                            <span className="rounded-sm bg-blue-500/10 px-1.5 py-0.5 text-blue-400">
                              {session.associatedFeatureIds.length} feature
                              {session.associatedFeatureIds.length !== 1
                                ? "s"
                                : ""}
                            </span>
                          )}
                          <span className="ml-auto text-[var(--color-text-muted)]">
                            {new Date(session.timestamp).toLocaleTimeString(
                              undefined,
                              {
                                hour: "numeric",
                                minute: "2-digit",
                              }
                            )}
                          </span>
                        </div>
                      </button>

                      {isExpanded && (
                        <div className="border-t border-[var(--color-border)] px-4 py-3 space-y-3">
                          {session.filesWritten.length > 0 && (
                            <div>
                              <h4 className="text-[11px] font-medium text-[var(--color-text-secondary)] mb-1">
                                Files Written / Edited
                              </h4>
                              <div className="space-y-0.5">
                                {session.filesWritten.map((file) => (
                                  <p
                                    key={file}
                                    className="truncate text-xs font-mono text-emerald-400/80"
                                  >
                                    {file}
                                  </p>
                                ))}
                              </div>
                            </div>
                          )}

                          {session.filesTouched.filter(
                            (f) => !session.filesWritten.includes(f)
                          ).length > 0 && (
                            <div>
                              <h4 className="text-[11px] font-medium text-[var(--color-text-secondary)] mb-1">
                                Files Read
                              </h4>
                              <div className="space-y-0.5">
                                {session.filesTouched
                                  .filter(
                                    (f) => !session.filesWritten.includes(f)
                                  )
                                  .map((file) => (
                                    <p
                                      key={file}
                                      className="truncate text-xs font-mono text-[var(--color-text-tertiary)]"
                                    >
                                      {file}
                                    </p>
                                  ))}
                              </div>
                            </div>
                          )}

                          {session.associatedCommitHashes.length > 0 && (
                            <div>
                              <h4 className="text-[11px] font-medium text-[var(--color-text-secondary)] mb-1">
                                Associated Commits
                              </h4>
                              <div className="flex flex-wrap gap-1.5">
                                {session.associatedCommitHashes.map((hash) => (
                                  <span
                                    key={hash}
                                    className="rounded-sm bg-[var(--color-surface-2)] px-1.5 py-0.5 text-xs font-mono text-[var(--color-text-tertiary)]"
                                  >
                                    {hash.slice(0, 7)}
                                  </span>
                                ))}
                              </div>
                            </div>
                          )}

                          {session.associatedFeatureIds.length > 0 && (
                            <div>
                              <h4 className="text-[11px] font-medium text-[var(--color-text-secondary)] mb-1">
                                Linked Features
                              </h4>
                              <div className="flex flex-wrap gap-1.5">
                                {session.associatedFeatureIds.map((id) => {
                                  const feature =
                                    activeProject?.features.find(
                                      (f) => f.clusterId === id
                                    );
                                  return (
                                    <span
                                      key={id}
                                      className="rounded-sm bg-blue-500/10 px-1.5 py-0.5 text-xs text-blue-400"
                                    >
                                      {feature
                                        ? feature.title || feature.autoLabel
                                        : `Feature #${id}`}
                                    </span>
                                  );
                                })}
                              </div>
                            </div>
                          )}

                          <div className="flex items-center gap-4 text-[10px] text-[var(--color-text-muted)] pt-1">
                            <span>
                              Session: {session.sessionId.slice(0, 8)}...
                            </span>
                            {session.tokenUsage.cacheReadTokens > 0 && (
                              <span>
                                Cache:{" "}
                                {session.tokenUsage.cacheReadTokens.toLocaleString()}{" "}
                                tokens
                              </span>
                            )}
                            {session.timeEnd && (
                              <span>
                                Duration:{" "}
                                {Math.round(
                                  (new Date(session.timeEnd).getTime() -
                                    new Date(session.timestamp).getTime()) /
                                    1000
                                )}
                                s
                              </span>
                            )}
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
