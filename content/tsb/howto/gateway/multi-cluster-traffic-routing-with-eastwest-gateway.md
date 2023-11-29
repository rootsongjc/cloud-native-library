---
title: 使用东西网关实现多集群流量故障转移
weight: 5
---

通过东西网关，任何内部服务都可以实现高可用性，实现自动的跨集群故障转移，而无需通过入口网关将其发布为对外访问的服务。

在本指南中，你将会：

- 在一个集群 `cluster-1` 中部署 [bookinfo 应用程序](https://istio.io/latest/docs/examples/bookinfo/)。然后在第二个集群 `cluster-2` 中部署相同的 bookinfo 应用程序。
- 使 `cluster-1` 中的 reviews、details 或 ratings 服务失败，并观察到 bookinfo 应用程序的失败情况。
- 将 reviews、details 和 ratings 服务添加到东西网关。
- 重复故障场景并观察应用程序不受影响，内部流量路由到 `cluster-2` 中的服务。

## 了解东西网关

东西网关是外部面向的入口网关（Tier-1 或 Tier-2 网关）的替代方案。东西网关是本地于集群的，不会自动向外部流量公开。东西网关不需要入口网关所需的资源，例如公共 DNS、公共 TLS 证书和入口配置。

- **使用入口网关** 用于可以外部访问且具有公共 DNS、TLS 证书和 URL 的服务。使用 **Tier 1 网关** 或全局服务器负载均衡（GSLB）解决方案，使这些服务具有高可用性。
- **使用东西网关** 用于任何内部服务，这些服务应具有高可用性，具有跨集群故障转移。东西网关易于快速配置，并为服务提供高可用性，而不需要显式的服务配置。

当将服务添加到东西网关时，Tetrate Service Bridge 会维护这些服务的内部注册表。东西网关与工作空间关联，默认情况下，所有服务都与网关注册。

当本地客户端尝试访问服务时，它将被路由到本地服务实例。如果本地服务失败并且远程集群中存在具有东西网关的备用实例，TSB 将路由客户端流量到远程东西网关。服务发现、健康检查和故障转移路由完全自动化，对服务的开发人员或最终用户是透明的。

## 载入集群

要使用东西路由，你需要载入至少两个集群到 TSB 中。这两个集群必须位于不同的可用区或不同的区域。有关如何载入集群的更多详细信息，请参见[集群载入](../../../setup/self-managed/onboarding-clusters)。

确保这两个集群共享相同的信任根。在部署两个集群的控制平面之前，你必须在 `cacerts` 中填充正确的证书。有关详细信息，请参阅 Istio 文档中的 [Plugin CA Certificates](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/)。

{{<callout note "DNS 外部地址注释">}}
如果你希望使用 DNS 主机名进行东西网关（`cluster-external-addresses` 注释）的配置，你还需要[在 XCP 边缘启用 DNS 解析](../../../operations/features/edge-dns-resolution)，以便在 XCP 边缘进行 DNS 解析。
{{</callout>}}

## 配置

在本示例中，假设你已经有一个名为 `tetrate` 的组织、一个名为 `tetrate` 的租户，以及两个控制平面集群 `cluster-1` 和 `cluster-2`。

### 将 Bookinfo 部署到集群 1

创建带有 istio-injection 标签的 `bookinfo` 命名空间：

```bash
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
```

部署 bookinfo 应用程序：

```bash
kubectl apply -n bookinfo -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml
```

创建 bookinfo 工作空间。创建以下 `workspace.yaml`：

```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: tetrate
  name: bookinfo-ws
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
```

使用 `tctl` 应用：

```bash
tctl apply -f bookinfo-ws.yaml
```

### 测试 Bookinfo，并模拟 `details` 服务的故障

你将使用 [sleep 服务](../../../reference/samples/sleep-service) 作为客户端。

```bash
kubectl create namespace sleep
kubectl label namespace sleep istio-injection=enabled
kubectl apply -n sleep -f https://raw.githubusercontent.com/istio/istio/master/samples/sleep/sleep.yaml
```

发送请求到 bookinfo 的 productpage：

```bash
kubectl exec deployment/sleep -n sleep -c sleep -- curl -s http://productpage.bookinfo:9080/productpage | grep -i details -A 8
```

你将看到以下响应，指示 `productpage` 服务可以从 `details` 服务获取书籍详细信息：

```bash
      <h4 class="text-center text-primary">Book Details</h4>
      <dl>
        <dt>Type:</dt>paperback
        <dt>Pages:</dt>200
        <dt>Publisher:</dt>PublisherA
        <dt>Language:</dt>English
        <dt>ISBN-10:</dt>1234567890
        <dt>ISBN-13:</dt>123-1234567890
      </dl>
```

通过终止 `details` 微服务来模拟故障：

```bash
kubectl scale deployment details-v1 -n bookinfo --replicas=0
```

重新测试并观

察到由于组件服务已失败，对 bookinfo 的 productpage 的请求生成错误：

```bash
kubectl exec deployment/sleep -n sleep -c sleep -- curl -s http://productpage.bookinfo:9080/productpage | grep -i details -A 8
```

你将看到以下响应，显示 `productpage` 服务无法从 `details` 服务获取书籍详细信息：

```bash
      <h4 class="text-center text-primary">Error fetching product details!</h4>

      <p>Sorry, product details are currently unavailable for this book.</p>
```

恢复 `details` 服务的部署：

```bash
kubectl scale deployment details-v1 -n bookinfo --replicas=1
```

### 部署东西网关

你可以使用现有的 [入口网关](../../../quickstart/ingress-gateway)（已经公开了端口 15443），或者如果你希望使用仅暴露端口 15443 的特定东西网关，可以通过在 [IngressGateway 部署 CR](../../../refs/install/dataplane/v1alpha1/spec#tetrateio-api-install-dataplane-v1alpha1-ingressgatewayspec) 中设置 `eastWestOnly: true` 来部署一个。

在示例中，你将部署一个特定的仅暴露端口 15443 的东西网关。你可以将东西网关部署在任何命名空间中。

创建以下 `eastwest-gateway.yaml`：

``` yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: eastwest-gateway
  namespace: eastwest
spec:
  eastWestOnly: true
```

然后将其应用到 `cluster-1` 和 `cluster-2` 两个集群：

```bash
kubectl create ns eastwest
kubectl apply -f eastwest-gateway.yaml
```

确保你的东西网关分配了一个 IP 地址：

```
kubectl get svc -n eastwest

NAME               TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)           AGE
eastwest-gateway   LoadBalancer   10.124.221.74   12.34.56.789   15443:31860/TCP   29s
```

### 在集群 2 中部署备份服务

在 `cluster-2` 中部署相同的 bookinfo 服务：

```bash
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
```

```bash
kubectl apply -n bookinfo -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml
```

创建以下 bookinfo WorkspaceSetting，以配置东西路由，并使用 tctl 应用。这将启用对属于 bookinfo 工作空间的所有服务的故障转移。你可以通过指定服务选择器来选择哪些服务启用故障转移，如下所示：

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-ws-setting
spec:
  defaultEastWestGatewaySettings:
    - workloadSelector:
        namespace: eastwest
        labels:
          app: eastwest-gateway
```

```bash
tctl apply -f bookinfo-ws-setting.yaml
```

### 对高可用配置重复故障测试

在集群 1 中，验证 BookInfo 正常工作：

```bash
kubectl exec deployment/sleep -n sleep -c sleep -- curl -s http://productpage.bookinfo:9080/productpage | grep -i details -A 8
```

终止集群 1 中的 `details` 服务：

```bash
kubectl scale deployment details-v1 -n bookinfo --replicas=0
```

验证 BookInfo 仍然正常工作，因为失败的服务的流量被路由到远程集群 2：

```bash
kubectl exec deployment/sleep -n sleep -c sleep -- curl -s http://productpage.bookinfo:9080/productpage | grep -i details -A 8
```

## 观察故障转移

要观察故障转移，你可以使用 TSB 仪表板。在 `details` 服务在集群 1 失败之前，`Cluster 1` 中的 `productpage` 会将请求发送到 `Cluster 1` 中的 `details` 服务。在 `details` 服务在集群 1 失败之后，`Cluster 1` 中的 `productpage` 会将请求发送到 `Cluster 2` 中的 `details` 服务。

首先，恢复集群 1 中的 `details` 服务部署：

```bash
kubectl scale deployment details-v1 -n bookinfo --replicas=1
```

然后发送大量流量，以便在 TSB 仪表板中查看服务拓扑。

```bash
while true; do kubectl exec deployment/sleep -n sleep -c sleep -- curl -s http://productpage.bookinfo:9080/productpage; sleep 10; done
```

打开 TSB 仪表板，将 `Timerange` 设置为 5 分钟，并启用每 10 秒自动刷新。

![Traffic is running locally in Cluster 1 (c1) before details service is terminated](../../../assets/howto/eastwest-1.png)

经过几分钟后，打开另一个终端标签页，将集群 1 中的 `details` 服务缩容，保持流量继续。

```bash
kubectl scale deployment details-v1 -n bookinfo --replicas=0
```

返回到 TSB 仪表板，你将看到 `Cluster 1` 中的 `productpage` 正在向 `Cluster 2` 中的 `details` 服务发送请求。

![productpage service in Cluster 1 (c1) is sending request to details service in Cluster 2 (c2)](../../../assets/howto/eastwest-2.png)

经过几分钟后，你将看到 `Cluster 1` 中的 `details` 服务从拓扑视图中消失。

![details service in Cluster 1 (c1) is removed from topology view](../../../assets/howto/eastwest-3.png)

### 基于子集的路由和故障转移

以 Bookinfo 应用程序为例，如果你启用了使用 [ServiceRoute](../../../quickstart/traffic-shifting) 或直接模式的 [VirtualService](https://istio.io/latest/docs/tasks/traffic-management/request-routing/) 进行子集路由，以将请求路由到 `reviews` 服务的 `v2` 版本，当你将 `Cluster 1` 中的 `reviews-v2` 部署缩减为 0 时，故障转移将发生到 `Cluster 2` 中的 `reviews-v2`。

![在 Cluster 1（c1）中，reviews-v2 和 details-v1 服务被缩减为零](../../../assets/howto/eastwest-4.png)

即使服务不在本地，也支持基于子集（或版本）的路由。再次以 Bookinfo 为例，如果你希望将 `reviews` 服务一起部署到与 productpage 不同的集群中，子集路由仍将受到尊重。

![在部署 productpage 的地方，reviews 和 ratings 服务都不在本地](../../../assets/howto/eastwest-5.png)

如果你未启用子集路由，默认情况下，`productpage` 将发送请求到所有 `reviews` 版本 `v1`、`v2` 和 `v3`。仅当你将一个版本（例如 `reviews-v2` 部署）在 `Cluster 1` 中缩减为 0 时，才不会发生故障转移。当你将所有 `reviews` 版本的部署都缩减为 0 时，才会发生到 `Cluster 2` 的故障转移。

{{<callout note "Istio 地域负载均衡">}}
默认情况下，TSB 在翻译的 `DestinationRule` 中包括异常检测，这启用了 [地域负载均衡](https://istio.io/latest/docs/tasks/traffic-management/locality-load-balancing/)。这确保你的流量保持在集群节点内。例如，当 `productpage` 调用 `reviews` 服务时，始终优先考虑距离源 `productpage` pod 最近的 `reviews` pod，无论是否配置了基于子集的路由。

地域负载均衡确保低延迟，并有助于最小化不必要的出口成本。只有在其他集群/节点中的服务实例不可用时，TSB 才会将流量路由到其他集群/节点的服务实例。
{{</callout>}}

## 常见问题

### TSB 在故障发生时如何识别远程服务？

具有相同名称且在多个集群中相同命名空间中运行的服务被视为相同。例如，在 Cluster 1 中运行的 `bookinfo` 命名空间中的 `details` 服务被视为与 Cluster 2 中运行的 `bookinfo` 命名空间中的 `details` 服务相同。只有当远程服务满足此标准时，故障转移才会发生。

具有相同名称的服务无法故障转移到不同命名空间的服务。例如，在 Cluster 1 中命名空间 `bookinfo-dev` 中的 `details` 服务将不会故障转移到 Cluster 2 中命名空间 `bookinfo-prod` 中的 `details` 服务。

### 如何选择哪些服务要暴露？

一个 `defaultEastWestGatewaySettings` 对象与一个工作空间关联，作为 `WorkspaceSetting` 资源的一部分。默认情况下，工作空间中的所有服务都会被暴露，并成为故障转移的候选对象。

你可以使用服务选择器来微调在东西网关中暴露哪些服务：

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-ws-setting
spec:
defaultEastWestGatewaySettings:
  - workloadSelector:
      namespace: eastwest
      labels:
        app: eastwest-gateway
    exposedServices:
      - serviceLabels:
          failover: enable
      - serviceLabels:
          app: details
```

## 故障排除

如果发现远程集群的故障转移请求失败，请执行以下检查：

1. 检查远程服务的 WorkloadEntry 是否在集群中已创建。你应该看到类似以下的输出：

    ```
    kubectl get we -A
    
    NAMESPACE   NAME                                         AGE   ADDRESS
    bookinfo    k-details-2563fd2d9c78aacb3d42d6db45051ade   67s   12.34.56.78
    bookinfo    k-ratings-66dadd9a9f80adfda349ea5b85f6ae70   67s   12.34.56.78
    bookinfo    k-reviews-c8faecbe6a6b00a4c411d938bc485eae   67s   12.34.56.78
    ```

{{<callout note "使用 IP 地址而不是 FQDN">}}
ADDRESS 列需要显示端点的 IP 地址（而不是 FQDN）。如果输出类似于以下内容，则需要执行额外的配置步骤：

```
NAMESPACE   NAME                                                      AGE    ADDRESS
bookinfo    k-productpage-c046fe25a722387a9e85cc0c39540510            10s    ab02acc8e39f240799a682b7ae6dc42d-1914098926.ca-central-1.elb.amazonaws.com.
bookinfo    k-ratings-884c48dc6eef342bb5c8f52bdb709f65                10x    ab02acc8e39f240799a682b7ae6dc42d-1914098926.ca-central-1.elb.amazonaws.com.
bookinfo    k-reviews-ecc8c772e25c119d8a6e4ad2db695

69b                10s    ab02acc8e39f240799a682b7ae6dc42d-1914098926.ca-central-1.elb.amazonaws.com.
```

在 ControlPlane CR 中启用 `ENABLE_DNS_RESOLUTION_AT_EDGE` 参数将允许 XCP Edge 用 IP 地址替换 FQDN。启用参数后，ControlPlane CR 将如下所示：

```
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  components:
    xcp:
      ...
      kubeSpec:
        overlays:
          - apiVersion: install.xcp.tetrate.io/v1alpha1
            kind: EdgeXcp
            name: edge-xcp
            patches:
              ...
              - path: spec.components.edgeServer.kubeSpec.deployment.env[-1]
                value:
                  name: ENABLE_DNS_RESOLUTION_AT_EDGE
                  value: "true"
  ...
```

应用更改后，FQDN 将被实际的 IP 地址替换，并且它将解锁东西网关的流量流动。

{{</callout>}}

2. 如果你使用了 `serviceLabels` 选择器，请确保在 `defaultEastWestGatewaySettings` 中使用的服务标签在你希望进行故障转移的服务中可用。
