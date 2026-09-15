#!/bin/bash
set -euo pipefail

LIGHT_CYAN='\033[0;36m'
RESET='\033[0m' # No Color

# Refuse a working directory that resolves outside the checked out repository
WORKSPACE_PATH=$(realpath "$GITHUB_WORKSPACE")
SEARCH_ROOT=$(realpath .)
if [[ "$SEARCH_ROOT" != "$WORKSPACE_PATH" && "$SEARCH_ROOT" != "$WORKSPACE_PATH"/* ]]; then
  echo "The working directory must reside inside the repository." >&2
  exit 1
fi

# Find every 'package.json' that declares Yarn as its package manager
YARN_PACKAGE_JSON_FILES=()
while IFS= read -r -d '' PACKAGE_JSON_FILE; do
  if jq -e -r '(.packageManager // "") | startswith("yarn@")' "$PACKAGE_JSON_FILE" > /dev/null; then
    YARN_PACKAGE_JSON_FILES+=("$PACKAGE_JSON_FILE")
  fi
done < <(find . -type f -name package.json -not -path '*/node_modules/*' -not -path '*/.yarn/*' -print0 | sort --zero-terminated)

if [ ${#YARN_PACKAGE_JSON_FILES[@]} -eq 0 ]; then
  echo "No 'package.json' declaring Yarn as its package manager was found." >&2
  exit 1
fi

NEW_YARN_VERSION=""
UPDATED_PACKAGE_JSON_PATHS=()

for PACKAGE_JSON_FILE in "${YARN_PACKAGE_JSON_FILES[@]}"; do
  PACKAGE_JSON_PATH=$(realpath --relative-to="$WORKSPACE_PATH" "$PACKAGE_JSON_FILE")
  PACKAGE_DIRECTORY=$(dirname "$PACKAGE_JSON_FILE")

  # Update Yarn if not already updated
  PREVIOUS_VERSION=$(jq -r '.packageManager' "$PACKAGE_JSON_FILE" | grep -oP "yarn@\K.*")
  (cd "$PACKAGE_DIRECTORY" && yarn set version stable)
  CURRENT_VERSION=$(jq -r '.packageManager' "$PACKAGE_JSON_FILE" | grep -oP "yarn@\K.*")

  # Both values reach step outputs, branch names and API paths, so reject anything unexpected
  if ! [[ "$CURRENT_VERSION" =~ ^[A-Za-z0-9.+-]+$ ]]; then
    echo "Unexpected Yarn version format: '$CURRENT_VERSION'." >&2
    exit 1
  fi
  if ! [[ "$PACKAGE_JSON_PATH" =~ ^[A-Za-z0-9@._/-]+$ ]]; then
    echo "Unexpected 'package.json' path: '$PACKAGE_JSON_PATH'." >&2
    exit 1
  fi

  if [ -n "$NEW_YARN_VERSION" ] && [ "$NEW_YARN_VERSION" != "$CURRENT_VERSION" ]; then
    echo "Inconsistent Yarn versions across 'package.json' files: '$NEW_YARN_VERSION' and '$CURRENT_VERSION'." >&2
    exit 1
  fi
  NEW_YARN_VERSION="$CURRENT_VERSION"

  if [ "$PREVIOUS_VERSION" == "$CURRENT_VERSION" ]; then
    echo -e "${LIGHT_CYAN}'$PACKAGE_JSON_PATH'${RESET} is already configured to use the latest version (${LIGHT_CYAN}'$CURRENT_VERSION'${RESET})."
    continue
  fi

  echo -e "${LIGHT_CYAN}'$PACKAGE_JSON_PATH'${RESET} is configured to use ${LIGHT_CYAN}'$PREVIOUS_VERSION'${RESET}. Yarn version has been set to ${LIGHT_CYAN}'$CURRENT_VERSION'${RESET}, the latest version."
  UPDATED_PACKAGE_JSON_PATHS+=("$PACKAGE_JSON_PATH")
done

if [ ${#UPDATED_PACKAGE_JSON_PATHS[@]} -eq 0 ]; then
  echo -e "All 'package.json' files are already configured to use the latest Yarn version (${LIGHT_CYAN}'$NEW_YARN_VERSION'${RESET})."
  exit 0
fi

echo "NEW_YARN_VERSION=$NEW_YARN_VERSION" >> "$GITHUB_OUTPUT"
{
  echo "PACKAGE_JSON_PATHS<<PACKAGE_JSON_PATHS_EOF"
  printf '%s\n' "${UPDATED_PACKAGE_JSON_PATHS[@]}"
  echo "PACKAGE_JSON_PATHS_EOF"
} >> "$GITHUB_OUTPUT"
