import { realpathSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { pathToFileURL } from "node:url";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SHOW_SELECTOR_PATCH = Symbol.for("active-tree:show-selector-patch");

type Entry = {
  id: string;
};

type TreeNode = {
  entry: Entry;
};

type Gutter = {
  position: number;
  show: boolean;
};

type FlatNode = {
  node: TreeNode;
  indent: number;
  showConnector: boolean;
  isLast: boolean;
  gutters: Gutter[];
  isVirtualRootChild: boolean;
};

type TreeList = {
  filteredNodes: FlatNode[];
  selectedIndex: number;
  lastSelectedId: string | null;
  activePathIds: Set<string>;
  visibleChildrenMap: Map<string | null, string[]>;
  multipleRoots: boolean;
  applyFilter: () => void;
};

type LayoutFrame =
  | {
      id: string;
      kind: "active";
      additionalBranches: string[];
    }
  | {
      id: string;
      kind: "side";
      indent: number;
      justBranched: boolean;
      showConnector: boolean;
      gutters: Gutter[];
      isLast: boolean;
    };

type TreeSelector = {
  getTreeList: () => TreeList;
};

type SelectorResult = {
  component: unknown;
  focus: unknown;
};

type SelectorFactory = (done: () => void) => SelectorResult;

type ShowSelector = (this: unknown, create: SelectorFactory) => void;

type InteractiveModeClass = {
  prototype: {
    showSelector: ShowSelector;
    [SHOW_SELECTOR_PATCH]?: {
      original: ShowSelector;
      patched: ShowSelector;
    };
  };
};

export default async function activeTree(pi: ExtensionAPI): Promise<void> {
  const { InteractiveMode } = (await importHostModule("index.js")) as {
    InteractiveMode: InteractiveModeClass;
  };

  installPatch(InteractiveMode);
  pi.on("session_shutdown", () => uninstallPatch(InteractiveMode));
}

export function applyActiveSpineLayout(treeList: TreeList): void {
  assertTreeList(treeList);

  const selectedId =
    treeList.filteredNodes[treeList.selectedIndex]?.node.entry.id ?? null;
  const nodesById = new Map(
    treeList.filteredNodes.map((flatNode) => [
      flatNode.node.entry.id,
      flatNode,
    ]),
  );
  const visibleRoots = (treeList.visibleChildrenMap.get(null) ?? []).filter(
    (id) => nodesById.has(id),
  );
  const activeRoot = visibleRoots.find((id) => treeList.activePathIds.has(id));

  if (!activeRoot) return;

  const ordered: FlatNode[] = [];
  const visited = new Set<string>();
  const stack: LayoutFrame[] = [
    {
      id: activeRoot,
      kind: "active",
      additionalBranches: visibleRoots.filter((id) => id !== activeRoot),
    },
  ];

  while (stack.length > 0) {
    const frame = stack.pop()!;
    const flatNode = requireNode(nodesById, frame.id);
    requireUnvisited(visited, frame.id);
    visited.add(frame.id);

    if (frame.kind === "side") {
      setSideBranchLayout(
        flatNode,
        frame.indent,
        frame.showConnector,
        frame.gutters,
        frame.isLast,
      );
      ordered.push(flatNode);

      const childIds = visibleChildren(treeList, nodesById, frame.id);
      const multipleChildren = childIds.length > 1;
      const childIndent =
        multipleChildren || (frame.justBranched && frame.indent > 0)
          ? frame.indent + 1
          : frame.indent;
      const childGutters = frame.showConnector
        ? [
            ...frame.gutters,
            { position: frame.indent - 1, show: !frame.isLast },
          ]
        : frame.gutters;
      for (let index = childIds.length - 1; index >= 0; index--) {
        stack.push({
          id: childIds[index],
          kind: "side",
          indent: childIndent,
          justBranched: multipleChildren,
          showConnector: multipleChildren,
          gutters: childGutters,
          isLast: index === childIds.length - 1,
        });
      }
      continue;
    }

    setActiveSpineLayout(flatNode);
    ordered.push(flatNode);

    const childIds = visibleChildren(treeList, nodesById, frame.id);
    const activeChild = childIds.find((childId) =>
      treeList.activePathIds.has(childId),
    );
    const sideBranches = [
      ...frame.additionalBranches,
      ...childIds.filter((childId) => childId !== activeChild),
    ];

    if (activeChild) {
      stack.push({ id: activeChild, kind: "active", additionalBranches: [] });
    }
    for (let index = sideBranches.length - 1; index >= 0; index--) {
      stack.push({
        id: sideBranches[index],
        kind: "side",
        indent: 1,
        justBranched: true,
        showConnector: true,
        gutters: [],
        isLast: !activeChild && index === sideBranches.length - 1,
      });
    }
  }
  assertCompleteLayout(treeList.filteredNodes, visited);
  commitLayout(treeList, ordered, selectedId);
}

export function installPatch(InteractiveMode: InteractiveModeClass): void {
  uninstallPatch(InteractiveMode);

  const prototype = InteractiveMode.prototype;
  const original = prototype.showSelector;
  const patched: ShowSelector = function showActiveTree(create): void {
    return original.call(this, (done) => {
      const result = create(done);
      const selector = getTreeSelector(result);
      if (selector) patchTreeList(selector.getTreeList());
      return result;
    });
  };

  prototype.showSelector = patched;
  prototype[SHOW_SELECTOR_PATCH] = { original, patched };
}

export function uninstallPatch(InteractiveMode: InteractiveModeClass): void {
  const prototype = InteractiveMode.prototype;
  const patch = prototype[SHOW_SELECTOR_PATCH];
  if (!patch) return;

  if (prototype.showSelector === patch.patched) {
    prototype.showSelector = patch.original;
  }
  delete prototype[SHOW_SELECTOR_PATCH];
}

function patchTreeList(treeList: TreeList): void {
  assertTreeList(treeList);

  const nativeApplyFilter = treeList.applyFilter.bind(treeList);
  treeList.applyFilter = function applyActiveTreeFilter(): void {
    nativeApplyFilter();
    applyActiveSpineLayout(this);
  };

  applyActiveSpineLayout(treeList);
}

function getTreeSelector(result: SelectorResult): TreeSelector | null {
  for (const candidate of [result.focus, result.component]) {
    if (
      typeof candidate === "object" &&
      candidate !== null &&
      "getTreeList" in candidate &&
      typeof candidate.getTreeList === "function"
    ) {
      return candidate as TreeSelector;
    }
  }
  return null;
}

function setActiveSpineLayout(flatNode: FlatNode): void {
  flatNode.indent = 0;
  flatNode.showConnector = false;
  flatNode.isLast = false;
  flatNode.gutters = [];
  flatNode.isVirtualRootChild = false;
}

function setSideBranchLayout(
  flatNode: FlatNode,
  indent: number,
  showConnector: boolean,
  gutters: Gutter[],
  isLast: boolean,
): void {
  flatNode.indent = indent;
  flatNode.showConnector = showConnector;
  flatNode.isLast = isLast;
  flatNode.gutters = gutters;
  flatNode.isVirtualRootChild = false;
}

function commitLayout(
  treeList: TreeList,
  ordered: FlatNode[],
  selectedId: string | null,
): void {
  treeList.filteredNodes.length = 0;
  for (const flatNode of ordered) treeList.filteredNodes.push(flatNode);
  treeList.multipleRoots = false;

  if (ordered.length === 0) {
    treeList.selectedIndex = 0;
    return;
  }

  const selectedIndex = selectedId
    ? ordered.findIndex((flatNode) => flatNode.node.entry.id === selectedId)
    : -1;
  treeList.selectedIndex = selectedIndex >= 0 ? selectedIndex : 0;
  treeList.lastSelectedId = ordered[treeList.selectedIndex].node.entry.id;
}

function visibleChildren(
  treeList: TreeList,
  nodesById: Map<string, FlatNode>,
  id: string,
): string[] {
  return (treeList.visibleChildrenMap.get(id) ?? []).filter((childId) =>
    nodesById.has(childId),
  );
}

function requireNode(nodesById: Map<string, FlatNode>, id: string): FlatNode {
  const flatNode = nodesById.get(id);
  if (!flatNode) throw new Error(`active-tree: missing visible node ${id}`);
  return flatNode;
}

function requireUnvisited(visited: Set<string>, id: string): void {
  if (visited.has(id))
    throw new Error(`active-tree: cycle or duplicate node ${id}`);
}

function assertCompleteLayout(
  flatNodes: FlatNode[],
  visited: Set<string>,
): void {
  if (visited.size !== flatNodes.length) {
    throw new Error(
      `active-tree: laid out ${visited.size} of ${flatNodes.length} visible nodes`,
    );
  }
}

function assertTreeList(value: unknown): asserts value is TreeList {
  if (typeof value !== "object" || value === null) {
    throw new Error("active-tree: Pi tree list is unavailable");
  }

  const treeList = value as Partial<TreeList>;
  if (
    !Array.isArray(treeList.filteredNodes) ||
    !(treeList.activePathIds instanceof Set) ||
    !(treeList.visibleChildrenMap instanceof Map) ||
    typeof treeList.selectedIndex !== "number" ||
    typeof treeList.applyFilter !== "function"
  ) {
    throw new Error("active-tree: incompatible Pi tree selector internals");
  }
}

async function importHostModule(relativePath: string): Promise<unknown> {
  const hostDistDirectory = dirname(realpathSync(process.argv[1]));
  const moduleUrl = pathToFileURL(
    resolve(hostDistDirectory, relativePath),
  ).href;
  return import(moduleUrl);
}
