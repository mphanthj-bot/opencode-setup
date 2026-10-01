#!/usr/bin/env bash
# Sinh block [model.*] Grok tu registry opencode (source of truth duy nhat).
# Usage:
#   sync-grok-models.sh --check                  # kho (mac dinh): in diff, exit 1 neu co thay doi
#   sync-grok-models.sh --write                  # ghi that (backup .bak-YYYYMMDD truoc)
#   sync-grok-models.sh --registry URL --config PATH [--check|--write]
# Model muse-spark-1.3 do FCC quan ly ([model.muse-spark-zen]) nen chi ghi comment.
set -euo pipefail

REGISTRY="https://models.opencode.ai/api.json"
CONFIG="$HOME/.grok/config.toml"
MODE="check"
BEGIN="# BEGIN OPENCODE-SYNC (do not edit: sinh boi tools/sync-grok-models.sh)"
END="# END OPENCODE-SYNC"

# short-section -> registry-id (giu ten cu cho quen picker)
MANAGED="big-pickle=big-pickle ling-flash-fin-free=ling-3.0-flash-fin-free longcat-free=longcat-2.5-preview-free mimo-free=mimo-v2.6-flash-free nemotron-ultra-free=nemotron-3-ultra-free nemotron-lightning-free=nemotron-3.5-lightning-free space-bunny-free=space-bunny-free"

while [ $# -gt 0 ]; do
  case "$1" in
    --registry) REGISTRY="$2"; shift 2;;
    --config)   CONFIG="$2";   shift 2;;
    --check)    MODE="check";  shift;;
    --write)    MODE="write";  shift;;
    *) echo "unknown flag: $1" >&2; exit 2;;
  esac
done

export MANAGED REGISTRY
BLOCK="$(python3 - <<'EOF'
import json, os, urllib.request
reg = os.environ["REGISTRY"]
if reg.startswith("file://"):
    raw = open(reg[7:], encoding="utf-8").read()
else:
    req = urllib.request.Request(reg, headers={"User-Agent": "opencode-setup-sync/1.0"})
    raw = urllib.request.urlopen(req, timeout=30).read().decode("utf-8")
models = json.loads(raw)["opencode"]["models"]
out = []
missing = []
for pair in os.environ["MANAGED"].split():
    short, rid = pair.split("=", 1)
    m = models.get(rid)
    if not m or "limit" not in m or "context" not in m["limit"]:
        missing.append(rid); continue
    lim = m["limit"]
    out.append(f"""[model.{short}]
model = "{rid}"
model_provider = "zen-local"
name = "{rid} (Zen)"
api_backend = "responses"
api_key = "public"
reasoning_summary = "concise"
max_completion_tokens = {lim.get("output", 32768)}
context_window = {lim["context"]}
""")
if missing:
    raise SystemExit("registry thieu model: " + ", ".join(missing))
out.append("# muse-spark-1.3-contributor-free: do FCC quan ly ([model.muse-spark-zen]), khong sinh o day")
print("\n".join(out).rstrip())
EOF
)" || exit 2

NEWCFG="$(python3 - "$CONFIG" "$BEGIN" "$END" "$BLOCK" <<'EOF'
import sys, re
path, begin, end, block = sys.argv[1:5]
managed = [p.split("=")[0] for p in __import__("os").environ["MANAGED"].split()]
src = open(path, encoding="utf-8").read()
lines = src.splitlines(keepends=True)
# 1. xoa section [model.<short>] cu nam NGOAI block (tranh trung)
hdr = re.compile(r"^\[model\.([^\]]+)\]\s*$")
kept, i, n, in_block = [], 0, len(lines), False
while i < n:
    s = lines[i].rstrip("\n")
    if s == begin: in_block = True
    elif s == end: in_block = False
    m = hdr.match(s)
    if m and m.group(1) in managed and not in_block:
        i += 1
        while i < n and not lines[i].lstrip().startswith("[") and lines[i].strip() != begin:
            i += 1
        continue
    kept.append(lines[i]); i += 1
src = "".join(kept)
# 2. thay block cu / chen block moi
newblock = begin + "\n" + block + "\n" + end + "\n"
if begin in src:
    pat = re.compile(re.escape(begin) + r".*?" + re.escape(end) + r"\n?", re.S)
    src = pat.sub(lambda _: newblock, src, count=1)
else:
    src = src.rstrip("\n") + "\n\n" + newblock
sys.stdout.write(src.rstrip("\n") + "\n")
EOF
printf x
)"; NEWCFG="${NEWCFG%x}"

TMPNEW="$(mktemp)"
printf '%s' "$NEWCFG" > "$TMPNEW"
# (NEWCFG giu nguyen newline cuoi nho ${NEWCFG%x}; file that luon ket thuc dung 1 \n)
if [ "$MODE" = "check" ]; then
  if cmp -s "$TMPNEW" "$CONFIG"; then echo "in-sync: khong co thay doi"; rm -f "$TMPNEW"; exit 0; fi
  diff -u "$CONFIG" "$TMPNEW" || true
  rm -f "$TMPNEW"
  exit 1
fi

# --write
if cmp -s "$TMPNEW" "$CONFIG"; then echo "in-sync: khong co thay doi"; rm -f "$TMPNEW"; exit 0; fi
cp "$CONFIG" "$CONFIG.bak-$(date +%Y%m%d)"
cat "$TMPNEW" > "$CONFIG"
rm -f "$TMPNEW"
echo "da ghi $CONFIG (backup $CONFIG.bak-$(date +%Y%m%d))"
