import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";
import { cn } from "../../lib/utils";
import type { ScoreBreakdown, WeeklyScore } from "../../lib/types";

const SUB_LABELS: { key: keyof Omit<ScoreBreakdown, "total">; label: string }[] = [
  { key: "adoption", label: "Adoption" },
  { key: "efficiency", label: "Efficiency" },
  { key: "granularity", label: "Focus" },
  { key: "velocity", label: "Velocity" },
  { key: "quality", label: "Quality" },
];

function scoreColor(score: number): string {
  if (score >= 70) return "text-emerald-400";
  if (score >= 40) return "text-amber-400";
  return "text-red-400";
}

function pillColor(value: number): string {
  if (value >= 70) return "bg-emerald-500/15 text-emerald-400";
  if (value >= 40) return "bg-amber-500/15 text-amber-400";
  return "bg-red-500/15 text-red-400";
}

interface ScoreHeroProps {
  score: ScoreBreakdown;
  weeklyScores: WeeklyScore[];
}

export function ScoreHero({ score, weeklyScores }: ScoreHeroProps) {
  return (
    <div className="flex flex-col items-center gap-6">
      {/* Big number */}
      <div className="flex flex-col items-center gap-2 pt-8">
        <span
          className={cn(
            "text-8xl font-bold tabular-nums tracking-tighter",
            scoreColor(score.total)
          )}
        >
          {score.total}
        </span>
        <span className="text-xs text-zinc-500 uppercase tracking-widest">
          CodeLens Score
        </span>
      </div>

      {/* Sub-score pills */}
      <div className="flex flex-wrap justify-center gap-2">
        {SUB_LABELS.map(({ key, label }) => (
          <span
            key={key}
            className={cn(
              "rounded-full px-3 py-1 text-xs font-medium tabular-nums",
              pillColor(score[key])
            )}
          >
            {label} {score[key]}
          </span>
        ))}
      </div>

      {/* Trend chart */}
      {weeklyScores.length >= 2 && (
        <div className="w-full max-w-lg h-40 mt-2">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={weeklyScores}>
              <XAxis
                dataKey="week"
                tick={{ fontSize: 10, fill: "#52525b" }}
                axisLine={false}
                tickLine={false}
              />
              <YAxis
                domain={[0, 100]}
                tick={{ fontSize: 10, fill: "#52525b" }}
                axisLine={false}
                tickLine={false}
                width={28}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: "#18181b",
                  border: "1px solid #27272a",
                  borderRadius: 8,
                  fontSize: 12,
                }}
                labelStyle={{ color: "#a1a1aa" }}
              />
              <Line
                type="monotone"
                dataKey="score"
                stroke="#e5a158"
                strokeWidth={2}
                dot={{ r: 3, fill: "#e5a158" }}
                activeDot={{ r: 5 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}
