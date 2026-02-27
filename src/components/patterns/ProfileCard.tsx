interface ProfileCardProps {
  languages: string[];
  peakHours: number[];
  avgGranularity: number;
  totalCommits: number;
  totalSessions: number;
  claudePercentage: number;
}

export function ProfileCard({
  languages,
  peakHours,
  avgGranularity,
  totalCommits,
  totalSessions,
  claudePercentage,
}: ProfileCardProps) {
  return (
    <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4">
      <h3 className="text-xs font-medium text-[var(--color-text-secondary)] mb-3">
        Developer Profile
      </h3>
      <div className="grid grid-cols-3 gap-4">
        <div>
          <p className="text-[10px] text-[var(--color-text-muted)] mb-1">
            Languages
          </p>
          <div className="flex flex-wrap gap-1">
            {languages.slice(0, 6).map((lang) => (
              <span
                key={lang}
                className="text-[10px] px-1.5 py-0.5 rounded bg-[var(--color-surface-2)] text-[var(--color-text-tertiary)]"
              >
                {lang}
              </span>
            ))}
          </div>
        </div>
        <div>
          <p className="text-[10px] text-[var(--color-text-muted)] mb-1">
            Peak Hours
          </p>
          <p className="text-sm font-medium text-[var(--color-text-primary)]">
            {peakHours.length > 0
              ? peakHours.map((h) => `${h}:00`).join(", ")
              : "—"}
          </p>
        </div>
        <div>
          <p className="text-[10px] text-[var(--color-text-muted)] mb-1">
            Commit Granularity
          </p>
          <p className="text-sm font-medium text-[var(--color-text-primary)]">
            {avgGranularity} files/commit
          </p>
        </div>
        <div>
          <p className="text-[10px] text-[var(--color-text-muted)] mb-1">
            Total Commits
          </p>
          <p className="text-sm font-medium text-[var(--color-text-primary)]">
            {totalCommits.toLocaleString()}
          </p>
        </div>
        <div>
          <p className="text-[10px] text-[var(--color-text-muted)] mb-1">
            Claude Sessions
          </p>
          <p className="text-sm font-medium text-[var(--color-text-primary)]">
            {totalSessions.toLocaleString()}
          </p>
        </div>
        <div>
          <p className="text-[10px] text-[var(--color-text-muted)] mb-1">
            Claude Code %
          </p>
          <p className="text-sm font-medium text-[var(--color-text-primary)]">
            {Math.round(claudePercentage * 100)}%
          </p>
        </div>
      </div>
    </div>
  );
}
