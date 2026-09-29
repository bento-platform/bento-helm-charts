# In-cluster DNS and TLS: local vs production

## Issue

Service-Registry returns public URLs (`https://bento.k8s.local/api/...`), and services also call them from
inside the cluster (e.g. WES posting an ingest to Katsu). By default, pods can't reach them:
- **kind:** the name doesn't resolve, because the host's `/etc/hosts` isn't visible to pods.
- **Real clusters:** it resolves to the external LoadBalancer IP, a hairpin that our firewall rules block.

## Split-horizon DNS

Inside the cluster, `bento.k8s.local` and `*.bento.k8s.local` resolve to the Gateway's Envoy Service, so
service-to-service calls get the same TLS, routes and policies as external traffic.

| File | Role |
|------|------|
| [envoy-proxy.yaml](../deployment/platform/envoy-gateway-system/envoy-proxy.yaml) | Gives the Envoy Service a fixed name, `bento-gateway` (the default name ends in a hash) |
| [coredns-configmap.yaml](../deployment/platform/kube-system/coredns-configmap.yaml) | Adds the CoreDNS rewrite below |

```
rewrite stop {
   name regex ^([a-z0-9-]+\.)*bento\.k8s\.local\.$ bento-gateway.envoy-gateway-system.svc.cluster.local.
   answer auto
}
```
The regex skips search-path expansions, lookalikes (`notbento…`) and `_`-prefixed labels (`_acme-challenge`).

- The ConfigMap owns the **whole** Corefile, so diff it against the default after cluster upgrades.
  `Prune=false,Delete=false` keeps cluster DNS if the Application is removed.
- Only port 443 is exposed, so in-cluster `http://` URLs fail.
- Recreating the Envoy Service can change its external IP. Re-run [set-gateway-ip.bash](../scripts/set-gateway-ip.bash).

Verify: `kubectl run dnstest --rm -it --image=busybox:1.36 --restart=Never -- nslookup bento.k8s.local`
should return the ClusterIP of `svc/bento-gateway`.

## Dev CA trust (local only)

Pods don't trust the dev root CA ([root-ca.yaml](../deployment/platform/cert-manager/root-ca.yaml)).
[trust-manager](../deployment/infra/trust-manager-app.yaml) syncs the
[`bento-ca-bundle`](../deployment/platform/cert-manager/trust-bundle.yaml) (dev CA + public roots) to a
ConfigMap in `default`. The backend services (authz, service-registry, katsu, wes, drs, drop-box) mount it at
`/etc/ssl/bento/ca-certificates.crt` and point these env vars at it:

| Env var | Used by |
|---------|---------|
| `SSL_CERT_FILE` | aiohttp, httpx |
| `REQUESTS_CA_BUNDLE` | requests |
| `CURL_CA_BUNDLE` | curl in WES workflows |

These env vars replace the image's trust store, which is why the bundle includes the public roots.
Always use the public OIDC URL (`https://auth.bento.k8s.local/...`). Keycloak runs with `hostname.strict: false`,
so through its internal URL it reports a different issuer than the one in user tokens.

## Gateway timeouts

Envoy's default route timeout is 15s for the whole response. When it expires, Envoy returns
`504 upstream request timeout` (access log flag `UT`) while the backend keeps running. A Katsu ingest can
finish even though WES reports it as failed.
[backend-traffic-policy.yaml](../deployment/platform/envoy-gateway-system/backend-traffic-policy.yaml)
raises the timeout to 300s for the whole Gateway.

- To go above 300s, also set `streamIdleTimeout` (the default is 5 minutes).
- To override the timeout for one service, add a `BackendTrafficPolicy` targeting its HTTPRoute (via `extraManifests`).
  The chart doesn't expose the HTTPRoute `timeouts` field.

## Production (on-prem, Let's Encrypt)

- **CoreDNS:** The domain differs per environment, so put the rewrite in a kustomize overlay.
- **No CA distribution:** the images already trust Let's Encrypt. Leave out everything marked
  `LOCAL DEV ONLY` and the dev issuers. Keep TLS verification on: never set `BENTO_VALIDATE_SSL=False` or `BENTO_DEBUG=True`.
- **Wildcard certificate needs DNS-01:** use a `letsencrypt-prod` ClusterIssuer with a DNS-01 solver. Run cert-manager
  with `--dns01-recursive-nameservers-only --dns01-recursive-nameservers=1.1.1.1:53,8.8.8.8:53` so its
  propagation checks bypass the in-cluster rewrite. Staging roots are not publicly trusted.
- **Envoy carries internal traffic:** run 2 or more replicas with a PDB and anti-affinity (set in the `EnvoyProxy`).
  Edge controls (WAF, firewall ACLs) don't apply to in-cluster calls, and Envoy sees pod IPs as the client address.
- **Timeouts:** size them to your largest ingest or transfer, and prefer per-route overrides.
- **NetworkPolicies:** allow traffic to the Envoy pods on port 10443 and to kube-dns on port 53.
