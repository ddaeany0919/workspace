# My Workspace Tools

이 저장소는 다수의 쉘 환경 설정, 안드로이드 개발 툴, Git Repo 유틸리티 등을 통합해둔 개인화 워크스페이스입니다.

## 폴더 구조 (업데이트됨)
* `core/`: 워크스페이스 전역에서 사용되는 공통 쉘(Boilerplate) 스크립트들
* `config/`: 쉘(`bash`, `zsh`) 초기 설정 파일들 및 환경 변수, IP 타겟팅 설정
* `android/`: 안드로이드(`ADB`, PVR, TV 관련 앱) 자동화 및 테스트, 빌드 스크립트
* `git_tools/`: 복수의 Git 저장소를 다루기 위한 `repo` 포팅 툴 및 일괄 Checkout 유틸리티
* `utils/`: 기타 로컬 편의 기능 (VPN 연장, 디렉토리 자동 복사(`advcpmv`) 등)
* `ai/`: AI 활용을 위해 `git diff`를 전송하는 스크립트 모음
* `_legacy_projects/`: CONNECT, PBVIVI 등 특정 프로젝트 종속 파일 (보관용)

## 빠른 사용법

터미널 홈 디렉토리의 `~/.bashrc` (또는 `~/.zshrc`)를 열어 다음과 같이 추가하세요:

```bash
# Workspace 초기화
if [[ $- == *i* ]] && [[ -z ${LC_WORKSPACE_PROJECT} ]]; then
    export LC_WORKSPACE_PROJECT="active"
    source /경로입력/c/Users/kth00/StudioProjects/workspace/setup.sh
fi
```

### 추가 기능
컬러풀한 Logcat을 보려면 파이썬 모듈이 필요합니다:
```bash
pip install --break-system-packages etc/logcat-color/logcat-color-0.10.0.tar.gz
```
