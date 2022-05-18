---
weight: 20
title: 配置访问记录器
date: '2022-05-18T00:00:00+08:00'
type: book
---

我们可以在 HTTP 或 TCP 过滤器级别和监听器级别上配置访问记录器。我们还可以配置多个具有不同日志格式和日志沉积的访问日志。**日志沉积（log sink）** 是一个抽象的术语，指的是日志写入的位置，例如，写入控制台（stdout、stderr）、文件或网络服务。

要配置多个访问日志的情况是，我们想在控制台（标准输出）中看到高级信息，并将完整的请求细节写入磁盘上的文件。用于配置访问记录器的字段被称为 `access_log`。

让我们看看在 HTTP 连接管理器（HCM）层面上启用访问日志到标准输出（`StdoutAccessLog`）的例子。

```yaml
- filters:
  - name: envoy.filters.network.http_connection_manager
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
      stat_prefix: ingress_http
      access_log:
      - name: envoy.access_loggers.stdout
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
```

Envoy 的目标是拥有可移植和可扩展的配置：类型化的配置。这样做的一个副作用是配置的名字很冗长。例如，为了启用访问日志，我们找到 HTTP 配置类型的名称，然后找到对应于控制台的类型（`StdoutAccessLog`）。

`StdoutAccessLog` 配置将日志条目写到标准输出（控制台）。其他支持的访问日志沉积有以下几种：

- 文件 (`FileAccessLog`)
- gRPC（`HttpGrpcAccessLogConfig` 和 `TcpGrpcAccessLogConfig`）
- 标准错误（`StderrAccessLog）`
- Wasm (`WasmAccessLog`)
- Open Telemetry

文件访问日志允许我们将日志条目写到配置中指定的文件中。例如：

```yaml
- filters:
  - name: envoy.filters.network.http_connection_manager
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
      stat_prefix: ingress_http
      access_log:
      - name: envoy.access_loggers.file
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
          path: ./envoy-access-logs.log
```

注意名称（`envoy.access_loggers.file`）和类型（`file.v3.FileAccessLog`）的变化。此外，我们还提供了我们希望 Envoy 存储访问日志的路径。

gRPC 访问日志沉积将日志发送到 HTTP 或 TCP gRPC 日志服务。为了使用 gRPC 日志沉积，我们必须建立一个 gRPC 服务器，其端点要实现 MetricsService，特别是 `StreamMetrics` 函数。然后，Envoy 可以连接到 gRPC 服务器并将日志发送给它。

在此之前，我们提到了默认的访问日志格式，它是由不同的命令操作符组成的。

```
[%start_time%] "%req(:method)%req(x-envoy-original-path?:path)%%protocol%"
%response_code% %response_flags% %bytes_received% %bytes_sent% %duration% %。
%resp(x-envoy-upstream-service-time)% "%req(x-forwarded-for)%" "%req(user-agent)%"
"%req(x-request-id)%" "%req(:authority)%" "%upstream_host%"
```

日志条目的格式是可配置的，可以使用 `log_format` 字段进行修改。使用 `log_format`，我们可以配置日志条目包括哪些值，并指定我们是否需要纯文本或 JSON 格式的日志。

例如，我们只想记录开始时间、响应代码和用户代理。我们会这样配置它。

```yaml
- filters:
  - name: envoy.filters.network.http_connection_manager
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
      stat_prefix: ingress_http
      access_log:
      - name: envoy.access_loggers.stdout
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
          log_format:
            text_format_source:
              inline_string: "%START_TIME% %RESPONSE_CODE% %REQ(USER-AGENT)%"
```

一个使用上述格式的日志条目样本看起来是这样的：

```
2021-11-01T21:32:27.170Z 404 curl/7.64.0
```

同样，如果我们希望日志是 JSON 等结构化格式，我们也可以不提供文本格式，而是设置 JSON 格式字符串。

为了使用 JSON 格式，我们必须提供一个格式字典，而不是像纯文本格式那样提供一个单一的字符串。

下面是一个使用相同的日志格式的例子，但用 JSON 写日志条目来代替。

```yaml
- filter:
  - name: envoy.filters.network.http_connection_manager
    typed_config:
      "@type": type.googleapis.com/envoy.extensions. filters.network.http_connection_manager.v3.HttpConnectionManager
      stat_prefix: ingress_http
      access_log:
      - name: envoy.access_loggers.stdout
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
          log_format:
            json_format:
              start_time:"%START_TIME%"
              response_code:"%response_code%"
              user_agent:"%req(user-agent)%"
```

上述片段将产生以下日志条目。

```json
{"user_agent":"curl/7.64.0","response_code":404,"start_time":"2021-11-01T21:37:59.979Z"}
```

某些命令操作符，如 `FILTER_STATE` 或 `DYNAMIC_METADATA`，可能产生嵌套的 JSON 日志条目。

日志格式也可以使用通过 `formatters` 字段指定的 formatter 插件。当前版本中有两个已知的格式化插件：元数据（`envoy.formatter.metadata`）和无查询请求（`envoy.formatter.req_without_query`）扩展。

元数据格式化扩展实现了 METADATA 命令操作符，允许我们输出不同类型的元数据（DYNAMIC、CLUSTER 或 ROUTE）。

同样，`req_without_query` 格式化允许我们使用 `REQ_WITHOUT_QUERY` 命令操作符，其工作方式与 `REQ` 命令操作符相同，但会删除查询字符串。该命令操作符用于避免将任何敏感信息记录到访问日志中。

下面是一个如何提供格式化器以及如何在 `inline_string` 中使用它的例子。

```yaml
- filters:
  - name: envoy.filters.network.http_connection_manager
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
      stat_prefix: ingress_http
      access_log:
      - name: envoy.access_loggers.stdout
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
          log_format:
            text_format_source:
              inline_string: "[%START_TIME%] %REQ(:METHOD)% %REQ_WITHOUT_QUERY(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%"
            formatters:
            - name: envoy.formatter.req_without_query
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.formatter.req_without_query.v3.ReqWithoutQuery
```

上述配置中的这个请求 `curl localhost:10000/?hello=1234` 会产生一个不包括查询参数（`hello=1234`）的日志条目。

```
[2021-11-01t21:48:55.941z] get / http/1.1
```
