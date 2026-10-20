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
BUDGET_SECONDS=$(( ${TIME_BUDGET:-60} * 60 ))
if [ "${BUDGET_SECONDS}" -gt 60 ]; then
    BUDGET_SECONDS=$(( BUDGET_SECONDS - 30 ))
fi

COMMON_ARGS="--contract ${SPEC_FILE} --server http://${HOST}:${PORT} -b -k --ie --ib --it --iu --srs --srw --no-checkUpdate --preseedCollectionGets --maxPreseedCollectionGets 50 --callTimeout 5 --readTimeout 5 --connectionTimeout 5 --writeTimeout 5 -o /tmp/cats-report"

rm -rf /tmp/cats-report
java ${JVM_OPTS} -jar /app/app.jar \
    ${COMMON_ARGS} \
    -f "HappyPath,OnlyRequiredFields,DefaultValuesInFields,ExamplesFields,EmptyJsonBody,AlternativeDateTimeFormatsFields,QueryObjectAsRequestBody,RemoveFields" \
    --fieldsFuzzingStrategy SIZE --maxFieldsToRemove 2 --limitFuzzedFields 8 || true

while true; do
    rm -rf /tmp/cats-report
    java ${JVM_OPTS} -jar /app/app.jar \
        ${COMMON_ARGS} \
        --fieldsFuzzingStrategy SIZE --maxFieldsToRemove 2 --limitFuzzedFields 10 \
        --includeEmojis --includeControlChars --includeWhitespaces --includeAllInjectionPayloads \
        --stopAfterTimeInSec "${BUDGET_SECONDS}" --fillTimeBudget || true
done
