import { cn } from "../../lib/utils";
import { usePatternStore } from "../../store/patternStore";
import type { DetectedPattern, PatternSeverity } from "../../lib/types";

function cardStyle(severity: PatternSeverity): string {
  switch (severity) {
    case "positive":
      return "border-emerald-500/30 bg-emerald-500/5";
    case "negative":
      return "border-amber-500/30 bg-amber-500/5";
    case "neutral":
      return "border-zinc-700 bg-zinc-800/50";
  }
}

function badgeStyle(severity: PatternSeverity): string {
  switch (severity) {
    case "positive":
      return "bg-emerald-500/15 text-emerald-400";
    case "negative":
      return "bg-amber-500/15 text-amber-400";
    case "neutral":
      return "bg-zinc-700 text-zinc-400";
  }
}

function severityLabel(severity: PatternSeverity): string {
  switch (severity) {
    case "positive":
      return "Improved";
    case "negative":
      return "Needs attention";
    case "neutral":
      return "Info";
  }
}

interface PatternCardsProps {
  patterns: (DetectedPattern & { storedStatus: string })[];
}

export function PatternCards({ patterns }: PatternCardsProps) {
  const setStatus = usePatternStore((s) => s.setStatus);

  if (patterns.length === 0) {
    return (
      <div className="text-center py-6">
        <p className="text-sm text-zinc-500">
          No patterns detected yet. Keep coding to build up data.
        </p>
      </div>
    );
  }

  // Filter out dismissed patterns
  const visible = patterns.filter((p) => p.storedStatus !== "dismissed");

  return (
    <div className="space-y-4">
      <h2 className="text-xs font-medium text-zinc-500 uppercase tracking-wider">
        Patterns
      </h2>
      <div className="grid gap-3 sm:grid-cols-2">
        {visible.map((pattern) => (
          <div
            key={pattern.id}
            className={cn(
              "rounded-lg border p-4 space-y-3 transition-colors",
              cardStyle(pattern.severity)
            )}
          >
            <div className="flex items-start justify-between gap-2">
              <h3 className="text-sm font-medium text-zinc-100">
                {pattern.title}
              </h3>
              <span
                className={cn(
                  "shrink-0 rounded-full px-2 py-0.5 text-[10px] font-medium",
                  badgeStyle(pattern.severity)
                )}
              >
                {severityLabel(pattern.severity)}
              </span>
            </div>

            <p className="text-xs text-zinc-400 leading-relaxed">
              {pattern.description}
            </p>

            {/* Before → After */}
            <div className="flex items-center gap-3 text-xs">
              <span className="rounded bg-zinc-800 px-2 py-1 font-mono text-zinc-300">
                {pattern.metricBefore}
              </span>
              <span className="text-zinc-600">&rarr;</span>
              <span className="rounded bg-zinc-800 px-2 py-1 font-mono text-zinc-300">
                {pattern.metricAfter}
              </span>
            </div>

            {/* Actions for detected patterns */}
            {pattern.storedStatus === "detected" && (
              <div className="flex gap-2 pt-1">
                <button
                  onClick={() => setStatus(pattern.id, "approved")}
                  className="rounded-md bg-zinc-700 px-3 py-1 text-[11px] text-zinc-200 hover:bg-zinc-600 transition-colors"
                >
                  Track this
                </button>
                <button
                  onClick={() => setStatus(pattern.id, "dismissed")}
                  className="rounded-md px-3 py-1 text-[11px] text-zinc-500 hover:text-zinc-300 transition-colors"
                >
                  Dismiss
                </button>
              </div>
            )}

            {pattern.storedStatus === "approved" && (
              <div className="flex gap-2 pt-1">
                <span className="text-[11px] text-emerald-500/80">Tracking</span>
                <button
                  onClick={() => setStatus(pattern.id, "fixed")}
                  className="rounded-md px-3 py-1 text-[11px] text-zinc-500 hover:text-zinc-300 transition-colors"
                >
                  Mark fixed
                </button>
              </div>
            )}

            {pattern.storedStatus === "fixed" && (
              <span className="text-[11px] text-emerald-400">Fixed</span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
