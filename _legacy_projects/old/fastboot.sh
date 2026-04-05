#!/usr/bin/env bash
source common/common_bash.sh

# 하드코딩된 IP 및 경로 최적화
TARGET_IP="${1:-192.168.1.1}"
GW="${2:-192.168.1.254}"

function run_fastboot() {
    log -i "Setting up fastboot for IP: ${TARGET_IP}"
    # 복잡한 커맨드 조합 최적화
    local cmd="ifconfig eth0 -addr=${TARGET_IP} mask=255.255.255.0 -gw=${GW}; boot -elf -noclose flash0.BSU1"
    do_execute "android fastboot -transport=tcp -device=flash0"
}

run_fastboot
