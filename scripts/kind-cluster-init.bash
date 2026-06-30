kind create cluster

VERSION=v0.11.0
docker run -d --name cloud-provider-kind --rm --network host -v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:${VERSION}