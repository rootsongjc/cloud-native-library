---
title: "Kubernetes 将推出新 sidecar container 特性"
date: 2023-08-02T11:00:00+08:00
draft: false
authors: ["Mirantis"]
summary: "Kubernetes 的新 sidecar container 特性允许用户在规范中定义辅助容器的行为，以帮助配置、网络、日志和度量收集等方面。这个新功能旨在为多容器 pod 中的 sidecar 容器提供更精细的粒度，使其能够比 initContainer 更好地反映 sidecar 的特定要求，简化常见用法模式并为未来开辟了一些有趣的设计空间。"
tags: ["Kubernetes","Sidecar","容器"]
categories: ["Kubernetes"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://www.mirantis.com/blog/understanding-kubernetes-new-sidecar-container-feature
---

上周，Kubernetes 项目[合并](https://github.com/kubernetes/kubernetes/pull/116429)了一个新的 alpha 特性，使用户能够在规范中定义“sidecar containers”。这个新功能旨在帮助定义多容器 pod 中辅助容器的行为，这些容器可能有助于配置、网络、日志和度量收集等方面。

## 什么是 sidecar container？

理论上，Kubernetes 期望您在每个 pod 中运行一个容器。实际上，[许多用例需要多容器 pod](https://www.mirantis.com/blog/kubernetes-pod-vs-container-multi-container-pods-and-container-communication/)——例如，当您使用某些服务网格时，几乎所有的 pod 中都可能有 sidecar。

有时，辅助容器仅用于初始化：例如为主容器配置和管理 secret。Kubernetes 已经为用户提供了定义 initContainer 的方式一段时间了。这个新功能最终为 initContainer 提供了更精细的粒度，以反映 sidecar 的特定要求，简化常见用法模式并为未来开辟了一些有趣的设计空间。

## sidecar container 特性如何工作？

在这个新的功能门控中，sidecar containers 被定义为...

- 在 pod 中比其他容器更早地启动，因为它们可能需要先初始化。这对于像服务网格这样的事情很重要，其中您希望 sidecar 准备好为主容器进程建立网络连接，以及在日志记录方面，您希望收集器 sidecar 能够抓取主容器的启动日志。
- 在 pod 的整个生命周期内保持运行，因为它们可能需要长期运行。例如，在网络和指标/日志记录的情况下，您需要 sidecar 运行的时间与主进程一样长。
- 永远不会阻止 pod 被终止，因为它们仅支持 pod 的核心功能——如果没有新功能，运行的 sidecar 容器可以阻止作业完成，即使 pod 的核心任务已完成

在较丑的一面上，在这个 alpha 实现中，您可以通过在您的 `initContainer` 规范中添加值为 `Always` 的 `restartPolicy` 字段来定义 sidecar container。例如：

```yaml
kind: Pod
metadata:
  name: myapp-pod
spec:
  initContainers:
  - name: init-myservice
    image: busybox:1.28
  - name: init-mydb
    image: busybox:1.28
  - name: istio-proxy
    image: istio/proxyv2:1.16.0
    args: ["proxy", "sidecar"]
    restartPolicy: Always
  containers:
  - name: myapp-container
    image: busybox:1.28
```

在上面的规范中，**init-myservice** 和 **init-mydb** 是标准 initContainers，而设置为 `Always` 的 `restartPolicy` 字段使 **istio-proxy** 成为 sidecar container。

这个新特性的 Kubernetes Enhancement Proposal (KEP) 承认了这种表面上的不优雅，指出 initContainer“不适合作为 sidecar containers，因为它们通常做的不仅是初始化”，并建议“基础设施容器”是一个更好的名称，未来可能会采用。KEP 解释了选择的结构背后的思考方式：

......将 sidecar containers 定义在其他 init 容器之间是很重要的，以便能够表达容器的初始化顺序。

一位高级贡献者在 Hacker News 上补充了一些细节，指出：

分离属性的挑战在于它与我们可能添加到 pod 周围的有关排序和生命周期的新功能不兼容。如果我们使用一个简单的布尔值，最终我们将不得不让它与其他字段交互，并处理“sidecar”的含义和更灵活性之间的冲突行为。[...]我们为 init containers 可以失败 pod、并且可以并行化、以及常规容器具有唯一的 restartPolicies 留出了空间。这两个都将允许更多的工作流/作业引擎控制，以分解单体容器并获得更好的隔离。

在[另一个评论](https://news.ycombinator.com/item?id=36666359)中，他们补充说，团队想要...

......留下更复杂的 init containers 和 sidecars 的排序（常规容器没有 restart 顺序）。例如，您可能需要一个服务网格来需要一个 vault secret——这两个可能都是 sidecars，并且如果两者都关闭，您可能需要确保 vault sidecar 首先启动。最终，我们可能希望在启动顺序中添加并行性，而单独的字段将阻止简单的排序现在起作用。

KEP 提供了有关引发该功能的问题案例以及一些组织正在运行 Kubernetes 分叉以实现类似功能的有趣更广泛的背景的详细见解。

如果您迫不及待地想在新的测试集群上尝试这个新功能，您需要为 kubelet、kube-apiserver、kube-controller-manager 和 kube-scheduler 启用 SidecarContainers feature gate。KEP 提供了有关默认策略和实现的有用细节，您可以期待在 8 月份发布 Kubernetes 1.28 时看到更多关于此功能的讨论。
