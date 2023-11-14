---
title: "零信任 Kubernetes 安全的三大 mTLS 最佳实践"
date: 2022-12-13T10:00:00+08:00
draft: false
authors: ["Tetrate"]
summary: "我们将介绍在 Kubernetes 中实现双向 TLS（mTLS）的三大最佳实践。"
tags: ["Kubernetes", "mTLS","安全"]
categories: ["安全"]
---

[Kubernetes](https://kubernetes.io/) 是编排现代云原生工作负载的事实标准。但是，它不提供开箱即用的安全通信。这意味着每个需要实施传输中加密以对其 Kubernetes 部署[采用零信任安全态势的](https://tetr8.io/3FCXsDn)人都需要自己解决这个问题。

幸运的是，有很多易于理解的方法可以实现，在本文中，我们将介绍在 Kubernetes 中实现双向 TLS（mTLS）的三大最佳实践。

## 什么是 mTLS，为什么对安全来说很重要？

传输层安全性（SSL 的后继者）是部署最广泛的安全通信标准，在 HTTPS 中最为明显。TLS 非常适合在需要向客户端证明其身份的服务器之间建立既保密（防窃听）又真实（防篡改）的安全通信。但是，在双方都需要向对方证明身份的情况下（例如在 Kubernetes 应用程序中的微服务之间），TLS 是不够的。

这就是双向 TLS (mTLS) 的用武之地。mTLS 是 TLS，但双方在建立安全通信通道之前向对方证明自己的身份。这是 Kubernetes 中安全通信所需的必要部分。mTLS 提供：

- 在线加密以确保机密性和防篡改
- 相互的、加密的安全身份证明以确保真实性

要深入了解 mTLS 的工作原理，请参阅我们关于 [mTLS 的文章](https://tetr8.io/3NEcL0Q)。

## mTLS 的困难部分：证明身份

困难的部分是为服务建立一个安全机制来向彼此证明它们的身份。

对于常规 TLS，过去很难管理向其客户端证明服务器身份的证书。[随着 Let's Encrypt](https://letsencrypt.org/) 和 [ACME 协议](https://en.wikipedia.org/wiki/Automatic_Certificate_Management_Environment)的出现，这变得容易多了。然而，在像 Kubernetes 这样的动态（并且主要是私有的）环境中管理服务身份和证书更加困难，因为有许多通常是短暂的服务需要强大的、可证明的身份，但实际上不能使用公共 ACME 服务。

推出自己的自动化证书管理系统是不切实际且有风险的。正确管理 mTLS 证书很困难，错误的后果很严重。您需要一种可信赖的、经过验证的方法来做到这一点；这就是服务网格的用武之地。

## 使用服务网格，NIST 微服务安全标准

在[微服务安全标准](https://tetr8.io/3zi85IC)中，美国国家标准与技术研究院 (NIST) 建议使用服务网格作为专用基础设施层来提供核心网络安全功能。这些核心功能之一是支持 mTLS 的强大服务身份和证书管理。而且，Istio——[使用最广泛的服务网格](https://tetr8.io/3UsARgY)—— 为您提供开箱即用的 mTLS 支持。Istio 透明地提供基础设施 —— 包括安全命名、强大的服务身份和证书管理 —— 用于 Kubernetes 工作负载之间的安全通信以及与外界的连接。

如果您想详细了解 NIST 的微服务安全标准以及 Tetrate 如何帮助满足这些标准，请查看 [Tetrate 的微服务联邦安全要求指南](https://tetr8.io/3Ccg6Qt)。

## 最佳实践一：不要使用自签名证书

虽然 Istio 将为您实施 mTLS，但它默认使用自签名证书，因此您可以立即看到网格工作，只需最少的配置。这使得初始用户体验变得简单，但它并非不适合生产环境。NIST 的指南（NIST SP 800-204A，SM-DR12）是完全禁用生成自签名证书的能力。

## 最佳实践二：将 Istio 的信任根植于现有 PKI

如果不应该使用 Istio 的默认自签名证书，还有什么选择？简短的回答是，您应该 [将 Istio 的信任根植于您现有的公钥基础设施 (PKI) 中](https://tetr8.io/3DDcAOJ)。这将通过确保它们都具有相同的信任根来实现跨其他集群中的 Istio 部署的通信。观看我们关于 [使用 Istio 的外部 CA 的视频，了解更多信息](https://www.youtube.com/watch?v=4b3H7isIAnQ)。

## 最佳实践三：使用中间证书

确切地说，您如何让 Istio 信任您现有的 PKI？Tetrate 的创始工程师和 NIST 微服务安全标准的合著者 Zack Butcher [在此处提供了所有详细信息](https://tetr8.io/3DDcAOJ)。但是，简而言之，我们的建议是使用您组织的根证书颁发机构颁发的中间证书。这将：

- 允许细粒度的证书撤销，而无需同时在整个基础架构中强制使用新证书。
- 启用签名证书的轻松轮换。

有关如何自动化 Istio 证书颁发机构 (CA) 轮换的分步说明，请参阅我们关于 [在大规模生产中自动化 Istio CA 轮换的](https://tetrate.io/blog/automate-istio-ca-rotation-in-production-at-scale/)文章。

## 下一步

如果您不熟悉服务网格和 Kubernetes 安全性，我们在 [Tetrate Academy](https://tetr8.io/academy) 提供一系列免费在线课程，可以让您快速了解 Istio 和 Envoy。

如果您正在寻找一种快速将 Istio 投入生产的方法，请查看 [Tetrate Istio Distribution (TID)](https://tetr8.io/tid)。TID 是 Tetrate 的强化、完全上游的 Istio 发行版，具有经过 FIPS 验证的构建和支持。这是开始使用 Istio 的好方法，因为您知道您有一个值得信赖的发行版，有一个支持您的专家团队，并且如果需要，还可以选择快速获得 FIPS 合规性。

一旦启动并运行 Istio，您可能需要更简单的方法来管理和保护您的服务，而不仅仅是 Istio 中可用的方法，这就是 Tetrate Service Bridge 的用武之地。您可以[在这里](https://tetr8.io/tsb)详细了解 Tetrate Service Bridge 如何使服务网格更安全、更易于管理和弹性，或[联系我们进行快速演示](https://tetr8.io/contact)。

## 更多资源

观看我们的视频：

- [使用 Istio 的外部 CA](https://www.youtube.com/watch?v=4b3H7isIAnQ)
- [Istio Ingress Gateway 中的 SSL 证书](https://www.youtube.com/watch?v=nYJJ57WCkxE)
- [如何将服务网格用于混合云和遗留工作负载](https://www.youtube.com/watch?v=o8AnLk4Da7M)
- [如何将 VM 工作负载连接到网格](https://www.youtube.com/watch?v=mHR7rR83KjM)
- [Tetrate 如何帮助美国国防部将 Istio 用于零信任架构](https://www.youtube.com/watch?v=E_D4bjvX8Xw&t=2s)
