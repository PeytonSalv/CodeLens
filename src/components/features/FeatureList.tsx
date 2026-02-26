import { useState } from "react";
import { useFeatures } from "../../hooks/useFeatures";
import { CHANGE_TYPE_COLORS, CHANGE_TYPE_LABELS } from "../../lib/constants";
import type { ChangeType, Feature } from "../../lib/types";
import { cn, formatNumber } from "../../lib/utils";

export function FeatureList() {
  const { features } = useFeatures();
  const [expandedId, setExpandedId] = useState<number | null>(null);

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
    <div className="flex h-full flex-col">
      <div className="flex items-center justify-between border-b border-[var(--color-border)] px-4 py-2">
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {features.length} features
        </span>
      </div>

      <div className="flex-1 overflow-auto p-4 space-y-2">
        {features.map((feature) => (
          <FeatureCard
            key={feature.clusterId}
            feature={feature}
            isExpanded={expandedId === feature.clusterId}
            onToggle={() =>
              setExpandedId(
                expandedId === feature.clusterId ? null : feature.clusterId
              )
            }
          />
        ))}
      </div>
    </div>
  );
}

function FeatureCard({
  feature,
  isExpanded,
  onToggle,
}: {
  feature: Feature;
  isExpanded: boolean;
  onToggle: () => void;
}) {
  const dominantType = Object.entries(feature.changeTypeDistribution).sort(
    ([, a], [, b]) => b - a
  )[0]?.[0] as ChangeType | undefined;

  const hasSubFeatures = feature.subFeatures && feature.subFeatures.length > 0;

  return (
    <div
      className={cn(
        "rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-1)] transition-colors",
        isExpanded
          ? "border-[var(--color-border-focus)]"
          : "hover:border-[var(--color-border-focus)]"
      )}
    >
      <button onClick={onToggle} className="w-full p-4 text-left">
        <div className="flex items-start justify-between">
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <h3 className="text-sm font-medium text-[var(--color-text-primary)]">
                {feature.title || feature.autoLabel}
              </h3>
              {hasSubFeatures && (
                <span className="rounded-sm bg-[var(--color-accent-muted)] px-1.5 py-0.5 text-[10px] text-[var(--color-accent)]">
                  {feature.subFeatures.length} prompt
                  {feature.subFeatures.length !== 1 ? "s" : ""}
                </span>
              )}
            </div>
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
            +{formatNumber(feature.totalLinesAdded)} / -
            {formatNumber(feature.totalLinesRemoved)}
          </span>
          <span>{feature.functionsTouched.length} functions</span>
          <span>{feature.primaryFiles.length} files</span>
          <span className="ml-auto text-[var(--color-text-muted)]">
            {new Date(feature.timeStart).toLocaleDateString(undefined, {
              month: "short",
              day: "numeric",
              hour: "numeric",
              minute: "2-digit",
            })}
          </span>
        </div>
      </button>

      {/* Sub-features (expanded) */}
      {isExpanded && hasSubFeatures && (
        <div className="border-t border-[var(--color-border)] px-4 py-3">
          <h4 className="text-[11px] font-medium text-[var(--color-text-secondary)] mb-2">
            Sub-features (by prompt)
          </h4>
          <div className="space-y-2">
            {feature.subFeatures.map((sub, idx) => {
              const subType = sub.changeType as ChangeType;
              const color = CHANGE_TYPE_COLORS[subType] ?? "#71717a";

              return (
                <div
                  key={`${sub.sessionId}-${idx}`}
                  className="relative rounded-md border border-[var(--color-border-subtle)] bg-[var(--color-surface-0)] p-3 pl-5"
                >
                  {/* Color indicator */}
                  <div
                    className="absolute left-0 top-0 bottom-0 w-1 rounded-l-md"
                    style={{ backgroundColor: color }}
                  />

                  <p className="text-[12px] text-[var(--color-text-primary)] line-clamp-2">
                    {sub.promptText}
                  </p>

                  <div className="mt-2 flex flex-wrap items-center gap-3 text-[10px] text-[var(--color-text-muted)]">
                    {sub.model && (
                      <span className="rounded-sm bg-[var(--color-surface-2)] px-1 py-px font-mono">
                        {sub.model}
                      </span>
                    )}
                    <span>{sub.commitHashes.length} commits</span>
                    <span>{sub.filesWritten.length} files</span>
                    <span>
                      +{formatNumber(sub.linesAdded)} / -
                      {formatNumber(sub.linesRemoved)}
                    </span>
                    <span className="ml-auto">
                      {new Date(sub.timestamp).toLocaleTimeString(undefined, {
                        hour: "numeric",
                        minute: "2-digit",
                      })}
                    </span>
                  </div>

                  {/* Files written */}
                  {sub.filesWritten.length > 0 && (
                    <div className="mt-2 flex flex-wrap gap-1">
                      {sub.filesWritten.slice(0, 5).map((file) => {
                        const filename = file.split("/").pop() ?? file;
                        return (
                          <span
                            key={file}
                            className="rounded-sm bg-[var(--color-surface-2)] px-1.5 py-0.5 text-[10px] font-mono text-[var(--color-text-tertiary)]"
                            title={file}
                          >
                            {filename}
                          </span>
                        );
                      })}
                      {sub.filesWritten.length > 5 && (
                        <span className="px-1 text-[10px] text-[var(--color-text-muted)]">
                          +{sub.filesWritten.length - 5} more
                        </span>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Primary files (expanded, no sub-features) */}
      {isExpanded && !hasSubFeatures && feature.primaryFiles.length > 0 && (
        <div className="border-t border-[var(--color-border)] px-4 py-3">
          <h4 className="text-[11px] font-medium text-[var(--color-text-secondary)] mb-1">
            Primary Files
          </h4>
          <div className="space-y-0.5">
            {feature.primaryFiles.map((file) => (
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
    </div>
  );
}
