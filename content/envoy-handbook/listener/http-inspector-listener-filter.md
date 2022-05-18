---
weight: 30
title: HTTP 检查器监听器过滤器
date: '2022-05-18T00:00:00+08:00'
type: book
---

[HTTP 检查器监听器过滤器](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/listener_filters/http_inspector)（`envoy.filters.listener.http_inspector`）允许我们检测应用协议是否是 HTTP。如果协议不是 HTTP，监听器过滤器将通过该数据包。

如果应用协议被确定为 HTTP，它也会检测相应的 HTTP 协议（如 HTTP/1.x 或 HTTP/2）。

我们可以使用过滤器链匹配中的 `application_protocols` 字段来检查 HTTP 检查过滤器的结果。

让我们考虑下面的片段。

```yaml
...
    listener_filters:
    - name: envoy.filters.listener.http_inspector
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.filters.listener.http_inspector.v3.HttpInspector
    filter_chains:
    - filter_chain_match:
        application_protocols: ["h2"]
      filters:
      - name: my_http2_filter
        ... 
    - filter_chain_match:
        application_protocols: ["http/1.1"]
      filters:
      - name: my_http1_filter
...
```

我们在 `listener_filters` 字段下添加了 `http_inspector` 过滤器来检查连接并确定应用协议。如果 HTTP 协议是 HTTP/2（`h2c`），Envoy 会匹配第一个网络过滤器链（以 `my_http2_filter` 开始）。

另外，如果下游的 HTTP 协议是 HTTP/1.1（`http/1.1）`，Envoy 会匹配第二个过滤器链，并从名为 `my_http1_filter` 的过滤器开始运行过滤器链。