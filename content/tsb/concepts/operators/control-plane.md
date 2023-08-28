---
title: 控制平面
description: TSB Operator 和控制平面生命周期。
weight: 2
---

本页面深入介绍了 TSB Operator 如何管理控制平面组件的生命周期，并概述了你可以通过 TSB Operator 配置和管理的自定义资源。

TSB Operator 配置为监督控制平面组件的生命周期，主动监控部署的同一命名空间内的 `ControlPlane` 自定义资源 (CR)。默认情况下，控制平面位于 `istio-system` 命名空间中。有关自定义资源 API 的详细信息，你可以参考[控制平面安装 API 参考文档](../../../refs/install/controlplane/v1alpha1/spec)。

![控制平面 Operator](../../../assets/concepts/control-plane-operator.svg)

## 组件

以下是你可以使用控制平面 Operator 配置和管理的各种类型的自定义组件：

| 组件        | Service                                           | Deployment                                                   |
| :---------- | :------------------------------------------------ | :----------------------------------------------------------- |
| istio       | Istio-operator-metrics  <br />(istiod, vmgateway) | Istio-operator <br />(istiod vmgateway) <br />(istio-cni-node daemonset in kube-system namespace) |
| oap         | oap                                               | oap-deployment                                               |
| collector   | otel-collector                                    | otel-collector                                               |
| xcpOperator | xcp-operator-edge                                 | xcp-operator-edge                                            |
| xcpEdge     | xcp-edge                                          | edge                                                         |

由运营商编排和安装的组件包括：

- istio：开源 Istio Operator，TSB Operator 利用它来管理开源 Istio 组件。
- oap：负责收集和聚合网格和 Envoy 网关 RED 指标和跟踪数据。
- 收集器：开放遥测收集器，它从控制平面组件收集指标并通过 Prometheus 指标端点公开它们。
- xcpOperator：控制平面 Operator，将控制平面组件的任务委托给 TSB Operator。
- xcpEdge：负责将配置从 xcpCentral 转换为 Istio CRD，存储在本地，并将集群信息传输到 xcpCentral。

### Istio 作为 TSB 组件

在控制平面的上下文中，TSB  Operator 安装开源 Istio  Operator。Istio 及其运营商被认为是 TSB 控制平面组件的组成部分，在 TSB 运营商的直接管理下运行。需要注意的是，Istio 不是由用户直接配置的。相反，与 Istio 的交互始终通过 TSB Operator 的 `ControlPlane` CR 进行。

负责控制平面管理的 TSB  Operator 在控制平面的命名空间内创建一个名为 `tsb-istiocontrolplane` 的 IstioOperator CR。该 CR 指导 Istio  Operator 监督必要的 Istio（子）组件的部署。对于 TSB 控制平面，启用以下（子）组件： `pilot` 、 `cni` 和 `ingressGateway` 。

TSB `ingressGateway` （子）组件体现了 Envoy 的自定义配置，部署为 `vmgateway` 。它的主要作用是将来自服务网格装载虚拟机的流量路由到部署在 Kubernetes 集群内的服务。当虚拟机和 Kubernetes Pod 之间的直接通信不可行时，这特别有用。

{{<callout note "Sidecar 代理版本">}}

尽管 Sidecar 代理在技术上是数据平面的一部分，但它们的版本与控制平面 Operator 版本相关。

{{</callout>}}
