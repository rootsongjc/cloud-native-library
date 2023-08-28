---
title: 创建工作区
weight: 4
---

在本节中，你将了解如何创建一个名为 `bookinfo-ws` 并绑定到 `bookinfo` 命名空间的 TSB 工作区。

## 先决条件

在继续之前，请确保你已完成以下任务：

- 熟悉 TSB 概念。
- 安装 TSB 演示环境。
- 部署 Istio Bookinfo 示例应用程序。
-  创建一个租户。

## 使用用户界面

1. 在左侧面板的“租户”下，选择“工作区”。
2. 单击该卡可添加新的工作区。
3. 输入工作区 ID 作为 `bookinfo-ws` 。
4. 为你的工作区提供显示名称和描述。
5. 输入 `demo/bookinfo` 作为初始命名空间选择器。
6.  单击添加。

如果你之前已成功启动演示应用程序，你应该会看到类似以下内容的内容：

-  1 个集群
-  1 命名空间
-  4 服务
-  1 个工作区

## 使用tctl

创建以下 `workspace.yaml` 文件：

```yaml
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: tetrate
  tenant: tetrate
  name: bookinfo-ws
spec:
  namespaceSelector:
    names:
      - "*/bookinfo"
```

使用 `tctl` 应用配置：

```bash
tctl apply -f workspace.yaml
```

如果你之前已成功登录演示应用程序并转到 UI 显示租户，你应该会看到类似于以下内容的内容：

![TSB 租户 UI：对象已创建](../../assets/quickstart/tenant-stats.png)

TSB 租户 UI：创建的对象

-  1 个集群
-  1 命名空间
-  4 服务
-  1 个工作区

通过执行这些步骤，你已成功创建了一个名为 `bookinfo-ws` 并绑定到 `bookinfo` 命名空间的 TSB 工作区。