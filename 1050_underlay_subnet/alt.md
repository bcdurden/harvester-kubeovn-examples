Defining the Underlay interface
```bash
cat <<EOF | kubectl apply -f -
apiVersion: kubeovn.io/v1
kind: ProviderNetwork
metadata:
  name: pn-mgmt
spec:
  defaultInterface: enp2s0
EOF
```

Defining the Underlay VLAN -> NIC
```bash
cat <<EOF | kubectl apply -f -
apiVersion: kubeovn.io/v1
kind: Vlan
metadata:
  name: vlan44
spec:
  id: 44
  provider: pn-mgmt
EOF
```


```bash
RULE_INDEX=$(kubectl get validatingwebhookconfiguration harvester-network-webhook -o yaml \
  | yq '.webhooks[0].rules | to_entries | map(select(.value.resources[] == "network-attachment-definitions")) | .[].key')

kubectl patch validatingwebhookconfiguration harvester-network-webhook \
  --type='json' \
  -p="[{'op':'remove','path':'/webhooks/0/rules/$RULE_INDEX'}]"

cat <<EOF | kubectl apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: my-underlay-nad
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "kube-ovn",
      "server_socket": "/run/openvswitch/kube-ovn-daemon.sock",
      "provider": "my-underlay-nad.default.ovn" 
    }
EOF
```

```bash
RULE_INDEX=$(kubectl get validatingwebhookconfiguration harvester-network-webhook -o yaml \
  | yq '.webhooks[0].rules | to_entries | map(select(.value.resources[] == "subnets")) | .[].key')
kubectl patch validatingwebhookconfiguration harvester-network-webhook \
  --type='json' \
  -p="[{'op':'remove','path':'/webhooks/0/rules/$RULE_INDEX'}]"

cat <<EOF | kubectl apply -f -
apiVersion: kubeovn.io/v1
kind: Subnet
metadata:
  name: my-underlay-subnet
spec:
  protocol: IPv4
  cidrBlock: 10.3.0.0/16
  gateway: 10.3.0.254
  gatewayType: centralized
  gatewayNode: "kubeovn-test-0,kubeovn-test-1,kubeovn-test-2"
  logicalGateway: true
  disableGatewayCheck: true
  natOutgoing: false
  vpc: ovn-cluster
  excludeIps:
  - 10.3.0.1
  vlan: vlan44              # <- defining the subnet as an underlay by linking the vlan
  provider: my-underlay-nad.default.ovn         # <- defining the subnet IPAM path
EOF
```


enableExternal: true  
extraExternalSubnets: 
- my-underlay-subnet