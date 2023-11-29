---
title: 应用载入最佳实践
description: "本指南描述了为应用载入准备 Tetrate 管理的平台的基本建议。适用于 Tetrate Service Express (TSE) 和 Tetrate Service Bridge (TSB)。"
weight: 1
---

本指南描述了为应用载入准备 Tetrate 管理的平台的基本建议。适用于 Tetrate Service Express (TSE) 和 Tetrate Service Bridge (TSB)。

为简单起见，本文档仅考虑在 Kubernetes 集群上部署的服务。

## 用户类型

本文档假设存在以下两种用户类型：

 * **平台所有者**：用户可以直接访问 TSE 或 TSB，并希望预先配置平台以接收和托管服务。平台所有者需要定义适当的默认值和防护措施，并准备附加服务，如 DNS 或仪表板。

 * **应用所有者**：用户无法访问 TSE 或 TSB，但可以访问 Kubernetes 集群中的一个或多个命名空间。每个应用所有者希望使用标准的 Kubernetes API 和工具（如 CD 流水线）将生产服务部署到集群中。

<details>
<summary><b>TSB 用户和角色层次结构</b></summary>

TSB 提供了一个非常丰富的 [用户和角色层次结构](https://docs.tetrate.io/service-bridge/latest/concepts/security)，允许平台所有者将有限的 TSB 功能委托给其他用户类型，包括多个应用所有者用户和团队。本文档不涵盖这些更复杂的情况。

相反，本文档适用于由 TSE 和 TSB 支持的更简单的 "一个平台所有者团队，多个应用所有者，高信任" 情况。它假定你将使用 [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) 或类似的方法来控制应用所有者如何访问 Kubernetes 命名空间。本文档使用 Tetrate 的“GitOps”集成来授予应用所有者访问某些 Tetrate 特定功能的权限，例如部署入口网关。GitOps 在 [TSE 中默认启用](https://docs.tetrate.io/service-express/gitops/gitops-tse)，并且可以在 [TSB 中启用和配置](https://docs.tetrate.io/service-bridge/1.6.x/operations/features/configure_gitops)。

</details>

## 情景

本文档将涵盖以下情景：

### 1. [准备集群](prepare)

平台所有者将为每个应用所有者团队创建命名空间，并创建相应的 Tetrate 工作区。他们将配置一个仅允许工作区内通信的零信任基础环境。在需要接收外部流量的命名空间中部署入口网关。

### 2. [部署服务并配置网关规则](deploy-service)

应用所有者将在其命名空间内部署服务，并在必要时配置入口网关规则以允许外部流量。

### 3. [监视 Tetrate 指标](monitor)

平台所有者将配置与第三方度量系统的集成，以便应用所有者可以从其应用程序中观察 Tetrate 指标。或者，平台所有者可以授予应用所有者访问 Tetrate 管理平面的权限，以便他们可以直接访问指标。

### 4. [扩展安全规则](security)

平台所有者可以"打开"零信任环境，以允许有限的安全例外。这允许应用所有者拥有的服务使用其他命名空间和位置中的服务。

### 5. [管理集群之间的流量](cross-cluster)

平台所有者可以预先配置暴露和故障转移措施，以公开远程集群中的源服务，并安排在冗余服务实例的本地到远程的故障转移。

## 高级主题

 * **共享网关：** 了解如何在工作区之间[共享入口网关](../../howto/gateway/shared-ingress)，以减少在大规模部署中网关的数量。
 * **Route 53 集成：** 了解如何微调 [Tetrate 的 Route 53 集成](https://docs.tetrate.io/service-express/integrations/route53)。