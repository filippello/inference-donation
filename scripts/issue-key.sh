#!/usr/bin/env bash
# Mint a recipient key with conservative per-person quotas.
#
# Usage:
#   ./issue-key.sh <recipient_alias> [rpm] [tpm] [days]
#
# Example (a dev in Caracas, 4 req/min, 60k tokens/min, valid 30 days):
#   ./issue-key.sh jose 4 60000 30
set -euo pipefail

GATEWAY="${GATEWAY_URL:-http://localhost:4000}"
ADMIN_KEY="${LITELLM_MASTER_KEY:?set LITELLM_MASTER_KEY in your env}"

ALIAS="${1:?recipient alias required}"
RPM="${2:-4}"
TPM="${3:-60000}"
DAYS="${4:-30}"

curl -sS -X POST "$GATEWAY/key/generate" \
  -H "Authorization: Bearer $ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<JSON | (command -v jq >/dev/null && jq '{key, key_alias, models, rpm_limit, tpm_limit, expires}' || cat)
{
  "key_alias": "$ALIAS",
  "models": ["relief-claude", "relief-codex"],
  "rpm_limit": $RPM,
  "tpm_limit": $TPM,
  "max_parallel_requests": 1,
  "duration": "${DAYS}d",
  "metadata": {"program": "venezuela-relief", "recipient": "$ALIAS"}
}
JSON

echo "✓ key for '$ALIAS' issued — share it privately. Revoke with scripts/revoke-key.sh"
