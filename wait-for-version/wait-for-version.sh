#!/usr/bin/env bash
#
# wait-for-version.sh
# ===================
#
# This script can be used in Github deployment pipelines to ensure that a specific deployed version has been switched online.
#
# It assumes that the API endpoint returns a JSON string with the following format:
# {
#  "version": "14.0.0.0"
# }
#
# Example usage:
# EXPECTED_VERSION=15.0.0 BASE_URL=http://localhost:5200 ./wait-for-version.sh
#

set -euo pipefail

# Config (can be overridden by env vars from GitHub Action)
BASE_URL="${BASE_URL:-http://localhost}"
EXPECTED_VERSION="${EXPECTED_VERSION:-14.0.0.0}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-3}"
VERSION_PARTS="${VERSION_PARTS:-3}" # how many components of the version string to compare
SLEEP_INTERVAL="${SLEEP_INTERVAL:-1}"

# Normalize expected version (remove optional leading "v", trim parts)
EXPECTED_VERSION=$(echo "$EXPECTED_VERSION" | sed 's/^v//' | cut -d. -f1-"$VERSION_PARTS")
URL="$BASE_URL/version"
attempts=1

while (( attempts <= MAX_ATTEMPTS )); do
    echo "Polling $URL (attempt ${attempts} / ${MAX_ATTEMPTS} )..."

    CURL_OUTPUT=$(curl -s "$URL") || {
        echo "❌ Failed to reach $URL"
        exit 1
    }

    VERSION=$(echo $CURL_OUTPUT | (jq -r '.version' || echo "N/A" ) | cut -d. -f1-$VERSION_PARTS) 
    if [[ "$VERSION" == "N/A" ]]; then
        echo "Response from server: $CURL_OUTPUT"
    fi

    echo "Current version: $VERSION (expected: $EXPECTED_VERSION)"

    if [[ "$VERSION" == "$EXPECTED_VERSION" ]]; then
        echo "✅ Expected version $EXPECTED_VERSION found!"
        exit 0
    fi

    sleep $SLEEP_INTERVAL
    ((attempts+=1))
done

if [[ $attempts -ge $MAX_ATTEMPTS ]]; then
  echo "❌ Timeout reached (${MAX_ATTEMPTS} attempts). Version $EXPECTED_VERSION not found."
fi
exit 1
