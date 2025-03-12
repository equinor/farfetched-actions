[![SCM Compliance](https://scm-compliance-api.radix.equinor.com/repos/equinor/farfetched-actions/badge)](https://scm-compliance-api.radix.equinor.com/repos/equinor/farfetched-actions/badge)

# Farfetched Actions
This repository contains reusable GitHub Actions and Workflows.

Although originally developed for the Equinor Farfetch'd team, there are no restrictions in the actions preventing them from being used by other teams.

## Workflows

### PR name validation
This action validates the PR name in accordance to the Farfetched "rules", which again are based on (Conventional Commit)[https://www.conventionalcommits.org/en/v1.0.0/].
If the name/title of the PR is not in accordance to the Conventional Commit standard (with possible additional restrictions added by the
Farfetched team), the action will "fail".
In case of failure the PR will be labeled with `invalid_PR_name` (default, can be overridden).

_Parameters:_
* **github-token** (mandatory)
The GitHub token, needed for internal `gh` operations (e.g. labeling the PR). Typically obtained through `${{ secrets.GITHUB_TOKEN }}`.
* **failed-pr-label** (optional)
The label to "stamp" on the PR if validation fails. Default: `invalid_PR_name`.


Example
```
name: 🔍️ PR Validation
on:
    pull_request:
        branches:
            - main
        types:
            - opened
            - edited
            - reopened
            - synchronize
    workflow_dispatch:

jobs:
    lint-pr-name:
        name: Lint pull request title
        runs-on: ubuntu-latest
        steps:
            - name: Validate name
              uses: equinor/farfetched-actions/pr-name-validator@v2.0
              with:
                  github-token:  ${{ secrets.GITHUB_TOKEN }}

```
