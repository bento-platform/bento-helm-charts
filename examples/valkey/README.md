# Valkey

Deploys a standalone [Valkey](https://valkey.io/) instance using the [official Valkey Helm chart](https://github.com/valkey-io/valkey-helm).

Valkey is used as a message broker and job queue by the following Bento services:

- WES
- Notification
- Event-Relay

## Prerequisites

- A running Kubernetes cluster (e.g. minikube, kind)
- `kubectl` configured to point at it
- `helm` installed

## Deploy

Add the Valkey Helm repository:

```bash
helm repo add valkey https://valkey-io.github.io/valkey-helm
helm repo update
```

Install the chart:

```bash
helm install valkey valkey/valkey \
  --namespace valkey \
  --create-namespace \
  -f values.yaml
```

Wait for the pod to be ready:

```bash
kubectl get pods -n valkey -w
```

## Verify

Once the pod is `Running`, confirm Valkey is responding:

```bash
kubectl exec -n valkey \
  $(kubectl get pod -n valkey -l app.kubernetes.io/name=valkey -o jsonpath='{.items[0].metadata.name}') \
  -c valkey -- valkey-cli ping
```

Expected output:

```
PONG
```

## In-cluster service address

Other services in the cluster can reach Valkey at:

```
valkey.valkey.svc.cluster.local:6379
```

## Teardown

```bash
helm uninstall valkey -n valkey
kubectl delete namespace valkey
```