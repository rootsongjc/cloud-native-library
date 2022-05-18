---
weight: 10
title: 服务发现
date: '2022-05-18T00:00:00+08:00'
type: book
---

集群可以在配置文件中静态配置，也可以通过集群发现服务（CDS）API 动态配置。每个集群都是一个端点的集合，Envoy 需要解析这些端点来发送流量。

解析端点的过程被称为**服务发现**。

## 什么是端点？

集群是一个识别特定主机的端点的集合。每个端点都有以下属性。

**地址 (`address`)**

该地址代表上游主机地址。地址的形式取决于集群的类型。对于 STATIC 或 EDS 集群类型，地址应该是一个 IP，而对于 LOGICAL 或 STRICT DNS 集群类型，地址应该是一个通过 DNS 解析的主机名。

**主机名 (`hostname`)**

一个与端点相关的主机名。注意，主机名不用于路由或解析地址。它与端点相关联，可用于任何需要主机名的功能，如自动主机重写。

**健康检查配置（`health_check_config`）**

可选的健康检查配置用于健康检查器联系健康检查主机。该配置包含主机名和可以联系到主机以执行健康检查的端口。注意，这个配置只适用于启用了主动健康检查的上游集群。

## 服务发现类型

有五种支持的服务发现类型，我们将更详细地介绍。

### 静态 (`STATIC`)

静态服务发现类型是最简单的。在配置中，我们为集群中的每个主机指定一个已解析的网络名称。例如：

```yaml
  clusters:
  - name: my_cluster_name
    type: STATIC
    load_assignment:
      cluster_name: my_service_name
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 8080
```

注意，如果我们不提供类型，默认为 `STATIC`。

### 严格的 DNS（`STRICT_DNS`）

通过严格的 DNS，Envoy 不断地、异步地解析集群中定义的 DNS 端点。如果 DNS 查询返回多个 IP 地址，Envoy 假定它们是集群的一部分，并在它们之间进行负载均衡。同样，如果 DNS 查询返回 0 个主机，Envoy 就认为集群没有任何主机。

关于健康检查的说明——如果多个 DNS 名称解析到同一个 IP 地址，则不共享健康检查。这可能会给上游主机造成不必要的负担，因为 Envoy 会对同一个 IP 地址进行多次健康检查（跨越不同的 DNS 名称）。

当  `respect_dns_ttl ` 字段被启用时，我们可以使用  `dns_refresh_rate ` 控制 DNS 名称的连续解析。如果不指定，DNS 刷新率默认为 5000ms。另一个设置（`dns_failure_refresh_rate`）控制故障时的刷新频率。如果没有提供，Envoy 使用 `dns_refresh_rate`。

下面是一个 STRICT_DNS 服务发现类型的例子。

```yaml
  clusters:
  - name: my_cluster_name
    type: STRICT_DNS
    load_assignment:
      cluster_name: my_service_name
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: my-service
                port_value: 8080
```

### 逻辑 DNS（`LOGICAL_DNS`）

逻辑 DNS 服务发现与严格 DNS 类似，它使用异步解析机制。然而，它只使用需要启动新连接时返回的第一个 IP 地址。

因此，一个逻辑**连接池**可能包含与各种不同上游主机的物理连接。这些连接永远不会耗尽，即使在 DNS 解析返回零主机的情况下。

> **什么是连接池？**
>
> 集群中的每个端点将有一个或多个连接池。例如，根据所支持的上游协议，每个协议可能有一个连接池分配。Envoy 中的每个工作线程也为每个集群维护其连接池。例如，如果 Envoy 有两个线程和一个同时支持 HTTP/1 和 HTTP/2 的集群，将至少有四个连接池。连接池的方式是基于底层线程协议的。对于 HTTP/1.1，连接池根据需要获取端点的连接（最多到断路限制）。当请求变得可用时，它们就被绑定到连接上。 当使用 HTTP/2 时，连接池在**一个连接**上复用多个请求，最多到 `max_concurrent_streams` 和 `max_requests_per_connections` 指定的限制。HTTP/2 连接池建立尽可能多的连接，以满足请求。

逻辑 DNS 的一个典型用例是用于大规模网络服务。通常使用轮询 DNS，它们在每次查询时返回多个 IP 地址的不同结果。如果我们使用严格的 DNS 解析，Envoy 会认为集群端点在每次内部解析时都会改变，并会耗尽连接池。使用逻辑 DNS，连接将保持存活，直到它们被循环。

与严格的 DNS 一样，逻辑 DNS 也使用 `respect_dns_ttl `和 `dns_refresh_rate ` 字段来配置 DNS 刷新率。

```yaml
  clusters:
  - name: my_cluster_name
    type: LOGICAL_DNS
    load_assignment:
      cluster_name: my_service_name
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: my-service
                port_value: 8080
```

### 端点发现服务（`EDS`）

Envoy 可以使用端点发现服务来获取集群的端点。通常情况下，这是首选的服务发现机制。Envoy 获得每个上游主机的显式知识（即不需要通过 DNS 解析的负载均衡器进行路由）。每个端点都可以携带额外的属性，可以告知 Envoy 负载均衡的权重和金丝雀状态区，等等。

```yaml
  clusters:
  - name: my_cluster_name
    type: EDS
    eds_cluster_config:
      eds_config:
        ...
```

我们会在动态配置和 xDS 一章中更详细地解释动态配置。

### 原始目的地（`ORIGINAL_DST`）

当与 Envoy 的连接通过 iptables REDIRECT 或 TPROXY 目标或与代理协议的连接时，我们使用原来的目标集群类型。

在这种情况下，请求被转发到重定向元数据（例如，使用 `x-envoy-original-dst-host` 头）地址的上游主机，而无需任何配置或上游主机发现。

当上游主机的连接闲置时间超过 `cleanup_interval` 字段中指定的时间（默认为 5000 毫秒）时，这些连接会被汇集起来并被刷新。

```yaml
clusters:
  - name: original_dst_cluster
    type: ORIGINAL_DST
    lb_policy: ORIGINAL_DST_LB
```

ORIGINAL_DST 集群类型可以使用的唯一负载均衡策略是 ORIGINAL_DST_LB 策略。

除了上述服务发现机制外，Envoy 还支持自定义集群发现机制。我们可以使用 `cluster_type` 字段配置自定义的发现机制。

Envoy 支持两种类型的健康检查，主动和被动。我们可以同时使用这两种类型的健康检查。在主动健康检查中，Envoy 定期向端点发送请求以检查其状态。使用被动健康检查，Envoy 监测端点如何响应连接。它使 Envoy 甚至在主动健康检查将其标记为不健康之前就能检测到一个不健康的端点。Envoy 的被动健康检查是通过异常点检测实现的。