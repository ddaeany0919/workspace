#!/bin/bash
source common_bash.sh

target_device="${ANDROID_SERIAL:+-s ${ANDROID_SERIAL}}"

CACHE_FILE="${WORKSPACE_HOME}/temp/launchable_activities.txt"
COUNT=""
SLEEP_MS=0
MODE="cached"

print_usage() {
    echo "Usage: $0 [-m] [-c count] [-t interval_ms] [-h]"
    echo "  -m          Update cached launchable activity list"
    echo "  -c count    Number of random launches (default: 1)"
    echo "  -t ms       Interval (ms) between launches"
    echo "  -h          Show this help message"
}

# Argument parsing
while getopts "mhc:t:" opt; do
    case "$opt" in
        m) MODE="update" ;;
        h) print_usage; exit 0 ;;
        c) COUNT="$OPTARG" ;;
        t) SLEEP_MS="$OPTARG" ;;
        *) print_usage; exit 1 ;;
    esac
done

# Update mode: regenerate activity list
if [ "$MODE" == "update" ]; then
    echo "🔄 Updating launchable activity list..."
    > "$CACHE_FILE"
    packages=$(adb ${target_device} shell pm list packages | cut -d':' -f2)

    for pkg in $packages; do
        output=$(adb ${target_device} shell cmd package resolve-activity --brief --components -p ${pkg} 2>/dev/null)

        if [[ "$output" == *"/"* ]]; then
            component=$(echo "$output" | tr -d '\r')
            echo "$component" >> "$CACHE_FILE"
            log -i "✔ $component"
        fi
    done
    log -i "✅ Cache updated: $CACHE_FILE"
    exit 0
fi

# Check if cache exists
if [ ! -f "$CACHE_FILE" ]; then
    log -e "❗ No cache found. Run with -m to generate activity list."
    exit 1
fi

# Load cached activities
mapfile -t activity_list < "$CACHE_FILE"

if [ ${#activity_list[@]} -eq 0 ]; then
    log -e "❌ Cached activity list is empty. Run with -m to update."
    exit 1
fi

launch_random() {
    random_index=$((RANDOM % ${#activity_list[@]}))
    random_activity=${activity_list[$random_index]}
    
    do_execute -i adb ${target_device} shell am start -n "$random_activity"

    if [[ "$SLEEP_MS" =~ ^[0-9]+$ ]] && [[ "$SLEEP_MS" -gt 0 ]]; then
        sleep_time=$(bc <<< "scale=3; $SLEEP_MS / 1000")
        sleep "$sleep_time"
    fi
}


# 실행 루프
if [[ -z "$COUNT" ]]; then
    echo "🔁 Running in infinite mode. Press Ctrl+C to stop."
    while true; do
        launch_random
    done
else
    for ((i = 1; i <= COUNT; i++)); do
        echo "[$i/$COUNT]"
        launch_random
    done
fi
# # Launch random activities
# for ((i = 1; i <= COUNT; i++)); do
#     random_index=$((RANDOM % ${#activity_list[@]}))
#     random_activity=${activity_list[$random_index]}
#     log -i "🚀 [$i/$COUNT] Launching: $random_activity"
#     do_execute -i adb ${target_device} shell am start -n "$random_activity"

#     if [ "$i" -lt "$COUNT" ] && [ "$SLEEP_MS" -gt 0 ]; then
#         sleep $(bc <<< "scale=3; $SLEEP_MS / 1000")
#     fi
# done
