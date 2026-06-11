# Notification Deployment Example

POC example deploying the [Bento Notification Service](https://github.com/bento-platform/bento_notification_service), Bento's platform notification service, using the `stateless-svc` Helm chart with a Valkey backend for pub/sub and a persistent SQLite database.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed
- A running Valkey cluster (see `examples/valkey/README.md`)

## Deploy

```bash
helm install notification charts/stateless-svc -f examples/notifications/values.yaml
kubectl get pods --watch
```

## Test

```bash
kubectl port-forward svc/notification-stateless-svc 5000:5000
curl http://localhost:5000/service-info
```

## Teardown

```bash
helm uninstall notification
```

## Notes

- `BENTO_AUTHZ_ENABLED` is set to `False` for this standalone example. In a real deployment this would be `True` with `BENTO_AUTHZ_SERVICE_URL` pointing to a live authz instance.
- The service stores a SQLite database under `/notification/data`. A PersistentVolumeClaim is used to ensure data survives pod restarts.
- `REDIS_HOST` points to `valkey-primary`, the in-cluster Valkey primary service, which the notification service uses for event pub/sub.