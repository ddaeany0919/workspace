function git_log_recursive() {
    local num=10;
    if [ ! -z $1 ]; then
        num=$1;
    fi;
    find ./ -name .git | while read dir ; do sh -c "echo ===== ${dir//\.git/} ===== && cd $dir/../ && git log --graph --abbrev-commit --decorate --date=format:'%y/%m/%d %T %a' --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ad)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' -${num}" ; done
}

function git_log() {
    git log --graph --abbrev-commit --decorate --date=format:'%y/%m/%d %T %a' --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ad)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)'
}

function git_log_recursive_prompt() {
    find ./ -name .git | while read dir ; do sh -c "echo ===== ${dir//\.git/} ===== && cd $dir/../ && git log -p --graph --abbrev-commit --decorate --date=format:'%y/%m/%d %T %a' --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ad)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)'" ; done
}

function git_log() {
    git log --graph --abbrev-commit --decorate --date=format:'%y/%m/%d %T %a' --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ad)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' $@
}

function git_log_release() {
   git --no-pager log --graph --abbrev-commit --decorate --date=format:'%Y-%m-%d %H:%M:%S' --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ad)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)'
}

function git_status_recursive() {
    find ./ -name .git | while read dir ; do sh -c "cd $dir/../ && git status -s | grep -q [azAZ09] && echo ---- ${dir//\.git/} ---- && git status -s" ; done
}

function git_recursive() {
    local command=$@
    find ./ -name .git | while read dir ; do sh -c "echo ===== ${dir//\.git/} ===== && git -C $dir $command" ; done
}
