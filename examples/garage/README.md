# Garage S3 Object Store

This example deploys a [Garage](https://garagehq.deuxfleurs.fr/) cluster into a local Kubernetes instance using the [garage-operator](https://github.com/rajsinghtech/garage-operator). It provides a local S3-compatible object store for use by the DRS and Drop-Box services.

## Prerequisites

- A running local Kubernetes cluster (e.g. minikube)
- `kubectl` and `helm` installed

## Installation

### 1. Install cert-manager

The garage-operator requires cert-manager for webhook certificates.

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml
kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=120s
```

### 2. Install the garage-operator

```bash
helm install garage-operator oci://ghcr.io/rajsinghtech/charts/garage-operator \
  --namespace garage-operator-system \
  --create-namespace
```

### 3. Create the admin secret

```bash
kubectl create secret generic garage-admin-token \
  --from-literal=admin-token=$(openssl rand -hex 32) \
  --namespace garage-operator-system
```

### 4. Deploy the Garage cluster

```bash
kubectl apply -f garage-cluster.yaml
kubectl wait --for=condition=Ready garagecluster/garage \
  --namespace garage-operator-system \
  --timeout=300s
```

### 5. Create buckets and access keys

```bash
kubectl apply -f drs-bucket.yaml
kubectl apply -f drop-box-bucket.yaml
kubectl apply -f drs-bucket-key.yaml
kubectl apply -f drop-box-bucket-key.yaml
```

## Validation

Port-forward the S3 endpoint and validate using the AWS CLI (`brew install awscli`):

```bash
kubectl port-forward svc/garage 3900:3900 -n garage-operator-system
```

In a new terminal:

```bash
export AWS_DEFAULT_REGION=garage
export AWS_ACCESS_KEY_ID=$(kubectl get secret drs-key -n garage-operator-system \
  -o jsonpath='{.data.access-key-id}' | base64 -d)
export AWS_SECRET_ACCESS_KEY=$(kubectl get secret drs-key -n garage-operator-system \
  -o jsonpath='{.data.secret-access-key}' | base64 -d)

aws s3 ls --endpoint-url http://localhost:3900
```

You should see the `drs` bucket listed.

## Teardown

```bash
kubectl delete -f drs-bucket-key.yaml
kubectl delete -f drop-box-bucket-key.yaml
kubectl delete -f drs-bucket.yaml
kubectl delete -f drop-box-bucket.yaml
kubectl delete -f garage-cluster.yaml
helm uninstall garage-operator -n garage-operator-system
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml
```