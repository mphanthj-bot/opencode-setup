# Bug: FCC proxy :8082 chet + Zen tu choi free-tier (2026-10-01)

## Ask
Dung lai proxy FCC de Grok chay model free opencode.

## Root cause
1. Proxy chet (khong process, khong listen :8082). Log cuoi truoc khi chet:
   upstream Zen tra 500 hang loat (`POST /v1/responses` ~200s/timeout).
2. Sau khi dung lai (`fcc-server`, healthy, `/v1/models` 200), Zen van 403
   `FreeTierError` ngay ca voi OPENCODE_API_KEY cua harness:
   - `space-bunny-free`: mo that, anonymous OK, `cost:"0"`.
   - 7 model free con lai: chi chay "within OpenCode" (opencode gui kem
     `x-opencode-client` + `x-opencode-ticket`; spoof header tay van 403).
   - Ket luan: entitlement free-tier nam phia tai khoan/key, khong phai loi cau hinh.

## Fix
- Khoi dong lai: `/root/.local/bin/fcc-server >> /root/.fcc/logs/server.log 2>&1`
  (chay nen). Kiem tra: `curl /v1/models` 200.
- Giua nguyen config Grok truc tiep Zen cho 7 section tu quan (it nhat
  space-bunny chay duoc ngay, khong phu thuoc proxy). 3 section FCC giu nguyen
  tro proxy (duong chinh thuc khi entitlement co lai).
- Khong bypass ticket (vi pham policy vendor).

## Tests
- `curl :8082/v1/models` 200, catalog `free-claude-code`.
- `grok -m space-bunny-free` (direct Zen): `"text":"OK"`.
- `grok -m mimo-free` / `-m opencode_zen/longcat-2.5-preview-free`: 403 FreeTierError
  (duong truc tiep lan proxy) — loi phia Zen, da ghi nhan.

## Prevention & sweep
- `tools/sync-grok-models.sh --check` se bao diff neu registry doi gia/entitlement.
- Khi proxy song va key co lai entitlement: chay `--write` de tro ve dang proxy
  (da mo ta trong `docs/spec-20261001-sync-grok-models.md`).
