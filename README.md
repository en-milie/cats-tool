# CATS — RESTgym / REST League 2027 Tool Integration

This directory contains all artifacts required to submit and run [CATS](https://github.com/Endava/cats) in the [RESTgym](https://github.com/restgym/restgym) benchmarking framework and the [REST League 2027 (ICSE 2027)](https://seunivr.github.io/RestLeague/2027/) competition.

## Directory Contents

| File | Target Path in `restgym/cats-tool` | Description |
|------|------------------------------------|-------------|
| `Dockerfile` | `Dockerfile` | Multi-arch (`linux/amd64`, `linux/arm64`) RESTgym-compliant image definition based on `eclipse-temurin:25-jre-alpine` |
| `entrypoint.sh` | `entrypoint.sh` | 4-stage execution script optimized for Operation Coverage, Code Coverage, Fault Detection (Unique 5XX), and AUC Efficiency |
| `restgym-tool-manifest.yaml` | `restgym-tool-manifest.yaml` | Official RESTgym v1 tool metadata manifest |
| `cats.jar` | `cats.jar` | Self-contained CATS 15.0.0 uber-JAR |
| `README.md` | `README.md` | Setup, execution, and submission documentation |

## RESTgym Environment Contract

When launched by RESTgym (`src/run.py`), the container receives the following environment variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `HOST` | Hostname or IP address of the target API proxy | Yes |
| `PORT` | TCP port of the target API proxy | Yes |
| `API` | Identifier of the API under test (used to locate `/specifications/${API}-openapi.json` or `/specifications/${API}-swagger.yaml`) | Yes |
| `TIME_BUDGET` | Testing time budget in minutes (default: `60`) | No |

## Multi-Stage Execution Strategy (`entrypoint.sh`)

To maximize all four REST League evaluation criteria (**Fault Detection**, **Operation Coverage**, **Code Coverage**, and **AUC Efficiency**) while guaranteeing zero premature container exits:

1. **Stage 1a, 1b & 1c — Fast Coverage & Runtime Resource Seeding Blitz (~5–25s)**
   - Pre-seeds up to 50 collection `GET` endpoints (`--preseedCollectionGets --maxPreseedCollectionGets 50`).
   - **Stage 1a**: Runs `HappyPath`, `OnlyRequiredFields`, `QueryObjectAsRequestBody`, and `AlternativeDateTimeFormatsFields` across all paths in operation-dependency order (`OperationDependencyOrder`) with active `RuntimeResourcePool` correlation and `--skipHttpMethods DELETE`.
   - **Stage 1b**: Runs `--profile coverage` (`--fieldsFuzzingStrategy SIZE --maxFieldsToRemove 2 --limitFuzzedFields 8`).
   - **Stage 1c**: Runs the seed fuzzers with `--useExamples`.
   - Reaches nearly all achievable `2XX` operations and baseline code branches within the first few seconds of the 60-minute budget, maximizing Area Under the Curve (AUC).

2. **Stage 2a & 2b — High-Yield Fault Detection, Boundary & Havoc Blitz (~30–90s)**
   - **Stage 2a**: Runs `--profile crash --includeAllInjectionPayloads --limitFuzzedFields 10` (35+ boundary, int32/negative, type-coercion, control-character, Unicode byte/length-expansion, auth-bypass, IDOR, mass-assignment, HTTP-method, and security injection fuzzers).
   - **Stage 2b**: Runs a 60-second `RandomFuzzer` multi-field havoc & type-confusion blitz (`-f "HappyPath,OnlyRequiredFields,RemoveFields,RandomFuzzer" --mc 500 --stopAfterTimeInSec 60`) to trigger deep `5XX` server faults and branch coverage early.

3. **Stage 3 — Full Black-Box Fuzzing Sweep**
   - Runs the complete CATS fuzzer suite (`-b -k --includeEmojis --includeControlChars --includeWhitespaces --includeAllInjectionPayloads --fieldsFuzzingStrategy SIZE --maxFieldsToRemove 2 --limitFuzzedFields 12`) with `--ie --ib --it --iu --srs --srw`.

4. **Stage 4 — Continuous Seeded Random Mutation Fuzzing (`RandomFuzzer`)**
   - Alternates 120-second seeded `RandomFuzzer` bursts with Stage 3 sweeps inside an infinite `while true` loop until RESTgym stops the container at the end of `TIME_BUDGET`.

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

## Updating `https://github.com/restgym/cats-tool`

Copy the files from this directory into a clone of `https://github.com/restgym/cats-tool`:

```bash
git clone https://github.com/restgym/cats-tool.git
cp Dockerfile entrypoint.sh restgym-tool-manifest.yaml cats.jar README.md cats-tool/
cd cats-tool
chmod +x entrypoint.sh
git add Dockerfile entrypoint.sh restgym-tool-manifest.yaml cats.jar README.md
git commit -m "Update CATS to 15.0.0 for REST League 2027"
```
