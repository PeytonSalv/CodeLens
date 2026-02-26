import { useProjectStore } from "../../store/projectStore";

export function Header() {
  const activeProject = useProjectStore((s) => s.activeProject);

  return (
    <header className="flex h-12 items-center justify-between border-b border-zinc-800 px-4 bg-zinc-900/80">
      <div className="flex items-center gap-3">
        {activeProject ? (
          <>
            <span className="text-sm font-medium text-zinc-100">
              {activeProject.repository.name}
            </span>
            <span className="text-xs text-zinc-500">
              {activeProject.repository.totalCommits} commits
            </span>
          </>
        ) : (
          <span className="text-sm text-zinc-500">No project open</span>
        )}
      </div>

      <div className="relative">
        <input
          type="text"
          placeholder="Search..."
          className="h-7 w-56 rounded-md border border-zinc-700 bg-zinc-950 px-2.5 text-xs text-zinc-200 placeholder:text-zinc-600 focus:border-zinc-500 focus:outline-none"
        />
        <kbd className="absolute right-2 top-1/2 -translate-y-1/2 text-[10px] text-zinc-600 font-mono">
          /
        </kbd>
      </div>
    </header>
  );
}
