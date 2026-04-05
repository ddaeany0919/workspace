OS=$(uname -s)
############ BASH ###########
export UNZIP="-O cp949"
export ZIPINFO="-O cp949"

############ WORKSPACE ROOT 설정 (가장 먼저 수행) ###########
# 이 파일의 위치를 기준으로 루트 경로를 정확히 계산합니다.
WORKSPACE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
export WORKSPACE_ROOT
WORKSPACE_UTILS="${WORKSPACE_ROOT}/3.utils"
export WORKSPACE_UTILS

# PATH 설정
export PATH="$WORKSPACE_ROOT/core:$WORKSPACE_ROOT/git_tools:$WORKSPACE_ROOT/utils:$WORKSPACE_ROOT/android:$WORKSPACE_ROOT/config:$WORKSPACE_ROOT/ai:$PATH"

############ 핵심 엔진 및 유틸리티 로드 ###########
# 1. 전역 환경 설정 로드
[[ -f "$WORKSPACE_ROOT/config/.default_env" ]] && source "$WORKSPACE_ROOT/config/.default_env"

# 2. 통합 코어 엔진 로드 (log 함수 등이 들어있음)
if [[ -f "$WORKSPACE_ROOT/core/common_bash.sh" ]]; then
    source "$WORKSPACE_ROOT/core/common_bash.sh"
else
    echo "Error: Cannot find $WORKSPACE_ROOT/core/common_bash.sh"
fi

# 3. 안드로이드 유틸 로드 (adb_target 등이 들어있음)
if [[ -f "$WORKSPACE_ROOT/android/common_android.sh" ]]; then
    source "$WORKSPACE_ROOT/android/common_android.sh"
fi

# 4. 기타 함수 및 에일리어스 로드
[[ -f "$WORKSPACE_ROOT/config/.bashrc_functions" ]] && source "$WORKSPACE_ROOT/config/.bashrc_functions"
[[ -f "$WORKSPACE_ROOT/git_tools/common_git.sh" ]] && source "$WORKSPACE_ROOT/git_tools/common_git.sh"

############ PS1 & ETC ###########
source "$WORKSPACE_ROOT/core/ps1.sh"

if [[ -f "$WORKSPACE_ROOT/config/.HOST_DISPLAY" ]]; then
    export DISPLAY="$(cat "$WORKSPACE_ROOT/config/.HOST_DISPLAY"):0.0"
fi

# --- Alias Common ---
[[ "$OS" == "Darwin" ]] && alias ls='ls -G' || alias ls='ls --color=tty'
alias ll='ls -FGlAhp'
alias vi='vim'
alias edit='code'

export VISUAL="vim"
