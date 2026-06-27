#!/usr/bin/env bash
# Revoke a recipient key immediately.
#   ./revoke-key.sh sk-the-recipient-key
set -euo pipefail
GATEWAY="${GATEWAY_URL:-http://localhost:4000}"
ADMIN_KEY="${LITELLM_MASTER_KEY:?set LITELLM_MASTER_KEY in your env}"
KEY="${1:?key to revoke required}"

curl -sS -X POST "$GATEWAY/key/delete" \
  -H "Authorization: Bearer $ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"keys\": [\"$KEY\"]}"
echo "✓ revoked"
