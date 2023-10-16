---
title: GitOps
description: 配置 Tetrate Service Bridge（TSB）资源的 GitOps 集成。
weight: 7
---

本文档描述了如何为 Tetrate Service Bridge（TSB）配置 GitOps 集成。

TSB 中的 GitOps 集成允许您与应用程序打包和部署的生命周期以及不同的持续部署（CD）系统进行集成。

本文假设您已经具备了配置 GitOps CD 系统的工作知识，例如 [FluxCD](https://fluxcd.io/) 或 [ArgoCD](https://argo-cd.readthedocs.io/en/stable/)。

## 工作原理

一旦在管理平面集群和/或应用程序集群中启用了 GitOps，CD 系统将能够将 TSB 配置应用于其中，然后将其推送到 TSB 管理平面。

![](../../../assets/operations/gitops.png)

## 启用 GitOps

可以通过 `ManagementPlane` 或 `ControlPlane` CR 或 Helm 值为每个集群配置 GitOps 组件。

{{<callout note "注意">}}
在同时在管理平面和控制平面中启用 GitOps 时，如果两个平面部署在同一个集群中（通常用于小型环境或[演示安装](../../setup/self_managed/demo-installation)），则只有两者之一会生效。具体来说，控制平面将是唯一启用的平面。这是为了避免两个平面多次推送相同的资源。
{{</callout>}}

`ManagementPlane` 和 `ControlPlane` CR 都有一个名为 `gitops` 的组件，设置 `enabled: true` 将激活该集群的 GitOps。

```yaml
spec:
  components:
    ...
    gitops:
      enabled: true
      reconcileInterval: 600s
```

{{<callout note "注意">}}
在启用 GitOps 时，强烈建议以一种配置用户权限的方式，使得普通用户只能对 TSB 配置具有读取访问权限。这将有助于确保只有配置的集群服务账户可以管理配置。
{{</callout>}}

### 在管理平面中启用 GitOps

以下是一个启用了 GitOps 的演示集群的自定义资源 YAML 示例，该管理平面部署在 `tsb` 命名空间中。如果使用 Helm，可以更新控制平面 Helm 值的 `spec` 部分。

```bash
kubectl edit -n tsb managementplane/managementplane
```

```yaml
spec:
  components:
    ...
    gitops:
      enabled: true
      reconcileInterval: 600s
```

设置 `enabled: true` 将激活该管理平面集群的 GitOps。

每当 CD 系统将资源应用于管理平面集群时，TSB GitOps 组件将它们推送到管理平面。此外，还有一个定期的协调过程，确保管理平面集群保持作为事实的源，并定期推送其中的信息。可以使用 `reconcileInterval` 属性来自定义后台协调过程运行的间隔。可以在[GitOps 组件参考](../../refs/install/managementplane/v1alpha1/spec#gitops)中找到更多详细信息和其他配置选项。

管理平面集群可以将配置推送到整个组织，而无需在该平面中授予任何特殊权限，一旦在该平面启用了 GitOps。

在对 `ManagementPlane` CR 应用更改后，TSB 操作员将为集群激活该功能，并开始响应应用的 TSB K8s 资源。

### 在控制平面中启用 GitOps

以下是一个启用了 GitOps 的演示集群的自定义资源 YAML 示例，该控制平面部署在 `istio-system` 命名空间中。如果使用 Helm，可以更新控制平面 Helm 值的 `spec` 部分。

```bash
kubectl edit -n istio-system controlplane/controlplane
```

```yaml
spec:
  components:
    ...
    gitops:
      enabled: true
      reconcileInterval: 600s
```

设置 `enabled: true` 将激活该集群的 GitOps。

每当 CD 系统将资源应用于应用程序集群时，TSB GitOps 组件将它们推送到管理平面。此外，还有一个定期的协调过程，确保应用程序集群保持作为事实的源，并定期推送其中的信息。可以使用 `reconcileInterval` 属性来自定义后台协调过程运行的间隔。可以在[GitOps 组件参考](../../../refs/install/controlplane/v1alpha1/spec#gitops)中找到更多详细信息和其他配置选项。

与在管理平面中的情况不同，在授权应用程序集群将配置推送到管理平面之前，需要授予集群服务账户权限。可以通过以下方式轻松完成：

```bash
$ tctl x gitops grant demo
```

这将授权推送配置到整个组织。如果要进一步限制集群服务账户可以推送配置的位置，请参阅命令文档：

```bash
$ tctl x gitops grant --help
```

在对 `ControlPlane` CR 应用更改后，TSB 操作员将为集群激活该功能，并开始响应应用的 TSB K8s 资源。

## 监控 GitOps 健康状况

GitOps 集成提供了指标和详细日志，可用于监控 GitOps 进程中涉及的不同组件的健康状况：

* [GitOps 指标](../../telemetry/key-metrics#gitops-operational-status)提供了在将配置发送到管理平面时经历的延迟、错误率等。