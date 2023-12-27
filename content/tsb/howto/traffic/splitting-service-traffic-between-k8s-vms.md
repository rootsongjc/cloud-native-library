---
title: "在 Kubernetes 和虚拟机之间切分流量"
weight: 1
---

本文将教你如何设置在虚拟机和 Kubernetes 集群上运行的服务之间的流量路由。

在本指南中，你将：

- 在集群中安装 Istio 演示`bookinfo`应用程序
- 在虚拟机上安装`bookinfo`应用程序的`ratings`服务
- 将流量在虚拟机和集群中的`ratings`应用程序之间进行 80/20 的分流

在开始之前，请确保你已经：

- [安装了 TSB 管理平面](../../../setup/self-managed/management-plane-installation)
- 对一个[集群进行了载入](../../../setup/self-managed/onboarding-clusters)
- [安装了数据面 Operator](../../../concepts/operators/data-plane)

首先，从在你的集群中安装 bookinfo 开始。

```bash
kubectl create ns bookinfo
kubectl apply -f \
    https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml \
    -n bookinfo
```

遵循[VM 载入文档](../../../setup/workload-onboarding/onboarding-vms)。在载入过程中，将 Istio 演示的`ratings`应用程序作为你的工作负载运行。

```bash
sudo docker run -d \
    --name ratings \
    -p 127.0.0.1:9080:9080 \
    docker.io/istio/examples-bookinfo-ratings-v1.1:1.16.2
```

为`ratings`创建一个工作负载入口，

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
   app: ratings   # 用于通过 TSB 进行可观测性的必需标签
   version: v3    # 用于通过 TSB 进行可观测性的必需标签
 serviceAccount: bookinfo-ratings
 network: <vm-network-name>
```

并应用一个 Sidecar。

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

一旦你载入了虚拟机，你的 Mesh 将在集群中的`ratings`应用程序和虚拟机之间分发流量，因为`ratings`服务选择任何带有`app: ratings`标签的工作负载，而我们的集群`Deployment`和`WorkloadEntry`都有这个标签。你可以通过日志或 UI 拓扑仪表板来验证流量正流经这两个应用程序。

现在，让我们微调流量，使 80% 的流量流向集群中的应用程序，而 20% 流向虚拟机。使用包含以下配置的文件运行`tctl apply -f`（根据你的安装填写`<tenant>`和`<cluster>`）。

{{<callout note 注意>}}
你可能已经设置了一个工作空间（例如用于入口流量）。如果是这样，你可以省略此工作空间并相应地调整其余配置。
{{</callout>}}

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

在发送一些流量通过应用程序后，我们可以再次查看服务仪表板或日志，以查看流量在`v1`和`v3`之间以 80/20 的比例分配。
