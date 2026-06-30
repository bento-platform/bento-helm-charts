# Deploying Bento with GitOps

The Bento stack and its dependencies can be bootstrapped in a k8s cluster using GitOps principles with ArgoCD.

The ArgoCD GitOps setup can be used for local dev, and for production deployments in real clusters, enabling us to 
work on the stack locally and to test it end-to-end in CI pipelines (TODO).

## Prerequisites

For running locally, you must have the following installed on your machine:
- [Kind CLI](https://kind.sigs.k8s.io/)
  - Creates a local k8s cluster in a Docker container
- [Cloud-provider kind CLI](https://github.com/kubernetes-sigs/cloud-provider-kind)
  - Enables services of type LoadBalancer and Gateway API features for the Kind cluster
- Kubectl CLI: used to bootstrap the stack

For production setups:
- A real Kubernetes cluster
- Kubectl CLI: used to bootstrap the stack

## Create local k8s cluster

> [!NOTE]
> For local dev only.
>
> For prod, use a production cluster provided by SD4H.

Use the convenience script to create a Kind cluster with the Cloud-Provider-Kind:
```bash
./scripts/kind-cluster-init.bash
```
## Install ArgoCD

> [!NOTE]
> For local dev only.
>
> For prod, ArgoCD is generally included as a cluster addon by the infra team or cluster operator.

Use the convenience script to install ArgoCD in the cluster:
```bash
cd scripts
./argocd-bootstrap.bash
```

Wait for the deployment to be healthy before proceeding:
```bash
kubectl rollout status -n argocd deployment argocd-server
```

## Bootstrap the infrastructure layer

This step creates the ArgoCD Application that is responsible for bootstrapping the infrastructure layer.

This layer consists of core dependencies and operators, such as:
- CNPG Operator
- Garage Operator
- Cert-Manager
- Keycloak Operator

These are installed using the [App-of-apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative).


Use `kubectl` to create the infra App-of-apps:
```bash
kubectl apply -f argocd/infra.yaml
```

Wait for the generated applications to be synced and healthy:
```bash
kubectl get applications -n argocd
```

## Bootstrap the platform layer

This step bootstraps resources that depend on the infra layer and are needed by applications later.

Among other things, it is responsible for creating: 
- Root Certificate Authority for local HTTPS and end-to-end tests
- Gateway API resources to expose services
- ... more to be added

Use `kubectl` to create the platform layer:
```bash
kubectl apply -f argocd/platform.yaml
```

After a few seconds, verify that all ArgoCD Applications are synced and healthy:
```bash
kubectl get applications -A
```

## Set local hosts resolving

The previous step creates a Gateway that enables routing host requests to k8s services with HTTPS.

For HTTPS to work, you have to configure the hosts to resolve to the Gateway's IP.

A convenience script is available for this purpose:
```bash
./scripts/set-gateway-ip.bash
```

It will output the entries you have to add to your `/etc/hosts` file:
```
Local k8s Gateway exposed on <GATEWAY IP> .

Serving HTTPS on port 443.

Add the following entries to your /etc/hosts file:

<GATEWAY IP>    argocd.bento.k8s.local
<GATEWAY IP>    portal.bento.k8s.local
<GATEWAY IP>    auth.bento.k8s.local
<GATEWAY IP>    public.bento.k8s.local
<GATEWAY IP>    garage.bento.k8s.local
<GATEWAY IP>    cbioportal.bento.k8s.local
```

Test that the ArgoCD route is resolvable:
```bash
curl -k https://argocd.bento.k8s.local
```

> [!NOTE]
> The `-k` flag is to skip TLS validation, it is required at this point because the 
> certificate's root CA is not trusted yet.


> [!IMPORTANT]
> For **Linux** users, if you run into a `Connection refused` error when attempting to reach the hostname (`<GATEWAY IP>:443`), 
> it is likely because of firewall rules preventing IP forwarding to the Docker subnet.
>
> To resolve this, run the following helper script to temporarily disable firewall rules:
> ```bash
> ./scripts/firewall-accept-forward.bash
> ```
>
> The gateway requests should now work.

> [!WARNING]
> For **Windows** and **MacOS** users, Cloud-Provider-Kind should create the Gateway container with an extra port mapping.
>
> This port is mapped to port 443 on the Gateway to enable HTTPS routing.
>
> If you are a **MacOS** or **Windows** user, take note of this port, it is in the script's output.
>
> It will need to be included in HTTPS URLs for networking to work: `https://<domain>:<mapped port>`
>
> For instance, ArgoCD should be accessible at `https://argocd.bento.k8s.local:<mapped port>`

## Export and trust root CA for HTTPS

All TLS certs are issued from a self-signed root CA with Cert-Manager.

This is advantageous for local dev and end-to-end testing since we can trust the root CA once to make all 
the issued certs for the subdomains trusted implicitly. As opposed to having to trust every single TLS certificate.

Run the convenience script to:
- Export the root CA to `/tmp/dev-ca.crt`
- Add the certificate to the list of CAs

```bash
./scripts/trust-root-ca.bash
```

Test that the ArgoCD route is resolvable, **WITHOUT** the `-k` flag:
```bash
# Returns HTML
curl https://argocd.bento.k8s.local
```

> [!NOTE]
> CA trust does not propagate to most browsers automatically, you must go in your browser's security settings 
> and import the root CA file.
>
> Afterwards your browser should implicitly trust TLS certs for the whole stack.

## Validate Gateway API networking

The `platform` layer deploys a `Gateway` resource, which enables external traffic to be routed to 
in-cluster services.

With Kind and [Cloud-Provider-Kind](https://github.com/kubernetes-sigs/cloud-provider-kind#mac-windows-and-wsl2-support) as the 
local Kubernetes cluster, the Gateway is created as a Docker container.

Check that a Docker container with the name starting with `kindccm-gw` exists:
```bash
docker ps
```

This container is created and managed by Cloud-Provider-Kind as soon as the `Gateway` resource is created, providing 
a network path from the host machine to k8s services exposed with an `HTTPRoute`.




## Explore the stack in the ArgoCD UI

Since the Bento stack is provisionned by ArgoCD, you can use the ArgoCD UI to inspect all the resources that have 
been created.

This is an helpful playground to familiarize yourself with Kubernetes concepts like Deployments, Pods, Services, etc.

To connect to ArgoCD, you must use the `admin` username and the password that is generated automatically.

Use the convenience script to obtain the password:
```bash
./scripts/argocd-admin-pw.bash
```

Open https://argocd.bento.k8s.local in a browser and enter the credentials.

You should see the ArgoCD applications that manage the Bento stack!
