kind create cluster

# Running Cloud-Provider-Kind in Docker works well on Linux but is having issues on MacOS.
case "$(uname -s)" in
    Darwin)
        # MacOS Cloud-Provider-Kind has to be ran with the CLI using sudo
        # Keep this terminal running!
        sudo cloud-provider-kind
        ;;
    Linux)
        # Linux supports running Cloud-Provider-Kind in a container
        VERSION=v0.11.0
        sudo docker run -d --name cloud-provider-kind --rm --network host \
            -v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:${VERSION}
        ;;
    *)
        echo "Unsupported OS"
        exit 1
        ;;
esac