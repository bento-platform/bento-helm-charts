kind create cluster

# TODO: Running Cloud-Provider-Kind in Docker works well on Linux but is having issues on MacOS.
#       Testing with the CLI tool instead so it runs as sudo, works well on Linux.
# 
# VERSION=v0.11.0
# sudo docker run -d --name cloud-provider-kind --rm --network host \
#     -v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:${VERSION}

# Sudo required for MacOS host port mapping
sudo cloud-provider-kind
