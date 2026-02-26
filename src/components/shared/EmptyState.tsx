import { useProject } from "../../hooks/useProject";

export function EmptyState() {
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
    <div className="flex h-full items-center justify-center">
      <div className="flex flex-col items-center gap-4 max-w-sm text-center">
        <div className="flex h-12 w-12 items-center justify-center rounded-lg border border-zinc-800 bg-zinc-900">
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            className="text-zinc-500"
          >
            <path d="M12 5v14M5 12h14" strokeLinecap="round" />
          </svg>
        </div>
        <div>
          <h2 className="text-sm font-medium text-zinc-200">
            Open a repository
          </h2>
          <p className="mt-1.5 text-xs text-zinc-500 leading-relaxed">
            Point CodeLens at a git repository to analyze its feature history
            and visualize the development timeline.
          </p>
        </div>
        <button
          onClick={handleOpen}
          className="rounded-md bg-zinc-800 px-4 py-1.5 text-[13px] text-zinc-200 transition-colors hover:bg-zinc-700"
        >
          Choose Folder
        </button>
      </div>
    </div>
  );
}
