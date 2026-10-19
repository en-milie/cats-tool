#!/bin/sh

echo "=== CATS Configuration ==="
echo "API: ${API}"
echo "HOST: ${HOST}"
echo "PORT: ${PORT}"
echo "TIME_BUDGET: ${TIME_BUDGET:-not set}"
echo "Server URL: http://${HOST}:${PORT}"
echo "=========================="

SPEC_FILE="/specifications/${API}-openapi.json"
if [ ! -f "${SPEC_FILE}" ] && [ -f "/specifications/${API}.yaml" ]; then
    SPEC_FILE="/specifications/${API}.yaml"
fi

if [ ! -f "${SPEC_FILE}" ]; then
    echo "ERROR: Specification file not found at ${SPEC_FILE}"
    ls -la /specifications/ 2>/dev/null || true
    exec sleep infinity
fi

JVM_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseStringDeduplication"

COMMON_ARGS="--contract ${SPEC_FILE} --server http://${HOST}:${PORT} -b -k --ie --ib --it --iu --srs --srw --no-checkUpdate --preseedCollectionGets --maxPreseedCollectionGets 50 -o /tmp/cats-report"

STAGE1_SEED_FUZZERS="HappyPath,OnlyRequiredFields,QueryObjectAsRequestBody,AlternativeDateTimeFormatsFields"

echo "[CATS] Stage 1a: Ultra-fast HappyPath + OnlyRequiredFields coverage blitz..."
rm -rf /tmp/cats-report
java ${JVM_OPTS} -jar /app/app.jar \
    ${COMMON_ARGS} \
    -f "${STAGE1_SEED_FUZZERS}" \
    --skipHttpMethods DELETE \
    --callTimeout 5 --readTimeout 5 --connectionTimeout 5 --writeTimeout 5 || true

echo "[CATS] Stage 1b: Combinatorial field removal & type-coercion coverage blitz (--profile coverage)..."
rm -rf /tmp/cats-report
java ${JVM_OPTS} -jar /app/app.jar \
    ${COMMON_ARGS} \
    --profile coverage \
    --fieldsFuzzingStrategy SIZE --maxFieldsToRemove 2 --limitFuzzedFields 8 \
    --callTimeout 5 --readTimeout 5 --connectionTimeout 5 --writeTimeout 5 || true

echo "[CATS] Stage 1c: Fast coverage blitz using OpenAPI schema/requestBody examples..."
rm -rf /tmp/cats-report
java ${JVM_OPTS} -jar /app/app.jar \
    ${COMMON_ARGS} \
    -f "${STAGE1_SEED_FUZZERS}" \
    --useExamples \
    --callTimeout 5 --readTimeout 5 --connectionTimeout 5 --writeTimeout 5 || true

echo "[CATS] Stage 2a: High-yield fault detection, injection, and boundary blitz (--profile crash)..."
rm -rf /tmp/cats-report
java ${JVM_OPTS} -jar /app/app.jar \
    ${COMMON_ARGS} \
    --profile crash \
    --includeAllInjectionPayloads \
    --limitFuzzedFields 10 \
    --callTimeout 5 --readTimeout 5 --connectionTimeout 5 --writeTimeout 5 || true

echo "[CATS] Stage 2b: Early multi-field havoc & type-confusion random mutation blitz (60s)..."
rm -rf /tmp/cats-report
java ${JVM_OPTS} -jar /app/app.jar \
    ${COMMON_ARGS} \
    -f "HappyPath,OnlyRequiredFields,RemoveFields,RandomFuzzer" \
    --mc 500 \
    --stopAfterTimeInSec 60 \
    --callTimeout 5 --readTimeout 5 --connectionTimeout 5 --writeTimeout 5 || true

ITERATION=1
while true; do
    EXTRA_ITER_ARGS=""
    if [ $((ITERATION % 2)) -eq 0 ]; then
        EXTRA_ITER_ARGS="--useExamples --rfc7396 --selfReferenceDepth 3"
    fi

    echo "[CATS] Stage 3 (Iteration ${ITERATION}): Full black-box fuzzing sweep (all 160 fuzzers + 2nd phase)..."
    rm -rf /tmp/cats-report
    java ${JVM_OPTS} -jar /app/app.jar \
        ${COMMON_ARGS} \
        --includeEmojis \
        --includeControlChars \
        --includeWhitespaces \
        --includeAllInjectionPayloads \
        --fieldsFuzzingStrategy SIZE --maxFieldsToRemove 2 --limitFuzzedFields 12 \
        ${EXTRA_ITER_ARGS} \
        --callTimeout 10 --readTimeout 10 --connectionTimeout 5 --writeTimeout 5 || true

    echo "[CATS] Stage 4 (Iteration ${ITERATION}): Seeded continuous random mutation fuzzing (120s)..."
    rm -rf /tmp/cats-report
    java ${JVM_OPTS} -jar /app/app.jar \
        ${COMMON_ARGS} \
        -f "HappyPath,OnlyRequiredFields,RemoveFields,RandomFuzzer" \
        --mc 500 \
        --stopAfterTimeInSec 120 \
        --callTimeout 10 --readTimeout 10 --connectionTimeout 5 --writeTimeout 5 || true

    ITERATION=$((ITERATION + 1))
    sleep 1
done
