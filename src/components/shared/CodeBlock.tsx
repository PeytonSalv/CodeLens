interface CodeBlockProps {
  code: string;
  language?: string;
}

export function CodeBlock({ code }: CodeBlockProps) {
  return (
    <pre className="overflow-auto rounded-md border border-[var(--color-border)] bg-[var(--color-surface-0)] p-3 text-xs font-mono leading-relaxed text-[var(--color-text-secondary)]">
      <code>{code}</code>
    </pre>
  );
}
