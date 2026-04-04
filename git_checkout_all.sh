#!/usr/bin/env bash

source common_bash.sh
# usage: git_checkout_all.sh <branch> [dir1 dir2 dir3 ...]
# example: git_checkout_all.sh feature/test A B C


branch="$1"
shift

if [[ $# -eq 0 ]]; then
    log -e "Usage: $0 <branch> <dir1> [dir2 ...]"
    exit 1
fi

for dir in "$@"; do
    if [[ -d "$dir/.git" ]]; then
        log -i "==> [$dir] checking out to branch '$branch'..."
        cd "$dir"
        # echo "Current directory: $(pwd)"
        do_execute -i git fetch --all --prune >/dev/null 2>&1
        if do_execute -i git show-ref --verify --quiet "refs/heads/$branch"; then
            do_execute -i git checkout "$branch"
        else
            do_execute -i git checkout -b "$branch" "origin/$branch" 2>/dev/null || git checkout "$branch"
        fi
        cd - >/dev/null 2>&1
        
    else
        log -w "⚠️  [$dir] is not a git repository, skipping."
    fi
done

log -i "✅ All done!"
