#!/bin/bash
set -u -x

# This borrowed a lot of ideas from https://raw.githubusercontent.com/kubernetes/kubernetes/master/hack/cherry_pick_pull.sh
# If you're looking for more capabilities like creating new PRs, be sure to start from that script instead of this one

dir=$(mktemp -d)

export PRS="${@}"
export MAIN_REPO_ORG=kubernetes
export MAIN_REPO_NAME=kubernetes
export AGGREGATION_REPO_ORG=azure
export AGGREGATION_REPO_NAME=kubernetes

echo Will fetch PRs: $PRS

if 
git clone https://github.com/${AGGREGATION_REPO_ORG}/${AGGREGATION_REPO_NAME}.git .
git remote add upstream https://github.com/${MAIN_REPO_ORG}/${MAIN_REPO_NAME}.git
git fetch upstream


for pull in ${PRS[@]}; do
    echo "Cherry-picking https://github.com/${MAIN_REPO_ORG}/${MAIN_REPO_NAME}/pull/${pull}.patch"
    curl -o "$dir/${pull}.patch" -sSL "https://github.com/${MAIN_REPO_ORG}/${MAIN_REPO_NAME}/pull/${pull}.patch"
    git apply -3 "$dir/${pull}.patch" || { 
        echo "Failed to merge. Stopping now"
        exit 1
    }
done

echo Once fixups done, run git push --force-with-lease

rm -rf "${dir}"
exit 0