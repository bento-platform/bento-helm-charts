# bento_public Deployment Example

POC example deploying [bento_public](https://github.com/bento-platform/bento_public), Bento's
public-facing data discovery portal, using the `stateless-svc` Helm chart.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed

## Deploy

```bash
helm install -f examples/public/values.yaml bento-public ./charts/stateless-svc
```

## Test

```bash
kubectl port-forward deployments/bento-public-stateless-svc 5001:5000
curl http://localhost:5001/service-info
```

## Teardown

```bash
helm uninstall bento-public
```

## Notes

- bento_public runs on port 5000 internally, so port-forwarding uses `5001:5000`.
- Environment variable values are set to dummies — replace with real URLs for a live deployment.
- Translation files and about pages are mounted as EmptyDir volumes. The app will start
  but may not display translations or about page content in this configuration.
- Branding images (PNG) are stored as `binaryData` in a ConfigMap and mounted into the
  container at `/bento-public/dist/public/assets`. This approach works for development
  given the small file sizes, but is not recommended for production due to ConfigMap's
  1 MiB size limit. The long-term solution is to serve static assets from an S3 bucket.
- The `stateless-svc` chart was extended with `binaryData` support in the ConfigMap
  template to support this deployment.