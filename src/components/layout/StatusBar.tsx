import { useProjectStore } from "../../store/projectStore";

export function StatusBar() {
  const { isScanning, scanProgress, scanMessage, activeProject } =
    useProjectStore();

  return (
    <footer className="flex h-6 items-center justify-between border-t border-zinc-800 bg-zinc-900/80 px-3">
      <div className="flex items-center gap-2">
        {isScanning ? (
          <>
            <div className="h-1.5 w-1.5 rounded-full bg-amber-400 animate-pulse" />
            <span className="text-[11px] text-zinc-500">{scanMessage}</span>
          </>
        ) : (
          <span className="text-[11px] text-zinc-600">
            {activeProject ? "Ready" : "No project open"}
          </span>
        )}
      </div>

      {isScanning && (
        <div className="flex items-center gap-2">
          <div className="h-1 w-24 overflow-hidden rounded-full bg-zinc-800">
            <div
              className="h-full rounded-full bg-amber-400 transition-all duration-300"
              style={{ width: `${scanProgress * 100}%` }}
            />
          </div>
          <span className="text-[11px] text-zinc-600 font-mono tabular-nums">
            {Math.round(scanProgress * 100)}%
          </span>
        </div>
      )}
    </footer>
  );
}
