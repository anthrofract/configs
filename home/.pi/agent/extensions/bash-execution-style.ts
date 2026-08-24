import {
  BashExecutionComponent,
  DynamicBorder,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import {
  Box,
  type Component,
  Container,
  Spacer,
} from "@earendil-works/pi-tui";

type BashStatus = "running" | "complete" | "cancelled" | "error";
type Render = (this: unknown, width: number) => string[];
type PatchablePrototype = {
  render: Render;
};
type BashExecutionInternals = {
  children: Component[];
  status: BashStatus;
};

export default function bashExecutionStyle(pi: ExtensionAPI): void {
  const prototype =
    BashExecutionComponent.prototype as unknown as PatchablePrototype;
  const original = prototype.render;
  const boxes = new WeakMap<object, Box>();
  let applyBackground = (_status: BashStatus, text: string): string => text;

  prototype.render = function render(width): string[] {
    const component = this as BashExecutionInternals;
    let box = boxes.get(component);

    if (!box) {
      box = replaceBorders(component, (text) =>
        applyBackground(component.status, text),
      );
      if (box) boxes.set(component, box);
    }

    return original.call(this, width);
  };

  pi.on("session_start", (_event, ctx) => {
    applyBackground = (status, text) =>
      ctx.ui.theme.bg(backgroundFor(status), text);
  });

  pi.on("session_shutdown", () => {
    prototype.render = original;
    applyBackground = (_status, text) => text;
  });
}

function replaceBorders(
  component: BashExecutionInternals,
  background: (text: string) => string,
): Box | undefined {
  if (component.children.length !== 4) return undefined;

  const [spacer, topBorder, content, bottomBorder] = component.children;
  if (
    !(spacer instanceof Spacer) ||
    !(topBorder instanceof DynamicBorder) ||
    !(content instanceof Container) ||
    !(bottomBorder instanceof DynamicBorder)
  ) {
    return undefined;
  }

  const box = new Box(0, 0, background);
  box.addChild(content);
  component.children = [spacer, box];
  return box;
}

function backgroundFor(
  status: BashStatus,
): "toolPendingBg" | "userMessageBg" | "toolErrorBg" {
  if (status === "running") return "toolPendingBg";
  if (status === "complete") return "userMessageBg";
  return "toolErrorBg";
}
