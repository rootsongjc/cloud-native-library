---
title: "网络策略"
weight: 11
---

## 网格内的网络策略

在服务网格的背景下，[网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)是一组规则和配置，定义了各种微服务如何通过网络相互通信。

这些策略在控制流量流动、强制安全措施和维护服务网格架构的合规性方面起着关键作用。

网络策略使组织能够通过指定允许的服务、协议、端口以及可交换的数据类型来控制服务之间的通信，这发生在 L3/L4 层。

这种精确的控制可以阻止未经授权的访问，减少容易受攻击的区域，并确保只在可信任的源之间进行通信。

## 网络策略与零信任架构

除了服务网格的思想，零信任架构（ZTA）安全方法认为，不应自动信任任何用户或设备，无论其是否来自组织内部或外部网络。

ZTA 强调通过严格的身份验证和授权步骤来确认身份，并允许访问，而不是依赖于老式的边界防御。你可以在[这里](https://tetrate.io/learn/zero-trust/nist-zero-trust-architecture/)了解更多信息。

## 面临的挑战是什么？

尽管 TSB 目前通过智能用户控制和定制的分层访问策略提供了许多安全优势，但当组织试图将 Cilium 或 Calico 网络策略与服务网格基础架构中的现有基于身份的访问策略集成时，就会面临挑战。

这种情况需要管理两组不同的策略，由不同的角色监督 - 安全管理员和平台所有者，这增加了许多组织今天所遇到的复杂性。

组织如何保持基于身份的网格访问控制策略和基于 L3/L4 的网络策略保持同步。这就是 TSB 引入 `网络策略建议` 来解决的问题。

## 什么是网络策略建议？

从 TSB 1.7.0 版本开始，TSB 具备了建议 Kubernetes 网络策略的能力。这些建议是根据平台所有者或应用程序所有者在 TSB 中设置的分层访问控制策略而导出的。

建议的网络策略已经通过 TSB 配置允许/拒绝的流量，这些策略作为一种便利提供，并以一种容易由安全团队和 Kubernetes 管理员管理和理解的形式提供。你可以检查网络策略，以验证 TSB 是否对你的网格应用适用适当的访问控制策略。

可以通过在 `ControlPlane` CR 的 XCP 组件中将 `ENABLE_NETWORK_POLICY_TRANSLATION` 设置为 `true` 来在每个控制平面集群上启用此功能。一旦启用，建议的网络策略将作为专用控制平面集群中的命名空间范围配置映射存储。管理网络特定访问控制的平台所有者/安全所有者可以从配置映射中检索这些策略，并在其所需的命名空间中验证和应用这些策略。

## 用例是什么？

TSB 主要关注以下用例。

### 用例 1：建议保护南北流量

当用户将 [Gateway](../refs/tsb/gateway/v2/gateway) 对象配置为 [Edge Gateway](../concepts/glossary#edge-gateway) 或 [Ingress Gateway](../concepts/glossary#ingress-gateway) 时，TSB 可以确保通过建议的网络策略仅允许外部流量到达的暴露端口，例如 `80` 或 `443`，仅路由到 TSB 网关工作负载的端口，即 `8080`，`8443` 和 `15443`。

{{<callout note "先决条件">}}
在应用 TSB 推荐的策略以使其生效之前，需要确保在各自的 Kubernetes 集群中启用了容器网络接口（CNI）插件的网络策略强制执行。
{{</callout>}}

### TSB 配置

配置一个 Edge Gateway 以暴露多个主机并路由到其他 Tier2 集群，其中部署了 IngressGateway 并配置了相同的主机名。

```yaml
# gateway-config.yaml
apiVersion: v1
kind: List
items:
  - apiVersion: install.tetrate.io/v1alpha1
    kind: Tier1Gateway
    metadata:
      name: edge-gateway
      namespace: edge-gw
    spec:
      kubeSpec:
        service:
          type: LoadBalancer
  - apiVersion: gateway.tsb.tetrate.io/v2
    kind: Gateway
    metadata:
      name: edge-gateway
      namespace: edge-gw
      annotations:
        tsb.tetrate.io/organization: tetrate
        tsb.tetrate.io/tenant: tetrate
        tsb.tetrate.io/workspace: edge-gw-ws
        tsb.tetrate.io/gatewayGroup: edge-gw-gp
    spec:
      workloadSelector:
        namespace: edge-gw
        labels:
          app: edge-gateway
      http:
      - name: bookinfo
        hostname: bookinfo.tetrate.io
        port: 80
        routing:
          rules:
            - match:
                - uri

:
                    prefix: "/productpage"
              route:
                clusterDestination:
                  clusters:
                    - name: gke-tetrate-us-west1-1
                      weight: 100
            - match:
                - uri:
                    prefix: "/api/v1/products"
              route:
                clusterDestination:
                  clusters:
                    - name: gke-tetrate-us-east1-2
                      weight: 100
```

当你应用上述配置后，根据 TSB 创建的默认 Istio `AuthZ` 策略和创建用于暴露端口的 k8s 服务对象的 `Tier1Gateway` 安装 API 配置，TSB 将开始将两者转换为建议的网络策略配置的配置映射。

```bash
kubectl get configmap -l xcp.tetrate.io/recommended-network-policy=true -n edge-gw
```
```text title="Output"
NAME                     DATA   AGE
np-authz-edge-gateway    1      31s
np-edge-gateway          1      31s
```

在应用这些策略之前，检索配置映射并验证建议的网络策略，这些策略将限制仅在服务配置的暴露端口上进行入站流量。

```bash
kubectl get configmap -n edge-gw np-edge-gateway -o jsonpath='{.data.policy}' > edge-gw-policy.yaml
```

建议的网络策略将限制仅在服务配置的暴露端口上进行入站流量。

```yaml
# edge-gw-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  creationTimestamp: null
  labels:
    xcp.tetrate.io/recommended-network-policy: "true"
    xcp.tetrate.io/service: edge-gateway
  name: np-edge-gateway
  namespace: edge-gw
spec:
  ingress:
  - ports:
    - port: 15443
    - port: 8080
    - port: 8443
  podSelector:
    matchLabels:
      app: edge-gateway
      istio: ingressgateway
  policyTypes:
  - Ingress
status: {}
```

在集群上应用网络策略

```bash
kubectl apply -f edge-gw-policy.yaml
```

```bash
kubectl describe networkpolicy np-edge-gateway -n edge-gw
```
```text title="Output"
Name:         np-edge-gateway
Namespace:    edge-gw
Created on:   2023-08-16 21:40:49 +0530 IST
Labels:       xcp.tetrate.io/recommended-network-policy=true
              xcp.tetrate.io/service=edge-gateway
Annotations:  <none>
Spec:
  PodSelector:     app=edge-gateway,istio=ingressgateway
  Allowing ingress traffic:
    To Port: 15443/TCP
    To Port: 8080/TCP
    To Port: 8443/TCP
    From: <any> (traffic not restricted by source)
  Not affecting egress traffic
  Policy Types: Ingress
```

### 用例 2：建议保护东西流量

在典型的基于租户/团队/业务单元的访问限制中，当用户配置 2 个租户，即 `Tenant A` 和 `Tenant B`，并将 `deny_all` 配置为 `OrganizationSetting` 的默认值以拒绝所有服务之间的通信时，
当用户为 `Tenant A` 配置允许策略以与 `Tenant B` 下的 `workspace-frontend` 进行通信，但不允许与 `Tenant B` 下的 `workspace-backend` 进行通信时，
当 TSB 创建 Istio `AuthZ` 策略以执行此行为时，TSB 还将为用户创建建议的网络策略作为配置映射，以便用户在 L3/L4 层强制执行相同的行为。

### TSB 配置

创建以下配置：

- 创建一个新的租户 `Marketing` 并在 `Marketing` 租户下创建 2 个工作区
  - 工作区 `marketing-frontend`
    - 映射到 `cluster-1` 中的 `marketing-frontend` 命名空间
    - 在 `marketing-frontend` 命名空间中部署 `productpage`
  - 工作区 `marketing-backend` 
    - 映射到 `cluster-1` 中的 `marketing-backend` 命名空间
    - 在 `marketing-backend` 命名空间中部署 `details`、`reviews` 和 `ratings`
- 创建一个新的租户 `Payment` 并在 `Payment` 租户下创建一个工作区
  - 工作区 `payment-chanel`
    - 映射到 `cluster-1` 中的 `payment-channel` 命名空间
    - 在 `payment-channel` 命名空间中部署 `sleep` 服务
- 允许 `payment-channel` 仅与 `marketing-frontend` 进行通信，使用 `TenantSettings`

```yaml
apiVersion: tsb.tetrate.io/v2
kind: TenantSetting
metadata:
  name: default-setting
  annotations: 
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: marketing
spec:
  defaultSecuritySetting:
    authenticationSettings:
      trafficMode: REQUIRED
    authorization:
      mode: RULES
      rules:
        allow:
        - from:
            fqn: organizations/tetrate/tenants/payment
          to:
            fqn: organizations/tetrate/tenants/marketing/workspaces/marketing-frontend
        - from:
            fqn: organizations/tetrate/tenants/marketing
          to:
            fqn: organizations/tetrate/tenants/marketing
    displayName: default-setting
  displayName: default-setting
```

应用上述配置后，TSB 将创建以下 `AuthZ` 策略。

```bash
kubectl get authorizationpolicy -A
```
```text title="Output"
NAMESPACE            NAME                                     AGE
marketing-backend    allow                                    8m26s
marketing-frontend   allow                                    8m26s
payment-channel      allow                                    8m26s
```

根据你提供的要求，我已经翻译并改写了英文文档，使其更流利，并符合 Google 的最佳文档规范。以下是翻译后的 Markdown 文档：

```markdown
根据我们的配置，由于`marketing-frontend`和`marketing-backend`命名空间属于同一个租户`Marketing`，
属于`marketing-frontend`命名空间的工作负载被允许与属于`marketing-backend`的工作负载通信，但不允许与任何其他命名空间通信，例如`payment-channel`。

```bash
kubectl get authorizationpolicy allow -n marketing-backend -o yaml
```
```yaml title="输出"
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  annotations:
    tsb.tetrate.io/config-mode: bridged
    tsb.tetrate.io/etag: '"VeslxrLeGvQ="'
    tsb.tetrate.io/fqn: organizations/tetrate/tenants/marketing/workspaces/marketing-backend
    tsb.tetrate.io/runtime-etag: '"enVCG/QQ2fc="'
    xcp.tetrate.io/contentHash: a654b8f44747c21a28d0b44dcd193748
  creationTimestamp: "2023-07-11T10:18:25Z"
  generation: 1
  name: allow
  namespace: marketing-backend
  resourceVersion: "4382832"
  uid: 22c3265f-0be7-42da-9584-6913c2676f16
spec:
  rules:
  - from:
    - source:
        principals:
        - gke-sreehari-us-west1-1.tsb.local/ns/marketing-backend/*
        - gke-sreehari-us-west1-1.tsb.local/ns/marketing-frontend/*
```

但是，`marketing-fontend`允许来自属于`payment`租户和`marketing`租户下所有工作区的工作负载的请求。

```bash
kubectl get authorizationpolicy allow -n marketing-frontend -o yaml
```
```yaml title="输出"
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  annotations:
    tsb.tetrate.io/config-mode: bridged
    tsb.tetrate.io/etag: '"hjW1MOChsJU="'
    tsb.tetrate.io/fqn: organizations/tetrate/tenants/marketing/workspaces/marketing-frontend
    tsb.tetrate.io/runtime-etag: '"ZWzxphzAJEQ="'
    xcp.tetrate.io/contentHash: f6098fa68d84259a71b1c42b3152402a
  creationTimestamp: "2023-07-11T10:18:25Z"
  generation: 1
  name: allow
  namespace: marketing-frontend
  resourceVersion: "4382827"
  uid: d4beae2c-1f66-4dd5-9662-7dd397519155
spec:
  rules:
  - from:
    - source:
        principals:
        - gke-sreehari-us-east1-2.tsb.local/ns/payment-channel/*
        - gke-sreehari-us-west1-1.tsb.local/ns/marketing-backend/*
        - gke-sreehari-us-west1-1.tsb.local/ns/marketing-frontend/*
        - gke-sreehari-us-west1-1.tsb.local/ns/payment-channel/*
```

通过上述`AuthZ`基于策略，`payment-channel`命名空间中的`sleep`服务被允许调用`marketing-frontend`中的`productpage`，但不允许调用`marketing-backend`命名空间中的`details`、`reviews`和`ratings`。

```bash
kubectl exec "$(kubectl get pod -n payment-channel -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -n payment-channel -c sleep -- curl -s http://productpage.marketing-frontend.svc:9080/api/v1/products -v
```
```text title="输出"
< HTTP/1.1 200 OK
```

```bash
kubectl exec "$(kubectl get pod -n payment-channel -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -n payment-channel -c sleep -- curl -s http://details.marketing-backend.svc:9080/details/1 -v
```
```text title="输出"
RBAC: access denied
```

### 验证建议的基于AuthZ的网络策略

```bash
kubectl get configmap -l xcp.tetrate.io/recommended-network-policy=true,xcp.tetrate.io/authz-policy=allow -A
```
```text title="输出"
NAMESPACE            NAME             DATA   AGE
marketing-backend    np-authz-allow   1      1m2s
marketing-frontend   np-authz-allow   1      1m2s
payment-channel      np-authz-allow   1      1m2s
```

在`marketing-backend`命名空间中应用特定于authz的网络策略，以允许仅从`marketing-frontend`和`marketing-backend`命名空间中的Pod进行入口。

```bash
kubectl get configmap -n marketing-backend np-authz-allow -o jsonpath='{.data.policy}' > backend-policy.yaml
```

验证建议的策略

```yaml
# backend-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  annotations:
    tsb.tetrate.io/config-mode: bridged
    tsb.tetrate.io/etag: '"VeslxrLeGvQ="'
    tsb.tetrate.io/fqn: organizations/tetrate/tenants/marketing/workspaces/marketing-backend
    tsb.tetrate.io/runtime-etag: '"enVCG/QQ2fc="'
    xcp.tetrate.io/contentHash: f53ddeb9e43de1ca56fd3ea20c21b919
  creationTimestamp: null
  labels:
    xcp.tetrate.io/authz-policy: allow
    xcp.tetrate.io/recommended-network-policy: "true"
  name: np-authz-allow
  namespace: marketing-backend
spec:
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: marketing-frontend
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: marketing-backend
  podSelector: {}
  policyTypes:
  - Ingress


status: {}
```

在应用上述策略之后验证相同的请求，你将注意到在尝试从除了`marketing-frontend`和`marketing-backend`之外的任何命名空间调用`review`、`details`和`ratings`时请求被拒绝。

```bash
kubectl exec "$(kubectl get pod -n payment-channel -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -n payment-channel -c sleep -- curl -s http://details.marketing-backend.svc:9080/details/1 -v
```
```text title="输出"
upstream connect error or disconnect/reset before headers
```

### 故障排除

一旦在控制平面集群中启用了网络策略推荐功能，XCP 将考虑所有现有的命名空间，这些命名空间被映射到TSB工作空间作为网络策略翻译的候选命名空间。但是，用户可以选择在选定的集群上禁用网络策略配置映射，方法是在 XCP 组件的`ControlPlane` CR中将`ENABLE_NETWORK_POLICY_TRANSLATION`设置为`false`。

```yaml
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
          - path: spec.components.edgeServer.kubeSpec.deployment.env
            value:
            - name: ENABLE_NETWORK_POLICY_TRANSLATION
              value: "false"
      ...
   ...
```
