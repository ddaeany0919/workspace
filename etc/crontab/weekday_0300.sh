#!/bin/bash --login
me=$(basename "$0")
echo "start $me via $(whoami)"
sudo -u luis bash -c "source ~/workspace/bin/.bashrc_luis && repo_mirror_sync.sh"
