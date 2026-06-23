# Event Relay Deployment Example

This example deploys the [Bento Event Relay](https://github.com/bento-platform/bento_event_relay) service using the `stateless-svc` Helm chart.

The Event Relay subscribes to Redis (Valkey) PubSub events and relays them to front-end clients over Socket.IO. It has no database and no persistent storage.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube or kind)
- The `stateless-svc` Helm chart available locally (`charts/stateless-svc`)
- A Valkey deployment running in the `default` namespace (see `examples/valkey`), reachable at `valkey.default.svc.cluster.local:6379`

## Deploy

From the root of the repo:

```bash
helm install event-relay charts/stateless-svc -f examples/event-relay/values.yaml
```

Check that the pod comes up healthy:

```bash
kubectl get pods -l app.kubernetes.io/instance=event-relay
kubectl logs -l app.kubernetes.io/instance=event-relay
```

You should see the service log its config on startup and report:

```
bento_event_relay listening on 5000
```

## Testing

1. Port-forward the service:

   ```bash
   kubectl port-forward svc/event-relay-stateless-svc 5000:5000
   ```

2. Check the service info endpoint:

   ```bash
   curl http://localhost:5000/service-info
   ```

   This should return a JSON response describing the `bento_event_relay` service, confirming the pod is healthy and serving traffic.

## Teardown

```bash
helm uninstall event-relay
```