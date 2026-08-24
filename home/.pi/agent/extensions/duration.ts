import { performance } from "node:perf_hooks";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { type Component, visibleWidth } from "@earendil-works/pi-tui";

const ENTRY_TYPE = "agent-settle-timestamp";
const ENTRY_VERSION = 1;
const TIMER_INTERVAL_MS = 1_000;
const UPDATE_WIDGET_EVENT = "pi-footer:update-widget";
const WIDGET_ID = "duration";

interface SettledEntry {
  version: typeof ENTRY_VERSION;
  kind: "settled";
  timestamp: number;
  durationMs: number;
}

interface Observation {
  timestamp: number;
  monotonicTime: number;
}

export default function duration(pi: ExtensionAPI): void {
  let start: Observation | undefined;
  let ticker: ReturnType<typeof setInterval> | undefined;

  const stopTicker = (): void => {
    if (ticker) clearInterval(ticker);
    ticker = undefined;
  };

  const publish = (value: string | null): void => {
    pi.events.emit(UPDATE_WIDGET_EVENT, { widgetId: WIDGET_ID, value });
  };

  const publishElapsed = (observation: Observation): void => {
    const elapsedMs = performance.now() - observation.monotonicTime;
    if (isValidDuration(elapsedMs)) {
      publish(`${formatWholeSecondDuration(elapsedMs)} `);
    }
  };

  pi.registerEntryRenderer(ENTRY_TYPE, (entry, _options, theme) => {
    if (!isSettledEntry(entry.data)) return undefined;

    const label = `${formatWholeSecondDuration(entry.data.durationMs)}   ${formatClock(entry.data.timestamp)}`;

    return rightAligned(label, (text) => theme.fg("dim", text));
  });

  pi.on("session_start", () => {
    stopTicker();
    start = undefined;
    publish(null);
  });

  pi.on("before_agent_start", () => {
    stopTicker();

    const timerStart = observe();
    start = timerStart;
    publishElapsed(timerStart);

    ticker = setInterval(() => {
      if (start !== timerStart) {
        stopTicker();
        return;
      }
      publishElapsed(timerStart);
    }, TIMER_INTERVAL_MS);
  });

  pi.on("agent_settled", () => {
    if (!start) return;

    const timestamp = Date.now();
    const durationMs = performance.now() - start.monotonicTime;

    stopTicker();
    start = undefined;
    publish(null);

    if (!isValidTimestamp(timestamp) || !isValidDuration(durationMs)) return;

    pi.appendEntry<SettledEntry>(ENTRY_TYPE, {
      version: ENTRY_VERSION,
      kind: "settled",
      timestamp,
      durationMs,
    });
  });

  pi.on("session_shutdown", () => {
    stopTicker();
    start = undefined;
    publish(null);
  });
}

function observe(): Observation {
  return {
    timestamp: Date.now(),
    monotonicTime: performance.now(),
  };
}

function formatClock(timestamp: number): string {
  const date = new Date(timestamp);
  const period = date.getHours() >= 12 ? "pm" : "am";
  const hour = date.getHours() % 12 || 12;
  const minutes = String(date.getMinutes()).padStart(2, "0");
  const seconds = String(date.getSeconds()).padStart(2, "0");
  return `${hour}:${minutes}:${seconds}${period}`;
}

function formatWholeSecondDuration(durationMs: number): string {
  let seconds = Math.round(durationMs / 1_000);
  const days = Math.floor(seconds / 86_400);
  seconds %= 86_400;
  const hours = Math.floor(seconds / 3_600);
  seconds %= 3_600;
  const minutes = Math.floor(seconds / 60);
  seconds %= 60;

  const parts: string[] = [];
  if (days > 0) parts.push(`${days}d`);
  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);
  if (seconds > 0 || parts.length === 0) parts.push(`${seconds}s`);
  return parts.join(" ");
}

function rightAligned(
  label: string,
  style: (text: string) => string,
): Component {
  return {
    render(width) {
      if (width < 1) return [];

      const fitted = fitFromRight(label, width);
      const padding = " ".repeat(Math.max(0, width - visibleWidth(fitted)));
      return [`${padding}${style(fitted)}`];
    },
    invalidate() {},
  };
}

function fitFromRight(text: string, width: number): string {
  if (visibleWidth(text) <= width) return text;

  let fitted = "";
  for (const character of [...text].reverse()) {
    const candidate = `${character}${fitted}`;
    if (visibleWidth(candidate) > width) break;
    fitted = candidate;
  }
  return fitted;
}

function isSettledEntry(value: unknown): value is SettledEntry {
  if (typeof value !== "object" || value === null || Array.isArray(value))
    return false;

  const entry = value as Record<string, unknown>;
  if (entry.version !== ENTRY_VERSION || !isValidTimestamp(entry.timestamp))
    return false;
  return entry.kind === "settled" && isValidDuration(entry.durationMs);
}

function isValidDuration(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value) && value >= 0;
}

function isValidTimestamp(value: unknown): value is number {
  return (
    typeof value === "number" &&
    Number.isFinite(value) &&
    !Number.isNaN(new Date(value).getTime())
  );
}
