---
weight: 1
title: Tetrate Service Bridge 手册
linktitle: TSB 手册
summary: "Tetrate Service Bridge（TSB）中文文档：安装、使用和升级。"
type: book
icon: book
icon_pack: fas
cascade:
  commentable: false
  date: '2023-08-09T12:00:00+08:00'
  categories: ["TSB"]
  tags: ["TSB"]
  type: book
---

Tetrate Servcie Bridge（TSB）基于开源的 Istio、Envoy 和 SkyWalking 建立，是 [Tetrate](https://tetrate.io) 的旗舰产品。本手册将帮助你全面地了解 TSB。无论你是应用程序开发人员、平台运维者，我们都会定制内容来满足你的需求。如果你遇到任何障碍，请放心，我们随时提供支持。

## 对于应用程序开发人员

作为使用 TSB 将应用程序部署到环境中的应用程序开发人员，你将体验到简化的过程。首先使用 [Sidecar 代理](./concepts/glossary)部署你的应用程序。然后，深入研究高级配置，例如将流量路由到应用程序、实施速率限制或在虚拟机和 Kubernetes 应用程序之间划分流量以实现逐步现代化。

### 理解关键概念

- [掌握服务网格架构](./concepts/service-mesh)
- [探索 TSB 的架构](./concepts/architecture)
- [高效的交通管理](./concepts/traffic-management)
- [TSB 的全局可观测性](./concepts/observability)

### 部署和配置应用程序

- [使用 Sidecar 部署应用程序](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/) - 如果需要，请熟悉 Istio 的故障排除资源。
- [为外部流量配置 TSB](./howto/traffic/load-balance)
- [使用 OpenAPI 注释](./howto/gateway/application-gateway-with-openapi-annotations)

### 高效的应用管理

- [监控指标和跟踪](./quickstart/observability)

### 解决常见用例

- [将流量引导至应用程序](./howto/gateway/app-ingress)
- [实施速率限制](./howto/rate-limiting/toc)
- [ 逐步金丝雀发布](./howto/traffic/canary-releases)
- [将虚拟机流量迁移到 Kubernetes](./howto/traffic/migrating-vm-monoliths)
- [跨集群故障转移](./howto/gateway/multi-cluster-traffic-shifting)

### 参考资料

- [TSB 常见问题解答](./knowledge-base/faq)
- [Istio 官方文档](https://istio.io/latest/docs/)

## 对于平台运维者

对于使用 TSB 将集群转变为统一网格的平台运维者来说，旅程从[安装 TSB 的管理平面](./setup/self-managed/management-plane-installation)开始。你还将加入应用程序集群以实现可观测性和控制，并通过[演示应用程序部署](./quickstart/introduction)掌握应用程序部署过程。

### 掌握基本概念

- [掌握服务网格架构](./concepts/service-mesh)
- [深入了解 TSB 的架构](./concepts/architecture)，包括管理、控制和数据平面
- [高效的交通管理](./concepts/traffic-management)
- [TSB 的全局可观测性](./concepts/observability)
- [了解配置数据流](./concepts/configuration-dataflow)
- [资源和权限的层次结构 (IAM)](./operations/users/roles-and-permissions)

### 安装、配置和操作

- [TSB 资源规划](./setup/resource-planning)
- [安装 TSB 的管理平面](./setup/self-managed/management-plane-installation)
  - [设置 OIDC 登录](./operations/users/oidc-azure) - 使用 OIDC 修改基于 LDAP 的登录。
- [应用程序板载集群](./setup/self-managed/onboarding-clusters)
- [部署和配置入口代理](./quickstart/ingress-gateway)
- [了解证书要求](./setup/certificate/certificate-requirements)
- [ 升级 TSB 版本](./setup/self-managed/upgrade)
- [管理 TSB ImagePullSecret](./setup/remote-registry)
- [将 GitOps 与服务网格结合使用](./knowledge-base/gitops)
- [监控配置状态](./troubleshooting/configuration-status)

### 管理与运维

- [TSB 访问管理](./operations/users/roles-and-permissions)
- [应用程序和 TSB 的默认日志级别](./operations/configure-log-levels)
- [TSB 组件警报指南](./operations/telemetry/alerting-guidelines)
- [使用 TSB 的调试容器进行故障排除](./troubleshooting/debug-container)
- [ 实施 GitOps](./howto/gitops/gitops)

### 参考资料

- [TSB 常见问题解答](./knowledge-base/faq)
- [TSB 安装和 OIDC 参考](./refs/install/managementplane/v1alpha1/spec#oidcsettings)
- [TSB 通信的防火墙配置](./setup/firewall-information)

## 对于安全管理员

服务网格使安全团队能够集中实施和执行策略，同时保持开发人员的敏捷性。

### 掌握关键概念

- [了解服务网格架构](./concepts/service-mesh)
- [探索高级 TSB 安全概述](./concepts/security)
- [探索管理平面/运行时拆分](./concepts/architecture)

#### 管理平面安全

- [IAM：资源和权限层次结构](./operations/users/roles-and-permissions)
- [深入研究运行时架构](./concepts/architecture)

#### 应用程序运行时安全

- [了解服务身份](./concepts/security)
- [实施服务到服务授权](https://istio.io/latest/docs/concepts/security/#authorization)（TSB 上的薄层）
- [使用网格对最终用户进行身份验证](./howto/gateway/end-user-auth-keycloak)

### 对应用程序实施控制

- [在各处强制实施 (m)TLS](./quickstart/security)
- [应用服务到服务的身份验证和授权](./quickstart/security)
- [管理到外部服务的出站](./howto/gateway/egress-gateways)
- [实施最终用户身份验证](./howto/gateway/end-user-auth-keycloak)
- [配置 Envoy 的外部授权 API](./howto/authorization/toc)

### 确保控制措施得到执行

- [通过全局可观测性监控服务间流量](./concepts/observability)
- [审核日志概述和 API](./concepts/security)

### TSB 的访问管理

- 通过灵活的 RBAC 来利用租户、工作区和组
- [TSB 连接的防火墙要求](./setup/firewall-information)

### 参考资料

- [TSB 常见问题解答](./knowledge-base/faq)
- [Istio 安全概述](https://istio.io/latest/docs/concepts/security/)
- [TSB 的 RBAC 访问控制 API 参考](./refs/tsb/rbac/v2/yaml)
