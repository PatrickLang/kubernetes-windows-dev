#!/bin/bash
set -u -x -e

# This borrowed a lot of ideas from https://raw.githubusercontent.com/kubernetes/kubernetes/master/hack/cherry_pick_pull.sh
# If you're looking for more capabilities like creating new PRs, be sure to start from that script instead of this one

dir=$(mktemp -d)

export PRS=$(cat <<-END
61778
63600
67435
67884
69516
69525
69568
69571
END
)

export MAIN_REPO_ORG=kubernetes
export MAIN_REPO_NAME=kubernetes
export AGGREGATION_REPO_ORG=azure
export AGGREGATION_REPO_NAME=kubernetes
export AGGREGATION_BRANCH=windows-v1.13-dev

echo Will fetch PRs: ${PRS}

if [ -d .git ]; then
    echo "Repo already exists, skipping creation"
    git reset HEAD -- .
    git checkout -- .
    git clean -df
    git checkout ${AGGREGATION_BRANCH}
    git reset --hard master
    git reset HEAD -- .
else
    git clone https://github.com/${AGGREGATION_REPO_ORG}/${AGGREGATION_REPO_NAME}.git .
    git remote add upstream https://github.com/${MAIN_REPO_ORG}/${MAIN_REPO_NAME}.git
    git fetch upstream
    git checkout ${AGGREGATION_BRANCH}
fi

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