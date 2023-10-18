---
title: 扩展安全策略
weight: 6
---

Tetrate 允许你创建一个明确定义、准确可持续发展的安全策略，可以与你的 Tetrate 管理的系统平滑地同步发展。

平台所有者（"Platform"）和应用程序所有者（"Apps"）共同合作创建你的安全策略的元素：

1. 识别安全阻塞
   应用程序所有者识别当前 Tetrate 安全策略阻止的必需流量。

2. 应用安全规则
   平台所有者验证所需的安全例外，并使用 Tetrate API 实施它。

3. 审计安全规则
   定期，平台所有者可能希望审计当前的安全策略，以确保它们足以满足安全和合规性需求。

## 平台：开始之前

本指南将涵盖在零信任环境中的工作负载之间配置访问控制。工作负载通过 Istio 提供的 Tetrate 平台发放和更新 SPIFFE 标识进行身份验证。本指南不涵盖 JWT、OAuth 或 OIDC 用户身份验证等更高级别的功能。

指南从推荐的起始姿态开始：

* 所有工作负载都使用 SPIFFE 标识，并且对于所有流量，都需要 mTLS。这意味着外部第三方（如集群中的其他服务或具有对数据路径的访问权限的服务）无法读取事务、修改事务或冒充客户端或服务。
* 默认情况下，所有通信都被拒绝，只有解锁了工作区，并且内部流量是允许的。
* 默认的安全传播策略是 REPLACE

### 你需要了解的内容

使用 **SecuritySetting** 部分配置 Tetrate 安全姿态。这些部分以资源的层次结构呈现：

1. 组织级别的 [**OrganizationSetting/defaultSecuritySetting**](https://docs.tetrate.io/service-bridge/refs/tsb/v2/organization_setting)
1. 租户级别的 [**TenantSetting/defaultSecuritySetting**](https://docs.tetrate.io/service-bridge/refs/tsb/v2/tenant_setting)。一个组织可以包含多个租户。
1. 每个工作区级别的 [**WorkspaceSetting/defaultSecuritySetting**](https://docs.tetrate.io/service-bridge/refs/tsb/v2/organization_setting)。一个租户包含多个工作区。
1. 每个安全组级别的 [**SecuritySetting**](https://docs.tetrate.io/service-bridge/refs/tsb/security/v2/security_setting)。安全组允许将工作区细分为更小的命名空间集合。
1. 每个服务级别的 [**ServiceSecuritySetting**](https://docs.tetrate.io/service-bridge/refs/tsb/security/v2/service_security_setting)。在安全组内，可以为单个服务应用规则。

在每个资源中，你可以配置一个 [**SecuritySetting**](https://docs.tetrate.io/service-bridge/refs/tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting) 部分。

### 传播策略

有关更多信息，请参阅[传播策略](https://docs.tetrate.io/service-bridge/refs/tsb/types/v2/types#tetrateio-api-tsb-types-v2-propagationstrategy)文档。

### 常见做法

在配置安全策略时，有两种常见做法：

1. **自上而下，开放工作区**
   
    首先定义高级别的默认值：

    * 在 **OrganizationSetting/defaultSecuritySetting** 中设置 **denyAll**，并将 **propagationStrategy** 设置为 **REPLACE**
    * 在 **WorkspaceSetting/defaultSecuritySetting** 中设置 **mode: WORKSPACE** 以允许工作区之间的通信，

2. **自下而上，细粒度规则**
   
    定义初始姿态：

    * 不要在组织级别启用 'Deny-All'，但是将 **propagationStrategy** 设置为 **STRICTER**。
    
    一旦在较低级别定义了 **Allow** 规则，那些不匹配该规则的请求将被拒绝，然后将这个拒绝传播到默认情况下拒绝所有其他请求的层次结构中。然后，你可以维护一个显式的 Allow 规则列表，知道其他所有东西都将被拒绝。

    这种方法更难以管理，因为你需要声明每个 **Allow** 规则，但它提供了更严格的安全性。

## 应用程序：识别安全阻塞

当你希望访问目标服务时，你需要知道该服务的 FQDN（全限定域名）。通常情况下，这会在 Tetrate 服务注册表中列出，但也可能以其他形式存在，例如 **ServiceEntry**。服务所有者应该能够提供 FQDN。

在调试访问控制问题时，你可以从客户端容器向目标服务发出简单的 HTTP 请求开始：

```bash
CLIENT=$(kubectl get pod -n bookinfo -l app=ratings -o jsonpath='{.items[0].metadata.name}')

kubectl exec $CLIENT -n bookinfo -c ratings -- \
  curl -s productpage.bookinfo.svc.cluster.local:9080/productpage
# 如果 Tetrate 策略拒绝访问，则期望响应为 'RBAC: access denied'
```

如果客户端的 **curl** 命令得到文本响应 `RBAC: access denied`，则表示 Tetrate 平台配置正在阻止访问。其他错误是由其他（非访问控制）原因引起的。

### 定义安全策略

安全策略是从目标服务的角度定义的；它们定义了哪些客户端被允许访问目标。目标服务的所有者应该要求平台所有者向阻止访问的 "拒绝访问" 安全策略中添加一个适当的例外，以便客户端可以访问目标服务。

_对于客户端和目标服务都是如此，平台所有者需要知道：_

1. 服务 **名称**
1. 服务 **serviceAccount**（```kubectl get pod -n bookinfo podname -o jsonpath="{.spec.serviceAccount}")```)
1. 服务所在的 **命名空间** 和 **集群**
1. Tetrate **工作区**

平台所有者将根据其安全实践确定适当的安全规则来打开所请求的流量。安全规则可以基于服务到服务、命名空间到命名空间、工作区到工作区或各种组合。

## 平台：应用安全规则

安全规则是从目标服务的角度进行配置的。它们可以基于工作区中的安全组，也可以是单独的 Kubernetes 服务账户。Tetrate 平台会积累这些规则，遵循每个级别的 **propagationStrategy**，并生成完整的安全策略。该策略使用集群内和集群之间的 Istio 配置来实施。

在构建规则时，请考虑以下两个问题：

| 目标是什么？           | 如何定义规则的位置                                           |
| ---------------------- | ------------------------------------------------------------ |
| 工作区中的所有命名空间 | 更新 **WorkspaceSetting/defaultSecuritySetting** 中的 **authorization** 部分。<br/>或者，你可能希望将 **WorkspaceSetting/defaultSecuritySetting** 视为不可变的，并在整个工作区范围内的 **安全组** 中进行更改 |
| 工作区中的某些命名空间 | 为目标创建一个适当的 **安全组**，并在附加到该 **安全         |

组** 的 **SecuritySetting** 中更新 **authorization** 部分 |
| 单个命名的服务                    | 为该服务创建一个 **ServiceSecuritySetting**，附加到工作区中的适当 **安全组**。在 **ServiceSecuritySetting** 中更新 **authorization** 部分 |

| 来源是什么？               | 如何定义规则                                                 |
| -------------------------- | ------------------------------------------------------------ |
| 同一命名空间               | 将 **AuthorizationSettings.mode** 设置为 **NAMESPACE**       |
| 同一安全组                 | 将 **AuthorizationSettings.mode** 设置为 **GROUP**           |
| 同一工作区                 | 将 **AuthorizationSettings.mode** 设置为 **WORKSPACE**       |
| 同一集群                   | 将 **AuthorizationSettings.mode** 设置为 **CLUSTER**         |
| 具名的 Kubernetes 服务账户 | 将 **AuthorizationSettings.mode** 设置为 **CUSTOM**，并列出服务账户 |
| 更加细粒度的控制           | 将 **AuthorizationSettings.mode** 设置为 **RULES**，并提供 **allow** 和 **deny** 的工作区和安全组列表 |

首先查看 [**SecuritySetting** 文档](https://docs.tetrate.io/service-bridge/refs/tsb/security/v2/security_setting) 获取一组实际示例和更详细的文档。

#### 在 DIRECT 模式中使用 Istio 原语

对于高级情况，也可以直接使用 Istio 原语定义安全策略。要执行此操作：

* 配置 **Security Group** 使用 **configMode: DIRECT**。这意味着 Tetrate **SecuritySettings** API 无法应用于此组
* 创建 **PeerAuthentication** 和 **AuthorizationPolicy** Istio Security v1beta1 资源，并使用注释将其附加到 **Security Group**

Tetrate 管理平台将会将这些 **DIRECT** 模式配置与其他 **BRIDGED** 模式配置协调一致，并生成适当的数据平面配置。

## 平台：审计安全规则

定期地，你可能希望审计 Tetrate 实施的安全规则。你可以使用几种行业标准工具来可视化规则：

* [Kiali](https://kiali.io/docs/features/security/) 可以检查和可视化生成的 Istio 配置
* Tetrate 平台可以生成源自平台所有者配置的分层访问控制策略的 L3/4 网络策略。然后，可以使用各种第三方 Kubernetes 网络策略可视化工具来检查和可视化这些 L3/4 Kubernetes 网络策略。