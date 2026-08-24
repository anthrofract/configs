import {
  type ExtensionAPI,
  ToolExecutionComponent,
} from "@earendil-works/pi-coding-agent";
import { Box } from "@earendil-works/pi-tui";

type Render = (this: unknown, width: number) => string[];
type PatchablePrototype = {
  render: Render;
};
type BoxInternals = {
  paddingY: number;
};
type ToolExecutionInternals = {
  contentBox?: Box;
};

const patches = new Map<PatchablePrototype, Render>();

export default function compactMessageSpacing(pi: ExtensionAPI): void {
  patchRender(
    ToolExecutionComponent.prototype as unknown as PatchablePrototype,
    (component) => setVerticalPadding((component as ToolExecutionInternals).contentBox),
  );

  pi.on("session_shutdown", () => {
    for (const [prototype, original] of patches) {
      prototype.render = original;
    }
    patches.clear();
  });
}

function patchRender(
  prototype: PatchablePrototype,
  compact: (component: unknown) => void,
): void {
  if (patches.has(prototype)) return;

  const original = prototype.render;
  prototype.render = function render(width): string[] {
    compact(this);
    return original.call(this, width);
  };
  patches.set(prototype, original);
}

function setVerticalPadding(box: Box | undefined): void {
  if (!box) return;

  const internals = box as unknown as BoxInternals;
  if (internals.paddingY === 0) return;

  internals.paddingY = 0;
  box.invalidate();
}
