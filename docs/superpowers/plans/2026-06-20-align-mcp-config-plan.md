# Align MCP Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the Codex MCP configuration file (`.codex/config.toml`) with the Cursor configuration (`.cursor/mcp.json`).

**Architecture:** Directly map the `context7` custom headers from `.cursor/mcp.json` into `.codex/config.toml` under the `[mcp_servers.context7.http_headers]` key.

**Tech Stack:** TOML

---

### Task 1: Update .codex/config.toml

**Files:**
- Modify: `.codex/config.toml`

- [ ] **Step 1: Write minimal implementation**

Update `.codex/config.toml`:
```toml
[mcp_servers.codegraph]
command = "codegraph"
args = [
    "serve",
    "--mcp",
    "--path",
    ".",
]

[mcp_servers.dart]
command = "dart"
args = [
    "mcp-server",
    "--experimental-mcp-server",
    "--force-roots-fallback",
]

[mcp_servers.context7]
url = "https://mcp.context7.com/mcp"
[mcp_servers.context7.http_headers]
"CONTEXT7_API_KEY" = "ctx7sk-861b0161-a942-48d4-b841-498156959f62"

[mcp_servers.deepwiki]
url = "https://mcp.deepwiki.com/mcp"
```

- [ ] **Step 2: Commit**

```bash
git add .codex/config.toml
git commit -m "chore: align context7 mcp headers with cursor configuration"
```
