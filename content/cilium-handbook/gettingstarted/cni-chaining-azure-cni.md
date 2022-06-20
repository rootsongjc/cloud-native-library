::: {.only}
not (epub or latex or html)

WARNING: You are looking at unreleased Cilium documentation. Please use
the official rendered version released here: <https://docs.cilium.io>
:::

Azure CNI {#chaining_azure}
=========

::: {.note}
::: {.title}
Note
:::

This is not the best option to run Cilium on AKS or Azure. Please refer
to `k8s_install_quick`{.interpreted-text role="ref"} for the best guide
to run Cilium in Azure Cloud. Follow this guide if you specifically want
to run Cilium in combination with the Azure CNI in a chaining
configuration.
:::

This guide explains how to set up Cilium in combination with Azure CNI
in a chaining configuration. In this hybrid mode, the Azure CNI plugin
is responsible for setting up the virtual network devices as well as
address allocation (IPAM). After the initial networking is setup, the
Cilium CNI plugin is called to attach eBPF programs to the network
devices set up by Azure CNI to enforce network policies, perform
load-balancing, and encryption.

Create an AKS + Cilium CNI configuration
----------------------------------------

Create a `chaining.yaml` file based on the following template to specify
the desired CNI chaining configuration. This
`ConfigMap`{.interpreted-text role="term"} will be installed as the CNI
configuration file on all nodes and defines the chaining configuration.
In the example below, the Azure CNI, portmap, and Cilium are chained
together.

``` {.yaml}
apiVersion: v1
kind: ConfigMap
metadata:
  name: cni-configuration
  namespace: kube-system
data:
  cni-config: |-
    {
      "cniVersion": "0.3.0",
      "name": "azure",
      "plugins": [
        {
          "type": "azure-vnet",
          "mode": "transparent",
          "ipam": {
             "type": "azure-vnet-ipam"
           }
        },
        {
          "type": "portmap",
          "capabilities": {"portMappings": true},
          "snat": true
        },
        {
           "name": "cilium",
           "type": "cilium-cni"
        }
      ]
    }
```

Deploy the `ConfigMap`{.interpreted-text role="term"}:

``` {.shell-session}
kubectl apply -f chaining.yaml
```

Deploy Cilium
-------------

Deploy Cilium release via Helm:

::: {.parsed-literal}

helm install cilium \\

:   \--namespace kube-system \\ \--set cni.chainingMode=generic-veth \\
    \--set cni.customConf=true \\ \--set nodeinit.enabled=true \\ \--set
    cni.configMap=cni-configuration \\ \--set tunnel=disabled \\ \--set
    enableIPv4Masquerade=false \\ \--set endpointRoutes.enabled=true
:::

This will create both the main cilium daemonset, as well as the
cilium-node-init daemonset, which handles tasks like mounting the eBPF
filesystem and updating the existing Azure CNI plugin to run in
\'transparent\' mode.
