```bash
cat <<EOF | kubectl apply -f -
apiVersion: kubeovn.io/v1
kind: ProviderNetwork
metadata:
  name: pn-mgmt
spec:
  defaultInterface: mgmt-br
EOF
```

```bash
cat <<EOF | kubectl apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: my-underlay-network
  namespace: default
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "br-pn-mgmt",
      "mode": "bridge",
      "ipam": {}
    }'
EOF
```

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kubeovn.io/v1
kind: Vlan
metadata:
  name: vlan6
spec:
  id: 6
  provider: pn-mgmt
EOF
```

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kubeovn.io/v1
kind: Subnet
metadata:
  name: my-underlay-subnet
spec:
  protocol: IPv4
  cidrBlock: 10.10.16.0/24
  logicalGateway: true
  excludeIps:
  - 10.10.16.50..10.10.16.254
  provider: my-underlay-network
EOF
```

enableExternal: true  
extraExternalSubnets: 
- my-underlay-subnet