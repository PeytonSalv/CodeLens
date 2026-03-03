import { useMemo } from "react";
import { useProjectStore } from "../store/projectStore";
import type { Commit, ScoreBreakdown, WeeklyScore } from "../lib/types";

const WEIGHTS = {
  adoption: 0.2,
  efficiency: 0.2,
  granularity: 0.2,
  velocity: 0.25,
  quality: 0.15,
};

function clamp(v: number): number {
  return Math.max(0, Math.min(100, v));
}

/** Detect re-prompts: consecutive prompts in same session with >60% word overlap. */
function countReprompts(
  sessions: Array<{ sessionId: string; promptText: string }>
): number {
  let count = 0;
  for (let i = 1; i < sessions.length; i++) {
    if (sessions[i].sessionId !== sessions[i - 1].sessionId) continue;
    const a = sessions[i - 1].promptText.toLowerCase().slice(0, 50);
    const b = sessions[i].promptText.toLowerCase().slice(0, 50);
    if (a.length > 10 && b.length > 10) {
      const wordsA = new Set(a.split(/\s+/));
      const wordsB = new Set(b.split(/\s+/));
      const intersection = [...wordsA].filter((w) => wordsB.has(w));
      const overlap = intersection.length / Math.max(wordsA.size, wordsB.size);
      if (overlap > 0.6) count++;
    }
  }
  return count;
}

function getISOWeek(date: Date): string {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const weekNo = Math.ceil(((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(weekNo).padStart(2, "0")}`;
}

function computeBreakdown(
  commits: Commit[],
  repromptRate: number,
  claudePct: number,
  velocityByWeek: { week: string; commits: number }[]
): ScoreBreakdown {
  // Adoption: how much Claude Code is used
  const adoption = clamp(claudePct * 200);

  // Efficiency: lower reprompt = better
  const efficiency = clamp((1 - repromptRate) * 100);

  // Granularity: fewer files per commit = more focused
  const avgFiles =
    commits.length > 0
      ? commits.reduce((s, c) => s + c.filesChanged.length, 0) / commits.length
      : 1;
  const granularity = clamp(100 - (avgFiles - 1) * 15);

  // Velocity: compare last 4 weeks vs prior 4 weeks
  let velocity = 50; // neutral default
  if (velocityByWeek.length >= 2) {
    const sorted = [...velocityByWeek].sort((a, b) => a.week.localeCompare(b.week));
    const mid = Math.max(0, sorted.length - 4);
    const recent = sorted.slice(mid);
    const prior = sorted.slice(Math.max(0, mid - 4), mid);
    const recentAvg =
      recent.length > 0
        ? recent.reduce((s, w) => s + w.commits, 0) / recent.length
        : 0;
    const priorAvg =
      prior.length > 0
        ? prior.reduce((s, w) => s + w.commits, 0) / prior.length
        : 0;
    if (priorAvg > 0) {
      const change = (recentAvg - priorAvg) / priorAvg;
      velocity = clamp(50 + change * 50);
    } else if (recentAvg > 0) {
      velocity = 80;
    }
  }

  // Quality: fewer bug fixes = better
  const bugFixCount = commits.filter((c) => c.changeType === "bug_fix").length;
  const bugFixPct = commits.length > 0 ? bugFixCount / commits.length : 0;
  const quality = clamp(100 - bugFixPct * 200);

  const total = Math.round(
    adoption * WEIGHTS.adoption +
      efficiency * WEIGHTS.efficiency +
      granularity * WEIGHTS.granularity +
      velocity * WEIGHTS.velocity +
      quality * WEIGHTS.quality
  );

  return {
    adoption: Math.round(adoption),
    efficiency: Math.round(efficiency),
    granularity: Math.round(granularity),
    velocity: Math.round(velocity),
    quality: Math.round(quality),
    total,
  };
}

export function useScore() {
  const activeProject = useProjectStore((s) => s.activeProject);

  return useMemo(() => {
    if (!activeProject) return { score: null, weeklyScores: [] };

    const { commits, analytics, promptSessions, developerProfile } = activeProject;

    // Reprompt rate: from developer profile or computed
    const repromptRate =
      developerProfile?.repromptRate ??
      (promptSessions.length > 0
        ? countReprompts(promptSessions) / promptSessions.length
        : 0);

    const claudePct = analytics.claudeCodeCommitPercentage;

    const score = computeBreakdown(
      commits,
      repromptRate,
      claudePct,
      analytics.velocityByWeek
    );

    // Weekly scores: group commits by ISO week
    const weekMap = new Map<string, Commit[]>();
    for (const c of commits) {
      try {
        const week = getISOWeek(new Date(c.timestamp));
        if (!weekMap.has(week)) weekMap.set(week, []);
        weekMap.get(week)!.push(c);
      } catch {
        // skip invalid
      }
    }

    const weeklyScores: WeeklyScore[] = [...weekMap.entries()]
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([week, weekCommits]) => {
        const weekClaude = weekCommits.filter((c) => c.isClaudeCode).length;
        const weekClaudePct =
          weekCommits.length > 0 ? weekClaude / weekCommits.length : 0;
        const breakdown = computeBreakdown(
          weekCommits,
          repromptRate, // use global reprompt rate for weekly
          weekClaudePct,
          analytics.velocityByWeek
        );
        return { week, score: breakdown.total, breakdown };
      });

    return { score, weeklyScores };
  }, [activeProject]);
}
