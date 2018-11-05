#!/bin/bash
set -u -x -e

# This borrowed a lot of ideas from https://raw.githubusercontent.com/kubernetes/kubernetes/master/hack/cherry_pick_pull.sh
# If you're looking for more capabilities like creating new PRs, be sure to start from that script instead of this one

dir=$(mktemp -d)

# substitutes
# #67884 - a17a561a9e00c126a3cdb347e1ce415b536045d5

export PRS=$(cat <<-END
#61778
#63600
b6ffa3fdb583303b47c80409ee23e4314b810832
#67435
a17a561a9e00c126a3cdb347e1ce415b536045d5
#69525
#70156
END
)

export MAIN_REPO_ORG=kubernetes
export MAIN_REPO_NAME=kubernetes
export AGGREGATION_REPO_ORG=azure
export AGGREGATION_REPO_NAME=kubernetes
export AGGREGATION_BRANCH=windows-v1.13-dev

echo Will fetch PRs: ${PRS}

if [ -d .git ]; then
    echo "Repo already exists. Discarding local changes, and syncing from origin/master"
    git am --abort || git rebase --abort || true
    git reset HEAD -- .
    git checkout -- .
    git clean -df
    git checkout master
    git pull
    git checkout ${AGGREGATION_BRANCH}
    git reset --hard master
    git reset HEAD -- .
else
    git clone git@github.com:${AGGREGATION_REPO_ORG}/${AGGREGATION_REPO_NAME}.git
    git remote add upstream https://github.com/${MAIN_REPO_ORG}/${MAIN_REPO_NAME}.git
    git fetch upstream
    git checkout ${AGGREGATION_BRANCH}
fi

PR_REGEX="^\#"
for item in ${PRS[@]}; do
    if [[ "$item" =~ $PR_REGEX ]]; then
        pull="$(echo $item | sed 's/^\#//')"
        echo "Cherry-picking https://github.com/${MAIN_REPO_ORG}/${MAIN_REPO_NAME}/pull/${pull}.patch"
        curl -o "$dir/${pull}.patch" -sSL "https://github.com/${MAIN_REPO_ORG}/${MAIN_REPO_NAME}/pull/${pull}.patch"
        git am -3 "$dir/${pull}.patch" || { 
            echo "Failed to merge. Stopping now"
            exit 1
        }
    else
        echo "Pulling existing change $item"
        git merge $item
    fi
done

rm -rf "${dir}"

echo Success! Now run git push --force-with-lease
exit 0