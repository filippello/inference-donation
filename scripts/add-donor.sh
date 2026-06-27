#!/usr/bin/env bash
# Register a donor with the gateway at runtime (no restart needed).
#
# Usage:
#   ./add-donor.sh <donor_id> <tunnel_url> <donor_client_key> [model_name] [exposed_model]
#
# Example:
#   ./add-donor.sh maria https://abc-123.trycloudflare.com sk-donor-maria \
#       relief-claude claude-sonnet-4-5
set -euo pipefail

GATEWAY="${GATEWAY_URL:-http://localhost:4000}"
ADMIN_KEY="${LITELLM_MASTER_KEY:?set LITELLM_MASTER_KEY in your env}"

DONOR_ID="${1:?donor_id required}"
TUNNEL_URL="${2:?tunnel url required (donor CLIProxyAPI public url)}"
DONOR_KEY="${3:?donor client key required}"
MODEL_NAME="${4:-relief-claude}"          # what recipients request
EXPOSED_MODEL="${5:-claude-sonnet-4-5}"   # model id CLIProxyAPI serves

curl -sS -X POST "$GATEWAY/model/new" \
  -H "Authorization: Bearer $ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<JSON | (command -v jq >/dev/null && jq . || cat)
{
  "model_name": "$MODEL_NAME",
  "litellm_params": {
    "model": "openai/$EXPOSED_MODEL",
    "api_base": "${TUNNEL_URL%/}/v1",
    "api_key": "$DONOR_KEY",
    "rpm": 6,
    "max_parallel_requests": 1
  },
  "model_info": {
    "id": "$DONOR_ID",
    "donor_id": "$DONOR_ID",
    "provider": "subscription"
  }
}
JSON

echo "✓ donor '$DONOR_ID' added as '$MODEL_NAME' (1 req in flight, 6 rpm cap)"
