import { cn } from "../../lib/utils";
import { VIEWS, type ViewType } from "../../lib/constants";
import { useProject } from "../../hooks/useProject";

const NAV_ITEMS: { key: ViewType; label: string; shortcut: string }[] = [
  { key: VIEWS.TIMELINE, label: "Timeline", shortcut: "1" },
  { key: VIEWS.FEATURES, label: "Features", shortcut: "2" },
  { key: VIEWS.FUNCTIONS, label: "Functions", shortcut: "3" },
  { key: VIEWS.PROMPTS, label: "Prompts", shortcut: "4" },
  { key: VIEWS.INTENT, label: "Intent", shortcut: "5" },
  { key: VIEWS.PATTERNS, label: "Patterns", shortcut: "6" },
  { key: VIEWS.ANALYTICS, label: "Analytics", shortcut: "7" },
];

interface SidebarProps {
  currentView: ViewType;
  onViewChange: (view: ViewType) => void;
}

export function Sidebar({ currentView, onViewChange }: SidebarProps) {
  const { scanRepository } = useProject();

  const handleOpen = async () => {
    try {
      const { open } = await import("@tauri-apps/plugin-dialog");
      const selected = await open({ directory: true });
      if (selected) {
        await scanRepository(selected as string);
      }
    } catch (e) {
      console.error("Dialog error:", e);
    }
  };

  return (
    <aside className="flex w-52 flex-col border-r border-zinc-800 bg-zinc-900/80">
      <div className="flex h-12 items-center px-4 border-b border-zinc-800">
        <span className="text-sm font-semibold tracking-tight text-zinc-100">
          CodeLens
        </span>
      </div>

      <nav className="flex-1 px-2 py-3 space-y-0.5">
        {NAV_ITEMS.map((item) => (
          <button
            key={item.key}
            onClick={() => onViewChange(item.key)}
            className={cn(
              "flex w-full items-center justify-between rounded-md px-3 py-1.5 text-[13px] transition-colors",
              currentView === item.key
                ? "bg-zinc-800 text-zinc-100"
                : "text-zinc-400 hover:bg-zinc-800/50 hover:text-zinc-200"
            )}
          >
            <span>{item.label}</span>
            <kbd className="text-[10px] text-zinc-600 font-mono">
              {item.shortcut}
            </kbd>
          </button>
        ))}
      </nav>

      <div className="border-t border-zinc-800 p-3">
        <button
          onClick={handleOpen}
          className="flex w-full items-center justify-center rounded-md border border-zinc-700 px-3 py-1.5 text-[13px] text-zinc-400 transition-colors hover:border-zinc-600 hover:text-zinc-200"
        >
          Open Repository
        </button>
      </div>
    </aside>
  );
}
