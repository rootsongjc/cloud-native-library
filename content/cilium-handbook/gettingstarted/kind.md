::: {.only}
not (epub or latex or html)

WARNING: You are looking at unreleased Cilium documentation. Please use
the official rendered version released here: <https://docs.cilium.io>
:::

Getting Started Using Kind {#gs_kind}
==========================

This guide uses [kind](https://kind.sigs.k8s.io/) to demonstrate
deployment and operation of Cilium in a multi-node Kubernetes cluster
running locally on Docker.

Install Dependencies
--------------------

Configure kind
--------------

Create a cluster
----------------

Install Cilium {#kind_install_cilium}
--------------

Then, install Cilium release via Helm:

::: {.parsed-literal}

helm install cilium \\

:   \--namespace kube-system \\ \--set kubeProxyReplacement=partial \\
    \--set hostServices.enabled=false \\ \--set externalIPs.enabled=true
    \\ \--set nodePort.enabled=true \\ \--set hostPort.enabled=true \\
    \--set bpf.masquerade=false \\ \--set image.pullPolicy=IfNotPresent
    \\ \--set ipam.mode=kubernetes
:::

::: {.note}
::: {.title}
Note
:::

To fully enable Cilium\'s kube-proxy replacement
(`kubeproxy-free`{.interpreted-text role="ref"}), cgroup v2 needs to be
enabled by setting the kernel `systemd.unified_cgroup_hierarchy=1`
parameter. Also, cgroup v1 controllers `net_cls` and `net_prio` have to
be disabled, or cgroup v1 has to be disabled (e.g. by setting the kernel
`cgroup_no_v1="all"` parameter). This ensures that Kind nodes have their
own cgroup namespace, and Cilium can attach BPF programs at the right
cgroup hierarchy. To verify this, run the following commands on the
host, and check that the output values are different.

``` {.shell-session}
$ sudo ls -al /proc/$(docker inspect -f '{{.State.Pid}}' kind-control-plane)/ns/cgroup
$ sudo ls -al /proc/self/ns/cgroup
```

See the [Pull Request](https://github.com/cilium/cilium/pull/16259) for
more details.
:::

Troubleshooting
---------------

### Unable to contact k8s api-server

In the `Cilium agent logs <ts_agent_logs>`{.interpreted-text role="ref"}
you will see:

    level=info msg="Establishing connection to apiserver" host="https://10.96.0.1:443" subsys=k8s
    level=error msg="Unable to contact k8s api-server" error="Get https://10.96.0.1:443/api/v1/namespaces/kube-system: dial tcp 10.96.0.1:443: connect: no route to host" ipAddr="https://10.96.0.1:443" subsys=k8s
    level=fatal msg="Unable to initialize Kubernetes subsystem" error="unable to create k8s client: unable to create k8s client: Get https://10.96.0.1:443/api/v1/namespaces/kube-system: dial tcp 10.96.0.1:443: connect: no route to host" subsys=daemon

As Kind is running nodes as containers in Docker, they\'re sharing your
host machines\' kernel. If `host-services`{.interpreted-text role="ref"}
wasn\'t disabled, the eBPF programs attached by Cilium may be out of
date and no longer routing api-server requests to the current
`kind-control-plane` container.

Recreating the kind cluster and using the helm command
`kind_install_cilium`{.interpreted-text role="ref"} will detach the
inaccurate eBPF programs.

### Crashing Cilium agent pods

Check if Cilium agent pods are crashing with following logs. This may
indicate that you are deploying a kind cluster in an environment where
Cilium is already running (for example, in the Cilium development VM).
This can also happen if you have other overlapping BPF `cgroup` type
programs attached to the parent `cgroup` hierarchy of the kind container
nodes. In such cases, either tear down Cilium, or manually detach the
overlapping BPF `cgroup` programs running in the parent `cgroup`
hierarchy by following the [bpftool
documentation](https://manpages.ubuntu.com/manpages/focal/man8/bpftool-cgroup.8.html).
For more information, see the [Pull
Request](https://github.com/cilium/cilium/pull/16259).

    level=warning msg="+ bpftool cgroup attach /var/run/cilium/cgroupv2 connect6 pinned /sys/fs/bpf/tc/globals/cilium_cgroups_connect6" subsys=datapath-loader
    level=warning msg="Error: failed to attach program" subsys=datapath-loader
    level=warning msg="+ RETCODE=255" subsys=datapath-loader

Cluster Mesh {#gs_kind_cluster_mesh}
------------

With Kind we can simulate Cluster Mesh in a sandbox too.

### Kind Configuration

This time we need to create (2) `config.yaml`, one for each kubernetes
cluster. We will explicitly configure their `pod-network-cidr` and
`service-cidr` to not overlap.

Example `kind-cluster1.yaml`:

``` {.yaml}
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
  podSubnet: "10.0.0.0/16"
  serviceSubnet: "10.1.0.0/16"
```

Example `kind-cluster2.yaml`:

``` {.yaml}
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
  podSubnet: "10.2.0.0/16"
  serviceSubnet: "10.3.0.0/16"
```

### Create Kind Clusters

We can now create the respective clusters:

``` {.shell-session}
kind create cluster --name=cluster1 --config=kind-cluster1.yaml
kind create cluster --name=cluster2 --config=kind-cluster2.yaml
```

### Setting up Cluster Mesh

We can deploy Cilium, and complete setup by following the Cluster Mesh
guide with `gs_clustermesh`{.interpreted-text role="ref"}. For Kind,
we\'ll want to deploy the `NodePort` service into the `kube-system`
namespace.
