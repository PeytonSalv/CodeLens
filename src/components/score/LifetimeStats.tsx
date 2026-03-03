import { useProjectStore } from "../../store/projectStore";
import { usePatternStore } from "../../store/patternStore";

export function LifetimeStats() {
  const activeProject = useProjectStore((s) => s.activeProject);
  const statuses = usePatternStore((s) => s.statuses);

  if (!activeProject) return null;

  const sessionsAnalyzed = activeProject.promptSessions.length;
  const patternsFixed = Object.values(statuses).filter(
    (e) => e.status === "fixed"
  ).length;

  // Heuristic: count reprompts that could have been saved based on approved/fixed patterns
  const repromptsSaved = patternsFixed * 3; // rough estimate per fixed pattern

  // Heuristic: estimate hours recovered from efficiency gains
  const hoursRecovered = Math.round(
    (sessionsAnalyzed * 0.02 + patternsFixed * 0.5) * 10
  ) / 10;

  const stats = [
    { label: "Sessions analyzed", value: sessionsAnalyzed },
    { label: "Patterns fixed", value: patternsFixed },
    { label: "Re-prompts saved", value: `~${repromptsSaved}` },
    { label: "Hours recovered", value: `~${hoursRecovered}` },
  ];

  return (
    <div className="flex justify-center gap-8 py-6 border-t border-zinc-800/50">
      {stats.map((stat) => (
        <div key={stat.label} className="flex flex-col items-center gap-1">
          <span className="text-lg font-semibold tabular-nums text-zinc-200">
            {stat.value}
          </span>
          <span className="text-[10px] text-zinc-500">{stat.label}</span>
        </div>
      ))}
    </div>
  );
}
