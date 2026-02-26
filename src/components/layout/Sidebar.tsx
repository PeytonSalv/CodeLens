import { cn } from "../../lib/utils";
import { VIEWS, type ViewType } from "../../lib/constants";
import { useProjectStore } from "../../store/projectStore";
import { useProject } from "../../hooks/useProject";

const NAV_ITEMS: { key: ViewType; label: string; shortcut: string }[] = [
  { key: VIEWS.TIMELINE, label: "Timeline", shortcut: "1" },
  { key: VIEWS.FEATURES, label: "Features", shortcut: "2" },
  { key: VIEWS.FUNCTIONS, label: "Functions", shortcut: "3" },
  { key: VIEWS.PROMPTS, label: "Prompts", shortcut: "4" },
  { key: VIEWS.ANALYTICS, label: "Analytics", shortcut: "5" },
];

interface SidebarProps {
  currentView: ViewType;
  onViewChange: (view: ViewType) => void;
}

export function Sidebar({ currentView, onViewChange }: SidebarProps) {
  const activeProject = useProjectStore((s) => s.activeProject);
  const { scanRepository } = useProject();

  const handleOpen = async () => {
    const { open } = await import("@tauri-apps/plugin-dialog");
    const selected = await open({ directory: true });
    if (selected) {
      scanRepository(selected);
    }
  };

  return (
    <aside className="flex w-52 flex-col border-r border-[var(--color-border)] bg-[var(--color-surface-1)]">
      <div className="flex h-12 items-center px-4 border-b border-[var(--color-border)] drag-region">
        <span className="text-sm font-semibold tracking-tight no-drag">
          CodeLens
        </span>
      </div>

      <nav className="flex-1 px-2 py-3 space-y-0.5">
        {NAV_ITEMS.map((item) => (
          <button
            key={item.key}
            onClick={() => onViewChange(item.key)}
            disabled={!activeProject}
            className={cn(
              "flex w-full items-center justify-between rounded-md px-3 py-1.5 text-[13px] transition-colors",
              currentView === item.key
                ? "bg-[var(--color-surface-3)] text-[var(--color-text-primary)]"
                : "text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-2)] hover:text-[var(--color-text-primary)]",
              !activeProject && "opacity-40 cursor-not-allowed"
            )}
          >
            <span>{item.label}</span>
            <kbd className="text-[10px] text-[var(--color-text-muted)] font-mono">
              {item.shortcut}
            </kbd>
          </button>
        ))}
      </nav>

      <div className="border-t border-[var(--color-border)] p-3">
        <button
          onClick={handleOpen}
          className="flex w-full items-center justify-center rounded-md border border-[var(--color-border)] px-3 py-1.5 text-[13px] text-[var(--color-text-secondary)] transition-colors hover:border-[var(--color-border-focus)] hover:text-[var(--color-text-primary)]"
        >
          Open Repository
        </button>
      </div>
    </aside>
  );
}
