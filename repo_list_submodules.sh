#!/bin/bash
source common_bash.sh

SUBDIR_ABS=$(realpath "$PWD")
REPO_ROOT=$(repo --show-toplevel 2>/dev/null)
CPU_COUNT=$(nproc)
log -d "SUBDIR_ABS=${SUBDIR_ABS}"
log -d "REPO_ROOT=${REPO_ROOT}"

if [ ! -d "$REPO_ROOT" ]; then
  log -w "repo 루트 디렉토리를 찾을 수 없습니다."
  exit 1
fi

# 절대경로를 repo 루트 기준 상대경로로 변환
SUBDIR_REL=$(realpath --relative-to="$REPO_ROOT" "$SUBDIR_ABS")
log -d "SUBDIR_REL=${SUBDIR_REL}"

# 해당 상대경로로 시작하는 project path만 추출
repo list | awk -F': ' -v prefix="$SUBDIR_REL" '$1 ~ ("^" prefix) { print $2}'
