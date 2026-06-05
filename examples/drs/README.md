# DRS Deployment Example

POC example deploying [DRS](https://github.com/bento-platform/bento_drs), Bento's Data Repository Service, using the `stateless-svc` Helm chart with a Garage S3 backend.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed
- The Garage S3 example from `examples/garage` must be running with the `drs` bucket and key created (see `examples/garage/README.md`)

## Deploy

```bash
helm install drs ./charts/stateless-svc -f examples/drs/values.yaml
```

Wait for the pod to be ready:

```bash
kubectl get pods -w
```

## Test

```bash
# Port-forward to access the service locally
kubectl port-forward deployment/drs-stateless-svc 5000:5000

# Check the service-info endpoint
curl http://localhost:5000/service-info
```

## Teardown

```bash
helm uninstall drs
```

## Notes

- DRS is configured for S3-only storage in this example. The `DATA` env var (used for local filesystem object storage) is intentionally omitted.
- Two `emptyDir` volumes are mounted for the SQLite database (`/drs/bento_drs/data/db/`) and ingest temporary files (`/drs/tmp`). These are ephemeral and data is lost on pod restart. For production, replace with PersistentVolumeClaims.
- S3 credentials are sourced from the `drs-key` Secret created automatically by the garage-operator when the `drs-key` GarageKey resource is applied.
- `AUTHZ_ENABLED` is set to `False` and dummy values are provided for `BENTO_AUTHZ_SERVICE_URL`, `SERVICE_URL_BASE_PATH`, and `OPENID_CONFIG_URL` to allow DRS to start without a full Bento auth stack.
- Probe headers include `Host: localhost` because the service rejects the pod IP that Kubernetes uses by default for health checks.