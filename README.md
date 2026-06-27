# LLM Relief — donar capacidad de LLM no usada

Durante una emergencia (p.ej. el terremoto de Venezuela), mucha gente no puede
pagar APIs de IA pero **sí** necesita acceso a LLMs para trabajar, programar y
resolver. Al mismo tiempo, mucha gente del mundo paga Claude Pro/Max o ChatGPT/
Codex y **no usa toda su cuota**. Esto deja que donen ese excedente: el donante
loguea su suscripción en un contenedor en su máquina y queda disponible —con
cuotas— para receptores, mientras dure la emergencia.

> **No pedimos plata. Pedimos capacidad que ya está pagada y se desperdicia.**

## Cómo funciona

```
DONANTES (cada uno en su PC, su IP)        GATEWAY central         RECEPTORES
 CLIProxyAPI + Claude/Codex logueado  ─┐
 + túnel saliente (cloudflared)        ├─►  LiteLLM   ──►  keys con cuota  ──► Claude Code /
 (el token NUNCA sale de tu máquina)  ─┘   balancea         por persona         Cline / curl
```

- **CLIProxyAPI** (en el donante) envuelve el CLI oficial de Claude/Codex vía
  OAuth y lo expone como API OpenAI-compatible. No extrae tokens ni hackea nada.
- **LiteLLM** (gateway central) balancea entre donantes vivos, hace health-check
  (los donantes se caen seguido) y emite una key por receptor con límites.
- El **receptor** usa cualquier cliente OpenAI-compatible; nunca ve la cuenta de
  nadie.

## ⚠️ Honestidad con el donante (leer antes de donar)

Compartir el acceso de una suscripción **va contra los Términos de Servicio** de
Anthropic y OpenAI, que son para uso individual. El riesgo (suspensión de la
cuenta) lo corre el donante. No hay forma de eliminar ese riesgo; este proyecto
lo **minimiza** por diseño:

| Riesgo | Mitigación incluida |
|--------|---------------------|
| "Muchas cuentas desde una IP de datacenter" = bandera roja | **Topología distribuida**: cada donante corre en su casa, su token y su IP. Nada se centraliza. |
| Quemar el límite del donante (y arruinar su propio uso) | `max_parallel_requests: 1` y `rpm: 6` por donante; cuotas conservadoras por receptor. |
| Patrón de uso automatizado/anómalo | Cuotas bajas por persona; sin batch masivo. |
| Donante quiere salir | `docker compose down`. Su token nunca estuvo en otro lado. |

Decidí vos si querés asumirlo. Documentá el estado de emergencia como contexto.

## Probar localmente (sin suscripción ni túnel)

Levanta gateway + DB + un **donante mock** y verifica el flujo completo
(routing → key de receptor → request → key inválida rechazada). Requiere Docker.

```bash
cd local-test
./test-local.sh
```

## Quickstart

> Los **receptores los centralizamos nosotros**: corremos un único gateway y
> emitimos las keys. No hay auto-registro de receptores por ahora.

### Operador (corre el gateway una vez)
```bash
cd gateway
cp .env.example .env && $EDITOR .env      # poné secretos (openssl rand -hex 24)
docker compose up -d
```

### Donante (corre en su máquina)
```bash
cd donor
./donate.sh                               # un comando: key + login + túnel
# si falta login, te muestra el comando real de tu binario; re-corré ./donate.sh
# al final imprime tu URL trycloudflare + tu client key para pasarnos
```
Pasale al operador tu **URL** y tu **client key**. El operador te suma:
```bash
cd scripts
./add-donor.sh maria https://abc-123.trycloudflare.com sk-donor-maria
```

### Receptor
```bash
cd scripts
./issue-key.sh jose                        # imprime sk-... con cuota
# mandale la key + la URL del gateway. Ver recipient/README.md
```

## Estado / roadmap

Esto es un **v0 funcional** para arrancar rápido. Endurecimientos pensados:

- **v1 — modelo pull/relay**: el donante abre un websocket *saliente* al gateway
  y tira de una cola, en vez de exponer un túnel entrante. Cero config de red,
  aún más difícil de detectar. (El túnel del v0 ya es saliente, pero esto lo
  lleva más lejos.)
- **Donantes híbridos**: el mismo gateway acepta también **API keys donadas con
  saldo** y **modelos abiertos self-hosted** (vLLM/airunway). Mismo `model_name`,
  LiteLLM los mezcla. Así degrada con elegancia si caen las suscripciones.
- **Panel de salud de donantes** y registro self-service (que el donante se sume
  solo, sin pasar por el operador).

## Estructura

```
gateway/    # nodo central: LiteLLM + postgres (docker compose)
donor/      # lo que corre cada donante: CLIProxyAPI + cloudflared
recipient/  # cómo conectar tu cliente
scripts/    # add-donor / issue-key / revoke-key (admin API de LiteLLM)
```

## Componentes upstream

- CLIProxyAPI — https://github.com/router-for-me/CLIProxyAPI
- LiteLLM — https://github.com/BerriAI/litellm
- cloudflared — https://github.com/cloudflare/cloudflared

Alternativa de gateway evaluada: theopenco/llmgateway (UI + tracking propios).
Para sumar cómputo donado de modelos abiertos: kaito-project/airunway o vLLM.
