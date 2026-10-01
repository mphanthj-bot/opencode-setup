# Spec: sync-grok-models.sh (2026-10-01)

## Ask
Trị trùng model trong picker Grok và sync động `context_window` theo runtime opencode.

## Design decisions
- Source of truth duy nhất: `https://models.opencode.ai/api.json` (registry chính chủ).
- Quản lý 7 section tên ngắn trong block sentinel
  `# BEGIN/END OPENCODE-SYNC` ở `~/.grok/config.toml`.
  `muse-spark-1.3` ủy quyền cho FCC (`[model.muse-spark-zen]`) — chỉ ghi comment.
- Không đụng section do FCC harness sở hữu (`opencode_zen/*`, `muse-spark-zen`):
  `fork_secondary_model` đang tham chiếu `opencode_zen/space-bunny-free`.
- Section legacy `[model.<short>]` ngoài block cho cùng model thì bị xóa (chống trùng).
- Chỉ dùng `bash + python3` (không `jq`, máy mới nào cũng có).
- Mặc định `--check` (khô); `--write` backup `.bak-YYYYMMDD` trước.
- Registry trả 403 nếu thiếu User-Agent → gửi `User-Agent: opencode-setup-sync/1.0`.

## Files changed
- `tools/sync-grok-models.sh` (mới)
- `tools/test-sync-grok-models.sh` + `tools/fixtures/models-min.json` (mới, 9 asserts)

## Edge cases
- Registry thiếu model trong allowlist → exit 2, không ghi gì.
- Chạy lại idempotent (byte-identical, `--check` exit 0).
- File không có sentinel → append block cuối file.
- Nội dung ngoài block giữ nguyên byte.

## Trade-offs
- Vẫn còn trùng tên với section FCC (`space-bunny-free` vs `opencode_zen/space-bunny-free`):
  xóa phía FCC có thể bị harness ghi lại + gãy `fork_secondary_model`. Chấp nhận.
- `context_window` lấy từ registry `limit.context`, `max_completion_tokens` từ `limit.output`.
