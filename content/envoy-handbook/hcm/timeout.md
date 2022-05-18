---
weight: 9
title: 超时
date: '2022-05-18T00:00:00+08:00'
type: book
---

Envoy 支持许多可配置的超时，这取决于你使用代理的场景。

我们将在 HCM 部分看一下不同的可配置超时。请注意，其他过滤器和组件也有各自的超时时间，我们在此不做介绍。

在配置的较高层次上设置的一些超时 —— 例如在 HCM 层次，可以覆盖较低层次上的配置，例如 HTTP 路由层次。

最著名的超时可能是请求超时。请求超时（`request_timeout`）指定了 Envoy 等待接收整个请求的时间（例如 `120s`）。当请求被启动时，该计时器被激活。当最后一个请求字节被发送到上游时，或者当响应被启动时，定时器将被停用。默认情况下，如果没有提供或设置为 0，则超时被禁用。

类似的超时称为 `idle_timeout`，表示如果没有活动流，下游或上游连接何时被终止。默认的空闲超时被设置为 1 小时。空闲超时可以在 HCM 配置的 `common_http_protocol_options` 中设置，如下所示。

```yaml
...
filters:
- name: envoy.filters.network.http_connection_manager
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
    stat_prefix: ingress_http
    common_http_protocol_options:
      # 设置空闲超时为 10 分钟
      idle_timeout: 600s
...
```

为了配置上游连接的空闲超时，我们可以使用相同的字段 `common_http_protocol_options`，但在集群部分。

还有一个与 Header 有关的超时，叫做 `request_headers_timeout`。这个超时规定了 Envoy 等待接收请求头信息的时间（例如 `5s`）。该计时器在收到头信息的第一个字节时被激活。当收到头信息的最后一个字节时，该时间就会被停用。默认情况下，如果没有提供或设置为 0，则超时被禁用。

其他一些超时也可以设置，比如 `stream_idle_timeout`、`drain_timeout` 和 `delayed_close_timeout`。

接下来就是路由超时。如前所述，路由层面的超时可以覆盖 HCM 的超时和一些额外的超时。

路由 `timeout` 是指 Envoy 等待上游做出完整响应的时间。一旦收到整个下游请求，该计时器就开始计时。超时的默认值是 15 秒；但是，它与永不结束的响应（即流媒体）不兼容。在这种情况下，需要禁用超时，而应该使用 `stream_idle_timeout`。

我们可以使用 `idle_timeout` 字段来覆盖 HCM 层面上的 `stream_idle_timeout`。

我们还可以提到 `per_try_timeout` 设置。这个超时是与重试有关的，它为每次尝试指定一个超时。通常情况下，个别尝试应该使用比 `timeout `域设置的值更短的超时。