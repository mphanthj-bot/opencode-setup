#!/usr/bin/env node
// MCP bọc `opencode2 --help` đã chuẩn hóa. Spawn thật opencode2, không hardcode help.
import { McpServer } from "@modelcontextprotocol/server";
import { StdioServerTransport } from "@modelcontextprotocol/server/stdio";
import * as z from "zod/v4";
import { spawnSync } from "node:child_process";

const OPENCODE_BIN = process.env.OPENCODE_BIN || "opencode2";
const ALLOW = new Set([
  "", "upgrade", "uninstall", "acp", "api", "debug", "auth", "mcp", "plugin",
  "models", "stats", "mini", "run", "session", "service", "reload", "pair", "serve",
  "debug agents", "debug config", "debug paths", "auth list", "auth login",
  "auth logout", "auth switch", "mcp list", "mcp add", "mcp auth", "mcp logout",
  "plugin list", "plugin add", "plugin check", "plugin update", "plugin remove",
  "session list", "session delete", "session export", "session import",
  "service start", "service restart", "service status", "service stop",
  "service get", "service set", "service unset",
]);

function help(args) {
  const r = spawnSync(OPENCODE_BIN, [...args, "--help"], {
    encoding: "utf8",
    timeout: 5000,
  });
  const out = (r.stdout || "") + (r.stderr || "");
  if (r.error) return `Lỗi spawn ${OPENCODE_BIN}: ${r.error.message}`;
  return out.trim() || "(trống)";
}

const OVERVIEW = `opencode2 v2.2.0 — CLI chính: opencode <subcommand> [flags] [<directory>]
17 subcommand: upgrade/update, uninstall, acp, api, debug, auth, mcp, plugin, models, stats, mini, run, session, service, reload, pair, serve.
Global flags mọi lệnh: --help/-h, --version/-v, --wizard, --completions bash|zsh|fish|sh, --log-level all|trace|debug|info|warn|warning|error|fatal|none, --print-logs.
Nhóm cần server có thêm: --standalone, --server string.
Dùng tool opencode2_command_help với command="mcp add" | "run" | "serve" | ... để xem chi tiết từng lệnh.`;

const EXAMPLES = {
  "mcp add": [
    "opencode2 mcp add context7 --global --url https://mcp.context7.com/mcp",
    'opencode2 mcp add context7 --global --url https://mcp.context7.com/mcp --header Authorization="Bearer YOUR_API_KEY"',
    "opencode2 mcp add context7 --global --env CONTEXT7_API_KEY=xxx -- npx -y @upstash/context7-mcp",
    "opencode2 mcp auth context7",
    "opencode2 mcp list",
  ].join("\n"),
  run: [
    'opencode2 run -m opencode/muse-spark-1.3-contributor-free "fix bug"',
    "opencode2 run --format json --auto \"triển khai task\"",
  ].join("\n"),
  serve: ["opencode2 serve --port 8082", "opencode2 serve --cors https://app.example.com"].join("\n"),
};

const GUIDE = {
  remote: [
    "opencode2 mcp add <name> --global --url https://host/mcp --header Authorization=\"Bearer TOKEN\"",
    "VD: opencode2 mcp add context7 --global --url https://mcp.context7.com/mcp",
  ].join("\n"),
  local: [
    "opencode2 mcp add <name> --global --env KEY=val -- <cmd> [args...]",
    "VD: opencode2 mcp add opencode2-help --global -- node /root/opencode2-help-mcp2/server.js",
    "VD: opencode2 mcp add context7 --global --env CONTEXT7_API_KEY=xxx -- npx -y @upstash/context7-mcp",
  ].join("\n"),
  oauth: ["opencode2 mcp add <name> --global --url https://host/mcp/oauth", "opencode2 mcp auth <name>"].join("\n"),
  context7: [
    "# Không key (rate thấp):",
    "opencode2 mcp add context7 --global --url https://mcp.context7.com/mcp",
    "# Có key (khuyên dùng):",
    'opencode2 mcp add context7 --global --url https://mcp.context7.com/mcp --header Authorization="Bearer YOUR_API_KEY"',
    "# Local stdio:",
    "opencode2 mcp add context7 --global --env CONTEXT7_API_KEY=YOUR_API_KEY -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY",
    "opencode2 mcp list && opencode2 reload",
  ].join("\n"),
};

const server = new McpServer({ name: "opencode2-help", version: "1.0.0" });

server.registerTool(
  "opencode2_overview",
  { description: "Tổng quan opencode2: cây lệnh + global flags", inputSchema: z.object({}) },
  async () => ({ content: [{ type: "text", text: `${OVERVIEW}\n\n--- opencode --help ---\n${help([])}` }] }),
);

server.registerTool(
  "opencode2_command_help",
  {
    description: "Help chi tiết 1 lệnh opencode2, kèm ví dụ chuẩn hóa",
    inputSchema: z.object({ command: z.string().describe('VD: "mcp add", "run", "serve"') }),
  },
  async ({ command }) => {
    const cmd = command.trim();
    if (!ALLOW.has(cmd)) {
      return {
        content: [{ type: "text", text: `Lệnh không hợp lệ: "${cmd}". Hợp lệ: ${[...ALLOW].join(", ")}` }],
        isError: true,
      };
    }
    const parts = cmd === "" ? [] : cmd.split(/\s+/);
    const raw = help(parts);
    const key = cmd.split(" ").pop();
    const ex = EXAMPLES[cmd] || EXAMPLES[key] || "";
    const text = ex ? `${raw}\n\n--- VÍ DỤ CHUẨN HÓA ---\n${ex}` : raw;
    return { content: [{ type: "text", text }] };
  },
);

server.registerTool(
  "opencode2_mcp_guide",
  {
    description: "Hướng dẫn copy-paste opencode2 mcp add",
    inputSchema: z.object({ kind: z.enum(["local", "remote", "oauth", "context7"]).default("context7") }),
  },
  async ({ kind }) => ({ content: [{ type: "text", text: GUIDE[kind] }] }),
);

await server.connect(new StdioServerTransport());
