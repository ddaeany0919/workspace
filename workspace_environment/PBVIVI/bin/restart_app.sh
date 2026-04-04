#!/bin/bash

PKG_NAME="$1"

if [ -z "$PKG_NAME" ]; then
    echo "Usage: $0 <package.name>"
    exit 1
fi

# 1. main activity component name 추출
COMPONENT=$(adb shell cmd package resolve-activity --brief "$PKG_NAME" | tail -n 1)

if [[ "$COMPONENT" != *"/"* ]]; then
    echo "Failed to resolve main activity for $PKG_NAME"
    exit 1
fi

echo "Resolved component: $COMPONENT"

# 2. taskId 조회
TASK_ID=$(adb shell "am stack list" | grep -A 1 "$PKG_NAME" | grep taskId | sed -n 's/.*taskId=\([0-9]*\):.*/\1/p')

if [ -n "$TASK_ID" ]; then
    echo "Removing existing taskId=$TASK_ID"
    adb shell "am stack remove $TASK_ID"
fi

# 3. main activity 실행
adb shell "am start -n $COMPONENT -f 0x10008000"