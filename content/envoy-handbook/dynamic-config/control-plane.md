---
weight: 30
title: 来自控制平面的动态配置
date: '2022-05-18T00:00:00+08:00'
type: book
---

使用控制平面来更新 Envoy 比使用文件系统的配置更复杂。我们必须创建自己的控制平面，实现发现服务接口。[这里](https://github.com/envoyproxy/go-control-plane/tree/main/internal/example)有一个 xDS 服务器实现的简单例子。这个例子显示了如何实现不同的发现服务，并运行 Envoy 连接的 gRPC 服务器的实例来检索配置。

![Envoy 的动态配置](../../images/008i3skNly1gz9lnkio4dj31b40u0myu.jpg "Envoy 的动态配置")

Envoy 方面的动态配置与文件系统的配置类似。这一次，不同的是，我们提供了实现发现服务的 gRPC 服务器的位置。我们通过静态资源指定一个集群来做到这一点。

```yaml
...
dynamic_resources:
  lds_config:
    resource_api_version: V3
    api_config_source:
      api_type: GRPC
      transport_api_version: V3
      grpc_services:
        - envoy_grpc:
            cluster_name: xds_cluster
  cds_config:
    resource_api_version: V3
    api_config_source:
      api_type: GRPC
      transport_api_version: V3
      grpc_services:
        - envoy_grpc:
            cluster_name: xds_cluster

static_resources:
  clusters:
  - name: xds_cluster
    type: STATIC
    load_assignment:
      cluster_name: xds_cluster
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 9090
```

控制平面不需要在 Envoy 概念上操作。它可以抽象出配置。它也可以使用图形用户界面或不同的 YAML、XML 或任何其他配置文件来收集用户的输入。重要的是，无论高级别配置是如何进入控制平面的，它都需要被翻译成 Envoy xDS API。

例如，Istio 是 Envoy 代理机群的控制平面，可以通过各种自定义资源定义（VirtualService、Gateway、DestinationRule...）进行配置。除了上层配置外，在 Istio 中，Kubernetes 环境和集群内运行的服务也被用来作为生成 Envoy 配置的输入。上层配置和环境中发现的服务可以一起作为控制平面的输入。控制平面可以接受这些输入，将其转化为 Envoy 可读的配置，并通过 gRPC 将其发送给 Envoy 实例。