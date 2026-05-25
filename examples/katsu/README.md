# Katsu Deployment Example

POC example deploying [Katsu](https://github.com/bento-platform/katsu), Bento's clinical and phenotypic metadata service, using the `stateless-svc` Helm chart with a CNPG-managed PostgreSQL database.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed

## Setup

### Install the CNPG operator

```bash
helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
helm repo update
helm install cnpg cloudnative-pg/cloudnative-pg --namespace cnpg-system --create-namespace
```

Wait for the operator to be ready:

```bash
kubectl get pods -n cnpg-system -w
```

## Deploy

```bash
# Deploy the PostgreSQL cluster
kubectl apply -f examples/katsu/katsu-db.yaml

# Wait for the cluster to be healthy
kubectl get cluster katsu-db -w

# Deploy Katsu
helm install -f examples/katsu/values.yaml katsu ./charts/stateless-svc
```

## Test

```bash
# Port-forward to access the service locally
kubectl port-forward deployments/katsu-stateless-svc 5000:8000

# Visit http://localhost:5000/service-info in a browser or:
curl http://localhost:5000/service-info
```

## Teardown

```bash
helm uninstall katsu
kubectl delete -f examples/katsu/katsu-db.yaml
kubectl delete pvc katsu-db-1
```

## Notes

- Katsu requires PostGIS, which is not included in the standard CNPG Postgres image. The `katsu-db.yaml` manifest uses `ghcr.io/cloudnative-pg/postgis` instead.
- `enableSuperuserAccess: true` is set in `katsu-db.yaml` because Katsu's Django migrations need superuser privileges to install the PostGIS extension on first run. This is a known limitation for local development — a production setup should pre-create the extension via CNPG bootstrap SQL instead.
- Katsu runs on port 8000 internally, so port-forwarding uses `5000:8000`.
- Probe headers include `Host: localhost` because Django's `ALLOWED_HOSTS` setting rejects the pod IP that Kubernetes uses by default for health checks.