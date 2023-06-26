---
weight: 1
linkTitle: 蓝绿部署
title: 蓝绿部署策略
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["蓝绿部署","Argo Rollouts","部署策略"]
---

蓝绿部署允许用户减少同时运行多个版本的时间。

## 概述

除了管理 ReplicaSet 外，在 `BlueGreenUpdate` 策略期间，Rollout 控制器还将修改 Service 资源。Rollout 规范要求用户在同一命名空间中指定对活动服务的引用以及可选的预览服务。活动服务用于将常规应用程序流量发送到旧版本，而预览服务用于将流量漏斗到新版本。Rollout 控制器通过向这些服务的选择器注入 ReplicaSet 的唯一哈希来确保正确的流量路由。这允许 Rollout 定义一个活动和预览堆栈以及从预览到活动的过程。

当 Rollout 的 `.spec.template` 字段发生更改时，控制器将创建新的 ReplicaSet。如果活动服务没有将流量发送到 ReplicaSet，则控制器将立即开始将流量发送到 ReplicaSet。否则，活动服务将指向旧 ReplicaSet，而 ReplicaSet 变得可用。一旦新的 ReplicaSet 变得可用，控制器将修改活动服务以指向新的 ReplicaSet。在等待 `.spec.strategy.blueGreen.scaleDownDelaySeconds` 配置的一些时间之后，控制器将缩小旧 ReplicaSet。

🔔 重要：当 Rollout 在服务上更改选择器时，所有节点更新其 IP 表以将流量发送到新的 Pod 而不是旧的 Pod 之前存在传播延迟。在此延迟期间，如果节点尚未更新，则流量将被定向到旧 Pod。为了防止将数据包发送到杀死旧 Pod 的节点，Rollout 使用 `scaleDownDelaySeconds` 字段为节点提供足够的时间来广播 IP 表更改。

## 示例

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollout-bluegreen
spec:
  replicas: 2
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: rollout-bluegreen
  template:
    metadata:
      labels:
        app: rollout-bluegreen
    spec:
      containers:
      - name: rollouts-demo
        image: argoproj/rollouts-demo:blue
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
strategy:
    blueGreen:
    # activeService 指定要在升级时使用新模板哈希更新的服务。
    # 对于蓝绿更新策略，此字段为必填字段。
    activeService: rollout-bluegreen-active
    # previewService 指定要在推广之前使用新模板哈希更新的服务。
    # 这使得预览栈可以在不提供生产流量的情况下可达。
    # 此字段为可选字段。
    previewService: rollout-bluegreen-preview
    # autoPromotionEnabled 通过在推广之前立即暂停 Rollout 来禁用新堆栈的自动推广。
    # 如果省略，默认行为是在 ReplicaSet 完全准备/可用后立即推广新堆栈。
    # 可以使用以下命令恢复 Rollout：`kubectl argo rollouts promote ROLLOUT`
    autoPromotionEnabled: false
```

## 可配置的特性

以下是将更改 BlueGreen 部署行为的可选字段：

```
  spec:
    strategy:
      blueGreen:
        autoPromotionEnabled: boolean
        autoPromotionSeconds: *int32
        antiAffinity: object
        previewService: string
        prePromotionAnalysis: object
        postPromotionAnalysis: object
        previewReplicaCount: *int32
        scaleDownDelaySeconds: *int32
        scaleDownDelayRevisionLimit: *int32
```

## 事件序列

以下描述了蓝绿更新期间发生的事件序列。

1. 从完全推广的稳定状态开始，使用修订版本 1 的 ReplicaSet 指向 `activeService` 和 `previewService`。
2. 用户通过修改 Pod 模板 (`spec.template.spec`) 启动更新。
3. 创建大小为 0 的修订版本 2 ReplicaSet。
4. 修改预览服务以指向修订版本 2 ReplicaSet。`activeService` 仍指向修订版本 1。
5. 如果使用了 `previewReplicaCount`，则将修订版本 2 ReplicaSet 缩放到 `spec.replicas` 或 `previewReplicaCount`。
6. 一旦修订版本 2 ReplicaSet Pod 完全可用，`prePromotionAnalysis` 就会开始。
7. 在 `prePromotionAnalysis` 成功后，如果 `autoPromotionEnabled` 为 false 或 `autoPromotionSeconds` 不为零，则蓝绿色暂停。
8. 通过手动或自动超过 `autoPromotionSeconds` 来恢复 Rollout。
9. 如果使用了 `previewReplicaCount`，则将修订版本 2 ReplicaSet 缩放到 `spec.replicas`。
10. Rollout 通过将 `activeService` 更新为指向新的 ReplicaSet 来“推广”修订版本 2 ReplicaSet。此时，没有服务指向修订版本 1
11. `postPromotionAnalysis` 分析开始
12. 一旦 `postPromotionAnalysis` 成功完成，更新成功，修订版本 2 ReplicaSet 被标记为稳定。Rollout 被认为是完全推广。
13. 在等待 `scaleDownDelaySeconds`（默认为 30 秒）之后，修订版本 1 ReplicaSet 被缩小。

### autoPromotionEnabled

AutoPromotionEnabled 将使 Rollout 在新的 ReplicaSet 健康后自动将其推广到活动服务。如果未指定，该字段的默认值为 true。

默认为 true

### autoPromotionSeconds

AutoPromotionSeconds 将使 Rollout 在自动暂停状态下进入 AutoPromotionSeconds 时间后自动将新的 ReplicaSet 推广到活动服务。如果 `AutoPromotionEnabled` 字段设置为 false，则将忽略此字段。

默认为 nil

### antiAffinity

有关更多信息，请查看 Anti Affinity 文档。

默认为 nil

### maxUnavailable

在更新期间可以不可用的 Pod 的最大数量。该值可以是绝对数字（例如：5）或所需 Pod 的百分比（例如：10%）。如果 MaxSurge 为 0，则不能为 0。

默认为 0

### prePromotionAnalysis

在将流量切换到新版本之前，配置 Analysis。AnalysisRun 可用于在 AnalysisRun 成功完成之前阻止 Service 选择器切换。分析运行的成功或失败决定 Rollout 是否切换流量，或完全中止 Rollout。

默认为 nil

### postPromotionAnalysis

在将流量切换到新版本后配置 Analysis。如果分析运行失败或出错，则 Rollout 进入中止状态并将流量切换回以前的稳定 Replicaset。如果指定了 `scaleDownDelaySeconds`，控制器将在 `scaleDownDelay` 时取消任何 AnalysisRuns 以缩小 ReplicaSet。如果省略它，并且指定了后期分析，则仅在 AnalysisRun 完成后缩小 ReplicaSet（最少为 30 秒）。

默认为 nil

### previewService

PreviewService 字段引用将被修改以在新 ReplicaSet 之前发送流量的 Service。一旦新 ReplicaSet 开始接收来自活动服务的流量，预览服务也将被修改以将流量发送到新 ReplicaSet。Rollout 始终确保预览服务将流量发送到最新的 ReplicaSet。因此，如果在将旧版本推广到活动服务之前引入新版本，则控制器将立即切换到全新的版本。

此功能用于提供可以用于测试应用程序的新版本的终点。

默认为空字符串

### previewReplicaCount

PreviewReplicaCount 字段将指示新版本的应用程序应运行的副本数。一旦应用程序准备好推广到活动服务，控制器将扩展新的 ReplicaSet 到 `spec.replicas` 的值。在测试阶段期间，此功能的主要用途是节省资源。如果应用程序不需要完全缩放应用程序进行测试，则此功能可以帮助节省一些资源。

如果省略，则预览 ReplicaSet 堆栈将缩放到 100% 的副本。

### scaleDownDelaySeconds

ScaleDownDelaySeconds 用于在将活动服务切换到新 ReplicaSet 后延迟缩小旧 ReplicaSet。

默认为 30

### scaleDownDelayRevisionLimit

ScaleDownDelayRevisionLimit 限制保留在活动服务中的旧 ReplicaSet 数量，直到从活动服务中删除后的 scaleDownDelay。如果省略，则将保留所有 ReplicaSets 以供指定的 scaleDownDelay。
