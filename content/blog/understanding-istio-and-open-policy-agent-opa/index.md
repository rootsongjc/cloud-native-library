---
title: "Istio 中的外部授权过滤器：使用 OPA 实现灵活的授权策略"
date: 2023-03-28T12:00:00+08:00
draft: false
authors: ["Tetrate"]
summary: "本文介绍了如何将服务网格和开放策略代理（OPA）结合使用，以实现基于身份的分割的五个策略检查。服务网格为前四项检查提供了执行点，而 OPA 则在第五项中发挥作用。本文还探讨了如何将特定于业务的策略应用于请求，以及如何使用 OIDC 或专用授权基础设施来实现最终用户对资源的授权。"
tags: ["Istio", "OPA"]
categories: ["Service Mesh"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://tetrate.io/blog/understanding-istio-and-open-policy-agent-opa/
---

客户向我们询问服务网格实践中关于开放策略代理 (OPA) 和服务网格如何结合使用的问题。我们探讨了关于服务网格和 OPA 策略的最佳实践，以及它们如何相互补充的想法。为了构建讨论框架，我们使用了 NIST 的零信任架构标准。在即将发布的 NIST 标准文档特别出版物 800-207A 中，基于身份的分段是一个主要概念。最低标准包括五项策略检查，应应用于进入的每个请求系统和每个后续跃点。您可以观看我们在今年的 CloudNativeSecurityCon 上与来自 NIST 的 Ramaswami Chandramouli 进行的深入讨论的[演示](https://www.youtube.com/watch?v=s2lIaFhkA8c)。

**使用服务网格实现基于身份的分割的五个策略检查：**

1. 传输中加密
2. 服务身份和认证
3. 服务到服务授权
4. 最终用户身份和身份验证
5. 最终用户对资源的授权

简而言之，服务网格是一个专用的基础设施层，专门用于为前四项检查实施策略，并在第五项中发挥一定作用。OPA 的亮点在于第五点：最终用户对资源的授权。

Istio 的 sidecar 代理充当微服务应用程序的安全内核。Envoy 数据平面是一个通用的策略执行点 (PEP)，可以拦截所有流量并可以在应用层应用策略。就此而言，它是一个参考监视器 ( [NIST SP 800-204B](https://csrc.nist.gov/publications/detail/sp/800-204b/final) )。将 Envoy 作为 PEP，我们可以将安全问题从应用程序转移到网格中。

策略**检查 1-2：传输中的加密和服务身份与认证**。为了满足前两个策略检查、传输中的加密以及服务身份和身份验证，网格为系统中的所有通信实施 mTLS。

**策略检查 3：服务到服务授权。** 服务网格还提供策略三，即服务到服务的授权。OPA 可以在这里开始发挥作用，但由于 OPA 是通用的，它没有围绕服务通信的 DSL，因此您必须自己创建它。另一方面，我们认为策略往往更自然，更容易用专为它构建的语言来表达。服务网格 —— 更重要的是，我们在 Istio 之上构建的应用程序连接和安全平台 [Tetrate Service Bridge](https://tetrate.io/tetrate-service-bridge/)—— 具有对编写服务到服务策略有意义的名词。

**策略检查 4：最终用户身份和身份验证。** 对于第四个策略检查，我们需要在系统的每一跳验证最终用户身份。服务网格提供执行点来进行检查，但有关用户身份验证的实际决定既不在服务网格领域也不在 OPA 范围内。相反，我们需要委托给受信任的身份提供者来在此处做出判决。

**策略检查 5：最终用户对资源的授权。** 零信任云原生访问控制的第五个策略检查是 OPA 可以发挥重要作用的地方。服务网格没有最终用户和资源之间关系的模型，因此不适合编写有关它的策略。NIST 的指南是通过 OIDC 与现有系统集成或利用专用授权基础设施 —— 例如，NIST 的下一代访问控制 (NGAC) 和 Open Policy Agent。

例如，以媒体流服务及其播放列表为例。我们可能需要授权最终用户访问数百万到数十亿个播放列表。就像 OPA 不是特别适合服务到服务的授权一样，Istio 授权策略也不适合最终用户到资源的授权；但是，OPA 适合。

OPA 也非常适合超越 NIST ZTA 策略框架的步骤：**将特定于业务的策略应用于请求。** 在我们完成零信任的五项策略检查之后，我们可以委托 OPA 作为规则引擎来执行业务策略。

在接下来的几个月里，我们将对此发表更多看法，尤其是在 SP 800-207A 进入起草过程时。但是，与此同时，我们在 Cloud Native Security Con 上的谈话录音对这些问题进行了更深入的讨论：

- [ZTA 基于身份的分割 ——Zack Butcher、Tetrate 和 Ramaswamy Chandramouli，NIST](https://www.youtube.com/watch?v=s2lIaFhkA8c)
- [赞助主题演讲：从 Google 到 NIST — 云原生安全的未来 — Zack Butcher，Tetrate](https://www.youtube.com/watch?v=YdcVALVwwY4)
