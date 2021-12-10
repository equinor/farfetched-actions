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
* **publish** (optional)
Set if the artifact should immediately be published in the Portal or not. Default true.
* **azure-tenant-id**
The Azure Tenant ID of the ServicePrincipal (Application registration) which is setup with the proper Federated Credentials.
* **azure-client-id**
The Client ID of the ServicePrincipal.
* **azure-resource-id**
The Resource Group ID where the artifact should be deployed to.
