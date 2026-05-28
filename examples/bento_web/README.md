# bento_web Deployment Example

POC example deploying [bento_web](https://github.com/bento-platform/bento_web), Bento's
private web portal, using the `stateless-svc` Helm chart.

## Prerequisites

- A running Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed

## Deploy

```bash
helm install -f examples/bento_web/values.yaml bento-web ./charts/stateless-svc
```

## Test

```bash
kubectl port-forward deployments/bento-web-stateless-svc 5000:80
curl http://localhost:5000/service-info
```

## Teardown

```bash
helm uninstall bento-web
```

## Notes

- bento_web is a static React frontend served by NGINX on port 80.
- Environment variable values are set to dummies — replace with real URLs for a live deployment.
- bento_web has no database dependency, so no additional manifests are needed.