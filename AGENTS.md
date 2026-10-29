# Project instructions

## Repository structure

- `flake.nix` automatically imports every `.nix` file under `config/`, `modules/`, and `packages/`. Do not place scratch files, backups, fixtures, or standalone Nix expressions in those directories.
- Everything under `home/` is deployed to the corresponding path in the user's home directory using live out-of-store symlinks. Do not place unrelated artifacts in this directory; edits to existing files may take effect without a rebuild.
- Keep platform boundaries explicit. Shared modules belong in `flake.commonModules` and must evaluate on both NixOS and nix-darwin. Platform-specific options belong in `flake.nixosModules` or `flake.darwinModules`.
- Treat `hosts/*/hardware.nix` as generated, machine-specific configuration. Put deliberate host configuration in the host's `default.nix` or a reusable module unless the task specifically requires regenerating hardware configuration.
- This repository uses an allowlist `.gitignore`. When adding a new top-level file or directory, add the corresponding exception to `.gitignore`.

## Local configuration

- `config/secrets.nix` is generated from the tracked `config/secrets.nix.age` and is intentionally gitignored.
- Before evaluating the main flake, ensure the plaintext file exists with `just decrypt` and use an explicit `path:.` flake reference so Nix includes it.
- Prefer the matching Just recipe when one exists; recipes that evaluate the main flake handle decryption.
- If a task explicitly changes `config/secrets.nix`, run `just encrypt` so the tracked encrypted file is updated.
- Prefer `~/bin/c`, a cross-platform copy/paste tool, over platform-specific commands such as `wl-copy`, `wl-paste`, `pbcopy`, or `pbpaste`: pipe content to it to copy to the clipboard, or run it interactively to paste clipboard contents.

## Updating the flake

When asked to update the flake, follow these steps. If any step fails, stop and report the error and suggested fixes. Do not attempt fixes unless asked.

Follow these instructions directly and efficiently. Stay focused on the update; avoid unnecessary research, codebase inspection, or rediscovery of documented conventions. Apply the same guidance to delegated tasks.

1. Run `jj git fetch`, then inspect the working-copy change (`@`). If it is both empty and has no description, stay on the current change. Otherwise, run `jj new` to start a new change on top of `@`.
2. Run `just update` (which runs `nix flake update`).
3. Check upstream online and update all pinned software under `packages/` to the latest version on its existing release channel. Edit the package Nix files, updating versions, URLs, revisions, and source/dependency hashes for all platforms. Stop if an update cannot be determined reliably.
4. After both flake-input and local-package updates, if the working-copy diff is empty, stop and report that there are no updates; do not build or commit.
5. Build all version-changed local packages supported on the current platform with `nix build --no-link path:.#<package>`, then run `just build`. Report any packages that could not be built. Do not activate the configuration.
6. If the required builds succeed, run `jj commit -m "Update flake"`.
7. Summarize changed flake-input revisions and all user-facing package version changes, additions, and removals by comparing pre-update and post-update configurations. Group components of the same application and omit dependency-only changes unless they have a notable user-facing impact. Identify supplying inputs where verified. Read and link upstream release notes covering the old-to-new version range. Briefly highlight concrete features, behavior changes, and fixes for each changed package, prioritizing relevance to this configuration, breaking changes, required actions, and security impact. Give major releases more detail.
