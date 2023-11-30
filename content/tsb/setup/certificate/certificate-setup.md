---
title: 证书类型
description: 解释了 TSB 中使用的不同类型的证书。
weight: 1
---

{{<callout note 注意>}}
自 1.7 版本以来，TSB 支持用于 TSB 管理平面 TLS 证书、内部证书和中间 Istio CA 证书的自动证书管理。详细信息请参阅 [自动证书管理](../automated-certificate-management)。
{{</callout>}}

有 4 种 TSB 运算符需要了解的证书类型：

1. TSB 内部证书：用于 TSB 内部组件相互信任的证书。
1. 应用 TLS 证书：提供给应用程序用户的证书，用于 Web 浏览器或工具。
1. 中间 Istio CA 证书：用于签发 Istio 工作负载叶子证书的中间 CA 证书。
1. 工作负载叶子证书：针对每个代理和网关签发的证书。

下面的图片显示了这些证书及其与 TSB 组件和你的应用程序的关系。

![TSB 组件中的证书](../../../assets/setup/certificates-in-tsb.svg)

## TSB 内部证书

TSB 的全局控制平面 (XCP) 从管理平面分发配置到控制平面集群。XCP 由 XCP central 和 XCP edge 组成。XCP central 部署在管理平面，TSB 服务器通过名为 MPC 的组件与其交互。TSB 内部证书（图片中突出显示为绿色）用于保护 XCP central、XCP edge、MPC 组件之间的通信。TSB 使用带 TLS 的 JWT 来确保通信的安全性。在部署 TSB 之前，你需要准备这些证书。

## 应用 TLS 证书

应用 TLS 证书（图片中突出显示为紫色）由客户端应用程序使用，以便信任访问应用程序。

你的应用程序提供的每个公开可访问的 HTTPS 服务都应具有作为 Kubernetes 机密挂载的 TLS 证书。在发布应用程序时，必须提供应用程序的 TLS 证书。虽然在技术上不是一个 "应用程序"，但你还需要设置命令行工具的 TLS 证书，以便它们可以访问 TSB 管理平面，以及你可以通过 Web 浏览器访问 TSB UI。TSB TLS 证书必须在部署 TSB 之前可用。

## 中间 Istio CA 证书

中间 Istio CA 证书（图片中突出显示为青色）在每个控制平面上以 `cacerts` 机密的形式挂载，以便可以签发 Istio 工作负载叶子证书。默认情况下，`istiod` 充当叶子证书发行者，使用中间 CA 证书来签署叶子证书。

证书应由企业 Root CA 签署（或可验证），以用于服务内部通信。集群特定的中间 CA 应在 TSB 控制平面部署期间可用。

有关在多集群设置中设置中间 Istio CA 的演示示例，请参阅 [Istio 文档](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert)。

对于生产环境，强烈建议使用生产就绪的 PKI 基础结构，例如以下内容，并遵循行业最佳实践：
1. 使用 AWS Private CA 作为企业 CA 创建中间 CA（不是自动化过程）。
2. 将现有 CA 集成到 Kubernetes CSR API 中（例如 [AWS 证书管理器](https://aws.amazon.com/certificate-manager/)、[HashiCorp Vault](https://www.vaultproject.io/)）。

通常，企业安全团队负责这些类型的证书。

## 工作负载叶子证书

工作负载叶子证书（图片中突出显示为黄色）会分发给每个代理和网关（或每个工作负载）。这些证书是短期证书（默认情况下为 24 小时，可以通过在 `ControlPlane` CR 中设置 `defaultWorkloadCertTTL` 来更改）。

重要的是要了解，这些证书会自动轮换，不受 TSB 管理。Istiod 负责使用企业中间证书签发和轮换证书。
