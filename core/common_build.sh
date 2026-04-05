function finishBuild() {
    local _message=$1
    exit 1
}

function prepareMakeCmd() {
    CMD_PREPARE="export WORKSPACE_ENV_TERMINAL_TITLE='build_$1' ; source ~/workspace/bin/.bashrc_luis && cd ${ANDROID_BUILD_TOP}"
}

function makeCleanBuild() {
    if ! ${ONLY_APPLY}; then
        local command="${CMD_PREPARE} ; "
        local cleanModules=""
        local buildModules=""
        for module in "$@"; do
            cleanModules="${cleanModules} clean-${module}"
            buildModules="${buildModules} ${module}"
            # command="${command} clean-${module} ${module}"
            # if [ -z "${cleanModules}" ]; then
            #     cleanModules="make clean-${module}"
            # else
            #     cleanModules="${cleanModules} clean-${module}"
            # fi
            # if [ -z "${buildModules}" ]; then
            #     buildModules="make ${module}"
            # else
            #     buildModules="${buildModules} ${module}"
            # fi
        done
        if $NINJA_BUILD; then
            command="${command} ${COMMAND_PREFIX} ${NINJA_COMMAND_PREFIX} ${buildModules}"
        else 
            local cleanCommands="${COMMAND_PREFIX} make ${cleanModules}"
            local buildCommands="${COMMAND_PREFIX} make ${buildModules}"

            # if [ ! -z "${cleanModules}" ]; then
            #     command="${command} && ${COMMAND_PREFIX} ${cleanModules}"
            # fi
            # if [ ! -z "${buildModules}" ]; then
            #     command="${command} ${buildModules} -j100"
            # fi

            command="${command} ${cleanCommands} && ${buildCommands}"
        fi
        log -i "makeCleanBuild() command=${command}"
        # return 1


        if ! eval ${SSH_COMMAND} "\"${command}\""; then
            log -w "build failed!"
            return 1
        else 
            log -i "??build success!!"
            for module in "$@"; do
            log -i "?“¦ $module"
            done
            
        fi
    fi

    return 0
}

# path, binary name, process name
function pushModules() {
    # check arguments whether array or string
    if [ $# -eq 0 ]; then
        log -e "pushModules() requires at least one argument"
        return 1
    elif [ $# -gt 1 ]; then
        local paths=("$@")
        for path in "${paths[@]}"; do
            if ! pushModules "${path}"; then
                return 1
            fi
        done
        return 0
    fi
    local source_path="$1"
    local dest_path="${source_path%/*}/"
    local executeOpt="-i"
    if $VIRTUAL_MODE; then
        executeOpt="-v"
    fi

    eval "source=${ANDROID_OUTPUT}${source_path}"
    if adb_connect && do_execute $executeOpt "$ADB_PUSH ${source} ${dest_path}"; then
        do_execute $executeOpt "adb shell sync"
        return 0
    else
        finishBuild "deploy failed!!"
        return 1
    fi
}

function installApk() {
    
    local source_path="$1"
    local fileName="$2.apk"
    local executeOpt="-i"
    if $VIRTUAL_MODE; then
        executeOpt="-v"
    fi

    eval "source=${ANDROID_OUTPUT}${source_path}"
    if adb_connect && do_execute $executeOpt "$ADB_INSTALL ${ANDROID_OUTPUT}${source_path}/${fileName}"; then
        return 0
    else
        finishBuild "deploy failed!!"
        return 1
    fi
}

function makeApkModule(){
    local moduleName=$1
    local outputPath="$2/${moduleName}"
    local processName=$3

    prepareMakeCmd "${moduleName}"
    if makeCleanBuild "${moduleName}"; then 
        if pushModules "${outputPath}"; then
            adb_kill "${processName}"
        fi
    fi
}

function makeGradleModule(){
    local taskTarget="${GRADLE_FLAVOR^}"

    local moduleName=$1
    local modulePath=$2
    local outputPath="${BUILD_ROOT}/${modulePath}/app/build/outputs/apk/${taskTarget}/release"
    local deployPath="$3/${moduleName}"
    local processName=$4

    prepareMakeCmd "${moduleName}"

    local command="${CMD_PREPARE}/$modulePath && ./gradlew -x lint assemble${taskTarget}Release"

    log "command=${command}"
    log "outputPath=${outputPath}"  

    if ! do_execute -i ${SSH_COMMAND} "\"${command}\""; then
        log -w "build failed!"
        return 1
    else 
        log -i "??build success!! ${moduleName}"
    fi

    local apk_file="$(find ${outputPath} -name "*.apk" -type f | head -n 1)"
    if [ -z "${apk_file}" ]; then
        log -e "APK file not found in ${outputPath}"
        return 1
    fi

    log "outputPath=${outputPath}"
    log "deployPath=${deployPath}"

    eval "source=${apk_file}"
    log "source=${source}"
    if adb_connect && do_execute $executeOpt "$ADB_PUSH ${source} ${deployPath}/${moduleName}.apk"; then
        do_execute $executeOpt "adb shell sync"
        adb_kill "${processName}"
        pm compile -f "${processName}"
        return 0
    else
        finishBuild "deploy failed!!"
        return 1
    fi

    # fi
}
