#!/bin/bash
SERVER="192.168.30.61"
PORT="8000"
# REPO_PATH="/path/to/repo"
DIFF=$(git diff --no-color --ignore-all-space --ignore-blank-lines)


 curl -X POST http://{$SERVER}:${PORT}/review \
   -H "Content-Type: application/json" \
   -d "{\"repo\": \"sample-repo\", \"diff\": $(jq -Rs . <<< \"$DIFF\")}"