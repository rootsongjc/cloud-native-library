---
title: 创建配置组
weight: 5
---

为了配置 bookinfo 应用程序，你需要创建一个网关组、一个流量组和一个安全组。每个组都提供特定的 API 来配置服务的各个方面。

## 先决条件

在继续阅读本指南之前，请确保你已完成以下步骤：

- 熟悉 TSB 概念
- 安装TSB演示环境
- 部署 Istio Bookinfo 示例应用程序
-  创建租户
-  创建工作区

## 使用用户界面

1. 在左侧面板的“租户”下，选择“工作区”。
2. 单击 `bookinfo-ws` 工作区卡。
3. 单击网关组按钮。
4. 单击带有 + 图标的卡以添加新的网关组。
5. 输入组 ID 作为 `bookinfo-gw` 。
6. 为你的网关组提供显示名称和描述。
7. 输入 `*/bookinfo` 作为初始命名空间选择器。
8. 将配置模式设置为 `BRIDGED` 。
9.  单击添加。
10. 从左侧面板中选择“工作区”返回到“工作区”。

对使用组 ID `bookinfo-traffic` 的流量组和使用组 ID `bookinfo-security` 的安全组重复相同的步骤。

## 使用tctl

创建 `groups.yaml` 文件：

<details>
  <summary>groups.yaml</summary>

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-gw
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-traffic
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
  configMode: BRIDGED
---
apiVersion: security.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo-ws
  name: bookinfo-security
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
  configMode: BRIDGED
```

</details>

使用 `tctl` 应用配置：

```bash
tctl apply -f groups.yaml
```

这些步骤将创建必要的网关、流量和安全组，用于配置 bookinfo 应用程序中服务的各个方面。
