kubectl get secret root-ca-secret -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/dev-ca.crt

case "$(uname -s)" in
    Darwin)
        # Trust cert on MacOS
        # TODO: validate this with a MacOS user
        sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/dev-ca.crt
        ;;
    Linux)
        # Trust cert on Linux
        sudo cp /tmp/dev-ca.crt /usr/local/share/ca-certificates/
        sudo update-ca-certificates
        ;;
    *)
        echo "Unsupported OS"
        exit 1
        ;;
esac

echo "Root CA certificate has been created at /tmp/dev-ca.crt and added to the trusted certs."
echo ""
echo "  NOTE: for browser trust, you must manually import the CA in the browser of your choice."
