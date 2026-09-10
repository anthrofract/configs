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

## Updating the flake

When asked to update the flake, follow these steps. If any step fails, stop and report the error and suggested fixes. Do not attempt fixes unless asked.

1. Run `jj git fetch`, then inspect the working-copy change (`@`). If it is both empty and has no description, stay on the current change. Otherwise, run `jj new` to start a new change on top of `@`.
2. Find the latest stable omp release at https://github.com/can1357/oh-my-pi, excluding prereleases unless requested. Update `inputs.omp.url` in `flake.nix` to that release tag if needed.
3. Run `just update` (which runs `nix flake update`). If the working-copy diff is empty afterward, stop and report that there are no updates; do not build or commit.
4. Run `just build`. Do not activate the configuration or run `just switch`, `just test`, or `just boot`.
5. If the build succeeds, run `jj commit -m "Update flake"`.
6. Report that the configuration built successfully and was committed but was not activated. Summarize the changed input versions/revisions and notable changes supported by release notes; distinguish these from anything not investigated.
