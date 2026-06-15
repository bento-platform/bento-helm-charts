# WES Deployment Example

POC example deploying [WES](https://github.com/bento-platform/bento_wes), Bento's workflow execution service, using the `stateless-svc` Helm chart.

WES runs ingestion workflows and depends on a Valkey instance for Celery task queuing and event pub/sub. This example deploys a standalone WES server, assuming Drop-Box, DRS, and Katsu are deployed elsewhere.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed
- Valkey deployed in the `default` namespace (see `examples/valkey/README.md`)

## Deploy

```bash
helm install wes charts/stateless-svc -f examples/wes/values.yaml
```

Wait for the pod to be ready:

```bash
kubectl get pods -w
```

## Test

```bash
kubectl port-forward deployment/wes-stateless-svc 5000:5000
```

```bash
curl http://localhost:5000/service-info
```

## Teardown

```bash
helm uninstall wes
```

## Notes

- `BENTO_AUTHZ_ENABLED=False` disables authorization checks. This is for development only and should not be used in production.
- Probes include a `Host: localhost` header because uvicorn rejects health checks where the pod IP is sent as the Host header by kubelet.