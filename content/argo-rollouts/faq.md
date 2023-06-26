---
weight: 15
title: FAQ
date: '2023-06-21T16:00:00+08:00'
type: book
---

## 一般问题

### Argo Rollouts 是依赖 Argo CD 或其他 Argo 项目吗？

Argo Rollouts 是一个独立的项目。虽然它与 Argo CD 和其他 Argo 项目配合使用效果很好，但它也可以单独用于渐进式交付场景。更具体地说，Argo Rollouts 不需要你也在同一集群上安装 Argo CD。

### Argo Rollouts 如何与 Argo CD 集成？

通过 Argo CD 的 [Lua 健康检查](https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/health.md)，Argo CD 可以了解 Argo Rollouts 资源的健康状况。这些健康检查了解 Argo Rollout 对象何时在进展、暂停、退化或健康。此外，Argo CD 具有基于 Lua 的资源操作，可以改变 Argo Rollouts 资源（例如取消暂停 Rollout）。

因此，操作员可以构建自动化程序以反应 Argo Rollouts 资源的状态。例如，如果 Argo CD 创建的 Rollout 被暂停，Argo CD 会检测到并将该应用程序标记为暂停。一旦确定新版本是好的，操作员就可以使用 Argo CD 的 resume 资源操作来取消暂停 Rollout，以便它可以继续前进。

### 我们可以通过 Argo CD 运行 Argo Rollouts kubectl 插件命令吗？

Argo CD 支持运行 Lua 脚本来修改资源类型（例如，通过将 `.spec.suspend` 设置为 true 暂停 CronJob）。这些 Lua 脚本可以在 argocd-cm ConfigMap 中或上游的 Argo CD [resource_customizations](https://github.com/argoproj/argo-cd/tree/master/resource_customizations) 目录中进行配置。这些自定义操作有两个 Lua 脚本：一个用于修改该资源，另一个用于检测是否可以执行该操作（例如，用户不应该能够恢复未暂停的 Rollout）。Argo CD 允许用户通过 UI 或 CLI 执行这些操作。

在 CLI 中，用户（或 CI 系统）可以运行

```
argocd app actions run <APP_NAME> <ACTION>
```

该命令执行列出在应用程序上的操作。

在 UI 中，用户可以单击资源的汉堡包按钮，操作将在几秒钟内出现。用户可以单击并确认该操作以执行它。

目前，Argo CD 中的 Rollout 操作有两个可用的自定义操作：resume 和 restart。

- resume：取消暂停具有 PauseCondition 的 Rollout。
- restart：设置 RestartAt 并导致所有 pod 重新启动。

### Argo Rollout 需要像 Istio 这样的 Service Mesh 吗？

Argo Rollouts 不需要使用服务网格或入口控制器。在缺乏流量路由提供程序的情况下，Argo Rollouts 管理金丝雀/稳定 ReplicaSets 的复制计数，以实现所需的金丝雀权重。正常的 Kubernetes Service 路由（通过 kube-proxy）用于在 ReplicaSets 之间分配流量。

### Argo Rollout 需要我们在组织中遵循 GitOps 吗？

Argo Rollouts 是一个 Kubernetes 控制器，无论如何更改清单，它都会对其做出反应。清单可以通过 Git 提交、API 调用、另一个控制器甚至是手动的 `kubectl` 命令进行更改。你可以使用 Argo Rollouts 与任何不遵循 GitOps 方法的传统 CI/CD 解决方案。

### 我们可以以 HA 模式运行 Argo Rollouts 控制器吗？

可以。k8s 集群可以运行多个 Argo-rollouts 控制器副本以实现 HA。要启用此功能，请使用 `--leader-elect` 标志运行控制器，并增加控制器的部署清单中的副本数。该实现基于 [k8s client-go 的 leaderelection package](https://pkg.go.dev/k8s.io/client-go/tools/leaderelection#section-documentation)。该实现对副本之间的*任意时钟偏差*具有容错能力。偏差率的容忍度可以通过适当设置 `--leader-election-lease-duration` 和 `--leader-election-renew-deadline` 来配置。有关详细信息，请参阅[package documentation](https://pkg.go.dev/k8s.io/client-go/tools/leaderelection#pkg-overview)。

## Rollouts

### Argo Rollouts 支持哪些部署策略？

Argo Rollouts 支持 BlueGreen、Canary 和 Rolling Update。此外，可以在蓝绿/金丝雀更新之上启用渐进式交付功能，进一步提供高级部署，例如自动分析和回滚。

### Rollout 对象在创建时是否遵循提供的策略？

与 Deployments 一样，Rollouts 在初始部署时不遵循策略参数。控制器尝试通过从提供的 `.spec.template` 创建完全扩展的 ReplicaSet 来尽快将 Rollout 逐步引入稳定状态。一旦 Rollout 有一个稳定的 ReplicaSet 可以过渡，控制器就开始使用提供的策略将前一个 ReplicaSet 过渡到所需的 ReplicaSet。

### 蓝绿回滚如何工作？

BlueGreen Rollout 保留旧的 ReplicaSet 运行 30 秒或 scaleDownDelaySeconds 的值。控制器通过添加名为 `argo-rollouts.argoproj.io/scale-down-deadline` 的注释来跟踪缩小规模之前的剩余时间。如果在旧 ReplicaSet 缩小之前应用旧的 Rollout 清单，则控制器执行所谓的快速回滚。控制器立即将活动服务的选择器切换回旧 ReplicaSet 的 rollout-pod-template-hash，并从该 ReplicaSet 中删除缩小的注释。控制器在尝试引入新版本时不执行任何常规操作，因为它试图尽快恢复。如果缩小范围注释过去，并且旧的 ReplicaSet 已经缩小，则会发生非快速跟踪回滚。在这种情况下，Rollout 将 ReplicaSet 视为任何新的 ReplicaSet，并遵循部署新的 ReplicaSet 的常规程序。

### 什么是 `argo-rollouts.argoproj.io/managed-by-rollouts` 注释？

Argo Rollouts 在控制器修改的服务和 Ingress 中添加了 `argo-rollouts.argoproj.io/managed-by-rollouts` 注释。它们用于在删除管理这些资源的 Rollout 时，控制器尝试将它们还原回它们的先前状态。

## Rollbacks

### Argo Rollouts 在回滚时会在 Git 中写回吗？

不会。Argo Rollouts 不会读取/写入 Git 中的任何内容。实际上，Argo Rollouts 对 Git 存储库一无所知（只有 Argo CD 有此信息，如果它管理 Rollout）。当回滚发生时，Argo Rollouts 将应用程序标记为“降级”，并将集群上的版本更改回已知稳定版本。

### 如果我同时使用 Argo Rollouts 和 Argo CD，回滚的情况下是否会出现无限循环？

不会出现无限循环。如前面的问题中已经解释的那样，Argo Rollouts 在任何方式上都不会干扰 Git。如果你同时使用这两个 Argo 项目，回滚的事件序列如下：

1. 版本 N 在 Rollout（由 Argo CD 管理）上在集群上运行。Git 存储库已更新为 Rollout/Deployment 清单中的版本 N+1
2. Argo CD 在 Git 中看到更改并使用新的 Rollout 对象更新集群中的实时状态
3. Argo Rollouts 接管，因为它观察所有 Rollout 对象的更改。Argo Rollouts 完全不知道 Git 中正在发生的事情。它只关心在集群中实时运行的 Rollout 对象正在发生什么。
4. Argo Rollouts 尝试使用所选策略（例如，蓝/绿）应用版本 N+1。
5. 版本 N+1 由于某种原因无法部署。
6. Argo Rollouts 再次缩小（或切换回流量）到集群中的版本 N。Argo Rollouts 不会在 Git 中进行任何更改
7. 集群正在运行版本 N，完全健康
8. Rollout 在 ArgoCD 和 Argo Rollouts 中都标记为“降级”。
9. 如果 Git 中的 Rollout 对象与集群中的相同，则 Argo CD 同步不会采取进一步措施。它们都提到版本 N+1

### 那么我如何使 Argo Rollouts 在回滚时写回 Git？

如果你只想使用 Argo CD 回退到以前的版本，则不需要这样做。当部署失败时，Argo Rollouts 会自动将集群设置回稳定/以前的版本，如前面的问题中所述。你不需要写入 Git 以实现此目的。集群仍然健康，你已避免了停机时间。然后，你应该修复问题并向前滚动（即部署下一个版本），如果你想以严格的方式遵循 GitOps。如果你想在部署失败后使 Argo Rollouts 在 Git 中写回，则需要使用外部系统或编写自定义粘合代码来协调此操作。但通常不需要这样做。

### Rollouts with Argo Rollouts 和 Rollbacks with Argo CD 之间有什么关系？

它们完全没有关系。Argo Rollouts 的 "rollbacks" 将集群切换回上一个版本，如前一个问题所述。它们不会以任何方式触及或影响 Git。Argo CD 的 [rollbacks](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_app_rollback/) 只是将集群指回以前的 Git 哈希。通常，如果你有 Argo Rollouts，就不需要使用 Argo CD 回滚命令。

### 如何在单个步骤中部署多个服务并根据它们的依赖关系回滚？

Rollout 规范专注于单个应用程序/部署。Argo Rollouts 不知道应用程序依赖关系。如果你想以智能方式同时部署多个应用程序（例如，如果后端部署失败，则自动回滚前端），则需要在 Argo Rollouts 之上编写自己的解决方案。在大多数情况下，你需要为要部署的每个应用程序创建一个 Rollout 资源。理想情况下，你还应该使你的服务向前向后兼容（即前端应该能够与 backend-preview 和 backend-active 一起工作）。

### 如何运行自己的自定义测试（例如烟雾测试）以决定是否应进行回滚？

使用自定义 [Job](https://argo-rollouts.readthedocs.io/en/stable/analysis/job/) 或 [Web](https://argo-rollouts.readthedocs.io/en/stable/analysis/web/) Analysis。你可以将所有烟雾测试打包到单个容器中，并将它们作为 Job 分析运行。Argo Rollouts 将使用分析结果自动回滚，如果测试失败。

## 实验

### 为什么我的实验没有结束？

实验的持续时间由 `.spec.duration` 字段和为实验创建的分析控制。`.spec.duration` 指示实验创建的 ReplicaSet 应运行多长时间。一旦时间过去，实验将缩小它创建的 ReplicaSet，并将 AnalysisRuns 标记为成功，除非实验中使用了 `requiredForCompletion` 字段。如果启用了该字段，ReplicaSet 仍然会被缩小，但是直到 Analysis Run 完成，实验才会结束。

此外，`.spec.duration` 是一个可选字段。如果它未设置，并且实验未创建任何 AnalysisRuns，则 ReplicaSets 将无限期运行。实验创建没有 `requiredForCompletion` 字段的 AnalysisRuns，当所创建的 AnalysisRun 失败或出错时，实验失败。如果设置了 `requiredForCompletion` 字段，则实验仅在 AnalysisRun 完成成功时标记自己为成功并缩小创建的 ReplicaSets。

此外，如果 `.spec.terminate` 字段设置为 true，则实验会结束，无论实验的状态如何。

## 分析

### 为什么我的 AnalysisRun 没有结束？

AnalysisRun 的持续时间由指定的度量标准控制。每个度量标准都可以指定时间间隔、计数和各种限制（ConsecutiveErrorLimit、InconclusiveLimit、FailureLimit）。如果省略了时间间隔，则 AnalysisRun 进行单次测量。计数指示应进行多少次测量，如果省略，则 AnalysisRun 将无限期运行。ConsecutiveErrorLimit、InconclusiveLimit 和 FailureLimit 定义了允许的阈值，以便在将 Rollout 放入完成状态之前。

此外，如果 `.spec.terminate` 字段设置为 true，则 AnalysisRun 会结束，无论分析运行的状态如何。

### 失败和错误之间有什么区别？

当失败条件计算为 true 或没有失败条件的 AnalysisRun 计算成功条件为 false 时，失败是。当控制器在执行测量时出现任何问题（即无效的 Prometheus URL）时，错误就会发生。
