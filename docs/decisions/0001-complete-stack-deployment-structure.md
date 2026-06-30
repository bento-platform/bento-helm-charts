# Bento GitOps deployment structure

## Context and Problem Statement

We are currently in the process of porting Bento to be deployable on Kubernetes clusters.
The development of generic Helm Charts in this repo makes it possible to deploy the core 
Bento services as Helm releases. Tackling an important part of the problem.

### Services dependencies

Bento also depends on open-source services, like PostreSQL DBs, Keycloak, and Redis clusters.
These services have to be configured and deployed BEFORE core Bento services.

### Networking

Furthermore, in a k8s context, it is prefered to avoid using [bento_gateway](https://github.com/bento-platform/bento_gateway), 
since Kubernetes network abstractions (Services, Gateway API, CNI security rules) can do everything that `bento_gateway` does and more, 
without needing to maintain our own network abstraction.

### GitOps

In a production context, we should leverage the Continuous Delivery (CD) features that k8s offers to streamline delivery with Git 
as the source of truth (GitOps). For this we will only consider ArgoCD at the moment, since it is a mature solution and already 
adopted as the GitOps provider for PCGL.

The GitOps structure has to be composable in layers for the different roles in production k8s environment:
- Infrastructure providers
  - Provides clusters
  - Network configuration
  - Cloud configuration (Openstack resources usage)
  - DNS
- Cluster/platform operators
  - Administers clusters for developers
  - Bootstrap GitOps for dev team
  - Provide in-cluster dependencies needed by dev team (k8s Operators, databases, etc)
- Application developers
  - Manage Bento deployments in k8s via Git

> [!NOTE]
> In a local dev context, the developer fulfils all of these roles. Giving them exposure to k8s administration.
> 
> In a production context, Bento developers are only concerned with the Bento core services.

### Developer experience and learning environment

Finally, the Bento team is new to working with Kubernetes and GitOps.

Given the steep learning curve of Kubernetes, the full solution should be deployable for local development, 
so that Bento developers can familiarise themselves with Kubernetes concepts, ArgoCD and GitOps principles. 

This provides developers with an environment for hands-on practice in a setup that is closely aligned with production deployments.

## Decision Drivers

- Solution has to support composable layers
  - Infra: Operators, cluster dependencies
  - Platform: Databases, auth system, North-South traffic, TLS, policies
  - Services: Bento core services (Katsu, Beacon, DRS, WES, etc)
- Solution has to be deployable in full in a local k8s cluster for developers
  - ArgoCD bootstrap
  - Gateway API setup with TLS
  - All 3 layers
- Solution has to be deployable for a production setup:
  - Infra and platform layers handled by infra/platform team
  - Bento dev team manages the Bento services layer only
- Solution should leverage native k8s deployment tools that integrate well with GitOps tools
  - Helm Charts
  - Kustomize
  - Raw k8s manifests

## Considered Options

The options considered revolve around the different ArgoCD patterns, and which one fits best for a given layer.

* Infra: (Cert-Manager, CNPG Operator, Keycloak Operator)
  * App-of-apps
  * ApplicationSet
  * Single app with raw manifests
* Platform
  * App-of-apps
  * ApplicationSet
  * Single app with raw manifests
* Services
  * App-of-apps
  * ApplicationSet
  * Single app with raw manifests

## Decision Outcome

### Infra

**Decision:** App-of-apps pattern

The App-of-Apps pattern has been chosen for the Infra layer.

Given that this layer only uses Helm Charts from various third party repos, the App-of-Apps pattern offers 
the simplest way to define the Helm Releases. Adding new dependencies is a simple process to understand.
For learning purposes, this also exposes Bento developers with the simplest ArgoCD primitive (`Applications`), 
without the added complexity of `ApplicationSet`.

`ApplicationSets` are too complex to justify using them in this context.

Raw manifests are not well suited for Helm Charts management here, and would require an extra manifest rendering step.

### Platform

**Decision:** `ApplicationSet` with Git directory generator

The platform layer is mostly responsible for installing raw k8s manifests for k8s primitives and Custom Resources for Operators, 
no Helm charts are used in this layer.

A single `ApplicationSet` with a Git directory generator can handle this elegantly when paired with Kustomize.
Given a Git Generator pointing to the path `/deployment/platform/*`, every directory under it containing Kustomize manifests will be 
generated as an ArgoCD `Application`. Kustomize also empowers us to apply patches on manifests when necessary.

The App-of-apps pattern would require us to write a new `Application` resource pointing to manifests, while an `ApplicationSet` only 
needs a manifests directory to work.

Raw manifests would work too here, but it is better to use Kustomize to support patches. `ApplicationSets` with a Git directory 
generator offer more features with little overhead and better automation and visibility.

### Services

**Decision:** `ApplicationSet` with Git file generator

`ApplicationSet` is the clear winner here, it is easy to template multiple Applications when they all rely on the same Helm Chart.

This layer has some particularities:
- All services are deployed with the Bento Helm chart `stateless-svc`
- Each service needs to define its own Helm values
- We may want to update the Katsu Helm Chart version alone, without updating all the other charts

The 2 first are easily handled with an `ApplicationSet`, but the last one requires more considerations.
When it comes to the `stateless-svc` Chart version, there are 2 options:
- **Git directory generator:** every service uses the same Helm Chart version (templated in the `ApplicationSet`)
- **Git file generator:** services can use different versions of helm charts by relying on a config file

The Git file generator has a clear flexibility advantage in this specific case.

With a Git Generator for the path `deployment/services/*/.argocd-app.yaml`, we can define a specific Helm Chart name, repo, 
and version for `Katsu` with `deployment/services/katsu/.argocd-app.yaml`:
```yaml
chart:
  name: stateless-svc
  repoURL: https://bento-platform.github.io/bento-helm-charts
  version: 0.5.0
```

In the same directory, the Helm Values for the chart can be provided and used by the `ApplicationSet` to template the 
`Application` for the Helm release. For instance the values for `Katsu` at `deployment/services/katsu/values.yaml`:
```yaml
image:
  repository: ghcr.io/bento-platform/katsu
  tag: "13.2.0"

service:
  port: 8000

# Rest of Helm values
```

This solution offers the most flexibility with minimal overhead, a single ApplicationSet definition can handle the deployment of 
all Bento core services. Furthermore, this solution can expand beyond our own stateless-svc Helm chart, keeping the door open for 
optional services that may depend on other Helm Charts.

The App-of-apps pattern would be a good alternative here, but it would require us to write and maintain more ArgoCD `Application` 
manifests than using `ApplicationSets`.

Raw manifests are not suitable here since we are using Helm charts. Helm charts could be rendered as manifests, 
but this adds an extra rendering step (ArgoCD already renders Helm Charts as manifests under the hood).

### Consequences

> [!NOTE]
> To be evaluated once feedback from developers and production deployments is gathered.
