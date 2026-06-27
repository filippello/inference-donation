# Deploy the gateway on Railway

Goal: the gateway (LiteLLM + Postgres) running at a public URL so recipients can
point any OpenAI-compatible tool at it. You operate donors/recipients from your
laptop with the scripts in `scripts/`.

## What you need
- A Railway account (railway.com) and this repo on GitHub (already at
  `filippello/inference-donation`).
- Two secrets, generated once:
  ```bash
  openssl rand -hex 24   # -> LITELLM_MASTER_KEY  (prefix it with sk- )
  openssl rand -hex 24   # -> LITELLM_SALT_KEY    (encrypts donor creds at rest; NEVER change later)
  ```

## A. Dashboard (recommended)

1. **New Project** → *Deploy from GitHub repo* → pick `inference-donation`.
2. On the created service → **Settings**:
   - **Root Directory**: `gateway`  (so it finds `Dockerfile` + `railway.json`)
   - Build/health are read from `gateway/railway.json` automatically.
3. **Add Postgres**: in the project, *New* → *Database* → *Add PostgreSQL*.
4. Back on the gateway service → **Variables**, add:
   | Variable | Value |
   |----------|-------|
   | `LITELLM_MASTER_KEY` | `sk-...` (your generated key — the admin key) |
   | `LITELLM_SALT_KEY` | your generated salt |
   | `STORE_MODEL_IN_DB` | `true` |
   | `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` (reference the Postgres service) |
5. **Networking** → *Generate Domain*. Railway sets `$PORT`; the container binds it.
6. First deploy runs the DB migrations on boot. When the healthcheck
   (`/health/readiness`) is green, you're live at `https://<name>.up.railway.app`.

## B. CLI (alternative)
```bash
npm i -g @railway/cli
railway login
railway init                      # create project
railway add --database postgres   # add Postgres
# set the gateway service root dir to "gateway" in the dashboard, then:
railway variables \
  --set LITELLM_MASTER_KEY=sk-... \
  --set LITELLM_SALT_KEY=... \
  --set STORE_MODEL_IN_DB=true \
  --set 'DATABASE_URL=${{Postgres.DATABASE_URL}}'
railway up
railway domain                    # get the public URL
```

## Operate it (from your laptop)
```bash
export GATEWAY_URL=https://<name>.up.railway.app
export LITELLM_MASTER_KEY=sk-...        # same value you set in Railway

# add a donor (they ran ./donate.sh and gave you URL + client key)
./scripts/add-donor.sh maria https://<her-tunnel>.trycloudflare.com sk-donor-xxx

# mint a recipient key
./scripts/issue-key.sh jose             # prints sk-... — send it privately
```
Recipient config (see `recipient/README.md`):
```
Base URL: https://<name>.up.railway.app
API key:  sk-... (the one you issued)
Model:    relief-claude
```

## Security
- `LITELLM_MASTER_KEY` is the **admin** key — keep it secret, never give it to
  recipients. Recipients only ever get per-person virtual keys (revocable with
  `scripts/revoke-key.sh`).
- `LITELLM_SALT_KEY` encrypts stored donor credentials. If you change it later,
  existing stored donor entries become unreadable — set it once.

## Note on cost / scale
Railway bills the running gateway (small) + Postgres. The gateway is light — it
just proxies. The heavy lifting (the actual LLM calls) happens on donors' machines.
