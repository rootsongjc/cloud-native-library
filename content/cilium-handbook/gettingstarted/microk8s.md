::: {.only}
not (epub or latex or html)

WARNING: You are looking at unreleased Cilium documentation. Please use
the official rendered version released here: <https://docs.cilium.io>
:::

Getting Started Using MicroK8s {#gs_microk8s}
==============================

This guide uses [microk8s](https://microk8s.io/) to demonstrate
deployment and operation of Cilium in a single-node Kubernetes cluster.
To run Cilium inside microk8s, a GNU/Linux distribution with kernel 4.9
or later is required (per the `admin_system_reqs`{.interpreted-text
role="ref"}).

Install microk8s
----------------

1.  Install `microk8s` \>= 1.15 as per microk8s documentation: [MicroK8s
    User guide](https://microk8s.io/docs/).

2.  Enable the microk8s Cilium service

    ``` {.shell-session}
    microk8s enable cilium
    ```

3.  Cilium is now configured! The `cilium` CLI is provided as
    `microk8s.cilium`.

Next steps
----------

Now that you have a Kubernetes cluster with Cilium up and running, you
can take a couple of next steps to explore various capabilities:

-   `gs_http`{.interpreted-text role="ref"}
-   `gs_dns`{.interpreted-text role="ref"}
-   `gs_cassandra`{.interpreted-text role="ref"}
-   `gs_kafka`{.interpreted-text role="ref"}
