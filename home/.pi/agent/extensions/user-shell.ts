import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";

import {
  createLocalBashOperations,
  getAgentDir,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

interface UserShellSettings {
  userShell?: {
    path?: unknown;
  };
}

export default function userShell(pi: ExtensionAPI): void {
  const shellPath = loadShellPath();
  const operations = createLocalBashOperations({ shellPath });

  pi.on("user_bash", () => ({ operations }));
}

function loadShellPath(): string {
  const agentDir = getAgentDir();
  const settingsPath = join(agentDir, "settings.json");
  const settings = JSON.parse(
    readFileSync(settingsPath, "utf8"),
  ) as UserShellSettings;
  const configuredPath = settings.userShell?.path;

  if (typeof configuredPath !== "string" || configuredPath.length === 0) {
    throw new Error(`Missing userShell.path in ${settingsPath}`);
  }

  const expandedPath = expandHome(configuredPath);
  return isAbsolute(expandedPath)
    ? expandedPath
    : resolve(agentDir, expandedPath);
}

function expandHome(path: string): string {
  if (path === "~") return homedir();
  if (path.startsWith("~/")) return join(homedir(), path.slice(2));
  return path;
}
