---
weight: 1
linkTitle: 简介
title: "Argo Rollouts 简介"
date: '2023-06-21T16:00:00+08:00'
type: book
---

## 什么是 Argo Rollouts？

Argo Rollouts 是一组 [Kubernetes 控制器](https://kubernetes.io/docs/concepts/architecture/controller/)和[自定义资源（CRD）](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)，为 Kubernetes 提供高级部署功能，例如蓝绿、金丝雀、金丝雀分析、实验和渐进式交付等功能。

Argo Rollouts 可选地与 [Ingress 控制器](https://kubernetes.io/docs/concepts/services-networking/ingress/)和服务网格集成，利用它们的流量整形能力在更新期间逐渐将流量转移到新版本。此外，Rollouts 可以查询和解释来自各种提供商的度量标准，以验证关键 KPI 并在更新期间驱动自动升级或回滚。

这是一个演示视频（点击在 Youtube 上观看）：

{{< youtube hIL0E2gLkf8 >}}

## 为什么选择 Argo Rollouts？

Kubernetes Deployment 对象支持滚动更新策略，该策略提供了一组基本的安全性保证（就绪探针）来保证更新期间的安全性。但是，滚动更新策略面临许多限制：

- 对滚动更新速度的控制很少
- 无法控制流量流向新版本
- 就绪探针不适用于更深入的、压力或一次性检查
- 没有查询外部度量标准以验证更新的能力
- 可以停止进程，但无法自动中止并回滚更新

因此，在大型高容量生产环境中，滚动更新往往被认为是过于冒险的更新过程，因为它无法控制爆炸半径，可能过于激进地进行滚动更新，并且在发生故障时无法提供自动回滚。

## 控制器特点

- 蓝绿更新策略
- 金丝雀更新策略
- 精细、加权的流量转移
- 自动回滚和升级
- 手动判断
- 可自定义的度量标准查询和业务 KPI 分析
- Ingress 控制器集成：NGINX、ALB、Apache APISIX
- 服务网格集成：Istio、Linkerd、SMI
- 同时使用多个提供程序：SMI + NGINX、Istio + ALB 等。
- 度量提供程序集成：Prometheus、Wavefront、Kayenta、Web、Kubernetes Jobs、Datadog、New Relic、Graphite、InfluxDB

## 快速开始

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

请按照完整的 [入门指南](../getting-started/)，演示创建并更新一个滚动对象。

## 它是如何工作的？

与 [Deployment 对象](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) 类似，Argo Rollouts 控制器将管理 [ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) 的创建、扩展和删除。这些 ReplicaSet 是由 Rollout 资源中的 `spec.template` 字段定义的，该字段使用与 Deployment 对象相同的 pod 模板。

当更改 `spec.template` 时，这表明 Argo Rollouts 控制器将引入一个新的 ReplicaSet。该控制器将使用 `spec.strategy` 字段中设置的策略来确定如何从旧 ReplicaSet 进行滚动更新到新 ReplicaSet。一旦新 ReplicaSet 缩放（并可选地通过 [分析](../analysis/)），控制器将将其标记为“stable”。

如果在从稳定的 ReplicaSet 到新的 ReplicaSet 的转换过程中 `spec.template` 发生其他更改（即，在滚动更新过程中更改应用程序版本），则先前的新 ReplicaSet 将被缩小，控制器将尝试推进反映更新的 `spec.template` 字段的 ReplicasSet。有关每个策略行为的更多信息，请参见 [Rollout 规范](../rollout/specification/) 部分。

## Argo Rollouts 的用例

- 用户想在开始为生产流量服务之前对新版本进行最后一分钟的功能测试。使用 BlueGreen 策略，Argo Rollouts 允许用户指定预览服务和活动服务。Rollout 将配置预览服务以将流量发送到新版本，而活动服务仍将接收生产流量。一旦用户满意，他们可以将预览服务升级为新的活动服务。([示例](https://github.com/argoproj/argo-rollouts/blob/master/examples/rollout-bluegreen.yaml))
- 在新版本开始接收实时流量之前，需要执行一组通用步骤。使用 BlueGreen 策略，用户可以启动新版本，而不会从活动服务接收流量。一旦这些步骤完成执行，Rollout 可以将流量切换到新版本。
- 用户希望将生产流量的一小部分分配给他们的应用程序的新版本，持续几个小时。之后，他们想要缩小新版本并查看一些指标，以确定新版本与旧版本相比是否性能良好。然后，他们将决定是否要将新版本滚动到所有生产流量或坚持使用当前版本。使用金丝雀策略，Rollout 可以将新版本的 ReplicaSet 扩展到接收指定百分比的流量，等待指定时间后将百分比设置回 0，然后等待满意后再滚动到服务所有流量。([示例](https://github.com/argoproj/argo-rollouts/blob/master/examples/rollout-analysis-step.yaml))
- 用户希望慢慢将新版本的生产流量增加。他们首先给它一小部分实时流量，并等待一段时间，然后再给新版本更多的流量。最终，新版本将接收所有生产流量。使用金丝雀策略，用户可以指定他们希望新版本接收的百分比以及百分比之间的等待时间。([示例](https://github.com/argoproj/argo-rollouts/blob/master/examples/rollout-canary.yaml))
- 用户希望使用 Deployment 的常规滚动更新策略。如果用户使用金丝雀策略且没有步骤，则 Rollout 将使用最大浮动和最大不可用值进行滚动到新版本。([示例](https://github.com/argoproj/argo-rollouts/blob/master/examples/rollout-rolling-update.yaml))

## 示例

你可以在以下位置查看更多 Rollouts 示例：

- [示例目录](https://github.com/argoproj/argo-rollouts/tree/master/examples)
- [Argo Rollouts 演示应用程序](https://github.com/argoproj/rollouts-demo)
