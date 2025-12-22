#!/bin/sh

while true; do
    java -jar /cats.jar \
        --contract "/specifications/${API}-openapi.json" \
        --server "http://${HOST}:${PORT}" \
        -b -k \
        --includeEmojis \
        --includeControlChars \
        --includeWhitespaces
done