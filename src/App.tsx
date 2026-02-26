import { useState } from "react";
import { Sidebar } from "./components/layout/Sidebar";
import { Header } from "./components/layout/Header";
import { StatusBar } from "./components/layout/StatusBar";
import { Timeline } from "./components/timeline/Timeline";
import { FeatureList } from "./components/features/FeatureList";
import { FunctionTree } from "./components/functions/FunctionTree";
import { PromptExplorer } from "./components/prompts/PromptExplorer";
import { Dashboard } from "./components/analytics/Dashboard";
import { EmptyState } from "./components/shared/EmptyState";
import { useProjectStore } from "./store/projectStore";
import type { ViewType } from "./lib/constants";

export default function App() {
  const [view, setView] = useState<ViewType>("timeline");
  const activeProject = useProjectStore((s) => s.activeProject);

  return (
    <div className="flex h-full w-full bg-[var(--color-surface-0)] text-[var(--color-text-primary)]">
      <Sidebar currentView={view} onViewChange={setView} />

      <div className="flex flex-1 flex-col min-w-0">
        <Header />

        <main className="flex-1 overflow-auto">
          {!activeProject ? (
            <EmptyState />
          ) : (
            <>
              {view === "timeline" && <Timeline />}
              {view === "features" && <FeatureList />}
              {view === "functions" && <FunctionTree />}
              {view === "prompts" && <PromptExplorer />}
              {view === "analytics" && <Dashboard />}
            </>
          )}
        </main>

        <StatusBar />
      </div>
    </div>
  );
}
