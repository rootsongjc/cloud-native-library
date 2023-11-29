---
title: 演示安装
weight: 1
description: "TSB 演示应用安装。"
---

本指南将引导你完成 TSB 演示配置文件的安装，该配置文件旨在快速概述 TSB 的功能。演示配置文件包括 PostgreSQL、Elasticsearch 和 LDAP，所有这些都在 Kubernetes 集群上进行编排。为了确保无缝体验，你的集群应包含 3-6 个节点，每个节点至少配备 4 个 vCPU 和 16 GB 内存。集群还必须建立默认存储类，并能够为 Elasticsearch 和 PostgreSQL 创建最小容量为 100 GB 的持久卷声明。

在继续之前，请参阅 [TSB 支持政策](../../../release-notes-announcements/support-policy)来验证与你的 Kubernetes 版本的兼容性。

## 先决条件

要安装演示配置文件，请确保你已完成以下步骤：

### 1. 获取 `tctl` 并同步镜像

首先按照[下载部分](../../requirements-and-download)中概述的步骤下载 `tctl` 。此外，按照同步容器镜像中所述[同步所需的容器镜像](../../requirements-and-download)。

### 2. 设置 Kubernetes 集群

准备一个要安装演示配置文件的 Kubernetes 集群。创建集群的具体步骤取决于你的环境。有关创建 Kubernetes 集群的具体说明，请参阅你的环境手册。

####  使用 kind

如果你使用 [kind](https://kind.sigs.k8s.io/) 集群进行安装，请按照以下步骤操作：

1. 创建类型集群后，安装 [MetalLB](https://metallb.universe.tf/) 以使 TSB 能够使用 `LoadBalancer` 类型的服务。
2. 配置 [L2 网络](https://metallb.universe.tf/configuration/#layer-2-configuration)，指定 `kind` Docker 网络 IP 范围内的 IP 地址范围。

##  安装

请按照以下步骤安装演示配置文件：

### 1.执行 `tctl install demo`

确保你的 Kubernetes 上下文设置为目标集群。使用 `tctl install demo` 命令，该命令利用 `kubectl` 配置中的 `current-context` 。在继续之前，请确认引用了正确的 Kubernetes 集群。

运行安装命令，如下所示。你可以使用 `--admin-password` 选项（自版本 1.4.0 起可用）提供管理员密码。或者，将为你生成一个密码。

```bash
tctl install demo \
  --registry <registry-location> \
  --admin-password <password>
```

{{<callout note "安装注意事项">}}

在某些资源受限或负载较重的环境中，安装时间可能比预期长，并且 `tctl` 工具可能会退出。 `tctl install demo` 命令是幂等的，允许你重新运行它，直到安装完成。

{{</callout>}}

成功安装后，你的 Kubernetes 集群将托管管理和控制平面，并将创建一个名为 `tetrate` 的组织。

## 访问网络用户界面

要访问 TSB Web UI，请执行以下步骤：

1. 从演示安装命令的输出中获取 URL 和凭据。查找类似于以下内容的输出：

   ```bash
   Controlplane installed successfully!
   Management Plane UI accessible at: https://31.224.214.68:8443
   Admin credentials: username: admin, password: yGWx1s!Y@&-KBe0V
   ```

1. 使用提供的 URL 和管理凭据登录 Web UI。

{{<callout note "提示">}}

即使你跳过快速入门，也请考虑[创建租户](../../../quickstart/tenant/)，因为遵循本网站上的示例可能需要它。

{{</callout>}}

##  进一步配置

有关演示安装的其他自定义（例如载入集群），请参阅[载入集群指南](../onboarding-clusters/)。
