---
weight: 2
title: "安装 SPIRE 服务器"
---

本文指导你如何在 Linux 和 Kubernetes 上安装 SPIRE 服务器。

## 步骤 1：获取 SPIRE 二进制文件

预构建的 SPIRE 发行版可在 [SPIRE 下载页面](https://spiffe.io/downloads/#spire-releases)找到。tarball 包含服务器和代理二进制文件。

如果需要，你也可以[从源代码构建 SPIRE](https://github.com/spiffe/spire/blob/main/CONTRIBUTING.md)。

## 步骤 2：安装服务器和代理

本入门指南描述了如何在同一节点上安装服务器和代理。在典型的生产部署中，服务器将安装在一个节点上，而一个或多个代理将安装在不同的节点上。

要安装服务器和代理，请执行以下操作：

1. 从 [SPIRE 下载页面](https://spiffe.io/downloads/#spire-releases)获取最新的 tarball，然后使用以下命令将其解压缩到 `/opt/spire` 目录中：

   ```bash
   wget https://github.com/spiffe/spire/releases/download/v1.8.2/spire-1.8.2-linux-amd64-musl.tar.gz
   tar zvxf spire-1.8.2-linux-amd64-musl.tar.gz
   sudo cp -r spire-1.8.2/. /opt/spire/
   ```

2. 为了方便起见，将 `spire-server` 和 `spire-agent` 添加到你的 `$PATH` 中：

   ```bash
   sudo ln -s /opt/spire/bin/spire-server /usr/bin/spire-server
   sudo ln -s /opt/spire/bin/spire-agent /usr/bin/spire-agent
   ```

## 步骤 3：配置服务器

要在 Linux 上配置服务器，你需要：

1. 配置信任域
2. 配置服务器证书颁发机构（CA），可能包括配置 UpstreamAuthority 插件
3. 配置节点认证插件
4. 配置用于持久化数据的默认 `.data` 目录

但是，为了简单起见，仅需完成步骤 1、2 和 3 即可快速部署演示目的。

要配置步骤 1、2 和 4 中的项，请编辑服务器的配置文件，位于 `/opt/spire/conf/server/server.conf`。

有关如何配置 SPIRE 的详细信息，请参阅[配置 SPIRE](https://spiffe.io/docs/latest/spire/using/configuring/)，特别是节点认证和工作负载认证。

注意，SPIRE 服务器在修改配置后必须重新启动才能生效。

请参阅[安装 SPIRE 代理](https://spiffe.io/docs/latest/spire/installing/install-agents/)，了解如何安装 SPIRE 代理。

# 如何在 Kubernetes 上安装 SPIRE 服务器

本节将逐步向你介绍在 Kubernetes 集群中运行服务器并配置工作负载容器以访问 SPIRE 的方法。

你必须从包含用于配置的 `.yaml` 文件的目录中运行所有命令。

## 步骤 1：获取所需文件

要获取所需的.yaml 文件，请克隆 https://github.com/spiffe/spire-tutorials 并从 `spire-tutorials/k8s/quickstart` 子目录复制 `.yaml` 文件。

## 步骤 2：为 SPIRE 组件配置 Kubernetes 命名空间

按照以下步骤配置部署 SPIRE 服务器和 SPIRE 代理的 spire 命名空间。

1. 创建命名空间：

   ```bash
   $ kubectl apply -f spire-namespace.yaml
   ```

2. 运行以下命令，并验证输出中是否列出了*spire*：

   ```bash
   $ kubectl get namespaces
   ```

## 步骤 3：配置 SPIRE 服务器

要在 Kubernetes 上配置 SPIRE 服务器，你需要：

1. 创建服务器服务帐户
2. 创建服务器捆绑包 ConfigMap
3. 创建服务器 ConfigMap
4. 创建服务器 StatefulSet
5. 创建服务器服务

有关详细信息，请参阅以下各节。

### 创建服务器服务帐户

通过应用 server-account.yaml 配置文件来配置名为 spire-server 的服务帐户：

```
$ kubectl apply -f server-account.yaml
```

通过运行以下命令确认成功创建，并验证该服务帐户是否出现在以下命令的输出中：

```
$ kubectl get serviceaccount --namespace spire
```

### 创建服务器捆绑包 ConfigMap、角色和 ClusterRoleBinding

为了使服务器能够为代理提供证书以用于在建立连接时验证服务器的身份，服务器需要具备在 spire 命名空间中获取和修补 ConfigMap 对象的功能。

在这种部署中，代理和服务器共享同一集群，SPIRE 可以配置为定期生成这些证书并将证书内容更新到 ConfigMap 中。为此，服务器需要能够在 Kubernetes RBAC 中获取和修补 ConfigMap 对象。

通过应用 `spire-bundle-configmap.yaml` 配置文件来创建名为 `spire-bundle` 的 ConfigMap：

```bash
$ kubectl apply -f spire-bundle-configmap.yaml
```

通过运行以下命令确认成功创建，并验证 `spire-bundle` ConfigMap 是否列在以下命令的输出中：

```bash
$ kubectl get configmaps --namespace spire | grep spire
```

为了允许服务器读取和写入此 ConfigMap，必须创建一个 ClusterRole，授予 Kubernetes RBAC 相应的特权，并将 ClusterRoleBinding 与前一步创建的服务帐户关联。

通过应用 `server-cluster-role.yaml` 配置文件来创建名为 `spire-server-trust-role` 的 ClusterRole 和相应的 ClusterRoleBinding：

```bash
$ kubectl apply -f server-cluster-role.yaml
```

通过运行以下命令确认成功创建，并验证 `spire-server-trust-role` ClusterRole 是否出现在以下命令的输出中：

```bash
$ kubectl get clusterroles --namespace spire | grep spire
```

### 创建服务器 ConfigMap

服务器在 Kubernetes ConfigMap 中进行配置，该 ConfigMap 在 `server-configmap.yaml` 中指定了一些重要的目录，特别是 `/run/spire/data和/run/spire/config`。这些卷在部署服务器容器时绑定。

请参阅[配置 SPIRE](https://spiffe.io/docs/latest/spire/using/configuring/)部分，了解如何配置 SPIRE 服务器的详细信息，特别是节点认证和工作负载认证。

注意，SPIRE 服务器在修改配置后必须重新启动才能生效。

使用以下命令将服务器 ConfigMap 应用到你的集群：

```bash
$ kubectl apply -f server-configmap.yaml
```

### 创建服务器 StatefulSet

通过应用 `server-statefulset.yaml` 配置文件来部署服务器：

```bash
$ kubectl apply -f server-statefulset.yaml
```

这将在 spire 命名空间中创建一个名为 `spire-server` 的 StatefulSet，并启动一个 `spire-server` 的 Pod，如以下两个命令的输出所示：

```bash
$ kubectl get statefulset --namespace spire

NAME           READY   AGE
spire-server   1/1     86m

$ kubectl get pods --namespace spire

NAME                           READY   STATUS    RESTARTS   AGE
spire-server-0                 1/1     Running   0          86m
```

当你部署服务器时，它会自动在 SPIRE 服务器的 gRPC 端口上配置 livenessProbe，以确保容器的可用性。

服务器部署时，绑定到以下表中总结的卷：

| 卷           | 描述                                        | 挂载位置            |
| ------------ | ------------------------------------------- | ------------------- |
| spire-config | 引用在前一步中创建的 spire-server ConfigMap | `/run/spire/config` |
| spire-data   | 服务器的 SQLite 数据库和密钥文件的 hostPath | `/run/spire/data`   |

### 创建服务器服务

通过应用 server-service.yaml 配置文件来创建服务器服务：

```bash
$ kubectl apply -f server-service.yaml
```

通过运行以下命令确认成功创建，并验证 spire 命名空间现在是否有一个名为 `spire-server` 的服务：

```bash
$ kubectl get services --namespace spire

NAME           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
spire-server   NodePort   10.107.205.29   <none>        8081:30337/TCP   88m
```
