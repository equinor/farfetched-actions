# Farfetched Actions
This repository contains reusable GitHub Actions and Workflows.
Although developed for the Farfetche'd team, there is no restrictions in the actions to not be used by other teams.

## Workflows
### Fusion Deploy
This workflow deploys the created artifact(s) in a workflow to the given Fusion Portal environment. It deploys "on behalf of" a Azure ServicePrincipal with Federated Credentials.
The workflow will login into Azure using the given ServicePrincipal, obtain a Token to use against the given resource and then upload the artifact(s) to the Portal using the token.

_Parameters:_
* **fusion-portal-url** (mandatory)
URL to the Portal where the artifact should be deployed.
* **app-key** (mandatory)
The AppKey (name of the package), as used within the Fusion Portal.
* **artifact-path** (mandatory)
The "local" path (with filename) to the artifact to be uploaded to Fusion.
* **publish** (optional)
Set if the artifact should immediately be published in the Portal or not. Default true.
* **azure-tenant-id**
The Azure Tenant ID of the ServicePrincipal (Application registration) which is setup with the proper Federated Credentials.
* **azure-client-id**
The Client ID of the ServicePrincipal.
* **azure-resource-id**
The Resource Group ID where the artifact should be deployed to.

Example (`deploy` here is a _job_ in a GitHub workflow)
```
    deploy:
        name: "🚀 Deploy to Fusion Portal"
        runs-on: ubuntu-latest
        needs: build
        steps:
            - name: "Download artifact"
              uses: actions/download-artifact@v2
              with:
                  name: theNameOfTheArtifactThatWasUploaded.zip

            - name: Deploy to Fusion Portal
              uses: equinor/farfetched-actions/fusion-deploy@v1.0
              with:
                  fusion-portal-url: ${{ secrets.FUSION_PORTAL_URL }}
                  app-key: ${{ env.FUSION_APP_KEY }}
                  artifact-path: theNameOfTheArtifactThatWasUploaded.zip
                  azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
                  azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
                  azure-resource-id: ${{ secrets.AZURE_RESOURCE_ID }}
```

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