import { useMemo } from "react";
import { useProjectStore } from "../store/projectStore";
import { usePatternStore } from "../store/patternStore";
import type { DetectedPattern, Commit } from "../lib/types";

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

function computeFileCouplings(commits: Commit[]): [string, string, number][] {
  const pairCounts = new Map<string, number>();
  for (const commit of commits) {
    const files = commit.filesChanged.map((f) => f.path).sort();
    for (let i = 0; i < files.length; i++) {
      for (let j = i + 1; j < files.length; j++) {
        const key = `${files[i]}|||${files[j]}`;
        pairCounts.set(key, (pairCounts.get(key) || 0) + 1);
      }
    }
  }
  return [...pairCounts.entries()]
    .filter(([, count]) => count >= 5)
    .sort((a, b) => b[1] - a[1])
    .map(([key, count]) => {
      const [a, b] = key.split("|||");
      return [a, b, count];
    });
}

function splitHalves<T>(arr: T[]): [T[], T[]] {
  const mid = Math.floor(arr.length / 2);
  return [arr.slice(0, mid), arr.slice(mid)];
}

export function usePatterns() {
  const activeProject = useProjectStore((s) => s.activeProject);
  const statuses = usePatternStore((s) => s.statuses);

  return useMemo(() => {
    if (!activeProject) return [];

    const { commits, promptSessions } = activeProject;
    const patterns: DetectedPattern[] = [];

    // 1. High reprompt rate
    if (promptSessions.length > 0) {
      const repromptCount = countReprompts(promptSessions);
      const rate = repromptCount / promptSessions.length;
      if (rate > 0.2) {
        patterns.push({
          id: "high_reprompt",
          type: "high_reprompt",
          title: "High re-prompt rate",
          description:
            "Over 20% of your Claude Code sessions involve re-prompting. Try writing more specific initial prompts.",
          metricBefore: `${Math.round(rate * 100)}%`,
          metricAfter: "<20%",
          severity: "negative",
        });
      }
    }

    // 2. File couplings
    const couplings = computeFileCouplings(commits);
    if (couplings.length > 0) {
      const top = couplings.slice(0, 3);
      patterns.push({
        id: "file_coupling",
        type: "file_coupling",
        title: "Frequently co-edited files",
        description: top
          .map(([a, b, n]) => `${a.split("/").pop()} & ${b.split("/").pop()} (${n}x)`)
          .join(", "),
        metricBefore: `${top[0][2]}x`,
        metricAfter: "Consider extracting shared logic",
        severity: "neutral",
      });
    }

    // Sort commits by time for half-comparison patterns
    const sorted = [...commits].sort(
      (a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
    );
    if (sorted.length >= 10) {
      const [firstHalf, secondHalf] = splitHalves(sorted);

      // 3. Bug fix decline
      const bugPctFirst =
        firstHalf.filter((c) => c.changeType === "bug_fix").length / firstHalf.length;
      const bugPctSecond =
        secondHalf.filter((c) => c.changeType === "bug_fix").length / secondHalf.length;
      if (bugPctSecond < bugPctFirst - 0.05) {
        patterns.push({
          id: "bug_fix_decline",
          type: "bug_fix_decline",
          title: "Fewer bug fixes over time",
          description:
            "Your bug fix ratio has decreased, suggesting code quality is improving.",
          metricBefore: `${Math.round(bugPctFirst * 100)}%`,
          metricAfter: `${Math.round(bugPctSecond * 100)}%`,
          severity: "positive",
        });
      }

      // 4. Granularity improvement
      const avgFilesFirst =
        firstHalf.reduce((s, c) => s + c.filesChanged.length, 0) / firstHalf.length;
      const avgFilesSecond =
        secondHalf.reduce((s, c) => s + c.filesChanged.length, 0) / secondHalf.length;
      if (avgFilesSecond < avgFilesFirst - 0.5) {
        patterns.push({
          id: "granularity_improvement",
          type: "granularity_improvement",
          title: "Commits getting more focused",
          description:
            "Your average files per commit is decreasing. Smaller, focused commits are easier to review.",
          metricBefore: `${avgFilesFirst.toFixed(1)} files`,
          metricAfter: `${avgFilesSecond.toFixed(1)} files`,
          severity: "positive",
        });
      }

      // 5. Claude adoption growth
      const claudeFirst =
        firstHalf.filter((c) => c.isClaudeCode).length / firstHalf.length;
      const claudeSecond =
        secondHalf.filter((c) => c.isClaudeCode).length / secondHalf.length;
      if (claudeSecond > claudeFirst + 0.1) {
        patterns.push({
          id: "claude_adoption_growth",
          type: "claude_adoption_growth",
          title: "Claude Code adoption growing",
          description:
            "You're using Claude Code for a larger share of commits over time.",
          metricBefore: `${Math.round(claudeFirst * 100)}%`,
          metricAfter: `${Math.round(claudeSecond * 100)}%`,
          severity: "positive",
        });
      }
    }

    // Merge with stored statuses
    return patterns.map((p) => ({
      ...p,
      storedStatus: statuses[p.id]?.status ?? "detected",
    }));
  }, [activeProject, statuses]);
}
