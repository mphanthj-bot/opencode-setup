# opencode-setup

Đóng gói toàn bộ setup opencode2 để clone lại trên máy mới bằng 1 lệnh.

## Khôi phục máy mới

```bash
git clone <repo-url> opencode-setup && cd opencode-setup && ./bootstrap.sh
```

`bootstrap.sh` tự lo (idempotent — chạy lại bao nhiêu lần cũng an toàn):

1. Tìm `node` chạy được, cài `opencode2` nếu thiếu.
2. `npm install` cho MCP local `mcp/opencode2-help`.
3. `mcp add` 3 server: `context7` (remote), `aitracuuluat` (remote), `opencode2-help` (local, đường dẫn theo repo).
4. Đặt model mặc định `opencode/muse-spark-1.3-contributor-free` (merge JSON, không đụng MCP).
5. Cài skill `find-skills` global (`npx skills`).
6. `reload` + in `mcp list` xác nhận 4 `connected`.

Có `CONTEXT7_API_KEY` thì export trước khi chạy để gắn header (rate cao):

```bash
export CONTEXT7_API_KEY=xxx
./bootstrap.sh
```

## Cấu trúc

```text
opencode-setup/
  bootstrap.sh            # script khôi phục 1 lệnh
  config/opencode.json.example  # model mặc định tham khảo
  mcp/opencode2-help/     # MCP bọc opencode2 --help (server.js + SKILL.md)
  README.md
```

## Không commit

`node_modules/`, API key/secret, session cũ. Muốn giữ session thì
`opencode2 session export <id>` ra file JSON riêng.
