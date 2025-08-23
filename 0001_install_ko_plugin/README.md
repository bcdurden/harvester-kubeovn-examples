# Installing the kubeovn ko plugin

There is a 'ko' plugin for kubectl that allows for direct communication with various cluster and per-node components of OVN/OVS. It is very useful to have to diagnose issues in networking pathways, flows, ACLs, routes, and more.

---
**WARNING** 

**I am not here as a representative of RGS or SUSE. Neither are the contributors to this repo.
None of these examples provided are in any way supported or implied to be supported by RGS or SUSE. These are here purely for educational purposes and example-driven learning for the Kubeovn deployment on Harvester. If you're interested in building supportable examples, please consult with your assigned SA or RGS or SUSE contacts.**

**END WARNING**

---

## Versions Tested

Current `Harvester` Version: `v1.6.0-EC6`

Tested `Harvester` Versions: 
* `v1.6.0-EC6`

`Kubeovn Operator` Versions: 
* `v1.13.5-rc5`


## Issues

None

## Implementation

Acquire the ko plugin binary that matches the kubeovn version (we are on 1.13.5 right now) [from their github](https://raw.githubusercontent.com/kubeovn/kube-ovn/release-1.13/dist/images/kubectl-ko)

Add to you binary path and kubectl will automatically find it.

## Requirements or Helpful links

Release 1.13: `https://raw.githubusercontent.com/kubeovn/kube-ovn/release-1.13/dist/images/kubectl-ko`

## Install

Download the binary within your linux environment and use install to add it to a path:

```bash
wget https://raw.githubusercontent.com/kubeovn/kube-ovn/release-1.13/dist/images/kubectl-ko
sudo install kubectl-ko /usr/local/bin/kubectl-ko
rm kubectl-ko
```

You can now test the plugin by querying for all routers and switches using the `nbctl` subcommand:

```bash
kubectl ko nbctl show
```

## Deep Dive

N/A

Example diagram image:
![image-name](./image/location.png)]

## Outcomes

Kubeovn's ko plugin has been installed and you can now use this to query ovn/ovs backend components.
