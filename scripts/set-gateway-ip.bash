HOST_IP=""
GW_PORT="443"
GW_ADDR=$(kubectl get gateway -n gateway gateway -o jsonpath='{.status.addresses[0].value}')

case "$(uname -s)" in
    Darwin)
        # MacOS Cloud-Provider-Kind exposes the Gateway on an ephemeral port on localhost.
        # Traffic is routed through 127.0.0.1 on that port
        echo "MacOS detected: using ephemeral Gateway port mapping."
        echo "WARNING: make sure to use the port when using HTTPS domains."
        echo ""

        export HOST_IP="127.0.0.1"

        # Discover the ephemeral Envoy port mapped to the host
        ENVOY_CONTAINER=$(docker ps --filter "name=kindccm-gw" --format '{{.Names}}'  | head -n1)
        export GW_PORT=$(docker inspect  -f '{{(index (index .NetworkSettings.Ports "10000/tcp") 0).HostPort}}'  "$ENVOY_CONTAINER")
        ;;
    Linux)
        # On Linux, the Gateway can be reached on the container IP directly
        export HOST_IP=$GW_ADDR
        ;;
    *)
        echo "Unsupported OS"
        exit 1
        ;;
esac

echo "Gateway IP:           ${HOST_IP}"
echo "Gateway HTTPS port:   ${GW_PORT}"

echo ""
echo "Add the following entries to your /etc/hosts file:"
echo ""

cat <<EOF
${HOST_IP}    argocd.bento.k8s.local
${HOST_IP}    portal.bento.k8s.local
${HOST_IP}    public.bento.k8s.local
${HOST_IP}    auth.bento.k8s.local
${HOST_IP}    garage.bento.k8s.local
${HOST_IP}    cbioportal.bento.k8s.local
${HOST_IP}    katsu.bento.k8s.local
EOF
