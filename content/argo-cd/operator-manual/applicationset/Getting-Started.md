---
draft: false
weight: 2
linktitle: "入门"
title: "ApplicationSet 入门"
date: '2023-06-30T16:00:00+08:00'
---

本指南假定你已经熟悉 Argo CD 及其基本概念。有关更多信息，请参阅 Argo CD 文档。

## 要求

- 安装 [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) 命令行工具
- 有一个 [kubeconfig](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) 文件（默认位置为 `~/.kube/config`）。

## 安装

有几种安装 ApplicationSet 控制器的选项。

### A) 将 ApplicationSet 作为 Argo CD 的一部分安装

从 Argo CD v2.3 开始，ApplicationSet 控制器已捆绑在 Argo CD 中。无需从 Argo CD 单独安装 ApplicationSet 控制器。

有关更多信息，请参阅 Argo CD [入门指南](../../../getting-started/)。

### B) 将 ApplicationSet 安装到现有的 Argo CD 安装中（Argeo CD v2.3 之前）

**注意**: 以下说明仅适用于 Argo CD 版本 v2.3.0 之前。

ApplicationSet 控制器 *必须* 安装到与其所针对的 Argo CD 相同的命名空间中。

假设 Argo CD 安装在 `argocd` 命名空间中，请运行以下命令：

```bash
 kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/applicationset/v0.4.0/manifests/install.yaml
```

安装完成后，ApplicationSet 控制器不需要进行其他设置。

`manifests/install.yaml` 文件包含安装 ApplicationSet 控制器所需的 Kubernetes 清单：

- `ApplicationSet` 资源的自定义资源定义
- `argocd-applicationset-controller` 的 Deployment
- 供 ApplicationSet 控制器使用的 ServiceAccount，用于访问 Argo CD 资源
- 授予 ServiceAccount 所需资源的 RBAC 访问权限的 Role
- 将 ServiceAccount 和 Role 绑定的 RoleBinding

## 启用高可用性模式

要启用高可用性，必须在 argocd-applicationset-controller 容器中设置命令 `--enable-leader-election=true` 并增加副本数。

在 manifests/install.yaml 中执行以下更改：

```yaml
     spec:
       containers:
       - command:
         - entrypoint.sh
         - argocd-applicationset-controller
         - --enable-leader-election=true
```

### 可选：升级后的额外安全保障

请参阅 控制资源修改 页面，了解你可能希望在 `install.yaml` 中的 ApplicationSet Resource 中添加的其他参数，以提供额外的安全性，以防止任何初始意外的后升级行为。

例如，为了暂时防止升级后的 ApplicationSet 控制器进行任何更改，你可以：

- 启用干运行
- 使用仅创建策略
- 在 ApplicationSets 上启用 `preserveResourcesOnDeletion`
- 在你的 ApplicationSets 模板中暂时禁用自动同步

这些参数将允许你观察/控制新版本 ApplicationSet 控制器在你的环境中的行为，以确保你对结果感到满意（请参阅 ApplicationSet 日志文件以获取详细信息）。只需不要忘记在完成测试后删除任何临时更改！

但是，如上所述，这些步骤并不是必需的：升级 ApplicationSet 控制器应该是一项最小侵入性的过程，并且这些步骤仅建议作为额外安全措施。

## 下一步

一旦你的 ApplicationSet 控制器正常运行，请继续阅读 [用例](../use-cases/)，了解更多支持的场景，或直接转到 [生成器](../generators/) 查看示例 `ApplicationSet` 资源。
