---
weight: 2
linkTitle: 插件
title: 指标插件
date: '2023-06-21T16:00:00+08:00'
type: book
---

🔔 重要提醒：从 v1.5 开始可用 - 状态：Alpha

Argo Rollouts 通过第三方插件系统支持获取分析指标。这使得用户可以扩展 Rollouts 的功能，以支持不受本地支持的度量提供者。Rollouts 使用一个名为 [go-plugin](https://github.com/hashicorp/go-plugin) 的插件库来实现。你可以在此处找到示例插件：[rollouts-plugin-metric-sample-prometheus](https://github.com/argoproj-labs/rollouts-plugin-metric-sample-prometheus)

## 使用指标插件

安装和使用 argo rollouts 插件有两种方法。第一种方法是将插件可执行文件挂载到 rollouts 控制器容器中。第二种方法是使用 HTTP(S) 服务器托管插件可执行文件。

### 将插件可执行文件挂载到 rollouts 控制器容器中

有几种方法可以将插件可执行文件挂载到 rollouts 控制器容器中。其中一些方法将取决于你的特定基础架构。这里有几种方法：

- 使用 init 容器下载插件可执行文件
- 使用 Kubernetes 卷挂载共享卷，例如 NFS、EBS 等。
- 将插件构建到 rollouts 控制器容器中

然后，你可以使用 configmap 将插件可执行文件位置指向插件。示例：

```yaml
 apiVersion: v1
 kind: ConfigMap
 metadata:
   name: argo-rollouts-config
 data:
   metricProviderPlugins: |-
     - name: "argoproj-labs/sample-prometheus" # 插件名称，它必须与插件所需的名称匹配，以便它可以找到其配置
       location: "file://./my-custom-plugin" # 支持 http(s):// url 和 file://
```

### 使用 HTTP(S) 服务器托管插件可执行文件

Argo Rollouts 支持从 HTTP(S) 服务器下载插件可执行文件。要使用此方法，你需要通过 `argo-rollouts-config` configmap 配置控制器，并将 `pluginLocation` 设置为 http(s) url。示例：

```yaml
 apiVersion: v1
 kind: ConfigMap
 metadata:
   name: argo-rollouts-config
 data:
   metricProviderPlugins: |-
     - name: "argoproj-labs/sample-prometheus" # 插件名称，它必须与插件所需的名称匹配，以便它可以找到其配置
       location: "https://github.com/argoproj-labs/rollouts-plugin-metric-sample-prometheus/releases/download/v0.0.4/metric-plugin-linux-amd64" # 支持 http(s):// 和 file://
       sha256: "dac10cbf57633c9832a17f8c27d2ca34aa97dd3d" # 可选的插件可执行文件的 sha256 校验和
```

## 一些注意事项

根据你用于安装和插件的方法，有一些需要注意的事项。如果无法下载或找到插件可执行文件，则控制器将不会启动。这意味着如果你正在使用需要下载插件的安装方法，并且由于某些原因服务器不可用，而且 rollouts 控制器 pod 在服务器宕机期间被删除或第一次启动时，它将无法启动，直到服务器再次可用。

Argo Rollouts 仅在启动时下载插件一次，但如果删除了 pod，则需要在下一次启动时再次下载插件。在 HA 模式下运行 Argo Rollouts 可以在一定程度上帮助解决此问题，因为每个 pod 都将在启动时下载插件。因此，如果在服务器故障期间删除了单个 pod，则其他 pod 仍将能够接管，因为它已经有可用的插件可执行文件。Argo Rollouts 管理员的责任是定义插件安装方法并考虑每种方法的风险。

## 可用插件列表（按字母顺序）

### 在此处添加你的插件

- 如果你已创建插件，请提交 PR 将其添加到此列表中。

[rollouts-plugin-metric-sample-prometheus](https://github.com/argoproj-labs/rollouts-plugin-metric-sample-prometheus)

- 这只是一个示例插件，可用作创建自己的插件的起点。它不适用于生产。它基于内置的 prometheus 提供程序。
