---
title: 数据平面
description: TSB Operator 和数据平面网关生命周期。
weight: 3
---

本页介绍如何利用 TSB Operator 来管理数据平面的网关配置。

TSB Operator 配置为监督数据平面网关组件的生命周期，主动监控所有命名空间中的 `IngressGateway` 、 `Tier1Gateway` 和 `EgressGateway` 自定义资源 (CR) 集群。默认情况下，数据平面网关组件驻留在 `istio-gateway` 命名空间中。你可以在数据平面安装 API 参考文档中找到有关自定义资源 API 的全面详细信息。

数据平面 Operator 监视其创建的 Kubernetes 资源。每当它检测到监视事件（例如删除部署）时，它都会启动协调以将系统恢复到所需状态，从而有效地重新创建任何已删除的部署。

{{<callout note "控制平面要求">}}

为了让 TSB Operator 管理数据平面网关组件，同一集群中必须存在功能齐全的控制平面。这就需要有一个有效的 TSB Operator 来管理控制平面，以及有效的 `ControlPlane` 自定义资源 (CR)。

{{</callout>}}

## 组件

![数据平面 Operator](../../../assets/concepts/data-plane-operator.svg)

以下是你可以使用数据平面 Operator 配置和管理的自定义组件类型：

| 组件  | Service                                                      | Deployment                                                   |
| :---- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| istio | istio-operator-metrics（用户在应用程序命名空间中配置的 istio 代理服务） | istio-operator（由用户在应用程序命名空间中配置的 istio 代理部署） |

在其专用命名空间中，TSB Operator 生成名为 `tsb-gateways` 的 `IstioOperator` 自定义资源 (CR)，并继续部署 Istio Operator。

默认情况下，生成的 `IstioOperator` CR 启用了 `ingressGateway` 和 `egressGateway` 组件。所有其他 Istio 组件在 CR 中都被明确禁用。这种特殊的配置将网关升级的生命周期与控制平面升级分离。

当用户在集群内的各个命名空间中创建和部署 `IngressGateway` 、 `Tier1Gateway` 和 `EgressGateway` 自定义资源 (CR) 时，TSB Operator 将转换这些资源并更新数据平面网关组件的命名空间中名为 `tsb-gateways` 的 `IstioOperator` CR。然后，部署在此命名空间中的 Istio Operator 将代表 TSB Operator 管理入口和出口 Envoy 网关的生命周期。这些特使网关对于处理 TSB 服务网格中托管的服务的入口和出口至关重要。

