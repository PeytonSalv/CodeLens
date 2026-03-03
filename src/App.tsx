import { useState } from "react";
import { Sidebar } from "./components/layout/Sidebar";
import { Header } from "./components/layout/Header";
import { StatusBar } from "./components/layout/StatusBar";
import { EmptyState } from "./components/shared/EmptyState";
import { Timeline } from "./components/timeline/Timeline";
import { Explorer } from "./components/explorer";
import { PromptExplorer } from "./components/prompts/PromptExplorer";
import { Dashboard } from "./components/analytics/Dashboard";
import { IntentDashboard } from "./components/intent/IntentDashboard";
import { PatternDashboard } from "./components/patterns/PatternDashboard";
import { Profile } from "./components/explorer/Profile";
import { LoadingSpinner } from "./components/shared/LoadingSpinner";
import { ScorePage } from "./components/score/ScorePage";
import { useProjectStore } from "./store/projectStore";
import { useProject } from "./hooks/useProject";
import { VIEWS, type ViewType } from "./lib/constants";

export default function App() {
  const [mode, setMode] = useState<"score" | "details">("score");
  const [view, setView] = useState<ViewType>("timeline");
  const activeProject = useProjectStore((s) => s.activeProject);
  const isScanning = useProjectStore((s) => s.isScanning);
  const scanProgress = useProjectStore((s) => s.scanProgress);
  const scanMessage = useProjectStore((s) => s.scanMessage);

  // Activate auto-refresh polling when a project is open
  useProject();

  if (mode === "score") {
    return <ScorePage onShowDetails={() => setMode("details")} />;
  }

  const renderView = () => {
    switch (view) {
      case VIEWS.TIMELINE:
        return <Timeline />;
      case VIEWS.EXPLORER:
        return <Explorer />;
      case VIEWS.PROMPTS:
        return <PromptExplorer />;
      case VIEWS.INTENT:
        return <IntentDashboard />;
      case VIEWS.PATTERNS:
        return <PatternDashboard />;
      case VIEWS.ANALYTICS:
        return <Dashboard />;
      case VIEWS.PROFILE:
        return <Profile />;
      default:
        return <Timeline />;
    }
  };

  return (
    <div className="flex h-screen w-screen bg-zinc-950 text-zinc-50 font-sans">
      <Sidebar
        currentView={view}
        onViewChange={setView}
        onBackToScore={() => setMode("score")}
      />

      <div className="flex flex-1 flex-col min-w-0">
        <Header />

        <main className="relative flex-1 overflow-auto">
          {!activeProject ? <EmptyState /> : renderView()}

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

        <StatusBar />
      </div>
    </div>
  );
}
