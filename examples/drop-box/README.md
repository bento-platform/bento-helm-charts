# Drop Box Deployment Example

POC example deploying [Drop Box](https://github.com/bento-platform/bento_drop_box_service), Bento's file drop box service, using the `stateless-svc` Helm chart with a Garage S3 backend.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed
- The Garage S3 example from `examples/garage` must be running (see `examples/garage/README.md`)

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

# Check the service-info endpoint
curl http://localhost:8080/service-info
```

To test the S3 connection, upload a file to the drop-box bucket and verify it appears via the `/tree` endpoint:

In a separate terminal, port-forward the Garage S3 endpoint:

```bash
kubectl port-forward svc/garage 3900:3900
```

Then set S3 credentials and upload a file:

```bash
export AWS_DEFAULT_REGION=garage
export AWS_ACCESS_KEY_ID=$(kubectl get secret drop-box-key \
  -o jsonpath='{.data.access-key-id}' | base64 -d)
export AWS_SECRET_ACCESS_KEY=$(kubectl get secret drop-box-key \
  -o jsonpath='{.data.secret-access-key}' | base64 -d)

# Upload a file to the drop-box S3 bucket
aws s3 cp --endpoint-url http://localhost:3900 README.md s3://drop-box

# Verify it was uploaded
aws s3 ls --endpoint-url http://localhost:3900 s3://drop-box
```

Then visit http://localhost:8080/tree — with `BENTO_AUTHZ_ENABLED=false`, the uploaded file should be listed.

## Teardown

```bash
helm uninstall drop-box
```

## Notes

- Drop Box supports both local filesystem and S3 storage. This example uses S3 only via the local Garage cluster.
- Probe headers include `Host: localhost` because uvicorn rejects health checks where the pod IP is sent as the Host header.