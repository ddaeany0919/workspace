#!/usr/bin/env bash
source common_bash.sh
# save as: repo_backup_changed_modules.sh
# usage:
#   bash repo_backup_changed_modules.sh
#   bash repo_backup_changed_modules.sh -d /path/to/backup
#   bash repo_backup_changed_modules.sh --since origin/main            # 기준 ref와 비교한 변경도 포함
#   bash repo_backup_changed_modules.sh --include-ignored              # .gitignore에 걸린 파일까지 포함
#   bash repo_backup_changed_modules.sh -d /mnt/backup --since aosp/android-14.0.0_r25

set -euo pipefail
DEBUG=true

DEST_ROOT=""
SINCE_REF=""
INCLUDE_IGNORED=0
REPO_TOP=$(repo --show-toplevel)

print_help() {
  cat <<'EOF'
repo 기반 모듈별 선택 백업 스크립트
- 각 모듈(프로젝트)에서 변경/스테이징/언트랙트 파일이 있으면 그 모듈만 백업합니다.
- 모든 모듈은 동일한 타임스탬프 백업 루트 하위에 "모듈 경로(REPO_PATH)" 그대로 저장됩니다.

옵션:
  -d, --dest DIR       백업 루트 디렉토리 (기본: ~/backup/repo_changed_YYYYmmdd_HHMMSS)
  --since REF          기준 ref(예: origin/main)와 비교해 변경된 파일 포함(삭제 제외)
  --include-ignored    .gitignore에 걸린 파일까지(untracked ignored) 포함
  -h, --help           도움말

예시:
  repo_backup_changed_modules.sh
  repo_backup_changed_modules.sh -d ~/backup/CONNECT
  repo_backup_changed_modules.sh --since origin/main
  repo_backup_changed_modules.sh -d /mnt/backup --include-ignored --since origin/main
EOF
}

# ---- args ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dest) DEST_ROOT="$2"; shift 2;;
    --since) SINCE_REF="$2"; shift 2;;
    --include-ignored) INCLUDE_IGNORED=1; shift;;
    -h|--help) print_help; exit 0;;
    *) echo "Unknown arg: $1"; print_help; exit 1;;
  esac
done

# if [[ ! -d ".repo" ]]; then
#   echo "ERROR: 현재 디렉토리에 .repo 가 없습니다. repo 루트에서 실행해주세요." >&2
#   exit 1
# fi

ts="$(date +%Y%m%d)"
if [[ -z "${DEST_ROOT}" ]]; then
  DEST_ROOT="${HOME}/backup/repo_changed_${ts}"
else
  DEST_ROOT="$(realpath -m "${DEST_ROOT}")/repo_changed_${ts}"
fi
mkdir -p "${DEST_ROOT}"

echo "[INFO] Backup root: ${DEST_ROOT}"
[[ -n "${SINCE_REF}" ]] && echo "[INFO] Since ref   : ${SINCE_REF}"
[[ ${INCLUDE_IGNORED} -eq 1 ]] && echo "[INFO] Include ignored files: yes"

function backup_project() {
  local dir="$1"
  local tmp_list
  tmp_list="$(mktemp)"
  trap 'rm -f "$tmp_list"' RETURN

  # 변경/스테이징/언트랙트(+옵션) + (옵션) since ref 비교
  {
    # 워킹트리 변경(삭제 제외)
    git -C $dir diff -z --name-only --diff-filter=ACMRT || true
    # 스테이징 변경(삭제 제외)
    git -C $dir diff -z --cached --name-only --diff-filter=ACMRT || true
    # 기준 ref 비교(삭제 제외)
    if [[ -n "${SINCE_REF}" ]]; then
      git -C $dir diff -z --name-only --diff-filter=ACMRT "${SINCE_REF}"...HEAD || true
    fi
    # 언트랙트 파일
    if [[ ${INCLUDE_IGNORED} -eq 1 ]]; then
      git -C $dir ls-files -z --others -i --exclude-standard || true
    else
      git -C $dir ls-files -z --others --exclude-standard || true
    fi
  } > "${tmp_list}"

  # log -d "[DEBUG] ${dir}: File list written to ${tmp_list}"

  # NUL 레코드 수 세기
  local cnt
  # cnt=$(awk -vRS='\0' 'END{print NR-1}' "${tmp_list}")
  cnt=$(tr -cd '\0' < "$tmp_list" | wc -c | tr -d ' ')
  if [[ "${cnt}" -le 0 ]]; then
    # 변경 없음 → 스킵
    return 0
  fi
  log -d "[DEBUG] ${dir}: ${cnt} files to copy"
  cat "${tmp_list}" | tr '\0' '\n'  # for debug
  
  local subdir_rel=$(realpath --relative-to="$REPO_TOP" "$dir")
  local dest_dir="${DEST_ROOT}/${subdir_rel}"
  # local dest_dir="${DEST_ROOT}/${dir}"

    # 복사 수행: 상대경로 유지(-R/--relative), NUL 목록(--from0)
  mkdir -p "${dest_dir}"
  # current dir 기준에서 tmp_list에 있는 파일들을 dest_dir로 복사
  rsync -aR --from0 --files-from="${tmp_list}" "${dir}/" "${dest_dir}/"
  
  # rsync -aR --from=${dir} --files-from="${tmp_list}" . "${dest_dir}/"

  STATUS=$?
  if [ "$STATUS" -ne 0 ]; then
    log -e "❌ $dir backup failed!"
    return 1
  fi
  log -i "[BACKUP] ${subdir_rel}  (${cnt} files)"
}

# 하위 디렉토리 목록 가져오기
repo_list_subdirectories.sh | while read -r dir; do
  # log -i "📂 $dir"
  if [ -d "$dir/.git" ]; then
    # (git -C $dir $GIT_CMD)
    backup_project "$dir"
  else
    echo "⚠️  .git directory is not exist: $dir"
  fi
done

# # --- per-project worker ---
# per_project() {
#   echo "[PROCESS] ${REPO_PATH} ..."
#   # repo forall 제공 변수: REPO_PATH, REPO_PROJECT, REPO_LREV, REPO_REMOTE
#   local proj_path="${REPO_PATH}"
#   local dest_dir="${DEST_ROOT}/${proj_path}"
#   local tmp_list
#   tmp_list="$(mktemp)"
#   trap 'rm -f "$tmp_list"' RETURN

#   # 변경/스테이징/언트랙트(+옵션) + (옵션) since ref 비교
#   {
#     # 워킹트리 변경(삭제 제외)
#     git diff -z --name-only --diff-filter=ACMRT || true
#     # 스테이징 변경(삭제 제외)
#     git diff -z --cached --name-only --diff-filter=ACMRT || true
#     # 기준 ref 비교(삭제 제외)
#     if [[ -n "${SINCE_REF}" ]]; then
#       git diff -z --name-only --diff-filter=ACMRT "${SINCE_REF}"...HEAD || true
#     fi
#     # 언트랙트 파일
#     if [[ ${INCLUDE_IGNORED} -eq 1 ]]; then
#       git ls-files -z --others -i --exclude-standard || true
#     else
#       git ls-files -z --others --exclude-standard || true
#     fi
#   } > "${tmp_list}"

#   echo "[DEBUG] ${proj_path}: File list written to ${tmp_list}"

#   # NUL 레코드 수 세기
#   local cnt
#   # cnt=$(awk -vRS='\0' 'END{print NR-1}' "${tmp_list}")
#   cnt=$(tr -cd '\0' < "$tmp_list" | wc -c | tr -d ' ')
#   echo "[DEBUG] ${proj_path}: ${cnt} files to copy"
#   if [[ "${cnt}" -le 0 ]]; then
#     # 변경 없음 → 스킵
#     return 0
#   fi

#   # 복사 수행: 상대경로 유지(-R/--relative), NUL 목록(--from0)
#   mkdir -p "${dest_dir}"
#   rsync -aR --from0 --files-from="${tmp_list}" . "${dest_dir}/"

#   # 삭제된 파일 목록 참고용 저장
#   mkdir -p "${dest_dir}/.backup_meta"
#   {
#     git diff --name-only --diff-filter=D || true
#     git diff --cached --name-only --diff-filter=D || true
#     if [[ -n "${SINCE_REF}" ]]; then
#       git diff --name-only --diff-filter=D "${SINCE_REF}"...HEAD || true
#     fi
#   } | sort -u > "${dest_dir}/.backup_meta/deleted_files.txt"

#   # 메타 정보
#   {
#     echo "project: ${REPO_PROJECT}"
#     echo "path:    ${proj_path}"
#     echo "remote:  ${REPO_REMOTE}"
#     echo "lrev:    ${REPO_LREV}"
#     [[ -n "${SINCE_REF}" ]] && echo "since:   ${SINCE_REF}"
#     echo "include_ignored: ${INCLUDE_IGNORED}"
#     echo "files_copied_count: ${cnt}"
#     echo "time:    $(date -Is)"
#   } > "${dest_dir}/.backup_meta/info.txt"

#   echo "[BACKUP] ${proj_path}  (${cnt} files)"
# }

# export DEST_ROOT SINCE_REF INCLUDE_IGNORED
# # export -f per_project

# # 모든 프로젝트 순회
# # shellcheck disable=SC2016
# # repo forall -c 'bash -c per_project'
# repo forall -c "bash -lc '$(declare -f per_project); per_project'"

# echo "[DONE] 선택 백업 완료: ${DEST_ROOT}"

