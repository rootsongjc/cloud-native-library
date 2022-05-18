---
weight: 50
title: 原始源监听器过滤器
date: '2022-05-18T00:00:00+08:00'
type: book
---

[原始源过滤器](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/listener_filters/original_src_filter)（`envoy.filters.listener.original_src`）在 Envoy 的上游（接收 Envoy 请求的主机）一侧复制了连接的下游（连接到 Envoy 的主机）的远程地址。

例如，如果我们用 `10.0.0.1`  发送请求给 Envoy 连接到上游，源 IP 是 `10.0.0.1` 。这个地址是由代理协议过滤器决定的（接下来解释），或者它可以来自于可信的 HTTP  Header。

```yaml
- name: envoy.filters.listener.original_src
  typed_config:
    "@type": type.googleapis.com/envoy.extensions. filters.listener.original_src.v3.OriginalSrc
    mark: 100
```

该过滤器还允许我们在上游连接的套接字上设置 `SO_MARK` 选项。`SO_MARK` 选项用于标记通过套接字发送的每个数据包，并允许我们做基于标记的路由（我们可以在以后匹配标记）。

上面的片段将该标记设置为 100。使用这个标记，我们可以确保非本地地址在绑定到原始源地址时可以通过 Envoy 代理路由回来。