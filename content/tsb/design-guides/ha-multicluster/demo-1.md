---
title: 演示环境
weight: 1
---

创建一个简单的示例，包括两个工作负载集群和一个边缘网关集群。

在这个示例中，我们将配置三个 Kubernetes 集群：

 * 集群 **cluster-1** 和 **cluster-2** 将作为工作负载集群，每个集群都有一个 **bookinfo** 应用程序实例和一个 **Ingress Gateway** 用于公开应用程序
 * 集群 **cluster-edge** 将托管前端边缘（"Tier-1"）网关，该网关将接收流量并分发到工作负载集群中的 Ingress Gateway

![边缘和工作负载负载均衡](../images/edge-workload.png)

#### 开始之前

在配置中有一些移动部分，因此在继续之前，识别并命名每个部分会很有帮助：

|                        | **cluster-1** | **cluster-2** | **cluster-edge** |
| ---------------------- | ------------- | ------------- | ---------------- |
| AWS 区域：             | eu-west-1     | eu-west-2     | eu-west-1        |
| 命名空间：              | bookinfo      | bookinfo      | edge             |
| 工作区：               | bookinfo-ws   | bookinfo-ws   | edge-ws          |
| 网络：                  | app-network   | app-network   | edge-network     |
| 网关组：                | bookinfo-gwgroup-1 | bookinfo-gwgroup-2 | edge-gwgroup |
| Ingress 网关：          | ingressgw-1   | ingressgw-2   | edgegw           |
| 网关资源：              | bookinfo-ingress-1 | bookinfo-ingress-2 | bookinfo-edge |
| Kubectl 上下文别名：   | `k1`          | `k2`          | `k3`             |

确保 **cluster-1** 和 **cluster-edge** 位于同一个区域，而 **cluster-2** 位于另一个区域；在测试集群故障转移时，这将会很有用。

在这个示例中，我们将使用组织 **tse** 和租户 **tse**。如果你使用 Tetrate Service Bridge (TSB)，请修改 Tetrate 配置以匹配你的组织层次结构。

{{<callout note "管理多个集群">}}

在处理多个 Kubernetes 集群时，为每个集群的 **kubectl** 命令创建一个别名可能很有用。例如，对于 AWS 上下文，你可以执行以下操作：

```bash
alias k1='kubectl --context arn:aws:eks:eu-west-1:901234567890:cluster/my-cluster-1'
```

在应用 Tetrate 配置时，不需要执行此操作，Tetrate 配置可以使用 `tctl` 应用，或者与支持 GitOps 集成的任何 Kubernetes 集群。
{{</callout>}}

### 先决条件

我们将假设以下初始配置：

 * 集群 **cluster-1**、**cluster-2** 和 **cluster-edge** 已经加入 Tetrate 平台，无论是 TSE 还是 TSB
 * 在每个集群上部署了任何必要的集成（例如 AWS 负载均衡控制器）
 * 如果使用 Tetrate Service Express，已在 **cluster-edge** 上部署了 **Route 53 控制器**

步骤：

1. 创建 Tetrate 配置：创建 Tetrate 工作区、网络和网关组
2. 在 cluster-1 中部署 bookinfo：在第一个集群中部署 bookinfo。部署一个 Ingress Gateway 和一个 Gateway 资源。
3. 在 cluster-2 中部署 bookinfo：重复，在第二个集群中部署 bookinfo。部署一个 Ingress Gateway 和一个 Gateway 资源。
4. 配置 Edge Gateway：在 Edge 集群中部署 Edge Gateway 和一个 Gateway 资源。如有必要，配置 DNS 并测试结果。

## 创建演示环境

### 创建 Tetrate 配置

我们将：

 1. 为两个工作负载集群创建一个工作区，每个集群都有一个网关组
 1. 为边缘集群创建一个工作区和网关组
 1. 配置 **cluster-edge** 为 Tier-1 集群
 1. 定义 Tetrate 网络和可达性配置

<details>
<summary>我们如何做...</summary>

#### 创建工作负载集群的配置

创建一个横跨两个工作负载集群的工作区 **bookinfo-ws**，以及每个集群的网关组。

```bash
cat <<EOF > bookinfo-ws.yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tse
  tenant: tse
  name: bookinfo-ws
spec:
  displayName: Bookinfo
  description: Test Bookinfo application
  namespaceSelector:
    names:
      - "cluster-1/bookinfo"
      - "cluster-2/bookinfo"
EOF

tctl apply -f bookinfo-ws.yaml


cat <<EOF > bookinfo-gwgroup-1.yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tse
  tenant: tse
  workspace: bookinfo-ws
  name: bookinfo-gwgroup-1
spec:
  namespaceSelector:
    names:
      - "cluster-1/bookinfo"
EOF

tctl apply -f bookinfo-gwgroup-1.yaml


cat <<EOF > bookinfo-gwgroup-2.yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tse
  tenant: tse
  workspace: bookinfo-ws
  name: bookinfo-gwgroup-2
spec:
  namespaceSelector:
    names:
      - "cluster-2/bookinfo"
EOF

tctl apply -f bookinfo-gwgroup-2.yaml
```

#### 创建边缘集群的配置

创建一个工作区 **edge-ws** 和一个边缘集群的网关组：

```bash
cat <<EOF > edge-ws.yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tse
  tenant: tse
  name: edge-ws
spec:
  namespaceSelector:
    names:
      - "cluster-edge/edge"
EOF

tctl apply -f edge-ws.yaml


cat <<EOF > edge-gwgroup.yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  tenant: tse
  organization: tse
  workspace: edge-ws
  name: edge-gwgroup
spec:
  namespaceSelector:
    names:
      - 'cluster-edge/edge'
EOF

tctl apply -f edge-gwgroup.yaml
```

#### 配置边缘集群为 Tier-1 集群

设置 Edge 集群的 "Is Tier 1" 标志。

通常，使用 Tetrate UI 更容易配置集群设置：

导航到 **Clusters**。编辑 **cluster-edge** 并将 '**Tier 1 Cluster?**' 字段设置为 **Yes**。保存更改：

![配置 cluster-edge 为 Tier-1 集群](../images/edge-tier1.png)

更新 **cluster-edge** 的 **Cluster** 配置，添加键 `spec: tier1Cluster: ` 如下所示：

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: cluster-edge
  organization: tse
spec:
# highlight-next-line
  tier1Cluster: true
```

#### 配置网络和可达性设置

Tetrate 平台使用网络设置来分组一组集群并定义访问控制列表。如果一个集群没有分配到网络，那么任何其他集群都可以访问该集群。在大规模操作时，网络设置提供了一种高级方式来标识一组集群并定义允许的流量。

我们将：

 1. 将 **cluster-edge** 分配给网络 **Edge-Network**
 1. 将 **cluster-1** 和 **cluster-2** 分配给网络 **App-Network**
 1. 定义可达性设置，以便 **Edge-Network** 可以向 **App-Network** 发送流量

通常，使用 Tetrate UI 配置网络设置更容易：

#### 分配网络

导航到 **Clusters**。编辑 **cluster-edge** 并将 **Network** 字段设置为值 **Edge-Network**。保存更改：

![将 cluster-edge 分配到网络 Edge-Network](../images/edge-network.png)

对于集群 **cluster-1** 和 **cluster-2**，重复此步骤，将它们分配到网络 **App-Network**。

#### 定义可达性

导航到 **Settings** 和 **Network Reachability**。指定 **Edge-Network** 允许连接（发送流量到）**App-Network**：

![定义可达性设置，以便 Edge-Network 可以发送流量到 App-Network](../images/reachability.png)

保存更改。

#### 分配网络

更新每个 **Cluster** 配置，添加键 `spec: network: ` 如下所示：

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: cluster-edge
  organization: tse
spec:
# highlight-next-line
  network: edge-network
```

#### 定义可达性

更新 **OrganizationSettings** 配置，添加如下的 networkReachability 部分：

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: OrganizationSetting
metadata:
  name: default
  organization: tse
spec:
  defaultSecuritySetting:
    authenticationSettings:
      trafficMode: REQUIRED
    authorization:
      mode: RULES
      rules: {}
  fqn: organizations/tse/settings/default
# highlight-start
  networkSettings:
    networkReachability:
      Edge-Network: App-Network
# highlight-end
```

**OrganizationSettings** 资源是一个内部对象；你可以使用 `tctl get organizationsettings -o yaml` 获取它。在提交更新之前，删除任何 **resourceVersion** 或 **etag** 值。

</details>

#### 检查你的更改

完成更改后，UI 中的集群页面应如下所示：

![集群摘要](../images/cluster-summary.png)

请注意每个集群的 **Network** 和 **Is Tier1** 列以及其值。

此外，你将为每个集群创建了工作区和网关组，并定义了可达性设置，以使 **Edge-Network** 可以访问 **App-Network**。

### 在 cluster-1 中部署 Bookinfo

![在 Cluster 1 中的 BookInfo](../images/cluster-1-config.png)

我们将：

1. 创建 **bookinfo** 命名空间并部署 **BookInfo** 应用程序
2. 在集群中部署一个 **Ingress Gateway**
3. 发布一个 **Gateway** 资源以暴露 **productpage.bookinfo** 服务
4. 验证服务是否正常运行

请记住设置 kubectl 上下文或使用你的上下文别名来指向 **cluster-1**。

<details>
<summary>操作步骤...</summary>

#### 创建 bookinfo 命名空间并部署 Bookinfo 应用程序：

```bash
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
kubectl apply -n bookinfo -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml

sleep 10

kubectl exec "$(kubectl get pod -n bookinfo -l app=ratings -o jsonpath='{.items[0].metadata.name}')" \
   -n bookinfo -c ratings -- curl -s productpage:9080/productpage
```

注意：最后一个 shell 命令验证 **BookInfo** 应用程序是否正确部署和运行。

#### 在集群中部署 Ingress Gateway

我们将在集群的 **bookinfo** 命名空间中部署一个 Ingress Gateway **ingressgw-1**：

```bash
cat <<EOF > ingressgw-1.yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: ingressgw-1
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      type: LoadBalancer
EOF

kubectl apply -f ingressgw-1.yaml
```

#### 发布一个 Gateway 资源以暴露 productpage.bookinfo

我们将在集群中的 Gateway 组中发布一个 Gateway 资源，引用我们刚刚部署的 Ingress Gateway。

使用 **tctl** 或 **kubectl**（如果在该集群上启用了 GitOps）：

```bash
cat <<EOF > bookinfo-ingress-1.yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  organization: tse
  tenant: tse
  workspace: bookinfo-ws
  group: bookinfo-gwgroup-1
  name: bookinfo-ingress-1
spec:
  workloadSelector:
    namespace: bookinfo
    labels:
      app: ingressgw-1
  http:
  - name: bookinfo
    port: 80
    hostname: bookinfo.tse.tetratelabs.io
    routing:
      rules:
      - route:
          serviceDestination:
            host: bookinfo/productpage.bookinfo.svc.cluster.local
            port: 9080
EOF


tctl apply -f bookinfo-ingress-1.yaml
```

```bash
cat <<EOF > bookinfo-ingress-1.yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: bookinfo-ingress-1
  annotations:
    tsb.tetrate.io/organization: tse
    tsb.tetrate.io/tenant: tse
    tsb.tetrate.io/workspace: bookinfo-ws
    tsb.tetrate.io/gatewayGroup: bookinfo-gwgroup-1
spec:
  workloadSelector:
    namespace: bookinfo
    labels:
      app: ingressgw-1
  http:
    - name: bookinfo
      port: 80
      hostname: bookinfo.tse.tetratelabs.io
      routing:
        rules:
          - route:
              serviceDestination:
                host: bookinfo/productpage.bookinfo.svc.cluster.local
                port: 9080
EOF

kubectl apply -f bookinfo-ingress-1.yaml
```

</details>

#### 验证服务是否正常运行

通过 Ingress Gateway 发送 HTTP 请求来检查 **cluster-1** 上的服务是否正常运行到 **productpage** 服务：

```bash
export GATEWAY_IP=$(kubectl -n bookinfo get service ingressgw-1 -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
echo $GATEWAY_IP

curl -s --connect-to bookinfo.tse.tetratelabs.io:80:$GATEWAY_IP \
    "http://bookinfo.tse.tetratelabs.io/productpage" 
```

注意：Ingress Gateway 可能需要一个云负载均衡器，并且你可能需要等待几分钟以完成云负载均衡器的配置。


### 在 cluster-2 中部署 Bookinfo

![在 Cluster 2 中的 BookInfo](../images/cluster-2-config.png)

我们将重复上述步骤来针对 **cluster-2** 进行操作，确保参考了 **cluster-2** 的 **GatewayGroup**、**IngressGateway** 和 **Gateway** 资源。

请记住设置 kubectl 上下文或使用你的上下文别名来指向 **cluster-2**。

<details>
<summary>操作步骤...</summary>

#### 创建 bookinfo 命名空间并部署 Bookinfo 应用程序：

```bash
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
kubectl apply -n bookinfo -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml
sleep 10
kubectl exec "$(kubectl get pod -n bookinfo -l app=ratings -o jsonpath='{.items[0].metadata.name}')" \
   -n bookinfo -c ratings -- curl -s productpage:9080/productpage
```

#### 在集群中部署 Ingress Gateway

```bash
cat <<EOF > ingressgw-2.yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: ingressgw-2
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      type: LoadBalancer
EOF

kubectl apply -f ingressgw-2.yaml
```

#### 发布一个 Gateway 资源以暴露 productpage.bookinfo

```bash
cat <<EOF > bookinfo-ingress-2.yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  organization: tse
  tenant: tse
  workspace: bookinfo-ws
  group: bookinfo-gwgroup-2
  name: bookinfo-ingress-2
spec:
  workloadSelector:
    namespace: bookinfo
    labels:
      app: ingressgw-2
  http:
  - name: bookinfo
    port: 80
    hostname: bookinfo.tse.tetratelabs.io
    routing:
      rules:
      - route:
          serviceDestination:
            host: bookinfo/productpage.bookinfo.svc.cluster.local
            port: 9080
EOF


tctl apply -f bookinfo-ingress-2.yaml
```

```bash
cat <<EOF > bookinfo-ingress-2.yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: bookinfo-ingress-2
  annotations:
    tsb.tetrate.io/organization: tse
    tsb.tetrate.io/tenant: tse
    tsb.tetrate.io/workspace: bookinfo-ws
    tsb.tetrate.io/gatewayGroup: bookinfo-gwgroup-2
spec:
  workloadSelector:
    namespace: bookinfo
    labels:
      app: ingressgw-2
  http:
    - name: bookinfo
      port: 80
      hostname: bookinfo.tse.tetratelabs.io
      routing:
        rules:
          - route:
              serviceDestination:
                host: bookinfo/productpage.bookinfo.svc.cluster.local
                port: 9080
EOF

kubectl apply -f bookinfo-ingress-2.yaml
```
</details>

#### 验证服务是否正常运行 

对 **cluster-2** 进行如下测试：

```bash
export GATEWAY_IP=$(kubectl -n bookinfo get service ingressgw-2 -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
echo $GATEWAY_IP

curl -s --connect-to bookinfo.tse.tetratelabs.io:80:$GATEWAY_IP \
    "http://bookinfo.tse.tetratelabs.io/productpage" 
```


### 配置 Edge Gateway

![Edge Cluster 中的 Edge Gateway](../images/edge-config.png)

我们将：

* 创建 **edge** 命名空间
* 在集群中部署一个 **Edge Gateway**
* 发布一个 **Gateway** 资源来均衡流量跨工作负载集群
* 验证服务是否正常运行

如果你正在使用 TSE 的 **Route 53 Controller** 来自动管理 DNS，请记住首先在此集群上启用它。任何公共 DNS 应指向此集群上的 Edge Gateway。

请记住设置 kubectl 上下文或使用你的上下文别名来指向 **cluster-edge**。

<details>
<summary>操作步骤...</summary>

#### 创建 edge 命名空间

```bash
kubectl create namespace edge
kubectl label namespace edge istio-injection=enabled
```

#### 在集群中部署 Edge Gateway

```bash
cat <<EOF > edgegw.yaml
apiVersion: install.tetrate.io/v1alpha1
kind: Tier1Gateway
metadata:
  name: edgegw
  namespace: edge
spec:
  kubeSpec:
    service:
      type: LoadBalancer
EOF

kubectl apply -f edgegw.yaml
```

#### 发布一个 Gateway 资源来均衡流量跨工作负载集群

```bash
cat <<EOF > bookinfo-edge.yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  organization: tse 
  tenant: tse
  workspace: edge-ws
  group: edge-gwgroup
  name: bookinfo-edge
spec:
  workloadSelector:
    namespace: edge
    labels:
      app

: edgegw
  http:
    - name: bookinfo
      port: 80
      hostname: bookinfo.tse.tetratelabs.io
      routing:
        rules:
          - route:
              clusterDestination: {}
EOF

tctl apply -f bookinfo-edge.yaml
```

```bash
cat <<EOF > bookinfo-edge..yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: bookinfo-edge
  annotations:
    tsb.tetrate.io/organization: tse
    tsb.tetrate.io/tenant: tse
    tsb.tetrate.io/workspace: edge-ws
    tsb.tetrate.io/gatewayGroup: edge-gwgroup
spec:
  workloadSelector:
    namespace: edge
    labels:
      app: edgegw
  http:
    - name: bookinfo
      port: 80
      hostname: bookinfo.tse.tetratelabs.io
      routing:
        rules:
          - route:
              clusterDestination: {}
EOF

kubectl apply -f bookinfo-edge.yaml
```

</details>

#### 验证服务是否正常运行

我们将发送测试流量到 **cluster-edge** 上的 Edge Gateway：

```bash
export GATEWAY_IP=$(kubectl -n edge get service edgegw -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
echo $GATEWAY_IP

curl -s --connect-to bookinfo.tse.tetratelabs.io:80:$GATEWAY_IP \
    "http://bookinfo.tse.tetratelabs.io/productpage" 
```

如果你已经配置了 DNS 以指向 Edge Gateway（例如，使用 TSE 的 Route 53 Controller），你可以直接测试服务：

```bash
curl http://bookinfo.tse.tetratelabs.io/productpage
```

请记住你可能需要等待几分钟，直到云负载均衡器完成配置。


## 下一步

你现在可以尝试 [工作负载集群故障转移](../cluster-failover) 行为。
