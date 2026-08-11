case "$(uname -s)" in
    Darwin)
        ;;
    *)
        echo "This script is MacOS-only (Cloud-Provider-Kind binds to an ephemeral port instead of 443 on MacOS)."
        exit 1
        ;;
esac

if ! command -v socat &> /dev/null; then
    echo "socat is required but not installed. Install it with: brew install socat"
    exit 1
fi

# There are two kindccm-gw-* containers (one for port 80, one for port 443) - find the one mapping 443
CONTAINER_ID=$(docker ps --filter "name=kindccm-gw" --format '{{.ID}} {{.Ports}}' | grep -- '->443/tcp' | awk '{print $1}')

if [ -z "$CONTAINER_ID" ]; then
    echo "Could not find a kindccm-gw-* container mapping port 443. Is the cluster running?"
    exit 1
fi

GW_PORT=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "443/tcp") 0).HostPort}}' "$CONTAINER_ID")

# Kill any existing socat process already bound to port 443 so re-running after a cluster restart works cleanly
if pgrep -f "socat TCP-LISTEN:443" > /dev/null; then
    echo "Killing existing socat process on port 443..."
    sudo pkill -f "socat TCP-LISTEN:443"
fi

echo "Forwarding localhost:443 -> localhost:${GW_PORT}"
echo "Press Ctrl+C to stop."
echo ""

sudo socat TCP-LISTEN:443,fork,reuseaddr TCP:127.0.0.1:${GW_PORT}
