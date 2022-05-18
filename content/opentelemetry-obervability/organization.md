---
linktitle: 附录 A：OpenTelemetry 项目组织
summary: 附录 A：OpenTelemetry 项目组织
weight: 10
title: 附录 A：OpenTelemetry 项目组织
date: '2022-02-05T00:00:00+08:00'
type: book
---

OpenTelemetry 是一个大型项目。OpenTelemetry 项目的工作被划分为**特殊兴趣小组**（SIG）。虽然所有的项目决策最终都是通过 GitHub issue 和 pull request 做出的，但 SIG 成员经常通过 CNCF 的官方 Slack 保持联系，而且大多数 SIG 每周都会在 Zoom 上会面一次。

任何人都可以加入一个 SIG。要想了解更多关于当前 SIG、项目成员和项目章程的细节，请查看 GitHub 上的 [OpenTelemetry 社区档案库](https://github.com/open-telemetry/community)。

## 规范

OpenTelemetry 是一个规范驱动的项目。OpenTelemetry 技术委员会负责维护该规范，并通过管理规范的 backlog 来指导项目的发展。

小的改动可以以 GitHub issue 的方式提出，随后的 pull request 直接提交给规范。但是，对规范的重大修改是通过名为 OpenTelemetry Enhancement Proposals（OTEPs）的征求意见程序进行的。

任何人都可以提交 OTEP。OTEP 由技术委员会指定的具体审批人进行审查，这些审批人根据其专业领域进行分组。OTEP 至少需要四个方面的批准才能被接受。在进行任何批准之前，通常需要详细的设计，以及至少两种语言的原型。我们希望 OTEP 的作者能够认真对待其他社区成员的要求和关注。我们的目标是确保 OpenTelemetry 适合尽可能多的受众的需求。

一旦被接受，将根据 OTEP 起草规范变更。由于大多数问题已经在 OTEP 过程中得到了解决，因此规范变更只需要两次批准。

## 项目治理

管理 OpenTelemetry 项目如何运作的规则和组织结构由 OpenTelemetry 治理委员会定义和维护，其成员经选举产生，任期两年。

治理成员应以个人身份参与，而不是公司代表。但是，为同一雇主工作的委员会成员的数量有一个上限。如果因为委员会成员换了工作而超过了这个上限，委员会成员必须辞职，直到雇主代表的人数降到这个上限以下。

## 发行版

OpenTelemetry 有一个基于插件的架构，因为有些观察能力系统需要一套插件和配置才能正常运行。

发行版（**distros**）被定义为广泛使用的 OpenTelemetry 插件的集合，加上一组脚本或辅助功能，可能使 OpenTelemetry 与特定的后端连接更简单，或在特定环境中运行 OpenTelemetry。

需要澄清的是，如果一个可观测性系统声称它与 OpenTelemetry 兼容，那么它应该总是可以使用 OpenTelemetry 而不需要使用某个特定的发行版。如果一个项目没有经过规范过程就扩展了 OpenTelemetry 的核心功能，或者包括任何导致它与上游 OpenTelemetry 仓库不兼容的变化，那么这个项目就是一个分叉，而不是一个发行版。

## 注册表

为了便于发现目前有哪些语言、插件和说明，OpenTelemetry 提供了一个注册表。任何人都可以向 [OpenTelemetry 注册表](https://opentelemetry.io/registry/)提交插件；在 OpenTelemetry 的 GitHub 组织内托管插件不是必须的。