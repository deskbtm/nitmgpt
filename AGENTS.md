# Codex Project Instructions

This repository is configured for Cursor first. When working here through Codex,
treat the Cursor configuration as project policy and bridge it into the Codex
workflow.

## Cursor Rules

Before changing files, read the relevant rules from `.cursor/rules/`.

Always apply:

- `.cursor/rules/i18n-sync.mdc` for any user-facing text changes.

Apply by task or file type:

- `.cursor/rules/flutter-expert.mdc` when editing `lib/**/*.dart`.
- `.cursor/rules/frontend-design.mdc` when building or changing Flutter UI.
- `.cursor/rules/unicons-preference.mdc` when adding or changing icons.
- `.cursor/rules/code-review.mdc` when reviewing changes.

If a Cursor rule conflicts with a direct user request, follow the user request
and mention the trade-off.

## MCP

Codex MCP servers are configured in `.codex/config.toml`.

Cursor MCP servers are configured in `.cursor/mcp.json`.

Keep both files aligned when adding or removing project MCP servers. Prefer the
Cursor file as the source of intent, then translate it into Codex TOML syntax.

## Project Conventions

- Follow the domain language in `CONTEXT.md`.
- Respect ADRs in `docs/adr/`.
- Keep unrelated user changes intact; this worktree may already be dirty.
- For Flutter work, prefer focused verification such as `dart analyze`,
  `flutter test`, or existing `tool/verify_*.dart` scripts depending on the
  files touched and local native dependency constraints.
