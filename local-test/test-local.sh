#!/usr/bin/env bash
# One-command end-to-end test. Requires Docker running.
#   ./test-local.sh
# Verifies: gateway boots -> routes to a donor -> recipient key works ->
# invalid key is rejected.
set -euo pipefail
cd "$(dirname "$0")"

MASTER="sk-test-master"
GW="http://localhost:4000"
pass=0; fail=0
check() { if [ "$1" = "$2" ]; then echo "  PASS: $3"; pass=$((pass+1)); else echo "  FAIL: $3 (got '$1', want '$2')"; fail=$((fail+1)); fi; }

echo "→ bringing up stack (first run pulls images, can take a minute)"
docker compose up -d

echo "→ waiting for gateway to be ready"
for i in $(seq 1 60); do
  curl -sf "$GW/health/readiness" >/dev/null 2>&1 && break
  sleep 2
  [ "$i" = 60 ] && { echo "gateway never became ready"; docker compose logs gateway | tail -30; exit 1; }
done

echo "→ issuing a recipient key (rpm=4, model=relief-claude)"
KEY=$(curl -sS -X POST "$GW/key/generate" \
  -H "Authorization: Bearer $MASTER" -H "Content-Type: application/json" \
  -d '{"key_alias":"test-recipient","models":["relief-claude"],"rpm_limit":4,"max_parallel_requests":1}' \
  | jq -r .key)
echo "  got key: ${KEY:0:12}..."

echo "→ recipient makes a chat request through the gateway"
CONTENT=$(curl -sS "$GW/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"model":"relief-claude","messages":[{"role":"user","content":"hola desde caracas"}]}' \
  | jq -r '.choices[0].message.content // "ERROR"')
echo "  response: $CONTENT"
case "$CONTENT" in *"mock donor"*) check ok ok "recipient routed to donor and got a response";; *) check bad ok "recipient routed to donor and got a response";; esac

echo "→ an invalid key must be rejected"
CODE=$(curl -sS -o /dev/null -w '%{http_code}' "$GW/v1/chat/completions" \
  -H "Authorization: Bearer sk-not-a-real-key" -H "Content-Type: application/json" \
  -d '{"model":"relief-claude","messages":[{"role":"user","content":"x"}]}')
check "$CODE" "401" "invalid key rejected with 401"

echo
echo "RESULT: $pass passed, $fail failed"
echo "(stack still up — inspect at $GW, tear down with: docker compose down -v)"
[ "$fail" = 0 ]
