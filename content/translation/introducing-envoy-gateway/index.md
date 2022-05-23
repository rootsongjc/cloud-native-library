---
title: 开源项目 Envoy Gateway 简介
summary: 今天，我们很高兴地宣布 Envoy Gateway 成为 Envoy 代理家族的新成员，该项目旨在大幅降低将 Envoy 作为 API 网关的使用门槛。

# Link this post with a project
projects: [""]

# Date published
date: '2022-05-16T13:00:00T+08:00'

# Date updated
lastmod: '2022-05-16T21:12:00+08:00'

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

authors: ["Matt Klein"]
tags: ["Envoy","开源","网关"]
categories: ["Envoy"]
links:
  - icon: medium
    icon_pack: fab
    name: 原文
    url: https://blog.envoyproxy.io/introducing-envoy-gateway-ad385cc5953
---

今天，我们很高兴地宣布 [Envoy Gateway](https://github.com/envoyproxy/gateway) 成为 Envoy 代理家族的新成员，该项目旨在大幅降低将 Envoy 作为 API 网关的使用门槛。

## 历史

Envoy [在 2016 年秋天开源](https://medium.com/lyft-engineering/announcing-envoy-c-l7-proxy-and-communication-bus-92520b6c8191)，令我们惊讶的是，它很快就引领了整个行业。用户被这个项目的许多不同方面所吸引，包括它的包容性社区、可扩展性、API 驱动的配置模型、强大的可观察性输出和越来越广泛的功能集。

尽管在其早期历史中，Envoy 成为了**服务网格**的代名词，但它在 Lyft 的首次使用实际上是作为 API 网关 / 边缘代理，提供深入的可观察性输出，帮助 Lyft 从单体架构迁移到微服务架构。

在过去的 5 年多时间里，我们看到 Envoy 被大量的终端用户采用，既可以作为 API 网关，也可以作为服务网格中的 sidecar 代理。同时，我们看到围绕 Envoy 出现了一个庞大的供应商生态系统，在开源和专有领域提供了大量的解决方案。Envoy 的供应商生态系统对项目的成功至关重要；如果没有对所有在 Envoy 上兼职或全职工作的员工的资助，这个项目肯定不会有今天的成就。

Envoy 作为许多不同的架构类型和供应商解决方案的组成部分，其成功的另一面是它本质上位于架构底层；Envoy 并不是一个容易学习的软件。虽然该项目在世界各地的大型工程组织中取得了巨大的成功，但在较小和较简单的用例中，它只被轻度采用，在这些用例中，[nginx](https://nginx.org/) 和 [HAProxy](http://www.haproxy.org/) 仍占主导地位。

Envoy Gateway 项目的诞生是出于这样的信念：将 Envoy 作为 API 网关的角色推向大众需要两个主要条件：

- 一个简化的部署模型和 API 层，旨在满足轻量级使用
- 将现有的 [CNCF](https://www.cncf.io/) API 网关项目（[Contour](https://projectcontour.io/) 和 [Emissary](https://github.com/emissary-ingress/emissary)）合并为一个共同的核，可以提供最好的用户体验，同时仍然允许供应商在 Envoy Proxy 和 Envoy Gateway 的基础上建立增值解决方案。

我们坚信，如果社区汇聚在单一的以 Envoy 为核心的 API 网关周围，它将会：

- 减少围绕安全、控制平面技术细节和其他共同关切的重复工作。
- 允许供应商专注于在 Envoy Proxy 和 Envoy Gateway 的基础上以扩展、管理平面 UI 等形式分层提供增值功能。
- 众人拾柴火焰高，让全世界更多的用户享受到 Envoy 的好处，无论组织的大小。更多的用户为更多的潜在客户提供了良性循环，为 Envoy 的核心项目提供了更多的支持，也为所有人提供了更好的整体体验。

## 项目概要

总得来说，Envoy Gateway 可以被认为是 Envoy Proxy 核心的一个封装器。它不会以任何方式改变核心代理、[xDS](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol)、[go-control-plane](https://github.com/envoyproxy/go-control-plane) 等（除了潜在的驱动功能、bug 修复和一般改进以外）。它将提供以下功能：

- 为网关用例提供简化的 API。该 API 将是带有一些 Envoy 特定扩展的 [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)。之所以选择这个 API，是因为在 Kubernetes 上作为 Ingress Controller 部署是该项目最初的重点，而且该 API 得到了业界的广泛认可。
- 开箱即用，让用户能够尽可能快地启动和运行。这包括提供控制器资源、控制平面资源、代理实例等的生命周期管理功能。
- 可扩展的 API 平面。虽然该项目将致力于使常见的 API 网关功能开箱即用（例如，速率限制、认证、[Let’s Encrypt](https://letsencrypt.org/) 集成等），但供应商将能够提供所有 API 的 SaaS 版本，提供额外的 API 和增值功能，如 WAF、增强的可观察性、混乱工程等。
- 高质量的文档和入门指南。我们对 Envoy Gateway 的主要目标是使最常见的网关用例对普通用户来说可以信手拈来。

关于 API，我们认为导致混乱的主要是在针对高级用例时，在其他项目中有效地重新实现 Envoy 的 [xDS](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol) API。这种模式导致用户不得不学习多个复杂的 API（最终转化为 xDS），才能完成工作。因此，Envoy Gateway 致力于 "硬性规定"，即 Kubernetes Gateway API（以及该 API 中任何允许的扩展）是**唯一**被支持的额外 API。更高级的用例将由 "xDS 模式" 提供服务，其中现有的 API 资源将为最终用户自动翻译，然后他们可以切换到直接利用 xDS API。这将导致一个更清晰的主 API，同时为那些可能超越主 API 的表达能力并希望通过 xDS 利用 Envoy 的全部功能的组织提供了路径。

## 关于 API 的标准化

虽然 Envoy Gateway 的目标是提供一个参考实现，以便在 Kubernetes 中作为 Ingress Controller 轻松运行 Envoy，但这项工作最主要的目的是 **API 标准化**。随着行业在特定的 Envoy Kubernetes Gateway API 扩展上的趋同，它将允许供应商轻松地提供替代的 SaaS 实现，如果用户超越了参考实现，想要额外的支持和功能等，这可能是最好的。显然，围绕定义 API 扩展，确定哪些 API 是必需的，哪些是可选的，等等，还有很多工作要做。这是我们标准化之旅的开始，我们渴望与所有感兴趣的人一起深入研究。

## 接下来的计划

今天，我们感谢 Envoy Gateway 的最初赞助商（[Ambassador Labs](https://www.getambassador.io/)、[Fidelity](https://www.fidelity.com/)、[Tetrate](https://www.tetrate.io/) 和 [VMware](https://www.vmware.com/)），很高兴能与大家一起开始这个新的旅程。该项目是非常早期的，到目前为止的重点是商定 [目标](https://github.com/envoyproxy/gateway/blob/main/GOALS.md)和[高水平的设计](https://github.com/envoyproxy/gateway/blob/main/docs/design/SYSTEM_DESIGN.md)，所以现在是参与的好时机，无论是作为终端用户还是作为系统集成商。

我们还想非常清楚地说明，Contour 和 Emissary 的现有用户不会被抛在后面。该项目（以及 [VMware](https://www.vmware.com/) 和 [Ambassador Labs](https://www.getambassador.io/)）完全致力于确保这些项目的用户最终能够顺利地迁移到 Envoy Gateway，无论是通过翻译和替换，还是通过这些项目成为 Envoy Gateway 核心的包装物。

我们对通过 Envoy Gateway 项目将 Envoy 带给更大的用户群感到非常兴奋，我们希望你能[加入我们](https://github.com/envoyproxy/gateway#contact)的旅程。