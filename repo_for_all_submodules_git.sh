#!/bin/bash
source common_bash.sh
# gradle 명령 지정: 기본은 build, 인자로 지정 가능

GIT_CMD="${@:-status}"

# repo root
REPO_ROOT=$(repo --show-toplevel)

# 하위 디렉토리 목록 가져오기
repo_list_subdirectories.sh | while read -r dir; do
  log -i "📂 $dir"
  if [ -d "$dir/.git" ]; then
    (git -C $dir $GIT_CMD)
    STATUS=$?
    if [ "$STATUS" -ne 0 ]; then
      echo "❌ $dir failed!"
      exit 1
    fi
  else
    echo "⚠️  .git directory is not exist: $dir"
  fi
done
