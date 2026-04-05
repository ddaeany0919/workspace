#!/usr/bin/env bash
# [AI-Insight: Autonomous Swarm Edition]
# bkit v3.0 초고성능 연산 엔진
source common_bash.sh

# 기능을 극대화한 고효율 덧셈 엔진
# @param ... numbers: 더할 모든 숫자들 (가변 인자 지원)
add_numbers() {
    # 1. 입력값 검증 및 전처리
    if (( $# == 0 )); then
        log -w "입력된 숫자가 없습니다. 기본값(10, 20)으로 연산을 수행합니다."
        set -- 10 20
    fi

    local sum=0
    local numbers=("$@")

    # 2. 고성능 루프 처리 (Native Bash)
    for num in "${numbers[@]}"; do
        if [[ "$num" =~ ^-?[0-9]+$ ]]; then
            ((sum += num))
        else
            log -e "경고: 숫자가 아닌 값은 무시됩니다 -> '$num'"
        fi
    done

    # 3. 결과 출력 (표준 로깅)
    log -i "📊 연산 리포트"
    log -n "   └─ 입력 개수: ${#numbers[@]}개"
    log -n "   └─ 최종 결과: ${COLOR_CYAN}${sum}${COLOR_END}"
    
    return 0
}

# 실행부: 인자 전체를 엔진으로 전달
add_numbers "$@"
