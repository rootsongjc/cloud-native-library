---
title: 共享入口网关
description: 如何使用 TSB 配置单个入口网关部署，而不是默认情况下的每个工作区部署。
weight: 3
---

Tetrate Service Bridge 默认情况下会为每个工作区部署一个入口网关。我们这样做是为了保持团队隔离，防止共享故障和以信心实现高速度。然而，在大规模部署中，由于诸如负载均衡器地址过多或网关 Pod 在低流量应用中利用率低等原因，这可能是不可取的。因此，TSB 支持配置共享入口网关部署：换句话说，个别应用团队仍然可以发布自己的配置，但它们在运行时都会配置相同的 Envoy 实例。

![TSB 允许许多团队配置单个共享网关部署。](../../../assets/howto/gateway/shared-gateway-deploy.svg)

## 什么是网关？

在 Istio 中，"网关" 这个词有点令人困惑，因为它指的是几个不同的事物：

1. 作为 Kubernetes 入口网关运行的一组 Envoy，我们将其称为 "_网关部署_"。
2. Istio 配置资源，即 Istio 网关 API — 用于在运行时配置 _网关部署_ 的端口、协议和证书。我们将其称为 "_Istio 网关 API 资源_"。
3. 用于配置 Kubernetes 入口的 Kubernetes 网关 API — 它与 Istio 的 _网关 API 资源_ 做相同的事情，但是是一个原生的 Kubernetes 构造。我们将其称为 "_Kubernetes 网关 API 资源_"。

_网关部署_ 是一组真正运行的 Envoy，而 _Istio 网关 API 资源_ 和 _Kubernetes 网关 API 资源_ 都是运行 Envoy 的配置。


![TSB 允许将多个网关设置和网关 API 资源配置到单个网关部署中。](../../../assets/howto/gateway/gateway-deploy-vs-config.svg)

在本文中，我们只会关注 TSB 应用入口网关，而不是应用边缘网关（有关 "[_网关术语_](../../../concepts/terminology#gateway)" 和 "[_TSB 中的网关_](../../../concepts/traffic-management##gateways-in-tsb)" 的更多信息）。

## 在 TSB 中创建共享网关

当我们配置共享网关时，我们需要做一个基本的决定：谁来管理共享网关，以及应用程序的每个配置存放在哪里？

通常情况下，一个中心团队，如平台或负载均衡组拥有（共享）网关部署，而个别应用团队希望配置它们。我们将共享网关部署称为 "共享网关"，并建议将它们放在自己专用的 Kubernetes 命名空间和 TSB 工作区中。我们将分别称之为 "共享网关命名空间" 和 "共享网关工作区"。

然后我们需要决定应用程序的每个配置存放在哪里：是在共享网关命名空间中与共享网关一起，还是在应用程序的命名空间中与应用程序一起。将配置放在共享网关命名空间中意味着共享网关所有者参与配置更改，并可以帮助防止共享故障中断，但这可能会导致共享网关所有者成为所有网关更改的瓶颈，可能会影响灵活性。将配置放在应用程序的命名空间中意味着它可以像应用程序本身一样快速更改，但由于没有中央所有者审查对共享网关的更改，可能会增加由于配置错误导致的共享故障的风险。

TSB 的桥接模式——[网关组](../../../refs/tsb/gateway/v2/gateway-group)，对于使用共享网关更安全（如阻止同一主机名的多个所有者）并且使得在网格中的大多数应用程序使用共享网关变得可行。你还可以使用直连模式—— `VirtualServices`，使用原始的 Istio 配置来配置共享网关，但你需要执行规则来防止共享故障（通常通过代码审查来实现）。

最终，大多数组织将稳定性优先于功能速度，因此我们建议将应用程序配置放在共享网关命名空间中，以便由拥有共享网关的团队进行审查。
## 部署 `httpbin` 服务

请按照[此文档中的说明](../../../reference/samples/httpbin)创建 `httpbin` 服务。完成该文档中的所有步骤。

## 部署共享网关

要部署共享网关，我们需要在 TSB 中创建一个工作区来托管我们的共享网关，以及为使用共享网关的应用程序创建工作区。

### TSB 设置
首先，我们将创建一个 TSB 租户来保存我们的共享入口示例；在实际部署中，你可以使用现有的租户或为这类用途创建一个共享基础设施租户：


```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: tetrate
  name: shared-ingress-example
spec:
  displayName: Shared Ingress Example
  description: Tenant for the Shared Ingress example
```

然后我们将为我们的共享入口创建一个工作区和组：
```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: shared-ingress-example
  name: ingress
spec:
  displayName: Shared Ingress
  description: Workspace for the shared ingress
  namespaceSelector:
    names:
      - "*/shared-ingress-ns"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: shared-ingress-example
  workspace: ingress
  name: shared-app-gateway
spec:
  configMode: BRIDGED
  namespaceSelector:
    names:
      - "*/shared-ingress-ns"
```
`tctl apply` 所有这些文件。

### 每个共享网关实例

最后我们部署共享网关本身：
```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: shared-gateway
  namespace: shared-ingress-ns
spec:
  kubeSpec:
    service:
      type: LoadBalancer
```

你需要在要托管共享入口网关部署的每个集群中运行 `kubectl apply` 命令来应用此文件。

## 配置共享网关

现在我们可以继续配置共享网关部署，可以通过以下方式之一完成：

- 在共享网关工作区中发布配置

或者

- 在应用程序工作区中发布配置

在这两种情况下，我们都会使用 `workloadSelector` 来定位网关。在应用程序工作区的情况下，我们还需要在网关部署上进行一些额外的配置。

{{<callout "warning" "为获得最佳效果，请勿在同一个共享网关上混合使用桥接模式和直连模式">}}
TSB 的桥接模式有助于确保来自不同团队的配置被隔离，从而减轻了常见的共享命运故障。但 TSB 无法为直连模式配置提供相同的保证。TSB 支持在针对同一个共享网关时同时使用桥接模式和直连模式配置，但无法在这样做时保证桥接模式的所有安全保证。因此，我们建议使用桥接模式的团队使用单独的共享网关部署，而使用直连模式的团队则与直连模式的 Istio 配置隔离开来，从而充分受益于 TSB 桥接模式的安全保证。
{{</callout>}}

## 在共享网关工作区中发布配置
对于任何给定应用程序，其共享网关配置将应用于 __共享网关工作区__。

{{<callout note "存储 TLS 证书的位置">}}
对于启用了 TLS 的应用程序，共享网关将需要在与共享网关相同的命名空间中应用证书。
{{</callout>}}

以下是创建我们将在接下来的示例中使用的 secret 的示例：

```bash
kubectl -n shared-ingress-ns create secret tls httpbin-certs \
  --key certs/httpbin.key \
  --cert certs/httpbin.crt
```

选择 *一种* 方法来通过共享网关配置应用程序入口：

- 通过 IngressGateway 进行桥接模式配置
- 通过 Istio Gateway 和 VirtualService 进行直连模式配置

### 通过 IngressGateway 进行桥接模式配置
我们可以在 TSB 中配置一个 `IngressGateway`，以将流量从共享网关路由到我们的应用程序：


```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  organization: tetrate
  tenant: shared-ingress-example
  workspace: ingress
  group: shared-app-gateway
  name: ingress-httpbin
spec:
  # Use the namespace from our IngressGateway with an app label that matches the `name`.
  workloadSelector:
    namespace: shared-ingress-ns
    labels:
      app: shared-gateway # `name` from our IngressGateway
  http:
  - name: httpbin
    port: 443
    hostname: httpbin.tetrate.com
    tls:
      mode: SIMPLE
      secretName: httpbin-certs
    routing:
      rules:
      - match:
        - headers:
            ":method":
              exact: "GET"
        route:
          host: httpbin/httpbin.httpbin.svc.cluster.local
```
请运行 `tctl apply` 命令来应用上述配置，从而通过共享网关实现对 `httpbin.tetrate.com` 到 `httpbin` 服务的路由。

你可以使用以下命令发送一些流量到我们的 httpbin 以验证 TSB 配置。


```bash
export GATEWAY_IP=$(kubectl -n shared-ingress-ns get service shared-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -k --resolve httpbin.tetrate.com:443:$GATEWAY_IP https://httpbin.tetrate.com/
```

### 直接模式：使用 VirtualServices 配置

我们也可以通过 Istio 配置直接配置共享网关，方法是创建一个 `Gateway` 和一个 `VirtualService`。在许多环境中，`Gateway` 将由中央团队管理，你只需要发布 `VirtualService` -- 你可以通过运行 `kubectl get gateway --namespace shared-ingress-ns` 来进行检查：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-shared-gateway
  namespace: shared-ingress-ns
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: shared-ingress-example
    tsb.tetrate.io/workspace: ingress
    tsb.tetrate.io/gatewayGroup: shared-app-gateway
spec:
  selector:
    app: shared-gateway # `name` from our IngressGateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "httpbin.tetrate.com"
    tls:
      mode: SIMPLE
      credentialName: httpbin-certs
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
  namespace: shared-ingress-ns
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: shared-ingress-example
    tsb.tetrate.io/workspace: ingress
    tsb.tetrate.io/gatewayGroup: shared-app-gateway
spec:
  hosts:
  - "httpbin.tetrate.com"
  gateways:
  - httpbin-shared-gateway
  http:
  - match:
    - uri:
        prefix: /get
    - method:
        exact: "GET"
    route:
      - destination:
          host: httpbin.httpbin
```
请运行 `tctl apply` 上述命令以应用配置，从而通过共享网关实现对 `httpbin.tetrate.com` 到 `httpbin` 服务的路由。

你可以使用以下命令发送一些流量到我们的 httpbin 以验证 TSB 配置。


```bash
export GATEWAY_IP=$(kubectl -n shared-ingress-ns get service shared-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -k --resolve httpbin.tetrate.com:443:$GATEWAY_IP https://httpbin.tetrate.com/
```

## 在应用工作区中发布配置

要启用跨命名空间的网关配置（我们在这里使用它允许应用程序从其自己的命名空间配置共享网关），我们需要更新共享网关部署以接收来自其他命名空间的配置。

{{<callout note "存储 TLS 证书的位置">}}
我们在应用工作区中配置网关对象，但我们仍然需要将证书存储在共享入口命名空间中，因为入口 pod 仍然驻留在共享入口命名空间中
{{</callout>}}

以下是我们将在接下来的示例中使用的创建密钥的示例：

```bash
kubectl -n shared-ingress-ns create secret tls httpbin-certs \
  --key certs/httpbin.key \
  --cert certs/httpbin.crt
```

由于 TSB 默认使用基于工作区的入口网关方法，我们需要应用该覆盖。Istio 将从应用程序工作区中发现网关对象，而不仅仅是从共享入口命名空间中发现。

````yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.components.pilot.k8s.env[-1]
            value:
              name: PILOT_SCOPE_GATEWAY_TO_NAMESPACE
              value: "false"
````

#### TSB 设置

通常，应用团队将在 Kubernetes 中拥有自己的工作区。在这种情况下，继续 [`httpbin` 示例](../../../reference/samples/httpbin)，我们假设该应用部署在 `httpbin` 命名空间中。因此，我们有了 `httpbin` 工作区来存储我们的配置：

```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: shared-ingress-example
  name: httpbin
spec:
  displayName: Httpbin Workspace
  namespaceSelector:
    names:
      - "*/httpbin"
```

请运行 `tctl apply` 上述命令以确保示例应用的工作区存在。

#### 配置路由

启用了我们网关的跨命名空间发现后，配置方式与上述步骤完全相同，唯一的区别是我们的所有配置都发布到应用命名空间中，而不是共享网关命名空间 (`shared-ingress-ns`)。

请选择以下一种方法来通过共享网关配置应用程序入口：

- 通过 IngressGateway 使用 Bridged 模式
- 通过 Istio Gateway 和 VirtualService 使用 Direct 模式

### 使用 IngressGateway 进行 Bridged 模式配置

我们可以通过在 TSB 中配置一个 `IngressGateway` 来将流量从共享网关路由到我们的应用程序：

```yaml
# Ensure we have a GatewayGroup to hang our config on
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: shared-ingress-example
  workspace: httpbin
  name: httpbin-gateway
spec:
  configMode: BRIDGED
  namespaceSelector:
    names:
      - "*/httpbin"
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  organization: tetrate
  tenant: shared-ingress-example
  workspace: httpbin     # changed vs shared config
  group: httpbin-gateway # changed vs shared config
  name: ingress-httpbin
spec:
  # Use the namespace from our IngressGateway with an app label that matches the `name`.
  workloadSelector:
    namespace: shared-ingress-ns
    labels:
      app: shared-gateway # `name` from our IngressGateway
  http:
  - name: httpbin
    port: 443
    hostname: httpbin.tetrate.com
    tls:
      mode: SIMPLE
      secretName: httpbin-certs
    routing:
      rules:
      - match:
        - headers:
            ":method":
              exact: "GET"
        route:
          host: httpbin/httpbin.httpbin.svc.cluster.local
```
请运行 `tctl apply` 上述命令以应用配置，从而通过共享网关实现对 `httpbin.tetrate.com` 到 `httpbin` 服务的路由。

你可以使用以下命令发送一些流量到我们的 httpbin 以验证 TSB 配置。


```bash
export GATEWAY_IP=$(kubectl -n shared-ingress-ns get service shared-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -k --resolve httpbin.tetrate.com:443:$GATEWAY_IP https://httpbin.tetrate.com/
```

### 使用 VirtualServices 进行 Direct 模式配置

我们也可以通过 Istio 配置直接配置共享网关，方法是创建一个 `Gateway` 和一个 `VirtualService`。在许多环境中，`Gateway` 将由中央团队管理，你只需要发布 `VirtualService`：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
  namespace: httpbin # changed vs shared config
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: shared-ingress-example
    tsb.tetrate.io/workspace: httpbin
    tsb.tetrate.io/gatewayGroup: httpbin-gateway
spec:
  selector:
    app: shared-gateway # `name` from our IngressGateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "httpbin.tetrate.com"
    tls:
      mode: SIMPLE
      credentialName: httpbin-certs
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
  namespace: httpbin # changed vs shared config
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: shared-ingress-example
    tsb.tetrate.io/workspace: httpbin
    tsb.tetrate.io/gatewayGroup: httpbin-gateway
spec:
  hosts:
  - "httpbin.tetrate.com"
  gateways:
  - httpbin-gateway # changed vs shared config
  http:
  - match:
    - uri:
        prefix: /get
    - method:
        exact: "GET"
    route:
      - destination:
          host: httpbin.httpbin
```
请运行上述命令以应用配置，从而通过共享网关实现对 `httpbin.tetrate.com` 到 `httpbin` 服务的路由。

你可以使用以下命令发送一些流量到我们的 httpbin 以验证 TSB 配置。


```bash
export GATEWAY_IP=$(kubectl -n shared-ingress-ns get service shared-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -k --resolve httpbin.tetrate.com:443:$GATEWAY_IP https://httpbin.tetrate.com/
```
