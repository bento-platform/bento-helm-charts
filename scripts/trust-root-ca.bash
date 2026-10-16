kubectl get secret root-ca-secret -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/dev-ca.crt

case "$(uname -s)" in
    Darwin)
        # Trust cert on MacOS, prompts for the password in a GUI dialog
        if ! sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /tmp/dev-ca.crt; then
            echo "Failed to add the root CA to the System keychain (was the authorization dialog cancelled?)"
            exit 1
        fi
        ;;
    Linux)
        # Trust cert on Linux
        if ! sudo cp /tmp/dev-ca.crt /usr/local/share/ca-certificates/ || ! sudo update-ca-certificates; then
            echo "Failed to add the root CA to the trusted certs"
            exit 1
        fi
        ;;
    *)
        echo "Unsupported OS"
        exit 1
        ;;
esac

echo "Root CA certificate has been created at /tmp/dev-ca.crt and added to the trusted certs."
echo ""
echo "  NOTE: for browser trust, you must manually import the CA in the browser of your choice."
