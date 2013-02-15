#!/usr/bin/env bash
# bin/compile run <source-repo> <source-branch> <destination-repo> <destination-branch>

# fail fast
set -e

if [ "run" != "$1" ]; then
  exec ssh -i "$IDENTITY_FILE" -o "StrictHostKeyChecking no" "$@"
fi

# parse args
SOURCE_REPO=$2
SOURCE_BRANCH=$3
DESTINATION_REPO=$4
DESTINATION_BRANCH=$5

echo "Source Git Repo: $SOURCE_REPO #$SOURCE_BRANCH"
echo "Destination Git Reop: $DESTINATION_REPO #$DESTINATION_BRANCH"

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
echo "Cloning $SOURCE_REPO : $SOURCE_BRANCH in $repo"
git clone --bare --recursive --branch $SOURCE_BRANCH $SOURCE_REPO $repo
cd $repo
echo "Adding remote deploy $DESTINATION_REPO"
git remote add deploy $DESTINATION_REPO
echo "Pushing to deploy $SOURCE_BRANCH:$DESTINATION_BRANCH"
git push deploy $SOURCE_BRANCH:$DESTINATION_BRANCH

set +e

echo "Cleaning up..."
rm -f "$IDENTITY_FILE"
rm -f "$IDENTITY_FILE.pub"
rm -rf $repo

echo "done."
exit 0