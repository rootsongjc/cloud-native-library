---
title: 管理平面
description: TSB Operator 和管理平面生命周期。
weight: "1"
---

本页深入介绍了 TSB Operator 如何配置管理平面组件，并概述了 TSB Operator 管理的各种组件。

TSB Operator 配置为监督管理平面组件的生命周期，主动监视部署的同一命名空间内的 `ManagementPlane` 自定义资源 (CR)。默认情况下，管理平面驻留在 `tsb` 命名空间中。你可以参阅[管理平面安装 API](../../../refs/install/managementplane/v1alpha1/spec) 参考文档，了解有关自定义资源 API 的全面详细信息。

## 组件

![管理平面组件](../../../assets/concepts/management-plane-operator.svg)

以下是你可以使用管理平面 Operator 配置和管理的各种类型的自定义组件：

| 组件        | Service              | Deployment           | Cronjobs |
| :---------- | :------------------- | :------------------- | :------- |
| apiServer   | tsb                  | tsb                  | teamsync |
| iamServer   | iam                  | iam                  |          |
| webUI       | web                  | web                  |          |
| frontEnvoy  | envoy                | envoy                |          |
| oap         | oap                  | oap                  |          |
| collector   | otel-collector       | otel-collector       |          |
| xcpOperator | xcp-operator-central | xcp-operator-central |          |
| xcpCentral  | xcp-central          | central              |          |
| mpc         | mpc                  | mpc                  |          |

Operator 配置并安装以下组件：

- apiServer：TSB API 服务器，负责：
  - 管理用户创建的服务网格配置
  - 将服务网格配置推送到控制平面集群
  - 管理从控制平面集群推送的集群信息
  - 加强用户操作授权
  - 存储操作审计日志
- frontEnvoy：充当管理平面的入口网关。
- iamServer：管理用户和 TSB 代理令牌身份验证。
- webUI：TSB UI 服务器。
- oap：为 TSB UI 提供 GraphQL 查询并聚合跨集群指标。
- 收集器：一个开放遥测收集器，从管理和控制平面组件收集指标并通过 Prometheus 指标端点公开它们。
- xcpOperator：控制平面 Operator，管理管理平面所需的控制平面组件。
- xcpCentral：控制平面的核心组件，管理平面使用它来向每个集群分发配置并接收有关每个集群状态的信息。
- mpc：apiServer 和 xcpCentral 之间的配置转换组件。

{{<callout note "演示安装">}}

在演示安装过程中，TSB Operator 还设置 PostgreSQL 和 Elasticsearch 组件。但是，这些仅用于演示目的，Tetrate 不支持用于生产环境或深入的系统评估。

{{</callout>}}
