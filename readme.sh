#!/usr/bin/env bash

source common_bash.sh

DEBUG=false

if [ -z ${WORKSPACE_PROJECT} ]; then
    log -e "This script should be run in workspace environment."
    exit 1
fi

# check README.md file that is symbolic link
if [ ! -f "${WORKSPACE_HOME}/README.md" ]; then
    log -i "Create README.md file"
    touch ${WORKSPACE_HOME}/.workspace_env/README.md
fi


# check arguments
if [ $# -eq 0 ]; then
    cat ${WORKSPACE_HOME}/README.md | glow -w 1
    exit 0
fi

# get options
while getopts "a?" option; do
    case $option in
        a) 
            # append all argument to README.md
            shift $((OPTIND-1))
            echo "$@" >> ${WORKSPACE_HOME}/README.md
            ;;
        ?) 
            cat ${WORKSPACE_HOME}/README.md | glow -w 1
            ;;
    esac
done

