---
title: 角色和权限
description: 如何设置与 TSB 资源相关的角色和权限。
weight: 5
---

TSB 提供了细粒度的权限管理，以控制对 TSB 资源的访问。你可以授予对资源（如[组织](../../../concepts/glossary/)、[租户](../../../concepts/glossary/)、[工作空间](../../../concepts/glossary/)等）的访问权限。一组权限可以放入[角色](../../../refs/tsb/rbac/v2/role#role)中，然后可以重复使用这些角色来分配权限给适当的资源，例如用户或团队。一旦定义了角色，就可以使用[访问绑定](../../../refs/tsb/rbac/v2/yaml)对象将角色绑定到一组用户或团队。

## 资源模型

为了了解如何处理 TSB 权限，你首先需要了解 TSB 中资源的模型。

在 TSB 中，资源被建模为一个分层树，其中组织是所有资源的根。组织包含一个或多个集群、租户、团队和用户。租户包含一个或多个工作空间。最后，工作空间可以包含一个或多个网关组、流量组和安全组。

{{<callout note 注意>}}
在本文档中，术语“配置组”用于指代所有网关组、流量组和安全组。
{{</callout>}}

![TSB 资源层次结构](../../../assets/operations/tsb_resources.png)

## 角色

[角色](../../../refs/tsb/rbac/v2/role)是一组针对特定资源的权限。例如，你可以创建一个允许对工作空间进行读/写权限的角色，并且对其父租户仅允许读权限。

下面是可用的权限列表：

| 权限（操作） | 描述                              |
| ------------ | --------------------------------- |
| `Read`       | 允许读取资源。                    |
| `Write`      | 允许更新资源。                    |
| `Create`     | 允许创建子资源。[(*1)](#remark-1) |
| `Delete`     | 允许删除资源。                    |
| `SetPolicy`  | 允许将资源的控制委派给其他用户。  |

<a name="remark-1" />(*1) 当用户创建子资源时，用户将被授予新创建的资源的所有权，因此对它们具有完全控制权。

TSB 附带了一些内置角色，具有一组最常见情况的权限：

| 角色   | 读取 | 写入 | 创建 | 删除 | SetPolicy |
| ------ | :--: | :--: | :--: | :--: | :-------: |
| 管理员 |  ✓   |  ✓   |  ✓   |  ✓   |     ✓     |
| 编辑   |  ✓   |  ✓   |  ✓   |      |           |
| 创建者 |  ✓   |      |  ✓   |      |           |
| 写手   |  ✓   |  ✓   |      |      |           |
| 读者   |  ✓   |      |      |      |           |

`管理员`和`编辑`角色都旨在赋予资源树的所有权（完全控制）。但是，`管理员`角色适用于系统管理员，而`编辑`角色适用于仅拥有资源树的用户或团队。

`创建者`角色适用于可以创建自己的资源并查看其他资源的用户。例如，具有`创建者`角色的用户可以读取工作空间中的所有资源，包括由其他用户创建的资源，但对于他们在该工作空间中创建的资源拥有完全所有权。

相比之下，`写手`角色只允许用户读取和修改现有资源，但不允许创建新资源。

最后，`读者`角色仅允许用户读取现有资源。他们将无法执行其他操作。

## 访问绑定

在 TSB 中，[访问绑定](../../../refs/tsb/rbac/v2/access-bindings)对象定义了一组[角色](../../../refs/tsb/rbac/v2/role)与特定TSB资源的一组用户/团队之间的绑定。下面显示了`AccessBinding`的示例。在指定目标资源、角色、用户和团队时，需要使用 FQN。

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/myorg/tenants/mytenant/workspaces/w1
spec:
  allow:
  - role: rbac/admin
    subjects:
    - user: organizations/myorg/users/alice
    - team: organizations/myorg/teams/platform-team
    - serviceAccount: organizations/myorg/serviceaccounts/sa
```

角色定义了对资源的权限集，而访问绑定定义了与特定资源相关的一组用户/团队关联的角色。由于团队成员可以更轻松地动态更改，因此通常建议你将权限分配给团队而不是用户，以便具有更大的灵活性。

{{<callout warning 注意>}}
TSB 将**自动**为上述任何资源创建一个访问绑定对象，当创建新资源时。这个访问绑定将将创建资源的用户设置为管理员。

例如，如果你创建了一个租户，TSB 将创建一个`AccessBindings`，将你设置为租户的管理员。

**请勿**创建新的访问绑定，如果你想将权限授予你的团队，因为你将会覆盖自动创建的访问绑定。为确保不会意外覆盖自动创建的访问绑定，请首先获取目标访问绑定 `tctl get`，编辑必要部分，然后使用 `tctl apply` 应用。
{{</callout>}}

## 完全限定名称

为了明确定义

一个资源，每个资源都有一个完全限定名称（FQN），描述了它们在资源层次结构中的位置。这些名称在你将在示例中使用的对象定义中使用。

以下显示了每个资源使用的命名模式。

| 资源        | FQN                                                          |
| ----------- | ------------------------------------------------------------ |
| 角色        | `rbac/<role name>`                                           |
| 组织        | `organizations/<org name>`                                   |
| 集群        | `organizations/<org name>/clusters/<cluster name>`           |
| 服务        | `organizations/<org name>/services/<service name>`           |
| 团队        | `organizations/<org name>/teams/<team name>`                 |
| 用户        | `organizations/<org name>/users/<user name>`                 |
| 服务帐户    | `organizations/<org name>/serviceaccounts/<service account name>` |
| WASM 扩展    | `organizations/<org name>/extensions/<extension name>`       |
| 租户        | `organizations/<org name>/tenants/<tenant name>`             |
| 工作空间    | `organizations/<org name>/tenants/<tenant name>/workspaces/<workspace name>` |
| 应用程序    | `organizations/<org name>/tenants/<tenant name>/applications/<application name>` |
| API         | `organizations/<org name>/tenants/<tenant name>/applications/<application name>/apis/<api name>` |
| 网关组      | `organizations/<org name>/tenants/<tenant name>/workspaces/<workspace name>/gatewaygroups/<group name>` |
| 安全组      | `organizations/<org name>/tenants/<tenant name>/workspaces/<workspace name>/securitygroups/<group name>` |
| 交通组      | `organizations/<org name>/tenants/<tenant name>/workspaces/<workspace name>/trafficgroups/<group name>` |
| Istio 内部组 | `organizations/<org name>/tenants/<tenant name>/workspaces/<workspace name>/istiointernalgroups/<group name>` |

## 使用角色和权限

当你首次安装 TSB 时，你将使用具有超级管理员特权的平台管理员帐户。出于明显的原因，你不希望让组织的其他成员使用此帐户使用 TSB。你应该创建新用户和团队，或使用从你的 IdP（身份提供者）（如 LDAP、Azure AD 或其他）导入的用户。

在本节中，你将了解如何将角色和权限分配给你的团队的常见场景。出于演示目的，示例将通过使用`tctl`命令行执行，但你可以通过 Web UI 配置 TSB，效果相同。

对于此示例，请假设你要配置 TSB 以具有以下团队和相应的设置：

| 团队     | 描述                                                         |
| -------- | ------------------------------------------------------------ |
| 平台团队 | 成员充当组织管理员。他们可以创建租户、工作空间、配置组，并授予特定团队对这些资源的访问权限 |
| 应用团队 | 成员能够配置运行在特定命名空间中的应用程序。具体来说，他们拥有工作空间中的特定流量组的所有权。 |
| 安全团队 | 成员能够读取租户下的所有内容，并在工作空间中配置安全组设置。 |

示例将引导你逐步配置权限。你需要完成以下所有步骤才能实现所需状态。

请假设在此示例中提到的租户、工作空间、配置组、用户和团队已经创建。另外，请注意，这不是实现相同效果的唯一方法。可能存在满足上述条件的一些角色、权限和绑定的组合。

### 使用访问绑定的注意事项

在下面的示例中，请务必使用_现有_访问绑定对象，而不是创建新的访问绑定对象。每个资源都存在一个访问绑定。如果创建新的绑定对象，你将实际上覆盖现有的绑定，在大多数情况下应避免这样做。

相反，当你被指示在以下示例中编辑访问绑定时，请确保首先使用 `tctl get` 获取绑定，进行编辑，然后使用 `tctl apply` 应用。

例如，如果你正在使用组织`AccessBindings`，首先获取目标绑定：

```bash
tctl get accessbindings organizations/myorg -o yaml > bindings.yaml
```

然后在进行编辑后，应用绑定：

```bash
tctl apply -f bindings -o yaml > bindings.yaml
```

要获取目标租户的`AccessBindings`，你将使用`tctl get accessbindings organizations/myorg/tenants/tenant1 -o yaml`。对于层次结构中下面的其他资源，你需要提供正确的 FQN。

### 配置平台团队

作为超级管理员用户，你将首先创建平台团队，然后执行任何操作。授予平台团队对必要资源的管理员角色。

在此示例中，将在特定组织`myorg`上授予平台团队 Admin 角色。获取有关预期组织的`AccessBindings`对象，并添加平台团队（`orgnizations/myorg/teams/platform`）：

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/myorg
spec:
  allow:
  - role: rbac/admin
    subjects:
    - team: organizations/myorg/teams/platform
      ...
```

使用 `tctl apply -f` 应用上述配置。

其余示例假设上述平台团队已准备好所有必要资源，以便配置可以继续进行。

### 配置应用团队和工作空间

应用团队应该能够查看`租户`中的资源，以及能够在工作空间内创建配置组，但不能执行其他操作。在这个示例和其他示例中，假定租户名称为`tenant1`。

要为团队授予对租户的读取权限，请检索用于预期租户的`AccessBindings`对象，并将应用团队添加为读者：

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/myorg/tenants/tenant1
spec:
  allow:
  - role: rbac/reader
    subjects:
    - team: organizations/myorg/teams/app
      ...
```

要为团队授予对工作空间的创建权限，请检索用于预期工作空间的`AccessBindings`对象，并将应用团队添加为创建者：

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/myorg/tenants/tenant1/workspaces/w1
spec:
  allow:
  - role: rbac/creator
    subjects:
    - team: organizations/myorg/teams/app
```

然后使用 `tctl apply -f` 应用这些配置。

### 配置安全团队和配置组

在前面的部分中，已经指出应用团队只能访问特定的流量组。然而，由于之前的工作空间`AccessBindings`定义将创建者角色授予了应用团队，[他们可以随意创建新的配置组。

在下一个场景中，平台团队想要限制应用团队拥有由他们为其创建的特定流量组。

此外，安全团队应具有对平台团队为其创建的特定安全组的类似权限。

要实现这一目标，请再次检索预期租户的`AccessBindings`，并将安全团队添加为读者，以便他们可以读取租户信息。确保也将应用团队保留在其中。

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/myorg/tenants/tenant1
spec:
  allow:
  - role: rbac/reader
    subjects:
    - team: organizations/myorg/teams/security
    - team: organizations/myorg/teams/app
    ...
```

再次检索预期工作空间的`AccessBindings`。这次从创建者角色中删除应用团队，并将应用团队和安全团队添加为工作空间的读者。

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/myorg/tenants/tenant1/workspaces/w1
spec:
  allow:
  - role: rbac/reader
    subjects:
    - team: organizations/myorg/teams/app
    - team: organizations/myorg/teams/security
    ...
```

然后检索预期的`TrafficGroup`的`AccessBindings`，并将应用团队添加为创建者。假设`TrafficGroup`由平台团队创建。

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/myorg/tenants/tenant1/workspaces/w1/trafficgroups/t1
spec:
  allow:
  - role: rbac/creator
    subjects:
    - team: organizations/myorg/teams/app
    ...
```

类似地，检索并编辑预期的`SecurityGroup`的`AccessBindings`，并将安全团队添加为创建者。假设`SecurityGroup`由平台团队创建。

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/myorg/tenants/tenant1/workspaces/w1/securitygroups/s1
spec:
  allow:
  - role: rbac/creator
    subjects:
    - team: organizations/myorg/teams/security
    ...
```

然后使用 `tctl apply -f` 应用这些对象。

一旦所有内容都成功应用，你应该已经在所需的配置中使用了 TSB。

你可以使用以下命令来应用上述配置文件（例如，将配置文件保存为 `config.yaml`）：

```bash
tctl apply -f config.yaml
```

这将会应用配置文件中定义的权限和角色配置。请确保你在执行此操作之前已经创建了所需的资源，如团队、租户、工作空间、配置组等。一旦配置成功应用，TSB 将按照你的需求进行配置。
