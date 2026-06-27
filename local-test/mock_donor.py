#!/usr/bin/env python3
"""Minimal OpenAI-compatible server that stands in for a real donor's CLIProxyAPI.

Lets us test the gateway end-to-end without a real Claude/Codex login or tunnel.
Stdlib only. Serves /v1/models and /v1/chat/completions.
"""
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8080
MODEL = "claude-sonnet-4-5"


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, payload):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.rstrip("/") in ("/v1/models", "/models"):
            self._send(200, {"object": "list",
                             "data": [{"id": MODEL, "object": "model"}]})
        else:
            self._send(200, {"status": "ok"})

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        try:
            req = json.loads(self.rfile.read(n) or b"{}")
        except json.JSONDecodeError:
            return self._send(400, {"error": "bad json"})
        user = next((m.get("content", "") for m in reversed(req.get("messages", []))
                     if m.get("role") == "user"), "")
        self._send(200, {
            "id": "chatcmpl-mock",
            "object": "chat.completion",
            "model": req.get("model", MODEL),
            "choices": [{
                "index": 0,
                "finish_reason": "stop",
                "message": {"role": "assistant",
                            "content": f"[mock donor] recibido: {user[:80]}"},
            }],
            "usage": {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2},
        })

    def log_message(self, *a):  # quiet
        pass


if __name__ == "__main__":
    print(f"mock donor on :{PORT} (model={MODEL})", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
