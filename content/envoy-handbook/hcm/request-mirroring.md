---
weight: 11
title: 请求镜像
date: '2022-05-18T00:00:00+08:00'
type: book
---

使用路由级别的请求镜像策略（`request_mirroring_policies`），我们可以配置 Envoy 将流量从一个集群镜像到另一个集群。

流量镜像或请求镜像是指当传入的请求以一个集群为目标时，将其复制并发送给第二个集群。镜像的请求是 "发射并遗忘" 的，这意味着 Envoy 在发送主集群的响应之前不会等待影子集群的响应。

请求镜像模式不会影响发送到主集群的流量，而且因为 Envoy 会收集影子集群的所有统计数据，所以这是一种有用的测试技术。

除了 "发送并遗忘" 之外，还要确保你所镜像的请求是空闲的。否则，镜像请求会扰乱你的服务与之对话的后端。

影子请求中的 `authority/host` 头信息将被添加 `-shadow`字符串。

为了配置镜像策略，我们在要镜像流量的路由上使用 `request_mirror_policies `字段。我们可以指定一个或多个镜像策略，以及我们想要镜像的流量的部分。

```yaml
  route_config:
    name: my_route
    virtual_hosts:
    - name: httpbin
      domains: ["*"]
      routes:
      - match:
          prefix: /
        route:
          cluster: httpbin
          request_mirror_policies:
            cluster: mirror_httpbin
            runtime_fraction:
              default_value:
                numerator: 100
      ...
```

上述配置将 100% 地接收发送到集群 `httpbin` 的传入请求，并将其镜像到`mirror_httpbin`。