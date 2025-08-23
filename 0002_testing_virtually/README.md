# Testing Kubeovn Virtually

This will outline the method for creating a virtual test rig for testing virtualized Harvester+Kubeovn within Harvester. 

If your bare metal devices are lacking and suffering from inadequate network ports, testing virtually might be a better path for you

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

Create a NAD called 'host' that uses an untagged network for communication.

You'll want to upload your Harvester ISO into Harvester as a VM image. You can fetch the URL from the github [release page](https://github.com/harvester/harvester/releases). 

Get the true image name since Harvester/Longhorn does generative names via the UI and use the 'template template' with that value:

```bash
export VM_IMAGE_NAME=$(kubectl get virtualmachineimage -l harvesterhci.io/imageDisplayName=<your-iso-name> -o jsonpath={.items[*].metadata.name})
cat test_template.yaml | envsubst | kubectl apply -f -
```

Now you can spin up multiple copies using this template.

## Requirements or Helpful links

[Include links or other information to your example.
`kubectl`, `Harvester running`, and `kubeconfig downloaded` can be implied here. But if you're using specific tools outside of that (think `yq` etc) then please define them here too.

If your kubeovn operator installation deviates from the default, please include the flags changed here. Reference the [install doc](./00_kubeovn_install/README.md) if needed

If you are testing in a virtualized environment, please specify that. Please include basic node information of your setup as well.

If dependent on the outcome of another use-case, please link it here.]

## Install

[Detail how to install the implementation or at least how it is up to this point if its not working. Feel free to be very detailed if needed and if this is a basic use case, consider using the UI and screenshots]

## Deep Dive

[If it is a complex idea, please explain more thoroughly and please use diagrams. [draw.io](https://draw.io) is a great starting point and it can export in PNG.

Example diagram image:
![image-name](./image/location.png)]

## Outcomes

[This is the final section, if things aren't working as expected or are unexplained, please mention them here. Otherwise do a brief review of what was just done and ways to test that it works from a variety of angles if necessary.]

Removal order:
* delete VM
* delete subnet
    * if subnet fails with a webhook complaint about an IP, find the VM's IP in `kubectl get ip` and delete that `IP` object
* delete NAD