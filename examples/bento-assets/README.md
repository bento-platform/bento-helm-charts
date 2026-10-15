# Bento Instance Assets Example

Deploying a Bento service with its instance assets (branding, translations, config files) taken from a versioned
[bento_assets](https://github.com/bento-platform/bento_assets) image, using the `assets` values of the `stateless-svc`
Helm chart (>= 0.6.0).

## Overview

Each Bento instance has its own assets image, `ghcr.io/bento-platform/bento-assets-<instance>:<version>`, whose
entrypoint copies a service's files to the paths the service reads them from (see the image's `manifest.json`).

With `assets.enabled`, the chart:

1. Adds an `assets` init container running the assets image with `assets.service` as its argument, writing into a
   `bento-assets` emptyDir mounted at `assets.mountPath`.
2. Mounts each of `assets.files` from that emptyDir into the service's container at `<mountPath>/<file>` with
   `subPath`, so the files the service's image already has in `mountPath` are kept. With `files: []`, the whole
   directory is mounted at `mountPath` instead.

The init container runs for every new pod, so bumping `assets.image.tag` rolls out the new assets.

> [!WARNING]
> Using `files: []` will override any files already present in the service container's `mountPath`, 
> only use it for services that support overriding the `mountPath`.

## Prerequisites

- A running Kubernetes cluster (e.g. kind)
- `kubectl` and `helm` installed

## Deploy

Deploy bento_web with the `dev` instance's branding:

```bash
helm install -f charts/stateless-svc/ci/bento-web-assets-values.yaml bento-web ./charts/stateless-svc
```

Deploy bento_public with all of the `dev` instance's public assets (temporary example, see
[`public-values.yaml`](./public-values.yaml)):

```bash
helm install -f examples/bento-assets/public-values.yaml bento-public ./charts/stateless-svc
```

## Test

```bash
# The init container's logs list the copied files
kubectl logs deployments/bento-web-stateless-svc -c assets

# The branding is mounted next to the image's own static files
kubectl exec deployments/bento-web-stateless-svc -- ls -l /web/dist/static/
```

For bento_public:

```bash
# Lists the 10 copied files
kubectl logs deployments/bento-public-stateless-svc -c assets

# The assets are mounted next to the image's own files
kubectl exec deployments/bento-public-stateless-svc -- ls -l /bento-public/dist/public/assets /bento-public/dist/public/styles

# Served by bento_public
kubectl port-forward deployments/bento-public-stateless-svc 5001:5000
curl -o branding.png http://localhost:5001/public/assets/branding.png
```

## Teardown

```bash
helm uninstall bento-web
helm uninstall bento-public
```

## Values per service

Paths follow the bento_assets `manifest.json`, which targets Bento v26 (bento_public 1.1.0).

### bento_public

```yaml
assets:
  enabled: true
  image:
    repository: ghcr.io/bento-platform/bento-assets-dev
    tag: "26.0.0"
  service: public
  mountPath: /bento-public/dist/public
  files:
    - en_about.html
    - fr_about.html
    - assets/branding.png
    - assets/branding.fr.png
    - assets/branding.lightbg.png
    - assets/branding.lightbg.fr.png
    - assets/icon_small.png
    - styles/instance.css
    - locales/en/translation_en.json
    - locales/fr/translation_fr.json
```

### bento_web

```yaml
assets:
  enabled: true
  image:
    repository: ghcr.io/bento-platform/bento-assets-dev
    tag: "26.0.0"
  service: web
  mountPath: /web/dist/static
  files:
    - branding.png
```

### Katsu

Replaces the `config.json` ConfigMap. `files` must be set, since mounting the whole directory would hide Katsu's code.

```yaml
assets:
  enabled: true
  image:
    repository: ghcr.io/bento-platform/bento-assets-dev
    tag: "26.0.0"
  service: katsu
  mountPath: /app/chord_metadata_service
  files:
    - config.json
```

### Beacon

```yaml
assets:
  enabled: true
  image:
    repository: ghcr.io/bento-platform/bento-assets-dev
    tag: "26.0.0"
  service: beacon
  mountPath: /config
  files: []
```

## Notes

- Pin a full version (`26.0.0`, or `26.0.0@sha256:...` for a digest). Floating tags (`26`, `edge`) don't change the
  pod template, so they don't roll out, and nodes keep their cached image with the default `IfNotPresent` pull policy.
- Only list the files the instance ships. Optional files (e.g. the French ones) that an instance doesn't have are
  skipped by the init container, and kubelet then creates their `subPath` as an empty directory, which fails to mount
  over a file of the service's image.
- `examples/public` and `deployment/services/katsu` still use ConfigMaps for these files; they can be switched to
  `assets` once the chart is released.
