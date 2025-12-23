#!/bin/sh
set -e

ls /specifications

while true; do
    java -jar /app/app.jar \
    --contract "/specifications/${API}-openapi.json" \
    --server "http://${HOST}:${PORT}" \
    -b -k \
    --includeEmojis \
    --includeControlChars \
    --includeWhitespaces || true
done