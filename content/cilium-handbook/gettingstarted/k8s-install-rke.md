::: {.only}
not (epub or latex or html)

WARNING: You are looking at unreleased Cilium documentation. Please use
the official rendered version released here: <https://docs.cilium.io>
:::

Installation using Rancher Kubernetes Engine {#rke_install}
============================================

This guide walks you through installation of Cilium on [Rancher
Kubernetes Engine](https://rancher.com/products/rke/), a CNCF-certified
Kubernetes distribution that runs entirely within Docker containers. RKE
solves the common frustration of installation complexity with Kubernetes
by removing most host dependencies and presenting a stable path for
deployment, upgrades, and rollbacks.

Install a Cluster Using RKE
---------------------------

The first step is to install a cluster based on the [RKE Installation
Guide](https://rancher.com/docs/rke/latest/en/installation/). When
creating the cluster, make sure to [change the default network
plugin](https://rancher.com/docs/rke/latest/en/config-options/add-ons/network-plugins/custom-network-plugin-example/)
in the config.yaml file.

Change:

``` {.yaml}
network:
  options:
    flannel_backend_type: "vxlan"
  plugin: "canal"
```

To:

``` {.yaml}
network:
  plugin: none
```

Deploy Cilium
-------------

::: {.tabs}
::: {.group-tab}
Helm v3

Install Cilium via `helm install`:

::: {.parsed-literal}
helm repo add cilium <https://helm.cilium.io> helm repo update helm
install cilium \\ \--namespace \$CILIUM_NAMESPACE
:::
:::

::: {.group-tab}
Cilium CLI

Install Cilium by running:

``` {.shell-session}
cilium install
```
:::
:::
