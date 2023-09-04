---
title: Splitting Service Traffic between K8S and VMs
menu-title: Split Traffic between K8S & VMs
description: Set-up traffic routing between a service running both on a VM, and a Kubernetes cluster.
weight: 1
---

In this how-to you'll learn how to setup traffic routing between a service
running both on a VM, and a Kubernetes cluster. 

In this guide, you'll <br />
✓ Install the Istio demo `bookinfo` application in a cluster <br />
✓ Install the `ratings` service from the `bookinfo` application on a VM. <br />
✓ Split traffic 80/20 between the VM, and the cluster instances of the ratings application

Before you get started, make sure that you: <br />
✓ [Install TSB management plane](../../setup/self_managed/management-plane-installation) <br />
✓ Onboarded a [cluster](../../setup/self_managed/onboarding-clusters)<br />
✓ [Install data plane operator](../../concepts/operators/data_plane)

First, start by installing bookinfo in your cluster. 

```bash{outputLines: 3-4}
kubectl create ns bookinfo
kubectl apply -f \
    https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml \
    -n bookinfo
```

Follow the [VM onboarding docs](../../setup/workload_onboarding/onboarding-vms). 
During onboarding, run the Istio demo `ratings` app as your workload. 

```bash{outputLines: 2-4} 
sudo docker run -d \
    --name ratings \
    -p 127.0.0.1:9080:9080 \
    docker.io/istio/examples-bookinfo-ratings-v1.1:1.16.2
```

Create a workload entry for ratings,

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

and apply a sidecar.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: bookinfo-ratings-no-iptables
  namespace: bookinfo
spec:
  egress:
  - bind: 127.0.0.2
    hosts:
    - ./*
  ingress:
  - defaultEndpoint: 127.0.0.1:9080
    port:
      name: http
      number: 9080
      protocol: HTTP
  workloadSelector:
    labels:
      app: ratings
      class: vm
```

Once you've onboarded the VM, your mesh will distribute traffic between the
`ratings` app in the cluster and the VM, because the `ratings` service selects
any workload with the `app: ratings` label, and both our cluster `Deployment`
and `WorkloadEntry` have this label. You can verify that traffic is flowing 
through both apps using logs or in the UI topology dashboard.

Now lets fine tune the traffic so that 80% of it goes to the in cluster app, and
20% goes to the VM. `tctl apply -f` a file containing the following
configuration (filling in `<tenant>` and `<cluster>` based on your install).

:::note
You may already have a workspace set up (e.g. for ingress traffic). If that is
the case, you can omit this workspace and adjust the rest of the config
accordingly.
:::

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  name: bookinfo-ws
  tenant: <tenant>
spec:
  namespaceSelector:
    names:
    - <cluster>/bookinfo
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  name: bookinfo-tg
  workspace: bookinfo-ws
  tenant: <tenant>
spec:
  namespaceSelector:
    names:
      - "<cluster>/bookinfo"
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: ratings
  group: bookinfo-tg
  workspace: bookinfo-ws
  tenant: <tenant>
spec:
  service: bookinfo/ratings
  subsets:
  - name: v1
    labels:
      version: v1
    weight: 80
  - name: v3
    labels:
      version: v3
    weight: 20
```

After sending some traffic through the app, we can look at the services
dashboard or logs again to see that the traffic is being split 80/20 between
ratings `v1` and `v3`.
