#!/bin/sh
memState=""
while true; do
    gear=$(getprop "vendor.mobis.camera.gear")
    mobis_evs_pid=$(pidof mobis_evs_qcx_aidl_app)
    qcx_evs_pid=$(pidof android.hardware.automotive.evs-qcx)

    mobis_evs_fd=$(lsof -p $mobis_evs_pid | wc -l) ; 
    qcx_evs_fd=$(lsof -p $qcx_evs_pid | wc -l) ; 
    mobis_evs=$(dmabuf_dump $mobis_evs_pid | grep "PROCESS TOTAL" | awk '{print $3 " " $4}'); 
    qcx_evs=$(dmabuf_dump $qcx_evs_pid | grep "PROCESS TOTAL" | awk '{print $3 " " $4}'); 

    state="| $gear | EVS [$mobis_evs_pid]: $mobis_evs (FD: $mobis_evs_fd) | QCX [$qcx_evs_pid]: $qcx_evs (FD: $qcx_evs_fd)"; 
    if [ "$state" != "$memState" ]; then
        _date=$(date +'%m-%d %H:%M:%S.%3N'); 
        echo "$_date $state"
        memState="$state"
    fi
    sleep 2;
done;