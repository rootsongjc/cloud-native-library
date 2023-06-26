---
weight: 1
title: "流量管理概览"
linkTitle: "概览"
date: '2023-06-21T16:00:00+08:00'
type: book
---

Argo Rollouts 是一个 Kubernetes 自定义资源定义 (Custom Resource Definition, CRD)，扩展了 Kubernetes Deployment Controller，它添加了渐进式交付（Progressive Delivery）和蓝绿部署（Blue Green Deployment）等交付策略。Argo Rollouts 可以与 Istio、Linkerd 等服务网格和其他流量管理工具集成。

## 流量管理

流量管理是通过控制数据平面，为应用程序创建智能的路由规则。这些路由规则可以操作流量，将其引导到应用程序的不同版本，从而实现渐进式交付。这些控制规则通过确保只有一小部分用户接收新版本，从而限制了新版本的波及范围。

实现流量管理有各种技术：

- 原始百分比（例如，5% 的流量应该流向新版本，而其余的流向稳定版本）
- 基于头的路由（例如，将带有特定标头的请求发送到新版本）
- 交叉流量，其中所有流量都被复制并并行发送到新版本（但响应被忽略）

## Kubernetes 中的流量管理工具

核心 Kubernetes 对象没有细粒度的工具来满足所有流量管理要求。在最多的情况下，Kubernetes 通过服务（Service）对象提供原生负载平衡功能，通过提供将流量路由到根据该服务选择器组合的 Pod 的端点。使用默认的核心服务对象无法实现流量镜像或通过标头路由，并且控制应用程序的不同版本的流量百分比的唯一方法是通过操作这些版本的副本计数。

服务网格填补了 Kubernetes 中的这些缺失功能。它们通过使用 CRD 和其他核心 Kubernetes 资源引入了新的概念和功能，以控制数据平面。

## Argo Rollouts 如何实现流量管理？

Argo Rollouts 通过操作服务网格资源来匹配 Rollout 的意图，从而实现流量管理。Argo Rollouts 目前支持以下服务网格：

- [AWS ALB Ingress Controller](../alb/)
- [Ambassador Edge Stack](../ambassador/)
- [Apache APISIX](../apisix/)
- [Istio](../istio/)
- [Nginx Ingress Controller](../nginx/)
- Service Mesh Interface (SMI)（SMI 已不再维护）
- [Traefik Proxy](../traefik/)
- [Multiple Providers](../mixed/)
- 如果需要其他实现，请在此处[提交问题](https://github.com/argoproj/argo-rollouts/issues)（或给它点赞，如果该问题已存在）

无论使用哪个服务网格，Rollout 对象都必须在其 spec 中设置金丝雀服务和稳定服务。以下是设置了这些字段的示例：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  ...
  strategy:
    canary:
      canaryService: canary-service
      stableService: stable-service
      trafficRouting:
       ...
```

控制器修改这些服务以将流量路由到适当的金丝雀和稳定 ReplicaSet，随着 Rollout 的进展，Service Mesh 使用这些服务来定义应该接收金丝雀和稳定流量的 Pod 组。

此外，使用流量管理时，Argo Rollouts 控制器需要以不同的方式处理 Rollout 对象。特别是，由 Rollout 拥有的稳定 ReplicaSet 在 Rollout 通过金丝雀步骤时仍然完全扩展。

由于流量由服务网格资源独立控制，控制器需要尽力确保稳定和新的 ReplicaSet 不会被发送到它们的流量压垮。通过保留稳定的 ReplicaSet 扩展，控制器确保稳定的 ReplicaSet 可以在任何时候处理 100% 的流量[^1]。新的 ReplicaSet 的行为与没有流量管理时相同。新的 ReplicaSet 副本计数等于最新的 SetWeight 步骤百分比乘以 Rollout 的总副本计数。该计算确保金丝雀版本不会接收超出其处理能力的流量。

## 基于托管路由和路由优先级的流量路由

### 流量路由器支持：（Istio）

启用流量路由时，你还可以让 argo rollouts 添加和管理除控制流量权重到金丝雀之外的其他路由。其中两个这样的路由规则是基于标头和镜像的路由。在使用这些路由时，我们还必须设置上游流量路由器的路由优先级。我们使用 `spec.strategy.canary.trafficRouting.managedRoutes` 字段来完成这项工作，这是一个数组，其中项目的顺序决定了优先级。这组路由也将按照指定的顺序放在手动定义的任何其他路由之上。

警告

在托管路由中列出的所有路由都将在 rollout 结束或中止时被删除。不要将任何手动创建的路由放入列表中。

以下是一个例子：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  ...
  strategy:
    canary:
      ...
      trafficRouting:
        managedRoutes:
          - name: priority-route-1
          - name: priority-route-2
          - name: priority-route-3
```

## 基于 Header 值的金丝雀流量路由

### 流量路由器支持：（Istio）

Argo Rollouts 有能力根据 HTTP 请求头值将所有流量发送到金丝雀服务。标头基础流量路由的步骤是 `setHeaderRoute`，具有标头的多个匹配器。

`name` - 标头路由的名称。

`match` - 标头匹配规则是一组 `headerName, headerValue` 对。

`headerName` - 要匹配的标头的名称。

`headerValue`- 包含 `exact` - 指定确切标头值的值、`regex` - 以正则表达式格式的值、`prefix` - 可以提供值的前缀。并非所有流量路由器都支持所有匹配类型。

要禁用基于标头的流量路由，只需指定 `setHeaderRoute`，并仅包含路由名称。

例如：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  ...
  strategy:
    canary:
      canaryService: canary-service
      stableService: stable-service
      trafficRouting:
        managedRoutes:
          - name: set-header-1
        istio:
          virtualService:
            name: rollouts-demo-vsvc
      steps:
      - setWeight: 20
      - setHeaderRoute: # 允许基于标头的流量路由
          name: "set-header-1"
          match:
          - headerName: Custom-Header1 # Custom-Header1=Mozilla
            headerValue:
              exact: Mozilla
          - headerName: Custom-Header2 # 或者 Custom-Header2 以 Mozilla 为前缀
            headerValue:
              prefix: Mozilla
          - headerName: Custom-Header3 # 或者 Custom-Header3 值匹配正则表达式：Mozilla(.*)
            headerValue:
              regex: Mozilla(.*)
      - pause: {}
      - setHeaderRoute:
          name: "set-header-1" # 禁用基于标头的流量路由
```

## 将流量路由镜像到金丝雀

### 流量路由器支持：（Istio）

Argo Rollouts 有能力根据各种匹配规则将流量镜像到金丝雀服务。将流量镜像到基于镜像的流量路由的步骤是 `setMirrorRoute`，具有标头的多个匹配器。

`name` - 镜像路由的名称。

`percentage` - 要镜像的匹配流量的百分比

`match` - 头路由的匹配规则，如果缺少此项，它将充当路由的删除。单个匹配块内的所有条件都具有 AND 语义，而匹配块列表具有 OR 语义。每个匹配内的每种类型（方法、路径、标头）必须具有一种且仅有一种匹配类型（完整、正则表达式、前缀）。并非所有匹配类型（完整、正则表达式、前缀）都受到所有流量路由器的支持。

要禁用基于镜像的流量路由，只需指定一个仅包含路由名称的 `setMirrorRoute`。

此示例将镜像 HTTP 流量的 35%，该流量匹配 `GET` 请求并具有 `/` 的 URL 前缀

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  ...
  strategy:
    canary:
      canaryService: canary-service
      stableService: stable-service
      trafficRouting:
        managedRoutes:
          - name: mirror-route
        istio:
          virtualService:
            name: rollouts-demo-vsvc
      steps:
        - setCanaryScale:
            weight: 25
      - setMirrorRoute:
          name: mirror-route
          percentage: 35
          match:
            - method:
                exact: GET
              path:
                prefix: /
      - pause:
          duration: 10m
      - setMirrorRoute:
          name: "mirror-route" # 移除基于镜像的流量路由
```

[^1]: Rollout 必须假定应用程序在完全扩展时可以处理 100% 的流量。它应该外包给 HPA 来检测如果 100% 不够，Rollout 是否需要更多的副本。