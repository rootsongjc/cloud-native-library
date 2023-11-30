---
title: 安装 sleep
description: 如何安装用于各种示例的 `sleep` 工作负载的指南。
weight: 3
---

有时候拥有一个什么都不做的工作负载是很方便的。在这个示例中，使用已安装 `curl` 的容器作为 `sleep` 服务的基础，以便更容易进行测试。

`sleep` 服务在 TSB 文档中的多个示例中使用。本文档提供了该服务的基本安装步骤。

请确保查阅每个 TSB 文档，以获取示例正常运行所需的特定注意事项或自定义设置，因为本文档描述了最通用的安装步骤。

以下示例假设您已经设置好了 TSB，并且已经注册了要安装 `sleep` 工作负载的 Kubernetes 集群。

除非另有说明，使用 `kubectl` 命令的示例必须指向同一集群。在运行这些命令之前，请确保您的 `kubeconfig` 指向所需的集群。

## 命名空间

除非另有说明，假定 `sleep` 服务安装在 `sleep` 命名空间中。如果不存在，请在目标集群中创建此命名空间。

运行以下命令以创建命名空间（如果尚未存在）：

```bash
kubectl create namespace sleep
```

此命名空间中的 `sleep` Pod 必须运行 Istio sidecar 代理。要自动启用对所有 Pod 的 sidecar 注入，请执行以下操作：

```bash
kubectl label namespace sleep istio-injection=enabled --overwrite=true
```

这将让 Istio 知道它需要将 sidecar 注入到稍后将创建的 Pod 中。

## 部署 `sleep` Pod 和服务

下载在 Istio 存储库中找到的 [`sleep.yaml`](../../../assets/reference/sleep.yaml) 清单。

运行以下命令以在 `sleep` 命名空间中部署 `sleep` 服务：

```bash
kubectl apply -n sleep -f sleep.yaml
```

## 创建 `sleep` 工作空间

根据使用情况，下一步可能需要也可能不需要。如果您要创建 TSB 工作空间，请按照以下步骤创建。

在此示例中，我们假设您已经在组织中创建了一个租户。如果尚未创建，请阅读[文档中的示例并创建一个](../../../quickstart/tenant)。

如果您尚未执行此操作，请创建一个用于 `sleep` 的工作空间，并声明命名空间 `sleep`。创建一个名为 `sleep-workspace.yaml` 的文件，其内容类似于下面的示例。确保将组织、租户和集群名称替换为适当的值。

{{<callout note 注意>}}
如果您已经[安装了 `demo` 配置文件](../../../setup/self-managed/demo-installation)，则已经存在一个名为 `tetrate` 的组织和一个名为 `demo` 的集群。
{{</callout>}}

```
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: <organization>
  tenant: <tenant>
  name: sleep
spec:
  displayName: Sleep Workspace
  namespaceSelector:
    names:
      - "<cluster>/sleep"
```

使用 `tctl` 应用清单：

```bash
tctl apply -f sleep-workspace.yaml
```
