import { useState } from "react";
import { useProjectStore } from "../../store/projectStore";
import { cn } from "../../lib/utils";

const OUTCOME_COLORS: Record<string, string> = {
  completed: "#34d399",
  partial: "#fbbf24",
  abandoned: "#f87171",
  reworked: "#60a5fa",
};

const OUTCOME_LABELS: Record<string, string> = {
  completed: "Completed",
  partial: "Partial",
  abandoned: "Abandoned",
  reworked: "Reworked",
};

export function IntentDashboard() {
  const activeProject = useProjectStore((s) => s.activeProject);
  const [expandedIndex, setExpandedIndex] = useState<number | null>(null);

  if (!activeProject) return null;

  const { promptSessions } = activeProject;

  // Compute intent metrics from prompt sessions
  const totalPrompts = promptSessions.length;
  const completedCount = promptSessions.filter(
    (s) => s.filesWritten.length > 0
  ).length;
  const avgToolCalls =
    totalPrompts > 0
      ? promptSessions.reduce((sum, s) => sum + s.toolCallCount, 0) /
        totalPrompts
      : 0;

  // Detect re-prompts (simplified: consecutive prompts in same session with similar text)
  const repromptCount = detectReprompts(promptSessions);

  // Classify outcomes heuristically
  const outcomes = promptSessions.map((session) => {
    const hasWrites = session.filesWritten.length > 0;
    const hasTools = session.toolCallCount > 0;

    if (hasWrites) return "completed";
    if (hasTools) return "partial";
    return "abandoned";
  });

  const outcomeCounts = outcomes.reduce(
    (acc, o) => {
      acc[o] = (acc[o] || 0) + 1;
      return acc;
    },
    {} as Record<string, number>
  );

  const completionRate =
    totalPrompts > 0
      ? ((outcomeCounts["completed"] || 0) / totalPrompts) * 100
      : 0;

  return (
    <div className="p-4 space-y-6">
      {/* Summary Stats */}
      <div className="grid grid-cols-4 gap-3">
        {[
          { label: "Total Prompts", value: totalPrompts },
          {
            label: "Completion Rate",
            value: `${Math.round(completionRate)}%`,
          },
          { label: "Re-prompts", value: repromptCount },
          {
            label: "Avg Tool Calls",
            value: Math.round(avgToolCalls * 10) / 10,
          },
        ].map((stat) => (
          <div
            key={stat.label}
            className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4"
          >
            <p className="text-2xl font-semibold tracking-tight text-[var(--color-text-primary)]">
              {stat.value}
            </p>
            <p className="mt-1 text-[11px] text-[var(--color-text-muted)]">
              {stat.label}
            </p>
          </div>
        ))}
      </div>

      {/* Outcome Distribution */}
      <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4">
        <h3 className="text-xs font-medium text-[var(--color-text-secondary)] mb-3">
          Outcome Distribution
        </h3>
        <div className="flex gap-2">
          {Object.entries(outcomeCounts).map(([outcome, count]) => (
            <div
              key={outcome}
              className="flex items-center gap-2 rounded-md px-3 py-1.5"
              style={{
                backgroundColor: `${OUTCOME_COLORS[outcome]}15`,
                borderLeft: `3px solid ${OUTCOME_COLORS[outcome]}`,
              }}
            >
              <span className="text-sm font-medium text-[var(--color-text-primary)]">
                {count}
              </span>
              <span className="text-xs text-[var(--color-text-muted)]">
                {OUTCOME_LABELS[outcome] || outcome}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Prompt List */}
      <div className="space-y-2">
        <h3 className="text-xs font-medium text-[var(--color-text-secondary)]">
          Prompt Sessions ({totalPrompts})
        </h3>
        {promptSessions.map((session, i) => {
          const outcome = outcomes[i];
          const isExpanded = expandedIndex === i;

          return (
            <div
              key={`${session.sessionId}-${i}`}
              className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] overflow-hidden"
            >
              <button
                onClick={() => setExpandedIndex(isExpanded ? null : i)}
                className="flex w-full items-center gap-3 p-3 text-left hover:bg-[var(--color-surface-2)] transition-colors"
              >
                <div
                  className="w-2 h-2 rounded-full shrink-0"
                  style={{ backgroundColor: OUTCOME_COLORS[outcome] }}
                />
                <p className="flex-1 text-xs text-[var(--color-text-primary)] truncate">
                  {session.promptText}
                </p>
                <span
                  className="text-[10px] px-1.5 py-0.5 rounded font-medium"
                  style={{
                    color: OUTCOME_COLORS[outcome],
                    backgroundColor: `${OUTCOME_COLORS[outcome]}15`,
                  }}
                >
                  {OUTCOME_LABELS[outcome] || outcome}
                </span>
                <span className="text-[10px] text-[var(--color-text-muted)] tabular-nums">
                  {session.toolCallCount} tools
                </span>
                <span className="text-[10px] text-[var(--color-text-muted)] tabular-nums">
                  {session.filesWritten.length} writes
                </span>
              </button>

              {isExpanded && (
                <div className="border-t border-[var(--color-border)] p-3 space-y-2 bg-[var(--color-surface-2)]">
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <p className="text-[10px] text-[var(--color-text-muted)] mb-1">
                        Files Written
                      </p>
                      {session.filesWritten.length > 0 ? (
                        session.filesWritten.map((f) => (
                          <p
                            key={f}
                            className="text-xs font-mono text-[var(--color-text-tertiary)] truncate"
                          >
                            {f}
                          </p>
                        ))
                      ) : (
                        <p className="text-xs text-[var(--color-text-muted)] italic">
                          None
                        </p>
                      )}
                    </div>
                    <div>
                      <p className="text-[10px] text-[var(--color-text-muted)] mb-1">
                        Files Touched
                      </p>
                      {session.filesTouched.slice(0, 8).map((f) => (
                        <p
                          key={f}
                          className="text-xs font-mono text-[var(--color-text-tertiary)] truncate"
                        >
                          {f}
                        </p>
                      ))}
                      {session.filesTouched.length > 8 && (
                        <p className="text-xs text-[var(--color-text-muted)]">
                          +{session.filesTouched.length - 8} more
                        </p>
                      )}
                    </div>
                  </div>
                  <div className="flex gap-4 text-[10px] text-[var(--color-text-muted)]">
                    <span>Session: {session.sessionId.slice(0, 8)}...</span>
                    {session.model && <span>Model: {session.model}</span>}
                    <span>
                      Tokens: {session.tokenUsage.inputTokens.toLocaleString()} in /{" "}
                      {session.tokenUsage.outputTokens.toLocaleString()} out
                    </span>
                  </div>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

/** Detect re-prompts: consecutive prompts in the same session with similar leading text. */
function detectReprompts(
  sessions: Array<{ sessionId: string; promptText: string }>
): number {
  let count = 0;
  for (let i = 1; i < sessions.length; i++) {
    if (sessions[i].sessionId !== sessions[i - 1].sessionId) continue;

    // Simple heuristic: check if prompts share significant overlap
    const a = sessions[i - 1].promptText.toLowerCase().slice(0, 50);
    const b = sessions[i].promptText.toLowerCase().slice(0, 50);

    if (a.length > 10 && b.length > 10) {
      // Check word overlap
      const wordsA = new Set(a.split(/\s+/));
      const wordsB = new Set(b.split(/\s+/));
      const intersection = [...wordsA].filter((w) => wordsB.has(w));
      const overlap = intersection.length / Math.max(wordsA.size, wordsB.size);
      if (overlap > 0.6) count++;
    }
  }
  return count;
}
