import { useMemo } from "react";
import { useProjectStore } from "../../store/projectStore";

export function FunctionTree() {
  const activeProject = useProjectStore((s) => s.activeProject);

  const fileTree = useMemo(() => {
    if (!activeProject) return new Map<string, Set<string>>();
    const tree = new Map<string, Set<string>>();
    for (const commit of activeProject.commits) {
      for (const file of commit.filesChanged) {
        if (!tree.has(file.path)) tree.set(file.path, new Set());
        for (const fn of file.functions) {
          tree.get(file.path)!.add(fn.name);
        }
      }
    }
    return tree;
  }, [activeProject]);

  if (fileTree.size === 0) {
    return (
      <div className="flex h-full items-center justify-center">
        <p className="text-sm text-[var(--color-text-muted)]">
          No function data available.
        </p>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-1">
      {Array.from(fileTree.entries()).map(([filePath, functions]) => (
        <div key={filePath}>
          <div className="flex items-center gap-1.5 py-1">
            <span className="text-xs text-[var(--color-text-tertiary)]">
              {filePath}
            </span>
          </div>
          <div className="ml-4 space-y-px">
            {Array.from(functions).map((fn) => (
              <div
                key={fn}
                className="rounded px-2 py-1 text-[13px] font-mono text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-2)] cursor-pointer"
              >
                {fn}
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
