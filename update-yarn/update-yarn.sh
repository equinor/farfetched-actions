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

echo "{NEW_YARN_VERSION}={$NEW_YARN_VERSION}" >> "$GITHUB_OUTPUT"
