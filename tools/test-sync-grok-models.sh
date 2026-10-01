#!/usr/bin/env bash
# Test cho tools/sync-grok-models.sh (RED phase). Chay: ./tools/test-sync-grok-models.sh
# Khong can network (dung fixture), khong dung cham config that.
set -uo pipefail

SCRIPT="$PWD/tools/sync-grok-models.sh"
FIX="$PWD/tools/fixtures/models-min.json"
PASS=0; FAIL=0
TMP="$(mktemp -d)"

ok()   { PASS=$((PASS+1)); echo "PASS: $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL: $1"; }

# 1. chen block khi chua co sentinel
cat > "$TMP/a.toml" <<'EOF'
[models]
default = "x"

[model.giu-nguyen]
model = "giu-nguyen"
EOF
"$SCRIPT" --registry "file://$FIX" --config "$TMP/a.toml" --write >/dev/null 2>&1
grep -q "BEGIN OPENCODE-SYNC" "$TMP/a.toml" && ok "chen sentinel block" || bad "chen sentinel block"
grep -q '\[model\.giu-nguyen\]' "$TMP/a.toml" && ok "giu nguyen content ngoai block" || bad "giu nguyen content ngoai block"

# 2. idempotent: chay lai khong doi file, --check exit 0
md5sum "$TMP/a.toml" | cut -d' ' -f1 > "$TMP/md5"
"$SCRIPT" --registry "file://$FIX" --config "$TMP/a.toml" --write >/dev/null 2>&1
[ "$(md5sum "$TMP/a.toml" | cut -d' ' -f1)" = "$(cat "$TMP/md5")" ] && ok "idempotent" || bad "idempotent"
"$SCRIPT" --registry "file://$FIX" --config "$TMP/a.toml" --check >/dev/null 2>&1
[ $? -eq 0 ] && ok "--check exit 0 khi khong doi" || bad "--check exit 0 khi khong doi"

# 3. --check exit 1 khi co thay doi
cat > "$TMP/b.toml" <<'EOF'
[model.big-pickle]
model = "big-pickle"
context_window = 1048576
EOF
"$SCRIPT" --registry "file://$FIX" --config "$TMP/b.toml" --check >/dev/null 2>&1
[ $? -eq 1 ] && ok "--check exit 1 khi co thay doi" || bad "--check exit 1 khi co thay doi"

# 4. sua ctx sai + xoa legacy ngoai block
"$SCRIPT" --registry "file://$FIX" --config "$TMP/b.toml" --write >/dev/null 2>&1
grep -q "context_window = 200000" "$TMP/b.toml" && ok "sua ctx big-pickle=200000" || bad "sua ctx big-pickle=200000"
[ "$(grep -c '\[model\.big-pickle\]' "$TMP/b.toml")" = "1" ] && ok "khong trung section" || bad "khong trung section"

# 5. backup duoc tao
ls "$TMP/b.toml.bak-"* >/dev/null 2>&1 && ok "backup .bak-date" || bad "backup .bak-date"

# 6. model trong allowlist nhung thieu o registry -> loi
echo '{"opencode":{"models":{}}}' > "$TMP/empty.json"
"$SCRIPT" --registry "file://$TMP/empty.json" --config "$TMP/a.toml" --check >/dev/null 2>&1
[ $? -ne 0 ] && ok "bao loi khi registry thieu model" || bad "bao loi khi registry thieu model"

rm -rf "$TMP"
echo "--- $PASS pass, $FAIL fail ---"
[ "$FAIL" -eq 0 ]
