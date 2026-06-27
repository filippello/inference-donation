#!/usr/bin/env bash
# Donate your unused Claude/Codex capacity. One command.
#   ./donate.sh
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p auths logs

# 1. Ensure this donor has a client key (the gateway uses it to reach you).
if grep -q "sk-donor-CHANGE-ME" config.yaml; then
  KEY="sk-donor-$(openssl rand -hex 16)"
  sed -i.bak "s/sk-donor-CHANGE-ME/$KEY/" config.yaml && rm -f config.yaml.bak
fi
KEY=$(grep -Eo 'sk-donor-[a-z0-9]+' config.yaml | head -1)

# 2. If no subscription is logged in yet, show the REAL login commands from your
#    own binary (we don't guess them) and stop here.
if [ -z "$(ls -A auths 2>/dev/null)" ]; then
  echo "No subscription logged in yet. Available auth commands for your build:"
  echo "------------------------------------------------------------------"
  docker compose run --rm cli-proxy-api --help 2>&1 | sed -n '1,40p' || true
  echo "------------------------------------------------------------------"
  echo "Run the Claude and/or Codex login command shown above (opens your browser),"
  echo "then re-run ./donate.sh. Your token stays in ./auths on this machine."
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
