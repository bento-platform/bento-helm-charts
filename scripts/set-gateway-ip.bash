export GW_ADDR=$(kubectl get gateway -n gateway gateway -o jsonpath='{.status.addresses[0].value}')

echo "Local k8s Gateway exposed on ${GW_ADDR} ."
echo ""
echo "Serving HTTPS on port 443."

echo ""
echo "Add the following entries to your /etc/hosts file:"
echo ""
echo "${GW_ADDR}    argocd.bento.k8s.local"
echo "${GW_ADDR}    portal.bento.k8s.local"
echo "${GW_ADDR}    public.bento.k8s.local"
echo "${GW_ADDR}    auth.bento.k8s.local"
echo "${GW_ADDR}    garage.bento.k8s.local"
echo "${GW_ADDR}    cbioportal.bento.k8s.local"
echo "${GW_ADDR}    katsu.bento.k8s.local"
