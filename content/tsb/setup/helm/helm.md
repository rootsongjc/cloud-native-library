---
title: TSB Helm Chart
description: 如何使用 Helm Charts 安装 Tetrate Service Bridge (TSB) 的不同组件。
weight: 1
---

## 概述

本文介绍如何使用 [Helm](https://helm.sh) Charts 来安装 Tetrate Service Bridge (TSB) 的不同组件。假设你的系统上已经安装了 [Helm](https://helm.sh/docs/intro/install/)。

TSB 为其 [平面](../../../concepts/architecture#overall-architecture) 中的每一个都提供了一个图表：

- [管理平面](../managementplane)：安装 TSB 管理平面Operator（可选择安装 MP CR 和/或密钥）。
- [控制平面](../controlplane)：安装 TSB 控制平面Operator（可选择安装 MP CR 和/或密钥）。
- [数据平面](../dataplane)：安装 TSB 数据平面Operator。

每个Chart都安装了相应平面的Operator。管理平面和控制平面都允许创建触发Operator的相应资源（使用 `spec` 属性）以部署所有 TSB 组件和/或必需的密钥（使用 `secrets` 属性）以使其正常运行。

这种行为让你选择完全配置 TSB 并与 CD 流水线集成的方式。你可以使用 Helm 来：

- 仅安装Operator
- 安装/升级平面资源（管理平面或控制平面 CR）以及Operator
- 安装/升级Operator和密钥
- 一次安装/升级它们（Operator、资源、密钥）

关于密钥，要牢记 `helm install/upgrade` 命令接受可以由不同来源提供的不同文件，使用其中一个源提供规范，另一个源提供密钥。

还有一个额外的配置 (`secrets.keep`)，用于保留已安装的密钥并避免删除它们。有了这个功能，密钥只需应用一次，以后的升级不会删除它们。

默认情况下，Helm 图表还会安装 TSB CRD。如果你希望跳过 CRD 安装步骤，可以传递 `--skip-crds` 标志。

## 安装过程

### 先决条件

在开始之前，请确保你已经：

1. 检查了[要求](../../requirements-and-download)
2. 安装了 [Helm](https://helm.sh/docs/intro/install/)
3. 安装了 [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
4. [同步](../../requirements-and-download#sync-tetrate-service-bridge-images) 了 Tetrate Service Bridge 镜像

### 配置 Helm 存储库

- 添加存储库：
  ```shell
  helm repo add tetrate-tsb-helm 'https://charts.dl.tetrate.io/public/helm/charts/'
  helm repo update

- 列出可用版本：
  ```shell
  helm search repo tetrate-tsb-helm -l
  ```

### 安装

前往 [管理平面安装](../managementplane) 来安装 [TSB 管理平面组件](../../components#management-plane)。

前往 [控制平面安装](../controlplane) 以将 [TSB 控制平面组件](../../components#control-plane) 安装到你的应用程序集群中。这将引入你的应用程序集群到 TSB 中。

前往 [数据平面安装](../dataplane) 来安装将管理网关生命周期的 [TSB 数据平面组件](../../components#data-plane) 到你的应用程序集群中。

{{<callout note 基于版本的控制平面>}}
当你使用基于版本的控制平面时，不再需要 Data Plane Operator来管理 Istio 网关，你可以跳过数据平面安装。要了解有关基于版本的控制平面的更多信息，请前往 [Istio 隔离边界](../../isolation-boundaries)。

{{</callout>}}