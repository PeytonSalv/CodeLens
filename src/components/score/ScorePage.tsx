import { useProjectStore } from "../../store/projectStore";
import { useScore } from "../../hooks/useScore";
import { usePatterns } from "../../hooks/usePatterns";
import { EmptyState } from "../shared/EmptyState";
import { LoadingSpinner } from "../shared/LoadingSpinner";
import { ScoreHero } from "./ScoreHero";
import { PatternCards } from "./PatternCards";
import { LifetimeStats } from "./LifetimeStats";

interface ScorePageProps {
  onShowDetails: () => void;
}

export function ScorePage({ onShowDetails }: ScorePageProps) {
  const activeProject = useProjectStore((s) => s.activeProject);
  const isScanning = useProjectStore((s) => s.isScanning);
  const scanProgress = useProjectStore((s) => s.scanProgress);
  const scanMessage = useProjectStore((s) => s.scanMessage);
  const { score, weeklyScores } = useScore();
  const patterns = usePatterns();

  return (
    <div className="flex h-screen flex-col bg-zinc-950 text-zinc-50">
      {/* Minimal header */}
      <header className="flex h-12 items-center justify-between border-b border-zinc-800 px-5">
        <span className="text-sm font-semibold tracking-tight text-zinc-100">
          CodeLens
        </span>
        {activeProject && (
          <button
            onClick={onShowDetails}
            className="text-xs text-zinc-500 hover:text-zinc-300 transition-colors"
          >
            Details &rarr;
          </button>
        )}
      </header>

      {/* Content */}
      <main className="relative flex-1 overflow-auto">
        {!activeProject ? (
          <EmptyState />
        ) : score ? (
          <div className="mx-auto max-w-2xl px-6 py-8 space-y-10">
            <ScoreHero score={score} weeklyScores={weeklyScores} />
            <PatternCards patterns={patterns} />
            <LifetimeStats />
          </div>
        ) : null}

        {/* Scan overlay */}
        {isScanning && (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-zinc-950/80 z-50">
            <LoadingSpinner size="md" />
            <p className="mt-3 text-sm text-zinc-400">{scanMessage}</p>
            <div className="mt-2 h-1 w-48 rounded-full bg-zinc-800 overflow-hidden">
              <div
                className="h-full bg-amber-400 transition-all duration-300"
                style={{ width: `${scanProgress * 100}%` }}
              />
            </div>
            <p className="mt-1 text-xs text-zinc-600 font-mono">
              {Math.round(scanProgress * 100)}%
            </p>
          </div>
        )}
      </main>
    </div>
  );
}
