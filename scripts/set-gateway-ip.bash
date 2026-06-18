export GW_ADDR=$(kubectl get gateway -n gateway gateway -o jsonpath='{.status.addresses[0].value}')
