---
title: 使用调试容器
Description: 如何运行和使用调试容器。
weight: 4
---

Tetrate Service Bridge (TSB) 是一个由各种协议相互连接的复杂组件集合。对于部署在 TSB 提供的服务网格上的应用程序来说，情况可能也是如此。在许多情况下，你需要检查、测试和验证各种 TSB 组件之间的网络连通性，以确保系统按预期工作。

为了为你节省在 Kubernetes 集群中创建调试环境的时间，Tetrate 提供了一个调试容器，其中已经安装了大多数用于验证网络状态的工具集。例如，诸如 `ping`、`curl`、`gpcurl`、`dig` 等工具已经在此容器中安装。

## 使用调试容器

只要可以访问适当的镜像仓库来下载容器镜像，这个调试容器就可以部署到任何集群中。

容器镜像包含在 TSB 发行版中，并且将与运行 [`tctl install image-sync` 命令](../../setup/requirements-and-download#sync-tetrate-service-bridge-images) 时的其余镜像一起同步到你的仓库中。

要部署调试容器，请运行以下命令。将 `<registry-location>` 替换为你同步了 TSB 镜像的仓库 URL。

```bash
kubectl run debug-container --image <registry-location>/tetrate-troubleshoot:${vars.versionNumber} -it -- ash
```

一旦创建了 Pod，你将被置于调试容器内的 shell 中，并且你可以运行必要的故障排除命令。

### 检查网络连通性

如果你想要检查 TSB 集群到你使用的数据存储（我们假设在此示例中是 PostgreSQL）的网络连通性，你可以运行以下命令：

```bash
curl -v telnet://<postgres_IP>:5432
```

或者使用 PostgreSQL 客户端命令 `psql` 来验证凭据。

```bash
psql -h my.postgres.local -P 5432 -U myUser
```
