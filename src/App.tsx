import { useState } from "react";
import { Sidebar } from "./components/layout/Sidebar";
import { Header } from "./components/layout/Header";
import { StatusBar } from "./components/layout/StatusBar";
import { EmptyState } from "./components/shared/EmptyState";
import { Timeline } from "./components/timeline/Timeline";
import { FeatureList } from "./components/features/FeatureList";
import { FunctionTree } from "./components/functions/FunctionTree";
import { PromptExplorer } from "./components/prompts/PromptExplorer";
import { Dashboard } from "./components/analytics/Dashboard";
import { IntentDashboard } from "./components/intent/IntentDashboard";
import { PatternDashboard } from "./components/patterns/PatternDashboard";
import { useProjectStore } from "./store/projectStore";
import { VIEWS, type ViewType } from "./lib/constants";

export default function App() {
  const [view, setView] = useState<ViewType>("timeline");
  const activeProject = useProjectStore((s) => s.activeProject);

  const renderView = () => {
    switch (view) {
      case VIEWS.TIMELINE:
        return <Timeline />;
      case VIEWS.FEATURES:
        return <FeatureList />;
      case VIEWS.FUNCTIONS:
        return <FunctionTree />;
      case VIEWS.PROMPTS:
        return <PromptExplorer />;
      case VIEWS.INTENT:
        return <IntentDashboard />;
      case VIEWS.PATTERNS:
        return <PatternDashboard />;
      case VIEWS.ANALYTICS:
        return <Dashboard />;
      default:
        return <Timeline />;
    }
  };

  return (
    <div className="flex h-screen w-screen bg-zinc-950 text-zinc-50 font-sans">
      <Sidebar currentView={view} onViewChange={setView} />

      <div className="flex flex-1 flex-col min-w-0">
        <Header />

        <main className="flex-1 overflow-auto">
          {!activeProject ? <EmptyState /> : renderView()}
        </main>

        <StatusBar />
      </div>
    </div>
  );
}
