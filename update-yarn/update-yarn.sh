#!/bin/bash
set -e

RED='\033[0;31m'
LIGHT_CYAN='\033[0;36m'
RESET='\033[0m' # No Color

LABEL_NAME="yarn-update"

# Create label if it doesn't exist
if ! gh label list | grep --quiet "$LABEL_NAME"; then
  gh label create "$LABEL_NAME" --color "ededed" --description "A pull request created to update the Yarn package manager version."
fi

# Ensure pull request doesn't exist
EXISTING_YARN_PULL_REQUESTS=$(gh pr list --label "$LABEL_NAME" --state open)
if [ -z "$EXISTING_YARN_PULL_REQUESTS" ]; then
  echo "No existing Yarn update PR found."
else
  echo "Existing Yarn update PR found. Skipping update."
  exit 0;
fi 

# Update yarn if not already updated
PREVIOUS_YARN_VERSION=$(jq -r '.packageManager' package.json | grep -oP "yarn@\K.*")
yarn set version stable
NEW_YARN_VERSION=$(jq -r '.packageManager' package.json | grep -oP "yarn@\K.*")

if [ "$PREVIOUS_YARN_VERSION" == "$NEW_YARN_VERSION" ]; then
  echo -e "Yarn is already configured to use the latest version (${LIGHT_CYAN}'$NEW_YARN_VERSION'${RESET})."
  exit 0;
fi

echo -e "The project is configured to use ${LIGHT_CYAN}'$PREVIOUS_YARN_VERSION'${RESET}. Yarn version has been set to ${LIGHT_CYAN}'$NEW_YARN_VERSION'${RESET}, the latest version."

BRANCH_NAME="yarn-update-$NEW_YARN_VERSION"

# Ensure branch doesn't exist
if git ls-remote --heads origin "$BRANCH_NAME" | grep --quiet "$BRANCH_NAME"; then
  echo -e "${RED}Branch '$BRANCH_NAME' already exists.${RESET}" >&2
  exit 1
fi

# Commit and push changes
git config --global user.name 'github-actions'
git config --global user.email 'github-actions@github.com'

git checkout -b "$BRANCH_NAME"

git add package.json
git commit -m "chore: update Yarn to '$NEW_YARN_VERSION'"
git push -u origin "$BRANCH_NAME"

# Create pull request
gh pr create \
    --title "chore: update Yarn to '$NEW_YARN_VERSION'" \
    --body "This PR updates Yarn to '$NEW_YARN_VERSION', the latest release." \
    --label "$LABEL_NAME"
