# Integrated with common_bash.sh for faster execution
source common_bash.sh

function git_log_recursive() {
    local num="${1:-10}"
    while read -r dir; do
        local repo_path="${dir%/.git}"
        echo -e "${COLOR_CYAN}===== ${repo_path#./} =====${COLOR_END}"
        git -C "${repo_path}" log --graph --abbrev-commit --decorate \
            --date=format:'%y/%m/%d %T %a' \
            --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ad)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' -"${num}"
    done < <(find ./ -name .git -type d)
}

function git_log() {
    git log --graph --abbrev-commit --decorate --date=format:'%y/%m/%d %T %a' \
        --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ad)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' "$@"
}

function git_status_recursive() {
    while read -r dir; do
        local repo_path="${dir%/.git}"
        local status
        status=$(git -C "${repo_path}" status -s)
        if [[ -n "$status" ]]; then
            echo -e "${COLOR_YELLOW}---- ${repo_path#./} ----${COLOR_END}"
            echo "$status"
        fi
    done < <(find ./ -name .git -type d)
}

function git_recursive() {
    local command="$*"
    [[ -z "$command" ]] && return
    while read -r dir; do
        local repo_path="${dir%/.git}"
        echo -e "${COLOR_CYAN}===== ${repo_path#./} =====${COLOR_END}"
        git -C "${repo_path}" ${command}
    done < <(find ./ -name .git -type d)
}
