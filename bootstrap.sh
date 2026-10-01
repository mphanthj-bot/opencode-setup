#!/usr/bin/env bash
# Khoi phuc toan bo setup opencode2 tren may moi: chay 1 lenh duy nhat.
#   git clone <repo> && cd opencode-setup && ./bootstrap.sh
# Idempotent: chay lai bao nhieu lan cung an toan (co gi thi skip).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_JSON="$HOME/.config/opencode2/opencode.json"

log() { echo "[bootstrap] $*"; }

# 1. Tim node chay duoc (uu tien node that, tranh shim hong)
NODE_BIN=""
for c in node /usr/bin/node /usr/local/bin/node; do
  if command -v "$c" >/dev/null 2>&1 && "$c" --version >/dev/null 2>&1; then
    NODE_BIN="$(command -v "$c")"
    break
  fi
done
[ -z "$NODE_BIN" ] && { log "LOI: khong tim thay node"; exit 1; }
log "node: $NODE_BIN ($("$NODE_BIN" --version))"

# 2. opencode2 CLI
if ! command -v opencode2 >/dev/null 2>&1; then
  log "cai opencode2..."
  npm install -g opencode2
else
  log "opencode2: $(opencode2 --version 2>&1 | head -n1)"
fi

# 3. Cai deps cho MCP local
log "npm install mcp/opencode2-help..."
(cd "$REPO_DIR/mcp/opencode2-help" && npm install --no-audit --no-fund)

# 4. Helper: them MCP neu chua co
has_mcp() { opencode2 mcp list 2>/dev/null | grep -q " $1 "; }
add_remote() { # add_remote <name> <url> [header]
  if has_mcp "$1"; then log "mcp $1: da co, skip"; return; fi
  if [ -n "${3:-}" ]; then
    opencode2 mcp add "$1" --global --url "$2" --header "$3"
  else
    opencode2 mcp add "$1" --global --url "$2"
  fi
  log "mcp $1: da them"
}

# 5. context7 (co CONTEXT7_API_KEY thi gan header, khong thi anonymous)
if has_mcp "context7"; then
  log "mcp context7: da co, skip"
elif [ -n "${CONTEXT7_API_KEY:-}" ]; then
  opencode2 mcp add context7 --global --url https://mcp.context7.com/mcp \
    --header "Authorization=Bearer $CONTEXT7_API_KEY"
  log "mcp context7: da them (co API key)"
else
  opencode2 mcp add context7 --global --url https://mcp.context7.com/mcp
  log "mcp context7: da them (anonymous)"
fi

# 6. aitracuuluat
add_remote "aitracuuluat" "https://mcp.aitracuuluat.vn/mcp"

# 7. opencode2-help (local, duong dan tuyet doi theo repo hien tai)
if has_mcp "opencode2-help"; then
  log "mcp opencode2-help: da co, skip"
else
  opencode2 mcp add opencode2-help --global -- \
    "$NODE_BIN" "$REPO_DIR/mcp/opencode2-help/server.js"
  log "mcp opencode2-help: da them"
fi

# 8. Model mac dinh (merge, khong dung cham mcp servers)
"$NODE_BIN" -e '
const fs=require("fs"),p=process.env.HOME+"/.config/opencode2/opencode.json";
let c={}; try{c=JSON.parse(fs.readFileSync(p,"utf8"));}catch{}
c.$schema=c.$schema||"https://opencode.ai/config.json";
c.model={providerID:"opencode",model:"muse-spark-1.3-contributor-free"};
fs.mkdirSync(require("path").dirname(p),{recursive:true});
fs.writeFileSync(p,JSON.stringify(c,null,2)); console.log("[bootstrap] model mac dinh: OK");
'

# 9. Skill find-skills global
if npx -y skills@latest list -g 2>/dev/null | grep -q "find-skills"; then
  log "skill find-skills: da co, skip"
else
  npx -y skills@latest add vercel-labs/skills -g -y -s find-skills
  log "skill find-skills: da them"
fi

# 10. Reload + xac nhan
opencode2 reload
log "=== TRANG THAI CUOI ==="
opencode2 mcp list
