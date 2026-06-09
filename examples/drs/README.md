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

Verify the PersistentVolumeClaim was created and bound:

```bash
kubectl get pvc drs-stateless-svc
```

## Test

```bash
# Port-forward to access the service locally
kubectl port-forward deployment/drs-stateless-svc 5000:5000

# Check the service-info endpoint
curl http://localhost:5000/service-info
```

### Persistence

Write test data to the SQLite database:

```bash
kubectl exec -it deploy/drs-stateless-svc -- python3 -c "
import sqlite3, os
os.makedirs('/drs/bento_drs/data/db', exist_ok=True)
conn = sqlite3.connect('/drs/bento_drs/data/db/db.sqlite3')
conn.execute('CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY)')
conn.execute('INSERT INTO test VALUES (1)')
conn.commit()
conn.close()
print('wrote data')
"
```

Restart the deployment:

```bash
kubectl rollout restart deployment/drs-stateless-svc
kubectl rollout status deployment/drs-stateless-svc
```

Verify the data survived the restart:

```bash
kubectl exec -it deploy/drs-stateless-svc -- python3 -c "
import sqlite3
conn = sqlite3.connect('/drs/bento_drs/data/db/db.sqlite3')
print(conn.execute('SELECT * FROM test').fetchall())
conn.close()
"
```

Expected output: `[(1,)]`

## Teardown

```bash
helm uninstall drs
kubectl delete pvc drs-stateless-svc
```

## Notes

- DRS is configured for S3-only storage in this example. The `DATA` env var (used for local filesystem object storage) is intentionally omitted.
- A PersistentVolumeClaim is used for the SQLite database at `/drs/bento_drs/data`. An `emptyDir` volume is still used for ingest temporary files at `/drs/tmp`.
- S3 credentials are sourced from the `drs-key` Secret created automatically by the garage-operator when the `drs-key` GarageKey resource is applied.
- `AUTHZ_ENABLED` is set to `False` and dummy values are provided for `BENTO_AUTHZ_SERVICE_URL`, `SERVICE_URL_BASE_PATH`, and `OPENID_CONFIG_URL` to allow DRS to start without a full Bento auth stack.
- Probe headers include `Host: localhost` because the service rejects the pod IP that Kubernetes uses by default for health checks.