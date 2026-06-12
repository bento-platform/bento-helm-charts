# Authz Deployment Example

POC example deploying the [Bento Authorization Service](https://github.com/bento-platform/bento_authorization_service), Bento's permissions and authorization service, using the `stateless-svc` Helm chart with a CNPG-managed PostgreSQL database.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed
- The [CloudNativePG operator](https://cloudnative-pg.io/) installed in the cluster

## Deploy

Apply the database manifest and wait for the cluster to be ready:

```bash
kubectl apply -f examples/authz/db.yaml
kubectl get cluster authz-db --watch
```

Wait until the status shows `Cluster in healthy state`, then deploy the service:

```bash
helm install authz charts/stateless-svc -f examples/authz/values.yaml
kubectl get pods --watch
```

## Test

```bash
kubectl port-forward svc/authz-stateless-svc 5000:5000
curl http://localhost:5000/service-info
```

## Teardown

```bash
helm uninstall authz
kubectl delete -f examples/authz/db.yaml
```

## Notes

- The CNPG operator automatically creates a secret named `authz-db-app` containing the database credentials, including a full connection URI. This is referenced directly by the `DATABASE_URI` environment variable.
- `OPENID_CONFIG_URL`, `CORS_ORIGINS`, and `SERVICE_URL_BASE_PATH` are set to dummy values. In a real deployment these would point to a live Keycloak instance and the public-facing gateway URL.
- Probes include a `Host: localhost` header because the service runs on uvicorn, which rejects requests where the kubelet sends the pod IP as the Host header.