---
name: opencode2-help
description: Tra cứu cú pháp opencode2 CLI v2.2.0 và hướng dẫn opencode2 mcp add chuẩn (local/remote/oauth/context7)
---

# opencode2-help

Tra cứu lệnh `opencode2` CLI và cách gắn MCP server, ưu tiên qua MCP tools live (help spawn thật từ binary, luôn tươi).

## When to use

Dùng skill này khi người dùng hỏi về: cú pháp bất kỳ lệnh `opencode2` (run, serve, mcp, session, auth, stats...), global flags, hoặc cách `mcp add/list/auth` một server mới (đặc biệt `context7`).

## Instructions

1. Tổng quan trước: gọi `opencode2_overview` để lấy cây 17 subcommand + global flags.
2. Help chi tiết: gọi `opencode2_command_help` với `command` thuộc whitelist, ví dụ `"mcp add"`, `"run"`, `"serve"`, `"session list"`. Lệnh lạ trả `isError` kèm danh sách hợp lệ — báo lại cho user, không đoán.
3. Hướng dẫn gắn MCP: gọi `opencode2_mcp_guide` với `kind` = `local` | `remote` | `oauth` | `context7` (mặc định `context7`), trả lệnh copy-paste cho user.
4. Sau khi `mcp add`, luôn chạy `opencode2 reload` rồi `opencode2 mcp list` để xác nhận `connected`.
5. Fallback khi MCP tools không khả dụng: chạy trực tiếp `opencode2 <command> --help` trong terminal. Quy tắc chuẩn theo `opencode2 mcp add --help`: remote dùng `--url` + `--header`, local dùng `--env` + `--` trước command, `--global` để ghi global config.
6. Context7 không key vẫn chạy (rate thấp) tại `https://mcp.context7.com/mcp`; có key thì thêm header `Authorization: Bearer YOUR_API_KEY`.
