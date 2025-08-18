kc debug node/harvester-dfcxt -it --image=busybox

Provider Network + VLAN

CRISOCK=unix:///run/k3s/containerd/containerd.sock
NS=kube-system
POD=rke2-multus-8l88m
CTR=kube-rke2-multus  

CID=$(crictl -r $CRISOCK ps | awk -v n="$NS" -v p="$POD" -v c="$CTR" '
  $0 ~ n && $0 ~ p && $0 ~ c {print $1; exit}')
PID=$(crictl -r $CRISOCK inspect $CID | jq -r '.info.pid')

# enter its mount namespace with the host's busybox/sh
sudo nsenter -t "$PID" -m -u -i -n -- /bin/sh

```bash
cat <<EOF | kubectl apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: my-external-provider
  namespace: kube-system
  labels:
    network.harvesterhci.io/clusternetwork: mgmt
    network.harvesterhci.io/ready: 'true'
    network.harvesterhci.io/type: L2VlanNetwork
    network.harvesterhci.io/vlan-id: '1'
spec:
  config: >-
    {
        "cniVersion": "0.3.1",
        "name": "my-external-provider",
        "type": "bridge",
        "bridge": "mgmt-br",
        "promiscMode": true,
        "vlan": 6,
        "ipam": {}
    }
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: my-provider
  namespace: default
  labels:
    network.harvesterhci.io/clusternetwork: mgmt
    network.harvesterhci.io/type: OverlayNetwork
spec:
  config: >-
    {
      "cniVersion": "0.3.1",
      "name": "my-provider",
      "type": "kube-ovn",
      "provider": "my-provider.default.ovn",
      "server_socket": "/run/openvswitch/kube-ovn-daemon.sock",
        "ipam": 
        {
            "type": "kube-ovn",
            "server_socket": "/run/openvswitch/kube-ovn-daemon.sock",
            "provider": "my-provider.default.ovn"
        }
    }
EOF
```

v1.multus-cni.io/default-network: 
Subnet

```bash
cat <<EOF | kubectl apply -f -
---
apiVersion: kubeovn.io/v1
kind: Subnet
metadata:
  name: my-external-subnet
spec:
  protocol: IPv4
  cidrBlock: 10.10.0.0/24
  gateway: 10.10.0.1
  excludeIps:
  - 10.10.0.1
  - 10.10.0.10..10.10.0.254
  provider: my-external-provider.kube-system
---
apiVersion: kubeovn.io/v1
kind: Subnet
metadata:
  name: my-internal-subnet
spec:
  cidrBlock: 10.20.0.0/24
  default: false
  enableLb: true
  excludeIps:
    - 10.20.0.1
  gateway: 10.20.0.1
  gatewayNode: ''
  gatewayType: distributed
  natOutgoing: true
  private: false
  protocol: IPv4
  provider: my-provider.default.ovn
  vpc: ovn-cluster
EOF
```


```bash
cat <<EOF | kubectl apply -f -
kind: VpcNatGateway
apiVersion: kubeovn.io/v1
metadata:
  name: my-nat-gateway
spec:
  vpc: ovn-cluster
  subnet: my-internal-subnet
  lanIp: 10.20.0.254
  externalSubnets:
    - my-external-provider
EOF
```