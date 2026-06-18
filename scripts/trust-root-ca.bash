kubectl get secret root-ca-secret -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/dev-ca.crt
sudo cp /tmp/dev-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

echo "Root CA certificate has been created at /tmp/dev-ca.crt and added to the trusted certs for Linux."
echo ""
echo "  NOTE: for browser trust, you must manually import the CA in the browser of your choice"