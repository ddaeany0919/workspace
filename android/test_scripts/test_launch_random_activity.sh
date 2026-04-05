#!/usr/bin/env bash

source common_bash.sh

target_device="${ANDROID_SERIAL:+-s ${ANDROID_SERIAL}}"
CACHE_FILE="${WORKSPACE_HOME}/temp/launchable_activities.txt"
COUNT=""
SLEEP_MS=0
MODE="cached"

function print_usage() {
    echo "Usage: $0 [-m] [-c count] [-t interval_ms] [-h]"
    echo "  -m          Update cached launchable activity list"
    echo "  -c count    Number of random launches (default: infinite)"
    echo "  -t ms       Interval (ms) between launches"
    echo "  -h          Show this help message"
}

while getopts "mhc:t:" opt; do
    case "$opt" in
        m) MODE="update" ;;
        h) print_usage; exit 0 ;;
        c) COUNT="$OPTARG" ;;
        t) SLEEP_MS="$OPTARG" ;;
        *) print_usage; exit 1 ;;
    esac
done

if [[ "$MODE" == "update" ]]; then
    log -i "🔄 Updating launchable activity list..."
    mkdir -p "$(dirname "$CACHE_FILE")"
    > "$CACHE_FILE"
    
    local packages
    packages=$(adb ${target_device} shell pm list packages | cut -d':' -f2)

    for pkg in $packages; do
        local output
        output=$(adb ${target_device} shell cmd package resolve-activity --brief --components -p "${pkg}" 2>/dev/null)
        if [[ "$output" == *"/"* ]]; then
            local component="${output//$'\r'/}"
            echo "$component" >> "$CACHE_FILE"
            log -i "✔ $component"
        fi
    done
    log -i "✅ Cache updated: $CACHE_FILE"
    exit 0
fi

[[ -f "$CACHE_FILE" ]] || { log -e "❗ No cache found. Run with -m first."; exit 1; }

mapfile -t activity_list < "$CACHE_FILE"
(( ${#activity_list[@]} == 0 )) && { log -e "❌ Activity list is empty."; exit 1; }

function launch_random() {
    local random_index=$((RANDOM % ${#activity_list[@]}))
    local random_activity="${activity_list[random_index]}"
    
    do_execute -i adb ${target_device} shell am start -n "$random_activity"

    if (( SLEEP_MS > 0 )); then
        local sleep_sec
        sleep_sec=$(printf "%.3f" "$(($SLEEP_MS))e-3")
        sleep "$sleep_sec"
    fi
}

if [[ -z "$COUNT" ]]; then
    log -i "🔁 Running in infinite mode. Press Ctrl+C to stop."
    while true; do launch_random; done
else
    for ((i = 1; i <= COUNT; i++)); do
        log -i "🚀 [$i/$COUNT] Launching..."
        launch_random
    done
fi
