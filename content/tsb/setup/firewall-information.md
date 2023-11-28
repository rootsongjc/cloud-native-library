---
title: 防火墙信息
description: 防火墙规则指南。
weight: 10

---

如果你的环境有严格的网络策略，防止两个命名空间之间进行任何未经授权的通信，你可能需要添加一个或多个例外到你的网络策略，以允许 sidecar 与本地 Istio 控制平面之间的通信，以及本地 Istio 控制平面与 TSB 管理平面之间的通信。

以下信息可用于推导适当的防火墙规则集。

## TSB、控制平面和工作负载之间的通信

### TSB 和 Istio 之间

{{<callout note "TSB 负载均衡器端口">}}
TSB 负载均衡器（也称为 `front-envoy`）的默认端口为 8443。此端口值是可配置的。例如，它可以更改为 443。如果更改了默认端口，则通过 `front-envoy` 通信的所有组件都需要相应调整以匹配用户定义的 `front-envoy` 端口的值。
{{</callout>}}

| 源                            | 目标                                                         |
| ----------------------------- | ------------------------------------------------------------ |
| `xcp-edge.istio-system`       | TSB 负载均衡器 IP，端口 `9443`                               |
| `oap.istio-system`            | TSB 负载均衡器 IP，端口 `8443` 或用户定义的 `front-envoy` 端口 |
| `otel-collector.istio-system` | TSB 负载均衡器 IP，端口 `8443` 或用户定义的 `front-envoy` 端口 |
| `oap.istio-system`            | Elasticsearch 目标 IP 和端口  *(如果使用 Elasticsearch 的演示部署或使用 `front-envoy` 作为 Elasticsearch 代理，请更改为 TSB 负载均衡器 IP，端口 `8443` 或用户定义的 `front-envoy` 端口)* |

### k8s 上的 Sidecars 和 Istio 控制平面之间

| 源                                                           | 目标                                |
| ------------------------------------------------------------ | ----------------------------------- |
| 任何应用程序命名空间中的 sidecar 或负载均衡器，或  任何命名空间中的共享负载均衡器以访问 Istio Pilot xDS 服务器。 | `istiod.istio-system`，端口 `15012` |
| 任何应用程序命名空间中的 sidecar 或负载均衡器，或  任何命名空间中的共享负载均衡器以访问 SkyWalking OAP 指标服务器。 | `oap.istio-system`，端口 `11800`    |
| 任何应用程序命名空间中的 sidecar 或负载均衡器，或  任何命名空间中的共享负载均衡器以访问 SkyWalking OAP 跟踪服务器。 | `oap.istio-system`，端口 `9411`     |

### VM 上的 Sidecars 和 Istio 控制平面之间

| 源                                                           | 目标                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| VM 上的 sidecar 以访问 Istio Pilot xDS 服务器、SkyWalking OAP 指标服务器、跟踪服务器 | VM 网关（`vmgateway.istio-system`）负载均衡器 IP，<br />端口 `15443` |


### VM 上的 Sidecars 和 k8s 中的工作负载之间

| 源                                      | 目标                                                         |
| --------------------------------------- | ------------------------------------------------------------ |
| VM 上的 sidecar 以访问 k8s 中的工作负载 | 要么 k8s pod 直接，要么 VM 网关（`vmgateway.istio-system`）负载均衡器 IP，<br />端口 `15443` |


### k8s 中的工作负载和 VM 上的 Sidecars 之间

| 源                             | 目标  |
| ------------------------------ | ----- |
| k8s pod 以访问 VM 上的工作负载 | VM IP |


### 集群 A 中的工作负载和集群 B 中的工作负载之间

| 源                      | 目标                                                    |
| ----------------------- | ------------------------------------------------------- |
| k8s pod 或 VM（集群 A） | 每个服务网关负载均衡器 IP，端口 `15443`（集群 B） |
| k8s pod 或 VM（集群 B） | 每个服务网关负载均衡器 IP，端口 `15443`（集群 A） |

{{<callout warning 共享负载均衡器>}}
如果使用共享负载均衡器，则负载均衡器 envoy 需要能够与所有附加的应用程序及其服务通信。由于这些信息事先未知，我们无法确定在防火墙中打开的端口的确切信息。
{{</callout>}}


## TSB 组件端口

以下是 TSB 组件使用的端口和协议。

### Cert manager

| 端口  | 协议  | 描述              |
| ----- | ----- | ----------------- |
| 10250 | HTTPS | Webhooks 服务端口 |
| 6080  | HTTP  | 健康检查          |

### 管理平面

| 端口                                                         | 协议      | 描述                          |
| ------------------------------------------------------------ | --------- | ----------------------------- |
| 管理平面 Operator `tsb-operator-management-plane.tsb` |           |                               |
| 8383                                                         | HTTP      | Prometheus 遥测               |
| 443                                                          | HTTPS     | Webhooks 服务端口             |
| 9443                                                         | HTTPS     | Webhook 容器端口，从 443 转发 |
| TSB API 服务器 `tsb.tsb`                                 |           |                               |
| 8000                                                         | HTTP      | HTTP API                      |
| 9080                                                         | GRPC      | GRPC API                      |
| 42422                                                        | HTTP      | Prometheus 遥测               |
| 9082                                                         | HTTP      | 健康检查                      |
| Open Telemetry `otel-collector.tsb`                      |           |                               |
| 9090                                                         | HTTP      | Prometheus 遥测               |
| 9091                                                         | HTTP      | 收集器端点                    |
| 13133                                                        | HTTP      | 健康检查                      |
| TSB 前端 Envoy `envoy.tsb`                               |           |                               |
| 8443                                                         | HTTP/GRPC | TSB HTTP 和 GRPC API 端口     |
| 9443                                                         | TCP       | XCP 端口                      |
| IAM `iamserver.tsb`                                      |           |                               |
| 8000                                                         | HTTP      | HTTP API                      |
| 9080                                                         | GRPC      | GRPC API                      |
| 42422                                                        | HTTP      | Prometheus 遥测               |
| 9082                                                         | HTTP      | 健康检查                      |
| MPC `mpc.tsb`                                            |           |                               |
| 9080                                                         | GRPC      | GRPC API                      |
| 42422                                                        | HTTP      | Prometheus 遥测               |
| 9082                                                         | HTTP      | 健康检查                      |
| OAP `oap.tsb`                                            |           |                               |
| 11800                                                        | GRPC      | GRPC API                      |
| 12800                                                        | HTTP      | REST API                      |
| 1234                                                         | HTTP      | Prometheus 遥测               |
| 9411                                                         | HTTP      | 追踪查询                      |
| 9412                                                         | HTTP      | 追踪收集                      |
| TSB UI `web.tsb`                                         |           |                               |
| 8080                                                         | HTTP      | HTTP 服务端口和健康检查       |
| XCP Operator 中心 `xcp-operator-central.tsb`          |           |                               |
| 8383                                                         | HTTP      | Prometheus 遥测               |
| 443                                                          | HTTPS     | Webhooks 服务端口             |
| XCP 中心 `central.tsb`                                   |           |                               |
| 8090                                                         | HTTP      | 调试接口                      |
| 9080                                                         | GRPC      | GRPC API                      |
| 8080                                                         | HTTP      | Prometheus 遥测               |
| 443                                                          | HTTPS     | Webhooks 服务端口             |
| 8443                                                         | HTTPS     | Webhook 容器端口，从 443 转发 |

### 控制平面

| 端口                                                       | 协议  | 描述                                                         |
| ---------------------------------------------------------- | ----- | ------------------------------------------------------------ |
| 控制平面 Operator `tsb-operator-control-plane.istio-system` |       |                                                              |
| 8383                                                       | HTTP  | Prometheus 遥测                                              |
| 443                                                        | HTTPS | Webhooks 服务端口                                            |
| 9443                                                       | HTTPS | Webhook 容器端口，从 443 转发                                |
| Open Telemetry `otel-collector.tsb`                        |       |                                                              |
| 9090                                                       | HTTP  | Prometheus 遥测                                              |
| 9091                                                       | HTTP  | 收集器端点                                                   |
| 13133                                                      | HTTP  | 健康检查                                                     |
| OAP `oap.istio-system`                                     |       |                                                              |
| 11800                                                      | GRPC  | GRPC API                                                     |
| 12800                                                      | HTTP  | REST API                                                     |
| 1234                                                       | HTTP  | Prometheus 遥测                                              |
| 15021                                                      | HTTP  | Envoy sidecar 健康检查                                       |
| 15020                                                      | HTTP  | Envoy sidecar 合并的 Prometheus 遥测，来自 Istio 代理、Envoy 和应用程序 |
| 9411                                                       | HTTP  | 追踪查询                                                     |
| 9412                                                       | HTTP  | 追踪收集                                                     |
| Istio Operator `istio-operator.istio-system`               |       |                                                              |
| 443                                                        | HTTPS | Webhooks 服务端口                                            |
| 8383                                                       | HTTP  | Prometheus 遥测                                              |
| Istiod `istiod.istio-system`                               |       |                                                              |
| 443                                                        | HTTPS | Webhooks 服务端口                                            |
| 8080                                                       | HTTP  | 调试接口                                                     |
| 15010                                                      | GRPC  | XDS 和 CA 服务（明文，仅限安全网络）                         |
| 15012                                                      | GRPC  | XDS 和 CA 服务（TLS 和 mTLS，推荐用于生产环境）              |
| 15014 | HTTP | 控制平面监控 |
| 15017 | HTTPS	 | Webhook 容器端口，从 443 转发|
| XCP Operator 中心 `xcp-operator-edge.istio-system` | | 
| 8383 | HTTP | Prometheus 遥测|
| 443 | HTTPS | Webhooks 服务端口|
| XCP 中心 `edge.istio-system` | | 
| 8090 | HTTP | 调试接口|
| 9080 | GRPC | GRPC API|
| 8080 | HTTP | Prometheus 遥测|
| 443 | HTTPS | Webhooks 服务端口|
| 8443 | HTTPS | Webhook 容器端口，从 443 转发|
| Onboarding Operator `onboarding-operator.istio-system` | | 
| 443 | HTTPS | Webhooks 服务端口|
| 9443 | HTTPS | Webhook 容器端口，从 443 转发|
| 9082 | HTTP | 健康检查|
| Onboarding 仓库 `onboarding-repository.istio-system` | | 
| 8080 | HTTP | HTTP 服务端口|
| 9082 | HTTP | 健康检查|
| Onboarding 平面 `onboarding-plane.istio-system` | | 
| 8443 | HTTP | Onboarding API|
| 9082 | HTTP | 健康检查|
| VM 网关 `vmgateway.istio-system` | | 
| 15021 | HTTP | 健康检查|
| 15012 | HTTP | Istiod|
| 11800 | HTTP | OAP 指标|
| 9411 | HTTP | 追踪|
| 15443 | HTTPS | mTLS 流量端口|
| 443 | HTTPS | HTTPS 端口|

### 数据平面

| 端口                                                         | 协议  | 描述                                            |
| ------------------------------------------------------------ | ----- | ----------------------------------------------- |
| 数据平面 Operator `tsb-operator-data-plane.istio-gateway` |       |                                                 |
| 8383                                                         | HTTP  | Prometheus 遥测                                 |
| 443                                                          | HTTPS | Webhooks 服务端口                               |
| 9443                                                         | HTTPS | Webhook 容器端口，从 443 转发                   |
| Istio Operator `istio-operator.istio-gateway`        |       |                                                 |
| 443                                                          | HTTPS | Webhooks 服务端口                               |
| 8383                                                         | HTTP  | Prometheus 遥测                                 |
| Istiod `istiod.istio-gateway`                            |       |                                                 |
| 443                                                          | HTTPS | Webhooks 服务端口                               |
| 8080                                                         | HTTP  | 调试接口                                        |
| 15010                                                        | GRPC  | XDS 和 CA 服务（明文，仅限安全网络）            |
| 15012                                                        | GRPC  | XDS 和 CA 服务（TLS 和 mTLS，推荐用于生产环境） |
| 15014                                                        | HTTP  | 控制平面监控                                    |
| 15017                                                        | HTTPS | Webhook 容器端口，从 443 转发                   |

### Sidecars

参考 [Istio 使用的端口](https://istio.io/latest/docs/ops/deployment/requirements/#ports-used-by-istio) 查看 Istio Sidecar 代理使用的端口和协议列表。

