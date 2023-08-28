---
title: "配置的数据流"
weight: 6
description: "配置在 TSB 中的数据流。"
---

Tetrate Service Bridge (TSB) 采用结构化数据流机制来确保配置更改和更新在整个服务网格基础设施中高效、准确地传播。这个复杂的过程涉及各种组件，包括管理平面、全局控制平面（XCP Central）和本地控制平面（XCP Edge），每个组件在配置生命周期中都发挥着关键作用。

![Simplified data flow from user input through TSB, XCP, to local control planes.](../../assets/concepts/tsb-data-flow.svg)

## 管理平面

TSB 中的所有配置更改均源自管理平面。用户通过各种接口与 TSB 配置交互，例如 gRPC API、TSB UI 和 `tctl` 命令行界面。配置更改随后会保存在数据库中，作为整个系统的事实来源。管理平面将这些更改推送到 XCP Central 以便进一步分发。

{{<callout note "MPC 组件">}}

由于遗留原因，XCP Central 通过 Kubernetes CRD 接收其配置。名为“MPC”的 shim 服务器建立到 TSB 的 API 服务器的 gRPC 流，以接收配置并将相应的 CR 推送到托管 XCP Central 的 Kubernetes 集群中。 MPC 还会从 XCP Central 向 TSB 发送系统运行时状态的报告，以帮助用户管理网格。

即将发布的 TSB 版本将删除该组件，TSB 的 API Server 和 XCP Central 将直接通过 gRPC 进行通信。

{{</callout>}}

## 全局控制平面 - XCP Central

XCP Central 充当应用程序集群中管理平面和本地控制平面之间的中介。它处理运行时配置、服务发现信息和管理元数据的分发。这种通信通过 gRPC 流进行，从而实现 XCP Central 和 XCP Edge 实例之间的双向交互。 XCP Central 发送新的用户配置，而 XCP Edge 报告服务发现更改和管理数据。 XCP Central 还将其本地状态的快照存储为其运行的集群中的 Kubernetes 自定义资源 (CR)。

{{<callout note "XCP Central Data Store">}}

如今，XCP Central 将其本地状态的快照作为 Kubernetes CR 存储在其部署的集群中。当 XCP Central 无法连接到管理平面并且 XCP Central 本身需要重新启动（即无法使用内存缓存）时，将使用此方法。

在未来版本中，当 XCP Central 通过 gRPC 直接从 TSB 接收其配置时，XCP Central 会将其配置保存在类似于管理平面的数据库中。

{{</callout>}}

## 本地控制平面 - XCP Edge

XCP Edge 负责将从 XCP Central 接收到的配置转换为特定于本地集群的本机 Istio 对象。它将这些配置发布到 Kubernetes API 服务器中，Istio 在其中照常处理它们。 XCP Edge 还管理跨网格的服务公开，有助于跨集群通信和功能。从 XCP Central 接收的配置信息存储在控制平面命名空间 ( `istio-system` ) 中，确保本地缓存在连接丢失时可用。

##  详细的数据流

![每个集群中从用户变更到 Istio 的详细数据流。](../../assets/concepts/configuration-dataflow.svg)

TSB 内的配置数据流可以概括为一系列步骤：

1. 用户通过 TSB UI、API 或 CLI 启动配置更改。
2. TSB API 服务器将配置存储在其数据库中。
3. TSB 将配置推送到 XCP Central。
4. XCP Central 通过 gRPC 将配置分发到 XCP Edge 实例。
5. XCP Edge 将传入配置存储在控制平面命名空间 ( `istio-system` ) 中。
6. XCP Edge 将配置转换为本机 Istio 对象。
7. Istio 处理配置并将其部署到 Envoy。

此外，服务发现信息的管理如下：

1. XCP Edge 将服务发现更新发送到 XCP Central。
2. XCP Central 将集群状态信息传播到 XCP Edge 实例。
3. 如果需要，XCP Edge 会更新多集群命名空间配置 ( `xcp-multicluster` )。
4. Istio 处理配置并将其部署到 Envoy。

##  与 GitOps 集成

TSB 的结构化配置数据流可以无缝集成到 GitOps 工作流程中。这种集成通过两个主要场景进行：

1. 从 CI/CD 接收配置：TSB 可以从 CI/CD 系统接收配置更新，该系统在 Git 存储库中维护事实来源。
2. 管理平面提交到 Git：在未来的版本中，TSB 的管理平面将能够将其配置更改直接提交到 Git，与 GitOps 方法保持一致。

这两种场景都可以在 TSB 生态系统内实现高效的配置管理，从而增强服务网格基础设施的可靠性和可维护性。