import { useProjectStore } from "../../store/projectStore";

export function PromptExplorer() {
  const activeProject = useProjectStore((s) => s.activeProject);
  const sessions = activeProject?.promptSessions ?? [];

  if (sessions.length === 0) {
    return (
      <div className="flex h-full items-center justify-center">
        <p className="text-sm text-[var(--color-text-muted)]">
          No prompts detected.
        </p>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-2">
      {sessions.map((session) => (
        <div
          key={session.sessionId}
          className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4"
        >
          <p className="text-[13px] text-[var(--color-text-primary)] line-clamp-3">
            {session.promptText}
          </p>
          <div className="mt-2 flex items-center gap-3 text-[11px] text-[var(--color-text-muted)]">
            <span>{session.associatedCommitHashes.length} commits</span>
            <span className="font-mono tabular-nums">
              {Math.round(session.similarityScore * 100)}% match
            </span>
          </div>
        </div>
      ))}
    </div>
  );
}
