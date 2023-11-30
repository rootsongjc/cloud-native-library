---
title: 创建安全域
description: 学习何时以及如何使用安全域（Security Domains）。
weight: 10
---

## 什么是安全域（Security Domains）？

**安全域（Security Domains）** 允许你在配置层次结构的任何位置 - [租户](../../refs/tsb/v2/tenant#tetrateio-api-tsb-v2-tenant)、[工作区](../../refs/tsb/v2/workspace#tetrateio-api-tsb-v2-workspace) 或 [安全组](../../refs/tsb/security/v2/security-group#tetrateio-api-tsb-security-v2-group) - 创建跨 [TSB 层次结构](../../concepts/security#tenancy) 的配置分组。将 `securityDomain` 视为可以附加到这些 TSB 资源中的名称，然后可以在 TSB 规则中使用它们。

一旦资源被标识为具有 `securityDomain`，就可以在创建规则时将安全域用作源或目标。这允许 Operator 在新对象创建时在 **Tetrate Service Bridge (TSB)** 层次结构中持续建立一组要求。

## 何时应该使用安全域（Security Domains）？

随着服务网格的扩展，你需要执行的策略数量也会增加。在某些情况下，这些安全控制与你当前的 TSB 层次结构选择不太匹配：你有一组服务、工作区和租户，共享一组公共安全控制。

安全域（Security Domains）为你提供了创建单一的 [授权规则](../../refs/tsb/security/v2/security-setting#tetrateio-api-tsb-security-v2-authorizationrules) 的能力，该规则可以使用它们共享的 `securityDomain` 名称来处理多个租户、工作区和安全组。然后，你可以使用简单的 [from](../../refs/tsb/security/v2/security-setting#tetrateio-api-tsb-security-v2-rule-from) 和 [to](../../refs/tsb/security/v2/security-setting#tetrateio-api-tsb-security-v2-rule-to) 子句创建广泛和包容性的规则，反映高级访问控制意图。

## 使用安全域（Security Domains）

**注意：下面的示例假设你已经知道如何 [创建租户](../../quickstart/tenant)。**

我们从一个简单的单集群 TSB 部署开始，其中有两个租户 `dev_US_East` 和 `stg_US_East`，代表开发和暂存环境。随着我们对 TSB 的使用增加，我们想要添加一个用于冗余的美国西部集群，这将需要我们创建两个新租户：`dev_US_West` 和 `stg_US_West`。

![初始计划 - 安全域（Security Domains）](../../assets/security-domains-1.png)

我们将使用安全域（Security Domains）来创建一个简单的、广泛的授权规则，允许来自所有 `stg` 暂存租户的流量到达所有 `dev` 开发租户。

**步骤 1** 在编辑你的 `tenant.yaml` 文件中，为新创建的租户添加 `dev` 和 `stg` 安全域（Security Domains）

```yaml
kind: Tenant
metadata:
 organization: tetrate
 tenant: dev_US_West
spec:
 displayName: Dev US West
 securityDomain: organizations/tetrate/securitydomains/dev
 ---
kind: Tenant
metadata:
 organization: tetrate
 tenant: stg_US_East
spec:
 displayName: Stg US West
 securityDomain: organizations/tetrate/securitydomains/stg
```

**步骤 2** 使用 `tctl edit organizationsettings` 添加所需的 `dev` 和 `stg` 安全域（Security Domains）之间的规则

在这个示例的 TSB 环境中，我们想要确保流量可以从暂存租户到达开发租户，但流量不能从开发租户到达暂存租户。如果没有安全域（Security Domains），我们需要在每个租户之间创建单独的规则，创建、管理和验证这些规则的复杂性会随着租户数量的增加而增加。使用安全域（Security Domains），我只需要将每个租户与适当的 `securityDomain` 关联起来。我的授权规则然后将 `securityDomain` 作为 `from` 和 `to` 子句中的目标引用：

```yaml
kind: OrganizationSetting
metadata:
 displayName: tetrate-settings
 name: tetrate-settings
 organization: tetrate
 resourceVersion: '"XI8Jtnl6JaE="'
spec:
 defaultSecuritySetting:
  authorization:
   mode: RULES
   rules:
    allow:
    - from:
      fqn: organizations/tetrate/securitydomains/stg
     to:
      fqn: organizations/tetrate/securitydomains/dev
 displayName: tetrate-settings
 etag: '"XI8Jtnl6JaE="'
 fqn: organizations/tetrate/settings/tetrate-settings
```

最后一步是可选的，但为了完整起见或者如果你关心现有租户之间的流量存在的话，建议执行此步骤。

**步骤 3** 测试新租户之间的行为并编辑你的 `tenant.yaml` 文件，将现有租户添加到新创建的安全域（Security Domains）

更新你的 `tenant.yaml` 文件，将你现有的租户添加到新创建的安全域（Security Domains）中。

```yaml


kind: Tenant
metadata:
 organization: tetrate
 tenant: dev_US_West
spec:
 displayName: Dev US West
 securityDomain: organizations/tetrate/securitydomains/dev
---
kind: Tenant
metadata:
 organization: tetrate
 tenant: stg_US_East
spec:
 displayName: Stg US West
 securityDomain: organizations/tetrate/securitydomains/stg
```

### 我们取得了什么成就？

我们成功配置了我们的新 *US West* 租户，并将它们添加到了它们各自的安全域（Security Domains）`dev` 和 `stg` 中。随着我们添加更多的 `dev` 和 `stg` 租户对，我们可以将它们与适当的 `securityDomain` 关联起来。TSB 将自动扩展授权规则，以在所有租户上应用访问控制。

![跨租户的安全域（Security Domains）](../../assets/security-domains-2.png)

### 安全域（Security Domains）的未来是什么？

:::note 早期特性实施
安全域（Security Domains）是 Tetrate Service Bridge 1.6 中的一项新功能。随着我们解锁其他用例和可视化，实现可能会在后续版本中得到扩展。
:::

上面的示例只是展示了使用 **安全域（Security Domains）** 可以实现的一小部分功能。虽然它们在简化大型环境中创建授权规则的任务方面取得了重大进展，但即使安全域关系也最终可能变得复杂。Tetrate 正在考虑通过 UI 可视化和其他扩展来使安全域更具可伸缩性和更容易准确配置，从而实现丰富的用例：

![安全域的完整用例](../../assets/security-domains-3.png)

如果你正在使用安全域（Security Domains），Tetrate 非常愿意听取你的意见。请通过你的 Tetrate 帐户团队联系我们。
