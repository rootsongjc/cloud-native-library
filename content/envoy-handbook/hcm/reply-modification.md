---
weight: 7
title: 修改响应
date: '2022-05-18T00:00:00+08:00'
type: book
---

HCM 支持修改和定制由 Envoy 返回的响应。请注意，这对上游返回的响应不起作用。

本地回复是由 Envoy 生成的响应。本地回复的工作原理是定义一组**映射器（mapper）**，允许过滤和改变响应。例如，如果没有定义任何路由或上游集群，Envoy 会发送一个本地 HTTP 404。

每个映射器必须定义一个过滤器，将请求属性与指定值进行比较（例如，比较状态代码是否等于 403）。我们可以选择从[多个过滤器](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/accesslog/v3/accesslog.proto#envoy-v3-api-msg-config-accesslog-v3-accesslogfilter)来匹配状态代码、持续时间、Header、响应标志等。

除了过滤器字段，映射器还有新的状态代码（`status_code`）、正文（`body` 和 `body_format_override`）和 Header（`headers_to_add`）字段。例如，我们可以有一个匹配请求状态代码 403 的过滤器，然后将状态代码改为 500，更新正文，或添加 Header。

下面是一个将 HTTP 503 响应改写为 HTTP 401 的例子。注意，这指的是 Envoy 返回的状态代码。例如，如果上游不存在，Envoy 将返回一个 503。

```yaml
...
- name: envoy.filters.network.http_connection_manager
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
    local_reply_config:
      mappers:
      - filter:
          status_code_filter:
            comparison:
              op: EQ
              value:
                default_value: 503
                runtime_key: some_key
        headers_to_add:
          - header:
              key: "service"
              value: "unavailable"
            append: false
        status_code: 401
        body:
          inline_string: "Not allowed"
```

> 注意 `runtime_key` 字段是必须的。如果 Envoy 找不到运行时密钥，它就会返回到 `default_value`。