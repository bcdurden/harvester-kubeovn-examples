# Build a VPC NAT Gateway

Kubeovn provides a structure for creating a common NAT Gateway tied to a VPC that member subnets can use to exit the VPC.

---
**WARNING** 

**I am not here as a representative of RGS or SUSE. Neither are the contributors to this repo.
None of these examples provided are in any way supported or implied to be supported by RGS or SUSE. These are here purely for educational purposes and example-driven learning for the Kubeovn deployment on Harvester. If you're interested in building supportable examples, please consult with your assigned SA or RGS or SUSE contacts.**

**END WARNING**

---

## Versions Tested

Current `Harvester` Version: `v1.6.0-RC5`

Tested `Harvester` Versions: 
* `v1.6.0-RC5`

`Kubeovn Operator` Versions: 
* `v1.13.5-rc4`

## Issues

* TODO: check webhook tweaks and report with [webhook issue](https://github.com/harvester/harvester/issues/8832)

## Implementation

We will define a VPCNatGateway object for the default VPC and map a new subnet to using it via a route. We will prove it works by creating a VM and see packets traverse the gateway.

Given this is a very early implementation of Kubeovn, some of the more prescriptive requirements enforced in the webhook have to be disabled manually. They will return upon reboot. But if you see steps that patch the webhook, do not be alarmed. There is an [issue filed](https://github.com/harvester/harvester/issues/8832) for this.

## Requirements or Helpful links

Refer to the use-case of [running a VM on kubeovn](../1001_vm_on_kubeovn/README.md) to get an idea of what we will be doing. The toil of creating a NAD and VM will not be covered in depth here, so its important you have seen how that works.

We need to enable VPC NAT Gateway which is a little different than some other features. We need to create named `ConfigMaps` that kubeovn is expecting. Note that the operator will override the version

```bash
cat <<EOF | kubectl apply -f -
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: ovn-vpc-nat-config
  namespace: kube-system
data:
  image: kubeovn/vpc-nat-gateway:v1.14.0
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: ovn-vpc-nat-gw-config
  namespace: kube-system
data:
  enable-vpc-nat-gw: 'true'
EOF
```

## Install

1) Create a macvlan NAD so we can attach to our management bridge

```bash
RULE_INDEX=$(kubectl get validatingwebhookconfiguration harvester-network-webhook -o yaml \
  | yq '.webhooks[0].rules | to_entries | map(select(.value.resources[] == "network-attachment-definitions")) | .[].key')

kubectl patch validatingwebhookconfiguration harvester-network-webhook \
  --type='json' \
  -p="[{'op':'remove','path':'/webhooks/0/rules/$RULE_INDEX'}]"
cat <<EOF | kubectl apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: my-ext-provider
  namespace: kube-system
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "mgmt-br",
      "mode": "bridge",
      "ipam": {
        "type": "kube-ovn",
        "server_socket": "/run/openvswitch/kube-ovn-daemon.sock",
        "provider": "my-ext-provider.kube-system"
      }
    }'
EOF
```

2) Create a new subnet named 'my-external-subnet' and reference this NAD as the provider. The specs for this subnet should match your host network that `Harvester` runs upon. 

    * For me that is `10.10.0.0/24`. Note that I am excluding all network addresses in my upstream that are managed by my upstream gateway's DHCP. Everything below `10.10.0.50` is a private address. 
    * Note that I am patching out the webhook. Given this is a very early implementation of Kubeovn, some of the more prescriptive requirements enforced in the webhook have to be disabled manually. They will return upon reboot.
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
  name: my-external-subnet
spec:
  protocol: IPv4
  provider: my-ext-provider.kube-system
  cidrBlock: 10.10.0.0/24
  gateway: 10.10.0.1
  excludeIps:
  - 10.10.0.1
  - 10.10.0.10..10.10.0.254
EOF
```

2) Create the overlay NAD and the internal subnet called 'my-internal-subnet' which will host the gateway (and our VMs). Feel free to re-use an existing subnet if you have one or create another. I'm going to copy the specs of the one I created in [1001_vm_on_kubeovn](../1001_vm_on_kubeovn/README.md).

```bash
export PROVIDER_NAME=my-provider
export SUBNET_NAME=my-internal-subnet
cat <<EOF | envsubst | kubectl apply -f -
#! PROVIDER_NAME
#! SUBNET_NAME
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: ${PROVIDER_NAME}
  namespace: default
  labels:
    network.harvesterhci.io/clusternetwork: mgmt
    network.harvesterhci.io/type: OverlayNetwork
spec:
  config: >-
    {"cniVersion":"0.3.1","name":"${PROVIDER_NAME}","type":"kube-ovn","provider":"${PROVIDER_NAME}.default.ovn","server_socket":"/run/openvswitch/kube-ovn-daemon.sock"}
---
apiVersion: kubeovn.io/v1
kind: Subnet
metadata:
  name: ${SUBNET_NAME}
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
  provider: ${PROVIDER_NAME}.default.ovn
  vpc: ovn-cluster
EOF
```

3) Create the VPC NAT Gateway object, which will use the internal subnet and have an additional interface on the external-subnet. In my example I'm using `10.20.0.254` as an IP local to the subnet this object will be attached via the provider (`my-ext-provider`  -> `my-internal-subnet`).

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
    - my-ext-provider
EOF
```

**At this point the install fails** 

The culprit is because the VPC Nat Gateway pod has been assigned a pod-network address that kube-ovn did not expect, so when it adds the route as part of the init, the route add fails within the pod. The Daemonset for the vpc nat gateway explicitly declares the default network:
```yaml
annotations:
    k8s.v1.cni.cncf.io/networks: kube-system/my-ext-provider
    my-ext-provider.kube-system.kubernetes.io/routes: '[{"dst":"0.0.0.0/0","gw":"10.10.0.1"}]'
    ovn.kubernetes.io/ip_address: 10.20.0.254
    ovn.kubernetes.io/logical_switch: my-internal-subnet
    ovn.kubernetes.io/routes: >-
        [{"dst":"10.54.0.1","gw":"10.20.0.1"},{"dst":"10.54.0.0/16","gw":"10.20.0.1"},{"dst":"100.64.0.0/16","gw":"10.20.0.1"}]
    ovn.kubernetes.io/vpc_nat_gw: my-nat-gateway
```

But when the pod runs, calico bulldozes over this and ignores the network declaration. Kubeovn's IP assignments are ignored by the kubelet and its receives a `10.52.0.0/16` address. The route add fails due to an invalid gateway.

Investigating the root cause shows an interesting configuration on Harvester's nodes:
```console
harvester-qm92w:/etc/cni/net.d # ls -l
total 28
-rw-------  1 root root  771 Aug 12 19:19 00-multus.conf
-rw-------  1 root root  766 Aug 12 19:19 10-canal.conflist
-rw-r--r--  1 root root  324 Aug 12 21:30 90-kube-ovn.conflist
-rw-r--r--. 1 root root   54 Jan 13  2020 99-loopback.conf.sample
```

By definition, the kubelet is going to pull the first cni config it sees (00-multus) and consume that. The contents of this file show that calico is being delegated to directly. And such, the other two conflist files are being ignored.
```json
{
        "cniVersion": "0.3.1",
        "name": "multus-cni-network",
        "type": "multus",
        "capabilities": {"bandwidth":true,"portMappings":true},
        "cniConf": "/host/etc/cni/multus/net.d",
        "kubeconfig": "/etc/cni/net.d/multus.d/multus.kubeconfig",
        "delegates": [
                {"cniVersion":"0.3.1","name":"k8s-pod-network","plugins":[{"datastore_type":"kubernetes","ipam":{"ranges":[[{"subnet":"usePodCidr"}]],"type":"host-local"},"kubernetes":{"kubeconfig":"/etc/cni/net.d/calico-kubeconfig"},"log_level":"info","mtu":1450,"nodename":"harvester-qm92w","policy":{"type":"k8s"},"type":"calico"},{"capabilities":{"portMappings":true},"snat":true,"type":"portmap"},{"capabilities":{"bandwidth":true},"type":"bandwidth"}]}
        ]
}
```

This essentially makes it impossible to choose kube-ovn's cni as an optional primary interface for a pod because it will get ignored by the default delegate. It will only ever be an optional secondary. This means that all other per-namespace isolation mechanisms that VPCs and Subnets allow will also be ignored.

I think this is a bug but I am not certain. I've reached out to find out more. The obvious fix looks to switch mutlus's config to use the confDir instead of a delegate, which it looks like its already primed for anyway.

EDIT: This is not a bug it seems, just an intentional configuration that is overriding default RKE2 behavious. I'm going to investigate further but early tweaks to allow for kubeovn to be an optional primary were not successful

## Deep Dive

Deeper explanation following success

## Outcomes

[This is the final section, if things aren't working as expected or are unexplained, please mention them here. Otherwise do a brief review of what was just done and ways to test that it works from a variety of angles if necessary.]

Removal order:
* delete VM
* delete subnet
    * if subnet fails with a webhook complaint about an IP, find the VM's IP in `kubectl get ip` and delete that `IP` object
* delete NAD