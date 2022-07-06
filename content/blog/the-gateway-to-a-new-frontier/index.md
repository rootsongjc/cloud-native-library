---
title: Envoy API Gateway——推动网关的进一步发展
summary: 在我们看来，由于Envoy的设计、功能设置、安装基础和社区，它是业内最好的API网关。有了Envoy Gateway，企业可以在将Envoy嵌入其API管理策略方面增加信心。

# Link this post with a project
projects: [""]

# Date published
date: '2022-05-17T11:00:00+08:00'

# Date updated
lastmod: '2022-05-17T11:12:00+08:00'

# Is this an unpublished draft?
draft: false

# Show this page in the Featured widget?
featured: false

# Featured image
# Place an image named `featured.jpg/png` in this page's folder and customize its options here.
image:
  caption: '© [**jimmysong.io**](https://jimmysong.io)'
  focal_point: 'right'
  placement: 2
  preview_only: false

authors: ["Varun Talwar"]
aliases: ["/translation/the-gateway-to-a-new-frontier"]
tags: ["Envoy","开源","网关","Tetrate"]
categories: ["Envoy"]
links:
  - icon: language
    icon_pack: fa
    name: 阅读英文版原文
    url: https://www.tetrate.io/blog/the-gateway-to-a-new-frontier/
---

## 前言

今天，Envoy 社区[宣布了](https://www.cncf.io/blog/2022/05/16/introducing-envoy-gateway/)一个令人兴奋的新项目。 [Envoy Gateway](https://github.com/envoyproxy/gateway)。该项目将行业领导者联合起来，精简由 Envoy 驱动的应用网关的好处。这种方法使 Envoy Gateway 能够立即为快速创新打下坚实的基础。该项目将提供一套服务来管理 Envoy 代理机群，通过易用性来推动采用，并通过定义明确的扩展机制来支持众多的用例。

## 我们为什么要这样做？

Tetrate 是 Envoy Proxy 的第一贡献者（按提交量计算），也是 Envoy Gateway 指导小组的成员，其贡献者涵盖技术和管理领域。我们相信，我们强大的伙伴关系和在开源软件方面的深厚经验将有助于确保 Envoy Gateway 的成功。Tetrate 推动了 EG 计划，因为我们致力于上游项目，因为我们相信这将降低 Envoy Proxy 用户的进入门槛，也因为这与我们开发服务网格作为零信任架构基础的使命相一致。Tetrate 将大力投资建设 Envoy Gateway 的安全功能，包括支持 OAuth2 和 [Let’s Encrypt](https://letsencrypt.org/) 集成等 API 功能。

### 对上游项目的承诺

Tetrate 从第一天起就站在服务网格的最前沿，始终相信上游项目和它们的社区。因此，我们一直在为 Istio 和 Envoy 的上游项目提供帮助和支持。我们看到不同的人在使用 Envoy，并创建他们自己的控制平面和 API 网关实现，导致碎片化，创新速度慢，功能差距大，以及缺乏对一个代码库的支持。由于我们与 Matt Klein 和 Envoy 社区长期以来关系密切，当我们提议将其纳入 Envoy 的标准化实现，并将其整合到一个官方的上游实现中时，我们得到了 Matt 和其他 CNCF 项目的强烈支持。我们一直在幕后与其他指导委员会成员（[Ambassador Labs](https://www.getambassador.io/)、[Fidelity Investments](https://www.fidelity.com/)、[Project Contour](https://projectcontour.io/) 和 [VMware](https://www.vmware.com/) 辛勤工作，以定义 Envoy Gateway。

我们知道，艰苦的工作才刚刚开始，我们致力于这个项目以及 CNCF 内其他几个项目的长期成功。

### 实现控制平面的标准化

在很短的时间内，Envoy 已经成为现代云原生应用的首选网络层。随着 Envoy 获得关注，大量的上游项目开始利用它来实现服务网格、入口、出口和 API 网关功能。这些项目中有许多能力重叠、功能差距、专有特性，或者缺乏社区多样性。这种支离破碎的状态是由于 Envoy 社区没有提供控制平面的实现而产生的副作用。

因此，创新的速度降低了，企业被要求辨别利用 Envoy 作为其应用网络数据平面的最佳方法。现在，社区正在提供 Envoy Gateway，更多的用户可以享受 Envoy 的好处，而无需决定控制平面。Envoy Gateway 的[目标](https://github.com/envoyproxy/gateway/blob/main/GOALS.md#goals)是：

> "...... 通过支持众多入口和 L7/L4 流量路由使用案例的表达式、可扩展、面向角色的 API，降低采用障碍，吸引更多用户使用 Envoy；并为供应商建立增值产品提供共同基础，而无需重新设计基本交互。"

### 易用性和运营效率

Envoy Proxy 是由 [xDS API](https://github.com/cncf/xds) 驱动的，这些 APIs 暴露了大量的功能，并被控制平面广泛采用。虽然这些 API 功能丰富，但对于用户来说，要快速学习并开始利用 Envoy 的功能是非常困难的。Envoy Gateway 将为用户抽象出这些复杂的功能，同时支持现有的运营和应用管理模式。

Envoy Gateway 将利用 [Gateway API](https://gateway-api.sigs.k8s.io/) 来实现这些目标，而不是开发一个新的项目专用 API。Gateway API 是一个由 [Kubernetes 网络特别兴趣小组](https://github.com/kubernetes/community/tree/master/sig-network)管理的项目，正在迅速成为提供用户接口以管理应用网络基础设施和流量路由的首选方法。这个开源项目有一个丰富、多样的社区，有几个知名的实施方案。我们期待着作为社区的一部分开展工作，使 Envoy Gateway 成为业界首选的网关 API 实现。

## 为什么这比传统的 API 网关更好？

传统的代理不是轻量级的、开放的，也不是动态可编程的、类似 xDS 的 API，因此 Envoy 很适合成为当今动态后端的 API 网关 —— 尤其是在增加安全功能的情况下。我们设想将 Envoy 网关作为不断发展的 API 管理领域的一个关键组成部分。API 网关是 API 管理的核心组件，提供透明地策略执行和生成详细遥测数据的功能。这种遥测技术提供了强大的可观测性，为企业提供了更好的洞察力，以排除故障、维护和优化其 API。

在我们看来，由于 Envoy 的设计、功能设置、安装基础和社区，它是业内最好的 API 网关。有了 Envoy Gateway，企业可以在将 Envoy 嵌入其 API 管理策略方面增加信心。

### 无边界的零信任

当你的所有应用服务都在一个服务网格中运行时，实现[零信任架构](https://www.tetrate.io/zero-trust/)就不那么难了。然而，现实中不都是服务网格。服务在虚拟机上运行，在无代理容器中运行，作为无服务器函数运行，等等。Envoy Gateway 将突破这些运行时的界限，为跨异构环境的统一策略执行提供基础。

这一基础的关键是 Envoy Gateway 的可扩展性，它提供了暴露 Envoy 和非 Envoy 安全功能的灵活性。这些扩展点将被用来提供实现零信任架构所需的功能，包括用户和应用认证、授权、加密和速率限制。Envoy Gateway 将很快成为寻求实现零信任架构的组织的一个关键组件。

同样，Tetrate 致力于上游项目和它们的长期可行性。这一举措又一次证明了这一点，并表明上游的 Envoy 和 Istio 现在正成为构建服务网格的事实上的支柱。Envoy Gateway 将使服务网格成为主流，架构师们应该把网格看作是 ZTA 的基础。为了帮助架构师进行论证，我们最近出版了《[服务网格手册](https://www.tetrate.io/service-mesh-handbook/)》。我们很快就会发布一种带有上游 Envoy Gateway 和 Istio 的架构方法，可以看作是你的应用网络的基础。

### 探索 Envoy Gateway

在 Tetrate，我们正在领导基于 Envoy Gateway 和 Istio 的零信任架构的定义，并将在后续博文中阐述设想的架构。如果你想和我们一起讨论架构，并了解更多关于如何为传统和云原生应用程序进行架构，请加入 [tetrate-community](http://tetrate-community.slack.com/) Slack 频道。

要了解更多关于 Tetrate 的信息，请访问 [tetrate.io](https://www.tetrate.io/envoy-gateway/)。
