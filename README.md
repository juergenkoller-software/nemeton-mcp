# Nemeton MCP Server

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue.svg)](https://apple.com/macos)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![MCP](https://img.shields.io/badge/protocol-MCP-purple.svg)](https://modelcontextprotocol.io)
[![juergenkoller-software/nemeton-mcp MCP server](https://glama.ai/mcp/servers/juergenkoller-software/nemeton-mcp/badges/score.svg)](https://glama.ai/mcp/servers/juergenkoller-software/nemeton-mcp)

**Control native macOS virtual machines from Claude Desktop, Claude Code, Cursor, or any MCP client.**

This is the official [Model Context Protocol](https://modelcontextprotocol.io) bridge for [**Nemeton**](https://store.juergenkoller.software/en/apps/nemeton) — a native macOS app that creates and manages Linux and macOS VMs using Apple's `Virtualization.framework` (no Parallels, no VMware, no subscriptions).

> **You need the Nemeton app installed and running.** This MCP server is a thin stdio→HTTP bridge — the actual VM logic lives in the app. Get Nemeton at [store.juergenkoller.software/apps/nemeton](https://store.juergenkoller.software/en/apps/nemeton).

---

## What you can do

> "Claude, spin up an Ubuntu 24.04 VM with 4 CPUs and 8 GB RAM, install Docker, and tell me when it's ready."

The MCP server exposes **50+ tools** across these categories:

| Category | Tools |
|---|---|
| **VM Lifecycle** | `list_vms`, `get_vm`, `create_vm`, `update_vm`, `clone_vm`, `delete_vm`, `reorder_vms`, `stop_all` |
| **VM Control** | `start_vm`, `stop_vm`, `force_stop_vm`, `pause_vm`, `resume_vm`, `suspend_vm`, `get_suspend_status` |
| **Snapshots** (CoW on APFS) | `list_snapshots`, `create_snapshot`, `restore_snapshot`, `delete_snapshot` |
| **Console** | `send_console`, `read_console`, `console_execute`, `take_screenshot` |
| **Networking & Files** | `vm_ip`, `ssh_execute`, `file_upload`, `file_download`, `file_list` |
| **GUI Control** | `gui_launch`, `gui_windows`, `vscode_command`, `select_vm` |
| **Clipboard Bridge** | `clipboard_read`, `clipboard_write` |
| **Host Info** | `get_host_info`, `get_metrics` |
| **Storage** | `resize_disk`, `export_vm`, `import_vm` |
| **Distros** | `list_distros` (Ubuntu, Debian, Fedora, Arch — auto-download ISOs) |
| **Display** | `fullscreen_enter`, `fullscreen_exit`, `fullscreen_toggle` |
| **Webhooks** | `list_webhooks`, `register_webhook`, `delete_webhook` |
| **Runtime** | `vm_runtime`, `vm_errors`, `list_downloads` |

Each tool returns structured JSON with VM state, snapshot metadata, console output, or operation result.

---

## Installation

### Prerequisites

1. **macOS 14 (Sonoma) or later** — required for `Virtualization.framework` features.
2. **Nemeton app installed and running** — [get it here](https://store.juergenkoller.software/en/apps/nemeton).
3. **Swift 5.9+** (Xcode 15+) if you want to build from source. Pre-built binaries are also available.

### Build from source

```bash
git clone https://github.com/juergenkoller-software/nemeton-mcp.git
cd nemeton-mcp
swift build -c release
# Binary: .build/release/NemetonMCP
```

### Pre-built binary

Download the latest `NemetonMCP` binary from the [Releases page](https://github.com/juergenkoller-software/nemeton-mcp/releases).

---

## Configuration

### Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "nemeton": {
      "command": "/path/to/NemetonMCP",
      "env": {
        "NEMETON_PORT": "22100",
        "NEMETON_TOKEN": "your-token-here"
      }
    }
  }
}
```

Get `NEMETON_TOKEN` from **Nemeton → Settings → API & Integrations**.

### Claude Code

Add to `~/.claude/mcp.json` (or via `claude mcp add`):

```bash
claude mcp add nemeton /path/to/NemetonMCP \
  --env NEMETON_PORT=22100 \
  --env NEMETON_TOKEN=your-token-here
```

### Cursor / other MCP clients

Same pattern: configure `NemetonMCP` as a stdio MCP server with the two environment variables above.

---

## How it works

```
┌────────────────┐  JSON-RPC stdio   ┌────────────────┐  HTTP+Bearer   ┌────────────────┐
│  Claude/Cursor │ ───────────────►  │  NemetonMCP    │ ─────────────► │  Nemeton.app   │
│  (MCP client)  │ ◄───────────────  │   (this repo)  │ ◄───────────── │  (port 22100)  │
└────────────────┘                   └────────────────┘                └────────────────┘
```

The bridge reads JSON-RPC 2.0 requests from `stdin`, forwards them to Nemeton's local HTTP server at `127.0.0.1:22100/mcp`, and writes responses back to `stdout`. All authentication, VM logic, and tool dispatch happens inside the Nemeton app.

This split lets us keep the MCP wire format open-source (so you can audit it, fork it, or run it through any sandboxing layer you prefer) while the VM internals stay in the app.

---

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `NEMETON_PORT` | `22100` | Port of Nemeton's local HTTP server |
| `NEMETON_TOKEN` | _(none)_ | Bearer token from Nemeton Settings (required for write operations) |

Errors and trace logs are written to `stderr` so they don't pollute the JSON-RPC stdout channel.

---

## About Nemeton

Nemeton is a native macOS app for creating and managing virtual machines using Apple's `Virtualization.framework`. Highlights:

- **No subscription** — one-time purchase, €389
- **Linux & macOS VMs** with automatic ISO/IPSW download
- **CoW snapshots on APFS** — save VM states without wasting disk
- **REST API + WebSocket events** (42 endpoints) for automation
- **MCP server** (this repo) for Claude/AI agents
- **Native performance** — uses Apple's framework directly, no QEMU overhead
- **100% local** — no cloud, no telemetry

→ **[Get Nemeton at store.juergenkoller.software](https://store.juergenkoller.software/en/apps/nemeton)**

---

## License

MIT — see [LICENSE](LICENSE). The bridge is open source; the Nemeton app itself is commercial.

## Issues & support

- **Bridge bugs:** [open an issue](https://github.com/juergenkoller-software/nemeton-mcp/issues)
- **App support:** [support@juergenkoller.software](mailto:support@juergenkoller.software)

Built by [Juergen Koller Software GmbH](https://juergenkoller.software).
