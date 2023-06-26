---
weight: 3
linkTitle: HPA
title: "水平 Pod 自动缩放"
date: '2023-06-21T16:00:00+08:00'
type: book
---

水平 Pod 自动缩放（HPA）根据观察到的 CPU 利用率或用户配置的指标自动调整 Kubernetes 资源拥有的 Pod 数量。为了实现这种行为，HPA 仅支持启用了 scale 端点的资源，该端点具有几个必需字段。scale 端点允许 HPA 了解资源的当前状态并修改资源以适当地进行扩展。Argo Rollouts 在 `0.3.0` 版本中添加了对 scale 端点的支持。在 HPA 修改资源后，Argo Rollouts 控制器负责在副本中协调该变化。由于 Rollout 中的策略非常不同，因此 Argo Rollouts 控制器会针对各种策略以不同的方式处理 scale 端点。下面是不同策略的行为。

## 蓝绿部署

HPA 将使用从接收来自活动服务的流量的 ReplicaSet 中获取的指标来缩放 `BlueGreen` 策略的 Rollouts。当 HPA 更改副本计数时，Argo Rollouts 控制器将首先缩放接收来自活动服务的 ReplicaSet，然后是接收来自预览服务的 ReplicaSet。控制器将缩放接收来自预览服务的 ReplicaSet，以准备在 Rollout 将预览切换为活动时使用。如果没有接收来自活动服务的 ReplicaSets，则控制器将使用与基本选择器匹配的所有 Pod 来确定缩放事件。在这种情况下，控制器将将最新的 ReplicaSet 缩放到新计数，并将较旧的 ReplicaSets 缩小。

## 金丝雀（基于 ReplicaSet）

HPA 将使用所有 Rollout 中的 ReplicaSets 的指标来缩放 `Canary` 策略的 Rollouts。由于 Argo Rollouts 控制器不控制发送流量到这些 ReplicaSets 的服务，因此它假设 Rollout 中的所有 ReplicaSets 都正在接收流量。

## 例子

下面是基于 CPU 指标缩放 Rollout 的 Horizontal Pod Autoscaler 的示例：

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-rollout-example
spec:
  maxReplicas: 6
  minReplicas: 2
  scaleTargetRef:
    apiVersion: argoproj.io/v1alpha1
    kind: Rollout
    name: example-rollout
  targetCPUUtilizationPercentage: 80
```

## 要求

为了使 HPA 能够操作 Rollout，托管 Rollout CRD 的 Kubernetes 集群需要 CRD 的子资源支持。该功能在 Kubernetes 版本 1.10 中作为 alpha 引入，并在 Kubernetes 版本 1.11 中过渡为 beta。如果用户想在 v1.10 上使用 HPA，则 Kubernetes 集群运营商将需要向 API 服务器添加自定义功能标志。在 1.10 之后，默认情况下会打开该标志。请查看以下[链接](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/)，了解有关设置自定义功能标志的更多信息。
