# Repository Guidelines

>This repository is a Nix flake for multi‑host NixOS and Home Manager configuration.

## Project Structure & Module Organization
- `flake.nix` — entrypoint; defines `nixosConfigurations` and `hostDefs` mapping hosts to modules.
- `hosts/<name>/` — machine‑specific NixOS config (e.g., `hosts/wsl/wsl.nix`, `hosts/lenovo/*`).
- `modules/system/*.nix` — shared system modules (`core.nix`, `docker.nix`, `vscode-remote.nix`).
- `modules/home/*.nix` — Home Manager modules (`cli.nix`, `git.nix`, `ssh.nix`, `nixvim.nix`, `zsh.nix`).
- `modules/vscode/*` — VS Code packaging/settings for GUI and remote.
- `home/home.nix` — user profile aggregator; imports the Home modules.
- `scripts/` — helper scripts (e.g., `scripts/auth.sh`).
- `docs/` — architecture/usage notes.

## Build, Test, and Development Commands
- Run static checks: `nix flake check` (executes `statix` + `deadnix`).
- Build a system: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
- Apply to a host: `sudo nixos-rebuild test --flake .#<host>` then `sudo nixos-rebuild switch --flake .#<host>`.
- Apply Home config (standalone): `home-manager switch --flake .#empathy@leny`.

## Coding Style & Naming Conventions
- Nix formatting: use `nixfmt` (RFC style). Example: `nixfmt -w .`.
- Lint: `statix check .`; find unused: `deadnix --fail .`.
- Use two‑space indentation; one option per line; prefer lower‑kebab‑case filenames (e.g., `vscode-remote.nix`).
- Keep modules small and focused; avoid inlining secrets or host‑specific logic in shared modules.

## Testing Guidelines
- Always run `nix flake check` before pushing.
- For system changes, validate with `nixos-rebuild test` on the targeted host before `switch`.
- No unit tests here; rely on flake checks and manual host verification.

## Commit & Pull Request Guidelines
- Follow Conventional Commits: `feat:`, `fix:`, `refactor:`, `build:` (see git history).
- PRs must include: summary, affected hosts, verification commands/output, and links to issues.
- If changing shared modules (under `modules/system` or `modules/home`), call out cross‑host impact.

## Security & Configuration Tips
- Do not commit credentials. `scripts/auth.sh` takes credentials via args/env; keep private.
- Proxy helpers are in Zsh (`setproxy`, `unsetproxy`); avoid hard‑coding proxies in modules.
- Keep default substituters; only modify mirrors with justification.
