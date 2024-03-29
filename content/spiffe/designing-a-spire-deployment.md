---
weight: 7
title: 设计一个 SPIRE 部署
linktitle: 6. 设计一个 SPIRE 部署
date: '2022-10-07T00:00:00+08:00'
type: book
description: "读者将了解到 SPIRE 部署的组成部分，有哪些部署模式，以及在部署 SPIRE 时需要考虑哪些性能和安全问题。"
---

读者将了解到 SPIRE 部署的组成部分，有哪些部署模式，以及在部署 SPIRE 时需要考虑哪些性能和安全问题。

你的 SPIRE 部署的设计应满足你的团队和组织的技术要求。它还应包括支持可用性、可靠性、安全性、可扩展性和性能的要求。该设计将作为你的部署活动的基础。

## 身份命名方案

请记住，在前面的章节中，SPIFFE ID 是一个结构化的字符串，代表一个工作负载的身份名称，正如你在第四章中看到的那样。工作负载标识符部分（URI 的路径部分）附加在信任域名（URI 的主机部分）上，可以组成关于服务所有权的含义，以表示它在什么平台上运行，谁拥有它，它的预期目的，或其他惯例。它是特意为你定义的灵活和可定制的。

你的命名方案可能是分层的，就像文件系统的路径。也就是说，为了减少歧义，命名方案不应该以尾部的正斜杠（`/`）结束。下面你将看到一些不同的样例，它们遵循三种不同的约定，你可以遵循，或者如果你感到特别有灵感，也可以想出你自己的。

### 直接命名服务

你可能会发现，作为软件开发生命周期的一部分，直接通过它从应用角度呈现的功能和它运行的环境来识别一个服务是很有用的。例如，管理员可能会规定，在特定环境中运行的任何进程都应该能够以特定身份出现。比如说。

```
 spiffe://staging.example.com/payments/mysql
```

或

```
 spiffe://staging.example.com/payments/web-fe
```

上面的两个 SPIFFE ID 指的是两个不同的组件 ——MySQL 数据库服务和一个 Web 前端 —— 在 staging 环境中运行的支付服务。`staging` 的意思是一个环境，`payment` 是一个高级服务。

前面两个例子和下面两个例子是说明性的，不是规定性的。实施者应该权衡自己的选择，决定自己喜欢的行动方案。

### 识别服务所有者

通常更高级别的编排器和平台都有自己的内置身份概念（如 Kubernetes 服务账户，或 AWS/GCP 服务账户），能够直接将 SPIFFE 身份映射到这些身份是有帮助的。比如：

```
spiffe://k8s-workload-cluster.example.com/ns/staging/sa/default
```

在这个例子中，信任域 `example.com` 的管理员正在运行一个 Kubernetes 集群 `k8s-workload-cluster.example.com`，它有一个 `staging` 命名空间，在这个命名空间中，有一个名为 `default` 的服务账户（SA）。

### 不透明的 SPIFFE 身份

SPIFFE 路径可能是不透明的，然后元数据可以被保存在一个二级数据库中。这可以被查询以检索与 SPIFFE 标识符相关的任何元数据。比如：

```
 spiffe://example.com/9eebccd2-12bf-40a6-b262-65fe0487d4
```

## SPIRE 的部署模式

我们将概述在生产中运行 SPIRE 的三种最常见的方式。这并不意味着我们要在这里限制可用的选择，但为了本书的目的，我们将把范围限制在这些部署 SPIRE 服务器的常见方式上。我们将只关注服务器的部署架构，因为每个节点通常安装一个代理。

### 数量：大信任域与小信任域的对比

信任域的数量预计是相对固定的，只是偶尔重访，而且预计不会随时间漂移太多。另一方面，一个给定的信任域中的节点数量和工作负载的数量，预计会根据负载和增长而频繁波动。

选择集中到一个大的信任域的单一信任根，还是分布和隔离到多个信任域，将由许多因素决定。本章的安全考虑部分谈到了使用信任域进行隔离的问题。还有一些原因，你可以选择多个小的信任域而不是一个大的信任域，包括增加可用性和租户的隔离。管理域边界、工作负载数量、可用性要求、云供应商数量和认证要求等变量也会影响这里的决策。

例如，你可以选择为每一个行政边界设置一个单独的信任域，以便在组织中可能有不同开发实践的不同小组之间进行自治。

| 类别     | 单信任域 | 嵌套   | 联合 |
| :------- | :------- | :----- | :--- |
| 部署规模 | 大       | 非常大 | 大   |
| 多区域   | 否       | 是     | 是   |
| 多云     | 否       | 是     | 是   |

表 6.1: 信任域大小的决策表

**一对一：单信任域中的单一 SPIRE 集群**

单一的 SPIRE 服务器，在高可用性的配置下，是单一信任域环境的最佳起点。

![图 6.1: 单一信任域。](../images/f6-1.jpg)

然而，当将单个 SPIRE 服务器部署到跨越区域、平台和云提供商环境的信任域时，当 SPIRE 代理依赖于远处的 SPIRE 服务器时，会出现潜在的扩展问题。在单个部署将跨越多个环境的情况下，解决在单个信任域上使用共享数据存储的解决方案是将 SPIRE 服务器配置为嵌套拓扑结构。

### 嵌套式 SPIRE

SPIRE 服务器的嵌套拓扑结构可使您尽可能保持 SPIRE 代理和 SPIRE 服务器之间的通信。

在这种配置中，顶级 SPIRE 服务器持有根证书和密钥，而下游服务器请求中间签名证书，作为下游服务器的 X.509 签名授权。如果顶层发生故障，中间服务器继续运行，为拓扑结构提供弹性。

嵌套拓扑结构很适合多云部署。由于能够混合和匹配节点验证器，下游服务器可以在不同的云提供商环境中驻留并为工作负载和代理提供身份。

![图 6.2：嵌套式 SPIRE 拓扑结构。](../images/f6-2.jpg)

虽然嵌套式 SPIRE 是提高 SPIRE 部署的灵活性和可扩展性的理想方式，但它并不提供任何额外的安全性。由于 X.509 没有提供任何方法来限制中间证书颁发机构的权力，每个 SPIRE 服务器可以生成任何证书。即使你的上游证书颁发机构是你公司地下室混凝土掩体中的加固服务器，如果你的 SPIRE 服务器被破坏，你的整个网络可能会受到影响。这就是为什么必须确保每台 SPIRE 服务器都是安全的。

![图 6.3：具有一个上游 SPIRE 服务器和两个嵌套 SPIRE 服务器的公司架构说明。两个嵌套的 SPIRE 服务器中的每一个都可以有自己的配置（与 AWS 和 Azure 有关），如果其中任何一个出现故障，另一个就不会受到影响。](../images/f6-3.jpg)

### SPIRE 联邦

部署可能需要多个信任根基，也许是因为一个组织有不同的组织部门，有不同的管理员，或者因为他们有独立的暂存和生产环境，偶尔需要沟通。

另一个用例是组织之间的 SPIFFE 互操作性，如云供应商和其客户之间。

![图 6.4：使用联邦信任域的 SPIRE 服务器。](../images/f6-4.jpg)

这些多个信任域和互操作性用例都需要一个定义明确、可互操作的方法，以便一个信任域中的工作负载能够认证不同信任域中的工作负载。在联合 SPIRE 中，不同信任域之间的信任是通过首先认证各自的捆绑端点，然后通过认证的端点检索外部信任域的捆绑来建立的。

### 独立的 SPIRE 服务器

运行 SPIRE 的最简单方法是在专用服务器上，特别是如果有一个单一的信任域，而且工作负载的数量不大。在这种情况下，你可以在同一节点上共同托管一个数据存储，使用 SQLite 或 MySQL 作为数据库，简化部署。然而，当使用共同托管的部署模式时，记得要考虑数据库的复制或备份。如果你失去了节点，你可以迅速在另一个节点上运行 SPIRE 服务器，但如果你失去了数据库，你的所有代理和工作负载都需要重新测试以获得新的身份。

![图 6.5: 单个专用的 SPIRE 服务器。](../images/f6-5.jpg)

**避免单点故障**

保持简单有利也有弊。如果只有一台 SPIRE 服务器，而它丢失了，一切都会丢失，需要重建。拥有一个以上的服务器可以提高系统的可用性。仍然会有一个共享的数据存储和安全连接及数据复制。我们将在本章后面讨论这种决定的不同安全影响。

要横向扩展 SPIRE 服务器，请将同一信任域中的所有服务器配置为对同一共享数据存储进行读和写。

数据存储是 SPIRE 服务器保存动态配置信息的地方，如注册条目和身份映射策略。SQLite 与 SPIRE 服务器捆绑在一起，是默认的数据存储。

![图 6.6: 多个 SPIRE 服务器实例在 HA 上运行。](../images/f6-6.jpg)

## 数据存储建模

在进行数据存储设计时，你的首要关注点应该是冗余和高可用性。你需要确定每个 SPIRE 服务器集群是否有一个专用的数据存储，或者是否应该有一个共享的数据存储。

数据库类型的选择可能受到整个系统可用性要求和你的运营团队能力的影响。例如，如果运维团队有支持和扩展 MySQL 的经验，这应该是首要选择。

### 每个集群的专用数据存储

多个数据存储允许系统的每个专用部分更独立。例如，AWS 和 GCP 云中的 SPIRE 集群可能有独立的数据存储，或者 AWS 中的每个 VPC 可能有一个专用数据存储。这种选择的好处是，如果一个地区或云提供商发生故障，在其他地区或云提供商中运行的 SPIRE 部署就不会受到影响。

在发生重大故障时，每个集群的数据存储的缺点变得最为明显。如果一个地区的 SPIRE 数据存储（以及所有的 SPIRE 服务器）发生故障，就需要恢复本地数据存储，或者将代理切换到同一信任域的另一个 SPIRE 服务器集群上，假设信任域是跨区域的。

如果有必要将代理切换到一个新的集群，必须特别考虑，因为新的集群将不知道另一个 SPIRE 集群发出的身份，或该集群包含的注册条目。代理将需要对这个新集群进行重新认证，并且需要通过备份或重建来恢复注册条目。

![图 6.7: 如果你需要将一个集群中的所有代理迁移到另一个集群，会发生什么？](../images/f6-7.jpg)

### 共享的数据存储

拥有一个共享的数据存储可以解决上述拥有单独数据存储的问题。然而，它可能会使设计和操作更加复杂，并依赖其他系统来检测故障，并在发生故障时更新 DNS 记录。此外，该设计仍然需要为每个 SPIRE 可用域、每个区域或数据中心的数据库基础设施的碎片，这取决于具体的基础设施。请查看 [SPIRE 文档](https://github.com/spiffe/spire/blob/master/doc/plugin_server_datastore_sql.md)以了解更多细节。

![图 6.8：使用全局数据存储方案的两个集群。](../images/f6-8.jpg)

## 管理失败

当基础设施发生故障时，主要的问题是如何继续向需要 SVID 才能正常运行的工作负载发放 SVID。SPIRE 代理的 SVID 内存缓存被设计为应对短期宕机的主要防线。

SPIRE 代理定期从 SPIRE 服务器获取授权发布的 SVID，以便在工作负载需要时将其交付给它们。这个过程是在工作负载请求 SVID 之前完成的。

### 性能和可靠性

SVID 缓存有两个优点：性能和可靠性。当工作负载要求获得其 SVID 时，代理不需要请求和等待 SPIRE 服务器提供 SVID，因为它已经有了缓存，这就避免了到 SPIRE 服务器的往返代价。此外，如果 SPIRE 服务器在工作负载请求其 SVID 时不可用，也不会影响 SVID 的发放，因为代理已经将其缓存起来了。

我们需要对 X509-SVID 和 JWT-SVID 进行区分。JWT-SVID 不能提前构建，因为代理不知道工作负载所需的 JWT-SVID 的具体受众，代理只预先缓存 X509-SVID。然而，SPIRE 代理确实维护着已发布的 JWT-SVID 的缓存，只要缓存的 JWT-SVID 仍然有效，它就可以向工作负载发布 JWT-SVID，而无需与 SPIRE 服务器联系。

### 存活时间

SVID 的一个重要属性是其存活时间（TTL）。如果一个 SVID 的剩余寿命小于 TTL 的一半，SPIRE 代理将更新缓存中的 SVID。这向我们表明，SPIRE 在对底层基础设施能够提供 SVID 的信心方面是保守的。它还提供了一个暗示，即 SVID TTL 在抵御中断方面的作用。较长的 TTL 可以提供更多的时间来修复和恢复任何基础设施的中断，但是在选择 TTL 的时候，需要在安全性和可用性之间做出妥协。长的 TTL 将提供充足的时间来修复故障，但代价是在较长的时间内暴露 SVID（及相关密钥）。较短的 TTL 可以减少恶意行为者利用被破坏的 SVID 的时间窗口，但需要更快地对故障作出反应。不幸的是，没有什么 "神奇" 的 TTL 可以成为所有部署的最佳选择。在选择 TTL 时，必须考虑在必须解决中断问题的时间窗口和已发布的 SVID 的可接受曝光度之间，你愿意接受什么样的权衡。

## Kubernetes 中的 SPIRE

本节介绍了在 Kubernetes 中运行 SPIRE 的细节。Kubernetes 是一个容器编排器，可以在许多不同的云供应商上管理软件部署和可用性，也可以在物理硬件上管理。SPIRE 包括几种不同形式的 Kubernetes 集成。

### Kubernetes 中的 SPIRE 代理

Kubernetes 包括 DaemonSet 的概念，这是一个自动部署在所有节点上的容器，每个节点有一个副本运行。这是运行 SPIRE 代理的一种完美方式，因为每个节点必须有一个代理。

随着新的 Kubernetes 节点上线，调度器将自动轮换 SPIRE 代理的新副本。首先，每个代理需要一份引导信任包的副本。最简单的方法是通过 Kubernetes ConfigMap 来分发。

一旦代理拥有启动信任包，它就必须向服务器证明自己的身份。Kubernetes 提供两种类型的认证令牌：

1. 服务账户令牌（SAT）
2. 预计服务账户令牌（PSAT）

服务账户令牌的安全性并不理想，因为它们永远有效，而且范围无限。预测的服务账户令牌要安全得多，但它们确实需要最新版本的 Kubernetes 和一个特殊的功能标志才能启用。SPIRE 支持用于节点证明的 SAT 和 PSAT。

### Kubernetes 中的 SPIRE 服务器

SPIRE 服务器以两种方式与 Kubernetes 交互。首先，每当它的信任包发生变化时，它必须将信任包发布到 Kubernetes ConfigMap。其次，当代理上线时，它必须使用 `TokenReview` API 验证其 SAT 或 PSAT 令牌。这两者都是通过 SPIRE 插件配置的，需要相关的 Kubernetes API 权限。

SPIRE 服务器可以完全在 Kubernetes 中运行，与工作负载一起。然而，为了安全起见，最好是在一个单独的 Kubernetes 集群上运行，或独立的硬件。这样一来，如果主集群被破坏，SPIRE 的私钥就不会有风险。

![图 6.9：SPIRE 服务器与工作负载在同一集群上。](../images/f6-9.jpg)

![图 6.10：为了安全起见，SPIRE 服务器在一个单独的集群上。](../images/f6-10.jpg)

### Kubernetes 工作负载证明

SPIRE 代理包括一个 Kubernetes 工作负载验证器插件。该插件首先使用系统调用来识别工作负载的 PID。然后，它使用对 Kubelet 的本地调用来识别工作负载的 pod 名称、镜像和其他特征。这些特征可以作为注册条目的选择器。

### Kubernetes 负载条目自动注册

一个名为 Kubernetes Workload Registrar 的 SPIRE 扩展可以自动创建节点和工作负载注册条目，充当 Kubernetes API 服务器和 SPIRE 服务器之间的桥梁。它支持几种不同的方法来识别正在运行的 pod，并在创建条目方面具有一定的灵活性。

### 增加 Sidecar

对于尚未适应使用工作负载 API 的工作负载（见第 7 章：与其他机构的集成中的本地 SPIFFE 支持一节），Kubernetes 可以很容易地添加支持的 sidecar。Sidecar 可以是一个 SPIFFE 感知的代理，比如 Envoy。或者，它可以是一个与 SPIRE 一起开发的 sidecar，名为“SPIFFE Helper"，它监控工作负载 API，并在其 SVID 发生变化时重新配置工作负载。

![图 6.11：与 sidecar 容器一起部署的 Kubernetes 集群中的工作负载。](../images/f6-11.jpg)

## SPIRE 的性能考虑因素

当连接到服务器的 SPIRE 代理数量增加时，也会给服务器、数据存储和网络本身带来更多的负荷。多个因素都会造成负载，包括节点数量和每个节点的工作负载，以及你轮换秘钥的频率。使用 JWT-SVID 与嵌套的 SPIRE 模型，公钥需要保持同步，这将增加代理和服务器之间需要传输的信息量。

我们不想对每个代理的工作负载数量或每个服务器的代理数量提出具体的性能要求或建议，因为所有的数据 a）取决于硬件和网络特性，b）变化很快。仅举一例，最新的一个版本将数据的性能提高了 30%。

正如你在前几章中所了解的，SPIRE 代理不断与服务器进行通信，以获得任何新的变化，如新工作负载的 SVID 或信任包的更新。在每次同步过程中，会有多个数据存储操作。默认情况下，同步时间为 5 秒，如果这对你的系统产生了太多的压力，你可以把它增加到一个更高的值来解决这些问题。

非常短的 SVID TTL 可以减轻安全风险，但如果你使用非常短的 TTL，要准备好看到你的 SPIRE 服务器的额外负载，因为签名操作的数量与轮换频率成比例增加。

另一个影响系统性能的关键因素可能是每个节点的工作负载数量。如果你在系统中的所有节点上增加一个新的工作负载，这将突然产生一个峰值，并对整个系统产生负荷。

如果您的系统严重依赖 JWT-SVID 的使用，请记住，JWT-SVID 不是在代理端预先生成的，需要按要求进行签名。这可能会给 SPIRE 服务器和代理带来额外的负载，并在它们过载时增加延迟。

## 验证器插件

SPIRE 为节点和工作负载认证提供了各种验证器插件。选择使用哪种验证器插件取决于对认证的要求，以及底层基础设施 / 平台提供的可用支持。

对于工作负载证明，这主要取决于被编排的工作负载的类型。例如，当使用 Kubernetes 集群时，Kubernetes 工作负载验证器将是合适的，同样，OpenStack 平台的 OpenStack 验证器也是如此。

对于节点认证来说，确定安全和合规的要求是很重要的。有时需要执行工作负载的地理围栏。在这些情况下，使用来自云提供商的节点验证器，可以断言，将提供这些保证。

在高度管制的行业，可能需要使用基于硬件的认证。这些机制通常依赖于底层基础设施提供支持，如 API 或像可信平台模块（TPM）的硬件模块。这可能包括对系统软件状态的测量，包括固件、内核版本、内核模块，甚至文件系统的内容。

**为不同的云平台设计证明**

在云环境中工作时，根据云提供商提供的元数据验证您的节点身份被认为是一种最佳做法。SPIRE 提供了一种简单的方法，通过专门为您的云设计的自定义节点验证器来实现这一点。大多数云提供商分配了一个 API，可以用来识别 API 调用者。

![图 6.12：节点验证器的结构和流程。](../images/f6-12.jpg)

节点验证器和解析器可用于亚马逊网络服务（AWS）、Azure 和谷歌云平台（GCP）。云环境的节点验证器是特定于该云的。验证器的目的是在向运行在该节点上的 SPIRE 代理发布身份信息之前对节点进行验证。

一旦建立了一个身份，SPIRE 服务器可能会安装一个 Resolver 插件，允许创建额外的选择器，与节点的元数据相匹配。可用的元数据是针对云的。

在相反的范围内，如果云提供商不提供验明节点的能力，就有可能用加入令牌进行引导。然而，这提供了一套非常有限的保证，这取决于通过什么程序完成。

## 注册条目的管理

SPIRE 服务器支持两种不同的方式来添加注册条目：通过命令行界面或注册 API（只允许管理员访问）。SPIRE 需要注册条目来运作。一种选择是由管理员手动创建。

![图 6.13: 工作负载手动登记。](../images/f6-13.jpg)

在大型部署或基础设施快速增长的情况下，手动流程将无法扩展。此外，任何手动程序都容易出错，而且可能无法跟踪所有的变化。

对于有大量注册条目的部署来说，使用自动流程来创建注册条目是一个更好的选择。

![图 6.14: 使用与工作负载协调器通信的 "身份运营商" 自动创建工作负载注册条目的例子。](../images/f6-14.jpg)

## 将安全考虑因素和威胁建模考虑在内

无论你做出什么样的设计和架构决定，都会影响到整个系统的威胁模型，也可能影响到与之互动的其他系统。

下面是一些重要的安全考虑因素和你在设计阶段应该考虑的安全问题。

### 公钥基础设施（PKI）设计

你的 PKI 的结构是什么，你如何定义你的信任域以建立安全边界，你把你的私钥放在哪里，以及它们多久轮换一次，这些都是你在这一点上需要问自己的关键问题。

![图 6.15: 一个具有三个信任域的 SPIRE 部署示例，每个信任域使用不同的企业证书颁发机构，每个证书颁发机构使用相同的根证书颁发机构。在每一层中，证书的 TTL 较短。](../images/f6-15.jpg)

每个组织都会有不同的证书层次，因为每个组织有不同的要求。上图代表了一个潜在的证书层次结构。

**TTL、撤销和更新**

在处理 PKI 时，围绕证书到期、重新签发和撤销的问题总是浮出水面。有几个考虑因素可以影响这里的决定。这些因素包括：

- **文件过期 / 重新发行的性能开销**：可以容忍多少性能开销。TTL 越短，性能开销越大。
- **递送文件的延迟**：TTL 必须长于身份文件的预期递送延迟，以确保服务在验证自己时不会出现空档。
- **PKI 生态系统的成熟度**：是否有撤销机制？它们是否得到维护并保持更新？
- **组织的风险偏好**：如果不启用撤销功能，如果身份被破坏并被发现，可接受的有效时间是多少。
- **对象的预期寿命**：根据对象的预期寿命，TTL 不应该被设置为太长的时间。

**爆炸半径**

在 PKI 设计阶段，考虑其中一个组件的破坏会如何影响基础设施的其他部分是非常重要的。例如，如果你的 SPIRE 服务器将密钥保存在内存中，而服务器被攻破，那么所有下游的 SVID 都需要被取消并重新发行。为了尽量减少这种攻击的影响，你可以设计 SPIRE 基础设施，为不同的网段、虚拟私有云或云供应商提供多个信任域。

**保存你的私人钥匙的秘密**

重要的是你把你的钥匙放在哪里。正如你先前可能已经了解到的，SPIRE 有一个密钥管理器的概念，它管理 CA 密钥。如果你打算把 SPIRE 服务器作为你的 PKI 的根，你可能想让你的根密钥具有持久性，但把它存储在磁盘上并不是一个好主意。

存储 SPIRE 密钥的解决方案可能是一个软件或硬件密钥管理服务（KMS）。有独立的产品可以作为 KMS，也有每个主要云供应商的内置服务。

将 SPIRE 与现有 PKI 集成的另一种可能的设计策略是使用 SPIRE 上游授权插件接口。在这种情况下，SPIRE 服务器通过使用支持的插件之一与现有的 PKI 进行通信来签署其中间 CA 证书。

### SPIRE 数据存储的安全考虑

我们有意将 SPIRE 服务器的数据存储从第四章的威胁模型中删除。数据存储是 SPIRE 服务器保存动态配置的地方，如从 SPIRE 服务器 API 检索的注册条目和身份映射策略。SPIRE 服务器数据存储支持不同的数据库系统，它可以作为数据存储使用。数据存储的妥协将允许攻击者在任何节点上注册工作负载，并可能是节点本身。攻击者还将能够将密钥添加到信任捆绑中，并进入下游基础设施的信任链。

攻击者的另一个可能的表面是对数据库或 SPIRE 服务器连接到数据库的拒绝服务攻击，这将导致对其他基础设施的拒绝服务。

当你考虑为生产中的 SPIRE 服务器基础设施设计任何数据库时，你不可能使用数据库进程与服务器共存于同一主机的模式。尽管对数据库的有限访问，以及与服务器共存的模式大大限制了攻击面，但它很难在生产环境中扩展。

![图 6.16：出于可用性和性能的考虑，SPIRE 服务器数据存储通常通过网络连接远程运行，但这带来了安全挑战。](../images/f6-16.jpg)

出于可用性和性能的考虑，SPIRE 数据存储通常会是一个网络连接的数据库。但你应该考虑以下问题：

- 如果这是一个与其他服务共享的数据库，还有谁可以访问它和管理它？
- SPIRE 服务器将如何对数据库进行认证？
- 数据库连接是否允许 TLS 保护的安全通信？

这些都是需要考虑的相关问题，因为 SPIRE 服务器如何连接到数据库在很大程度上决定了整个部署的安全程度。在使用 TLS 和基于密码的认证的情况下，SPIRE 服务器的部署应依靠秘密管理器或 KMS 来保证数据安全。

在某些部署中，您可能需要添加另一个较低级别的**元 PKI** 基础设施，使你能够确保与 SPIRE 服务器的所有低级别的依赖性的通信，包括您的配置管理或部署软件。

### SPIRE 代理配置和信任包

你分配和部署 SPIRE 生态系统组件的方式，以及它在你的环境中的配置可能会对你的威胁模型和整个系统的安全模型产生严重的影响。这不仅是 SPIRE 的低级依赖，也是你所有安全系统的低级依赖，所以这里我们只关注 SPIFFE 和 SPIRE 特有的东西。

**信任包**

有不同的方法来交付代理的**引导信任包（bootstrap trust bundle）**。这是代理在最初启动时使用的信任包，以便对 SPIRE 服务器进行验证。如果攻击者能够将密钥添加到初始信任包中并进行中间人攻击，那么它将对工作负载进行同样的攻击，因为它们从受害代理那里接收 SVID 和信任包。

**配置**

SPIRE 代理的配置也需要保持安全。如果攻击者可以修改这个配置文件，那么他们可以将其指向被攻击的 SPIRE 服务器并控制代理。

### 节点验证器插件的影响

通过多个独立的机制来证明信任，可以提供更大的信任断言。你选择的节点证明可能会大大影响你的 SPIRE 部署的安全性，并将它的信任根基转向另一个系统。当决定使用什么类型的证明时，你应该把它纳入你的威胁模型，并在每次发生变化时审查该模型。

例如，任何其他基于占有证明的证明都会转移信任的根基，所以你要确保你作为下级依赖的系统符合你的组织的安全和可用性标准。

当设计一个使用加入令牌的证明模式的系统时，仔细评估添加和使用令牌的操作程序，无论是由操作者还是供应系统。

### 遥测和健康检查

SPIRE 服务器和代理都支持健康检查和不同类型的遥测。启用或错误配置健康检查和遥测可能会增加 SPIRE 基础设施的攻击面，这一点可能并不明显。SPIFFE 和 SPIRE 威胁模型假设代理只通过本地 Unix 套接字暴露工作负载 API 接口。该模型没有考虑到错误配置（或有意配置）的健康检查服务监听不在本地主机上，可能会使代理暴露于潜在的攻击，如 DoS、RCE 和内存泄漏。在选择遥测集成模型时，最好采取类似的预防措施，因为一些遥测插件（如 Prometheus）可能会暴露出额外的端口。
