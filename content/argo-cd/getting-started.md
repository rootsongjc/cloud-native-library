---
weight: 5
linkTitle: 入门
title: 入门
date: '2023-06-30T16:00:00+08:00'
type: book
---

🔔 提示：本指南假设你对 Argo CD 所基于的工具有一定的了解。请阅读[了解基础知识](../understand-the-basics/)以了解这些工具。

## 要求

- 安装 [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) 命令行工具。
- 有一个 [kubeconfig](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) 文件（默认位置是`~/.kube/config`）。
- CoreDNS。可以通过以下方式为 microk8s 启用`microk8s enable dns && microk8s stop && microk8s start`

## 1. 安装 Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

这将创建一个新的命名空间，`argocd`，Argo CD 服务和应用程序资源将驻留在其中。

🔔 警告：安装清单包括`ClusterRoleBinding`引用命名空间的资源`argocd`。如果你要将 Argo CD 安装到不同的命名空间中，请确保更新命名空间引用。

如果你对 UI、SSO、多集群功能不感兴趣，那么你可以仅安装[核心](../operator-manual/installation/#core) Argo CD 组件：

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml
```

此默认安装将具有自签名证书，如果没有一些额外的工作就无法访问。执行以下操作之一：

- 按照[说明配置证书](../operator-manual/tls/)（并确保客户端操作系统信任它）。
- 配置客户端操作系统以信任自签名证书。
- 在本指南中的所有 Argo CD CLI 操作上使用 --insecure 标志。

用于`argocd login --core`配置 CLI 访问并[跳过](../user-guide/commands/argocd_login/)步骤 3-5。

## 2. 下载 Argo CD CLI

从 [GitHub](https://github.com/argoproj/argo-cd/releases/latest) 下载最新的 Argo CD 版本。更详细的安装说明可以通过 [CLI 安装文档](../cli-installation/)找到。

还适用于 Mac、Linux 和 WSL Homebrew：

```bash
brew install argocd
```

## 3. 访问 Argo CD API 服务器

默认情况下，Argo CD API 服务器不向外部 IP 公开。要访问 API 服务器，请选择以下技术之一来公开 Argo CD API 服务器：

### 服务类型负载均衡器

将 argocd-server 服务类型更改为`LoadBalancer`：

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

### Ingress

请按照[ingress 文档](../operator-manual/ingress/)了解如何使用 ingress 配置 Argo CD。

### 转发端口

Kubectl 端口转发还可用于连接到 API 服务器，而无需公开服务。

```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

然后可以使用 https://localhost:8080 访问 API 服务器

## 4. 使用 CLI 登录

帐户的初始密码`admin`是自动生成的，并以明文形式存储 在 Argo CD 安装命名空间中`password`命名的机密字段中。`argocd-initial-admin-secret`你可以使用 CLI 简单地检索此密码`argocd`：

```bash
argocd admin initial-password -n argocd
```

🔔 警告：`argocd-initial-admin-secret`更改密码后，你应该从 Argo CD 命名空间中删除。该秘密除了以明文形式存储最初生成的密码外没有其他用途，并且可以随时安全地删除。如果必须重新生成新的管理员密码，Argo CD 将根据需要重新创建它。

使用上面的用户名`admin`和密码，登录 Argo CD 的 IP 或主机名：

```bash
argocd login <ARGOCD_SERVER>
```

🔔 注意：CLI 环境必须能够与 Argo CD API 服务器通信。如果无法按照上述步骤 3 中的描述直接访问它，你可以告诉 CLI 通过以下机制之一使用端口转发来访问它：1) 向每个 CLI 命令添加 `--port-forward-namespace argocd`标志；或 2) 设置`ARGOCD_OPTS`环境变量：`export ARGOCD_OPTS='--port-forward-namespace argocd'`.

使用以下命令更改密码：

```bash
argocd account update-password
```

## 5. 注册集群以部署应用程序（可选）

此步骤将集群的凭据注册到 Argo CD，并且仅在部署到外部集群时才需要。在内部部署时（到运行 Argo CD 的同一集群），应使用 https://kubernetes.default.svc 作为应用程序的 K8s API 服务器地址。

首先列出当前 kubeconfig 中的所有集群上下文：

```bash
kubectl config get-contexts -o name
```

从列表中选择一个上下文名称并将其提供给`argocd cluster add CONTEXTNAME`。例如，对于 docker-desktop 上下文，运行：

```bash
argocd cluster add docker-desktop
```

上面的命令将 ServiceAccount ( `argocd-manager`) 安装到该 kubectl 上下文的 `kube-system` 命名空间中，并将服务帐户绑定到管理员级别的 ClusterRole。Argo CD 使用此服务帐户令牌来执行其管理任务（即部署 / 监控）。

🔔 注意：可以修改 `argocd-manager-role` 角色的规则，使其仅具有对有限的命名空间、组和类型集的 `create`、`update`、`patch`、`delete`权限。但是，要使 Argo CD 发挥作用，在集群作用域中需要`get`、`list`和`watch`权限。

## 6. 从 Git 存储库创建应用程序

<https://github.com/argoproj/argocd-example-apps.git> 提供了包含 guestbook 应用程序的示例存储库，以演示 Argo CD 的工作原理。

### 通过 CLI 创建应用程序

首先，我们需要运行以下命令将当前命名空间设置为 argocd：

```bash
kubectl config set-context --current --namespace=argocd
```

使用以下命令创建示例 guestbook 应用程序：

```bash
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
```

### 通过 UI 创建应用程序

打开浏览器访问 Argo CD 外部 UI，通过在浏览器中访问 IP / 主机名进行登录，并使用步骤 4 中设置的凭据。

登录后，点击 **+ New App** 按钮，如下图：

![+ New App 按钮](../assets/new-app.png)

为你的应用程序命名`guestbook`，使用项目`default`，并将同步策略保留为`Manual`：

![应用程序信息](../assets/app-ui-information.png)

通过将存储库 url 设置为 github 存储库 url，将 <https://github.com/argoproj/argocd-example-apps.git> 存储库连接到 Argo CD，将修订保留为`HEAD`，并将路径设置为`guestbook`：

![连接仓库](../assets/connect-repo.png)

对于**Destination**，将集群 URL 设置为`https://kubernetes.default.svc`（或`in-cluster`集群名称），将命名空间设置为`default`：

![目的地](../assets/destination.png)

填写完以上信息后，点击 UI 顶部的**Create** `guestbook`即可创建应用程序：

![目的地](../assets/create-app.png)

## 7. 同步（部署）应用程序

### 通过 CLI 同步

创建 guestbook 应用程序后，你现在可以查看其状态：

```bash
$ argocd app get guestbook
Name:               guestbook
Server:             https://kubernetes.default.svc
Namespace:          default
URL:                https://10.97.164.88/applications/guestbook
Repo:               https://github.com/argoproj/argocd-example-apps.git
Target:
Path:               guestbook
Sync Policy:        <none>
Sync Status:        OutOfSync from  (1ff8a67)
Health Status:      Missing

GROUP  KIND        NAMESPACE  NAME          STATUS     HEALTH
apps   Deployment  default    guestbook-ui  OutOfSync  Missing
       Service     default    guestbook-ui  OutOfSync  Missing
```

应用程序状态为初始`OutOfSync`状态，因为应用程序尚未部署，并且尚未创建 Kubernetes 资源。要同步（部署）应用程序，请运行：

```bash
argocd app sync guestbook
```

此命令从存储库检索清单并执行`kubectl apply`其中一个清单。guestbook 应用程序现已运行，你现在可以查看其资源组件、日志、事件和评估的健康状态。

### 通过 UI 同步

![guestbook 应用](../assets/guestbook-app.png) 

![查看应用](../assets/guestbook-tree.png)
