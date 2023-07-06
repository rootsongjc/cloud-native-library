---
title: 如何利用 OpenTelemetry 监控和优化 Kubernetes 的性能
summary: "本文介绍了如何将 OpenTelemetry 与 Kubernetes 配合使用。OpenTelemetry 可以作为 Prometheus 的替代品，也可以将数据导出到各种后端，包括 Prometheus。OpenTelemetry Operator 负责部署和管理 OpenTelemetry Collector，该组件是收集、处理和导出遥测数据的中央组件。OpenTelemetry 日志提供了一种标准化的方式来收集、处理和分析分布式系统中的日志。此外，本文还介绍了 OpenTelemetry 的下一步计划，包括 Web 服务器的自动化仪器化、OpenTelemetry Profile 和 Open Agent Management Protocol。"
date: '2023-05-09T16:00:00+08:00'
draft: false
authors: ["Robert Kimani"]
tags: ["可观测性","Kubernetes","OpenTelemetry"]
categories: ["可观测性"]
links:
  - icon: language
    icon_pack: fa
    name: 阅读英文版原文
    url: https://thenewstack.io/how-opentelemetry-works-with-kubernetes/
---

> 摘要：本文译自 [How OpenTelemetry Works with Kubernetes](https://thenewstack.io/how-opentelemetry-works-with-kubernetes)。本文介绍了如何将 OpenTelemetry 与 Kubernetes 配合使用。OpenTelemetry 可以作为 Prometheus 的替代品，也可以将数据导出到各种后端，包括 Prometheus。OpenTelemetry Operator 负责部署和管理 OpenTelemetry Collector，该组件是收集、处理和导出遥测数据的中央组件。OpenTelemetry 日志提供了一种标准化的方式来收集、处理和分析分布式系统中的日志。此外，本文还介绍了 OpenTelemetry 的下一步计划，包括 Web 服务器的自动化仪器化、OpenTelemetry Profile 和 Open Agent Management Protocol。

OpenTelemetry 的主要目标是提供一种标准的方式，使开发人员和最终用户能够从他们的应用程序和系统中创建、收集和导出遥测数据，并促进不同可观察性工具和平台之间的互操作性。

OTEL 支持多种编程语言，包括 [Java](https://thenewstack.io/getting-started-with-opentelemetry-for-java/)、[Python](https://thenewstack.io/an-introduction-to-python-a-language-for-the-ages/)、[Go](https://thenewstack.io/opentelemetry-in-go-its-all-about-context/)、[Ruby](https://thenewstack.io/why-were-sticking-with-ruby-on-rails-at-gitlab/) 等，因此可以从不同类型的应用程序和系统中收集遥测数据，是一种多用途的解决方案。

一旦 OpenTelemetry 组件收集到遥测数据，就可以将其导出到各种后端，如软件即服务解决方案、平台或存储系统，提供存储和查询功能。OpenTelemetry 提供与各种后端的集成，包括 [Prometheus](https://prometheus.io/)、Jaeger、[Zipkin](https://zipkin.io/) 等，使导出遥测数据到不同系统变得更加容易。

在 Kubernetes 中使用 OTEL 并不困难。实际上，安装 [Kubernetes](https://thenewstack.io/kubernetes/) 的 OTEL Operator 是一个简单的过程，在本文中，您将学习如何执行此操作。

通过此 Operator，您可以轻松地管理 Kubernetes 集群中的 OpenTelemetry 组件，并将其配置为导出遥测数据到您选择的后端。这简化了监视 Kubernetes 集群的过程，并使您能够对应用程序的健康和性能做出明智的决策。

## OpenTelemetry 的基本组件

前四个组件用于仪器开发人员或可观察性公司创建可观察性产品。

### 规范

规范提供了定义这些组件的行为和功能的标准化方式，确保在不同的 OpenTelemetry 实现之间保持一致性和兼容性。例如，规范定义了跟踪和指标数据的格式和语义，确保它们可以被系统中的其他组件正确解释。

### API

OpenTelemetry API 为开发人员提供了一种标准的方式来使用跟踪、指标和其他遥测数据对其应用程序进行仪器化。该 API 是语言不可知的，并允许在不同的编程语言和框架之间进行一致的仪器化。

API 为开发人员提供了一种标准的方式来使用跟踪和指标对其应用程序进行仪器化。

### SDK

OpenTelemetry SDK 提供了 OpenTelemetry API 的语言特定实现。SDK 通过提供用于收集和导出遥测数据的库和实用程序，使开发人员更轻松地对其应用程序进行仪器化。

### 数据模型 - OTLP

OpenTelemetry 数据模型提供了一种用于遥测数据的标准化格式，称为 OTLP（OpenTelemetry 协议）。OTLP 是一种供应商中立的格式，使将遥测数据导出到不同的后端和分析工具变得更加容易。

最后两个组件，OpenTelemetry 自动仪器化和收集器，适用于希望从其应用程序收集和导出遥测数据到不同后端的开发人员，而无需编写自己的仪器化代码。

### 自动仪器化

OpenTelemetry 包括一个自动仪器化代理，可以注入具有跟踪和指标的应用程序，而无需任何手动仪器化代码。这使得可以向现有应用程序添加可观察性，而无需进行重大代码更改。

自动仪器化组件可以下载并安装为库或代理，具体取决于使用的编程语言或框架。自动仪器化库会自动将应用程序代码注入 OpenTelemetry API 调用，以捕获和导出遥测数据。

### 收集器

收集器组件负责从不同来源（如应用程序、服务器和基础架构组件）收集遥测数据，并将其导出到各种后端。

收集器可以下载并配置以从不同来源收集数据，并可以执行聚合、采样和其他操作，以在导出到不同后端之前对遥测数据执行处理，具体取决于特定用例。

## Telemetry 数据是如何创建的

我们以一个包含三个工作负载的电子商务应用程序为例——前端、驱动程序和客户端——它们通过 HTTP 相互通信。我们想要收集遥测数据以监视这些应用程序的性能和健康状况。

为此，我们使用 OpenTelemetry API 为每个应用程序实现仪表化：`logger.log()`、`meter.record()` 和 `tracer.span().start()`。这些 API 允许我们创建遥测信号，例如日志、度量和跟踪。

创建这些信号后，它们被发送或者由 OpenTelemetry 收集器收集，后者充当集中式数据中心。

收集器负责处理这些信号，其中包括批处理、重新标记、PII 过滤、数据丢弃和聚合等任务，以确保数据准确和有意义。一旦收集器对数据满意，它就将遥测信号发送到平台进行存储和分析。

收集器可以配置为将这些处理后的信号发送到各种平台，例如 Prometheus、[Loki](https://github.com/grafana/loki)、Jaeger 或供应商，例如 [Dynatrace](https://www.dynatrace.com/)、New Relic 等。

例如，收集器可以将日志发送到类似 Loki 的日志聚合平台、将指标发送到类似 Prometheus 的监控平台、将跟踪发送到类似 Jaeger 的分布式跟踪平台。平台中存储的遥测数据可以用于深入了解系统的行为和性能，并识别需要解决的任何问题。

## 定义 Kubernetes Operator 的行为

您可以将 OpenTelemetry Operator 部署到 Kubernetes 集群中，并使其自动为应用程序仪表化和收集遥测数据。

[OpenTelemetry Kubernetes Operator](https://opentelemetry.io/docs/k8s-operator/) 提供了两个自定义资源定义（CRD），用于定义 Operator 的行为。这两个 CRD 共同允许您为应用程序定义 OpenTelemetry Operator 的完整行为。

这两个 CRD 是：

**`otelinst`** ：此 CRD 用于定义应用程序的仪表化。它指定要使用 OpenTelemetry API 的哪些组件、要收集哪些数据以及如何将该数据导出到后端。

使用 otelinst CRD，您可以指定要仪表化的应用程序的名称、语言和运行时环境、跟踪的采样率以及要使用的导出器类型。

**`otelcol`**：此 CRD 用于定义 OpenTelemetry 收集器的行为。它指定收集器的配置，包括接收器（遥测数据源）、处理器（用于过滤和转换数据）和导出器（用于将数据发送到后端）。

使用 otelcol CRD，您可以指定要用于通信的协议，例如 Google 远程过程调用（gRPC）或 HTTP，要使用哪些接收器和导出器，以及任何其他配置选项。

## 安装 OpenTelemetry Kubernetes Operator

OpenTelemetry Kubernetes Operator 可以使用各种方法安装，包括：

- Operator 生命周期管理器 (OLM)。这是[推荐的方法](https://olm.operatorframework.io/docs/tasks/install-operator-with-olm/)，因为它提供了方便的安装、升级和管理 Operator 的方法。
- Helm charts。Helm 是 Kubernetes 的软件包管理器，提供了一种在 Kubernetes 上部署和管理应用程序的简单方法。OpenTelemetry operator 的 Helm charts [可用](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-operator)，可用于部署 Operator。
- Kubernetes 清单。Operator 也可以使用 Kubernetes 清单进行安装，后者提供了一种声明性的方式来管理 Kubernetes 资源。Operator 清单可以根据特定要求进行定制。

要收集遥测数据，我们需要使用创建遥测信号的代码仪表化我们的应用程序。有不同的方法来为遥测数据仪表化应用程序。

### 显式/手动方法

在此方法中，开发人员明确向其应用程序添加仪表化代码，以创建日志、度量和跟踪等遥测信号。这种方法使开发人员对遥测数据更具控制力，但可能耗时且容易出错。

### 直接集成在运行时

某些运行时，例如 [Quarkus](https://quarkus.io/) 和 [WildFly](https://www.wildfly.org/) 框架，直接与 OpenTelemetry 集成。这意味着开发人员无需向其应用程序添加仪表化代码，运行时会自动为他们生成遥测数据。这种方法可能更易于使用，要求更少的维护工作，但比显式/手动方法灵活性可能较差。

直接集成在运行时的主要缺点是，仪表化仅限于支持的框架。如果应用程序使用不受支持的框架，则可能无法有效捕获遥测数据或需要额外的自定义仪表化。

如果所选运行时或框架仅与特定的可观察性供应商兼容，则此方法还可能导致供应商锁定。

因此，此方法可能不适用于所有应用程序或组织，特别是如果他们需要在选择可观察性堆栈或需要仪器化各种框架和库时具有灵活性。

### 自动仪表化/代理方法

在此方法中，向应用程序运行时添加 OpenTelemetry 代理或自动仪表化库。代理/库自动为应用程序代码创建仪表化并生成遥测数据，而无需开发人员添加仪表化代码。

这种方法可能是最易于使用的，需要最少的维护工作，但可能不太灵活，并且可能无法捕获所有相关的遥测数据。

虽然自动仪表化/代理方法具有许多优点，但主要缺点之一是它可能消耗更多的内存和 CPU 周期，因为它支持广泛的框架并为应用程序中几乎所有 API 进行仪表化。这种附加开销可能会影响应用程序的性能，尤其是如果应用程序已经消耗了资源。

此外，此方法可能无法捕获所有必要的遥测数据，或可能会导致错误的正面或负面结果。例如，它可能无法捕获某些边缘情况，或者可能捕获过多的数据，使查找相关信息变得困难。

但是，尽管存在这些缺点，自动仪表化/代理方法仍然强烈推荐给刚开始使用观察性的组织，因为它提供了一种快速且简单的方法来快速收集遥测数据。

## 传送遥测数据的收集和导出

收集器负责接收来自仪器代码的遥测数据，处理并将其导出到平台进行存储和分析。收集器可以配置各种组件，例如接收器、处理器和导出器，以满足特定需求。

接收器负责从各种来源（例如代理、导出器或网络）接受数据，而处理器则可以转换、过滤或增强数据。最后，导出器将数据发送到存储或分析平台，例如 Prometheus 或 Jaeger。

收集器有两个版本，Core 和 Contrib。

[Core](https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol) 是官方版本，包含稳定和经过充分测试的组件，而 [Contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib) 是社区驱动版本，包含额外的实验性[组件](https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib)。

您还可以通过选择所需的组件并根据您的要求进行配置来构建自己的收集器。收集器用 Go 编写，这使得它易于部署和维护。[OpenTelemetry 网站上的文档](https://opentelemetry.io/docs/collector/)提供了详细的指南，介绍如何设置、配置和使用收集器。

在某些情况下，OpenTelemetry 可以作为 Prometheus 的替代品，特别是在边缘设备上资源有限的情况下。Prometheus 更加专注于监控和警报，而 OpenTelemetry 则专为可观察性而设计，并提供超出指标以外的功能，包括跟踪和日志记录。

此外，OpenTelemetry 可以用于将数据导出到各种后端，包括 Prometheus，因此如果您愿意，仍然可以使用 Prometheus 进行监控和警报。OpenTelemetry 的灵活性和可扩展性使您可以将可观察性解决方案定制为符合您的特定需求和资源限制。

OpenTelemetry Operator 负责部署和管理 OpenTelemetry Collector，该组件是收集、处理和导出遥测数据的中央组件。它不部署其他边车，例如 Envoy，但可以与它们一起工作以收集额外的遥测数据。

OpenTelemetry Collector 可以以不同的模式部署，例如边车、daemonset、deployment 或 statefulset，具体取决于特定用例和要求。

但是，如果目标是从群集中的节点收集日志，则将收集器部署为 daemonset 可以是一个不错的选择，因为它确保在每个节点上运行一个收集器实例，从而实现高效且可靠的日志收集。

### OTEL 收集器配置

以下是使用 otelcol 自定义资源定义部署 OpenTelemetry 收集器的 Kubernetes 清单文件示例：

在此示例中，我们定义了一个名为 `otel-collector` 的收集器，它使用 OTLP 接收器接收跟踪数据，使用 Prometheus 导出器将指标导出到 Prometheus 服务器，并使用两个处理器（`batch` 和 `queued_retry`）处理数据。config 字段指定收集器的配置，其格式为 YAML。

使用 OpenTelemetry 收集跟踪、指标和日志在几个方面都很重要：

- **增加可观察性。** 通过收集和关联跟踪、指标和日志，您可以更好地了解应用程序和系统的性能。增强的可观察性使您能够在影响用户之前快速识别和解决问题。
- **改进故障排除。** OpenTelemetry 提供了一种收集遥测数据的标准化方式，这使得在整个堆栈中进行故障排除变得更加容易。通过在单个位置访问所有相关遥测数据，您可以快速找到问题的根本原因。
- **更好的性能优化。** 有了详细的遥测数据，您可以做出有关如何优化应用程序和系统以实现更好的性能和可靠性的明智决策。例如，通过分析指标，您可以确定系统中未利用或过度利用的区域，并相应地调整资源分配。
- **跨平台兼容性。** OpenTelemetry 设计用于跨多种编程语言、框架和平台工作，这使得从堆栈的不同部分收集遥测数据变得更加容易。这种互操作性对于使用多种技术并需要在整个堆栈中标准化可观察性实践的组织非常重要。

### OpenTelemetry 日志

OpenTelemetry 日志提供了一种标准化的方式来收集、处理和分析分布式系统中的日志。通过使用 OpenTelemetry 收集日志，开发人员可以避免日志分布在多个系统和不同格式的问题，从而难以分析和排除问题。

使用 OpenTelemetry 日志，开发人员可以从多个来源收集日志，包括传统的日志库，然后使用通用格式和 API 处理和分析它们。这允许更好地与可观察性堆栈的其他部分（例如指标和跟踪）集成，并提供更完整的系统行为视图。

此外，OpenTelemetry 日志提供了一种将日志与其他上下文信息（例如有关请求、用户或环境的元数据）进行丰富的方法，这些信息可以用于使日志分析更有意义和有效。

## OpenTelemetry 的下一步是什么？

### Web 服务器的自动化仪器化

OTEL [webserver](https://github.com/open-telemetry/opentelemetry-cpp-contrib/tree/main/instrumentation/otel-webserver-module#otel-webserver-module) 模块包括 Apache 和 [Nginx](https://www.nginx.com/?utm_content=inline-mention) 仪器化。Apache 模块负责在运行时将仪器化注入到 Apache 服务器中，以跟踪传入请求到服务器。它捕获参与传入请求的许多模块的响应时间，包括 mod_proxy。这使得可以捕获每个模块的分层时间消耗。

类似地，Nginx web 服务器模块也可以通过在运行时将仪器化注入到 Nginx 服务器中来跟踪传入请求到服务器。它捕获涉及请求处理的各个模块的响应时间。

### OpenTelemetry Profile

此 [文档](https://github.com/open-telemetry/oteps/blob/main/text/profiles/0212-profiling-vision.md) 概述了 OpenTelemetry 项目中的分析支持的长期愿景。该计划是 OpenTelemetry 社区成员之间的讨论和协作的结果，代表了各种行业和专业知识的多元化。

该文档旨在指导 OpenTelemetry 中的分析支持开发，但并非要求清单。预计随着学习和反馈的增加，该愿景将随时间演化和完善。

### Open Agent Management Protocol

Open Agent Management Protocol (OpAMP) 是一种网络协议，可实现对大型数据收集代理群集的远程管理。它允许代理报告其状态并从服务器接收配置，并从服务器接收代理安装包更新。

[OpAMP](https://github.com/open-telemetry/opamp-spec) 是供应商无关的，因此服务器可以远程监视和管理实现 OpAMP 的不同供应商的代理群集，包括来自不同供应商的混合代理群集。

它支持代理的远程配置、状态报告、代理自身的遥测报告、可下载特定于代理的软件包的管理、安全自动更新功能和连接凭据管理。此功能允许管理大型混合代理群集的单个窗口视图。
