---
weight: 2
title: "注册工作负载"
---

本文将指导你在 SPIRE 服务器中使用 SPIFFE ID 注册工作负载。

## 如何创建注册条目

注册条目包含以下内容：

- SPIFFE ID
- 一个或多个选择器集合
- 父级 ID

服务器将向代理发送所有有权在该节点上运行的工作负载的注册条目列表。代理缓存这些注册条目并保持其更新。

在工作负载认证期间，代理会发现选择器并将其与缓存的注册条目中的选择器进行比较，以确定应该为工作负载分配哪些 SVID。

你可以通过在命令行中发出 `spire-server entry create` 命令或直接调用 Entry API 来注册工作负载，具体方法请参阅 [Entry API 文档](https://github.com/spiffe/spire-api-sdk/blob/v1.8.2/proto/spire/api/server/entry/v1/entry.proto)。可以使用 `spire-server entry update` 命令修改现有条目。

在 Kubernetes 上运行时，调用 SPIRE 服务器的常见方法是通过在运行 SPIRE 服务器的 Pod 上使用`kubectl exec`命令。例如：

```bash
kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ns/default/sa/default \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s:ns:default \
```

有关 `spire-server entry create` 和 `spire-server entry update` 命令和选项的更多信息，请参阅 [SPIRE 服务器参考指南](https://spiffe.io/docs/latest/deploying/spire_server/)。

## 如何注册工作负载

通过在 SPIRE 服务器中创建一个或多个注册条目来注册工作负载。要注册工作负载，需要告诉 SPIRE：

1. 分配给在工作负载有权运行的节点上运行的代理的 SPIFFE ID。
2. 运行在这些机器上的工作负载本身的属性。

### 1. 定义代理的 SPIFFE ID

分配给代理的 SPIFFE ID 可能是作为节点认证过程的一部分自动分配的 ID。例如，当代理经过 AWS IID 节点认证时，会自动分配形式为 `spiffe://example.org/agent/aws_iid/ACCOUNT_ID/REGION/INSTANCE_ID` 的 SPIFFE ID。

或者，可以通过创建一个指定了选择器的[注册条目](https://spiffe.io/docs/latest/deploying/registering/#create-registration-entry)来为一个或多个代理分配 SPIFFE ID。例如，可以通过创建以下注册条目将 SPIFFE ID  `spiffe://acme.com/web-cluster` 分配给在标记 `app` 设置为 `webserver` 的一组 EC2 实例上运行的任何 SPIRE 代理：

```bash
spire-server entry create \
    -node \
    -spiffeID spiffe://acme.com/web-cluster \
    -selector tag:app:webserver
```

选择器是 SPIRE 可以在发出身份之前验证的节点或工作负载的本机属性。单个注册条目可以包含节点选择器或工作负载选择器，但不能同时包含两者。请注意上述命令中的 `-node` 标志，它表示此命令正在指定节点选择器。

根据工作负载应用程序运行的平台或架构，提供了不同的选择器。

| 平台       | 请访问                                                       |
| ---------- | ------------------------------------------------------------ |
| Kubernetes | [GitHub](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_k8s_sat.md) |
| AWS        | [GitHub](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_nodeattestor_aws_iid.md) |
| Azure      | [GitHub](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_server_noderesolver_azure_msi.md) |

### 2. 定义工作负载的 SPIFFE ID

一旦代理或代理有一个分配的 SPIFFE ID，就可以创建另一个注册条目来标识在调用该代理公开的工作负载 API 时的特定工作负载。

例如，要创建一个注册条目，以匹配在标识为 `spiffe://acme.com/web-cluster` 的代理上运行的 Unix 组 ID 1000 下运行的 Linux 进程，可以使用以下命令：

```bash
spire-server entry create \
    -parentID spiffe://acme.com/web-cluster \
    -spiffeID spiffe://acme.com/webapp  \
    -selector unix:gid:1000
```

| 平台       | 请访问                                                       |
| ---------- | ------------------------------------------------------------ |
| Unix       | [GitHub](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_workloadattestor_unix.md) |
| Kubernetes | [GitHub](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_workloadattestor_k8s.md) |
| Docker     | [GitHub](https://github.com/spiffe/spire/blob/v1.8.2/doc/plugin_agent_workloadattestor_docker.md) |

## 如何列出注册条目

要列出所有现有的注册条目，请使用命令 `spire-server entry show`。

要将注册条目筛选为与特定 SPIFFE ID、父级 SPIFFE ID 或注册条目 ID 匹配的条目，请分别使用 `-spiffeID`、`-parentID`、`-selector` 或 `-entryID` 标志。

请注意，每个注册条目都有一个唯一的注册条目 ID，但是多个注册条目可以指定相同的 SPIFFE ID。

例如，要列出与标记 `app` 设置为 `webserver` 的一组 EC2 实例匹配的所有注册条目，请运行以下命令：

```bash
spire-server entry show -selector tag:app:webserver
```

有关 `spire-server entry show` 命令和选项的更多信息，请参阅[SPIRE 服务器参考指南](https://spiffe.io/docs/latest/deploying/spire_server/)。

## 如何删除注册条目

要永久删除现有的注册条目，请使用 `spire-server entry delete` 命令，并指定相关的注册条目 ID。

例如：

```bash
spire-server entry delete -entryID 92f4518e-61c9-420d-b984-074afa7c7002
```

有关 `spire-server entry delete` 命令和选项的更多信息，请参阅  [SPIRE 服务器参考指南](https://spiffe.io/docs/latest/deploying/spire_server/)。

## 将工作负载映射到多个节点

工作负载注册条目可以有一个父级 ID。这可以是特定节点的 SPIFFE ID（即通过节点认证获得的代理的 SPIFFE ID），也可以是节点注册条目（有时称为节点别名/集合）的 SPIFFE ID。节点别名（或集合）是具有相似特征的一组节点，它们被赋予了一个共享的身份。节点注册条目具有节点选择器，要求节点至少具有这些选择器才能符合共享的身份。这意味着具有至少与节点注册条目中定义的选择器相同的任何节点都被赋予该别名（或属于该节点集）。当工作负载注册条目使用节点别名的 SPIFFE ID 作为父级时，具有该别名的任何节点都有权为该工作负载获取 SVID
