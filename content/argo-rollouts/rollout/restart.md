---
weight: 6
title: "重启 Rollouts Pod"
linkTitle: "重启 Rollouts"
date: '2023-06-21T16:00:00+08:00'
type: book
---

出于各种原因，应用程序通常需要重新启动，例如出于健康目的或强制执行启动逻辑，例如重新加载修改的 Secret。在这些情况下，不希望进行整个蓝绿或金丝雀更新过程。Argo Rollouts 支持通过执行所有 Rollout 中的 Pod 的滚动重建来重启其所有 Pod 的能力，同时跳过常规的 BlueGreen 或 Canary 更新策略。

## 它是如何工作的

可以通过 kubectl 插件使用 kubectl-argo-rollouts restart 命令来重新启动 Rollout：

```bash
kubectl-argo-rollouts restart ROLLOUT
```

或者，如果 Rollouts 与 Argo CD 一起使用，则可以通过 Argo CD UI 或 CLI 执行捆绑的“restart”操作：

```bash
argocd app actions run my-app restart --kind Rollout --resource-name my-rollout
```

这两种机制都会将 Rollout 的`.spec.restartAt`更新为以[RFC 3339 格式](https://tools.ietf.org/html/rfc3339)的 UTC 字符串的当前时间形式（例如 2020-03-30T21:19:35Z），这表示 Rollout 控制器应该在此时间戳之后创建 Rollout 的所有 Pod。

在重新启动期间，控制器会迭代每个 ReplicaSet，以查看所有 Pod 的创建时间戳是否比`restartAt`时间新。对于早于“restartAt”时间戳的每个 Pod，将会被驱逐，允许 ReplicaSet 将该 Pod 替换为重新创建的一个。

为了防止太多的 Pod 同时重新启动，控制器将自己限制为一次删除最多`maxUnavailable`个 Pod。其次，由于 Pod 被驱逐而不是删除，因此重新启动过程将遵守任何现有的 PodDisruptionBudgets。

控制器按以下顺序重新启动 ReplicaSets：

1. 稳定的 ReplicaSet
2. 当前的 ReplicaSet
3. 从最旧的开始的所有其他 ReplicaSet

如果在重新启动过程中修改了 Rollout 的 Pod 模板规范（`spec.template`），则重新启动将被取消，并且将执行正常的蓝绿或金丝雀更新。

注意：与 Deployment 不同，其中“重新启动”只是由 Pod 规范注释中的时间戳触发的正常滚动升级，Argo Rollouts 通过终止 Pod 并允许现有 ReplicaSet 替换终止的 Pod 来促进重启。为了在 Rollout 处于长时间运行的蓝绿/金丝雀更新中（例如暂停的金丝雀）时仍允许重启发生而做出了此设计选择。但是，这样做的一些后果是：

- 重新启动具有单个副本的 Rollout 将导致停机，因为 Argo Rollouts 需要终止 Pod 以替换它。
- 与部署的滚动更新相比，重新启动 Rollout 将更慢，因为不使用 maxSurge 来更快地启动新的 Pod。
- maxUnavailable 将用于一次重启多个 Pod（从 v0.10 开始）。但是，如果 maxUnavailable pods 为 0，则控制器仍将一次重启一个 Pod。

## 计划重新启动

用户可以通过将`.spec.restartAt`字段设置为将来的时间来计划重新启动 Rollout。在当前时间在 restartAt 时间之后时，控制器才开始重新启动。
