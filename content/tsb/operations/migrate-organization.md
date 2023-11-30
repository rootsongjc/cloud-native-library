---
title: 将数据迁移到新的组织
description: 将所有配置、用户和组从一个组织迁移到一个新创建的组织。
weight: 10
---

本文描述了如何将所有配置、用户和组从一个[组织](../../concepts/glossary/)迁移到一个新创建的组织。

## 获取数据

首先，提取每个租户的所有配置。对于每个租户，执行以下命令：

```bash
tctl get all --tenant <tenant> > config.yaml
```

一旦你将所有配置保存在 `config.yaml` 中，请确保手动复制其中的各种绑定（例如 ApplicationAccessBindings、APIAccessBindings 等）到一个名为 `bindings.yaml` 的文件中，并从 `config.yaml` 中删除它们。

这是因为当你稍后使用 `config.yaml` 的内容时，绑定的全限定名称将不存在，这将导致在应用配置时出现错误。绑定必须在将对象移动到新组织后才能应用。

你还需要编辑 `config.yaml`，将文件中每个 `metadata.organization` 字段中的值替换为指向你将要创建的新组织。

如果你正在创建一个新的租户，你还应该更改租户部分。

以下是一个示例 YAML 文件，显示了你的 `config.yaml` 中的一个条目应该是什么样子的。还请注意，下面的 YAML 文件不包含全限定名称、`etag` 和 `resourceVersion`。你还应该从你的 `config.yaml` 中删除这些内容。

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  displayName: Bookinfo app
  name: bookinfo
  organization: ${myorg}
  tenant: ${mytenant}
spec:
  displayName: Bookinfo app
  namespaceSelector:
    names:
    - '*/bookinfo'
```

## 应用配置

编辑 `config.yaml` 后，你需要创建新的组织。创建一个名为 `myorg.yaml` 的文件，其中包含以下内容，将名称替换为你的新组织名称：

```
apiVersion: api.tsb.tetrate.io/v2
kind: Organization
metadata:
  name: <myorg>
```

然后应用新的配置以创建该组织。

```bash
tctl apply -f myorg.yaml
```

对于你旧组织中的每个租户，你需要在新组织中创建一个等效的租户。创建一个包含所需租户的文件。内容应该类似于以下示例，其中组织和租户名称已替换为你环境中的有效值。

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: <myorg>
  name: <mytenant>
```

然后应用新的配置以创建新的租户（们）。示例假定你在文件 `mytenants.yaml` 中列出了所有必要的租户。

```bash
tctl apply -f mytenants.yaml
```

最后，应用存储在你之前编辑的 `config.yaml` 文件中的配置：

```bash
tctl apply -f config.yaml
```

此时，旧组织和新组织都将存在，但只有旧组织将工作，因为你尚未更新管理平面中的配置以指向新组织。

## 载入集群

创建一个名为 `clusters.yaml` 的文件，其内容类似于以下示例，将集群名称和组织替换为你环境中的有效值。为所有应该属于新组织的集群添加更多条目。

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: <cluster>
  organization: <myorg>
  labels:
    env: qa
    tier: one
spec:
  displayName: "Cluster T1"
  network: tier1
  tier1Cluster: true
```

然后应用配置。这将将集群与新组织关联起来。

```bash
tctl apply -f clusters.yaml
```

创建一个名为 `controlplane.yaml` 的文件，其内容类似于以下示例，将集群名称替换为你环境中的有效值。

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  hub: ...
  telemetryStore:
    ...
  managementPlane:
    host: ...
    port: ...
    clusterName: <mycluster>
```

## 同步用户/组

此时，你应该已经将所有集群和控制平面迁移到新组织。现在，你需要将用户和组同步到新组织。为此，创建一个作业，如下所示：

```bash
kubectl create job --from=cronjob/teamsync teamsync -n tsb
```

一段时间后，作业完成后，你将能够从 TSB UI 中查看新组织中的用户和组。

确保从绑定中删除 `tetrate-agents`。从 `bindings.yaml` 中的每个绑定中删除下面示例中显示的部分：

```yaml
- role: rbac/envreader
  subjects:
  - team: organizations/<myorg>/teams/tetrate-agents
```

然后，在完成此操作后，应用这些绑定：

```bash
tctl apply -f bindings.yaml
```

## 迁移组织

此时，你已将所有内容迁移到新组织，但管理平面仍然配置为使用旧组织。

创建一个名为 `managementplane.yaml` 的文件，并指向它以使用新组织：

```
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
  namespace: tsb
spec:
  hub: ...
  organization: <myorg>
  dataStore:
    ...
  telemetryStore:
    ...
  tokenIssuer:
    ...
```

现在是一个好时机，确保你没有错误配置任何内容，因为应用此配置可能导致你的应用断开连接并被关闭。

确保旧组

织中没有尚未应用到新创建组织的缺少配置。例如，如果你配置了 tier1-tier2，则需要明确允许网络从 tier1 到 tier2 进行通信。

一旦你满意，应用新的配置：

```bash
kubectl apply -f managementplane.yaml
```

最后，使用新组织登录到 TSB：

```bash
tctl login
```

一旦你确认一切正常工作，你可以继续删除旧的工作区、租户和组织。

{{<callout note "验证用户与旧组织的关联">}}
如果你已配置了与 TSB 一起使用的外部 LDAP，并且用户仍然在旧组织中进行验证，你需要手动修复存储在 Postgres 中的数据。如果你按照本文档提供的确切顺序执行了步骤，这不应该发生。

**如果你需要修复 Postgres，请确保首先备份数据库**。准备好后，从 Postgres 命令行发出以下命令，将 `<your_old_org>` 替换为旧组织的名称：

```
delete from node where name like '%<your_old_org>%';
```

这将删除所需的表，并通过外键也会删除其他相关数据。
{{</callout>}}
