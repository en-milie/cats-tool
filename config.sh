#!/bin/sh
# Configuration script for CATS in RESTgym
# This script is called before CATS execution to perform any necessary setup

echo "=== CATS Configuration ==="
echo "API: ${API}"
echo "HOST: ${HOST}"
echo "PORT: ${PORT}"
echo "TIME_BUDGET: ${TIME_BUDGET:-not set}"
echo "Specification: /specifications/${API}-openapi.json"
echo "Server URL: http://${HOST}:${PORT}"
echo "=========================="

# Verify the specification file exists
if [ ! -f "/specifications/${API}-openapi.json" ]; then
    echo "ERROR: Specification file not found at /specifications/${API}-openapi.json"
    ls -la /specifications/
    exit 1
fi

echo "Configuration complete. Starting CATS..."
