---
title: 云原生网络功能（CNF）应该让每个容器聚焦一个关注点
summary: "这篇文章介绍了如何编写云原生网络功能（CNF），即在电信领域的网络应用，它们与大多数云原生企业应用有不同的非功能性需求。CNF 需要满足高性能、高可靠性、高安全性和低延迟等指标。文章提出了一个基本的设计原则：每个容器只负责一个关注点，即一个单一的网络功能或子功能。"
date: '2023-03-02T11:00:00+08:00'
draft: false
featured: false
authors: ["W. Watson"]
tags: ["云原生"]
categories: ["云原生"]
links:
  - icon: language
    icon_pack: fa
    name: 阅读英文版原文
    url: https://infoq.com/articles/cloud-native-network-functions-concern/
---

> 译者注：这篇文章介绍了如何编写云原生网络功能（CNF），即在电信领域的网络应用，它们与大多数云原生企业应用有不同的非功能性需求。CNF 需要满足高性能、高可靠性、高安全性和低延迟等指标。文章提出了一个基本的设计原则：每个容器只负责一个关注点，即一个单一的网络功能或子功能。

## 本文主旨

- Docker 和 Kubernetes 文档都提倡将一个应用程序或每个容器“一个问题”打包的概念。这也可以作为每个应用程序和容器运行“一种进程类型”的指南。
- 基于电信的云原生网络功能 (CNF) 具有低延迟、高吞吐量和弹性等特定要求，这激发了多关注点/多进程类型的容器化方法。
- 使用多种进程类型实现的高性能电信应用程序应该探索使用 unix 域套接字而不是 TCP 或 HTTP 进行通信，因为这可以加快容器之间的通信。

[微服务的详细和简明定义](https://vmblog.com/archive/2022/01/04/the-zeitgeist-of-cloud-native-microservices.aspx#.Y73WvezMJhE) 很有价值。厚微服务可以是任何利用康威定律并按产品团队边界部署代码的东西。精益微服务是那些遵循粗粒度代码部署的服务，通常在容器中，具有单一的关注点。

[Cloud Native Network Functions](https://www.infoq.com/articles/cloud-native-network-functions/)（CNFs）是电信领域的网络应用，非功能性需求不同于大多数云原生企业应用。CNF 通常是 [有状态的](https://www.cncf.io/blog/2022/09/12/top-11-things-you-didnt-know-about-cloud-native-statefulness/) 同时需要 [低延迟、高吞吐量和弹性](https://www.cncf.io/blog/2022/09/26/top-9-overlooked-questions-when-designing-your-stateful-cloud-native-network-application/ )。任何减少或禁止这些要求的架构要么不适合电信发展，要么在其实施中需要特殊例外。这就是瘦微服务模型的挑战，它促进了容器和 CNF 的“一个关点，一个进程”的设计。

## 每个容器聚焦于一个关注点

[Google 云文档、](https://cloud.google.com/architecture/best-practices-for-building-containers)[docker 文档](https://docs.docker.com/config/containers/multi-service_container/) 和 [Kubernetes 文档](https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers) 都提倡每个容器一个应用程序或一个关注点的概念。谷歌云文档使用术语“应用程序”，而 docker 文档使用术语“关注点”并将关注点进一步描述为一组父/子进程，它们是应用程序的一个方面。nginx 实现就是一个很好的例子，它将在启动时创建一组子工作进程。理解单一关注规则的另一种方法是说容器中应该只存在一种进程类型（例如一组 nginx 工作进程）。

为什么存在这条规则？虽然最初认为这条规则背后的基本原理是降低单个模块、组件、对象等的复杂性，但这条规则背后的真正驱动力是尊重代码的变化率，这个概念借鉴了传统建筑概念和生物学。工件的部署速度应与其更改频率一致。云原生的方式是通过尽最大努力解耦代码来做到这一点。对性能优化的需求通常会助长对解耦的抵制，我们将在后面介绍。

电信等行业有独立发展的历史。换句话说，在电信行业内，代码、代码库和代码部署都是在一个大型组织内开发的。即使多个子组织共同开发一个大型项目（例如商业级交换机），此类库、项目和最终产品的部署也是集中部署并锁定步骤。鉴于这段历史，即使前面提到的微服务的厚定义存在问题，网络功能更难遵守微服务的薄定义和单一关注点规则也就不足为奇了。

## 每个进程一个关注点的七大好处

[Tom Donohue](https://twitter.com/monodot) 说明了此处重述的[单一关注原则](https://www.tutorialworks.com/containers-single-or-multiple-processes/) 的好处：

- **隔离**：进程在使用容器命名空间系统时，不会相互干扰。
- **可扩展性**：与许多类型相比，扩展一个进程或一类进程更容易。这可能是出于复杂性的原因（一种进程类型比许多进程类型更难扩展）或因为变化率不同（一个进程需要根据与其他进程不同的条件增长）。
- **可测试性**：当假定一个进程独立运行时，它可以独立于其他进程进行测试。这使开发人员可以通过消除额外的变量来更轻松地定位问题的根本原因。
- **可部署性**：当进程的二进制文件和依赖项部署在容器中时，部署的变化率相对于二进制文件和容器是粗粒度的，但相对于其他进程及其依赖项是细粒度的。这允许部署根据依赖树中发生更改的位置和时间进行调整，而不是同步重新部署所有内容。
- **可组合性**：进程中只有一个关注点，因此每个容器的进程类型更容易推理，因为它更容易以数字方式共享和口头交流其内容。这使得它更容易在其他项目中重用。
- **遥测**：从一个问题或进程类型推断日志消息比与其他问题交错的日志消息更容易。在将所有日志消息打印到 [标准输出](https://en.wikipedia.org/wiki/Standard_streams) 的容器中尤其如此，例如 12 因素云原生应用程序。
- **编排**：如果容器中有多个进程类型，则必须在容器内管理次要关注点的生命周期，这实际上意味着在父进程类型中创建编排器。

开源云原生运动对电信行业的影响是供应商之间协作的爆炸式增长。与在一个组织的保护伞下开发紧密耦合的软件相反，对更多协作和互操作性的呼吁已经促使来自不同组织的多个项目重新审视单一关注点原则的好处。

## 云原生进程最佳实践

### 独立于流程顺序

将多个进程类型放在同一个容器中的论据之一是[需要更多地控制问题的启动顺序](https://medium.com/@kelseyhightower/12-fractured-apps-1080c73d481c)。例如需要数据库的传统应用程序。如果数据库不可用，应用程序和 Web 服务器可能无法正常启动，因此有人可能会在启动应用程序之前手动启动 docker 文件中的数据库。虽然这确实有效，但这样做会失去关注点松散耦合的七个好处。更好的方法是使您的关注点和流程类型尽可能独立于顺序。

### 你的进程将被终止

Kubernetes 有一个 [pod 优先级](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) 的设置，如果不满足一组条件时，允许用户[抢占或终止](https://kubernetes.io/docs/concepts/scheduling-eviction/) pod。这意味着 pod 需要响应来自这些调度策略的正常关闭请求，否则它们将面临数据损坏和其他错误。这些正常关闭请求以 [SIGTERM 请求](https://www.gnu.org/software/libc/manual/html_node/Termination-Signals.html) 的形式出现，通常在 SIGKILL 请求发出前 30 秒终止强制过程。当运行多个进程时，所有子进程都需要能够处理正常关闭信号。正如我们稍后将看到的，处理进程的正常关闭可能会导致一些微妙的问题，这些问题在处理多个进程时会变得更糟。

在电信中，流程顺序独立性和抢占通常由与其管理的流程紧密耦合的编排器处理。有了像 Kubernetes 这样的与应用程序无关的编排器，这些自定义和紧密耦合的编排器时代即将结束，如[声明式调度配置](https://kubernetes.io/docs/reference/scheduling/config/)。电信云原生方法可能应该类似于 Erlang 社区对进程的 "[让它失败](https://erlang.org/download/armstrong_thesis_2003.pdf)"方法，其中调用进程对它所调用的进程更加稳健。

### 多进程和应用程序生命周期

[Google Cloud](https://cloud.google.com/architecture/best-practices-for-building-containers) 建议您为每个容器打包一个“应用程序”。在更技术层面上，单个应用程序被定义为具有可能的许多子进程的单个父进程。这一基本原理的主要部分是利用应用程序生命周期中不同的变化率。生命周期是什么意思？生命周期是应用程序的开始、执行和终止。任何具有不同启动、执行或终止原因的进程都应该与其他进程分开（即不紧密耦合）。当我们理清这些问题时，我们可以将它们表示为单独的健康检查、策略和部署配置。然后我们可以声明性地表达这些关注点，在源代码控制中跟踪它们，并在语义上对它们进行版本控制。这使我们能够避免步调一致地升级，导致将不同的应用生命周期锁定在一起。

管理容器中多个应用程序或进程类型的生命周期的问题源于它们都有[不同的状态](https://cloud.google.com/architecture/best-practices-for-building-container#package_a_single_app_per_container)。例如，如果您有一个父进程启动 Apache，然后还启动 Redis，则父进程需要知道如何以及何时启动、监视和终止 Apache 和 Redis。对于您无法控制的代码或二进制文件，此问题甚至更加困难，因为您无法控制这些应用程序如何表达其健康状况。这就是为什么表达程序健康状况的最佳位置，尤其是您无法控制的进程，是在暴露给容器管理系统或编排器（例如 Kubernetes）的配置中，它旨在适应生命周期而不是临时的 bash 脚本。

### 多进程加剧云原生信号和僵尸问题

[不处理所谓的 PID 1](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/) 容器中的进程充满了极度隐蔽、难以察觉的问题。当涉及多个进程时，这些问题会加剧。正确处理 PID 1 的两个主要问题是[处理终止信号和僵尸](https://cloud.google.com/architecture/best-practices-for-building-containers#signal-handling)。

### SIGTERM

所有应用程序和进程都必须知道两种类型的关机：正常关机和立即关机。假设一个有状态应用程序希望打开一个重要文件、写入数据并关闭文件而不被中断。在这种情况下，由于 K8s 的抢占功能，应用程序最终会破坏文件。处理此类问题的一种方法是正常关闭。这就是 SIGTERM 信号的作用。它告诉应用程序它将被关闭并开始正常运行以避免损坏或其他错误。在编排系统中，所有进程都应设计为在需要时处理正常关闭。但是启动其他进程的进程呢？为了处理子进程的正常终止，父进程需要向所有子进程传递 SIGTERM 信号，让它们也正常关闭。这就是 PID 1 处理不当的问题所在。除非明确告知，否则像 bash 这样的简单脚本不会将 SIGTERM 信号传递给它们启动的进程。如果您不通过 SIGTERM，将产生非常难以检测的错误。

### 一个隐蔽的 SIGTERM 错误示例

[Gitlab 记录](https://about.gitlab.com/blog/2022/05/17/how-we-removed-all-502-errors-by-caring-about-pid-1-in-kubernetes/)他们遇到了一个问题，即页面上会出现 502 错误，但在一定时间后神秘地自行修复。问题是因为前面提到的正常终止信号 (SIGTERM) 没有被发送到在页面服务资源被删除后打开连接的子进程。众所周知，这个问题很难追踪。

### 僵尸进程

容器中的[PID 1 进程](https://en.m.wikipedia.org/wiki/Process_identifier)也会在子进程终止后清理它们。这看起来很简单，但默认情况下 PID 1 bash 脚本无法正确清理。不清理或收割子进程意味着什么？这些不干净的进程，也称为僵尸进程，填满了所谓的进程表。它们最终会阻止您启动新进程，从而阻止您的整个节点运行。

### 一个合适的初始化系统来处理僵尸和信号

限制僵尸进程影响的一种方法是拥有一个[适当的初始化系统](https://ahmet.im/blog/minimal-init-process-for-containers/)。如果您正在考虑使用您无法控制的代码（例如 Postgres 数据库）运行 PID 1 进程，则尤其如此。这个进程可能会启动其他进程，然后忘记收割它们。使用适当的 init 系统，任何终止的子进程最终都会被 init 系统回收。

您可以在容器内运行适当的初始化系统和复杂的监督程序。监督程序有时候被认为是矫枉过正，因为它们占用了太多资源，而且有时过于复杂。复杂监管程序有 supervisord、monit 和 runit。适当的 init 系统比复杂的监管程序小，因此适用于容器。合适的容器初始化系统有 tini、dumb-init 和 s6-overlay。

## 性能和云原生电信进程

在容器中运行多个进程的主要动机之一是对性能的渴望。在单独的容器中而不是在同一个容器中运行进程（假设进程间通信是相同的）似乎会降低性能。这种[性能下降可归因于](https://pythonspeed.com/articles/docker-performance-overhead/) 容器系统中内置的隔离和安全措施。也可以通过在特权模式下运行容器来删除它，但这会降低安全性。

人们对将进程分离到多个容器中存在一种误解，那就是所有通信的性能都会受到影响，因为它必须通过 TCP 或更糟糕的 HTTP 进行。这不太对。通过[使用 unix 域套接字进行通信](https://dev.to/douglassakey/a-simple-example-of-using-unix-domain-socket-in-kubernetes-1fga)。这可以在 Kubernetes 中通过使用在 pod 内的所有容器之间共享的卷挂载来配置。

在电信环境中，数据平面的核心关注点是性能，因此使用线程、共享内存和进程间通信来提高性能。当这些问题密切相关时，它会因为复杂性而增加。在不同容器之间但在同一个 pod 中实现的进程间通信应该有所帮助。电信控制平面通常需要较低的性能，因此可以设计为遗留应用程序

## 总结

为了获得云原生生态系统的最大互操作性和可升级性优势，电信行业需要遵守容器和部署的单一焦点规则。能够做到这一点的供应商将比不能做到这一点的供应商更具竞争优势。

*要了解更多云原生原理，请加入 CNCF 的云原生[网络功能工作组](https://github.com/cncf/cnf-wg)。有关 CNCF 的 CNF 认证计划的信息，该计划[验证您网络功能中的云原生最佳实践](https://www.cncf.io/certification/cnf/)。*

*特别感谢 Denver Williams 对本文的技术审阅。*
