import { useProjectStore } from "../../store/projectStore";

export function StatusBar() {
  const { isScanning, scanProgress, scanMessage, activeProject } =
    useProjectStore();

  return (
    <footer className="flex h-6 items-center justify-between border-t border-[var(--color-border)] bg-[var(--color-surface-1)] px-3">
      <div className="flex items-center gap-2">
        {isScanning ? (
          <>
            <div className="h-1.5 w-1.5 rounded-full bg-[var(--color-accent)] animate-pulse" />
            <span className="text-[11px] text-[var(--color-text-tertiary)]">
              {scanMessage}
            </span>
          </>
        ) : (
          <span className="text-[11px] text-[var(--color-text-muted)]">
            {activeProject ? "Ready" : "No project open"}
          </span>
        )}
      </div>

      {isScanning && (
        <div className="flex items-center gap-2">
          <div className="h-1 w-24 overflow-hidden rounded-full bg-[var(--color-surface-3)]">
            <div
              className="h-full rounded-full bg-[var(--color-accent)] transition-all duration-300"
              style={{ width: `${scanProgress * 100}%` }}
            />
          </div>
          <span className="text-[11px] text-[var(--color-text-muted)] font-mono tabular-nums">
            {Math.round(scanProgress * 100)}%
          </span>
        </div>
      )}
    </footer>
  );
}
