# Repository Guidelines

>This repository is a multi-host Nix flake for NixOS + macOS (nix-darwin) + Home Manager.

## Layout (Where Things Live)
- `flake.nix` — entrypoint; defines `nixosConfigurations`, `darwinConfigurations`, and shared inputs.
- `hosts/<name>/` — host composition layer.
  - Linux/NixOS hosts: `hosts/wsl`, `hosts/lenovo`, `hosts/devbox`.
  - macOS host: `hosts/macbook-pro` (+ `hosts/macbook-pro/apps` for GUI apps).
- `hosts/common/*` — shared NixOS host modules (`global/` + `optional/`).
- `home/home.nix` — Linux-ish Home Manager aggregator for `homeConfigurations` and NixOS HM.
- `home/profiles/darwin-cli.nix` — macOS Home Manager profile (shell/tools/user dotfiles).
- `modules/system/*.nix` — shared NixOS system modules.
- `modules/home/*.nix` — shared Home Manager modules (mostly for Linux/NixOS targets).
- `modules/cli/modern.nix` — cross-shell modern CLI defaults (fish/starship/fzf/etc).
- `modules/vscode/*` — VS Code shared settings/extensions + GUI/remote split.
- `modules/darwin/app-builders.nix` — macOS app packagers (ZIP/DMG → `.app` + optional CLI links).
- `scripts/` — helper scripts (keep secrets out of git).
- `docs/` — architecture/usage notes.

## Best Practice: System vs Home (CLI vs GUI)
- Prefer **Home Manager** for user-scoped CLI tools and dotfiles (portable, easy to reuse).
- Prefer **nix-darwin systemPackages** for GUI `.app` you want in `/Applications/Nix Apps` / Launchpad.
- macOS GUI apps:
  - Nixpkgs-provided apps: add to `hosts/macbook-pro/apps/default.nix` under `nixpkgsApps`.
  - Custom ZIP/DMG apps: wrap with `mkZipApp`/`mkDmgApp` and add under `customApps`.
- VS Code:
  - Settings/extensions live in `modules/vscode/base.nix` + `modules/vscode/settings.nix`.
  - GUI config uses `modules/vscode/gui.nix`; Remote server uses `modules/vscode/remote.nix`.

## Build / Apply / Checks
- Fast eval (no builds): `nix flake check --no-build`
- Full static checks: `nix flake check` (runs `statix` + `deadnix`)
- NixOS apply: `sudo nixos-rebuild test --flake .#<host>` then `sudo nixos-rebuild switch --flake .#<host>`
- macOS apply: `sudo darwin-rebuild switch --flake .#MacBook-Pro`
- Build only:
  - NixOS: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
  - macOS: `nix build .#darwinConfigurations.MacBook-Pro.system`
- Suppress dirty-tree warnings during iteration: add `--no-warn-dirty` to `nix`/`*-rebuild` commands.

## Debugging Workflow (Keep It Fast)
- Start with the smallest failing target (`nix flake check --no-build` or a single host build).
- Use `--show-trace` for eval errors; use `nix log <drv>` for build logs.
- Use `rg` for searching; avoid broad refactors without a failing reproduction.
- Change one thing at a time, re-evaluate, then commit.

## Style, Validation, Commits
- Formatting: `nixfmt -w .` (keep 2-space indentation and one option per line).
- Lint: `statix check .`; unused: `deadnix --fail .`.
- Commits: small + atomic + Conventional Commits (`feat:`, `fix:`, `refactor:`...). Run `nix flake check --no-build` before committing and `nix flake check` before pushing.

## Security Notes
- Do not commit credentials or tokens; keep private material out of Nix store when possible.
- If proxy settings are needed, prefer per-host modules under `hosts/<name>/` instead of hard-coding globally.
