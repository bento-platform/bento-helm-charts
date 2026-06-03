# Drop Box Deployment Example

POC example deploying [Drop Box](https://github.com/bento-platform/bento_drop_box_service), Bento's file drop box service, using the `stateless-svc` Helm chart with a Garage S3 backend.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed
- The Garage S3 example from `examples/garage` must be running (see `examples/garage/README.md`)

## Setup

### Copy the Drop Box S3 key to the default namespace

The `drop-box-key` secret is created by the Garage operator in the `garage-operator-system` namespace. Copy it to the default namespace so the drop-box pod can access it:

```bash
kubectl create secret generic drop-box-key \
  --from-literal=access-key-id=$(kubectl get secret drop-box-key -n garage-operator-system -o jsonpath='{.data.access-key-id}' | base64 -d) \
  --from-literal=secret-access-key=$(kubectl get secret drop-box-key -n garage-operator-system -o jsonpath='{.data.secret-access-key}' | base64 -d)
```

## Deploy

```bash
helm install drop-box ./charts/stateless-svc -f examples/drop-box/values.yaml
```

Wait for the pod to be ready:

```bash
kubectl get pods -w
```

## Test

```bash
# Port-forward to access the service locally
kubectl port-forward deployment/drop-box-stateless-svc 8080:5000

# Visit http://localhost:8080/service-info in a browser or:
curl http://localhost:8080/service-info
```

## Teardown

```bash
helm uninstall drop-box
kubectl delete secret drop-box-key
```

## Notes

- Drop Box supports both local filesystem and S3 storage. This example uses S3 only via the local Garage cluster.
- The `drop-box-key` secret must be manually copied from `garage-operator-system` to `default` because Kubernetes secrets are namespace-scoped and the Garage operator creates them in its own namespace.
- Probe headers include `Host: localhost` because uvicorn rejects health checks where the pod IP is sent as the Host header.