---
weight: 1
title: "统一网关"
description: "本文介绍了 Tetrate Service Bridge（TSB）生态系统中统一网关的概念，解释了其重要性，并提供了详细的使用场景。"
---

本文介绍了 Tetrate Service Bridge（TSB）生态系统中统一网关的概念，解释了其重要性，并提供了详细的使用场景。

## 简介

统一网关是在 TSB 1.7.0 中引入的关键功能，它将[Tier1Gateway](https://docs.tetrate.io/service-bridge/next/refs/tsb/gateway/v2/tier1_gateway)和[IngressGateway](https://docs.tetrate.io/service-bridge/next/refs/tsb/gateway/v2/ingress_gateway)的功能合并到一个称为[Gateway](https://docs.tetrate.io/service-bridge/next/refs/tsb/gateway/v2/gateway)的公共资源中。这种统一简化了网关管理过程，并提供了更一致的体验。

从 TSB 1.7.0 开始，Tier1Gateway 和 IngressGateway 资源将被弃用，我们强烈建议使用 Gateway 资源满足你的所有网关需求。前 Tier1 Gateway 现在将被统称为[Edge Gateway](https://docs.tetrate.io/service-bridge/next/concepts/glossary/#edge-gateway)。

统一网关选项卡无缝集成到 TSB UI 中，使得任何网关的配置都变得容易，不管它是作为 Tier 1 还是 Tier 2 网关工作。

![TSB UI 中的 Unified Gateway](../../../assets/howto/gateway/unified-gateway.png)

## 为什么需要统一网关？

在我们的旅程早期，我们认识到我们的客户对集群特定（Tier 2）和跨云供应商（Tier1）网关有不同的需求。因此，我们开发了不同的网关解决方案来满足这些不同的需求。然而，随着我们的 Gateway API 的发展和客户需求变得更加复杂，我们不断增强 Tier1 网关的能力的需求变得明显。

这种发展带来了挑战——持续的工程努力、客户教育何时选择 Tier1 或 Tier2 以及维护并行代码库。我们已经着手开展一项开创性的工作：统一网关，以简化这些复杂性并提供更一致的体验。

## 统一网关的优势

统一网关不仅是 Tier 1 和 Tier 2 网关的融合，它是网关管理的范式转变。以下是你需要了解这个变革性解决方案的内容：

### 全面的功能

统一网关结合了 TSB 版本 1.6.X 中 Tier 1 和 Tier 2 网关的强大功能，确保你获得最佳的两个世界。无论是处理重试、故障转移还是任何其他高级功能，统一网关都可以为你提供支持，无论它是作为 Tier 1 还是 Tier 2 网关配置的。

### 无缝过渡

对于我们现有的客户，我们了解连续性的重要性。不用担心，你的 Tier 1 和 Tier 2 网关将继续像往常一样使用 1.6.X 版本提供的功能。但我们不会止步于此。我们正在引入一个无缝的过渡过程，将你现有的网关过渡到统一网关模型，增强 Tier 1 功能，如重试等等。

### 统一网关的新 API

拥抱创新并不意味着忽略过去。在为新机遇引入新的统一网关 API 的同时，我们致力于支持后续三个 TSB 版本的先前 API。这确保你可以按照自己的节奏切换，而不会受到干扰。

### 授权直连模式

统一网关不仅仅是网关，而是赋能。新老客户都可以通过直连模式发挥网关 API 的全部功能，从而对其网格基础设施获得无与伦比的控制和自定义。

### 与开放 API 策略相符

我们相信开放标准的力量。统一网关与我们的开放 API 策略完美契合，使你可以使用标准化的 Open API 规范配置统一网关。这种方法促进了一致性，并简化了与现有工具链的集成。

## 使用案例

让我们深入了解统一网关的使用场景。

### 准备集群

下图显示了我们在本文档中使用的部署架构。我们在 GKE 中创建了 3 个集群，在其中一个集群中部署了 TSB，将另外三个集群加载到了 TSB 中，并在基础设施下的集群中部署了 bookinfo 应用程序。

![基础设施拓扑](../../../assets/howto/gateway/unified-gateway-infrastructure.svg)

下表描述了这些集群的角色和应用程序：

| 集群        | gke-jimmy-us-central1-1 | gke-jimmy-us-west1-1 | gke-jimmy-us-west1-2                           | gke-jimmy-us-west2-3 |
| ----------- | ----------------------- | -------------------- | ---------------------------------------------- | -------------------- |
| Region      | `us-central1`           | `us-west1`           | `us-west1`                                     | `us-west2`           |
| TSB 角色    | Management Plane        | Control Plane        | Control Plane                                  | Control Plane        |
| Application | -                       | `bookinfo-frontend`  | `bookinfo-backend`                             | `httpbin`            |
| Services    | -                       | `productpage`        | `productpage`, `ratings`, `reviews`, `details` | `httpbin`            |
| Network     | `tier1`                 | `cp-cluster-1`       | `cp-cluster-2`                                 | `cp-cluster-3`       |

本节介绍了统一网关的使用场景。

### 场景 1：基于集群的路由，使用 HTTP 路径和 Header 匹配

在这种情况下，我们将使用 Gateway 资源来公开`bookinfo.tetrate.io`和`httpbin.tetrate.io`。我们将利用基于 Gateway 的集群路由功能，根据 Gateway 上的路径前缀将 bookinfo 前端服务路由到 cp-cluster-1，将其他后端服务路由到 cp-cluster-2。使用 Gateway，用户可以公开多个具有 clusterDestination 的主机，只要主机：端口组合是唯一的即可。

![基于集群的路由，使用 HTTP 路径和 Header 匹配](../../../assets/howto/gateway/unified-gateway-scenario-1.svg)

**部署拓扑和流量路由**

我们设置了以下部署拓扑：

- **Tier 1 集群**：该集群用作外部流量的入口点，并将其路由到相应的后端集群。
- **后端集群**：有三个后端集群，每个集群托管不同的服务：
  1. `cp-cluster-1`托管“Bookinfo”应用程序的前端服务。
  2. `cp-cluster-2`托管“Bookinfo”应用程序的后端服务。
  3. `cp-cluster-3`托管名为`httpbin`的 HTTP 服务。

**配置**

**1. Tier 1 集群网关（边缘网关）：**

在 `tier1` 集群中，我们部署了一个名为 `edge-gateway` 的网关。该网关接收传入的流量，并根据主机和路径前缀将其路由到适当的后端集群。

以下是路由请求到“Bookinfo”前端和后端服务的配置摘录：

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
 kind: Gateway
 metadata:
   name: edge-gateway
   namespace: tier1
   annotations:
     tsb.tetrate.io/organization: tetrate
     tsb.tetrate.io/tenant: tier1
     tsb.tetrate.io/workspace: tier1
     tsb.tetrate.io/gatewayGroup: edge-gateway-group
 spec:
   workloadSelector:
     namespace: tier1
     labels:
       app: edge-gateway
   http:
   - name: bookinfo
     hostname: bookinfo.tetrate.io
     port: 80
     routing:
       rules:
         - match:
             - uri:
                 prefix: "/productpage"
               headers:
                 X-CLUSTER-SELECTOR:
                   exact: gke-jimmy-us-west1-1
           route:
             clusterDestination:
               clusters:
                 - name: gke-jimmy-us-west1-1
                   weight: 100
         - match:
             - uri:
                 prefix: "/productpage"
               headers:
                 X-CLUSTER-SELECTOR:
                   exact: gke-jimmy-us-west1-2
           route:
             clusterDestination:
               clusters:
                 - name: gke-jimmy-us-west1-2
                   weight: 100
         - match:
             - uri:
                 prefix: "/productpage"
           route:
             clusterDestination:
               clusters:
                 - name: gke-jimmy-us-west1-1
                   weight: 100
         - match:
             - uri:
                 prefix: "/api/v1/products"
           route:
             clusterDestination:
               clusters:
                 - name: gke-jimmy-us-west1-2
                   weight: 100
   - name: httpbin
     hostname: httpbin.tetrate.io
     port: 80
     routing:
       rules:
         - route:
             clusterDestination:
               clusters:
                 - name: gke-jimmy-us-west2-3
                   weight: 100
```

这些规则确保带有不同路径前缀的对 `bookinfo.tetrate.io` 的请求被路由到适当的后端集群。同样，请求到 `httpbin.tetrate.io` 的流量被重定向到 `cp-cluster-3`。

**2. 后端集群中的入口网关**

在每个后端集群（`cp-cluster-1`、`cp-cluster-2` 和 `cp-cluster-3`）中，我们部署了入口网关，以接收来自 `tier1` 集群的流量，并将其路由到相应的服务。

以下是 `cp-cluster-1` 中 Ingress Gateway 的示例配置：

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: bookinfo-ingress-gateway
spec:
  # ... (metadata and selectors)
  http:
    - hostname: bookinfo.tetrate.io
      name: bookinfo-tetrate
      port: 80
      routing:
        rules:
          - route:
              serviceDestination:
                host: bookinfo-frontend/productpage.bookinfo-frontend.svc.cluster.local
```

这个配置可以确保在 `cp-cluster-1` 中收到的 `bookinfo.tetrate.io` 的 Ingress Gateway 的流量被路由到前端服务。

**验证**

我们可以使用像 curl 这样的工具请求公开的服务以验证设置。例如，要测试 `/productpage`：

```bash
export GATEWAY_IP=$(kubectl -n tier1 get service edge-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl -Ss "<http://bookinfo.tetrate.io/productpage>" --resolve "bookinfo.tetrate.io:80:$GATEWAY_IP" -v
```

同样，你可以根据定义的路由规则测试其他路由和服务。

### 场景 2：主机路由与网关标头重写

此场景展示了统一网关的权限重写或标头重写功能。我们在 `tier1` 集群中部署边缘网关，以在不同集群之间路由流量，并使用 IngressGateways 为每个控制平面集群接收流量。

![主机路由与网关标头重写](../../../assets/howto/gateway/unified-gateway-scenario-2.svg)

**部署拓扑和流量路由**

我们已经设置了以下部署拓扑：

- **Tier 1 Cluster：** 该集群作为外部流量的入口点，并将其路由到相应的后端集群。

- 后端集群：

   有三个后端集群，每个集群托管不同的服务：

  1. `cp-cluster-1` 托管"Bookinfo"应用程序的前端服务。
  2. `cp-cluster-2` 托管"Bookinfo"应用程序的后端服务。

**配置**

**1. Tier 1 Cluster Gateway (tier1-gateway)**

在 Tier 1 集群中，我们部署名为 `tier1-gateway` 的网关。此网关接收传入流量并根据主机和路径前缀将其路由到适当的后端集群。此外，它会为特定路由执行主机标头重写。

以下是用于使用标头重写路由到"Bookinfo"前端和后端服务的配置片段：

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: tier1-gateway
  namespace: tier1
spec:
  # ... (metadata and selectors)
  http:
  - name: bookinfo
    hostname: bookinfo.tetrate.io
    port: 80
    routing:
      rules:
        - match:
            - uri:
                prefix: "/productpage"
          modify:
            rewrite:
              authority: 'internal-bookinfo-frontend.tetrate.io'
          route:
            clusterDestination:
              clusters:
                - name: gke-jimmy-us-west1-1
                  weight: 100
        - match:
            - uri:
                prefix: "/api/v1/products"
          modify:
            rewrite:
              authority: 'internal-bookinfo-backend.tetrate.io'
          route:
            clusterDestination:
              clusters:
                - name: gke-jimmy-us-west1-2
                  weight: 100
```

这些规则确保将对具有不同路径前缀的 `bookinfo.tetrate.io` 的请求路由到适当的后端集群。此外，对于这些路由，主机标头将被重写。

**2. 后端集群中的 Ingress Gateways**

在每个后端集群 (`cp-cluster-1` 和 `cp-cluster-2`) 中，我们部署 Ingress Gateways 以从 `tier1` 集群接收流量并将其路由到相应的服务。这些 Ingress Gateways 监听重写后的主机标头。

以下是 `cp-cluster-1` 中 Ingress Gateway 配置的示例：

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: bookinfo-ingress-gateway
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: payment
    tsb.tetrate.io/workspace: bookinfo-frontend-ws
spec:
  displayName: Bookinfo Ingress
  workloadSelector:
    namespace: bookinfo-frontend
    labels:
      app: bookinfo-gateway
  http:
    - hostname: internal-bookinfo-frontend.tetrate.io
      name: bookinfo-tetrate
      port: 80
      routing:
        rules:
          - route:
              serviceDestination:
                host: bookinfo-frontend/productpage.bookinfo-frontend.svc.cluster.local
```

此配置可确保 `cp-cluster-1` 中的 Ingress Gateway 收到具有重写后的主机标头的流量时，将其路由到前端服务。

**验证**

我们可以使用 curl 等工具请求已公开的服务以验证设置。例如，要测试 `/productpage`:

```bash
export GATEWAY_IP=$(kubectl -n tier1 get service tier1-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl -Ss "<http://bookinfo.tetrate.io/productpage>" --resolve "bookinfo.tetrate.io:80:$GATEWAY_IP" -v
```

类似地，你可以根据定义的路由规则测试其他路由和服务。

### 场景 3：使用 TSB 应用和 OpenAPI 规范创建 UnifiedGateway

此场景演示了如何使用 OpenAPI 规范和 Tetrate Service Bridge (TSB) 为 Tier 1 和 Tier 2 用例创建 Unified Gateways。此方法允许你使用 OpenAPI 规范定义应用程序的流量路由。

**部署拓扑和流量路由**

我们的目标是使用 OpenAPI 规范为流量路由配置一个统一网关。以下图说明了部署拓扑和路由设置：

![使用 TSB 应用和 OpenAPI 规范创建 UnifiedGateway](../../../assets/howto/gateway/unified-gateway-scenario-3.svg)

**配置步骤**

1. **Tier 1 集群配置**

   在 `tier1` 集群中，我们使用 OpenAPI 规范配置 Application 和 API 资源。这些配置使用 `x-tsb-clusters` 注释进行基于集群的路由以公开 `bookinfo.tetrate.io`。

   ```yaml
   x-tsb-clusters:
     clusters:
       - name: gke-jimmy-us-west1-2
         weight: 100
   ```

   此配置将流量路由到在 `x-tsb-clusters` 注释中指定的多个 Tier 2 集群。

2. **Tier 2 集群配置**

   在 Tier 2 集群 (`cp-cluster-2` 在此场景中)，我们使用基于服务的路由配置 Application 和 API 资源以公开 `bookinfo.tetrate.io`。此配置使用 `x-tsb-service` 注释来路由到 `productpage.bookinfo-backend` 服务。

   ```yaml
   x-tsb-service: productpage.bookinfo-backend
   ```

**验证**

要验证路由设置，你可以使用 curl 等工具向公开服务发出请求。例如，要测试 `/api/v1/products/*` 路由：

```bash
# Export the Load Balancer IP of the tier1-gateway
export GATEWAY_IP=$(kubectl -n tier1 get service tier1-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Send a request to the API
curl -Ss "<http://bookinfo.tetrate.io/api/v1/products/1/reviews>" --resolve "bookinfo.tetrate.io:80:$GATEWAY_IP" -v
```

### 场景 4：实现 HTTP 到 HTTPS 重定向

此场景演示了如何配置 `Gateway` 资源以实现 HTTP 到 HTTPS 重定向。这对于通过 HTTPS 安全地公开服务并支持使用普通 HTTP 的传统应用程序非常有用。

**部署拓扑**

我们的目标是在端口 80 上使用明文 (HTTP) 公开 `bookinfo.tetrate.io`，并在端口 443 (HTTPS) 上配置 HTTP 到 HTTPS 重定向，以确保安全通信。以下图说明了部署拓扑和路由设置：

![实现 HTTP 到 HTTPS 重定向](../../../assets/howto/gateway/unified-gateway-scenario-4.svg)

**配置步骤**

1. **Tier 1 集群配置**

   在 `tier1` 集群中，我们创建一个名为 `tier1-gateway` 的 `Gateway` 资源。此网关负责 HTTP 到 HTTPS 重定向。我们指定两个 HTTP 监听器：

   - `bookinfo-plaintext`：该监听器在端口 80 上侦听并处理 `bookinfo.tetrate.io` 的请求。它使用 301 重定向代码将请求重定向到端口 443 (HTTPS)。

   - `bookinfo`：该监听器在端口 443 (HTTPS) 上侦听以进行安全通信。它使用 TLS，使用名为 `bookinfo-certs` 的 secret。

     ```yaml
     apiVersion: gateway.tsb.tetrate.io/v2
     kind: Gateway
     metadata:
       name: tier1-gateway
       namespace: tier1
       annotations:
         tsb.tetrate.io/organization: tetrate
         tsb.tetrate.io/tenant: tier1
         tsb.tetrate.io/workspace: tier1
         tsb.tetrate.io/gatewayGroup: tier1-gateway-group
     spec:
       workloadSelector:
         namespace: tier1
         labels:
           app: tier1-gateway
       http:
       - name: bookinfo-plaintext
         port: 80
         hostname: bookinfo.tetrate.io
         routing:
           rules:
             - redirect:
                 authority: bookinfo.tetrate.io
                 port: 443
                 redirectCode: 301
                 scheme: https
       - name: bookinfo
         hostname: bookinfo.tetrate.io
         port: 443
         tls:
           mode: SIMPLE
           secretName: bookinfo-certs
         routing:
           rules:
             - match:
                 - uri:
                     prefix: "/productpage"
               route:
                 clusterDestination:
                   clusters:
                     - name: gke-jimmy-us-west1-2
                       weight: 100
     ```

2. **Tier 2 集群配置**

   在 Tier 2 集群 (`cp-cluster-2` 在此场景中)，我们配置了 `eastWestOnly: true` 的 IngressGateway。此设置仅公开 mTLS `15443` 多集群端口。我们还使用名为 `bookinfo-ingress-gateway` 的 `Gateway` 资源来路由请求。

   ```yaml
   apiVersion: install.tetrate.io/v1alpha1
   kind: IngressGateway
   metadata:
     name: bookinfo-gateway
   spec:
     eastWestOnly: true
     kubeSpec:
       service:
         type: LoadBalancer
   apiVersion: gateway.tsb.tetrate.io/v2
   kind: Gateway
   metadata:
     name: bookinfo-ingress-gateway
     annotations:
       tsb.tetrate.io/organization: tetrate
       tsb.tetrate.io/tenant: payment
       tsb.tetrate.io/workspace: bookinfo-backend-ws
       tsb.tetrate.io/gatewayGroup: bookinfo-gg
   spec:
     displayName: Bookinfo Ingress
     workloadSelector:
       namespace: bookinfo-backend
       labels:
         app: bookinfo-gateway
     http:
       - hostname: bookinfo.tetrate.io
         name: bookinfo-tetrate
         routing:
           rules:
             - route:
                 serviceDestination:
                   host: bookinfo-backend/productpage.bookinfo-backend.svc.cluster.local
   ```

**验证**

要验证 HTTP 到 HTTPS 重定向，请执行以下操作：

1. 要在浏览器中查看重定向，你需要更新你的 `/etc/hosts` 文件，以使 `bookinfo.tetrate.io` 解析为你的 Edge Gateway IP：

   ```bash
   export GATEWAY_IP=$(kubectl -n tier1 get service tier1-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   echo "$GATEWAY_IP bookinfo.tetrate.io" | sudo tee -a /etc/hosts
   ```

2. 在浏览器中访问 `http://bookinfo.tetrate.io/productpage`。你应该会自动重定向到 `https://bookinfo.tetrate.io/productpage`，以确保安全通信。

### 场景 5：配置外部服务

在此场景中，我们使用统一网关为转发外部服务流量配置专用出口网关。我们在 `httpbin` 命名空间中部署 `IngressGateway` (在两个集群中都部署) 并设置 `ServiceEntry` 以定义外部服务。

**部署拓扑**

此部署涉及创建一个新的 `httpbin` 命名空间和两个集群 (`cp-cluster-1` 和 `cp-cluster-2`) 中的 `IngressGateway`。为了使这些集群能够访问外部服务 `httpbin.org`，我们在两个集群中添加了一个 `ServiceEntry`，并将网关配置为覆盖请求的权限。

![配置外部服务](../../../assets/howto/gateway/unified-gateway-scenario-5.svg)

**配置步骤**

1. **创建 `ServiceEntry` 和 `IstioInternalGroup`**

   使用 `ServiceEntry` 定义一个外部服务，并将其与 `IstioInternalGroup` 相关联。此配置使集群能够访问 `httpbin.org`。我们在两个集群中创建这些资源。

   ```yaml
   apiVersion: v1
   kind: List
   items:
     - apiVersion: tsb.tetrate.io/v2
       kind: Workspace
       metadata:
         name: httpbin-ws
         annotations:
           tsb.tetrate.io/organization: tetrate
           tsb.tetrate.io/tenant: payment
       spec:
         namespaceSelector:
           names:
             - "gke-jimmy-us-west1-1/httpbin"
             - "gke-jimmy-us-west1-2/httpbin"
         displayName: httpbin-ws
     - apiVersion: istiointernal.tsb.tetrate.io/v2
       kind: Group
       metadata:
         name: httpbin-internal-gp
         annotations:
           tsb.tetrate.io/organization: tetrate
           tsb.tetrate.io/tenant: payment
           tsb.tetrate.io/workspace: httpbin-ws
       spec:
         namespaceSelector:
           names:
             - "gke-jimmy-us-west1-1/httpbin"
             - "gke-jimmy-us-west1-2/httpbin"
     - apiVersion: networking.istio.io/v1beta1
       kind: ServiceEntry
       metadata:
         name: httpbin-external-svc
         annotations:
           tsb.tetrate.io/organization: tetrate
           tsb.tetrate.io/tenant: payment
           tsb.tetrate.io/workspace: httpbin-ws
           tsb.tetrate.io/istioInternalGroup: httpbin-internal-gp
         labels:
           istio.io/rev: tsb
       spec:
         hosts:
           - httpbin.org
         exportTo:
           - "."
         location: MESH_EXTERNAL
         ports:
           - number: 443
             name: https
             protocol: HTTPS
         resolution: DNS
   ```

2. **应用 `Gateway` 配置**

   配置 `Gateway` 资源以将请求从 `httpbin.tetrate.io` 重写为 `httpbin.org`。我们在 `cp-cluster-1` 和 `cp-cluster-2` 两个集群中设置了这个配置。

   ```yaml
   - apiVersion: gateway.tsb.tetrate.io/v2
     kind: Gateway
     metadata:
       name: httpbin-ingress-gateway
       annotations:
         tsb.tetrate.io/organization: tetrate
         tsb.tetrate.io/tenant: payment
         tsb.tetrate.io/workspace: httpbin-ws
         tsb.tetrate.io/gatewayGroup: httpbin-gg
     spec:
       displayName: Httpbin Ingress
       workloadSelector:
         namespace: httpbin
         labels:
           app: httpbin-gateway
       http:
         - hostname: httpbin.tetrate.io
           name: httpbin-tetrate
           port: 80
           routing:
             rules:
               - modify:
                   rewrite:
                     authority: httpbin.org
                 route:
                   serviceDestination:
                     host: httpbin/httpbin.org
                     tls:
                       mode: SIMPLE
                       files:
                         caCertificates: "/etc/ssl/certs/ca-certificates.crt"
   ```

**验证**

要验证此配置，你可以按照以下步骤操作：

1. 要获取两个集群中 `IngressGateway` 的 IP 地址，请在每个集群中运行以下命令：

   ```bash
   export GATEWAY_IP=$(kubectl -n httpbin get service httpbin-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
   ```

2. 使用两个网关通过代理访问 `httpbin.org`，执行以下命令：

   ```bash
   curl -v '<http://httpbin.tetrate.io/get>' --resolve "httpbin.tetrate.io:80:$G
   ```