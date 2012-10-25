#!/usr/bin/env bash
# bin/compile run <git-source-repo> <git-source-branch> <git-destination-repo> <git-destination-branch>

# fail fast
set -e

if [ "run" != "$1" ]; then
  exec ssh -i "$IDENTITY_FILE" -o "StrictHostKeyChecking no" "$@"
fi

# parse args
GIT_SOURCE_REPO=$2
GIT_SOURCE_BRANCH=$3
GIT_DESTINATION_REPO=$4
GIT_DESTINATION_BRANCH=$5

echo "Source Git Repo: $GIT_SOURCE_REPO #$GIT_SOURCE_BRANCH"
echo "Destination Git Reop: $GIT_DESTINATION_REPO #$GIT_DESTINATION_BRANCH"

self="$( cd "$( dirname "$0" )" && pwd )"/$0

export IDENTITY_FILE="`mktemp /tmp/tmp.XXXXXXXXXX`"
export GIT_SSH="$self"

repo=`mktemp -d /tmp/tmp.XXXXXXXXXX`
trap 'rm -rf $repo' EXIT INT TERM HUP

echo "$RSA_KEY" >"$IDENTITY_FILE"
echo "$RSA_PUBLIC_KEY" >"$IDENTITY_FILE.pub"
trap 'rm -f "$IDENTITY_FILE"' EXIT INT TERM HUP
trap 'rm -f "$IDENTITY_FILE.pub"' EXIT INT TERM HUP
eval $(ssh-agent)
ssh-add "$IDENTITY_FILE"

echo "Using Git Version: `git --version`"
echo "Cloning $GIT_SOURCE_REPO : $GIT_SOURCE_BRANCH in $repo"
git clone --bare --recursive --branch $GIT_SOURCE_BRANCH $GIT_SOURCE_REPO $repo
cd $repo
echo "Adding remote deploy $GIT_DESTINATION_REPO"
git remote add deploy $GIT_DESTINATION_REPO
echo "Pushing to deploy $GIT_SOURCE_BRANCH:$GIT_DESTINATION_BRANCH"
git push deploy $GIT_SOURCE_BRANCH:$GIT_DESTINATION_BRANCH

set +e

echo "Cleaning up..."
rm -f "$IDENTITY_FILE"
rm -f "$IDENTITY_FILE.pub"
rm -rf $repo

echo "done."
exit 0