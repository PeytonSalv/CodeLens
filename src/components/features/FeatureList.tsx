import { useFeatures } from "../../hooks/useFeatures";
import { CHANGE_TYPE_COLORS, CHANGE_TYPE_LABELS } from "../../lib/constants";
import type { ChangeType } from "../../lib/types";
import { formatNumber } from "../../lib/utils";

export function FeatureList() {
  const { features } = useFeatures();

  if (features.length === 0) {
    return (
      <div className="flex h-full items-center justify-center">
        <p className="text-sm text-[var(--color-text-muted)]">
          No features detected yet.
        </p>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-2">
      {features.map((feature) => {
        const dominantType = Object.entries(
          feature.changeTypeDistribution
        ).sort(([, a], [, b]) => b - a)[0]?.[0] as ChangeType | undefined;

        return (
          <div
            key={feature.clusterId}
            className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] p-4 transition-colors hover:border-[var(--color-border-focus)]"
          >
            <div className="flex items-start justify-between">
              <div className="min-w-0 flex-1">
                <h3 className="text-sm font-medium text-[var(--color-text-primary)]">
                  {feature.title || feature.autoLabel}
                </h3>
                {feature.narrative && (
                  <p className="mt-1 text-xs text-[var(--color-text-tertiary)] line-clamp-2">
                    {feature.narrative}
                  </p>
                )}
              </div>
              {dominantType && (
                <span
                  className="ml-3 shrink-0 rounded-sm px-1.5 py-0.5 text-[10px] font-medium"
                  style={{
                    color: CHANGE_TYPE_COLORS[dominantType],
                    backgroundColor: CHANGE_TYPE_COLORS[dominantType] + "18",
                  }}
                >
                  {CHANGE_TYPE_LABELS[dominantType]}
                </span>
              )}
            </div>

            <div className="mt-3 flex items-center gap-4 text-[11px] text-[var(--color-text-muted)]">
              <span>{feature.commitHashes.length} commits</span>
              <span>
                +{formatNumber(feature.totalLinesAdded)} / -{formatNumber(feature.totalLinesRemoved)}
              </span>
              <span>{feature.functionsTouched.length} functions</span>
              <span>{feature.primaryFiles.length} files</span>
            </div>
          </div>
        );
      })}
    </div>
  );
}
