#!/bin/bash
set -e

LIGHT_CYAN='\033[0;36m'
RESET='\033[0m' # No Color

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
