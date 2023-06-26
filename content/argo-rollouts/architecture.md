---
weight: 4
linkTitle: 架构
title: 架构
date: '2023-06-21T16:00:00+08:00'
type: book
---

这里是 Argo Rollouts 管理的部署中所有参与的组件的概述。

![Argo Rollouts 架构](../images/argo-rollout-architecture.png)

## Argo Rollouts 控制器

这是主要的控制器，它监视集群中的事件并在更改 `Rollout` 类型的资源时做出反应。控制器将读取所有滚动的详细信息，并将集群带到与 Rollout 定义中描述的相同状态。

请注意，Argo Rollouts 不会干涉或响应在普通的 [Deployment 资源](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) 上发生的任何更改。这意味着你可以在以其他方法部署应用程序的集群中安装 Argo Rollouts。

要在你的集群中安装控制器并开始进行渐进式交付，请参见[安装页面](../installation)。

## Rollout 资源

Rollout 资源是由 Argo Rollouts 引入和管理的自定义 Kubernetes 资源。它与原生 Kubernetes Deployment 资源大多兼容，但具有控制高级部署方法（如金丝雀和蓝/绿部署）的阶段、阈值和方法的额外字段。

请注意，Argo Rollouts 控制器仅响应在 Rollout 源中发生的那些更改。它不会对普通的 Deployment 资源做任何事情。这意味着，如果你想使用 Argo Rollouts 管理它们，你需要将你的 Deployments 迁移到 Rollouts，请参考 [迁移页面](../migrating)。

你可以在 [完整规范页面](../features/specification) 中查看 Rollout 的所有可能选项。

## 旧版本和新版本的副本集

这些是 [标准 Kubernetes ReplicaSet 资源](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) 的实例。Argo Rollouts 在其上放置了一些额外的元数据，以跟踪作为应用程序一部分的不同版本。

请注意，在 Rollout 中参与的副本集是由控制器以自动方式完全管理的。你不应使用外部工具干扰它们。

## Ingress/Service

这是流量从实时用户进入你的集群并重定向到适当版本的机制。Argo Rollouts 使用 [标准 Kubernetes service 资源](https://kubernetes.io/docs/concepts/services-networking/service/)，但需要一些额外的元数据来进行管理。

Argo Rollouts 在网络选项方面非常灵活。首先，你可以在 Rollout 期间拥有不同的服务，这些服务仅适用于新版本、旧版本或两者。针对金丝雀部署，Argo Rollouts 支持几种 [服务网格和入口解决方案](../features/traffic-management/)，以根据特定百分比拆分流量，而不是基于 pod 计数的简单负载均衡，并且可以同时使用多个路由提供程序。

## AnalysisTemplate 和 AnalysisRun

分析是将 Rollout 连接到你的指标提供程序并定义确定更新是否成功的特定指标阈值的功能。对于每个分析，你可以定义一个或多个度量查询以及它们的预期结果。如果度量查询良好，Rollout 将自动继续，如果度量显示失败，则自动回滚，如果度量无法提供成功/失败答案，则暂停 Rollout。

为执行分析，Argo Rollouts 包括两个自定义 Kubernetes 资源：`AnalysisTemplate` 和 `AnalysisRun`。

`AnalysisTemplate` 包含有关要查询的度量的说明。附加到 Rollout 的实际结果是 `AnalysisRun` 自定义资源。你可以在特定的 Rollout 上定义 `AnalysisTemplate`，也可以在集群上全局定义为可由多个 Rollout 共享的 `ClusterAnalysisTemplate`。`AnalysisRun` 资源在特定的 Rollout 上进行作用域限制。

请注意，在 Rollout 中使用分析和度量完全是可选的。你可以手动暂停和推广（promote）Rollout，或通过 API 或 CLI 使用其他外部方法（例如烟雾测试）。你不需要度量解决方案才能使用 Argo Rollouts。你还可以在 Rollout 中混合自动化（即基于分析的）和手动步骤。

除了度量之外，你还可以通过运行 [Kubernetes Job](../analysis/job/) 或运行 [Webhook](../analysis/web/) 来决定 Rollout 的成功。

## 度量提供程序

Argo Rollouts 包括[对几个流行的度量提供程序的本地集成](../features/analysis/)，你可以在分析资源中使用它们来自动推广或回滚 Rollout。有关特定设置选项，请参阅每个提供程序的文档。

## CLI 和 UI（未在图表中显示）

你可以使用 [Argo Rollouts CLI](../features/kubectl-plugin/) 或 [集成 UI](../dashboard/) 查看和管理 Rollout，两者都是可选的。
