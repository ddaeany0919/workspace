#!/usr/bin/env bash

source common_bash.sh

# repo list 기반 서브디렉토리 추출 최적화
function list_repo_dirs() {
    local subdir_abs repo_root subdir_rel
    subdir_abs=$(realpath "$PWD")
    repo_root=$(repo --show-toplevel 2>/dev/null)
    
    [[ -z "$repo_root" ]] && { log -w "repo root not found"; return 1; }
    
    subdir_rel=$(realpath --relative-to="$repo_root" "$subdir_abs")
    
    # Simple and fast awk for filtering
    repo list | awk -F': ' -v prefix="$subdir_rel/" '
        $1 ~ ("^" prefix) {
            sub("^" prefix, "", $1);
            print $1;
        }'
}

list_repo_dirs
