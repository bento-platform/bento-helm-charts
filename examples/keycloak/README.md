# Keycloak

Deploys a Keycloak instance backed by a CNPG-managed PostgreSQL cluster, both running in the `keycloak` namespace.

## Prerequisites

- [CNPG operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) installed
- Keycloak Operator installed

## Setup

### 1. Install the Keycloak Operator

```bash
kubectl create namespace keycloak
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/kubernetes.yml -n keycloak
```

### 2. Deploy the PostgreSQL cluster

```bash
kubectl apply -f examples/keycloak/keycloak-db.yaml
kubectl wait --for=condition=Ready cluster/keycloak-db -n keycloak --timeout=120s
```

### 3. Deploy Keycloak

```bash
kubectl apply -f examples/keycloak/keycloak.yaml -n keycloak
```

### 4. Wait for Keycloak to be ready

```bash
kubectl get pods -n keycloak -w
```

Keycloak is ready when `keycloak-0` shows `1/1 Running`. On the first deployment, Keycloak runs a Quarkus build step which may cause one restart before stabilizing -- this is expected.

## Validation

Port-forward the Keycloak service and open the admin console:

```bash
kubectl port-forward -n keycloak svc/keycloak-service 8080:8080
```

Open `http://localhost:8080` in your browser. You should see the Keycloak login page.

## Teardown

```bash
kubectl -n keycloak delete keycloak keycloak
kubectl -n keycloak delete cluster keycloak-db
kubectl delete -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/kubernetes.yml -n keycloak
kubectl delete -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
kubectl delete -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
kubectl delete namespace keycloak
```