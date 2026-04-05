#!/usr/bin/env bash
source common/common_bash.sh

function build_module() {
    local module="${1:-frameworks}"
    log -i "Building module: ${module}"
    
    # 전역 설정을 통한 빌드 서버 참조 시도
    local build_svr="${BUILD_SERVER:-svr}"
    
    do_execute "ssh -t ${build_svr} 'cd ~/android && make ${module} -j$(nproc)'"
}

build_module "$@"
