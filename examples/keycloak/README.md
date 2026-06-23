# Keycloak Infrastructure Example

Deploys a Keycloak instance backed by a CNPG PostgreSQL cluster using the official Keycloak Operator.

All commands are run from the root of the `bento-helm-charts` repository.

## Prerequisites

- CNPG operator installed in the cluster
- A running minikube cluster

## Installation

### 1. Install the Keycloak Operator

```bash
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
kubectl create namespace keycloak
kubectl -n keycloak apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/kubernetes.yml
```

### 2. Deploy the PostgreSQL cluster

```bash
kubectl apply -f examples/keycloak/keycloak-db.yaml
kubectl wait --for=condition=Ready cluster/keycloak-db --timeout=120s
```

### 3. Deploy Keycloak

Apply the Keycloak CR first, then create the database secret. The secret must be created after `kubectl apply` so that the `last-applied-configuration` annotation registered by the operator does not contain secret data that would overwrite the password on subsequent applies.

```bash
kubectl -n keycloak apply -f examples/keycloak/keycloak.yaml
kubectl -n keycloak delete secret keycloak-db-secret --ignore-not-found
kubectl -n keycloak create secret generic keycloak-db-secret --from-literal=username=keycloak --from-literal=password=$(kubectl get secret keycloak-db-app -o jsonpath='{.data.password}' | base64 -d)
```

### 4. Wait for Keycloak to be ready

```bash
kubectl get pods -n keycloak -w
```

Keycloak is ready when `keycloak-0` shows `1/1 Running`. On the very first deployment, Keycloak runs a Quarkus build step which may cause one restart before the pod stabilizes — this is expected.

## Validation

Port-forward the Keycloak service and open the admin console:

```bash
kubectl port-forward -n keycloak svc/keycloak-service 8080:8080
```

Open `http://localhost:8080` in your browser. You should see the Keycloak login page.

## Notes

- The CNPG operator generates the database credentials in the `keycloak-db-app` secret in the `default` namespace. The secret must be copied into the `keycloak` namespace manually, since the Keycloak Operator only watches that namespace.
- The Keycloak Operator only watches the `keycloak` namespace. All Keycloak resources must be deployed there.
- The CNPG cluster runs in the `default` namespace and is referenced by Keycloak via its fully qualified service name `keycloak-db-rw.default.svc.cluster.local`.

## Teardown

```bash
kubectl -n keycloak delete keycloak keycloak
kubectl -n keycloak delete secret keycloak-db-secret
kubectl delete cluster keycloak-db
kubectl delete -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/kubernetes.yml -n keycloak
kubectl delete -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
kubectl delete -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.6.3/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
kubectl delete namespace keycloak
```