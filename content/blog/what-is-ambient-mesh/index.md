---
title: 什么是 Ambient Mesh？
summary: 我们对任何能够使服务网格的采用更加容易的事情都充满热情，但我们还不确定 Ambient Mesh 的部署模型能否能兑现这一承诺。
date: '2022-09-28T10:00:00+08:00'
draft: false
authors: ["Zachary Butcher"]
tags: ["Service Mesh","Istio"]
categories: ["Istio"]
links:
  - icon: language
    icon_pack: fa
    name: 阅读英文版原文
    url: https://www.tetrate.io/blog/ambient-mesh-what-you-need-to-know-about-this-experimental-new-deployment-model-for-istio/
---

Istio[最近宣布了“Ambient Mesh”](https://istio.io/latest/blog/2022/introducing-ambient-mesh/) —— 一种用于 Istio 的实验性“无 sidecar”部署模型。我们最近在[从服务网格中获得最大性能和弹性](https://www.tetrate.io/blog/ebpf-and-sidecars-getting-the-most-performance-and-resiliency-out-of-the-service-mesh/)的背景下写了关于 sidecar 与 sidecar-less 的文章。在本文中，我们将特别介绍我们对 Ambient Mesh 的看法。

如果你想立即开始使用可用于生产的 Istio 发行版，请尝试[Tetrate Istio Distro (TID)](https://istio.tetratelabs.io/)。TID 是经过审查的 Istio 上游发行版，它易于安装、管理和升级，基于适用于 FedRAMP 环境的 FIPS 认证构建。如果你需要一种统一且一致的方式来保护和管理一组应用程序中的服务，请查看[Tetrate Service Bridge (TSB)](https://www.tetrate.io/tetrate-service-bridge/)，这是我们基于 Istio 和 Envoy 构建的全面的边缘到工作负载应用程序连接平台。

## 什么是 Ambient Mesh？

Ambient Mesh 是最近引入 Istio 的一种实验性新部署模型。它将 Envoy sidecar 当前执行的职责分为两个独立的组件：一个用于加密的节点级组件（称为“ztunnel”）和一个为每个服务账户部署的 L7 Envoy 实例，用于所有其他处理（称为“waypoint”）。Ambient Mesh 模型试图在潜在改进的生命周期和资源管理中获得一些效率 —— 至少，这是动机。

## 我为什么要关心 Ambient Mesh？

对于大多数服务网格用户来说，Istio 数据平面的确切部署模型是你可能不需要考虑太多的选择。默认可能没问题。对于*一些*服务网格用户，特别是那些拥有少量服务的大规模水平扩展足迹的用户（waypoint 架构获得最高效率的地方），Ambient Mesh 模型将在成熟为生产就绪的基础设施软件时很有用。

## 本文主旨

- Ambient Mesh 部署模型与 sidecar 模型进行了一些权衡，特别是在生命周期管理、资源利用、故障排除和安全状况方面。它们之间不分伯仲。
- Ambient Mesh 目前还在实验阶段，最早要到 2023 年才能投入生产 —— 也就是说，**暂时不要在此基础上进行构建**。现在，它的性能差，功能更少，并且对于已广泛使用的技术（如 CNI）具有未定义的行为。但是，我们预计随着未来几个月的实现，这种情况将迅速改善。
- 你关心的大部分网格功能（如按请求流量管理和安全控制、分布式追踪和应用程序级 RED 指标）都发生在 L7 中。目前尚不清楚 Ambient Mesh 的仅 L4 部分的适用范围有多大，以及打破这些数据平面职责将在多大程度上有助于推动网格的采用。

这篇文章的其余部分是我们对环境模型与 Istio 现有的 Sidecar 部署模型的权衡，看看哪一个适合你以及何时适合你。

## Istio 中的 L4 和 L7 处理如何工作？

由于 Ambient Mesh 分割了 L4 和 L7 处理，因此准确了解每一层中发生的网格行为非常重要：

|                                  | **L4**                                                       | **L7**                                                       |
| -------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **安全**                         |                                                              |                                                              |
| 服务间身份验证                   | [SPIFFE](https://spiffe.io/)，通过 mTLS 证书。Istio 颁发一个短期 X.509 证书，该证书对 pod 的服务账户身份进行编码。 | 不适用 — Istio 中的服务身份仅基于 TLS。                      |
| 服务间授权                       | 基于网络的授权，加上基于身份的策略，例如：A 只能接受来自“10.2.0.0/16”的调用；A 可以调用 B。 | 完整的策略，例如：A 只能使用包含 READ 范围的有效最终用户凭据在 B 上获取 /foo。 |
| 最终用户身份验证                 | 不适用 - 我们不能应用每个用户的设置。                        | JWT 的本地身份验证，支持通过 OAuth 和 OIDC 流进行远程身份验证。 |
| 最终用户授权                     | 不适用 —— 见上文。                                           | 服务间策略可以扩展为需要[具有特定范围、颁发者、委托人、受众等的最终用户凭据](https://istio.io/latest/docs/reference/config/security/conditions/)—— 但它不能用于完整的用户到资源访问控制。应该使用外部授权来实现用户对资源的完全访问。 |
| Envoy 的外部授权 API (ext_authz) | 无法执行任何针对请求的策略；ext_authz API 只能针对 L7 流量进行配置。 | 使用来自外部服务（例如 OPA）的决策来执行每个请求的策略。     |
| **可观测性**                     |                                                              |                                                              |
| 日志记录                         | 基本网络信息：网络五元组、发送 / 接收的字节数等。[请参阅 Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators)。 | [完整的请求元数据记录](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators)，以及基本的网络信息。 |
| 追踪                             | 目前不行；最终可能与 HBONE 一起使用。                        | Envoy 参与分布式跟踪。[请参阅有关追踪的 Istio 概述](https://istio.io/latest/docs/tasks/observability/distributed-tracing/overview/)。 |
| 指标                             | 仅限 TCP（发送 / 接收的字节数、数据包数等）。                | L7 RED 指标：请求率、错误率、请求持续时间（延迟）。          |
| **流量管理**                     |                                                              |                                                              |
| 负载均衡                         | 仅连接级别。[请参阅 TCP 流量转移任务](https://istio.io/latest/docs/tasks/traffic-management/tcp-traffic-shifting/)。 | 根据请求，启用例如金丝雀部署、gRPC 流量等。[请参阅 HTTP 流量转移任务](https://istio.io/latest/docs/tasks/traffic-management/traffic-shifting/)。 |
| 断路                             | [仅限 TCP](https://istio.io/latest/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-TCPSettings)。 | 除了 TCP 之外的 [HTTP 设置](https://istio.io/latest/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-HTTPSettings)。 |
| 异常值检测                       | 关于连接建立 / 失败。                                        | 根据请求成功 / 失败。                                        |
| 速率限制                         | [仅对 L4 连接数据的速率限制，在连接建立](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/rate_limit_filter#config-network-filters-rate-limit)时，具有全局和本地速率限制选项。 | [L7 请求元数据的速率限制](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/rate_limit_filter#config-http-filters-rate-limit)，每个请求。 |
| 超时                             | 仅建立连接（通过断路设置配置连接保持活动）。                 | 根据要求。                                                   |
| 重试                             | 重试连接建立。                                               | 每次请求失败时重试。                                         |
| 故障注入                         | 不适用——无法在 TCP 连接上配置故障注入。                      | 完整的应用程序和连接级故障（[超时、延迟、特定响应代码](https://istio.io/latest/docs/tasks/traffic-management/fault-injection/)）。 |
| 流量镜像                         | 不适用 - 仅 HTTP                                             | [对多个后端的请求进行基于百分比的镜像](https://istio.io/latest/docs/tasks/traffic-management/mirroring/)。 |

值得记住的是，运行在 L7 的代理可以执行 L4 和 L7 列中的所有操作，而运行在 L4 的代理只能执行 L4 列。通过清楚地了解发生的情况以及 L4 与 L7 的局限性，我们可以查看 Ambient Mesh 与 sidecar 模型相比所做的权衡。

## 现在我们应该使用 Ambient Mesh 吗？（还不可以）

截至 2022 年 9 月宣布，Ambient Mesh 是概念的实验证明。从[几乎每一个指标](https://github.com/istio/istio/tree/experimental-ambient#limitations)来看，它的性能都比 sidecar 模型差，而且它有很多[限制](https://github.com/istio/istio/tree/experimental-ambient#limitations)。Ambient Mesh 还**没有准备好**在生产环境中使用（对于我们的客户 —— 大型企业的平台团队 —— 应用程序开发和测试环境也算作生产环境）。

但是，我们预计随着社区中的工程师致力于部署模型，这种状态会相对迅速地发生变化。它将像[所有其他 Istio 功能](https://istio.io/latest/docs/releases/feature-stages/)一样通过功能阶段进行。查看[Istio 功能列表](https://istio.io/latest/docs/releases/feature-stages/#istio-features)，Ambient Mesh 将在 2023 年某个时候升级为 Alpha 状态。我们预计它会在 2023 年末或 2024 年初进入 Beta 版 —— 在此之前我们不建议将其用于生产用途。

## 关于 Service Mesh 和 Istio 的 Ambient Mesh 假设

总结 Ambient Mesh 公告博客文章，该架构的核心动机是假设：

1. **假设**Envoy 的 L7 功能使得将新应用程序加入网格变得具有挑战性。
2. **假设**Envoy 的 L7 功能是发现 CVE 的地方（绝大多数 Envoy CVE 在 L7 代码中，而不是在处理 TLS 和连接的 L4 代码中），因此在严格的 L4 代理中在节点级别持有多个 Pod 的证书是可以接受的，而在节点级别执行 L7 则不是。
3. **假设**Sidecar 通常会导致资源过度分配。
4. **假设**一个额外的网络跃点比一个执行 L7 计算的 Envoy 便宜（从两个 L7 sidecar 移动到一个 L7 路点增加了一个跃点，但删除了一个执行 L7 处理的 Envoy）。
5. **假设**Istio 最有价值的特性是传输中的加密，因此优化以简化该用例是很有价值的。

## Ambient Mesh 假设如何匹配我们与实际客户的经验

我们与世界上一些最大的企业密切合作以实现服务网格采用的经验并**不能完全**证明这些激励想法：

1. **L7 功能**：网格的某些 L7 功能**可能**会使应用程序更难采用，但根据我们的经验，由于连接寿命的变化或双重加密问题，应用程序载入中会出现更多的中断。无论 sidecar 或节点级代理如何，这些问题都会类似地表现出来，但对于应用程序团队在节点部署模型中进行故障排除更具挑战性（他们通常缺乏检查特权 / 节点级组件日志的权限）。要更深入地了解[节点级代理与 sidecar](https://www.tetrate.io/blog/ebpf-and-sidecars-getting-the-most-performance-and-resiliency-out-of-the-service-mesh/)，请参阅我们上面提到的博客文章。

2. **L7 CVE**，[查看它们](https://www.cvedetails.com/vulnerability-list/vendor_id-19794/product_id-53798/Envoyproxy-Envoy.html)，我们看到：

   - 33 个和 L7 处理有关，主要是解析或者 HTTP 处理。
   - 剩下的 12 个是 L4 或 Envoy 固有的（连接处理、证书处理、嘈杂的邻居 DOS、缓冲区溢出等）。
   - L7 CVE 的平均严重性高于非 L7 CVE。

   与 L7 Envoy 相比，仅 L4 的 Envoy **确实**提供了更小的攻击面，因为可以利用的代码（和 CVE）更少。攻击面是否足够低以证明持有节点上每个 pod 的身份是合理的，还有待观察。Ambient Mesh 安全模型的关键在于我们对 ztunnel 组件的信任程度 —— 这是社区打算首先关注的组件。总体而言，与 sidecar 模型相比，ambient 的安全模型充其量是横向的一步，但在将其融入现有安全模型时，边界更难推理。
   
3. **资源利用率**：确实，如果未配置 pod 资源请求，并且未使用[配置资源可见性](https://istio.io/latest/docs/ops/best-practices/traffic-management/#cross-namespace-configuration)或[Sidecar API 资源](https://istio.io/latest/docs/reference/config/networking/sidecar/)等技术，sidecar 会导致资源利用率低下。但是，我们通过 Sidecar API 资源严格控制资源可见性和限制配置范围的 Istio 部署的经验是，sidecar 资源利用率非常低，并且我们可以为每个 sidecar 设置比 Istio 的默认配置文件更小的资源请求。为这种类型的配置手动维护 Sidecar API 资源非常具有挑战性 —— 这就是 [Tetrate Service Bridge](https://www.tetrate.io/tetrate-service-bridge/) 根据更高级别的访问结构自动生成它的原因。

   我们很高兴看到 Ambient 部署模型如何提高资源利用率 —— 为相同的网格行为部署更少的 Envoy 具有很大的潜力，因为独立的 Watpoint Envoy 通常可以处理比单个服务实例（及其 sidecar）更多的流量。

4. **额外的网络跃点与 sidecar**：Ambient 的部署模型提供的最有趣的可能性之一是在 sidecar 架构中移除额外的 L7 Envoy。因为网格中的通信是 sidecar-to-sidecar，并且客户端和服务器都应用 L7 策略，我们必须对每个请求进行两次 L7 处理。在 Ambient 模式下，该策略将由服务器的 Waypoint 执行 —— 因此 L7 处理每个请求只发生一次。但是，在连接的两侧仍然有一个 ztunnel 进行 L4 处理。

   这种权衡 —— 网络跳跃而不是 Envoy 进行 L7 处理 —— 总体上是否值得，还有待观察。当然，在延迟低且连接可靠的同一可用区的云提供商网络中，这可能是值得的。但是，我们的许多客户在本地和各种看起来不像云提供商网络的物理站点上部署了服务网格。

5. **mTLS**：Istio 的传输加密毫无疑问是其最强大的功能之一。它用于（[以 FIPS 验证的形式](https://www.tetrate.io/blog/tetrate-istio-distro-achieves-fips-certification/)）用于[FIPS 合规性](https://www.tetrate.io/blog/tetrate-first-to-provide-hardened-istio-to-dods-iron-bank/)、[PCI 合规性](https://www.tetrate.io/blog/case-study-fico-encryption-pci-compliance-with-istio-service-mesh/)，以及在各种其他安全第一的环境中。但是，当我们查看网格的功能时，单独采用加密的原因并不常见：通常是加密与 L7 策略（包括流量控制）和可观测性相结合，激发了对该技术的投资。查看上表，很明显这些功能无法仅通过 ztunnel 实现 —— 它们需要 L7 Envoy。事实上，我们今天看到的大多数网格使用都需要 L7 Envoy。我们对任何能够使服务网格的采用更加容易的事情都充满热情，但我们还不确定 Ambient Mesh 的部署模型能否能兑现这一承诺。

## 关于 Ambient Mesh 的分离思考

Ambient Mesh 是对无 sidecar 服务网格模型的一个有趣的尝试。我们很高兴看到它是如何发展的，特别是如果它有助于更容易地采用网格。在某些特定的用例中，我们预计这种方法会产生好处，但现在还处于早期阶段，而且还没有决定权衡是否值得。无论哪种方式，Ambient Mesh 可能需要一段时间才能考虑投入生产。在那之前，正如他们所说，注意这个空间。

要[立即开始使用服务网格，Tetrate Istio Distro](https://istio.tetratelabs.io/)是安装、管理和升级 Istio 的最简单方法。它提供了经过审查的 Istio 上游发行版，该发行版已由 Tetrate 为特定平台进行测试和优化，以及一个便于获取、安装和配置多个 Istio 版本的 CLI。Tetrate Istio Distro 还为 FedRAMP 环境提供[FIPS 认证的 Istio 构建](https://www.tetrate.io/blog/tetrate-istio-distro-achieves-fips-certification/)。

对于需要统一且一致的方式来保护和管理复杂、异构部署环境中的服务和传统工作负载的企业，我们提供[Tetrate Service Bridge](https://www.tetrate.io/tetrate-service-bridge/)，这是我们基于 Istio 和 Envoy 构建的旗舰边缘到工作负载应用程序连接平台。
