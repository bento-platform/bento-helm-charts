# Reference Deployment Example

POC example deploying the [Bento Reference Service](https://github.com/bento-platform/bento_reference_service), Bento's reference genome and annotation service, using the `stateless-svc` Helm chart with a CNPG-managed PostgreSQL database.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed
- The [CloudNativePG operator](https://cloudnative-pg.io/) installed in the cluster

## Deploy

Apply the database manifest and wait for the cluster to be ready:

```bash
kubectl apply -f examples/reference/db.yaml
kubectl get cluster reference-db --watch
```

Wait until the status shows `Cluster in healthy state`, then deploy the service:

```bash
helm install reference charts/stateless-svc -f examples/reference/values.yaml
kubectl get pods --watch
```

## Test

```bash
kubectl port-forward svc/reference-stateless-svc 5000:5000
```

Check the service info endpoint:

```bash
curl http://localhost:5000/service-info
```

Or open the Swagger UI in your browser at `http://localhost:5000/docs`.

## Teardown

```bash
helm uninstall reference
kubectl delete -f examples/reference/db.yaml
```

## Notes

- `BENTO_AUTHZ_ENABLED` is set to `False` for this standalone example. In a real deployment this would be `True` with `BENTO_AUTHZ_SERVICE_URL` pointing to a live authz instance.
- An EmptyDir volume is mounted at `/reference/tmp` for temporary storage during genome file ingestion. This data does not persist across pod restarts.
- Probes include a `Host: localhost` header because the service runs on uvicorn, which rejects requests where the kubelet sends the pod IP as the Host header.