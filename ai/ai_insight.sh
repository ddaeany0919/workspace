#!/usr/bin/env bash
# AI-Insight: 자율 파이프라인(Swarm) 대응 버전
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Core & Env 로드
CORE_PATH="$(dirname "$0")/../core/common_bash.sh"
ENV_PATH="$(dirname "$0")/../config/.default_env"
[[ -f "$CORE_PATH" ]] && source "$CORE_PATH"
[[ -f "$ENV_PATH" ]] && source "$ENV_PATH"

MEMO_TEXT=""
FILE_TARGETS=()
AUTONOMOUS_MODE=false

while getopts "hm:f:a" opt; do
    case "$opt" in
        m) MEMO_TEXT="$OPTARG" ;;
        f) MEMO_TEXT=$(cat "$OPTARG") ;;
        a) AUTONOMOUS_MODE=true ;; # 자율 모드 옵션 추가
        h) echo "Usage: $0 [-a] -m 'memo' [files...]"; exit 0 ;;
    esac
done
shift $((OPTIND - 1))
FILE_TARGETS=("$@")

draw_line_with_title "AI-Insight: Autonomous Pipeline Initializing" "=" "${COLOR_CYAN}"

log -i "📝 회의 메모 수신 완료 (길이: ${#MEMO_TEXT}자)"
[[ "$AUTONOMOUS_MODE" == "true" ]] && log -w "🤖 자율 모드가 활성화되었습니다. 에이전트 간 핑퐁을 시작합니다."

# 컨텍스트 수집 (기존 로직 보존)
CONTEXT_DATA=""
for target in "${FILE_TARGETS[@]}"; do
    if [[ -e "$target" ]]; then
        log -i "🔍 분석 대상 포착: ${COLOR_YELLOW}$target${COLOR_END}"
        history=$(git log -p -n 3 -- "$target" 2>/dev/null)
        source_code=$(cat "$target" 2>/dev/null)
        CONTEXT_DATA+="\n\n[FILE: $target]\n--- HISTORY ---\n$history\n--- SOURCE ---\n$source_code"
    fi
done

# 데이터 패킹 (Handoff 정보 추가)
log -n "📦 자율 협업 컨텍스트 패키징 중..."
python3 -c "import json, sys, os; 
data = {
    'memo': sys.argv[1], 
    'git_context': sys.argv[2],
    'status': {
        'current_phase': 'PLAN', # 시작 단계 설정
        'active_agent': 'pm-lead',
        'autonomous': sys.argv[4].lower() == 'true',
        'progress': 10
    }
}; 
with open(sys.argv[3], 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
" "$MEMO_TEXT" "$CONTEXT_DATA" "$AI_CONTEXT_FILE" "$AUTONOMOUS_MODE"
log -i " [완료]"

log -i "✅ 수집 완료: $AI_CONTEXT_FILE"
draw_line "-"

if [[ "$AUTONOMOUS_MODE" == "true" ]]; then
    log -i "🚀 파이프라인 가동: [pm-lead]가 기획 분석을 시작합니다..."
    # 여기서 실제로 pm-lead 에이전트를 호출하는 브릿지 로직이 실행됩니다.
else
    echo -e "${COLOR_YELLOW}🚀 수동 분석 준비 완료:${COLOR_END}"
    echo -e "터미널에 ${COLOR_CYAN}\"분석해서 수정해줘\"${COLOR_END}라고 입력하세요."
fi
