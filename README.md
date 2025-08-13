# Example Configurations for Harvester with Kubeovn

Due to the potentially vast amount of configuration options for network topologies with Kubeovn, this repo will function as a base for defining scenario/use-case examples to assist others in building their own PoCs and solutions.

Given some of the idiosyncrasies between various OVS and Kubeovn implementations, this one will focus on the version of Kubeovn supplied with Harvester v1.6.0. As versions/releases progress, there will be an attempt to keep common use-cases up to date. If it's found that one example isn't working due to a change or similar, please report it as an issue or edit the doc and put a warning up top with the effective warning.

---
**WARNING** 

**I am not here as a representative of RGS or SUSE. Neither are the contributors to this repo.
None of these examples provided are in any way supported or implied to be supported by RGS or SUSE. These are here purely for educational purposes and example-driven learning for the Kubeovn deployment on Harvester. If you're interested in building supportable examples, please consult with your assigned SA or RGS or SUSE contacts.**

**END WARNING**

---

**Break things!!!**

This is also supposed to be a sandbox, so your use-case submission doesn't have to work immediately or at all. It can be an idea people can collaborate on in order to achieve the desired outcome. There will be some use-cases that don't work for unknown reasons, and part of this is to discover the reasons why in order to either improve the product or improve best-practice messaging

## Layout

**Naming**

This repo will be mostly document-based so it will be laid out as such using a naming scheme. We will follow an indexing scheme that follows level of complexity/difficulty so the user is aware before they jump in too deep. Hopefully this can function as a bit of a training ground for kubeovn and harvester.

**Contents**

Each folder is designed to be self-sufficient. So any yaml code or scripts you write that are included should be contained within that directory. If a common set of functions or common process needs to be defined for most/all use-cases, it can become its own folder (for instance, the install of kubeovn will be its own folder). Any common tools can be included in a base-level folder structure.

You don't have to be overly descriptive of what you are trying to build, but if you can include diagrams or explanations of the various parts, especially if it verges on the complex side, it would be helpful.

Use the [template.md](./template.md) file for your document and feel free to tweak its layout, its just meant to offer a guide and a starting point..