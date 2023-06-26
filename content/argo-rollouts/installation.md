---
linktitle: "安装"
title: "安装 Argo Rollouts"
weight: 2
date: '2023-06-21T16:00:00+08:00'
type: book
---

## 控制器安装

两种安装方式：

- [install.yaml](https://github.com/argoproj/argo-rollouts/blob/master/manifests/install.yaml) - 标准安装方法。

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f <https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml>
```

这将创建一个新的命名空间 `argo-rollouts`，在其中运行 Argo Rollouts 控制器。

🔔 提示：如果你使用的是其他命名空间名称，请更新 `install.yaml` 群集角色绑定的服务帐户命名空间名称。

🔔 提示：在 Kubernetes v1.14 或更低版本上安装 Argo Rollouts 时，CRD 清单必须使用 `--validate = false` 选项进行 `kubectl apply`。这是由于在 v1.15 中引入的新 CRD 字段的使用，在较低的 API 服务器中默认被拒绝。

🔔 提示：在 GKE 上，你需要授予你的帐户创建新集群角色的权限：

```bash
kubectl create clusterrolebinding YOURNAME-cluster-admin-binding --clusterrole=cluster-admin --user=YOUREMAIL@gmail.com
```

- [namespace-install.yaml](https://github.com/argoproj/argo-rollouts/blob/master/manifests/namespace-install.yaml) - 安装 Argo Rollouts，仅需要命名空间级别的特权。使用此安装方法的示例用途是在同一集群上的不同命名空间中运行多个 Argo Rollouts 控制器实例。

  > 注意：Argo Rollouts CRD 未包含在 `namespace-install.yaml` 中。必须单独安装 CRD 清单。CRD 清单位于 [manifests/crds](https://github.com/argoproj/argo-rollouts/blob/master/manifests/crds) 目录中。使用以下命令安装它们：
  >
  > ```bash
  > kubectl apply -k https://github.com/argoproj/argo-rollouts/manifests/crds\?ref\=stable
  > ```

你可以在 [Quay.io](https://quay.io/repository/argoproj/argo-rollouts?tab=tags) 找到控制器的发布容器镜像。还有旧版本在 Dockerhub 上，但由于引入了速率限制，Argo 项目已经转移到了 Quay。

## Kubectl 插件安装

kubectl 插件是可选的，但方便从命令行管理和可视化升级。

### Brew

```bash
brew install argoproj/tap/kubectl-argo-rollouts
```

### 手动

1. 使用 curl 安装 [Argo Rollouts Kubectl 插件](https://github.com/argoproj/argo-rollouts/releases)。

   ```bash
   curl -LO <https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-darwin-amd64>
   ```

   🔔 提示：对于 Linux 发行版，请将 `darwin` 替换为 `linux`

2. 将 `kubectl-argo-rollouts` 二进制文件设置为可执行。

   ```bash
   chmod +x ./kubectl-argo-rollouts-darwin-amd64
   ```

3. 将二进制文件移动到你的 PATH 中。

   ```bash
   sudo mv ./kubectl-argo-rollouts-darwin-amd64 /usr/local/bin/kubectl-argo-rollouts
   ```

   测试以确保你安装的版本是最新的：

   ```bash
   kubectl argo rollouts version
   ```

## Shell 自动完成

CLI 可以为多个 shell 导出 shell 完成代码。

对于 bash，请确保安装并启用 bash 完成。要在当前 shell 中访问完成，请运行 `source <(kubectl-argo-rollouts completion bash)`。或者，将其写入文件并在`.bash_profile` 中进行 source。

完成命令支持 bash、zsh、fish 和 powershell。

有关更多详细信息，请参见[完成命令文档](notion://www.notion.so/jimmysong/notion：//www.notion.so/jimmysong/generated/kubectl-argo-rollouts/kubectl-argo-rollouts_completion.md)。

## 使用 Docker CLI

CLI 也可以作为容器镜像在 https://quay.io/repository/argoproj/kubectl-argo-rollouts 中提供。

你可以像任何其他 Docker 镜像一样运行它，或在支持 Docker 镜像的任何 CI 平台中使用它。

```
docker run quay.io/argoproj/kubectl-argo-rollouts:master version
```

## 支持的版本

在任何时候，Argo Rollouts 的官方支持版本是最新发布的版本，在 Kubernetes 版本 N 和 N-1（由 Kubernetes 项目本身支持）上支持。

例如，如果 Argo Rollouts 的最新次要版本是 1.2.1 并支持 Kubernetes 版本为 1.24、1.23 和 1.22，则支持以下组合：

- 在 Kubernetes 1.24 上的 Argo Rollouts 1.2.1
- 在 Kubernetes 1.23 上的 Argo Rollouts 1.2.1

## 升级 Argo Rollouts

Argo Rollouts 是一个不持有任何外部状态的 Kubernetes 控制器。只有在实际发生部署时，它才是活动的。

要升级 Argo Rollouts：

1. 尝试找到没有部署发生的时间段；
2. 删除控制器的先前版本并应用 / 安装新版本；
3. 发生新的 Rollout 时，新控制器将被激活。

如果你在升级控制器时进行部署，则不应有任何停机时间。当前的 Rollouts 将被暂停，一旦新控制器变为活动状态，它将恢复所有正在进行的部署。