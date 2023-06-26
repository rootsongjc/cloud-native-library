---
weight: 9
title: "反亲和性"
date: '2023-06-21T16:00:00+08:00'
type: book
---

## **背景**

根据集群的配置，蓝绿部署（或使用流量管理的金丝雀部署）可能会导致新创建的 Pod 在部署新版本后重新启动。这可能会导致问题，特别是对于无法快速启动或无法正常退出的应用程序。

这种行为发生的原因是集群自动缩放器想要缩小创建的额外容量以支持运行在双倍容量中的部署。当节点缩小时，它所拥有的 Pod 会被删除并重新创建。这通常发生在部署具有自己的专用实例组时，因为部署对集群自动缩放器的影响更大。因此，具有大量共享节点的集群较少经历这种行为。

例如，此处有一个正在运行的部署，它有 8 个 Pod 分布在 2 个节点上。每个节点最多可容纳 6 个 Pod：

![原 Rollout 正在运行，跨越两个节点](images/step-0.png)

当部署的 `spec.template` 发生变化时，控制器会创建一个新的 ReplicaSet，其中包含规范更新和 Pod 总数翻倍的版本。在这种情况下，Pod 的数量增加到 16。

由于每个节点只能容纳 6 个 Pod，所以集群自动缩放器必须将节点数增加到 3 个来容纳所有 16 个 Pod。Pod 在节点之间的分布如下所示：

![Rollout 容量扩大到两倍](images/step-1.png)

部署完成后，旧版本会被缩小。这会使集群拥有比必要的更多的节点，从而浪费资源（如下所示）。

![原 Rollout 正在运行，跨越两个节点](images/step-2.png)

集群自动缩放器终止了额外的节点，Pod 重新调度到剩余的 2 个节点上。

![原 Rollout 正在运行，跨越两个节点](images/step-3.png)

为减少此行为的发生几率，部署可以在 ReplicaSet 中注入反亲和性。这可以防止新 Pod 在具有先前版本 Pod 的节点上运行。

你可以在[此处](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#inter-pod-affinity-and-anti-affinity)了解有关反亲和性的更多信息。

启用反亲和性的示例如下所示。当 `spec.template` 发生变化时，由于反亲和性，新 Pod 无法在运行旧 ReplicaSet 的 Pod 的节点上调度。因此，集群自动缩放器必须创建 2 个节点来托管新的 ReplicaSet 的 Pod。在这种情况下，Pod 不会启动，因为缩小后的节点保证不具有新的 Pod。

![原 Rollout 正在运行，跨越两个节点](images/solution.png)

## **在部署中启用反亲和性**

通过将反亲和性结构添加到蓝绿或金丝雀策略中启用反亲和性。设置反亲和性结构时，控制器会将 PodAntiAffinity 结构注入到 ReplicaSet 的 Affinity 中。此功能不会修改 ReplicaSet 的任何现有亲和性规则。

用户可以在以下调度规则之间进行选择：`RequiredDuringSchedulingIgnoredDuringExecution` 和 `PreferredDuringSchedulingIgnoredDuringExecution`。

`RequiredDuringSchedulingIgnoredDuringExecution` 要求新版本的 Pod 在与以前版本不同的节点上。如果无法做到这一点，则不会调度新版本的 Pod。

```yaml
 strategy:
     bluegreen:
       antiAffinity:
           requiredDuringSchedulingIgnoredDuringExecution: {}
```

与 Required 策略不同，`PreferredDuringSchedulingIgnoredDuringExecution` 不会强制要求新版本的 Pod 在与以前版本不同的节点上。调度程序会尝试将新版本的 Pod 放置在单独的节点上。如果不可能，新版本的 Pod 仍将被调度。`Weight` 用于创建首选反亲和性规则的优先级顺序。

```yaml
 strategy:
     canary:
       antiAffinity:
           preferredDuringSchedulingIgnoredDuringExecution:
             weight: 1 # Between 1 - 100
```

🔔 重要提示：采用这种方法的主要缺点是，部署可能需要更长时间，因为为了根据反亲和性规则调度 Pod，可能会创建新节点。当部署具有自己的专用实例组时，这种延迟最常见，因为为了遵守反亲和性规则，可能会创建新节点。
