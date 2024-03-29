---
title: 工作负载载入指南
description: 自动化在 Kubernetes 之外部署的工作负载的载入。
weight: 1
---

工作负载载入是 TSB 的一个功能，它自动化了在服务网格中将在 Kubernetes 之外部署的工作负载载入的过程。

例如，你可以使用它来将部署在虚拟机上（或者可能是自动缩放组中的虚拟机）的工作负载载入，这些工作负载并不属于你的 Kubernetes 集群的一部分。

{{<callout note 注意>}}
工作负载载入功能目前是一个 alpha 版本。

有可能它尚不支持所有可能的部署场景。尤其值得注意的是，它尚不支持使用 `Iptables` 进行流量重定向。你应该根据需要配置 Istio Sidecar 和你的应用程序。

目前，此功能支持从以下环境载入工作负载：

* 部署在 `AWS EC2` 实例上的工作负载
* 部署在 `AWS Auto-Scaling Groups` 上的工作负载
* 作为 `AWS ECS` 任务部署的工作负载
* 部署在本地环境的工作负载
{{</callout>}}

{{< list_children show_summary="false">}}
