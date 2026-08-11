---
name: obsidian-runtime
description: Inspect and control a running Obsidian application through the real Obsidian CLI. Use only for Obsidian plugin or theme development/debugging, or when a task explicitly requires Obsidian-interpreted runtime state such as resolved backlinks, unresolved links, parsed tags/properties/tasks, active vault/file/tabs/workspace, registered commands, plugin state, console errors, DOM/CSS inspection, app evaluation, or screenshots. Do not use for ordinary Markdown reading, writing, searching, note organization, vault maintenance, wikilink/frontmatter editing, bulk text changes, or filesystem operations; use direct file tools for those tasks even when the files are in an Obsidian vault.
---

# Obsidian Runtime

Operate Obsidian only when the application must interpret the vault or expose runtime state. Keep ordinary knowledge-base work on the filesystem.

## Enforce the boundary

Proceed only when at least one condition holds:

1. Develop, test, or debug an Obsidian plugin, theme, or CSS snippet.
2. Query state computed or owned by the running app that direct file tools cannot reliably provide.

Qualifying state includes resolved backlinks, unresolved links, parsed tags/properties/tasks, active UI state, installed or enabled plugins, registered commands, File Recovery or Sync history, console errors, DOM/CSS, evaluated app APIs, and screenshots.

Do not call the CLI merely because the user mentions Obsidian, a vault, notes, or `.md` files. Use filesystem reads, `rg`, and direct edits for ordinary content and structure maintenance. Use dedicated Markdown, Bases, or Canvas tooling when their file formats—not application runtime state—are the actual concern.

## Invoke the correct binary

Use `scripts/obsidian-runtime` from this skill directory for every CLI call. Never invoke the bare `obsidian` command directly: on this Nix-managed macOS system it may be the GUI launcher rather than the CLI.

The runner resolves the actual CLI in this order:

1. `OBSIDIAN_CLI_BIN`, when explicitly set.
2. `obsidian-cli` on `PATH`.
3. The CLI binary inside `/Applications/Obsidian.app`.
4. `/usr/local/bin/obsidian` only when it is a symlink to `obsidian-cli`.

Run `scripts/obsidian-runtime --print-binary` to inspect the selected executable without launching Obsidian. If no valid CLI exists, stop and report the runner's error; do not fall back to the GUI launcher.

## Execute safely

1. Target a vault explicitly when the current directory is not unquestionably inside the intended vault. Put `vault=<name-or-id>` before the command.
2. Run `scripts/obsidian-runtime help <command>` when command syntax is uncertain; the installed CLI help is authoritative.
3. Prefer structured output such as `format=json` when available.
4. Start with read-only inspection commands. Ask for confirmation before permanent deletion, history restoration, plugin installation/uninstallation, publishing, or other destructive or externally visible changes unless the user explicitly requested that action.
5. Remember that Obsidian must be running; the first CLI call may launch it. Report this when it affects the task.
6. If the CLI says it cannot find Obsidian while the app is running, check whether `~/.obsidian-cli.sock` exists. Codex's filesystem sandbox can block this local Unix socket; rerun the same narrowly scoped runner command with the required sandbox escalation instead of changing commands or falling back to GUI automation.
7. Treat empty output as a possible wrong vault, wrong active file, app startup delay, unsupported command, or sandboxed socket. Check `vault`, `version`, and command help before concluding that no data exists.

## Common runtime operations

```bash
# Obsidian-interpreted link state
scripts/obsidian-runtime vault="My Vault" backlinks path="Folder/Note.md" format=json
scripts/obsidian-runtime vault="My Vault" unresolved verbose format=json

# Parsed vault state
scripts/obsidian-runtime vault="My Vault" properties counts format=json
scripts/obsidian-runtime vault="My Vault" tasks todo verbose format=json

# Plugin development loop
scripts/obsidian-runtime plugin:reload id=my-plugin
scripts/obsidian-runtime dev:errors
scripts/obsidian-runtime dev:console level=error
scripts/obsidian-runtime dev:screenshot path=/tmp/obsidian-plugin.png
```

For plugin development, repeat reload, error inspection, targeted DOM/CSS or console inspection, and visual verification until the change is confirmed.
