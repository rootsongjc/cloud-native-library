---
title: "服务网格终极指南第二版——下一代微服务开发"
summary: "本文是 InfoQ 自 2020 年 2 月发表的服务网格终极指南后的第二版，发布于 2021 年 9 月。"
date: 2021-10-11T10:00:00+08:00
lastmod: 2021-10-11T10:00:00+08:00
authors: ["Srini Penchikala"]
categories: ["service mesh"]
tags: ["service mesh"]
draft: false
featured: false
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://www.infoq.com/articles/service-mesh-ultimate-guide-2021/
---

## 主要收获

- 了解采用服务网格技术的新兴架构趋势，特别是多云、多集群和多租户模式，如何在异构基础设施（裸机、虚拟机和 Kubernetes）中部署服务网格解决方案，以及从边缘计算层到网格的应用 / 服务连接。
- 了解服务网格生态系统中的一些新模式，如多集群服务网格、媒体服务网格（Media Service Mesh）和混沌网格，以及经典的微服务反模式，如 “死星（Death Star） “架构。
- 获取最新的关于在部署领域使用服务网格的创新总结，在 Pod（K8s 集群）和 VM（非 K8s 集群）之间进行快速实验、混乱工程和金丝雀部署。
- 探索服务网格扩展领域的创新，包括：增强身份管理，以确保微服务连接的安全性，包括自定义证书授权插件，自适应路由功能，以提高服务的可用性和可扩展性，以及增强 sidecar 代理。
- 了解操作方面即将出现的情况，如配置多集群功能和将 Kubernetes 工作负载连接到托管在虚拟机基础设施上的服务器，以及管理多集群服务网格中所有功能和 API 的开发者门户。

在过去的几年里，服务网格技术有了长足的发展。服务网格在各组织采用云原生技术方面发挥着重要作用。通过提供四种主要能力 —— 连接性、可靠性、可观测性和安全性，服务网格已经成为 IT 组织的技术和基础设施现代化工作的核心组成部分。服务网格使开发和运维团队能够在基础设施层面实现这些能力，因此，当涉及到跨领域的非功能需求时，应用团队不需要重新发明轮子。

自本文[第一版](https://www.infoq.com/articles/service-mesh-ultimate-guide/)于 2020 年 2 月发表以来，服务网格技术经历了重大创新，在不断发展的服务网格领域出现了一些新的架构趋势、技术能力和服务网格项目。

在过去的一年里，服务网格产品的发展远远超过了原有的 Kubernetes 解决方案，没有托管在 Kubernetes 平台上的应用无法利用服务网格。并非所有的组织都将其所有的业务和 IT 应用程序过渡到 Kubernetes 云平台。因此，自服务网格诞生以来，一直需要这项技术在不同的 IT 基础设施环境中工作。

随着微服务架构的不断采用，应用系统在云供应商、基础设施（Kubernetes、虚拟机、裸机服务器）、地域，甚至在服务网格集成环境中要管理的工作负载类型方面，都已实现解耦和分布式。

让我们从服务网格的历史开始说起，了解服务网格是如何产生的。

2016 年前后，“服务网格 " 这个词出现在微服务、云计算和 DevOps 的领域。Buoyant 团队在 2016 年用[这个](https://twitter.com/wm/status/1383061764938469377?s=20)词来解释他们的产品 Linkerd。和云计算领域的许多概念一样，相关的模式和技术其实有很长的历史。

服务网格的到来主要是由于 IT 领域内的一场风暴。开发人员开始使用多语言（polyglot）方法构建分布式系统，并需要动态服务发现。运维部门开始使用短暂的基础设施，并希望优雅地处理不可避免的通信故障和执行网络策略。平台团队开始接受像 Kubernetes 这样的容器编排系统，并希望使用现代 API 驱动的网络代理（如 Envoy）在系统中和周围动态地路由流量。

本文旨在回答软件架构师和技术负责人的相关问题，如：什么是服务网格？我是否需要服务网格？如何评估不同的服务网格产品？

## 服务网格模式

服务网格模式专注于管理分布式软件系统中所有服务之间的通信。

### 背景介绍

该模式的背景有两个方面。首先，工程师们已经采用了微服务架构模式，并通过将多个（理想情况下是单一用途且可独立部署的）服务组合在一起构建他们的应用。第二，组织已经接受了云原生平台技术，如容器（如 Docker）、编排器（如 Kubernetes）和网关。

### 意图

服务网格模式试图解决的问题包括：

- 消除了将特定语言的通信库编译到单个服务中的需求，以处理服务发现、路由和应用层（第 7 层）非功能通信要求。
- 外部化服务通信配置，包括外部服务的网络位置、安全凭证和服务质量目标。
- 提供对其他服务的被动和主动监测。
- 在整个分布式系统中分布式地执行策略。
- 提供可观测性的默认值，并使相关数据的收集标准化。
  - 启用请求记录
  - 配置分布式追踪
  - 收集指标

### 结构

服务网格模式主要侧重于处理传统上被称为 “东西向 “的基于远程过程调用（RPC）的流量：请求 / 响应类型的通信，源自数据中心内部，在服务之间传播。这与 API 网关或边缘代理相反，后者被设计为处理 “南北 “流量。来自外部的通信，进入数据中心内的一个终端或服务。

## 服务网格的特点

服务网格的实施通常会提供以下一个或多个功能：

- 规范化命名并增加逻辑路由，（例如，将代码级名称 “用户服务 " 映射到平台特定位置 “AWS-us-east-1a/prod/users/v4”。
- 提供流量整形和流量转移
- 保持负载均衡，通常采用可配置的算法
- 提供服务发布控制（例如，金丝雀释放和流量分割）
- 提供按请求的路由（例如，影子流量、故障注入和调试重新路由）。
- 增加基线可靠性，如健康检查、超时 / 截止日期、断路和重试（预算）。
- 通过透明的双向传输级安全（TLS）和访问控制列表（ACL）等策略，提高安全性
- 提供额外的可观测性和监测，如顶线指标（请求量、成功率和延迟），支持分布式追踪，以及 "挖掘" 和检查实时服务间通信的能力。
- 使得平台团队能够配置 " 理智的默认值”，以保护系统免受不良通信的影响。

服务网格的能力可分为以下四个方面：

- 连接性
- 可靠性
- 安全性
- 可观测性

让我们看看服务网格技术在这些领域都能提供哪些功能。

**连接性**

- 流量控制（路由，分流）
- 网关（入口、出口）
- 服务发现
- A/B 测试、金丝雀
- 服务超时、重试

**可靠性**

- 断路器
- 故障注入 / 混沌测试

**安全性**

- 服务间认证（mTLS）
- 证书管理
- 用户认证（JWT）
- 用户授权（RBAC）
- 加密

**可观测性**

- 监测
- 遥测、仪表、计量
- 分布式追踪
- 服务图表

## 服务网格架构：内部原理

服务网格由两部分组成：数据平面和控制平面。Matt Klein，[Envoy Proxy](https://www.envoyproxy.io/) 的作者，写了一篇关于 “ [服务网格数据平面与控制平面 ](https://blog.envoyproxy.io/service-mesh-data-plane-vs-control-plane-2774e720f7fc)“的深入探讨。

广义上讲，数据平面 “执行工作”，负责 “有条件地翻译、转发和观察流向和来自 [网络终端] 的每个网络数据包”。在现代系统中，数据平面通常以代理的形式实现，（如 Envoy、[HAProxy](http://www.haproxy.org/) 或 [MOSN](https://github.com/mosn/mosn)），它作为 "sidecar" 与每个服务一起在进程外运行。Linkerd 使用了一种 [微型代理](https://linkerd.io/2020/12/03/why-linkerd-doesnt-use-envoy/)方法，该方法针对服务网格的使用情况进行了优化。

控制平面 “监督工作”，并将数据平面的所有单个实例 —— 一组孤立的无状态 sidecar 代理变成一个分布式系统。控制平面不接触系统中的任何数据包 / 请求，相反，它允许人类运维人员为网格中所有正在运行的数据平面提供策略和配置。控制平面还能够收集和集中数据平面的遥测数据，供运维人员使用。

控制平面和数据平面的结合提供了两方面的优势，即策略可以集中定义和管理，同时，同样的政策可以以分散的方式，在 Kubernetes 集群的每个 pod 中本地执行。这些策略可以与安全、路由、断路器或监控有关。

下图取自 Istio 架构文档，虽然标注的技术是 Istio 特有的，但这些组件对所有服务网格的实现都是通用的。

![Istio 架构](arch.jpg "Istio 架构") 

Istio 架构，展示了控制平面和代理数据平面的交互方式（由 [Istio 文档提供](https://istio.io/docs/)）。

## 使用案例

服务网格可以实现或支持多种用例。

### 动态服务发现和路由

服务网格提供动态服务发现和流量管理，包括用于测试的流量影子（复制），以及用于金丝雀发布和 A/B 实验的流量分割。

服务网格中使用的代理通常是 “应用层 " 感知的（在 OSI 网络堆栈的第 7 层运行）。这意味着流量路由决策和指标的标记可以利用 HTTP 头或其他应用层协议元数据。

### 服务间通信可靠性

服务网格支持跨领域的可靠性要求的实施和执行，如请求重试、超时、速率限制和断路。服务网格经常被用来补偿（或封装）处理[分布式计算的八个谬误](https://en.wikipedia.org/wiki/Fallacies_of_distributed_computing)。应该注意的是，服务网格只能提供 wire-level 的可靠性支持（如重试 HTTP 请求），最终服务应该对相关的业务影响负责，如避免多个（非幂等的）HTTP POST 请求。

### 流量的可观测性

由于服务网格处于系统内处理的每个请求的关键路径上，它还可以提供额外的 “可观测性”，例如请求的分布式追踪、HTTP 错误代码的频率以及全局和服务间的延迟。虽然在企业领域是一个被过度使用的短语，但服务网格经常被提议作为一种方法来捕获所有必要的数据，以实现整个系统内流量的统一界面视图。

### 通信安全

服务网格还支持跨领域安全要求的实施和执行，如提供服务身份（通过 x509 证书），实现应用级服务 / 网络分割（例如，“服务 A" 可以与 “服务 B “通信，但不能与 “服务 C “通信），确保所有通信都经过加密（通过 TLS），并确保存在有效的用户级身份令牌或 “[护照](https://qconsf.com/sf2019/presentation/user-device-identity-microservices-netflix-scale) "。

## 反模式

当反模式的使用出现时，这往往是一个技术成熟的标志。服务网格也不例外。

### 太多的流量管理层次

当开发人员不与平台或运维团队协商，并在现在通过服务网格实现的代码中重复现有的通信处理逻辑时，就会出现这种反模式。例如，除了服务网格提供的 wire-level 重试策略外，应用程序还在代码中还实现了重试策略。这种反模式会导致重复的事务等问题。

### 服务网格银弹

在 IT 领域没有 “银弹 “这样的东西，但供应商有时会被诱惑给新技术贴上这个标签。服务网格不会解决微服务、Kubernetes 等容器编排器或云网络的所有通信问题。服务网格的目的只是促进服务件（东西向）的通信，而且部署和运行服务网格有明显的运营成本。

### 企业服务总线（ESB）2.0

在前微服务面向服务架构（SOA）时代，企业服务总线（ESB）实现了软件组件之间的通信系统。有些人担心 ESB 时代的许多错误会随着服务网格的使用而重演。

通过 ESB 提供的集中的通信控制显然有价值。然而，这些技术的发展是由供应商推动的，这导致了多种问题，例如：ESB 之间缺乏互操作性，行业标准的定制扩展（例如，将供应商的特定配置添加到 WS-* 兼容模式中），以及高成本。ESB 供应商也没有做任何事情来阻止业务逻辑与通信总线的集成和紧耦合。

### 大爆炸部署

在整个 IT 界有一种诱惑，认为大爆炸式的部署方法是最容易管理的方法，但正如 [Accelerate](https://itrevolution.com/book/accelerate/) 和 [DevOps 报告](https://puppet.com/resources/report/state-of-devops-report/)的研究，事实并非如此。由于服务网格的全面推广意味着这项技术处于处理所有终端用户请求的关键路径上，大爆炸式的部署是非常危险的。

### 死星建筑

当企业采用微服务架构，开发团队开始创建新的微服务或在应用中利用现有的服务时，服务间的通信成为架构的一个关键部分。如果没有一个良好的治理模式，这可能会导致不同服务之间的紧密耦合。当整个系统在生产中出现问题时，也将很难确定哪个服务出现了问题。

如果缺乏服务沟通战略和治理模式，该架构就会变成所谓的 “死星架构”。

关于这种架构反模式的更多信息，请查看关于云原生架构采用的[第一部分](https://www.infoq.com/articles/cloud-native-architecture-adoption-part1/)、[第二部分](https://www.infoq.com/articles/cloud-native-architecture-adoption-part2/)和[第三部分的](https://www.infoq.com/articles/cloud-native-architecture-adoption-part3/)文章。

### 特定领域的服务网格

服务网格的本地实现和过度优化有时会导致服务网格部署范围过窄。开发人员可能更喜欢针对自己的业务领域的服务网格，但这种方法弊大于利。我们不希望实现过于细化的服务网格范围，比如为组织中的每个业务或功能域（如财务、人力资源、会计等）提供专用的服务网格。这就违背了拥有像服务网格这样的通用服务协调解决方案的目的，即企业级服务发现或跨域服务路由等功能。

## 服务网格的实现和产品

以下是一份非详尽的当前服务网格实施清单。

- [Linkerd ](https://linkerd.io/)(CNCF 毕业项目)
- [Istio](https://istio.io/)
- [Consul](https://www.consul.io/)
- [Kuma](https://kuma.io/)（CNCF 沙盒项目）
- [AWS App Mesh](https://aws.amazon.com/app-mesh/)
- [NGINX Service Mesh](https://www.nginx.com/products/nginx-service-mesh/)
- [AspenMesh](https://aspenmesh.io/)
- [Kong](https://konghq.com/kong-mesh/)
- [Solo Gloo Mesh](https://www.solo.io/products/gloo-mesh/)
- [Tetrate Service Bridge](https://www.tetrate.io/tetrate-service-bridge/)
- [Traefik Mesh](http://traefik.io/traefik-mesh)（原名 Maesh）
- [Meshery](http://layer5.io/meshery)
- [Open Service MEsh](http://openservicemesh.io/)（CNCF 沙盒项目）

另外，像 [DataDog](https://www.datadoghq.com/blog/tag/service-mesh/) 这样的其他产品也开始提供与 [Linkerd](https://docs.datadoghq.com/integrations/linkerd/?tab=host)、Istio、Consul Connect 和 AWS App Mesh 等服务网格技术的集成。

## 服务网格对比

服务网格领域的发展极为迅速，因此任何试图创建比较的努力都可能很快变得过时。然而，确实存在一些比较。应该注意了解来源的偏见（如果有的话）和进行比较的日期。

- https://layer5.io/landscape
- https://kubedex.com/istio-vs-linkerd-vs-linkerd2-vs-consul/（截至 2021 年 8 月的正确数据）
- https://platform9.com/blog/kubernetes-service-mesh-a-comparison-of-istio-linkerd-and-consul/（截至 2019 年 10 月的最新情况）
- [https://servicemesh.es/ ](https://servicemesh.es/)(最后发表于 2021 年 8 月)

InfoQ 一直建议服务网格的采用者对每个产品进行自己的尽职调查和试验。

## 服务网格教程

对于希望试验多服务网格的工程师或建筑师来说，可以使用以下教程、游戏场和工具。

- [Layer 5 Meshery](https://layer5.io/meshery)—— 多网格管理平面
- [Solo 的 Gloo Mesh](https://github.com/solo-io/supergloo)—— 服务网格编排平台
- [KataCoda Istio 教程](https://www.katacoda.com/courses/istio/deploy-istio-on-kubernetes)
- [Consul 服务网格教程](https://learn.hashicorp.com/consul)
- [Linkerd 教程](https://linkerd.io/2/getting-started/)
- [NGINX 服务网格教程](https://docs.nginx.com/nginx-service-mesh/tutorials/)
- [Istio 基础教程](https://tetrate-academy.thinkific.com/courses/istio-fundamentals-zh)

## 服务网格的历史

自 2013 年底 Airbnb 发布 [SmartStack](https://medium.com/airbnb-engineering/smartstack-service-discovery-in-the-cloud-4b8a080de619)，为新兴的 “ [微服务 ](https://www.infoq.com/microservices/)“风格架构提供进程外服务发现机制（使用 [HAProxy](http://www.haproxy.org/)）以来，InfoQ 一直在跟踪这个我们现在称之为 [服务网格](https://www.infoq.com/servicemesh/)的话题。许多之前被贴上 “独角兽 “标签的组织在此之前就在研究类似的技术。从 21 世纪初开始，谷歌就在开发其 [Stubby ](https://grpc.io/blog/principles/)RPC 框架，该框架演变成了 [gRPC](https://cloud.google.com/blog/products/gcp/grpc-a-true-internet-scale-rpc-framework-is-now-1-and-ready-for-production-deployments)，以及 [谷歌前端（GFE）](https://landing.google.com/sre/sre-book/chapters/production-environment/)和全局软件负载均衡器（GSLB），在 [Istio](https://istio.io/) 中可以看到它们的特质。在 2010 年代早期，Twitter 开始了 Scala 驱动的 [Finagle](https://twitter.github.io/finagle/) 的工作，[Linkerd](https://linkerd.io/) 服务网格由此产生。

2014 年底，Netflix 发布了[一整套基于 JVM 的实用程序](https://netflix.github.io/)，包括 [Prana](https://www.infoq.com/news/2014/12/netflix-prana/)，一个 “sidecar “程序，允许用任何语言编写的应用服务通过 HTTP 与库的独立实例进行通信。2016 年，NGINX 团队开始谈论 “[Fabric 模型](https://www.nginx.com/blog/microservices-reference-architecture-nginx-fabric-model/) "，这与服务网格非常相似，但需要使用他们的商业 NGINX Plus 产品来实现。另外，Linkerd v0.2 在 2016 年 2 月[发布](https://linkerd.io/2016/02/18/linkerd-twitter-style-operability-for-microservices/)，尽管该团队直到后来才开始称它为服务网格。

服务网格历史上的其他亮点包括 2017 年 5 月的 [Istio](https://istio.io/)、2018 年 7 月的 [Linkerd 2.0](https://linkerd.io/2018/09/18/announcing-linkerd-2-0/)、2018 年 11 月的 [Consul Connect](https://www.hashicorp.com/products/consul/service-mesh) 和 [Gloo Mesh](https://github.com/solo-io/supergloo)、2019 年 5 月的 [服务网格接口（SMI）](https://smi-spec.io/)，以及 2019 年 9 月的 Maesh（现在叫 Traefik Mesh）和 Kuma。

即使是在独角兽企业之外出现的服务网格，如 HashiCorp 的 [Consul](https://www.consul.io/)，也从上述技术中获得了灵感，通常旨在实现 CoreOS 提出的 “[GIFEE ](https://github.com/linearregression/GIFEE)“概念；所有人可用的 Google 基础设施（Google infrastructure for everyone else）。

为了深入了解现代服务网格概念的演变历史，[Phil Calçado](https://philcalcado.com/) 写了一篇全面的文章 “ [模式：服务网格](https://philcalcado.com/2017/08/03/pattern_service_mesh.html) "。

## 服务网格标准

尽管在过去的几年里，服务网格技术年复一年地发生着重大转变，但服务网格的标准还没有跟上创新的步伐。

使用服务网格解决方案的主要标准是[服务网格接口](https://smi-spec.io/)（SMI）。服务网格接口是在 [Kubernetes](https://kubernetes.io/) 上运行的服务网格的一个规范。它本身并没有实现服务网格，而是定义了一个通用的标准，可以由各种服务网格供应商来实现。

SMI API 的目标是提供一套通用的、可移植的服务网格 API，Kubernetes 用户可以以一种与提供者无关的方式使用。通过这种方式，人们可以定义使用服务网格技术的应用程序，而不需要与任何特定的实现紧密结合。

SMI 基本上是一个 Kubernetes 自定义资源定义（[CRD](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)）和扩展 API 服务器的集合。这些 API 可以安装到任何 Kubernetes 集群，并使用标准工具进行操作。为了激活这些 API，需要在 Kubernetes 集群中运行一个 SMI 提供者。

SMI 规范既允许终端用户的标准化，也允许服务网格技术提供商的创新。SMI 实现了灵活性和互操作性，并涵盖了最常见的服务网格功能。目前的[规范组件](https://github.com/servicemeshinterface/smi-spec/tree/main/apis)集中在服务网格能力的连接方面。API 规范包括以下内容。

- 流量访问控制
- 流量指标
- 流量规格
- 流量分割

目前的 SMI [生态系统](https://github.com/servicemeshinterface/smi-spec)包括广泛的服务网格，包括 Istio、Linkerd、Consul Connect、Gloo Mesh 等。

SMI 规范是在 [Apache License 2.0 版本下](http://www.apache.org/licenses/)[许可的](https://github.com/servicemeshinterface/smi-spec/blob/main/LICENSE)。

如果你想了解更多关于 SMI 规范及其 API 细节，请查看以下链接。

- [核心规范](https://github.com/servicemeshinterface/smi-spec/blob/main/SPEC_LATEST_STABLE.md)（当前版本：0.6.0）
- [规范 Github 项目](https://github.com/servicemeshinterface/smi-spec)
- [如何贡献](https://github.com/servicemeshinterface/smi-spec/blob/main/CONTRIBUTING.md)

## 服务网格基准测试

[服务网格性能](https://smp-spec.io/)是一个捕捉基础设施容量、服务网配置和工作负载元数据细节的标准。SMP 规范用于捕捉以下细节。

- 环境和基础设施细节
- 节点的数量和规模，编排器
- 服务网格和它的配置
- 工作量 / 应用细节
- 进行统计分析以确定性能特征

来自 Linkerd 团队的 William Morgan [写了](https://linkerd.io/2021/05/27/linkerd-vs-istio-benchmarks/)关于 Linkerd 和 Istio 的性能基准测试。还有一篇来自 2019 年的[文章](https://istio.io/latest/blog/2019/performance-best-practices/)，介绍了 Istio 关于服务网格性能基准测试的最佳实践。

重要的是要记住，就像其他性能基准测试一样，你不应该对任何这些外部出版物投入过多的注意力，特别是产品供应商发表的文章。该在你的服务器环境中设计和执行你自己的性能测试，以验证哪个具体产品适合你的应用程序的业务和非功能要求。

## 探索服务网格的未来

[Kasun Indrasiri](https://www.infoq.com/profile/Kasun-Indrasiri/) 探讨了 “ [为事件驱动的消息传递使用服务网格的潜力](https://www.infoq.com/articles/service-mesh-event-driven-messaging/) "，他在其中讨论了在服务网格中实现消息传递支持的两种主要的新兴架构模式：协议代理 sidecar 和 HTTP 桥接 sidecar。这是服务网格社区中一个活跃的发展领域，在 [Envoy 中](https://github.com/envoyproxy/envoy/issues/2852)支持 [Apache Kafka 的](https://github.com/envoyproxy/envoy/issues/2852)工作引起了相当多的关注。

Christian Posta 之前在 “[Towards a Unified, Standard API for Consolidating Service Meshes ](https://www.infoq.com/articles/service-mesh-api-federating/)中写过关于服务网格使用标准化的尝试。这篇文章还讨论了 2019 年微软和合作伙伴在 KubeCon EU 上宣布的[服务网格接口（SMI）](https://cloudblogs.microsoft.com/opensource/2019/05/21/service-mesh-interface-smi-release/)。SMI 定义了一套通用和可移植的 API，旨在为开发人员提供不同服务网格技术的互操作性，包括 Istio、Linkerd 和 Consul Connect。

将服务网格与平台结构整合的主题可以进一步分为两个子主题。

首先，正在进行的工作是减少由服务网格数据平面引入的网络开销。这包括[数据平面开发工具包（DPDK）](https://www.dpdk.org/)，它是一个[用户空间应用程序](https://www.linuxjournal.com/content/userspace-networking-dpdk)，“绕过了 Linux 内核网络堆栈，直接与网络硬件对话”。还有 [Cilium 团队的](https://www.infoq.com/news/2018/03/cilium-linux-bpf/)基于 Linux 的 BPF 解决方案，它利用 Linux 内核中的扩展[伯克利包过滤器（eBPF）功能](https://cilium.io/blog/istio/)来实现 “非常有效的网络、策略执行和负载均衡功能”。另一个团队正在用[网络服务网格（Network Service Mesh）](https://github.com/networkservicemesh/networkservicemesh/)将服务网格的概念映射到 L2/L3 有效载荷，试图 “以云原生的方式重新想象网络功能虚拟化（NFV）"。

其次，有多项举措将服务网格与公共云平台更紧密地结合在一起，从 [AWS App Mesh](https://www.infoq.com/news/2019/01/aws-app-mesh/)、[GCP Traffic Director](https://www.infoq.com/news/2019/04/google-traffic-director/) 和 [Azure Service Fabric Mesh 的](https://www.infoq.com/articles/azure-service-fabric-mesh/)发布可见端倪。

Buoyant 团队致力于为服务网格技术开发有效的以人为本的控制平面。他们最近发布了 [Buoyant Cloud](https://buoyant.io/cloud/)，一个基于 SaaS 的 “团队控制平面”，用于平台团队操作 Kubernetes。这个产品将在下面的章节中详细讨论。

自去年以来，在服务网格领域也有一些创新。

### 多云、多集群、多租户服务网格

近年来，不同组织对云的采用已经从单一的云解决方案（私有云或公共云）转变为由多个不同供应商（AWS、谷歌、微软 Azure 等）支持的基于多云（私有、公共和混合）的新基础设施。同时，需要支持不同的工作负载（交易、批处理和流媒体），这对实现统一的云架构至关重要。

这些业务和非功能需求反过来又导致需要在异构基础设施（裸机、虚拟机和 Kubernetes）中部署服务网格解决方案。服务网格需要相应转变，以支持这些不同的工作负载和基础设施。

像 [Kuma](https://konghq.com/blog/multi-cluster-multi-cloud-service-meshes-with-cncfs-kuma-and-envoy/) 和 [Tetrate Service Bridge](https://www.tetrate.io/tetrate-service-bridge/) 这样的技术支持多网格控制平面，以使业务应用在多集群和多云服务网格环境中工作。这些解决方案抽象出跨多个区域的服务网格策略的同步以及跨这些区域的服务连接（和服务发现）。

多集群服务网格技术的另一个新趋势是需要从边缘计算层（物联网设备）到网格层的应用 / 服务连接。

### 媒体服务网格

思科系统公司开发的[媒体流网格（Media Streaming Mesh）](https://www.ciscotechblog.com/blog/introducing-media-streaming-mesh/)或媒体服务网格，用于协调实时应用程序，如多人游戏、多方视频会议或在 Kubernetes 云平台上使用服务网格技术的 CCTV 流。这些应用正越来越多地从单体应用转向微服务架构。服务网格可以通过提供负载均衡、加密和可观测性等功能来帮助应用程序。

### 混沌网格

[Chaos Mesh](https://chaos-mesh.org/) 是 [CNCF 托管的项目](https://community.cncf.io/chaos-mesh-community/)，是一个开源的、云原生的混沌工程平台，用于托管在 Kubernetes 上的应用程序。虽然不是直接的服务网格实现，但 Chaos Mesh 通过协调应用程序中的故障注入行为来实现混沌工程实验。故障注入是服务网格技术的一个关键能力。

Chaos Mesh 隐藏了底层的实现细节，因此应用开发者可以专注于实际的混沌实验。Chaos Mesh [可以和服务网格一起使用](https://chaos-mesh.org/blog/chaos-mesh-q&a/)。请看这个[用例](https://github.com/sergioarmgpl/operating-systems-usac-course/blob/master/lang/en/projects/project1v3/project1.md)，该团队如何使用 Linkerd 和 Chaos Mesh 来为他们的项目进行混沌实验。

### 服务网格作为一种服务

一些服务网格供应商，如 Buoyant，正在提供管理服务网格或 “服务网格作为一种服务 “的解决方案。今年早些时候，Buoyant [宣布](https://buoyant.io/newsroom/buoyant-cloud-offers-managed-service-mesh/)公开测试发布一个名为 [Buoyant Cloud 的](http://buoyant.io/cloud) SaaS 应用程序，允许客户组织利用 Linkerd 服务网格的按需支持功能来管理服务网格。

Buoyant Cloud 解决方案提供的一些功能包括如下：

- 自动跟踪 Linkerd 数据平面和控制平面的健康状况
- 在 Kubernetes 平台上管理跨 pod、代理和集群的服务网格生命周期和版本
- 以 SRE 为重点的工具，包括服务水平目标（SLO）、工作负荷黄金指标跟踪和变更跟踪

### 网络服务网格（NSM）

网络服务网格（[NSM](https://networkservicemesh.io/)）是云原生计算基金会的另一个沙盒项目，提供了一个混合的、多云的 IP 服务网格。NSM 实现了网络服务连接、安全和可观测性等功能，这些都是服务网格的核心特征。NSM 与现有的容器网络接口（[CNI](https://github.com/containernetworking/cni)）实现协同工作。

### 服务网格扩展

服务网格扩展是另一个已经看到很多创新的领域。服务网格扩展的一些发展包括：

- 增强的身份管理，以确保微服务连接的安全，包括自定义证书授权插件
- 自适应路由功能，以提高服务的可用性和可扩展性
- 加强 sidecar 代理权

### 服务网格业务

采用服务网格的另一个重要领域是服务网格生命周期的运维方面。操作方面 —— 如配置多集群功能和将 Kubernetes 工作负载连接到虚拟机基础设施上托管的服务器，以及管理多集群服务网格中所有功能和 API 的开发者门户 —— 将在生产中服务网格解决方案的整体部署和支持方面发挥重要作用。

## 常见问题

### 什么是服务网格？

服务网格是一种在分布式（可能是基于微服务的）软件系统内管理所有服务对服务（东西向）流量的技术。它既提供以业务为重点的功能操作，如路由，也提供非功能支持，如执行安全策略、服务质量和速率限制。它通常（尽管不是唯一的）使用 sidecar 代理来实现，所有服务都通过 sidecar 代理进行通信。

### 服务网格与 API 网关有什么不同？

关于服务网格的定义，见上文。

另一方面，API 网关管理进入集群的所有入口（南北）流量，并为跨功能的通信要求提供额外支持。它作为进入系统的单一入口点，使多个 API 或服务凝聚在一起，为用户提供统一的体验。

### 如果我正在部署微服务，我是否需要服务网格？

不一定。服务网格增加了技术栈的操作复杂性，因此通常只有在组织在扩展服务与服务之间的通信方面遇到困难，或者有特定的用例需要解决时才会部署。

### 我是否需要服务网格来实现微服务的服务发现？

不，服务网格提供了实现服务发现的一种方式。其他解决方案包括特定语言的库（如 Ribbon 和 [Eureka](https://www.infoq.com/news/2012/09/Eureka/) 或 [Finagle](https://www.infoq.com/finagle/)）。

### 服务网格是否会给我的服务之间的通信增加开销 / 延迟？

是的，当一个服务与另一个服务进行通信时，服务网格至少会增加两个额外的网络跳数（第一个是来自处理源的出站连接的代理，第二个是来自处理目的地的入站连接的代理）。然而，这个额外的网络跳转通常发生在 [localhost 或 loopback 网络接口](https://en.wikipedia.org/wiki/Localhost)上，并且只增加了少量的延迟（在毫秒级）。实验和了解这对目标用例是否是一个问题，应该是服务网格分析和评估的一部分。

### 服务网格不应该是 Kubernetes 或应用程序被部署到的 "云原生平台" 的一部分吗？

潜在的。有一种说法是在云原生平台组件内保持关注点的分离（例如，Kubernetes 负责提供容器编排，而服务网格负责服务间的通信）。然而，正在进行的工作是将类似服务网格的功能推向现代平台即服务（PaaS）产品。

### 我如何实施、部署或推广服务网格？

最好的方法是分析各种服务网格产品（见上文），并遵循所选网格特有的实施准则。一般来说，最好是与所有利益相关者合作，逐步将任何新技术部署到生产中。

### 我可以建立自己的服务网格吗？

是的，但更相关的问题是，你应该吗？建立一个服务网格是你组织的核心竞争力吗？你能否以更有效的方式为你的客户提供价值？你是否也致力于维护你自己的网络，为安全问题打补丁，并不断更新它以利用新技术？由于现在有一系列的开源和商业服务网格产品，使用现有的解决方案很可能更有效。

### 在一个软件交付组织内，哪个团队拥有服务网格？

通常，平台或运维团队拥有服务网格，以及 Kubernetes 和持续交付管道基础设施。然而，开发人员将配置服务网格的属性，因此这两个团队应该紧密合作。许多企业正在追随云计算先锋的脚步，如 Netflix、Spotify 和谷歌，并正在创建内部平台团队，为[以产品为重点的全周期开发团队](https://www.infoq.com/news/2018/06/netflix-full-cycle-developers/)提供工具和服务。

### Envoy 是一个服务网格吗？

Envoy 是一个云原生代理，最初是由 Lyft 团队设计和构建的。Envoy 经常被用作服务网格的数据平面。然而，为了被认为是一个服务网格，Envoy 必须与控制平面一起使用，这样才能使这些技术集合成为一个服务网格。控制平面可以是简单的集中式配置文件库和指标收集器，也可以是全面 / 复杂的 Istio。

### Istio 和 “服务网格 " 这两个词可以互换使用吗？

不，Istio 是服务网格的一种。由于 Istio 在服务网格类别出现时很受欢迎，一些人将 Istio 和服务网格混为一谈。这个混淆的问题并不是服务网格所独有的，同样的挑战发生在 Docker 和容器技术上。

### 我应该使用哪个服务网格？

这个问题没有唯一的答案。工程师必须了解他们当前的需求，以及他们的实施团队的技能、资源和时间。上面的服务网格比较链接将提供一个良好的探索起点，但我们强烈建议企业至少尝试两个网格，以了解哪些产品、技术和工作流程最适合他们。

### 我可以在 Kubernetes 之外使用服务网吗？

是的。许多服务网格允许在各种基础设施上安装和管理数据平面代理和相关控制平面。[HashiCorp 的 Consul](https://www.hashicorp.com/resources/consul-service-mesh-kubernetes-and-beyond) 是最知名的例子，Istio 也被实验性地用于 Cloud Foundry。

## 其他资源

- [InfoQ 服务网格主页](https://www.infoq.com/servicemesh/)
- [InfoQ eMag：服务网格的过去、现在和未来](https://www.infoq.com/minibooks/service-mesh/)
- [服务网格：每位软件工程师都需要了解的世界上最容易被滥用的技术](https://servicemesh.io/)
- [服务网格的比较](https://servicemesh.es/)
- [服务网格](https://softwareengineeringdaily.com/2020/01/07/service-meshes/)
- [采用云原生架构，第三部分：服务协调和服务网格](https://www.infoq.com/articles/cloud-native-architecture-adoption-part3/)
