# Bento layers in ArgoCD

For a streamlined and declarative provisioning of Bento stacks in k8s, ArgoCD Applications are deployed 
in ordered "layers":
1. **Infra:** Core dependencies (Operators, CRDs)
2. **Platform:** Platform resources that Bento services depend on (PostgreSQL DBs, S3 buckets, HTTPRoutes, etc)
3. **Services:** Bento services (Katsu, Beacon, web apps, etc)

This document covers how this is defined in ArgoCD.

## Infra

The `infra` layer is deployed as an ArgoCD App-of-apps, a common ArgoCD pattern where a root Application manages a 
number of child Applications. It is a convenient way of managing Helm releases for various charts with ArgoCD.

The root application is defined in [argocd/infra.yaml](../argocd/infra.yaml).

This application points to the Git repo at the path [deployment/infra/](../deployment/infra/), 
which itself contains ArgoCD Applications for Helm charts.

To add a new `Application` to the infra App-of-apps, you simply have to 
1. Add a new `Application` manifest file under [deployment/infra/](../deployment/infra/)
2. Add it to the `kustomization.yaml` resources in the same directory.
3. Commit, push and merge into `main`

On its next sync cycle, ArgoCD will detect that a new application is defined in Git and will attempt 
to deploy it in k8s.

This layer is mostly responsible for installing required k8s operators that are needed later, namely:
- Cert-Manager
- Cloud Native PostgreSQL operator (CNPG)
- Garage operator
- Keycloak operator

## Platform

The `platform` layer is deployed as an ArgoCD `ApplicationSet`, a powerful ArgoCD pattern that generates Applications 
based on templates and Git repo structures.

The platform `ApplicationSet` is defined in [argocd/platform.yaml](../argocd/platform.yaml).

The `ApplicationSet` will generate one (1) ArgoCD Application for every directory in Git at the 
path [deployment/platform/](../deployment/platform/).

While the `infra` layer relies heavily on Helm, the resources that are installed in the `platform` layer are 
generally raw k8s manifests.

Therefore, we recommend using Kustomize in the `platform` layer. 

To add an application to the platform layer:
1. Create a new directory, e.g. `deployment/platform/my-app`
2. Create a `kustomization.yaml` file at `deployment/platform/my-app/kustomization.yaml`
3. Add resources to `kustomization.yaml`
4. (Optional) Add patches, labels, annotations to `kustomization.yaml`
5. Commit, push and merge into `main`

On its next cycle, ArgoCD will detect that a new application is defined in Git and will attempt to deploy it in k8s.

This layer is responsible for installing in-cluster services that Bento services depend on, these platform services 
often depend on operators and CRDs that are installed in the `infra` layer.
- Cert-Manager root CA for TLS
- Gateway API HTTPRoutes to expose services
- CNPG databases
- Garage cluster, buckets (S3)
- Keycloak instance

## Services

Finaly, when the `infra` and `platform` layers are fully synced and healthy in ArgoCD, the `services` layer can be deployed.

The `services` layer consists of the Bento core services: Katsu, Beacon, Public, Portal, Authz, WES, DRS, etc.

This layer is deployed using an ArgoCD `ApplicationSet` that is configured to turn every 
match for `deployment/services/*/values.yaml` into one `Application` for the Helm chart `stateless-svc`.

Since all Bento services have to be deployable with the Bento Helm Chart `stateless-svc`, this offers a streamlined and 
declarative way of configuring all Bento serices for GitOps.

To add an application to the `services` layer:
1. Create a new directory with the service's name, e.g. `deployment/services/etl` for `etl`
2. Create a `values.yaml` for the service in the directory, based on the `stateless-svc` Chart's 
   [values](https://github.com/bento-platform/bento-helm-charts/blob/main/charts/stateless-svc/values.yaml)
3. Commit, push and merge into `main`

On its next cycle, ArgoCD will detect that a new application is defined in Git and will attempt to deploy it in k8s.
