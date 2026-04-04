#!/bin/bash

# gradle 명령 지정: 기본은 build, 인자로 지정 가능
GRADLE_CMD="assembleRelease"

# repo root
REPO_ROOT=$(repo --show-toplevel)

# 하위 디렉토리 목록 가져오기
repo_list_subdirectories.sh | while read -r rel_path; do

  if [ -x "$rel_path/gradlew" ]; then
    echo "🔧 빌드 중: $rel_path"
    cd "$rel_path"
    ./gradlew "$GRADLE_CMD"
    STATUS=$?
    cd -
    if [ "$STATUS" -ne 0 ]; then
      echo "❌ $rel_path 빌드 실패!"
      exit 1
    fi
  else
    echo "⚠️  gradlew 가 없습니다: $rel_path"
  fi
  
done
