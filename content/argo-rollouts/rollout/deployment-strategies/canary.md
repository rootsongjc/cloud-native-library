---
weight: 2
linkTitle: 金丝雀部署
title: 金丝雀部署
date: '2023-06-21T16:00:00+08:00'
type: book
tags: ["金丝雀部署","部署策略","Argo Rollouts"]
---

金丝雀发布是一种部署策略，操作员将新版本的应用程序释放到生产流量的一小部分中。

## 概述

由于没有关于金丝雀部署的共识标准，因此 Rollouts Controller 允许用户概述他们想要运行其金丝雀部署的方式。用户可以定义一个控制器使用的步骤列表，以在`.spec.template`发生更改时操作 ReplicaSets。在新的 ReplicaSet 被提升为稳定版本并且旧版本被完全缩减之前，每个步骤将被评估。

每个步骤可以有两个字段。`setWeight`字段指定应发送到金丝雀的流量百分比，`pause`结构指示 Rollout 暂停。当控制器到达 Rollout 的`pause`步骤时，它将向`.status.PauseConditions`字段添加一个`PauseCondition`结构。如果`pause`结构中的`duration`字段设置，Rollout 将在等待`duration`字段的值之前不会进入下一个步骤。否则，Rollout 将无限期等待该 Pause 条件被删除。通过使用`setWeight`和`pause`字段，用户可以描述他们想要如何进入新版本。以下是金丝雀策略的示例。

🔔 重要：如果金丝雀 Rollout 未使用[流量管理](../traffic-management/)，则 Rollout 将尽最大努力在新版本和旧版本之间实现最后一个`setWeight`步骤中列出的百分比。例如，如果 Rollout 有 10 个副本和 10％ 的第一个`setWeight`步骤，则控制器将将新的期望 ReplicaSet 缩放为 1 个副本，将旧的稳定 ReplicaSet 缩放为 9 个。在 setWeight 为 15％的情况下，Rollout 尝试通过向上舍入计算（即，新的 ReplicaSet 具有 2 个 Pod，因为 10 的 15％向上舍入为 2，旧的 ReplicaSet 具有 9 个 Pod，因为 10 的 85％向上舍入为 9）获得更精细的控制百分比而不使用大量副本。那个用户应该使用流量管理功能。

## 示例

```yaml
 apiVersion: argoproj.io/v1alpha1
 kind: Rollout
 metadata:
   name: example-rollout
 spec:
   replicas: 10
   selector:
     matchLabels:
       app: nginx
   template:
     metadata:
       labels:
         app: nginx
     spec:
       containers:
       - name: nginx
         image: nginx:1.15.4
         ports:
         - containerPort: 80
   minReadySeconds: 30
   revisionHistoryLimit: 3
   strategy:
     canary: #表明 Rollout 应使用金丝雀策略
       maxSurge: "25%"
       maxUnavailable: 0
       steps:
       - setWeight: 10
       - pause:
           duration: 1h # 1 小时
       - setWeight: 20
       - pause: {} # 無限期暂停
```

## 暂停持续时间

暂停持续时间可以用可选的时间单位后缀指定。有效的时间单位为“s”、“m”、“h”。如果未指定，则默认为“s”。

```yaml
 spec:
   strategy:
     canary:
       steps:
         - pause: { duration: 10 }  # 10 秒
         - pause: { duration: 10s } # 10 秒
         - pause: { duration: 10m } # 10 分钟
         - pause: { duration: 10h } # 10 小时
         - pause: {}                # 无限期暂停
```

如果暂停步骤没有指定`duration`，则 Rollout 将无限期暂停。要取消暂停，请使用 argo kubectl 插件`promote`命令。

```bash
 # 提升到下一步
 kubectl argo rollouts promote <rollout>
```

## 动态金丝雀规模（带流量路由）

默认情况下，Rollout 控制器将根据当前步骤的`trafficWeight`来扩展金丝雀，以匹配流量权重。例如，如果当前权重为 25％，并且有四个副本，则为了匹配流量权重，金丝雀将被缩放为 1。

可以控制金丝雀副本在步骤期间的缩放比例，以便它不必必须匹配流量权重。以下是此类用例：

1. 新版本不应公开（`setWeight: 0`），但你希望将金丝雀扩展到进行测试。
2. 你希望最小化金丝雀堆栈的规模，并使用一些基于标头的流量整形到金丝雀，而`setWeight`仍然设置为 0。
3. 你希望将金丝雀扩展到 100％，以便进行流量阴影处理。

🔔 重要：仅当使用带有流量路由的金丝雀策略时，才可以设置金丝雀比例。

要在步骤期间控制金丝雀比例和权重，请使用`setCanaryScale`步骤，并指示金丝雀应使用哪个比例：

- 显式副本计数而不更改流量权重（`replicas`）
- spec.replicas 中的明确的权重百分比，而不更改流量权重（`weight`）
- 是否匹配当前金丝雀的`setWeight`步骤（`matchTrafficWeight：true或false`）

```yaml
 spec:
   strategy:
     canary:
       steps:
       # 显式计数
       - setCanaryScale:
           replicas: 3
       # spec.replicas 的百分比
       - setCanaryScale:
           weight: 25
       # matchTrafficWeight 返回与 canary 流量权重匹配的默认行为
       - setCanaryScale:
           matchTrafficWeight: true
```

在使用具有显式值的`setCanaryScale`的情况下，如果与`setWeight`步骤一起使用时不正确，则必须小心。如果不正确地完成，则会将不平衡的流量比例定向到金丝雀（与 Rollout 的比例成比例）。例如，以下一组步骤将导致 90％的流量仅由 10％的 Pod 提供服务：

```yaml
 spec:
   replicas: 10
   strategy:
     canary:
       steps:
       # 1 金丝雀 Pod（spec.replicas 的 10％）
       - setCanaryScale:
           weight: 10
       # 90％的流量到 1 个金丝雀 Pod
       - setWeight: 90
       - pause: {}
```

上述情况是由于`setWeight`在`setCanaryScale`之后的更改行为引起的。要重置，请设置`matchTrafficWeight：true`，并将恢复`setWeight`行为，即，后续`setWeight`将创建与流量权重匹配的金丝雀副本。

## 动态稳定规模（带流量路由）

🔔 重要：从 v1.1 开始可用

在使用流量路由时，默认情况下稳定的 ReplicaSet 在更新期间保持缩放为 100％。这具有一个优点，即如果发生中止，则可以立即将流量转移到稳定的 ReplicaSet 而无需延迟。但是，它的缺点是在更新期间，将最终存在双倍数量的副本 Pod（类似于蓝绿色部署），因为稳定的 ReplicaSet 在整个更新期间都被缩放。

可以通过动态减少稳定的 ReplicaSet 规模来实现，以使其在流量权重增加到金丝雀时缩小。这对于 Rollout 具有高副本计数和资源成本是一个问题，或者在裸机情况下不可能创建额外的节点容量以容纳双倍副本的情况下是有用的。

可以通过将`canary.dynamicStableScale`标志设置为 true 来启用动态缩放稳定的 ReplicaSet：

```yaml
 spec:
   strategy:
     canary:
       dynamicStableScale: true
```

请注意，如果设置了`dynamicStableScale`并且 Rollout 中止了，则金丝雀 ReplicaSet 将动态缩小，因为流量转移到了稳定的 ReplicaSet。如果你希望在中止时保留金丝雀 ReplicaSet 的缩放比例，则可以设置`abortScaleDownDelaySeconds`的显式值：

```yaml
 spec:
   strategy:
     canary:
       dynamicStableScale: true
       abortScaleDownDelaySeconds: 600
```

## 模仿滚动更新

如果省略`steps`字段，则金丝雀策略将模仿滚动更新行为。与部署类似，金丝雀策略具有`maxSurge`和`maxUnavailable`字段，以配置 Rollout 应如何向新版本推进。

## 其他可配置特性

以下是将修改金丝雀策略行为的可选字段：

```yaml
 spec:
   strategy:
     canary:
       analysis: object
       antiAffinity: object
       canaryService: string
       stableService: string
       maxSurge: stringOrInt
       maxUnavailable: stringOrInt
       trafficRouting: object
```

### analysis

配置在 Rollout 期间执行的后台分析。如果分析不成功，则 Rollout 将中止。

默认为 nil

### antiAffinity

有关更多信息，请查看 Anti Affinity 文档。

默认为 nil

### canaryService

`canaryService`引用将被修改为仅将流量发送到金丝雀 ReplicaSet 的 Service。这使用户只能击中金丝雀 ReplicaSet。

默认为空字符串

### stableService

`stableService`是一个选择具有稳定版本的 Pod，并且不会选择任何具有金丝雀版本的 Pod 的 Service 的名称。这使用户只能击中稳定的 ReplicaSet。

默认为空字符串

### maxSurge

`maxSurge` 定义了升级过程中可以创建的最大副本数，以达到最后一次 setWeight 设置的正确比例。Max Surge 可以是整数或百分比字符串（例如 "20%"）。

默认为 "25%"。

### maxUnavailable

升级期间可以不可用的 Pod 的最大数量。值可以是绝对数（例如：5）或所需 Pod 的百分比（例如：10%）。如果 MaxSurge 为 0，则不能为 0。

默认为 "25%"。

### trafficRouting

流量管理 规则，用于控制活动和金丝雀版本之间的流量。如果未设置，则将使用默认的基于加权 Pod 副本的路由。

默认为 nil。
