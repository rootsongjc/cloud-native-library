---
title: Onboarding VMs with tctl
description: Guide to onboard a VM or Bare Metal machine to a TSB service mesh.
---

import ratingsWorkloadEntryYAML from '!!raw-loader!../../assets/setup/ratings-workloadentry.yaml';
import ratingsSidecarYAML from '!!raw-loader!../../assets/setup/ratings-sidecar.yaml';
import CodeBlock from '@theme/CodeBlock';

:::note Bare metal servers
In this guide we only call out virtual machines (VMs). If you want to onboard a
workload running on a bare metal server, simply replace VM for bare metal. There
is no difference in handling between them.
:::

## Problem definition

Istio and the underlying Kubernetes platform create a sealed ecosystem, where 
control plane and data plane components are tightly integrated. For example, 
control plane components running on each node create a mutually trusted 
relationship. When new pods are scheduled to run on a node, the node is a 
trusted entity and its critical resources, like iptables, are modified.

When a virtual machine (VM) is brought into that ecosystem, it is an outsider.
To successfully extend an Istio/Kubernetes cluster with a VM, the following 
steps must be taken:
- Authentication. The VM must establish an authenticated encrypted session to the
  control plane. The VM must prove that it is allowed to join the cluster.
- Routing. The VM must be aware of services defined in the Kubernetes cluster
  and vice-versa. If the VM runs a service, it must be visible to pods running
  inside the cluster.

## Overview

Onboarding a Virtual Machine (VM) into a TSB managed Istio service mesh can be
broken down into the following steps:

- Registering the VM `workload` with the Istio control plane (WorkloadEntry)
- Obtaining a bootstrap security token and seed configuration for the Istio
  Proxy that will run on the VM
- Transferring the bootstrap security token and seed configuration to the VM
- Starting Istio Proxy on the VM

To improve the user experience with VM onboarding, TSB comes with `tctl` CLI
that automates most of these tasks.

At a high level, `tctl` aims to streamline VM onboarding flow down to a single
command:

```bash{promptUser: Alice}
tctl x sidecar-bootstrap
```

The `tctl` sidecar bootstrap logic, as well as the registration of the VM
workload with the service mesh is driven by the configuration inside a 
`WorkloadEntry` resource. `tctl` sidecar bootstrap allows you to onboard VMs in
various network and deployment scenarios to your service mesh on Kubernetes. The
`tctl` sidecar bootstrap also allows VM onboarding to be reproduced at any point
from any context, by a developer machine, or a CI/CD pipeline.

## Requirements

Before you get started make sure that you have:

✓ TSB version 0.9 or above<br />
✓ A Kubernetes cluster onboarded into TSB<br />
✓ The relevant application deployed on that Kubernetes cluster in the appropriate namespace<br />
✓ A Virtual Machine spun up and ready to go<br />
✓ The most recent `kubectl` ready<br />
✓ The most recent Tetrate Service Bridge CLI (`tctl`) ready

:::note Differences between environments
This set-up guide provides the common steps you need to take to get a VM
onboarded. Since you have to deal with your specific combination of cloud 
providers, networks, firewalls, workloads, and operating systems, you will need
to adapt the steps so that they will work for your situation. In this guide, we
will use the example of onboarding the Ratings service from the Istio Bookinfo
example on an Ubuntu VM.
:::

## Walkthrough

### Cluster Mesh expansion

To allow workloads from outside the Kubernetes environment to become part of the
service mesh, you need to enable `mesh expansion` in the cluster. Edit the 
[`ControlPlane`](../../refs/install/controlplane/v1alpha1/spec) CR or Helm values to include
the `meshExpansion` property as shown below.

```yaml
spec:
  meshExpansion: {}
```

To edit the resource, run the following command:

```bash{promptUser: alice}{outputLines: 2-3}
kubectl patch ControlPlane controlplane -n istio-system \
    --patch '{"spec":{"meshExpansion":{}}}' \
    --type merge
```

Once you have completed this step you can onboard as many VM workloads to this
cluster as needed. If you have multiple clusters, repeat this step for each
cluster where you need to onboard VMs.

### VM Preparation

To prepare your VM for onboarding you will need to have SSH access to a 
privileged user on the VM, because you must add a user account and install 
additional software.

:::note Example environment
As an example this guide will show how to prepare an Ubuntu 18.04 LTS virtual 
machine.
:::

First, ensure that Docker is installed on the VM. You will be installing Istio
Proxy later on, which will run inside a Docker container. Using Docker allows 
you to keep the Proxy dependencies isolated from your operating system
installation, as well as provide a homogeneous environment for the Proxy to run
on.

To install Docker on the VM, run:

```bash{promptUser: Alice}
sudo apt-get update
sudo apt-get -y install docker.io
```

To allow `tctl` to onboard your VM workload, create and configure a dedicated
user account. This user account will need permissions to interact with the
Docker daemon as well as have SSH access. To bootstrap the onboarding process,
the `tctl` tool will connect to your VM using SSH.

To set up and configure the user account, run the following commands:

```bash{promptUser: Alice}{outputLines: 1,3,4,6,7,12-17}
# create dedicated user account "istio-proxy" for VM onboarding
sudo useradd --create-home istio-proxy

# sudo into the dedicated user
sudo su - istio-proxy

# configure SSH access for the new user account
mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh
touch $HOME/.ssh/authorized_keys
chmod 600 $HOME/.ssh/authorized_keys

#
# Add your SSH public key to $HOME/.ssh/authorized_keys
#

# go back to the privileged user
exit
``` 

To give the new user account permissions to interact with Docker daemon, you
must add the account to the docker user group:

```bash{promptUser: Alice}
sudo usermod -aG docker istio-proxy
```

To store the onboarding configuration, you must set up a directory for it. If
you wish to use a different path, make sure it is reflected in the
`WorkloadEntry` resource which you will be configuring later.

```bash{promptUser: Alice}
sudo mkdir -p /etc/istio-proxy
sudo chmod  775 /etc/istio-proxy
sudo chown istio-proxy:istio-proxy /etc/istio-proxy
```

If your workload is not running yet, start it now. In our example we will run
the Ratings service from the Istio Bookinfo example. This example will be
running inside Docker but this is not required. Your workload can run from the
operating system as a regular process.

```bash{promptUser: Alice}{outputLines: 2-4}
sudo docker run -d \
    --name ratings \
    -p 127.0.0.1:9080:9080 \
    docker.io/istio/examples-bookinfo-ratings-v1:1.16.2
```

### Configuring firewalls

To allow a VM to join a service mesh, there must be IP (L3) connectivity between
the VM and the Kubernetes cluster. You may need to configure firewalls at the
Kubernetes and the VM network ends, to allow traffic between the two on the
various TCP ports used for traffic.

#### Kubernetes and VM on the same network (or peered networks)

Since all workloads have direct IP connectivity, traffic between the VM and Pod
IPs will not use the VM gateway.

In this scenario you must:

✓ allow ingress traffic from the VM IP to the entire range of TCP ports on the Pod IPs<br />
✓ allow ingress traffic from Pod IPs to a relevant set of TCP ports on the VM IP

#### Kubernetes and VM on different networks

When workloads that span Kubernetes and VM do not have direct IP connectivity,
traffic must flow through the VM Gateway.

In this scenario where the networks are segregated, the following TCP ports on
the VM Gateway in Kubernetes must be accessible by the VM:

- 15012 (control plane xDS traffic)
- 15443 (data plane ingress traffic)
- 9411 (sidecar tracing data ingress)
- 11800 (sidecar access logs ingress)

:::note GKE and EKS
On both GKE and EKS these ports will allow incoming traffic automatically.
:::

The ports you need to open for traffic to your VM workload from the Kubernetes
cluster is dependent on the proxy listening ports that you will configure in the
[Sidecar](https://istio.io/latest/docs/reference/config/networking/sidecar/#Sidecar)
resource. In the example, we use port 9080. In this case, we need to allow TCP
traffic from Kubernetes to VM on port 9080.

### Create a WorkloadEntry

A [WorkloadEntry](https://istio.io/latest/docs/reference/config/networking/workload-entry/)
resource captures information about a workload running on a VM which will allow
you to properly onboard the VM with a verifiable identity that is recognized by
the TSB service mesh.

The configuration of a WorkloadEntry deals with the following information:
- Details needed by the service mesh to register the VM workload
- Annotations to provide `tctl` with the right information to bootstrap the VM onboarding 
- Labels for TSB observability that hold the logical service identity of the workload

A template example of a `WorkloadEntry` resource can be seen below and
highlights properties that must be configured based on the specifics of your
environment.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: WorkloadEntry
metadata:
  name: ratings-vm
  namespace: bookinfo
  annotations:
    sidecar-bootstrap.istio.io/ssh-host: <ssh-host>
    sidecar-bootstrap.istio.io/ssh-user: istio-proxy
    sidecar-bootstrap.istio.io/proxy-config-dir: /etc/istio-proxy
    sidecar-bootstrap.istio.io/proxy-image-hub: docker.io/tetrate
    sidecar-bootstrap.istio.io/proxy-instance-ip: <proxy-instance-ip>
spec:
  address: <address>
  labels:
    class: vm
    app: ratings   # mandatory label for observability through TSB
    version: v3    # mandatory label for observability through TSB
  serviceAccount: bookinfo-ratings
  network: <vm-network-name>
```

#### network: &lt;vm-network-name&gt;
The service mesh in your Kubernetes cluster needs to know if your VM resides in
a network that can directly reach the pod IPs. As explained in the firewall
section, this will determine if traffic should be routed through the VM gateway
or not. By adding the `network` property and providing a name for the VM
network, the service mesh will enable VM gateway routing. If you omit the
network property, the service mesh will assume the VM to run on a network with
direct IP connectivity.

#### address: &lt;address&gt;
Address must hold the destination IP of the VM workload that can be directly
connected to by the pods. In the same network scenario this is the VM IP address
that a pod can directly connect to. In a segregated network scenario this is the
VM IP address the pods can reach. As an example, if you have different VPCs for
Kubernetes and VM this can be a private IP address as long as VPC
routing/peering is set up correctly. In case of different cloud providers this
typically is a public IP address on which the VM is reachable.

#### proxy-instance-ip: &lt;proxy-instance-ip&gt;
If this annotation is provided, it must hold the IP address the Istio Proxy
sidecar on the VM can bind its listener to. This typically is the IP address of
the interface that will receive incoming traffic originating from outside. If
the VM has an interface that is configured with a public IP address and this is
the same IP as the `address` property, this annotation can be omitted. Most
cloud providers the VMs do not have an interface that listens directly on a
public IP address, but on a private IP. In this case, you must configure the
internal IP address of the VM to which external incoming traffic is routed.

#### ssh-host: &lt;ssh-host&gt;
When you execute the `tctl` bootstrap command, `tctl` tries to connect to the VM
it needs to onboard. The default behavior is for `tctl` to use the IP address as
found in the `address` property. If the machine you run `tctl` on does not have
direct IP connectivity to that address, for instance in the case of `address`
holding a private IP address, you can set this optional `ssh-host` annotation.
In this case, provide the IP address or hostname that allows `tctl` to connect
over SSH to the VM.

In the ratings VM example we will assume the following:

- Kubernetes Cluster at cloud provider and VM on-prem
- External VM IP address is not directly bound on the machine
- Istio Proxy on VM Workload will listen on TCP port 9080
- `tctl` and Kubernetes can both reach the VM over the same external IP.
- VM internal IP: 10.128.0.2
- VM external IP:  35.194.38.142

Example `WorkloadEntry` using these assumptions looks like this:

<CodeBlock className="language-yaml">
  {ratingsWorkloadEntryYAML}
</CodeBlock>

Save as [`ratings-workloadentry.yaml`](../../assets/setup/ratings-workloadentry.yaml). You can add this file to source control or
apply directly to your cluster using `kubectl`:

```bash{userPrompt: Alice}
kubectl apply -f ratings-workloadentry.yaml
```

### Create a Sidecar

Now that we have configured our `WorkloadEntry` to provide information for
bootstrapping the onboarding process of the VM and IP connectivity, we need to
configure the VMs Istio Proxy sidecar. The [Sidecar](https://istio.io/latest/docs/reference/config/networking/sidecar/)
resource gives you control over the configuration of the Istio Proxy. In this
example the Sidecar configuration allows you to avoid using IPtables on the VM
for redirecting traffic.

The `Sidecar` example below shows the configuration for the ratings VM example,
listening on TCP port 9080.

<CodeBlock className="language-yaml">
  {ratingsSidecarYAML}
</CodeBlock>

Save as [`ratings-sidecar.yaml`](../../assets/setup/ratings-sidecar.yaml). You can add this file to source control or apply
directly to your cluster using `kubectl`:

```bash{userPrompt: Alice}
kubectl apply -f ratings-sidecar.yaml
```

### Onboard the VM

With both `WorkloadEntry` and `Sidecar` configured and applied to your
Kubernetes cluster, the VM workload is now registered with your service mesh.
With your VM and service mesh prepared, we can use `tctl` to complete the actual
onboarding process.

The `tctl` CLI will:

- Obtain a bootstrap security token and seed configuration from the service mesh
- Transfer this bootstrap security token and seed configuration to the VM
- Start Istio Proxy using the bootstrap security token and seed configuration

Since this onboarding process is complex, `tctl` implements a dry run feature.
It will allow you to inspect the process flow without actual execution. To see
what `tctl` is planning to do, run:

```bash{promptUser: Alice}{outputLines: 2-3}
tctl x sidecar-bootstrap ratings-vm.bookinfo \
    --start-istio-proxy \
    --dry-run
```

You'll see an output similar to below:

```
[SSH client] going to connect to istio-proxy@35.194.38.142:22

[SSH client] going to execute a command remotely: mkdir -p /etc/istio-proxy

[SSH client] going to copy into a remote file: /etc/istio-proxy/sidecar.env
JWT_POLICY=third-party-jwt
PROV_CERT=/var/run/secrets/istio
OUTPUT_CERTS=/var/run/secrets/istio
PILOT_CERT_PROVIDER=istiod
...
```

The dry run will output both generated configuration and commands that will be
run over SSH on the VM.

Once you're satisfied with the test, you can remove the `--dry-run` argument and
start the actual onboarding process like this:

```bash{promptUser: Alice}{outputLines: 2}
tctl x sidecar-bootstrap ratings-vm.bookinfo \
    --start-istio-proxy
```

An output similar to below will appear:

```
[SSH client] connecting to istio-proxy@35.194.38.142:22
[SSH client] executing a command remotely: mkdir -p /etc/istio-proxy
[SSH client] copying into a remote file: /etc/istio-proxy/sidecar.env
[SSH client] copying into a remote file: /etc/istio-proxy/k8s-ca.pem
[SSH client] copying into a remote file: /etc/istio-proxy/istio-ca.pem
[SSH client] copying into a remote file: /etc/istio-proxy/istio-token
[SSH client] executing a command remotely: docker rm --force istio-proxy
istio-proxy
[SSH client] executing a command remotely: docker run -d --name istio-proxy --restart unless-stopped --network host ...
[SSH client] closing connection
```

When done, you should see the generated configuration copied on the VM and a
Docker container with Istio Proxy started.

### VM Workload calling mesh services
The VM workload in this example does not need to initiate requests to services
inside the service mesh. In case your VM workload does, special considerations
need to be made with respect to egress routing. The Istio Proxy instance on your
VM is dynamically provided with a list of available services in the service
mesh. Since our example does not use `iptables` to automatically redirect
traffic to the Istio Proxy you will need to update your `/etc/hosts` file to
include the `FQDN` of each of the services your Workload needs to initiate
requests to and point them to the bind address of the egress listener.

Example of additions to `/etc/hosts`:

```
# direct the following services to the egress listener address
127.0.0.2 reviews.bookinfo.svc
127.0.0.2 www.example.org
```

For more information on this topic, please consult the
[IstioEgressListener](https://istio.io/latest/docs/reference/config/networking/sidecar/#IstioEgressListener)
reference.

## Testing workload traffic

To test if onboarding the VM succeeded and traffic is flowing between workloads
on VM and Kubernetes, you have multiple options. Next to inspecting logs of your
services to see if activity occurs, you can also use the TSB UI to look at the
various service metrics and the topology map. The values for the `app` and 
`version` labels you provided in the `WorkloadEntry` will be reflected in the
topology map and service metrics.

