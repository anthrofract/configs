import {
  type ExtensionAPI,
  ToolExecutionComponent,
  type ToolDefinition,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

type Tool = ToolDefinition<any, any, any>;
type ResultRenderer = NonNullable<Tool["renderResult"]>;
type Result = Parameters<ResultRenderer>[0];
type Summary = (result: Result) => string | undefined;
type ToolExecution = {
  toolName: string;
  getResultRenderer(): ResultRenderer | undefined;
};

const emptyOutputs = new Set([
  "(empty directory)",
  "No files found matching pattern",
  "No matches found",
]);

export default function toolOutputSummary(pi: ExtensionAPI): void {
  const prototype = ToolExecutionComponent.prototype as unknown as ToolExecution;
  const original = prototype.getResultRenderer;

  function getResultRenderer(this: ToolExecution): ResultRenderer | undefined {
    const renderResult = original.call(this);
    const summarize = summaries.get(this.toolName);
    if (!renderResult || !summarize) return renderResult;

    return (result, options, theme, context) => {
      if (options.expanded || options.isPartial || context.isError) {
        return renderResult(result, options, theme, context);
      }

      const summary = summarize(result);
      if (!summary) return renderResult(result, options, theme, context);
      return new Text(theme.fg("muted", summary), 0, 0);
    };
  }

  prototype.getResultRenderer = getResultRenderer;

  pi.on("session_shutdown", () => {
    if (prototype.getResultRenderer === getResultRenderer) {
      prototype.getResultRenderer = original;
    }
  });
}

const summaries = new Map<string, Summary>([
  ["find", (result) => summarizeNonEmpty(extractText(result), "result")],
  [
    "grep",
    (result) => summarizeNonEmpty(extractText(result), "match", "matches"),
  ],
  ["ls", (result) => summarizeNonEmpty(extractText(result), "entry", "entries")],
  ["read", summarizeRead],
]);

function extractText(result: {
  content?: Array<{ type: string; text?: string }>;
}): string {
  return (result.content ?? [])
    .filter((content) => content.type === "text")
    .map((content) => content.text ?? "")
    .join("\n");
}

function summarizeRead(result: Result): string | undefined {
  const output = extractText(result);
  if (
    result.content?.some((content) => content.type === "image") ||
    output.startsWith("Read image file [")
  ) {
    return undefined;
  }

  const truncation = (
    result.details as { truncation?: { outputLines?: number } } | undefined
  )?.truncation;
  const outputLines = truncation?.outputLines;
  const count =
    typeof outputLines === "number"
      ? outputLines
      : countReadLines(output);

  return `↳ ${count} ${pluralize(count, "line")} read`;
}

function countReadLines(output: string): number {
  const content = output.replace(
    /\n\n\[\d+ more lines in file\. Use offset=\d+ to continue\.\]\s*$/,
    "",
  );
  return content ? content.split(/\r?\n/).length : 0;
}

function summarizeNonEmpty(
  output: string,
  singular: string,
  plural = `${singular}s`,
): string {
  const trimmed = output.trim();
  const count = emptyOutputs.has(trimmed)
    ? 0
    : output.split(/\r?\n/).filter((line) => line.trim()).length;
  return `↳ ${count} ${pluralize(count, singular, plural)} returned`;
}

function pluralize(
  count: number,
  singular: string,
  plural = `${singular}s`,
): string {
  return count === 1 ? singular : plural;
}
