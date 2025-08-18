# Creating an Underlay Subnet

Here we will create an underlay subnet on the default VPC and attach a VM to it. This will be done using a VLAN that attaches to the existing `mgmt-br` device created by Harvester's Networking configuration.

## Broken
**NOTE: Currently this example does not work as there are issues either in the configuration or in kubeovn, it is being investigated**

---
**WARNING** 

**I am not here as a representative of RGS or SUSE. Neither are the contributors to this repo.
None of these examples provided are in any way supported or implied to be supported by RGS or SUSE. These are here purely for educational purposes and example-driven learning for the Kubeovn deployment on Harvester. If you're interested in building supportable examples, please consult with your assigned SA or RGS or SUSE contacts.**

**END WARNING**

---

## Versions Tested

Current `Harvester` Version: `v1.6.0-RC6`

Tested `Harvester` Versions: 
* `v1.6.0-RC6`

`Kubeovn Operator` Versions: 
* `v1.13.5-rc5`

[Include any other software versions that are part of the implementation. No need to be too granular here, but if bringing in a new tool, please define it here]

## Issues

[Include anything not working here. If a bug is suspected, please open a `Github ticket`.  If existing tickets exist for this issue, please also link them here for tracking. If the issue is now resolved and you wish to record the fix for posterity, feel free to use ~~strikeout~~ notation]

## Implementation

[Define the implementation details of your use-case, or at least what you have planned. Don't make this too long.]

## Requirements or Helpful links

[Include links or other information to your example.
`kubectl`, `Harvester running`, and `kubeconfig downloaded` can be implied here. But if you're using specific tools outside of that (think `yq` etc) then please define them here too.

If your kubeovn operator installation deviates from the default, please include the flags changed here. Reference the [install doc](./00_kubeovn_install/README.md) if needed

If you are testing in a virtualized environment, please specify that. Please include basic node information of your setup as well.

If dependent on the outcome of another use-case, please link it here.]

## Install

First we need to create a Provider Network, the method by which an underlay subnet can connect to a physical device. We will use the physical bridge already created as part of Harvester's installation:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kubeovn.io/v1
kind: ProviderNetwork
metadata:
  name: pn-mgmt
spec:
  defaultInterface: mgmt-bo
EOF
```

Next we need to create a VLAN object to attach to this device. I will use VLAN 6 since that is routable in my upstream network.

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

We also need a NAD that will function as our provider, this is easy.

```bash
export PROVIDER_NAME=underlay-provider
cat <<EOF | envsubst | kubectl apply -f -
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
EOF
```

Now we can create our underlay subnet. My upstream DHCP uses .50 - .254 and I want those left alone.

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
  cidrBlock: 10.10.16.0/24
  disableGatewayCheck: true
  excludeIps:
  - 10.10.16.50..10.10.16.254
  vlan: vlan6
  provider: pn-mgmt.default.ovn
EOF
```

***NO WORKIE***
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
  name: pn-mgmt
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "kube-ovn",
      "name":"pn-mgmt",
      "server_socket": "/run/openvswitch/kube-ovn-daemon.sock",
      "provider": "pn-mgmt.default.ovn"
    }
EOF
```

Now there should be a new bridge created for my provider network (mgmt). I can use the `ko` tools to inspect. I need to use a harvster node name though, since this interface is common across all harvester nodes, any node will do.

```bash
kubectl ko vsctl harvester-dfcxt show
```

Note that there is a new bridge created named `br-mgmt` and it has ports tying the physical device (harvester's `mgmt-br` device) with appropriate VLAN and the `br-mgmt` port going to an interface named `br-mgmt. 

```console
    Bridge br-mgmt
        Port mgmt-br
            trunks: [0, 6]
            Interface mgmt-br
        Port br-mgmt
            Interface br-mgmt
                type: internal
```

If I create a VM using the template attached to the NAD we created:

```bash
export VM_IMAGE_NAME=ubuntu-noble
export VM_NAME=underlay-vm
export PROVIDER_NAME=pn-mgmt
export DNS_SERVER=10.10.0.10
cat templates/vm.yaml | envsubst | kubectl apply -f -
```

**Currently stuck here, traffic does not flow to underlay, still investigating**

## Deep Dive

Underlay Network brief:
- layer2 only

## Outcomes

[This is the final section, if things aren't working as expected or are unexplained, please mention them here. Otherwise do a brief review of what was just done and ways to test that it works from a variety of angles if necessary.]

Removal order:
* delete VM
* delete subnet
    * if subnet fails with a webhook complaint about an IP, find the VM's IP in `kubectl get ip` and delete that `IP` object
* delete NAD