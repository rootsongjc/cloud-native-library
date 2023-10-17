---
title: "部署服务和配置网关规则"
weight: 3
---

应用程序所有者的用户体验在他们直接使用原生 Kubernetes API 与 Kubernetes 平台交互，或者依赖于间接方法（如 CD 流水线）来部署和配置平台时几乎没有变化。

应用程序所有者 ("Apps") 将按以下步骤部署和公开服务：

1. 部署服务

   在由平台所有者提供的 Kubernetes 命名空间中部署目标服务。

2. 公开服务

   配置一个 Gateway 资源，通过本地 Ingress 网关公开服务。

## Apps: 开始之前

在开始之前，您需要从您的管理员（平台所有者）那里获得以下信息：

 * Kubernetes 集群和命名空间：在所选择的命名空间中部署和管理服务所需的 API 访问权限
 * Tetrate 拓扑：Kubernetes 命名空间被分组为 Tetrate 工作空间，一个工作空间可以包含来自多个集群的命名空间。您需要了解拓扑，包括：
   * Tetrate 工作空间的名称
   * 该工作空间中的命名空间和集群
   * Tetrate Gateway Groups 的名称 - 通常每个工作空间每个集群有一个 Gateway Group

请注意，Tetrate 部署的最常见安全姿态是允许 Workspace 内的流量，在工作空间之间以及不在工作空间中的 mesh 服务之间拒绝所有流量。如果需要，您的管理员可以在工作空间之间开放额外的流量。

## Apps: 部署服务

将您的服务部署到由平台所有者提供的 Kubernetes 命名空间中，例如：

```bash
kubectl apply -n bookinfo -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml
```

{{<callout note "识别 Tetrate 管理的命名空间">}}

由 Tetrate 管理的命名空间将启用 Istio 注入。您可以使用 `kubectl describe ns <namespace>` 来验证此信息，并查找标签 **istio-injection=enabled**。您部署的 Pod 将在运行时具有一个额外的 **istio-proxy** 容器，以及几个瞬态的 init 容器。

{{</callout>}}

## Apps: 公开服务

使用 Gateway 资源公开一个服务。这将配置 Ingress 网关以将流量负载均衡到您的服务：

![通过 Ingress 网关公开服务](../images/topology.png)

**Gateway** 资源引用了以下资源，这些资源应由您的管理员（平台所有者）提供：

 * Tetrate 组织 **tse**，租户 **tse**，工作空间 **bookinfo-ws** 和 Gateway 组 **bookinfo-gwgroup-1**
 * 位于 **bookinfo/bookinfo-ingress-gw** 中的 Ingress Gateway

突出显示的行包含了这些资源的名称：

```yaml
cat <<EOF > bookinfo-gateway.yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: bookinfo-gateway
  annotations:
# highlight-start
    tsb.tetrate.io/organization: tse
    tsb.tetrate.io/tenant: tse
    tsb.tetrate.io/workspace: bookinfo-ws
    tsb.tetrate.io/gatewayGroup: bookinfo-gwgroup-1
# highlight-end
spec:
  workloadSelector:
# highlight-start
    namespace: bookinfo
# highlight-end
    labels:
# highlight-start
      app: bookinfo-ingress-gw
# highlight-end
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

kubectl apply -f bookinfo-gateway.yaml
```

此配置在所选的 Ingress 网关上实例化。Ingress 网关是一个基于 Envoy 的代理，用于侦听传入流量（在本例中是端口 **80** 上的 **http** 流量）。然后，将具有主机头 **bookinfo.tse.tetratelabs.io** 的流量路由到您的服务 **bookinfo/productpage.bookinfo.svc.cluster.local**，端口为 **9080**。

### 了解 Tetrate Gateway

在幕后，您应用的 Tetrate **Gateway** 对象将由 Tetrate 管理平面在 Tetrate 的配置层次结构中处理，然后用于创建一个或多个 Istio **gateway** 对象：

```bash
kubectl get gateway -n bookinfo bookinfo-gateway -o yaml
```

**gateway** 对象包含一个选择器，该选择器标识了应该实例化此配置的 Ingress 网关（一个 Envoy 代理 Pod）。

#### Tetrate 参数

如果您的 Tetrate 参数有任何错误，**apply** 操作将被拒绝。您将收到类似于以下错误消息：

```
Error from server: error when creating "bookinfo-gateway.yaml": admission webhook "gitops.tsb.tetrate.io" denied the request: computing an access decision: checking permissions [organizations/tse/serviceaccounts/auto-cluster-cluster-1#exHFFwuGQSCPQP941C4ilMZFWwmO4lJoTyQXKjAPHXk ([CreateGateway]) organizations/tse/tenants/tse/workspaces/bookinfo-ws/gatewaygroups/bookinfo-gwgroup]: target "organizations/tse/tenants/tse/workspaces/bookinfo-ws/gatewaygroups/bookinfo-gwgroup" does not exist: node not found
```

这四个参数（**organization**、**tenant**、**workspace** 和 **gatewayGroup**）对应于由管理员（平台所有者）创建的 Tetrate 配置，它们定义了您的 **Ingress** 资源应位于 Tetrate 配置层次结构中的位置。

#### 工作负载选择器

**workloadSelector** 段标识了应将此配置应用于哪个 Ingress 网关（代理）。如果这些参数中的任何一个不正确（它们与 Ingress 控制器不匹配），则不会应用配置。

在上述示例中，您可以按以下方式找到 Ingress 网关：

```bash
kubectl get pods -n bookinfo -l=app=bookinfo-ingress-gw
```

#### 检查 Ingress 网关

Ingress Gateway pod 部署在由您分配的 Tetrate 工作空间管理的一个命名空间中：

```bash
kubectl get ingressgateway -A
```

检查 Ingress Gateway 配置，并查看托管 Envoy 代理的 Pod：

```bash
kubectl describe ingressgateway -n bookinfo bookinfo-ingress-gw
kubectl describe pod -n bookinfo -l app=bookinfo-ingress-gw
```

跟踪日志，包括实时访问日志：

```bash
kubectl logs -n bookinfo -l app=bookinfo-ingress-gw
```

#### Route 53 同步

如果管理员配置了 AWS Route 53 同步，那么 Tetrate 集成还将根据您的 **Gateway** 资源中的 **hostname** 自动为您配置一个基于 Route 53 DNS 的名称。

如果您具有访问 **istio-system**

 命名空间的权限，您可以从 Tetrate 的 Route 53 控制器中查看日志：

```bash
kubectl logs -n istio-system -l app=route53-controller
```

#### 通过 Ingress 网关访问服务

如果为您配置了 DNS，您应该能够直接访问服务：

```bash
curl http://bookinfo.tse.tetratelabs.io
```

您还可以确定 Ingress Gateway 的公共地址（IP 或 FQDN）并直接发送流量：

```bash
export GATEWAY_IP=$(kubectl -n bookinfo get service bookinfo-ingress-gw -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")

curl -s --connect-to bookinfo.tse.tetratelabs.io:80:$GATEWAY_IP \
    "http://bookinfo.tse.tetratelabs.io/productpage" 
```

## 进一步阅读

有关配置 Ingress Gateway 资源以控制如何公开服务的更多信息，请参阅以下文档：

 * [附加的 Gateway 示例 (TSB 文档)](../..//quickstart/ingress-gateway)
 * Gateway 参考文档：[TSB](https://docs.tetrate.io/service-bridge/refs/tsb/gateway/v2/ingress_gateway) / [TSE](https://docs.tetrate.io/service-express/reference/k8s-api/tsb-crds-gen#gateway)