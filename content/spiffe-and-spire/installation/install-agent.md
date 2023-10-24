---
weight: 3
title: "安装 SPIRE 代理"
---

本文指导你如何在 Linux 和 Kubernetes 上安装 SPIRE Agent。

## 步骤 1：获取 SPIRE 二进制文件

可以在 [SPIRE 下载页面](https://spiffe.io/downloads/#spire-releases) 找到预构建的 SPIRE 发行版。tarball 包含服务器和 Agent 二进制文件。

如果愿意，也可以从源代码 [构建 SPIRE](https://github.com/spiffe/spire/blob/v1.8.2/CONTRIBUTING.md)。

## 步骤 2：安装服务器和 Agent

本入门指南描述了如何在同一节点上安装服务器和 Agent。在典型的生产部署中，服务器安装在一个节点上，而一个或多个 Agent 安装在不同的节点上。

要安装服务器和 Agent：

1. 从 [SPIRE 下载页面](https://spiffe.io/downloads/#spire-releases) 获取最新的 tarball，然后使用以下命令将其解压到 /opt/spire 目录中：

   ```
   wget <https://github.com/spiffe/spire/releases/download/v1.8.2/spire-1.8.2-linux-amd64-musl.tar.gz>
   tar zvxf spire-1.8.2-linux-amd64-musl.tar.gz
   sudo cp -r spire-1.8.2/. /opt/spire/
   ```

2. 为了方便起见，将 `spire-server` 和 `spire-agent` 添加到 $PATH 中：

   ```
   sudo ln -s /opt/spire/bin/spire-server /usr/bin/spire-server
   sudo ln -s /opt/spire/bin/spire-agent /usr/bin/spire-agent
   ```

## 步骤 3：配置 Agent

安装 SPIRE Agent 后，需要根据您的环境进行配置。有关如何配置 SPIRE 的详细信息，请参阅 [配置 SPIRE](https://spiffe.io/docs/latest/spire/using/configuring/)，特别是节点验证和工作负载验证。

请注意，SPIRE Agent 在修改其配置后必须重新启动，以使更改生效。

如果尚未安装 SPIRE Server，请参阅 [安装 SPIRE Server](https://spiffe.io/docs/latest/spire/installing/install-server/) 了解如何安装 SPIRE Server。

## 在 Kubernetes 上安装 SPIRE Agents

必须从包含用于配置的 .yaml 文件的目录中运行所有命令。有关详细信息，请参阅 SPIRE Server 安装指南的 [Obtain the Required Files](https://spiffe.io/docs/latest/spire/installing/install-server/#section-1) 部分。

要在 Kubernetes 上安装 SPIRE Agents，您需要执行以下操作：

1. 创建 Agent 服务账号
2. 创建 Agent 配置映射
3. 创建 Agent DaemonSet

有关详细信息，请参阅以下各节。

### 步骤 1：创建 Agent 服务账号

将 agent-account.yaml 配置文件应用于在 spire 命名空间中创建名为 spire-agent 的服务账号：

```
$ kubectl apply -f agent-account.yaml
```

为了允许代理读取 kubelet API 以执行工作负载验证，必须创建一个 ClusterRole，授予 Kubernetes RBAC 适当的权限，并将 ClusterRoleBinding 关联到上一步创建的服务账号。

1. 通过应用 agent-cluster-role.yaml 配置文件来创建名为 spire-agent-cluster-role 的 ClusterRole 和相应的 ClusterRoleBinding：

   ```
   $ kubectl apply -f agent-cluster-role.yaml
   ```

2. 为了确认成功创建，请验证 ClusterRole 是否出现在以下命令的输出中：

   ```
   $ kubectl get clusterroles --namespace spire | grep spire
   ```

### 步骤 2：创建 Agent 配置映射

将 agent-configmap.yaml 配置文件应用于创建代理配置映射。这将作为 `agent.conf` 文件挂载，用于确定 SPIRE Agent 的配置。

```
$ kubectl apply -f agent-configmap.yaml
```

agent-configmap.yaml 文件指定了许多重要的目录，特别是 /run/spire/sockets 和 /run/spire/config。这些目录在部署代理容器时绑定。

请参阅 [配置 SPIRE](https://spiffe.io/docs/latest/spire/using/configuring/) 部分，详细了解如何配置 SPIRE Agent，特别是节点验证和工作负载验证。

请注意，一旦修改了 SPIRE Agent 的配置，必须重新启动该 Agent 才能使更改生效。

### 步骤 3：创建 Agent DaemonSet

代理以 DaemonSet 形式部署，每个 Kubernetes 工作节点上运行一个代理。

通过应用 agent-daemonset.yaml 配置来部署 SPIRE 代理。

```
$ kubectl apply -f agent-daemonset.yaml
```

这将在 spire 命名空间中创建一个名为 spire-agent 的 DaemonSet，并在 spire-server 旁边启动一个 spire-agent pod，如以下两个命令的输出所示：

```bash
$ kubectl get daemonset --namespace spire

NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
spire-agent   1         1         1       1            1           <none>          6m45s

$ kubectl get pods --namespace spire

NAME                           READY   STATUS    RESTARTS   AGE
spire-agent-88cpl              1/1     Running   0          6m45s
spire-server-0                 1/1     Running   0          103m
```

当代理部署时，绑定以下表格中总结的卷：

| 卷            | 描述                                                         | 挂载位置           |
| ------------- | ------------------------------------------------------------ | ------------------ |
| spire-config  | 在步骤 2 中创建的 spire-agent configmap。                    | /run/spire/config  |
| spire-sockets | hostPath，将与在同一工作节点上运行的所有其他 pod 共享。它包含一个 UNIX 域套接字，用于工作负载与代理 API 通信。 | /run/spire/sockets |