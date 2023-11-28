---
title: TSB Operator
description: TSB Operator 概念介绍。
---

本节向你介绍 TSB Operator 的基本概念。你将深入了解 TSB Operator 如何管理 TSB 的整个生命周期，包括跨各个平面的安装、升级和运行时行为。

{{<callout note "Kubernetes 知识">}}

如果你不熟悉 Kubernetes 命名空间、Operator、清单和自定义资源，建议你熟悉这些概念。此背景将极大地增强你对 TSB Operator 的理解以及维护 TSB 服务网格的能力。

你可以查阅 [Kubernetes 文档](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)来了解有关 Operator 模式的更多信息。

{{</callout>}}

TSB Operator 在控制 TSB 管理、控制和数据平面组件的安装、升级和运行时行为方面发挥着关键作用。为了确保兼容性并提供平滑的升级体验，基于 Kubernetes 的 TSB 组件清单已集成到 TSB Operator 中。因此，管理、控制和数据平面组件的版本与管理它们的 TSB Operator 部署的版本相关联。TSB Operator 利用用户创建的自定义资源 (CR) 来配置和实例化这些组件。

为了有效管理 TSB 生命周期，TSB Operator 与 `tctl` CLI 工具密切协作。使用 `tctl` ，你可以生成跨管理、控制和数据平面安装和配置 TSB Operator 所需的初始 TSB Operator 清单。

每个平面都需要其 TSB Operator 实例。安装后，TSB Operator 将配置为监控特定平面的相关 CR。TSB Operator 的行为受到多种因素的影响，包括：

- 捆绑的 TSB 组件在 TSB Operator 中体现。
- 在 TSB Operator 监视的命名空间中检测到的 CR 内容。
- 由 TSB Operator 管理的 TSB 组件的存在。

通过 TSB Operator 对 TSB 生命周期的管理通常遵循当前状态和期望状态之间的协调过程。

以下是与 TSB Operator 生命周期操作相关的要点：

- CR 的可用性向 TSB Operator 表明，应使用 CR 中指定的配置来部署固定 TSB 版本的所有组件。
- CR 缺失会提示 TSB Operator 确保没有 TSB 组件正在运行。TSB Operator 将删除在其控制下部署的任何组件。
- 如果 CR 已可用，则使用较新版本的 Operator 更新 TSB Operator 引导清单会触发 TSB 升级。
- 更新 CR 会导致现有 TSB 安装重新配置以采用新的配置详细信息。
- 运行与 Operator 嵌入式清单中列出的版本不同的 TSB 组件将自动删除，以支持指定版本。
- 任何丢失的 TSB 组件（例如用户意外删除的组件）都会根据 TSB Operator 指定的固定版本和 CR 配置重新创建。
