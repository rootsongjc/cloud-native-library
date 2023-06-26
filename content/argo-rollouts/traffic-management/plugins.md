---
weight: 7
title: "流量路由插件"
linkTitle: "插件"
date: '2023-06-21T16:00:00+08:00'
type: book
---

🔔 提醒：自 1.5 版本起可用 - 状态：Alpha

Argo Rollouts 支持通过第三方插件系统获取分析指标。这允许用户扩展 Rollouts 的功能以支持本机不支持的度量提供者。Rollouts 使用一个名为 go-plugin 的插件库来实现这一点。你可以在这里找到一个示例插件：rollouts-plugin-trafficrouter-sample-nginx

## 使用 Traffic Router 插件

安装和使用 Argo Rollouts 插件有两种方法。第一种方法是将插件可执行文件挂载到 rollouts 控制器容器中。第二种方法是使用 HTTP（S）服务器托管插件可执行文件。

### 将插件可执行文件挂载到 rollouts 控制器容器中

有几种方法可以将插件可执行文件挂载到 rollouts 控制器容器中。其中一些将取决于你的特定基础设施。这里有几种方法：

- 使用 init 容器下载插件可执行文件
- 使用 Kubernetes 卷挂载共享卷，如 NFS、EBS 等。
- 将插件构建到 rollouts 控制器容器中

然后，你可以使用 configmap 将插件可执行文件位置指向到。示例：

```yaml
 apiVersion: v1
 kind: ConfigMap
 metadata:
   name: argo-rollouts-config
 data:
   trafficRouterPlugins: |-
     - name: "argoproj-labs/sample-nginx" # 插件的名称，它必须与插件所需的名称匹配，以便它可以找到它的配置
       location: "file://./my-custom-plugin" # 支持 http（s）：// url 和 file：//
```

### 使用 HTTP（S）服务器托管插件可执行文件

Argo Rollouts 支持从 HTTP（S）服务器下载插件可执行文件。要使用此方法，你需要通过`argo-rollouts-config` configmap 配置控制器，并将`pluginLocation`设置为 http（s）url。示例：

```yaml
 apiVersion: v1
 kind: ConfigMap
 metadata:
   name: argo-rollouts-config
 data:
   trafficRouterPlugins: |-
     - name: "argoproj-labs/sample-nginx" # 插件的名称，它必须与插件所需的名称匹配，以便它可以找到它的配置
       location: "https://github.com/argoproj-labs/rollouts-plugin-trafficrouter-sample-nginx/releases/download/v0.0.1/metric-plugin-linux-amd64" # 支持 http(s)：// url 和 file：//
       sha256: "08f588b1c799a37bbe8d0fc74cc1b1492dd70b2c" #可选的插件可执行文件的 sha256 校验和
```

## 一些注意事项

根据你用于安装和插件的方法，需要注意一些事项。如果无法下载或找到插件可执行文件，rollouts 控制器将无法启动。这意味着如果你使用需要下载插件的安装方法，而服务器因某种原因不可用，并且 rollouts 控制器的 pod 在服务器关闭时被删除或正在首次启动，则将无法启动，直到可用插件的服务器再次可用。

Argo Rollouts 仅在启动时下载插件一次，但如果删除了 pod，则需要在下一次启动时再次下载插件。在 HA 模式下运行 Argo Rollouts 可以在一定程度上帮助解决这种情况，因为每个 pod 在启动时都会下载插件。因此，如果单个 pod 在服务器故障期间被删除，则其他 pod 仍将能够接管，因为已经有一个可用的插件可执行文件。Argo Rollouts 管理员有责任定义插件安装方法，考虑每种方法的风险。

## 可用插件列表（按字母顺序排列）

### 在此处添加你的插件

- 如果你已创建插件，请提交 PR 将其添加到此列表中。

[rollouts-plugin-trafficrouter-sample-nginx](https://github.com/argoproj-labs/rollouts-plugin-trafficrouter-sample-nginx)

- 这仅是一个示例插件，可以用作创建自己的插件的起点。它不适合在生产中使用。它基于内置的 prometheus 提供者。

[Contour](https://github.com/argoproj-labs/rollouts-plugin-trafficrouter-contour)

- 这是一个支持 Contour 的插件。

[Gateway API](https://github.com/argoproj-labs/rollouts-plugin-trafficrouter-gatewayapi/)

- 提供对 Gateway API 的支持，其中包括 Kuma、Traefix、cilium、Contour、GloodMesh、HAProxy 和[许多其他](https://gateway-api.sigs.k8s.io/implementations/#implementation-status)。

