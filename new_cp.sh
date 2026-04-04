#!/usr/bin/bash

source common_bash.sh

DEBUG=true;


function new_cp {
    local argsCount=$#
    log -d "args count=${argsCount}"
    if [ ${argsCount} -lt 2 ]; then
        log -w "need more arguments"
        exit 1;
    else
        local lastElement=${@:argsCount}
        log -d "last_args=${lastElement}"
        

    fi


    
    
    

    

}

new_cp $@



