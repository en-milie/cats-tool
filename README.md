# CATS — RESTgym / REST League 2027 Tool Integration

This directory contains all artifacts required to run [CATS](https://github.com/Endava/cats) in the [RESTgym](https://github.com/restgym/restgym) benchmarking framework and the [REST League 2027 (ICSE 2027)](https://seunivr.github.io/RestLeague/2027/) competition.

## Directory Contents

| File | Target Path in `restgym/cats-tool` | Description |
|------|------------------------------------|-------------|
| `Dockerfile` | `Dockerfile` | Multi-arch (`linux/amd64`, `linux/arm64`) RESTgym-compliant image definition based on `eclipse-temurin:25-jre-alpine` |
| `entrypoint.sh` | `entrypoint.sh` | Container entrypoint invoking CATS against the target API proxy |
| `restgym-tool-manifest.yaml` | `restgym-tool-manifest.yaml` | Official RESTgym v1 tool metadata manifest |
| `cats.jar` | `cats.jar` | Self-contained CATS 15.3.0 uber-JAR |
| `README.md` | `README.md` | Setup and execution documentation |

## RESTgym Environment Contract

When launched by RESTgym (`src/run.py`), the container receives the following environment variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `HOST` | Hostname or IP address of the target API proxy | Yes |
| `PORT` | TCP port of the target API proxy | Yes |
| `API` | Identifier of the API under test (used to locate `/specifications/${API}-openapi.json` or `/specifications/${API}-swagger.yaml`) | Yes |
| `TIME_BUDGET` | Testing time budget in minutes (default: `60`) | No |

## Building and Testing in RESTgym

### 1. Build inside a RESTgym checkout

From the root of a `restgym` repository checkout (where this directory is placed at `tools/cats/`):

```bash
docker build -t restgym-tool-cats -f tools/cats/Dockerfile .
```

### 2. Run against a RESTgym API container

```bash
docker run --rm --network host \
  -e HOST=localhost \
  -e PORT=9090 \
  -e API=my-api \
  -e TIME_BUDGET=60 \
  restgym-tool-cats
```
