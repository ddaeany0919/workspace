#!/usr/bin/env bash

# Use native bash repetition instead of seq for better performance
function stress_cpu() {
    local count="${1:-4}"
    local duration="${2:-0}"
    log -i "Starting CPU stress with $count workers..."
    
    for ((i=0; i<count; i++)); do
        dd if=/dev/zero of=/dev/null &
    done
    
    if (( duration > 0 )); then
        sleep "$duration"
        pkill dd
    fi
}

stress_cpu "$@"
