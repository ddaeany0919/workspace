#!/usr/bin/env bash

source common_bash.sh

# repo sync 최적화 (Quoted)
CPU_COUNT=$(nproc)
repo sync -c -j"${CPU_COUNT}" $(repo_list_submodules.sh "${PWD}")
