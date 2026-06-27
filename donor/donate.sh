#!/usr/bin/env bash
# Donate your unused Claude/Codex capacity. One command.
#   ./donate.sh
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p auths logs

# 0. Seed runtime config from the template on first run (config.yaml is gitignored).
[ -f config.yaml ] || cp config.example.yaml config.yaml

# 1. Ensure this donor has a client key (the gateway uses it to reach you).
if grep -q "sk-donor-CHANGE-ME" config.yaml; then
  KEY="sk-donor-$(openssl rand -hex 16)"
  sed -i.bak "s/sk-donor-CHANGE-ME/$KEY/" config.yaml && rm -f config.yaml.bak
fi
KEY=$(grep -Eo 'sk-donor-[a-z0-9]+' config.yaml | head -1)

# 2. If no subscription is logged in yet, run the OAuth login now.
#    Provider: ./donate.sh [claude|codex|both]  (default: claude)
if [ -z "$(ls -A auths 2>/dev/null)" ]; then
  PROVIDER="${1:-claude}"
  IMG="eceasy/cli-proxy-api:latest"
  login() {  # $1 = -claude-login | -codex-login
    echo
    echo "→ OAuth login ($1). A URL will print below."
    echo "  1) Open it in your browser and authorize."
    echo "  2) Your browser redirects to a localhost page that WON'T load — that's fine."
    echo "  3) Copy that full URL from the address bar and paste it here when asked."
    docker run --rm -it \
      -v "$PWD/config.yaml:/CLIProxyAPI/config.yaml" \
      -v "$PWD/auths:/root/.cli-proxy-api" \
      --entrypoint ./CLIProxyAPI "$IMG" -config config.yaml "$1" -no-browser
  }
  case "$PROVIDER" in
    claude) login -claude-login ;;
    codex)  login -codex-login ;;
    both)   login -claude-login; login -codex-login ;;
    *) echo "unknown provider '$PROVIDER' (use: claude|codex|both)"; exit 1 ;;
  esac
  echo
  echo "✓ logged in. Token saved in ./auths (stays on this machine). Re-run ./donate.sh"
  exit 0
fi

# 3. Serve + open the outbound tunnel.
echo "→ starting (CLIProxyAPI + outbound tunnel)"
docker compose up -d

# 4. Grab the public URL Cloudflare assigned.
echo "→ waiting for your public URL"
URL=""
for i in $(seq 1 30); do
  URL=$(docker compose logs tunnel 2>/dev/null | grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' | tail -1 || true)
  [ -n "$URL" ] && break
  sleep 2
done

echo
echo "============================================================"
echo " You are now donating. Send these two values to the operator:"
echo "   URL:        ${URL:-<not found yet — check: docker compose logs tunnel>}"
echo "   Client key: $KEY"
echo "============================================================"
echo "Stop anytime:  docker compose down"
