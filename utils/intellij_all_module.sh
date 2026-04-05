#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <module_path>"
    exit 1
fi

TARGET="$1"
BASE_PATH="${TARGET%/}"  # 끝의 / 제거
IML_DIR="intellij/.idea/modules"
MODULES_XML="intellij/.idea/modules.xml"

mkdir -p "$IML_DIR"

function is_valid_module() {
    local path="$1"
    # 유효한 모듈 디렉토리 조건 (Native grep -q 사용)
    find "$path" -maxdepth 5 \( \
        -name "src" -o \
        -name "java" -o \
        -name "aidl" -o \
        -name "jni" -o \
        -name "Android.bp" -o \
        -name "build.gradle" -o \
        -name "build.gradle.kts" \
    \) -print -quit | grep -q .
}

function add_module() {
    local mod_path="$1"
    local dot_path="${mod_path//\//.}"
    local iml_file="$IML_DIR/$dot_path.iml"

    # 이미 존재하면 스킵
    if [[ -f "$iml_file" ]]; then
        echo "⚠️  Already exists: $iml_file"
        return
    fi

    # .iml 생성 (Variables quoted)
    cat > "$iml_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<module type="JAVA_MODULE" version="4">
  <component name="NewModuleRootManager" inherit-compiler-output="true">
    <content url="file://\$MODULE_DIR\$/../../../$mod_path" />
    <orderEntry type="inheritedJdk" />
    <orderEntry type="sourceFolder" forTests="false" />
  </component>
</module>
EOF

    echo "✔ Created: $iml_file"

    # modules.xml에 이미 존재하는지 확인 (Improved check)
    if ! grep -q "$dot_path.iml" "$MODULES_XML" 2>/dev/null; then
        local TMP
        TMP="$(mktemp)"
        awk -v new_module="      <module fileurl=\"file://\$PROJECT_DIR\$/.idea/modules/$dot_path.iml\" filepath=\"\$PROJECT_DIR\$/.idea/modules/$dot_path.iml\" />" '
            /<\/modules>/ { print new_module }
            { print }
        ' "$MODULES_XML" > "$TMP"
        mv "$TMP" "$MODULES_XML"
        echo "✔ Added to modules.xml"
    else
        echo "⚠️  Already registered in modules.xml"
    fi
}

# 1-depth 하위 디렉토리 순회
for dir in "$BASE_PATH"/*; do
    [[ -d "$dir" ]] || continue
    if is_valid_module "$dir"; then
        add_module "${dir#./}"
    else
        echo "⏭️  Skipped (no valid source): $dir"
    fi
done
