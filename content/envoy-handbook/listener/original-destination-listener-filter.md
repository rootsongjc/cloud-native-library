---
weight: 40
title: 原始目的地监听器过滤器
date: '2022-05-18T00:00:00+08:00'
type: book
---

[原始目的地过滤器](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/listener_filters/original_dst_filter)（`envoy.filters.listener.original_dst`）会读取 `SO_ORIGINAL_DST` 套接字选项。当一个连接被 iptables `REDIRECT` 或 `TPROXY` 目标（如果`transparent`选项被设置）重定向时，这个选项被设置。该过滤器可用于与 `ORIGINAL_DST` 类型的集群连接。

当使用 `ORIGINAL_DST` 集群类型时，请求会被转发到由重定向元数据寻址的上游主机，而不做任何主机发现。因此，在集群中定义任何端点都是没有意义的，因为端点是从原始数据包中提取的，并不是由负载均衡器选择。

我们可以将 Envoy 作为一个通用代理，使用这种集群类型将所有请求转发到原始目的地。

要使用 `ORIGINAL_DST` 集群，流量需要通过 iptables `REDIRECT` 或 `TPROXY` 目标到达 Envoy。

```yaml
...
listener_filters:
- name: envoy.filters.listener.original_dst
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.listener.original_dst.v3.OriginalDst
...
clusters:
  - name: original_dst_cluster
    connect_timeout: 5s
    type: ORIGNAL_DST
    lb_policy: CLUSTER_PROVIDED
```

# 