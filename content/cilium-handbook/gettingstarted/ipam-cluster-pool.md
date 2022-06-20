::: {.only}
not (epub or latex or html)

WARNING: You are looking at unreleased Cilium documentation. Please use
the official rendered version released here: <http://docs.cilium.io>
:::

CRD-backed by Cilium cluster-pool IPAM {#gsg_ipam_crd_cluster_pool}
======================================

This is a quick tutorial walking through how to enable CRD-backed by
Cilium cluster-pool IPAM. The purpose of this tutorial is to show how
components are configured and resources interact with each other to
enable users to automate or extend on their own.

For more details, see the section
`ipam_crd_cluster_pool`{.interpreted-text role="ref"}

Enable Cluster-pool IPAM mode
-----------------------------

1.  Setup Cilium for Kubernetes using helm with the options:
    `--set ipam.mode=cluster-pool`.
2.  Depending if you are using IPv4 and / or IPv6, you might want to
    adjust the `podCIDR` allocated for your cluster\'s pods with the
    options:
    -   `--set ipam.operator.clusterPoolIPv4PodCIDRList=<IPv4CIDR>`
    -   `--set ipam.operator.clusterPoolIPv6PodCIDRList=<IPv6CIDR>`
3.  To adjust the CIDR size that should be allocated for each node you
    can use the following options:
    -   `--set ipam.operator.clusterPoolIPv4MaskSize=<IPv4MaskSize>`
    -   `--set ipam.operator.clusterPoolIPv6MaskSize=<IPv6MaskSize>`
4.  Deploy Cilium and Cilium-Operator. Cilium will automatically wait
    until the `podCIDR` is allocated for its node by Cilium Operator.

Validate installation
---------------------

1.  Validate that Cilium has started up correctly

    ``` {.shell-session}
    $ cilium status --all-addresses
    KVStore:                Ok   etcd: 1/1 connected, has-quorum=true: https://192.168.60.11:2379 - 3.3.12 (Leader)
    [...]
    IPAM:                   IPv4: 2/256 allocated,
    Allocated addresses:
      10.0.0.1 (router)
      10.0.0.3 (health)
    ```

2.  Validate the `spec.ipam.podCIDRs` section:

    ``` {.shell-session}
    $ kubectl get cn k8s1 -o yaml
    apiVersion: cilium.io/v2
    kind: CiliumNode
    metadata:
      name: k8s1
      [...]
    spec:
      ipam:
        podCIDRs:
          - 10.0.0.0/24
    ```
