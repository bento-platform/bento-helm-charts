HOST_IP=""
GW_PORT="443"
GW_ADDR=$(kubectl get gateway -n envoy-gateway-system gateway -o jsonpath='{.status.addresses[0].value}')

case "$(uname -s)" in
    Darwin)
        # On MacOS, the container IPs are not reachable from the host.
        # Cloud-Provider-Kind publishes the Envoy Gateway's port 443 on localhost instead.
        export HOST_IP="127.0.0.1"
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
${HOST_IP}    bento.k8s.local
${HOST_IP}    argocd.bento.k8s.local
${HOST_IP}    portal.bento.k8s.local
${HOST_IP}    auth.bento.k8s.local
${HOST_IP}    garage.bento.k8s.local
${HOST_IP}    cbioportal.bento.k8s.local
EOF
