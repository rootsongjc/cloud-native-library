---
title: YAML API 指南
description: 介绍如何使用我们的 YAML API 与 TSB 进行通信的指南。
weight: 1
---

在本指南中，你将学习如何使用 TSB CLI（`tctl`）执行常见操作。你将学习如何配置 CLI 以访问你的 TSB 安装，并如何从命令行管理 TSB 资源。

## 入门

要使用 YAML API，你需要安装并配置 TSB CLI。一旦你安装并配置了 CLI 以与你的 TSB 安装进行通信，你将需要使用 `tctl login` 命令配置对 TSB 平台的访问权限：

```bash
tctl login
```

你将被要求提供 TSB 组织名称，这在 TSB 安装过程中已设置或提供给你，租户名称以及凭据。

平台管理员应该已经为你分配了一个租户。如果没有，或者你是执行初始设置的管理员，可以将租户留空。你始终可以稍后编辑已配置的用户并在需要时设置租户。

```text
Organization: tetrate
Tenant:
Username: admin
Password:
Login Successful!
  Configured user: demo-admin
  User "demo-admin" enabled in profile: demo
```

{{<callout note 重要提示>}}
用户设置中预先配置的组织和租户仅用于 `tctl get` 和 `tctl delete` 命令。在使用 `tctl apply` 创建或修改资源时，组织和租户将从每个资源的 **metadata** 部分中获取，如下所示。
{{</callout>}}

## YAML API 基础知识

TSB YAML API 具有声明性语义。所有 TSB 对象共享一组用于唯一标识资源在资源层次结构中位置的属性，以及一个特定的模型，其中包含属于该特定资源的值。例如，以下 TSB 资源配置了给定流量组的流量设置：

```yaml
# 块 1 - 资源类型
apiVersion: traffic.tsb.tetrate.io/v2
kind: TrafficSetting
# 块 2 - 资源元数据
metadata:
  name: defaults
  group: helloworld
  workspace: helloworld
  tenant: tetrate
  organization: tetrate
# 块 3 - 资源内容
spec:
  reachability:
    mode: GROUP
  resilience:
    circuitBreakerSensitivity: MEDIUM
```

- 第一个块（`apiVersion` 和 `kind`）标识资源的类型。
- 第二个块定义了资源的 `metadata`。所有资源都有一个 `name` 和一组配置资源在资源层次结构中所属位置的元数据属性。
- 第三个块（`spec`）包含了资源对象的实际内容。

### 应用资源

资源是使用 `tctl apply` 命令应用的。如果应用的资源尚不存在，这将创建它。如果资源已经存在，则该命令将替换其中包含的信息。

{{<callout note 注意>}}
更新操作是完整的对象更新。必须在每次应用操作中发送整个对象，不支持部分更新。
{{</callout>}}

在应用资源时，父资源也必须存在。如果 `apply` 请求包含多个资源，则必须以正确的顺序提供它们，以确保操作不会因资源缺少其父资源而失败。以下示例显示了如何在现有组织中创建租户和工作空间：

```bash
tctl apply -f - <<EOF
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: tetrate    # 此组织必须存在
  name: example-tenant     # 要创建的租户的名称
spec:
  displayName: Example Tenant
  description: An example tenant for the YAML guide
---
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: example-tenant   # 上面的租户名称
  name: first-workspace    # 要创建的工作空间的名称
spec:
  displayName: First Workspace
  description: An example workspace
  namespaceSelector:
    names:
      - "*/default"
---
EOF
```

### 列出和获取资源

`tctl get` 命令检索资源。如果未指定名称，将返回所请求类型的所有资源。如果给定了特定名称，则仅返回请求的资源。

get 命令的语法为：`tctl get <resource type> <parameters>`

其中参数包括可选的资源名称以及配置资源层次结构中资源所属位置的必要标志。

该命令还接受多个输出参数，以以表格形式（默认）、YAML 或 JSON 检索对象：

#### 获取配置的租户中的所有工作空间

```bash
tctl get workspace
```

示例输出：

```text
NAME        DISPLAY NAME  DESCRIPTION
helloworld  Helloworld    Helloworld application
bookinfo    Bookinfo      Bookinfo application
```

#### 获取工作空间的详细信息

```bash
tctl get workspace helloworld -o yaml
```

示例输出：

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  description: Helloworld application
  displayName: Helloworld
  name: helloworld
  organization: tetrate
  resourceVersion: '"BePMGaj00FM="'
  tenant: tetrate
spec:
  description: Helloworld application
  displayName: Helloworld
  etag: '"BePMGaj00FM="'
  fqn: organizations/tetrate/tenants/tetrate/workspaces/helloworld
  namespaceSelector:
    names:
    - '*/helloworld'
```

#### 获取给定流量组中的所有服务路由

注意，我们需要提供标志来指定我们要获取服务路由的工作空间和组：

```bash
tctl get serviceroute \
    --workspace helloworld \
    --trafficgroup helloworld -o yaml
```

示例输出：

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  group: helloworld
  name: hello
  organization: tetrate
  resourceVersion: '"NWEYABT/fjM="'
  tenant: tetrate
  workspace: helloworld
spec:
  etag: '"NWEYABT/fjM="'
  fqn: organizations/tetrate/tenants/tetrate/workspaces/helloworld/trafficgroups/helloworld/serviceroutes/hello
  service: helloworld/helloworld.helloworld.svc.cluster.local
  subsets:
  - labels:
      version: v1
    name: v1
    weight: 80
  - labels:
      version: v2
    name: v2
    weight: 20
```

### 删除资源

`tctl delete` 命令用于删除资源。它遵循与 tctl get 命令相同的语义，只是需要名称参数。

:::warning
请注意，删除资源将删除资源及其所有子对象，因此请谨慎使用，特别是在删除资源位于资源层次结构较高级别时。
:::

假设你已经有一个现有的 `trafficgroup`，你可以使用以下命令查询：

```bash
tctl get trafficgroup --workspace test
```

示例输出：

```text
NAME     DISPLAY NAME  DESCRIPTION
test-tg  test-tg       et-tg
```

要删除 `trafficgroup`：

```bash
tctl delete trafficgroup test-tg --workspace test
```

再次查询它：

```bash
tctl get trafficgroup -w test
No resources found
```