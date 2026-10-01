# opencode2-help-mcp2

MCP server bọc `opencode2 --help` đã chuẩn hóa. Spawn thật binary nên help luôn tươi, không hardcode.

## Chạy

```bash
/usr/bin/node /root/opencode2-help-mcp2/server.js
```

## Tools

* `opencode2_overview` — tổng quan 17 subcommand + global flags + full `opencode --help`.
* `opencode2_command_help` (`command`: "mcp add" | "run" | "serve" | ...) — help chi tiết 1 lệnh + ví dụ chuẩn hóa. Lệnh lạ trả `isError`.
* `opencode2_mcp_guide` (`kind`: local|remote|oauth|context7, mặc định context7) — lệnh copy-paste `opencode2 mcp add`.

## Gắn vào opencode2

```bash
opencode2 mcp add opencode2-help --global -- /usr/bin/node /root/opencode2-help-mcp2/server.js
opencode2 reload && opencode2 mcp list
```

## Gỡ

```bash
opencode2 mcp logout opencode2-help 2>/dev/null; opencode2 reload
# xóa entry opencode2-help trong /root/.config/opencode2/opencode.json rồi reload
```
