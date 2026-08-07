#!/bin/bash
set -euo pipefail

LIGHT_CYAN='\033[0;36m'
RESET='\033[0m' # No Color

# Refuse a working directory that resolves outside the checked out repository
PACKAGE_JSON_PATH=$(realpath --relative-to="$GITHUB_WORKSPACE" package.json)
if [[ "$PACKAGE_JSON_PATH" == ../* ]]; then
  echo "'package.json' must reside inside the repository." >&2
  exit 1
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

# Both values reach step outputs, branch names and API paths, so reject anything unexpected
if ! [[ "$NEW_YARN_VERSION" =~ ^[A-Za-z0-9.+-]+$ ]]; then
  echo "Unexpected Yarn version format: '$NEW_YARN_VERSION'." >&2
  exit 1
fi
if ! [[ "$PACKAGE_JSON_PATH" =~ ^[A-Za-z0-9@._/-]+$ ]]; then
  echo "Unexpected 'package.json' path: '$PACKAGE_JSON_PATH'." >&2
  exit 1
fi

echo "NEW_YARN_VERSION=$NEW_YARN_VERSION" >> "$GITHUB_OUTPUT"
echo "PACKAGE_JSON_PATH=$PACKAGE_JSON_PATH" >> "$GITHUB_OUTPUT"
