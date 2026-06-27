# For recipients

You were given **a key** (`sk-...`) and **a gateway URL** (e.g. `https://gateway.example.org`).
Point any OpenAI-compatible tool at it. You never see or touch a donor's account.

## Claude Code / Codex / Cline / Cursor / etc.

Most coding tools accept a custom OpenAI-compatible endpoint. Set:

```
Base URL:  https://gateway.example.org
API key:   sk-...   (the key you were given)
Model:     relief-claude   (or relief-codex)
```

## Plain curl test

```bash
curl https://gateway.example.org/v1/chat/completions \
  -H "Authorization: Bearer sk-YOURKEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "relief-claude",
    "messages": [{"role": "user", "content": "Escribe un hello world en Python"}]
  }'
```

## Aider (good for coding)

```bash
export OPENAI_API_BASE=https://gateway.example.org
export OPENAI_API_KEY=sk-YOURKEY
aider --model openai/relief-claude
```

## Notes

- If you get rate-limited, wait a moment — capacity is shared and donors are limited.
- If a request fails, just retry; the gateway routes you to another donor.
- Be considerate: this is donated capacity from real people. Don't run huge batch jobs.
