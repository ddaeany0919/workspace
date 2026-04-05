#!/usr/bin/env bash
# Integrated and Optimized Common Bash for Legacy Projects

# 1. Colors
export COLOR_END='\033[0m'
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[0;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_CYAN='\033[0;36m'

# 2. Logging
DEBUG=false
function log() {
    local type="$1"
    local msg="${*:2}"
    local time
    printf -v time '%(%H:%M:%S)T' -1
    
    case "$type" in
        "-i") echo -e "${time} ${COLOR_GREEN}[INFO]${COLOR_END} $msg" ;;
        "-w") echo -e "${time} ${COLOR_YELLOW}[WARN]${COLOR_END} $msg" ;;
        "-e") echo -e "${time} ${COLOR_RED}[ERROR]${COLOR_END} $msg" ;;
        *) echo -e "${time} [LOG] $msg" ;;
    esac
}

# 3. Execution
function do_execute() {
    local cmd="$*"
    log -i "Executing: $cmd"
    eval "$cmd"
    local res=$?
    (( res != 0 )) && log -e "Command failed with exit code $res"
    return $res
}

# 4. Utilities
function isNumber() {
    [[ "$1" =~ ^-?[0-9]+$ ]] && echo 1 || echo 0
}
