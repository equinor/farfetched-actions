#!/bin/bash
set -euo pipefail

FILES=()
while IFS= read -r PACKAGE_JSON_PATH; do
  [ -n "$PACKAGE_JSON_PATH" ] || continue
  FILES+=("$PACKAGE_JSON_PATH")
done <<< "$PACKAGE_JSON_PATHS"

if [ ${#FILES[@]} -eq 0 ]; then
  echo "No 'package.json' files to commit." >&2
  exit 1
fi

# Build the file additions of the commit
ADDITIONS="[]"
for FILE in "${FILES[@]}"; do
  ADDITIONS=$(jq \
    --arg path "$FILE" \
    --arg contents "$(base64 -w0 -- "$FILE")" \
    '. + [{path: $path, contents: $contents}]' <<< "$ADDITIONS")
done

# Commits created through the API are signed by GitHub
EXPECTED_HEAD_OID=$(gh api "/repos/$REPO/git/ref/heads/$BRANCH" --jq '.object.sha')
QUERY='mutation ($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid } } }'

jq -n \
  --arg query "$QUERY" \
  --arg repo "$REPO" \
  --arg branch "$BRANCH" \
  --arg headline "$COMMIT_MESSAGE" \
  --arg oid "$EXPECTED_HEAD_OID" \
  --argjson additions "$ADDITIONS" \
  '{
    query: $query,
    variables: {
      input: {
        branch: { repositoryNameWithOwner: $repo, branchName: $branch },
        message: { headline: $headline },
        expectedHeadOid: $oid,
        fileChanges: { additions: $additions }
      }
    }
  }' | gh api graphql --input - > /dev/null

echo "Committed ${#FILES[@]} 'package.json' file(s) to '$BRANCH'."
