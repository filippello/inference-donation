# Gateway image for Railway (or any platform). Bakes our config into the
# official LiteLLM image and binds to the platform-provided $PORT.
FROM ghcr.io/berriai/litellm:main-stable

COPY litellm-config.yaml /app/config.yaml

# Railway injects $PORT at runtime; fall back to 4000 locally.
ENTRYPOINT []
CMD ["sh", "-c", "litellm --config /app/config.yaml --host 0.0.0.0 --port ${PORT:-4000}"]
