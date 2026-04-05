#!/bin/bash
#
# Ultra-Fast Ninja Direct Build for Android Modules
# Ninja를 직접 호출하여 초고속 빌드 (소스 코드만 수정한 경우)
#
# 사용 전 필수 조건:
#   1. 최소 1회 정상 빌드 완료 (source build/envsetup.sh && lunch && m <module>)
#   2. Android.bp 변경 없이 소스 코드(.cpp, .java 등)만 수정한 경우
#
# 장점:
#   - soong_ui 우회로 globs 재생성 등 불필요한 단계 스킵
#   - 실제 컴파일만 수행하여 3-10초 내 빌드 완료
#   - 모든 Android 모듈에 적용 가능
#
# 주의:
#   - Android.bp 변경 시 반드시 정상 빌드 먼저 수행
#   - 의존성 라이브러리 변경 시 정상 빌드 필요
#
# 사용법:
#   ./ninja_quick_build.sh <module_name>           # 특정 모듈 빌드
#   ./ninja_quick_build.sh                         # 기본 모듈 빌드 (AudioHAL)
#   ./ninja_quick_build.sh <module_name> -v        # 상세 로그
#   ./ninja_quick_build.sh -h                      # 도움말
#
# 예제:
#   ./ninja_quick_build.sh vendor.mobis.audiohal-service-connect
#   ./ninja_quick_build.sh OemCarService
#   ./ninja_quick_build.sh audiobridgeservice
#

set -e

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 도움말 함수
show_help() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Ultra-Fast Ninja Build for Android Modules       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}사용법:${NC}"
    echo -e "  $0 [module_name] [options]"
    echo ""
    echo -e "${YELLOW}옵션:${NC}"
    echo -e "  -v, --verbose    상세 빌드 로그 출력"
    echo -e "  -d, --deploy     빌드 성공 시 디바이스에 자동 설치/Push"
    echo -e "  -h, --help       도움말 표시"
    echo ""
    echo -e "${YELLOW}예제:${NC}"
    echo -e "  $0                                                  # 기본 모듈 (AudioHAL)"
    echo -e "  $0 vendor.mobis.audiohal-service-connect           # AudioHAL 빌드"
    echo -e "  $0 OemCarService                                    # OemCarService 빌드"
    echo -e "  $0 audiobridgeservice -v                            # 상세 로그와 함께 빌드"
    echo ""
    echo -e "${YELLOW}필수 조건:${NC}"
    echo -e "  1. 최소 1회 정상 빌드 완료"
    echo -e "     ${GREEN}source build/envsetup.sh && lunch connect_s-userdebug && m <module>${NC}"
    echo -e "  2. Android.bp 변경 없이 소스만 수정한 경우"
    echo ""
    echo -e "${YELLOW}Android.bp 변경 시:${NC}"
    echo -e "  ${GREEN}source build/envsetup.sh && lunch connect_s-userdebug && m <module>${NC}"
    echo ""
    exit 0
}

# Android 루트 자동 감지
detect_android_root() {
    local current_dir="$PWD"

    # 현재 디렉토리부터 상위로 올라가며 build/envsetup.sh 찾기
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/build/envsetup.sh" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done

    return 1
}

# =========================================================================
# [ 사용자 환경 설정 ]
# 새로운 프로젝트나 폴더 환경으로 이동할 경우, 아래 변수값만 수정하세요!
# =========================================================================

# 1. 기본 타겟 모듈명 (인자 없이 실행할 때 기본으로 빌드될 모듈)
DEFAULT_MODULE="vendor.mobis.audiohal-service-connect"

# 2. 기본 안드로이드 타겟 프로덕트 (예: connect_s, connect_l, pbvivi 등)
DEFAULT_PRODUCT="connect_s"

# =========================================================================


# Android 루트 감지
ANDROID_ROOT=$(detect_android_root)
if [ -z "$ANDROID_ROOT" ]; then
    echo -e "${RED}ERROR: Android 소스 루트를 찾을 수 없습니다!${NC}"
    echo -e "${YELLOW}Android 소스 트리 내에서 실행하세요.${NC}"
    exit 1
fi

cd "$ANDROID_ROOT" || exit 1

# 인자 파싱
MODULE_NAME=""
VERBOSE=""
PRODUCT=""
DEPLOY_AUTO=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -v|--verbose)
            VERBOSE="-v"
            shift
            ;;
        -d|--deploy)
            DEPLOY_AUTO=true
            shift
            ;;
        -p|--product)
            PRODUCT="$2"
            shift 2
            ;;
        -*)
            echo -e "${RED}ERROR: 알 수 없는 옵션: $1${NC}"
            echo -e "도움말: $0 --help"
            exit 1
            ;;
        *)
            if [ -z "$MODULE_NAME" ]; then
                MODULE_NAME="$1"
            fi
            shift
            ;;
    esac
done

# 모듈명이 없으면 기본값 사용
if [ -z "$MODULE_NAME" ]; then
    MODULE_NAME="$DEFAULT_MODULE"
    echo -e "${YELLOW}모듈명이 지정되지 않아 기본 모듈 사용: ${GREEN}${MODULE_NAME}${NC}"
    echo ""
fi

# Product 자동 감지 (사용자 설정 DEFAULT_PRODUCT 최우선 적용)
if [ -z "$PRODUCT" ]; then
    # 사용자가 위쪽에 정의한 기본 프로덕트 폴더가 있는지 체크
    if [ -d "out/target/product/${DEFAULT_PRODUCT}" ]; then
        PRODUCT="${DEFAULT_PRODUCT}"
    elif [ -d "out/target/product" ]; then
        # 없으면 out 폴더에 빌드된 아무 프로덕트나 자동 감지
        PRODUCT=$(ls out/target/product | head -1)
    else
        echo -e "${RED}ERROR: Product를 찾을 수 없습니다!${NC}"
        echo -e "${YELLOW}먼저 정상 빌드를 수행하세요.${NC}"
        exit 1
    fi
fi

# Ninja 설정
NINJA_BIN="prebuilts/build-tools/linux-x86/bin/ninja"
NINJA_FILE="out/combined-${PRODUCT}.ninja"

# 필수 파일 확인
if [ ! -f "$NINJA_BIN" ]; then
    echo -e "${RED}ERROR: Ninja 실행 파일이 없습니다: ${NINJA_BIN}${NC}"
    exit 1
fi

if [ ! -f "$NINJA_FILE" ]; then
    echo -e "${RED}ERROR: Ninja 빌드 파일이 없습니다!${NC}"
    echo -e "${YELLOW}먼저 정상 빌드를 수행하세요:${NC}"
    echo -e "  ${GREEN}source build/envsetup.sh${NC}"
    echo -e "  ${GREEN}lunch ${PRODUCT}-userdebug${NC}"
    echo -e "  ${GREEN}m ${MODULE_NAME}${NC}"
    echo ""
    echo -e "Ninja 파일: ${NINJA_FILE}"
    exit 1
fi

# 헤더 출력
echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Ultra-Fast Ninja Build                         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Android Root: ${BLUE}${ANDROID_ROOT}${NC}"
echo -e "Product:      ${BLUE}${PRODUCT}${NC}"
echo -e "Module:       ${GREEN}${MODULE_NAME}${NC}"
echo -e "Ninja:        ${BLUE}${NINJA_BIN}${NC}"
echo ""

# 빌드 시작
START_TIME=$(date +%s)

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Ninja 빌드 시작...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# 병렬 빌드 설정
NPROC=$(nproc)
JOBS=$((NPROC > 16 ? 16 : NPROC))  # 최대 16 job

# 빌드 로그 파일
BUILD_LOG="/tmp/ninja_build_${MODULE_NAME}_$$.log"

# Ninja 실행 (로그 저장)
$NINJA_BIN \
    -f "$NINJA_FILE" \
    -j${JOBS} \
    $VERBOSE \
    ${MODULE_NAME} | tee "$BUILD_LOG"

BUILD_RESULT=$?
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# BUILD_RESULT가 비어있으면 0으로 설정 (빌드 성공으로 간주)
if [ -z "$BUILD_RESULT" ]; then
    BUILD_RESULT=0
fi

if [ "$BUILD_RESULT" -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                빌드 성공! ✓                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "⏱  소요 시간: ${GREEN}${ELAPSED}초${NC}"

    # 빌드 로그에서 Install: 로 시작하는 라인 파싱
    declare -a OUTPUT_FILES
    while IFS= read -r line; do
        if [[ "$line" =~ Install:\ (.+)$ ]]; then
            OUTPUT_FILES+=("${BASH_REMATCH[1]}")
        fi
    done < "$BUILD_LOG"

    # 정리: 로그 파일 삭제
    rm -f "$BUILD_LOG"

    if [ ${#OUTPUT_FILES[@]} -gt 0 ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}📦 빌드 산출물 (${#OUTPUT_FILES[@]}개):${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        for idx in "${!OUTPUT_FILES[@]}"; do
            OUTPUT_FILE="${OUTPUT_FILES[$idx]}"

            # 파일 존재 확인
            if [ ! -f "$OUTPUT_FILE" ]; then
                echo -e "${YELLOW}⚠ 파일 없음: ${OUTPUT_FILE}${NC}"
                continue
            fi

            echo ""
            echo -e "  ${GREEN}[$((idx + 1))/${#OUTPUT_FILES[@]}]${NC} ${BLUE}${OUTPUT_FILE}${NC}"

            # 파일 정보 표시
            FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
            FILE_TIME=$(ls -l --time-style='+%Y-%m-%d %H:%M:%S' "$OUTPUT_FILE" | awk '{print $6, $7}')
            echo -e "      📊 크기: ${CYAN}${FILE_SIZE}${NC} | 🕐 ${CYAN}${FILE_TIME}${NC}"

            # 파일 타입별 배포 안내
            local CMD_EXEC=""
            if [[ "$OUTPUT_FILE" == *".so" ]]; then
                echo -e "      ${MAGENTA}→${NC} ${GREEN}adb push $OUTPUT_FILE /vendor/lib64/${NC}"
                CMD_EXEC="adb push $OUTPUT_FILE /vendor/lib64/"
            elif [[ "$OUTPUT_FILE" == *".apk" ]]; then
                echo -e "      ${MAGENTA}→${NC} ${GREEN}adb install -r $OUTPUT_FILE${NC}"
                CMD_EXEC="adb install -r $OUTPUT_FILE"
            elif [[ "$OUTPUT_FILE" == *".jar" ]]; then
                TARGET_PATH=$(echo "$OUTPUT_FILE" | sed "s|out/target/product/${PRODUCT}||")
                echo -e "      ${MAGENTA}→${NC} ${GREEN}adb push $OUTPUT_FILE $TARGET_PATH${NC}"
                CMD_EXEC="adb push $OUTPUT_FILE $TARGET_PATH"
            else
                if [[ "$OUTPUT_FILE" == */vendor/* ]]; then
                    TARGET_PATH=$(echo "$OUTPUT_FILE" | sed "s|out/target/product/${PRODUCT}||")
                    echo -e "      ${MAGENTA}→${NC} ${GREEN}adb root && adb remount && adb push $OUTPUT_FILE $TARGET_PATH${NC}"
                    CMD_EXEC="adb root && adb remount && adb push $OUTPUT_FILE $TARGET_PATH"
                else
                    TARGET_PATH=$(echo "$OUTPUT_FILE" | sed "s|out/target/product/${PRODUCT}||")
                    echo -e "      ${MAGENTA}→${NC} ${GREEN}adb push $OUTPUT_FILE $TARGET_PATH${NC}"
                    CMD_EXEC="adb push $OUTPUT_FILE $TARGET_PATH"
                fi
            fi

            if [[ "$DEPLOY_AUTO" == "true" && -n "$CMD_EXEC" ]]; then
                echo -e "      ${CYAN}🚀 자동 배포 실행 중...${NC}"
                eval "$CMD_EXEC"
            fi
        done
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        echo -e "${YELLOW}⚠ 빌드 산출물을 찾을 수 없습니다${NC}"
        echo -e "모듈: ${MODULE_NAME}"
        echo -e "빌드 로그: $BUILD_LOG"
    fi

else
    echo -e "${RED}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                빌드 실패! ✗                        ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Android.bp 변경이 있었다면 정상 빌드를 수행하세요:${NC}"
    echo -e "  ${GREEN}source build/envsetup.sh${NC}"
    echo -e "  ${GREEN}lunch ${PRODUCT}-userdebug${NC}"
    echo -e "  ${GREEN}m ${MODULE_NAME}${NC}"
    exit 1
fi
