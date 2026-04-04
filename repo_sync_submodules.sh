#!/bin/bash
CPU_COUNT=$(nproc)
OPT="-c -j${CPU_COUNT}"
repo sync ${OPT} $(repo_list_submodules.sh ${PWD})