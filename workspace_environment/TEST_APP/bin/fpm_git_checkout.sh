source common_bash.sh

# set branch, default to DEV-FPM
branch="${1:-DEV-FPM}"

# set dir_list array
declare -a dir_list
dir_list=()
dir_list+=("${WORKSPACE_ANDROID_HOME}/device/hmg/common/")
dir_list+=("${WORKSPACE_ANDROID_HOME}/device/mobis/common/")
dir_list+=("${WORKSPACE_ANDROID_HOME}/vendor/hmg/packages/services/Car/plugins/fingerprint/")
dir_list+=("${WORKSPACE_ANDROID_HOME}/vendor/mobis/proprietary/frameworks/")
# shift
# for dir in "$@"; do
#     dir_list+=("$dir")
# done

log "Branch to checkout: $branch"
log "Directories to process: ${dir_list[*]}"

git_checkout_all.sh "$branch" "${dir_list[@]}"