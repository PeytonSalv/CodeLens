import { useProjectStore } from "../../store/projectStore";

export function Header() {
  const activeProject = useProjectStore((s) => s.activeProject);

  return (
    <header className="flex h-12 items-center justify-between border-b border-[var(--color-border)] px-4 bg-[var(--color-surface-1)]">
      <div className="flex items-center gap-3">
        {activeProject && (
          <>
            <span className="text-sm font-medium">
              {activeProject.repository.name}
            </span>
            <span className="text-xs text-[var(--color-text-tertiary)]">
              {activeProject.repository.totalCommits} commits
            </span>
          </>
        )}
      </div>

      <div className="flex items-center gap-2">
        <div className="relative">
          <input
            type="text"
            placeholder="Search..."
            className="h-7 w-56 rounded-md border border-[var(--color-border)] bg-[var(--color-surface-0)] px-2.5 text-xs text-[var(--color-text-primary)] placeholder:text-[var(--color-text-muted)] focus:border-[var(--color-border-focus)] focus:outline-none"
          />
          <kbd className="absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-[var(--color-text-muted)] font-mono">
            /
          </kbd>
        </div>
      </div>
    </header>
  );
}
