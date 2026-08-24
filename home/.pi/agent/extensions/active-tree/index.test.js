import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { realpathSync } from "node:fs";
import { dirname, resolve } from "node:path";
import test from "node:test";
import { pathToFileURL } from "node:url";

import {
  applyActiveSpineLayout,
  installPatch,
  uninstallPatch,
} from "./index.ts";

function flatNode(id) {
  return {
    node: { entry: { id } },
    indent: 99,
    showConnector: false,
    isLast: false,
    gutters: [],
    isVirtualRootChild: false,
  };
}

function treeList({ ids, activeIds, children, selectedId }) {
  const filteredNodes = ids.map(flatNode);
  return {
    filteredNodes,
    selectedIndex: ids.indexOf(selectedId),
    lastSelectedId: selectedId,
    activePathIds: new Set(activeIds),
    visibleChildrenMap: new Map(children),
    multipleRoots: false,
    applyFilter() {},
  };
}

function ids(tree) {
  return tree.filteredNodes.map((node) => node.node.entry.id);
}

function node(tree, id) {
  return tree.filteredNodes.find((candidate) => candidate.node.entry.id === id);
}

const children = [
  [null, ["root"]],
  ["root", ["approach-b", "approach-a"]],
  ["approach-a", ["approach-a-more"]],
  ["approach-a-more", []],
  ["approach-b", ["library-y", "library-x"]],
  ["library-x", ["library-x-more"]],
  ["library-x-more", []],
  ["library-y", ["rewrite", "patch"]],
  ["patch", []],
  ["rewrite", ["current"]],
  ["current", []],
];

const nativeOrder = [
  "root",
  "approach-b",
  "library-y",
  "rewrite",
  "current",
  "patch",
  "library-x",
  "library-x-more",
  "approach-a",
  "approach-a-more",
];

test("renders the active path as a spine with alternatives at their attachment points", () => {
  const tree = treeList({
    ids: nativeOrder,
    activeIds: ["root", "approach-b", "library-y", "rewrite", "current"],
    children,
    selectedId: "current",
  });

  applyActiveSpineLayout(tree);

  assert.deepEqual(ids(tree), [
    "root",
    "approach-a",
    "approach-a-more",
    "approach-b",
    "library-x",
    "library-x-more",
    "library-y",
    "patch",
    "rewrite",
    "current",
  ]);
  assert.equal(tree.filteredNodes[tree.selectedIndex].node.entry.id, "current");

  for (const id of ["root", "approach-b", "library-y", "rewrite", "current"]) {
    assert.equal(node(tree, id).indent, 0);
    assert.equal(node(tree, id).showConnector, false);
  }

  assert.equal(node(tree, "approach-a").indent, 1);
  assert.equal(node(tree, "approach-a").isLast, false);
  assert.equal(node(tree, "approach-a-more").indent, 2);
  assert.deepEqual(node(tree, "approach-a-more").gutters, [
    { position: 0, show: true },
  ]);
  assert.equal(node(tree, "patch").indent, 1);
  assert.equal(node(tree, "patch").isLast, false);
});

test("rebuilds the spine when a different preserved branch becomes active", () => {
  const tree = treeList({
    ids: nativeOrder,
    activeIds: ["root", "approach-b", "library-x", "library-x-more"],
    children,
    selectedId: "library-x-more",
  });

  applyActiveSpineLayout(tree);

  assert.deepEqual(ids(tree), [
    "root",
    "approach-a",
    "approach-a-more",
    "approach-b",
    "library-y",
    "rewrite",
    "current",
    "patch",
    "library-x",
    "library-x-more",
  ]);
  for (const id of ["root", "approach-b", "library-x", "library-x-more"]) {
    assert.equal(node(tree, id).indent, 0);
  }
  assert.equal(node(tree, "library-y").indent, 1);
  assert.equal(node(tree, "rewrite").indent, 2);
});

test("attaches alternative session roots beneath the active root", () => {
  const tree = treeList({
    ids: ["active-root", "active-leaf", "old-root", "old-child"],
    activeIds: ["active-root", "active-leaf"],
    children: [
      [null, ["active-root", "old-root"]],
      ["active-root", ["active-leaf"]],
      ["active-leaf", []],
      ["old-root", ["old-child"]],
      ["old-child", []],
    ],
    selectedId: "active-leaf",
  });

  applyActiveSpineLayout(tree);

  assert.deepEqual(ids(tree), [
    "active-root",
    "old-root",
    "old-child",
    "active-leaf",
  ]);
  assert.equal(node(tree, "active-root").indent, 0);
  assert.equal(node(tree, "old-root").indent, 1);
  assert.equal(node(tree, "old-child").indent, 2);
  assert.equal(node(tree, "active-leaf").indent, 0);
});

test("handles a deep abandoned chain without recursive traversal or indentation drift", () => {
  const depth = 10_000;
  const ids = ["root", "active"];
  const deepIds = Array.from({ length: depth }, (_, index) => `old-${index}`);
  ids.push(...deepIds);

  const deepChildren = [
    [null, ["root"]],
    ["root", ["active", deepIds[0]]],
    ["active", []],
  ];
  for (let index = 0; index < deepIds.length; index++) {
    deepChildren.push([
      deepIds[index],
      index + 1 < deepIds.length ? [deepIds[index + 1]] : [],
    ]);
  }

  const tree = treeList({
    ids,
    activeIds: ["root", "active"],
    children: deepChildren,
    selectedId: "active",
  });

  applyActiveSpineLayout(tree);

  assert.equal(tree.filteredNodes.length, depth + 2);
  assert.equal(tree.filteredNodes[tree.selectedIndex].node.entry.id, "active");
  assert.equal(node(tree, "old-0").indent, 1);
  assert.equal(node(tree, "old-1").indent, 2);
  assert.equal(node(tree, `old-${depth - 1}`).indent, 2);
});

test("patches Pi 0.84.2's native tree-list state and keeps native rendering", async () => {
  const piPath = execFileSync("which", ["pi"], { encoding: "utf8" }).trim();
  const piPackageRoot = resolve(dirname(realpathSync(piPath)), "..");
  const piDist = resolve(piPackageRoot, "lib/node_modules/pi-monorepo/dist");
  const moduleUrl = pathToFileURL(
    resolve(piDist, "modes/interactive/components/tree-selector.js"),
  ).href;
  const themeUrl = pathToFileURL(
    resolve(piDist, "modes/interactive/theme/theme.js"),
  ).href;
  const [{ TreeSelectorComponent }, { initTheme }] = await Promise.all([
    import(moduleUrl),
    import(themeUrl),
  ]);
  initTheme("dark", false);

  const message = (id, parentId, text, children = []) => ({
    entry: {
      id,
      parentId,
      timestamp: "2026-01-01T00:00:00.000Z",
      type: "message",
      message: { role: "user", content: text },
    },
    children,
  });
  const activeLeaf = message("active-leaf", "active", "current");
  const active = message("active", "root", "active", [activeLeaf]);
  const abandonedLeaf = message("abandoned-leaf", "abandoned", "old detail");
  const abandoned = message("abandoned", "root", "old", [abandonedLeaf]);
  const root = message("root", null, "start", [abandoned, active]);
  const selector = new TreeSelectorComponent(
    [root],
    "active-leaf",
    24,
    () => {},
    () => {},
  );
  class InteractiveMode {
    showSelector(create) {
      this.result = create(() => {});
      return this.result;
    }
  }
  const nativeShowSelector = InteractiveMode.prototype.showSelector;
  installPatch(InteractiveMode);

  try {
    const mode = new InteractiveMode();
    mode.showSelector(() => ({ component: selector, focus: selector }));
    const nativeTreeList = selector.getTreeList();
    const expectedOrder = [
      "root",
      "abandoned",
      "abandoned-leaf",
      "active",
      "active-leaf",
    ];

    assert.deepEqual(
      nativeTreeList.filteredNodes.map((entry) => entry.node.entry.id),
      expectedOrder,
    );
    nativeTreeList.applyFilter();
    assert.deepEqual(
      nativeTreeList.filteredNodes.map((entry) => entry.node.entry.id),
      expectedOrder,
    );

    nativeTreeList.foldedNodes.add("abandoned");
    nativeTreeList.applyFilter();
    assert.deepEqual(
      nativeTreeList.filteredNodes.map((entry) => entry.node.entry.id),
      ["root", "abandoned", "active", "active-leaf"],
    );
    nativeTreeList.foldedNodes.delete("abandoned");
    nativeTreeList.applyFilter();

    nativeTreeList.selectedIndex = 0;
    const activeBranchIndex = nativeTreeList.findBranchSegmentStart("down");
    assert.equal(
      nativeTreeList.filteredNodes[activeBranchIndex].node.entry.id,
      "active",
    );

    const rendered = selector.render(80).join("\n");
    const plain = rendered.replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "");
    assert.ok(plain.indexOf("user: old") < plain.indexOf("user: active"));
    assert.match(plain, /• user: active/);
  } finally {
    uninstallPatch(InteractiveMode);
  }

  assert.equal(InteractiveMode.prototype.showSelector, nativeShowSelector);
});

test("leaves native filtered layout intact when no active-path entry is visible", () => {
  const tree = treeList({
    ids: ["match", "match-child"],
    activeIds: ["hidden-root", "hidden-leaf"],
    children: [
      [null, ["match"]],
      ["match", ["match-child"]],
      ["match-child", []],
    ],
    selectedId: "match-child",
  });

  applyActiveSpineLayout(tree);

  assert.deepEqual(ids(tree), ["match", "match-child"]);
  assert.equal(node(tree, "match").indent, 99);
  assert.equal(node(tree, "match-child").indent, 99);
  assert.equal(
    tree.filteredNodes[tree.selectedIndex].node.entry.id,
    "match-child",
  );
});
