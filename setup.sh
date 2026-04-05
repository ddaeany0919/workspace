#!/bin/bash
# 간단한 진입점 스크립트입니다.
# 사용법: 
#   터미널에서 `source setup.sh` 명령어를 실행해주세요.

WORKSPACE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f "$WORKSPACE_ROOT/config/bashrc_main.sh" ]; then
    source "$WORKSPACE_ROOT/config/bashrc_main.sh"
    echo -e "\033[0;32m[+] Workspace 환경이 성공적으로 로드되었습니다!\033[0m"
else
    echo -e "\033[0;31m[!] config/bashrc_main.sh 파일을 찾을 수 없습니다.\033[0m"
fi
