---
title: 使用 Tier-1 网关进行多集群流量切换
description: 部署 Tier-1 网关并使用它在多个集群之间切换流量
weight: 7
---

本文档描述了如何使用 [Tier-1 网关](../../../concepts/glossary/) 进行多集群流量切换。你将创建一个用于 Tier-1 网关部署的集群，以及两个用于运行 [bookinfo 应用程序](../../../quickstart/deploy-sample-app) 的集群。

每个应用程序集群都将配置一个 [入口网关](../../../concepts/glossary/)，用于将流量路由到 bookinfo 应用程序。最后，你将配置 Tier-1 网关，将流量从一个集群上运行的应用程序切换到另一个集群上运行的应用程序。

在开始之前，请确保你已经：
- 熟悉了 [TSB 概念](../../../concepts/)
- 熟悉了 [TSB 管理平面](../../../concepts/glossary/) 和 [集群载入](../../../setup/self-managed/onboarding-clusters)。以下场景将假定你已经安装了 TSB 管理平面，并且已经将 `tctl` 配置为正确的管理平面。

{{<callout note "Kubernetes 供应商">}}
以下场景在 GKE Kubernetes 集群上进行了测试。然而，这里描述的步骤应该足够通用，可以在其他 Kubernetes 供应商上使用。
{{</callout>}}

{{<callout warning 证书>}}
本场景使用自签名证书来进行 Istio CA。这里的说明仅供演示目的。对于生产集群设置，强烈建议使用生产就绪的 CA。
{{</callout>}}

## Tier-1 网关

在 TSB 中，有两种接收入站流量的网关类型：Tier-1 网关和 Ingress 网关（也称为 Tier-2 网关）。Tier-1 网关将流量分发到其他集群中一个或多个 Ingress 网关，使用 Istio mTLS 进行通信。Ingress 网关将流量路由到部署了网关的集群中运行的一个或多个工作负载（业务应用服务）。

关于 Tier-1 部署，有一些需要注意的地方：

首先，默认情况下，*部署了 Tier-1 网关的集群不能包含其他网关或工作负载*。你必须使用专用集群进行 Tier-1 部署。从 TSB 1.6 开始，你可以通过允许在任何工作负载集群中部署 Tier-1 网关来放宽此要求。参见 [在应用程序集群中运行 Tier1 网关](../../../operations/features/tier1-in-app-cluster)。

*在部署 Tier-1 和应用程序的集群上运行的 Istio 必须共享相同的根 CA*。有关如何为多个集群上的 Istio 设置根和中间 CA，请参阅 Istio 文档中的 [插入 CA 证书](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/)。TSB 控制平面 Operator 将部署 Istio，并且 Istio 的 CA 将从插入 CA 证书步骤中描述的 secrets-mount 文件中读取证书。

*应用程序必须在两个集群中的相同命名空间中部署*。这是因为你将为两个应用程序集群使用相同的 Ingress 网关配置。

## 准备集群

下面的图像显示了你将在本文档中使用的部署架构。管理平面应该已经部署好了。

![](../../../assets/howto/tier1-tier2-diagram.svg)

你将创建一个 Tier-1 网关集群和两个应用程序集群。每个应用程序集群都有一个 Ingress 网关和应用程序工作负载。

在你的云提供商中，创建上述三个集群：一个用于 Tier-1 网关，两个用于应用程序。

然后，根据 [插入 CA 证书](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/) 文档的描述，在每个集群中插入证书和密钥。

{{<callout note "应用程序集群中的 Tier1 网关">}}
如果启用了 [在应用程序集群中运行 Tier1 网关](../../../operations/features/tier1-in-app-cluster)，你只能有两个集群。你需要调整后续步骤中的载入集群 YAML 和 `tier1` 工作区的命名空间选择器以适应这种情况。如果你选择将相同的网络分配给你的集群，网络可达性可能不相关。

{{</callout>}}

## 载入 Tier-1 网关和应用程序集群

创建一个名为 [traffic-shifting-clusters.yaml](../../../assets/howto/traffic-shifting-clusters.yaml) 的文件，其中包含以下内容。这将为我们的使用创建集群资源：Tier-1 集群命名为 `t1`，应用程序集群命名为 `c1` 和 `c2`。稍后在 TSB 配置对象中引用它们时，你将需要使用这些名称。

<details>
<summary>traffic-shifting-clusters.yaml</summary>

```yaml
# Application cluster 1.
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: c1
  organization: tetrate
spec:
  displayName: 'Cluster 1'
  network: tier2
---
# Application cluster 2.
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: c2
  organization: tetrate
spec:
  displayName: 'Cluster 2'
  network: tier2
---
# Tier-1 cluster
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: t1
  organization: tetrate
spec:
  displayName: 'Tier-1 Cluster'
  network: tier1
  tier1Cluster: true
```
</details>

使用 `tctl` 应用这些内容：

```
tctl apply -f traffic-shifting-clusters.yaml
```

### 网络可达性

一个集群具有一个 `network` 字段，表示像 AWS/GCP/Azure 上的 VPC 之类的网络边界。同一网络中的所有集群都被假定为可以互相访问，用于多集群路由。如果

你的集群位于不同的网络中，则必须适当配置它们，以使它们可以相互访问。

请注意，在你创建的集群资源中，Tier-1 集群和应用程序集群已分配了不同的网络：Tier-1 集群的网络是 `tier1`，而两个应用程序集群的网络是 `tier2`。

你将使用这些网络名称来告诉 TSB `tier1` 和 `tier2` 是可达的。创建一个名为 [organization-settings.yaml](../../../assets/howto/traffic-shifting-organization-settings.yaml) 的文件，其中包含以下内容。

<details>
<summary>organization-settings.yaml</summary>

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: OrganizationSetting
metadata:
  name: tetrate-settings
  organization: tetrate
spec:
  networkSettings:
    networkReachability:
      # clusters that belong to tier1 networks can reach
      # clusters that belong to tier2 networks.
      tier1: tier2
```
</details>

使用 `tctl` 应用这些内容：

```
tctl apply -f organization-settings.yaml
```

### 在集群中安装控制平面组件

此时，集群已经注册到 TSB，但尚未载入。要载入这些集群，请按照使用 [Helm](../../../setup/helm/controlplane) 或 [tctl](../../../setup/self-managed/onboarding-clusters) 的方法进行集群载入步骤。

当所有集群都正确载入时，你应该在 TSB UI 中看到以下信息。请注意，集群正在报告 Istio 和 TSB 代理的版本。

![](../../../assets/howto/tsb-ui-tier1-two-applications.png)

## 部署应用程序和 Ingress 网关到应用程序集群

对于两个应用程序集群，执行以下操作：

1. 部署 [bookinfo 应用程序](../../../quickstart/deploy-sample-app)
2. 部署 Ingress 网关

要部署 Ingress 网关，请创建一个名为 [`bookinfo-ingress-deploy.yaml`](../../../assets/howto/traffic-shifting-bookinfo-ingress-deploy.yaml) 的文件，其中包含以下内容：

<details>
<summary>bookinfo-ingress-deploy.yaml</summary>
```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: tsb-gateway-bookinfo
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      type: LoadBalancer
```
</details>

使用 `kubectl` 应用这些内容：

```
kubectl apply -f bookinfo-ingress-deploy.yaml
```

确保在应用 YAML 文件时将 `kubectl` 指向正确的集群。

{{<callout note 部署和配置>}}
请注意，在部署应用程序和 Ingress 网关时，我们使用 `kubectl`。在 TSB 中，部署和配置是不同的概念，分别以不同的方式处理。你直接使用 `kubectl` 部署到集群，并通过 TSB 管理平面使用 `tctl` 进行配置。
{{</callout>}}

{{<callout note 网关服务类型>}}
在此示例中，我们使用负载均衡器作为网关服务类型。根据你的 Kubernetes 环境（例如，裸机），你可能需要使用 NodePort。

通常，负载均衡器类型在云提供商中都是可用的。在 GKE 上，这将启动一个网络负载均衡器，该负载均衡器将为你提供一个单独的 IP 地址，将所有流量转发到你的服务。如果在自己的基础设施上使用 Kubernetes，而不安装像 MetalLB 或 PureLB 这样的负载均衡器服务，那么你将需要使用 NodePort。NodePort 在所有节点（虚拟机）上打开一个特定的端口，任何发送到此端口的流量都将转发到服务。
{{</callout>}}

## 租户和工作区

在这个示例中，你将把 Tier-1 网关关联到一个 [工作区](../../../concepts/glossary/)，将两个 Ingress 网关关联到另一个工作区。你应该确保工作区和工作区所属的 [租户](../../../concepts/glossary/) 都已经正确配置。

### 创建租户

如果你已经在 TSB 中配置了一个租户，可以跳过此部分。

创建一个名为 [`traffic-shifting-tenant.yaml`](../../../assets/howto/traffic-shifting-tenant.yaml) 的文件，其中包含以下内容。

<details>
<summary>traffic-shifting-tenant.yaml</summary>
```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: tetrate
  name: tetrate
```
</details>

使用 `tctl` 应用这些内容：

```
tctl apply -f traffic-shifting-tenant.yaml
```

## 创建工作区

创建工作区以关联网关。创建一个名为 [`traffic-shifting-workspaces.yaml`](../../../assets/howto/traffic-shifting-workspaces.yaml) 的文件。

<details>
<summary>traffic-shifting-workspaces.yaml</summary>
```yaml
# workspace for bookinfo
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  tenant: tetrate
  organization: tetrate
  name: bookinfo-workspace
spec:
  description: for bookinfo
  displayName: bookinfo
  namespaceSelector:
    names:
      - 'c1/bookinfo'
      - 'c2/bookinfo'
---
# workspace for tier-1
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  tenant: tetrate
  organization: tetrate
  name: tier1-workspace
spec:
  description: for tier1
  displayName: tier1
  namespaceSelector:
    names:
      - 't1/tier1'
```
</details>

使用 `tctl` 应用这些内容：

```
tctl apply -f traffic-shifting-workspaces.yaml
```

如果要使用现有的工作区，可以更新工作区以包括你刚刚创建的集群和命名空间，方法是更新工作区命名空间选择器。

## 配置 Ingress 网关

接下来，你将配置 Ingress 网关以接收两个应用程序集群中的 bookinfo 应用程序的流量。

在配置 Ingress 网关之前，请使用 [此脚本](../../../quickstart/ingress-gateway) 创建一个 TLS 证书。确保在两个应用程序集群的 `bookinfo` 命名空间中创建这些证书的 secrets。

创建一个名为 [`traffic-shifting-bookinfo-ingress-config.yaml`](../../../assets/howto/traffic-shifting-bookinfo-ingress-config.yaml) 的文件。

<details>
<summary>traffic-shifting-bookinfo-ingress-config.yaml</summary>

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  tenant: tetrate
  organization: tetrate
  workspace: bookinfo-workspace
  name: bookinfo-gateway-group
spec:
  displayName: bookinfo-gateway-group
  description: for bookinfo-gateway
  namespaceSelector:
    names:
      - 'c1/bookinfo'
      - 'c2/bookinfo'
  configMode: BRIDGED
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: bookinfo-gateway
  group: bookinfo-gateway-group
  workspace: bookinfo-workspace
  tenant: tetrate
  organization: tetrate
spec:
  workloadSelector:
    namespace: bookinfo
    labels:
      app: tsb-gateway-bookinfo
  http:
    - name: bookinfo-gateway
      port: 443
      hostname: bookinfo.tetrate.com
      tls:
        mode: SIMPLE
        # make sure to use correct secret name that you created previously
        secretName: bookinfo-certs
      routing:
        rules:
          - route:
              host: 'bookinfo/productpage.bookinfo.svc.cluster.local'
              port: 9080
```
</details>

```
tctl apply -f traffic-shifting-bookinfo-ingress-config.yaml
```

Ingress 网关配置将自动推送到两个应用程序集群，因为上面的配置在 `Group` 对象的 `namespaceSelector` 部分指定了集群。

## 部署和配置 Tier-1 网关

创建一个名为 [`traffic-shifting-tier1-deploy.yaml`](../../../assets/howto/traffic-shifting-tier1-deploy.yaml) 的文件，其中包含以下内容。

<details>
<summary>traffic-shifting-tier1-deploy.yaml</summary>

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  tenant: tetrate
  organization: tetrate
  workspace: tier1-workspace
  name: tier1-gateway-group
spec:
  displayName: tier1-gateway-group
  description: for tier1-gateway-group
  namespaceSelector:
    names:
      - 't1/tier1'
  configMode: BRIDGED
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
  name: tier1-gateway
  group: tier1-gateway-group
  workspace: tier1-workspace
  tenant: tetrate
  organization: tetrate
spec:
  workloadSelector:
    namespace: tier1
    labels:
      app: tier1-gateway
  externalServers:
    - hostname: bookinfo.tetrate.com
      name: bookinfo
      port: 443
      tls:
        mode: SIMPLE
        # make sure to use correct secret name that you created previously
        secretName: bookinfo-certs
      clusters:
        - name: c1
          weight: 100
```
</details>

使用 `kubectl` 部署这些内容：

```
kubectl apply -f traffic-shifting-tier1-deploy.yaml
```

创建一个名为 [`traffic-shifting-tier1-config.yaml`](../../../assets/howto/traffic-shifting-tier1-config.yaml) 的文件，其中包含以下内容。

<details>
<summary>traffic-shifting-tier1-config.yaml</summary>

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  tenant: tetrate
  organization: tetrate
  workspace: tier1-workspace
  name: tier1-gateway-group
spec:
  displayName: tier1-gateway-group
  description: for tier1-gateway-group
  namespaceSelector:
    names:
      - 't1/tier1'
  configMode: BRIDGED
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
  name: tier1-gateway
  group: tier1-gateway-group
  workspace: tier1-workspace
  tenant: tetrate
  organization: tetrate
spec:
  workloadSelector:
    namespace: tier1
    labels:
      app: tier1-gateway
  externalServers:
    - hostname: bookinfo.tetrate.com
      name: bookinfo
      port: 443
      tls:
        mode: SIMPLE
        # make sure to use correct secret name that you created previously
        secretName: bookinfo-certs
      clusters:
        - name: c1
          weight: 100
```
</details>

你将使用之前为 Ingress 网关创建的相同的 bookinfo TLS 证书。在以下的 YAML 中，你将所有传入的流量路由到第一个应用程序集群，这个集群在前面的步骤中命名为 `c1`。

使用 `tctl` 配置 Tier-1 网关：

```
tctl apply -f traffic-shifting-tier1-config.yaml
```

此时，你应该能够向 Tier-1 网关发送请求。使用 Tier-1 集群的 kubeconfig 获取 Tier-1 公共 IP 地址。

```bash
export GATEWAY_IP=$(kubectl -n tier1 get service tier1-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl "https://bookinfo.tetrate.com/productpage" --resolve "bookinfo.tetrate.com:443:${GATEWAY_IP}" -v --cacert bookinfo-ca.crt
```

## 流量切换

现在，你已经安装并配置了 Tier-1 网关，可以使用它来配置流量切换。流量切换是逐渐将流量从一个版本迁移到另一个版本的应用程序或服务的操作。

在之前的配置中，来自 Tier-1 网关的所有流量都被路由到运行在集群 `c1` 中的 bookinfo 应用程序的 Ingress 网关。假设你有一个更新版本的 bookinfo 应用程序，它运行在另一个集群 `c2` 中。

在这种情况下，通常希望配置只将少量流量路由到新的集群 `c2`，以便你可以测试并观察新集群中的应用程序是否按预期工作。当你验证没有问题后，可以逐渐增加路由到 `c2` 的流量百分比，直到所有流量都路由到 `c2` 为止。然后，可以安全地停用 `c1`。

要将应用程序流量从集群 `c1` 切换到集群 `c2`，创建一个名为 [`traffic-shifting-tier1-config2.yaml`](../../../assets/howto/traffic-shifting-tier1-config2.yaml)（或者你可以编辑之前的配置文件），然后使用 `tctl` 应用。

<details>
<summary>traffic-shifting-tier1-config2.yaml</summary>

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  tenant: tetrate
  organization: tetrate
  workspace: tier1-workspace
  name: tier1-gateway-group
spec:
  displayName: tier1-gateway-group
  description: for tier1-gateway-group
  namespaceSelector:
    names:
      - 't1/tier1'
  configMode: BRIDGED
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
  name: tier1-gateway
  group: tier1-gateway-group
  workspace: tier1-workspace
  tenant: tetrate
  organization: tetrate
spec:
  workloadSelector:
    namespace: tier1
    labels:
      app: tier1-gateway
  externalServers:
    - hostname: bookinfo.tetrate.com
      name: bookinfo
      port: 443
      tls:
        mode: SIMPLE
        # make sure to use correct secret name that you created previously
        secretName: bookinfo-certs
      clusters:
        - name: c1
          weight: 90
        - name: c2
          weight: 10
```
</details>

下面是原始 YAML 和新 YAML 之间的差异。请注意，`Group` 定义已再次包含在其中，但可以省略。

```
@@ -36,4 +36,6 @@
       secretName: bookinfo-certs
     clusters:
     - name: c1
-      weight: 100
+      weight: 90
+    - name: c2
+      weight: 10
```

使用此配置，Tier-1 网关将路由 10% 的流量到集群 `c2` 中的 Ingress 网关，将 90% 的流量路由到集群 `c1`。然后，你可以逐渐增加路由到 `c2` 的流量，直到达到 100%。
