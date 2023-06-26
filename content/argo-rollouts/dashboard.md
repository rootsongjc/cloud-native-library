---
weight: 6
linkTitle: Dashboard
title: UI Dashboard
date: '2023-06-21T16:00:00+08:00'
type: book
---

Argo Rollouts Kubectl 插件可以提供本地 UI 仪表板来可视化你的 Rollouts。

要启动它，请在包含你的 Rollouts 的命名空间中运行 `kubectl argo rollouts dashboard` 。然后访问 `localhost:3100` 查看用户界面。

## 列表视图

![Rollouts 列表视图](../images/rollouts-list.png)

## 单独的 Rollout 视图

![Rollouts 视图](../images/rollout-ui.png)
