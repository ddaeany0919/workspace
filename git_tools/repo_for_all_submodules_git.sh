#!/usr/bin/env bash

source common_bash.sh

# 모든 하위 레포지토리에 대해 Git 명령 실행 (최적화 버전)
GIT_CMD="${*:-status}"

while read -r dir; do
    log -i "📂 $dir"
    if [[ -d "$dir/.git" ]]; then
        git -C "$dir" ${GIT_CMD} || { log -e "❌ $dir failed!"; exit 1; }
    else
        log -w "⚠️  .git directory does not exist: $dir"
    fi
done < <(repo_list_subdirectories.sh)
