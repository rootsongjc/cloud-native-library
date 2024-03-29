---
weight: 3
title: 2.3 技术变革
date: '2022-05-18T00:00:00+08:00'
type: book
---

现在我们将一些问题转移到了云中的 DevOps 平台。

## 分解单体应用

传统的 n 层单体式应用部署到云中后很难维护，因为它们经常对云基础设施提供的部署环境做出不可靠的假设，这些假设云很难提供。例如以下要求：

- 可访问已挂载的共享文件系统
- P2P 应用服务器集群
- 共享库
- 配置文件位于常用的配置文件目录

大多数这些假设都出于这样的事实：单体应用通常都部署在长期运行的基础设施中，并与其紧密结合。不幸的是，单体应用并不太适合弹性和短暂（非长期支持）生命周期的基础设施。

但是即使我们可以构建一个不需要这些假设的单体应用，我们依然有一些问题需要解决：

- 单体式应用的变更周期耦合，使独立业务能力无法按需部署，阻碍创新速度。
- 嵌入到单体应用中的服务不能独立于其他服务进行扩展，因此负载更难于优化。
- 新加入组织的开发人员必须适应新的团队，经常学习新的业务领域，并且一次就熟悉一个非常大的代码库。这样会增加 3-6 个月的适应时间，才能实现真正的生产力。
- 尝试通过堆积开发人员来扩大开发组织，增加了昂贵的沟通和协调成本。
- 技术栈需要长期承诺。引进新技术太过冒险，可能会对整体产生不利影响。

细心的读者会注意到，该列表正好与“微服务”的列表相反。将组织分解为业务能力团队还要求我们将应用程序分解成微服务。只有这样，我们才能从云计算基础架构中获得最大的收益。

## 分解数据

仅仅将单体应用分解为微服务还是远远不够的。数据模型必须要解耦。如果业务能力团队被认为是自主的，却被迫通过单一的数据存储进行协作，那么单体应用对创新的阻碍将依然存在。

事实上，产品架构必须从数据开始的说法是有争议的。由 Eric Evans（Addison-Wesley）在领域驱动设计（DDD）中提出的原理认为，我们的成功在很大程度上取决于领域模型的质量（以及支持它的普遍存在的语言）。要使领域模型有效，还必须在内部一致 —— 我们不应该在同一模型内的一致定义中找到重复定义的术语或概念。

创建不具有这种不一致的联合领域模型是非常困难和昂贵的（可以说是不可能的）。Evans 将业务的整体领域模型的内部一致性子集称为有界上下文。

最近与航空公司客户合作时，我们讨论了他们业务的核心概念，自然是“航空公司预订”的话题。该集团可以在其预定业务中划分十七种不同的逻辑定义，几乎不能将它们调和为一个。相反，每个定义的所有细微差别都被仔细地描绘成一个个单一的概念，这将成为组织的巨大瓶颈。

有界上下文允许你在整个组织中保持单一概念的不一致定义，只要它们在有界上下文中一致地定义。

因此，我们首先需要确定可以在内部保持一致的领域模型的细分。我们在这些细分上画出固定的边界，划分出有界上下文。然后，我们可以将业务能力团队与这些环境相匹配，这些团队将构建提供这些功能的微服务。

微服务提供了一个有用的定义，用于定义 12 因素应用程序应该是什么。12 因素主要是技术规范，而微服务主要是业务规范。通过定义有界上下文，为它们分配一组业务能力，委托业务能力团队对这些业务能力负责，并建立 12 因素应用程序。在这些应用程序可以独立部署的情况下，为业务能力团队的运维提供了一组有用的技术工具。

我们将有界上下文与每个服务模式的数据库结合，每个微服务封装、管理和保护自己的领域模型和持久存储。在每个服务模式的数据库中，只允许一个应用程序服务访问逻辑数据存储，逻辑数据存储可能是以多租户集群中的单个 schema 或专用物理数据库中存在。对这些概念的任何外部访问都是通过一个明确定义的业务协议来实现的，该协议的实现方式为 API（通常是 REST，但可能是任何协议）。

这种分解允许应用拥有多语言支持的持久性，或者基于数据形态和读写访问模式选择不同的数据存储。然而，数据必须经常通过事件驱动技术重新组合，以便请求交叉上下文。诸如命令查询责任隔离（CQRS）和事件溯源（Event Sourcing）之类的技术通常在跨上下文同步类似概念时很有帮助，这超出了本文的范围。

## 容器化

容器镜像（例如通过 LXC、Docker 或 Rocket 项目准备的镜像）正在迅速成为云原生应用架构的部署单元。然后通过诸如 Kubernetes、Marathon 或 Lattice 等各种调度解决方案实例化这样的容器镜像。亚马逊和 Google 等公有云供应商也提供一流的解决方案，用于容器化调度和部署。容器利用现代的 Linux 内核原语，如控制组（cgroups）和命名空间来提供类似的资源分配和隔离功能，这些功能与虚拟机提供的功能相比，具有更少的开销和更强的可移植性。应用程序开发人员将需要将应用程序包装成容器镜像，以充分利用现代云基础架构的功能。

## 从管弦乐编排到舞蹈编舞

不仅仅服务交付、数据建模和治理必须分散化，服务集成也是如此。企业服务集成传统上是通过企业服务总线（ESB）实现的。ESB 成为管理服务之间交互的所有路由、转换、策略、安全性和其他决策的所有者。我们将其称之为编排，类似于导演，它决定了乐团演出期间演奏音乐的流程。ESB 和编排可以产生非常简单和令人愉快的架构图，但它们的简单性仅仅是表面性的。在 ESB 中隐藏的是复杂的网络。管理这种复杂性成为全职工作，这成为应用开发团队的持续瓶颈。正如我们在联合数据模型所看到的，像 ESB 这样的联合集成解决方案成为阻碍幅度的巨大难题。

诸如微服务这样的云原生架构更倾向于舞蹈，它们类似于芭蕾舞中的舞者。它们将心智放置在端点上，类似于 Unix 架构中的虚拟管道和智能过滤器，而不是放在集成机制中。当舞台上的情况与原来的计划有所不同时，没有导演告诉舞者该怎么做。相反，他们会自适应。同样，服务通过客户端负载均衡和断路器等模式，适应环境中不断变化的各种情况。

虽然架构图看起来像一个庞杂的网络，但它们的复杂性并不比传统的 SOA 大。编排简单地承认并暴露了系统原有的复杂性。再次，这种转变是为了支持从云原生架构中寻求速度所需的自治。团队能够适应不断变化的环境，而无需承担与其他团队协调的开销，并避免了在集中管理的 ESB 中协调变更所造成的开销。