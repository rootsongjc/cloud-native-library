---
weight: 4
title: 1.1 范围
date: '2022-05-18T00:00:00+08:00'
type: book
---

从理论上讲，DevSecOps 原语可以应用于许多应用架构，但最适合于基于微服务的架构，由于应用是由相对较小的、松散耦合的模块组成的，被称为微服务，因此允许采用敏捷开发模式。即使在基于微服务的架构中，DevSecOps 原语的实现也可以采取不同的形式，这取决于平台。在本文中，所选择的平台是一个容器编排和资源管理平台（如 Kubernetes）。该平台是物理（裸机）或虚拟化（如虚拟机、容器）基础设施上的一个抽象层。为了在本文中明确提及该平台或应用环境，它被称为 **DevSecOps 原语参考平台**，或简称为 **参考平台**。

在描述参考平台的 DevSecOps 原语的实现之前，我们假设在部署服务网格组件方面采用了以下 [尽职调查](https://www.oreilly.com/library/view/cloud-native-infrastructure/9781491984291/)：

-   用于部署和管理基于服务网格的基础设施（如网络路由）、策略执行和监控组件的安全设计模式
-   测试证明这些服务网格组件在应用的各个方面（如入口、出口和内部服务）的各种情况下都能按预期工作。

为参考平台实施 DevSecOps 原语所提供的指导与 (a) DevSecOps 管道中使用的工具和 (b) 提供应用服务的服务网格软件无关，尽管来自 Istio 等服务网格产品的例子被用来将它们与现实世界的应用工件（如容器、策略执行模块等）联系起来。

以下是对参考平台所呈现的整个应用环境中的代码类型（在执行摘要中提到）的稍微详细的描述。请注意，这些代码类型包括那些支持实施 DevSecOps 原语的代码。

1.  应用代码：体现了执行一个或多个业务功能的应用逻辑，由描述业务事务和数据库访问的代码组成。
2.  应用服务代码（如服务网格代码）：为应用提供各种服务，如服务发现、建立网络路由、网络弹性服务（如负载均衡、重试），以及安全服务（如根据策略强制执行认证、授权等，见第 4 章）。
3.  基础设施即代码：以声明性代码的形式表达运行应用程序所需的计算、网络和存储资源。
4.  策略即代码：包含声明性代码，用于生成实现安全目标的规则和配置参数，例如在运行期间通过安全控制（如认证、授权）实现零信任。
5.  可观测性即代码：触发与日志（记录所有事务）和追踪（执行应用程序请求所涉及的通信途径）以及监控（在运行期间跟踪应用程序状态）有关的软件。

代码类型 3、4 和 5 可能与代码类型 2 有重叠。

本文件涵盖了与上述所有五种代码类型相关的管道或工作流程的实施。因此，整个应用环境（不仅仅是应用代码）受益于应用代码的所有最佳实践（例如，敏捷迭代开发、版本控制、治理等）。基础设施即代码、策略即代码和可观测性即代码属于一个特殊的类别，称为声明性代码。当使用“xx 即代码”的技术时，编写的代码（例如，用于配置资源的代码）被管理，类似于应用源代码。这意味着它是有版本的，有文件的，并且有类似于应用源代码库的访问控制定义。通常，使用特定领域的声明性语言：声明需求，并由相关工具将其转换为构成运行时实例的工件。例如，在基础设施即代码（IaC）的情况下，声明性语言将基础设施建模为一系列的资源。相关的配置管理工具将这些资源集中起来，并生成所谓的 **清单**，定义与所定义的资源相关的平台（运行时实例）的最终状态。这些清单存储在与配置管理工具相关的服务器中，并由该工具用于为指定平台上的运行时实例创建编译的配置指令。清单通常以平台中立的表示方式（如 JSON）进行编码，并通过 REST API 反馈给平台资源配置代理。