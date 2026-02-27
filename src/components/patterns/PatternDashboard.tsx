import { useProjectStore } from "../../store/projectStore";
import { ProfileCard } from "./ProfileCard";
import type { Commit } from "../../lib/types";

export function PatternDashboard() {
  const activeProject = useProjectStore((s) => s.activeProject);

  if (!activeProject) return null;

  const { commits, analytics, promptSessions } = activeProject;

  // Compute patterns from available data
  const hourCounts = computeHourDistribution(commits);
  const dayCounts = computeDayDistribution(commits);
  const fileCouplings = computeFileCouplings(commits);
  const peakHours = findPeakHours(hourCounts, 3);
  const avgGranularity = computeAvgGranularity(commits);

  const dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const maxHourCount = Math.max(...hourCounts, 1);
  const maxDayCount = Math.max(...dayCounts, 1);

  return (
    <div className="p-4 space-y-6">
      {/* Profile Card */}
      <ProfileCard
        languages={activeProject.repository.languagesDetected}
        peakHours={peakHours}
        avgGranularity={avgGranularity}
        totalCommits={commits.length}
        totalSessions={promptSessions.length}
        claudePercentage={analytics.claudeCodeCommitPercentage}
      />

      <div className="grid grid-cols-2 gap-3">
        {/* Hour Heatmap */}
        <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4">
          <h3 className="text-xs font-medium text-[var(--color-text-secondary)] mb-3">
            Commit Activity by Hour
          </h3>
          <div className="grid grid-cols-12 gap-1">
            {hourCounts.map((count, hour) => {
              const intensity = count / maxHourCount;
              return (
                <div key={hour} className="flex flex-col items-center gap-1">
                  <div
                    className="w-full aspect-square rounded-sm"
                    style={{
                      backgroundColor: `rgba(52, 211, 153, ${Math.max(
                        intensity,
                        0.05
                      )})`,
                    }}
                    title={`${hour}:00 — ${count} commits`}
                  />
                  {hour % 3 === 0 && (
                    <span className="text-[9px] text-[var(--color-text-muted)]">
                      {hour}
                    </span>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Day Distribution */}
        <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4">
          <h3 className="text-xs font-medium text-[var(--color-text-secondary)] mb-3">
            Commit Activity by Day
          </h3>
          <div className="space-y-1.5">
            {dayCounts.map((count, day) => (
              <div key={day} className="flex items-center gap-2">
                <span className="text-[10px] text-[var(--color-text-muted)] w-6">
                  {dayLabels[day]}
                </span>
                <div className="flex-1 h-4 rounded-sm bg-[var(--color-surface-2)] overflow-hidden">
                  <div
                    className="h-full rounded-sm bg-[#60a5fa]"
                    style={{
                      width: `${(count / maxDayCount) * 100}%`,
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

      {/* File Couplings */}
      <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4">
        <h3 className="text-xs font-medium text-[var(--color-text-secondary)] mb-3">
          File Couplings (frequently co-edited)
        </h3>
        {fileCouplings.length === 0 ? (
          <p className="text-xs text-[var(--color-text-muted)] italic">
            No significant file couplings detected.
          </p>
        ) : (
          <div className="space-y-1">
            {fileCouplings.slice(0, 15).map(([a, b, count], i) => (
              <div
                key={i}
                className="flex items-center gap-2 text-xs font-mono"
              >
                <span className="text-[var(--color-text-tertiary)] truncate flex-1">
                  {a}
                </span>
                <span className="text-[var(--color-text-muted)] shrink-0">
                  &harr;
                </span>
                <span className="text-[var(--color-text-tertiary)] truncate flex-1">
                  {b}
                </span>
                <span className="text-[10px] text-[var(--color-text-muted)] tabular-nums shrink-0">
                  {count}x
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function computeHourDistribution(commits: Commit[]): number[] {
  const counts = new Array(24).fill(0);
  for (const commit of commits) {
    try {
      const date = new Date(commit.timestamp);
      counts[date.getHours()]++;
    } catch {
      // skip invalid timestamps
    }
  }
  return counts;
}

function computeDayDistribution(commits: Commit[]): number[] {
  const counts = new Array(7).fill(0);
  for (const commit of commits) {
    try {
      const date = new Date(commit.timestamp);
      // JS: 0=Sun, convert to 0=Mon
      const day = (date.getDay() + 6) % 7;
      counts[day]++;
    } catch {
      // skip
    }
  }
  return counts;
}

function computeFileCouplings(
  commits: Commit[]
): [string, string, number][] {
  const pairCounts = new Map<string, number>();

  for (const commit of commits) {
    const files = commit.filesChanged.map((f) => f.path).sort();
    for (let i = 0; i < files.length; i++) {
      for (let j = i + 1; j < files.length; j++) {
        const key = `${files[i]}|||${files[j]}`;
        pairCounts.set(key, (pairCounts.get(key) || 0) + 1);
      }
    }
  }

  return [...pairCounts.entries()]
    .filter(([_, count]) => count >= 3)
    .sort((a, b) => b[1] - a[1])
    .map(([key, count]) => {
      const [a, b] = key.split("|||");
      return [a, b, count];
    });
}

function findPeakHours(hourCounts: number[], n: number): number[] {
  return hourCounts
    .map((count, hour) => ({ hour, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, n)
    .filter((h) => h.count > 0)
    .map((h) => h.hour)
    .sort((a, b) => a - b);
}

function computeAvgGranularity(commits: Commit[]): number {
  if (commits.length === 0) return 0;
  const totalFiles = commits.reduce(
    (sum, c) => sum + c.filesChanged.length,
    0
  );
  return Math.round((totalFiles / commits.length) * 10) / 10;
}
