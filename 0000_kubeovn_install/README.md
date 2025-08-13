# Installing Kubeovn in Harvester

This will cover the installation of Kubeovn including customizing the install. There might be mentions here of tweaks needed to bypass bugs.

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

* As of `Harveser v1.16.0-RC5` there is an issue with the default Pod and Service CIDR ranges of Kubeovn conflicting with Calico. If these are not adjusted during install, Kubeovn will begin to affect network routing and policy for Pods being managed by Calico (and vice versa). Longhorn's replication and UI stop working or become very slow.
* As of `Harveser v1.16.0-RC5`there seems to be random crashes of Kubeovn components, even on a small cluster with no utilitization. It is likely due to the resource limits of the components causing the Pods to crash with OOM. Fixing this requires bumping up the limits right now. Currently the Harvester team is investigating proper limits and it should be fixed in the future. For now its an easy fix.

## Implementation

The Kubeovn Operator is an Addon within Harvester v1.6.0 that installs Kubeovn as an additional CNI and SDN stack on top of Harvester. It is by default disabled. 

Enabling it in a default installation is a simple button-click, but this will cover custom installation tweaks that may be necessary to test various use-cases.

Post-install Configuration changes can be made by editing the Addon. Due to how the operator functions, any manual kubernetes-config changes within the different kubeovn components will be blown away once the operator realizes a component is out of spec.

## Requirements or Helpful links

* [Kuveovn Github](https://github.com/kubeovn/kube-ovn)

## Install

### Manual path:
* Open Advanced->Addons and select the `...` button to the right of the `kubeovn-operator` and select `Edit Config`.
* Click the `Enable` radio button.
* If you wish to do a default installation (not recommended in 1.6.0-RC5), select `Save`
* If you wish to modify the installation flags, select `Edit as YAML`
* For `Harvester v1.6.0-RC5`, there is a documented bug (fixed in next release) for the Pod and Service CIDR ranges. They should be changed to `10.54.0.0/16` and `10.55.0.0/16` respectively to not conflict with Calico.
* There is some evidence that as of `v1.6.0-RC5` there is resource limitation issues causing pod-crashes. Bumping the core and memory limits (not the requests) should help alleviate this.

### Using kubectl instead

The addon can be installed/configured in one go using `kubectl`. See [addon.yaml](./addon.yaml) for more configuration details.

Example yaml configuration in `addon.yaml`:
```yaml
    configurationSpec:
      components:
        OVSDBConTimeout: 3
        OVSDBInactivityTimeout: 10
        checkGateway: true
        enableANP: true
        enableBindLocalIP: true
        enableExternalVPC: true
        enableIC: false
        enableKeepVMIP: true
        enableLB: true
        enableLBSVC: true
        enableLiveMigrationOptimize: true
        enableNATGateway: true
        enableNP: true
        enableOVNIPSec: false
        enableTProxy: false
        hardwareOffload: false
        logicalGateway: true
        lsCtSkipOstLportIPS: true
        lsDnatModDlDst: true
        secureServing: false
        setVLANTxOff: false
        u2oInterconnection: true
```

CIDR fixes are here. Note that if you are using an airgapped or unconnected system, you'll want to change the pinger address to something reachable internally (such as your gateway)
```yaml
      ipv4:
        joinCIDR: 100.64.0.0/16
        pingerExternalAddress: 1.1.1.1
        pingerExternalDomain: google.com.
        podCIDR: 10.54.0.0/16
        podGateway: 10.54.0.1
        serviceCIDR: 10.55.0.0/16
```

Resource limits can be tweaked here. There's a lot of lines so I'll only show one example for the cni. The limits here were increased by 2x. It looks like the crash-affected components tend to be `kubeOvnCNI` `kubeOvnController` and `ovnCentral`.
```yaml
      kubeOvnCNI:
        requests:
          cpu: "100m"
          memory: "100Mi"
        limits:
          cpu: "2"
          memory: "2Gi"
```


## Deep Dive

This is a basic install, nothing to dive into. If you wish to understand some of the configuration options, check the kubeovn reference link above.

## Outcomes

Installation only takes a few minutes and can be confirmed by the addition of the `Virtual Private Cloud` subsection under `Networks` in the left-hand menu.