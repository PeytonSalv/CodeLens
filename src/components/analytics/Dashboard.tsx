import { useProjectStore } from "../../store/projectStore";
import { formatNumber } from "../../lib/utils";
import { CHANGE_TYPE_COLORS, CHANGE_TYPE_LABELS } from "../../lib/constants";
import type { ChangeType } from "../../lib/types";

export function Dashboard() {
  const activeProject = useProjectStore((s) => s.activeProject);

  if (!activeProject) return null;

  const { analytics, commits, promptSessions } = activeProject;

  // Compute additional metrics from prompt sessions
  const completedPrompts = promptSessions.filter(
    (s) => s.filesWritten.length > 0
  ).length;
  const intentCompletion =
    analytics.avgIntentCompletion ??
    (promptSessions.length > 0
      ? completedPrompts / promptSessions.length
      : 0);
  const repromptRate = analytics.repromptRate ?? 0;
  const embeddingCoverage = analytics.embeddingCoverage ?? 0;

  const stats = [
    { label: "Features", value: formatNumber(analytics.totalFeatures) },
    {
      label: "Functions Modified",
      value: formatNumber(analytics.totalFunctionsModified),
    },
    {
      label: "Prompts Detected",
      value: formatNumber(analytics.totalPromptsDetected),
    },
    {
      label: "Claude Code",
      value: `${Math.round(analytics.claudeCodeCommitPercentage * 100)}%`,
    },
    {
      label: "Avg Match",
      value: `${Math.round(analytics.avgPromptSimilarity * 100)}%`,
    },
  ];

  const mlStats = [
    {
      label: "Intent Completion",
      value: `${Math.round(intentCompletion * 100)}%`,
      description: "Prompts that led to file changes",
    },
    {
      label: "Re-prompt Rate",
      value: `${Math.round(repromptRate * 100)}%`,
      description: "Consecutive prompts on same topic",
    },
    {
      label: "Patterns Found",
      value: formatNumber(analytics.patternCount ?? 0),
      description: "Detected behavioral patterns",
    },
    {
      label: "ML Coverage",
      value: `${Math.round(embeddingCoverage * 100)}%`,
      description: "Commits with embeddings",
    },
  ];

  // Velocity chart data
  const velocity = analytics.velocityByWeek.slice(-12);
  const maxCommits = Math.max(
    ...velocity.map((v) => v.commits),
    1
  );

  // Change type breakdown
  const changeTypes = Object.entries(analytics.changeTypeTotals).sort(
    (a, b) => b[1] - a[1]
  ) as [ChangeType, number][];
  const totalChangeCommits = changeTypes.reduce(
    (sum, [_, count]) => sum + count,
    0
  );

  return (
    <div className="p-4 space-y-6">
      {/* Primary Stats */}
      <div className="grid grid-cols-5 gap-3">
        {stats.map((stat) => (
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

      {/* ML Stats */}
      <div className="grid grid-cols-4 gap-3">
        {mlStats.map((stat) => (
          <div
            key={stat.label}
            className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4"
          >
            <p className="text-xl font-semibold tracking-tight text-[var(--color-text-primary)]">
              {stat.value}
            </p>
            <p className="mt-1 text-[11px] text-[var(--color-text-muted)]">
              {stat.label}
            </p>
            <p className="mt-0.5 text-[10px] text-[var(--color-text-muted)] opacity-60">
              {stat.description}
            </p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-3">
        {/* Velocity Chart */}
        <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4">
          <h3 className="text-xs font-medium text-[var(--color-text-secondary)] mb-3">
            Velocity (last 12 weeks)
          </h3>
          {velocity.length > 0 ? (
            <div className="flex items-end gap-1 h-24">
              {velocity.map((week) => (
                <div
                  key={week.week}
                  className="flex-1 flex flex-col items-center gap-0.5"
                >
                  <div
                    className="w-full rounded-sm bg-[#34d399]"
                    style={{
                      height: `${(week.commits / maxCommits) * 100}%`,
                      minHeight: week.commits > 0 ? "2px" : "0",
                    }}
                    title={`${week.week}: ${week.commits} commits, ${week.features} features`}
                  />
                </div>
              ))}
            </div>
          ) : (
            <p className="text-xs text-[var(--color-text-muted)] italic">
              No velocity data available
            </p>
          )}
        </div>

        {/* Change Type Distribution */}
        <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4">
          <h3 className="text-xs font-medium text-[var(--color-text-secondary)] mb-3">
            Change Type Distribution
          </h3>
          <div className="space-y-1.5">
            {changeTypes.map(([type, count]) => (
              <div key={type} className="flex items-center gap-2">
                <div
                  className="w-2 h-2 rounded-full shrink-0"
                  style={{
                    backgroundColor:
                      CHANGE_TYPE_COLORS[type] || "#71717a",
                  }}
                />
                <span className="text-xs text-[var(--color-text-tertiary)] flex-1">
                  {CHANGE_TYPE_LABELS[type] || type}
                </span>
                <div className="w-24 h-2 rounded-sm bg-[var(--color-surface-2)] overflow-hidden">
                  <div
                    className="h-full rounded-sm"
                    style={{
                      width: `${(count / totalChangeCommits) * 100}%`,
                      backgroundColor:
                        CHANGE_TYPE_COLORS[type] || "#71717a",
                    }}
                  />
                </div>
                <span className="text-[10px] text-[var(--color-text-muted)] tabular-nums w-6 text-right">
                  {count}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {/* Most Modified Files */}
        <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4">
          <h3 className="text-xs font-medium text-[var(--color-text-secondary)] mb-3">
            Most Modified Files
          </h3>
          <div className="space-y-1.5">
            {analytics.mostModifiedFiles.slice(0, 8).map((file) => (
              <p
                key={file}
                className="truncate text-xs font-mono text-[var(--color-text-tertiary)]"
              >
                {file}
              </p>
            ))}
          </div>
        </div>

        {/* Most Modified Functions */}
        <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4">
          <h3 className="text-xs font-medium text-[var(--color-text-secondary)] mb-3">
            Most Modified Functions
          </h3>
          <div className="space-y-1.5">
            {analytics.mostModifiedFunctions.slice(0, 8).map((fn) => (
              <p
                key={fn}
                className="truncate text-xs font-mono text-[var(--color-text-tertiary)]"
              >
                {fn}
              </p>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
