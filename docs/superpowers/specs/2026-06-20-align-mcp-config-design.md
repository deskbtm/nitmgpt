# Spec: Align MCP Configuration from Cursor to Codex

## Goal
Align the Codex MCP configuration file (`.codex/config.toml`) with the source of intent (`.cursor/mcp.json`) in order to resolve missing HTTP headers and environment settings for the MCP servers.

## Design
Directly map the `context7` custom headers from `.cursor/mcp.json` into `.codex/config.toml` under the `[mcp_servers.context7.http_headers]` key.

### Target file: .codex/config.toml
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

## Verification
Ensure the file `.codex/config.toml` is written correctly and conforms to valid TOML.
