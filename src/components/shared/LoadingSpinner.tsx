import { cn } from "../../lib/utils";

interface LoadingSpinnerProps {
  size?: "sm" | "md";
  className?: string;
}

export function LoadingSpinner({ size = "md", className }: LoadingSpinnerProps) {
  return (
    <div
      className={cn(
        "animate-spin rounded-full border-t-transparent",
        size === "sm"
          ? "h-3 w-3 border"
          : "h-5 w-5 border-2",
        "border-[var(--color-text-muted)]",
        className
      )}
    />
  );
}
