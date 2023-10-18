---
title: 功能状态
description: 内置功能状态。
weight: 2
---

下表显示了现有的 TSB 功能及其当前阶段。该表将在每个主要或次要版本中更新。

## 特征阶段定义

下表定义了 TSB 功能的成熟阶段。

| 阶段     | Alpha（技术预览）                         | Beta                                                 | Stable                                                       |
| :------- | :---------------------------------------- | :--------------------------------------------------- | :----------------------------------------------------------- |
| 特征     | 可能不包含最终版本计划的所有功能。        | 功能完整，但可能包含许多已知或未知的错误。           | 功能完整，没有已知错误。                                     |
| 生产用途 | 不应该在生产中使用。                      | 可用于生产。                                         | 可靠，生产经过强化。                                         |
| API      | 不保证向后兼容性。                        | API 是有版本的。                                     | 可靠，值得生产。API 具有版本控制功能，并具有自动版本转换功能以实现向后兼容性。 |
| 性能     | 未量化或保证。                            | 未量化或保证。                                       | 性能（延迟/规模）被量化、记录，并保证不会出现回归。          |
| 文档     | 缺乏文档。                                | Documented.                                          | 记录用例。                                                   |
| 环境     | 在单一环境（仅限 EKS 或 GKE）上进行测试。 | 至少在两个环境上进行了测试。 （EKS、GKE、OpenShift） | 在多种环境下经过良好测试。 （AKS、EKS、GKE、MKE、OpenShift） |
| 监控     | 并非所有重要指标都可用。                  | 大多数重要指标都可用。                               | 所有重要指标均可用。                                         |

##  功能状态表

| 领域               | 描述                           | 状态   | API  | tctl |  UI  |
| :----------------- | :----------------------------- | :----- | :--: | :--: | :--: |
| **安装**           |                                |        |      |      |      |
|                    | tctl 安装                      | Stable |  N   |  Y   |  N   |
|                    | helm 安装                      | Stable |  N   |  N   |  N   |
|                    | Istio 隔离边界                 | Alpha  |  N   |  N   |  N   |
| **用户和访问**     |                                |        |      |      |      |
|                    | 从 LDAP 自动同步用户和团队     | Stable |  Y   |  Y   |  Y   |
|                    | 从 Azure AD 自动同步用户和团队 | Stable |  Y   |  Y   |  Y   |
|                    | 角色                           | Stable |  Y   |  Y   |  Y   |
|                    | 权限                           | Stable |  Y   |  Y   |  Y   |
|                    | 与 OIDC 的单点登录             | Stable |  Y   |  Y   |  Y   |
| **配置**           |                                |        |      |      |      |
|                    | 工作空间                       | Stable |  Y   |  Y   |  Y   |
|                    | 配置组                         | Stable |  Y   |  Y   |  Y   |
|                    | 配置桥接模式 - 流量            | Stable |  Y   |  Y   |  Y   |
|                    | 配置桥接模式 - 安全            | Stable |  Y   |  Y   |  Y   |
|                    | 配置桥接模式 - 网关            | Stable |  Y   |  Y   |  Y   |
|                    | 配置直接模式 - 流量            | Stable |  Y   |  Y   |  Y   |
|                    | 配置直接模式 - 安全            | Stable |  Y   |  Y   |  Y   |
|                    | 配置直连模式 - 网关            | Stable |  Y   |  Y   |  Y   |
|                    | 配置直接模式 - IstioInternal   | Stable |  Y   |  Y   |  Y   |
|                    | 1 级网关                       | Stable |  Y   |  Y   |  Y   |
|                    | 入口网关（第 2 层）            | Stable |  Y   |  Y   |  Y   |
|                    | 东西方门户                     | Beta   |  Y   |  Y   |  Y   |
|                    | 虚拟机网关                     | Stable |  Y   |  Y   |  Y   |
|                    | 出口网关                       | Beta   |  Y   |  Y   |  Y   |
|                    | TCP 流量                       | Beta   |  Y   |  Y   |  Y   |
|                    | 配置状态传播                   | Beta   |  Y   |  Y   |  Y   |
|                    | GitOps/Kubernetes CRD          | Beta   |  N   |  N   |  N   |
|                    | 分级政策                       | Beta   |  Y   |  Y   |  Y   |
|                    | 受限的层级策略                 | Beta   |  Y   |  Y   |  Y   |
|                    | 允许/拒绝规则                  | Beta   |  Y   |  Y   |  Y   |
|                    | 安全域                         | Alpha  |  Y   |  Y   |  Y   |
|                    | 服务安全设置                   | Alpha  |  Y   |  Y   |  Y   |
|                    | 身份传播                       | Alpha  |  Y   |  Y   |  Y   |
| **应用**           |                                |        |      |      |      |
|                    | 应用                           | Beta   |  Y   |  Y   |  Y   |
|                    | 使用 OpenAPI 规范配置 API      | Beta   |  Y   |  Y   |  Y   |
| **API 网关**        |                                |        |      |      |      |
|                    | 速率限制                       | Beta   |  Y   |  Y   |  Y   |
|                    | 外部授权                       | Beta   |  Y   |  Y   |  Y   |
|                    | WASM 扩展                      | Beta   |  Y   |  Y   |  Y   |
|                    | WAF                            | Alpha  |  Y   |  Y   |  Y   |
| **可观测性**       |                                |        |      |      |      |
|                    | 服务指标                       | Stable |  N   |  N   |  Y   |
|                    | 服务拓扑                       | Stable |  N   |  N   |  Y   |
|                    | 服务追踪                       | Stable |  N   |  N   |  Y   |
| **服务注册中心**   |                                |        |      |      |      |
|                    | 库伯内特服务                   | Stable |  N   |  Y   |  Y   |
|                    | Istio 服务条目                 | Beta   |  N   |  Y   |  Y   |
| **虚拟机工作负载** |                                |        |      |      |      |
|                    | 基于 tctl 的虚拟机载入         | Beta   |  N   |  Y   |  N   |
|                    | EC2 的工作负载入门             | Beta   |  N   |  Y   |  N   |
|                    | 本地工作负载的工作负载入门     | Beta   |  N   |  Y   |  N   |
|                    | ECS 的工作负载载入             | Beta   |  N   |  Y   |  N   |