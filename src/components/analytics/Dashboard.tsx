import { useProjectStore } from "../../store/projectStore";
import { formatNumber } from "../../lib/utils";

export function Dashboard() {
  const activeProject = useProjectStore((s) => s.activeProject);

  if (!activeProject) return null;

  const { analytics } = activeProject;

  const stats = [
    { label: "Features", value: formatNumber(analytics.totalFeatures) },
    { label: "Functions Modified", value: formatNumber(analytics.totalFunctionsModified) },
    { label: "Prompts Detected", value: formatNumber(analytics.totalPromptsDetected) },
    {
      label: "Claude Code",
      value: `${Math.round(analytics.claudeCodeCommitPercentage * 100)}%`,
    },
    {
      label: "Avg Match",
      value: `${Math.round(analytics.avgPromptSimilarity * 100)}%`,
    },
  ];

  return (
    <div className="p-4 space-y-6">
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

      <div className="grid grid-cols-2 gap-3">
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
