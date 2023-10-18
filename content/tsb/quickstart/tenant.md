---
title: 创建租户
description: 使用 UI 或 tctl 创建 TSB 租户。
weight: 3
---

在本部分中，你将了解如何使用 TSB UI 或 `tctl` 创建 TSB 租户。

## 先决条件

在继续之前，请确保你已完成以下任务：

- 熟悉 TSB 概念。
- 安装 TSB 演示环境。
- 部署 Istio Bookinfo 示例应用程序。

## 使用用户界面

1. 在左侧面板的组织下，选择租户。
2. 单击该卡以添加新租户。
3. 输入租户 ID `tetrate` 。
4. 向你的租户提供显示名称和描述。
5.  单击添加。

## 使用 tctl

创建以下 `tenant.yaml` 文件：

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: tetrate
  name: tetrate
spec:
  displayName: Tetrate
```

使用 `tctl` 应用配置：

```bash
tctl apply -f tenant.yaml
```

通过执行这些步骤，你将成功创建一个名为 `tetrate` 的 TSB 租户。该租户可用于组织和管理你的 TSB 环境。
