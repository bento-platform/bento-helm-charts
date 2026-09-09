# WES Deployment Example

POC example deploying [WES](https://github.com/bento-platform/bento_wes), Bento's workflow execution service, using the `litestream-svc` Helm chart.

This Chart differs from `stateless-svc` by:
- Using a `StatefulSet` instead of a `Deployment`, since the service is technicaly stateful
- Automatic continuous SQLite backups to S3
- Automatic recovery of SQLite DB from S3 backups before WES starts

This allows us to run SQLite backed services in k8s with extra protection for data loss, and better deployment automation.

WES runs ingestion workflows and depends on a Valkey instance for Celery task queuing and event pub/sub. This example deploys a standalone WES server, assuming Drop-Box, DRS, and Katsu are deployed elsewhere.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed
- Valkey deployed in the `default` namespace (see `examples/valkey/README.md`)
- Garage cluster deployed

## Deploy

Create the S3 bucket and credentials for Litestream backups:
```bash
kubectl apply -f examples/wes-litestream/wes-bucket.yaml
```

```bash
helm install wes charts/litestream-svc -f examples/wes-litestream/values.yaml
```

Wait for the pod to be ready:

```bash
kubectl get pods -w
```

## Test

```bash
kubectl port-forward statefulsets/wes-litestream-svc 5000:5000
```

```bash
curl http://localhost:5000/service-info
```

## Test persistence

Write some data to a test table:
```bash
kubectl exec wes-litestream-svc-0 -c litestream-svc -- python3 -c "
import sqlite3
c = sqlite3.connect('/wes/data/bento_wes.db')
c.execute('CREATE TABLE IF NOT EXISTS litestream_canary (id INTEGER PRIMARY KEY, note TEXT)')
c.execute('INSERT INTO litestream_canary (note) VALUES (\"before-dr-test\")')
c.commit()
"
```

Check the Litestream logs for a new compaction log:
```bash
kubectl logs wes-litestream-svc-0 -c litestream
```

Fully delete the Helm release, deletes the Pod and its PVC.
```bash
helm uninstall wes
```

Reinstall WES with the same values:
```bash
helm install wes charts/litestream-svc -f examples/wes-litestream/values.yaml
```

If all went well, Litestream should detect that there is no DB file in the fresh PVC, 
the init-container should create this file from the S3 backups before WES starts.

See if the test data we wrote before scraping the Helm release is in the restored DB:
```bash
kubectl exec wes-litestream-svc-0 -c litestream-svc -- python3 -c "
import sqlite3
print(sqlite3.connect('/wes/data/bento_wes.db').execute('SELECT * FROM litestream_canary').fetchall())
"
```

This should print the following:
> [(1, 'before-dr-test')]

## Teardown

```bash
# Delete the Helm release
helm uninstall wes

# Delete the S3 resources
kubectl delete -f examples/wes-litestream/wes-bucket.yaml
```

## Notes

- `BENTO_AUTHZ_ENABLED=False` disables authorization checks. This is for development only and should not be used in production.
- Probes include a `Host: localhost` header because uvicorn rejects health checks where the pod IP is sent as the Host header by kubelet.