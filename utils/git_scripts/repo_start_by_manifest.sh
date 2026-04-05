#!/bin/bash

REPO_ROOT=$(repo --show-toplevel)
MANIFEST_FILE="${REPO_ROOT}/.repo/manifest.xml"

CPU_COUNT=$(nproc)
OPT="-c -j${CPU_COUNT}"
for project in $(repo_list_submodules.sh ${PWD}); do
    
    # echo "Processing project: $project"
    
    # Extracting the directory and manifest revision for each project
    # Using repo info to get the mount path and manifest revision
    # Note: The repo info command may vary based on your repo version and setup
    # Ensure that the project is a valid repo project
    if [[ -z "$project" ]]; then
        echo "❌ No valid project found. Skipping..."
        continue
    fi
    info=$(repo info $project)
    # echo "$info"
    info=$(env -i HOME="$HOME" PATH="$PATH" LANG=C.UTF-8 LC_ALL=C.UTF-8 PYTHONNOUSERSITE=1 PYTHONPATH= \
       repo info -- "$project" 2>&1)
    rc=$?
    # echo "Return code: $rc"
    # echo "Info output: $info"
    if [ $rc -gt 0 ]; then
        echo "❌ Project ${project} does not exist or is not a valid repo project. Skipping..."
        exit 1
    fi
    # info=$(repo info "$project")
    if [[ -z "$info" ]]; then
        echo "❌ No info found for project ${project}. Skipping..."
        continue
    fi
    # echo "$info"
    # Extracting the mount path and manifest revision
    # Adjust the grep and awk commands based on your repo info output format
    # sample output:
    # ----------------------------
    # Manifest branch: master
    # Manifest merge branch: refs/heads/master
    # Manifest groups: default,platform-linux
    # Superproject revision: None----------------------------
    # Project: graphics.adreno_buildcfg
    # Mount path: /home/luis/workspace/1.Projects/CONNECT/lagvm/LINUX/android/vendor/qcom/proprietary/gles/adreno_buildcfg
    # Current revision: 5e70d05d61cc71de6c410f9ca7609814febaae57
    # Current branch: m_aos4_qct_8255_hqx_release
    # Manifest revision: 5e70d05d61cc71de6c410f9ca7609814febaae57
    # Local Branches: 1 [m_aos4_qct_8255_hqx_release]
    # ----------------------------

    mount_path=$(echo "$info" | grep "^Mount path:" | sed 's/Mount path:[[:space:]]*//')
    current_revision=$(echo "$info" | grep "^Current revision:" | sed 's/Current revision:[[:space:]]*//')
    current_branch=$(echo "$info" | grep "^Current branch:" | sed 's/Current branch:[[:space:]]*//')
    manifest_revision=$(echo "$info" | grep "^Manifest revision:" | sed 's/Manifest revision:[[:space:]]*//')

    # directory=$(echo $info | grep -i "mount path" | sed 's/Mount path:[[:space:]]*//')
    
    echo "📂 ${project}"
    # go to the project directory
    cd ${mount_path}
    # echo "Current directory: $(pwd)"
    # check if revision matches
    # check current branch name on mount path
    

    if [[ "$current_branch" != "$manifest_revision" ]]; then
        echo "🔧 Current branch (${current_branch}) does not match manifest revision (${manifest_revision})"
        # Here you would typically run the sync command
        # For example:
        # repo sync ${OPT} "${project}"

        # check need git stash
        # if git diff-index --quiet HEAD --; then
        #     echo "No local changes detected. Proceeding with sync."
        # else
        #     echo "Local changes detected. Stashing changes before sync."
        #     git stash push -m "Stashing changes before repo sync"
        # fi
        # # Perform the sync operation
        # repo sync ${OPT} "${project}" >> /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✅ Sync completed"
            git checkout "${manifest_revision}" >> /dev/null 2>&1
            if [ $? -gt 0 ]; then
                echo "⚠️ Failed to checkout to manifest revision ${manifest_revision} for project ${project}."
            fi
        fi
    
    else
        echo "      Already checked out ${manifest_revision}"
    fi
    cd -
done