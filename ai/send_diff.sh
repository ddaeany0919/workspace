#!/usr/bin/env bash
# send_diff: 전역 변수 연동 버전

# 전역 설정 로드
ENV_PATH="$(dirname "$0")/../config/.default_env"
[[ -f "$ENV_PATH" ]] && source "$ENV_PATH"

DIFF=$(git diff --no-color --ignore-all-space --ignore-blank-lines)

if [[ -z "$DIFF" ]]; then
    echo "변경 사항이 없습니다."
    exit 0
fi

# 전역 설정된 AI_REVIEW_URL 사용
curl -X POST "${AI_REVIEW_URL}" \
   -H "Content-Type: application/json" \
   -d "{\"repo\": \"$(basename $(git rev-parse --show-toplevel))\", \"diff\": $(jq -Rs . <<< \"$DIFF\")}"
