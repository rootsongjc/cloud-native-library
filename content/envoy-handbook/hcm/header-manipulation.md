---
weight: 6
title: Header 操作
date: '2022-05-18T00:00:00+08:00'
type: book
---

HCM 支持在加权集群、路由、虚拟主机和 / 或全局配置层面操纵请求和响应头。

注意，我们不能直接从配置中修改所有的 Header，使用 Wasm 扩展的情况除外。然后，我们可以修改 `:authority ` header，例如下面的情况。

不可变的头是伪头（前缀为`:`，如`:scheme`）和`host`头。此外，诸如 `:path `和 `:authority` 这样的头信息可以通过 `prefix_rewrite`、`regex_rewrite` 和  `host_rewrite` 配置来间接修改。

Envoy 按照以下顺序对请求 / 响应应用这些头信息：

1. 加权的集群级头信息
1. 路由级 Header
1. 虚拟主机级 Header
1. 全局级 Header

这个顺序意味着 Envoy 可能会用更高层次（路由、虚拟主机或全局）配置的头来覆盖加权集群层次上设置的 Header。

在每一级，我们可以设置以下字段来添加 / 删除请求 / 响应头。

- `response_headers_to_add`：要添加到响应中的 Header 信息数组。
- `response_headers_to_remove`：要从响应中移除的 Header 信息数组。
- `request_headers_to_add`：要添加到请求中的 Header 信息数组。
- `request_headers_to_remove`：要从请求中删除的 Header 信息数组。

除了硬编码标头值之外，我们还可以使用变量来为标头添加动态值。变量名称以百分数符号（%）为分隔符。支持的变量名称包括 `%DOWNSTREAM_REMOTE_ADDRESS%`、`%UPSTREAM_REMOTE_ADDRESS%`、`%START_TIME%`、`%RESPONSE_FLAGS%` 和更多。你可以在[这里](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#custom-request-response-headers)找到完整的变量列表。

让我们看一个例子，它显示了如何在不同级别的请求 / 响应中添加 / 删除头信息。

```yaml
route_config:
  response_headers_to_add:
    - header: 
        key: "header_1"
        value: "some_value"
      # 如果为真（默认），它会将该值附加到现有值上。
      # 否则它将替换现有的值
      append: false
  response_headers_to_remove: "header_we_dont_need"
  virtual_hosts:
  - name: hello_vhost
    request_headers_to_add:
      - header: 
          key: "v_host_header"
          value: "from_v_host"
    domains: ["hello.io"]
    routes:
      - match:
          prefix: "/"
        route:
          cluster: hello
        response_headers_to_add:
          - header: 
              key: "route_header"
              value: "%DOWNSTREAM_REMOTE_ADDRESS%"
      - match:
          prefix: "/api"
        route:
          cluster: hello_api
        response_headers_to_add:
          - header: 
              key: "api_route_header"
              value: "api-value"
          - header:
              key: "header_1"
              value: "this_will_be_overwritten"
```

## 标准 Header

Envoy 在收到请求（解码）和向上游集群发送请求（编码）时，会操作一组头信息。

当使用裸露的 Envoy 配置将流量路由到单个集群时，在编码过程中会设置以下头信息。

```
':authority', 'localhost:10000'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.64.0'
'accept', '*/*'
'x-forwarded-proto', 'http'
'x-request-id', '14f0ac76-128d-4954-ad76-823c3544197e'
'x-envoy-expected-rq-timeout-ms', '15000'
```

在编码（响应）时，会发送一组不同的头信息。

```
':status', '200'
'x-powered-by', 'Express'
'content-type', 'text/html; charset=utf-8'
'content-length', '563'
'etag', 'W/"233-b+4UpNDbOtHFiEpLMsDEDK7iTeI"'
'date', 'Fri, 16 Jul 2021 21:59:52 GMT'
'x-envoy-upstream-service-time', '2'
'server', 'envoy'
```

下表解释了 Envoy 在解码或编码过程中设置的不同头信息。

| Header                           | 描述                                                         |
| -------------------------------- | ------------------------------------------------------------ |
| `:scheme`                        | 设置并提供给过滤器，并转发到上游。(对于 HTTP/1，`:scheme` 头是由绝对 URL 或 `x-forwaded-proto` 头值设置的) 。 |
| `user-agent`                     | 通常由客户端设置，但在启用 `add_user_agent `时可以修改（仅当 Header 尚未设置时）。该值由 `--service-cluster`命令行选项决定。 |
| `x-forwarded-proto`              | 标准头，用于识别客户端用于连接到代理的协议。该值为 `http` 或 `https`。 |
| `x-request-id`                   | Envoy 用来唯一地识别一个请求，也用于访问记录和跟踪。         |
| `x-envoy-expected-rq-timeout-ms` | 指定路由器期望请求完成的时间，单位是毫秒。这是从 `x-envoy-upstream-rq-timeout-ms` 头值中读取的（假设设置了 `respect_expected_rq_timeout`）或从路由超时设置中读取（默认为 15 秒）。 |
| `x-envoy-upstream-service-time`  | 端点处理请求所花费的时间，以毫秒为单位，以及 Envoy 和上游主机之间的网络延迟。 |
| `server`                         | 设置为 `server_name` 字段中指定的值（默认为 `envoy`）。      |


根据不同的场景，Envoy 会设置或消费一系列其他头信息。当我们在课程的其余部分讨论这些场景和功能时，我们会引出不同的头信息。

## Header 清理

Header 清理是一个出于安全原因添加、删除或修改请求 Header 的过程。有一些头信息，Envoy 有可能会进行清理。

| Header                                     | 描述                                                         |
| ------------------------------------------ | ------------------------------------------------------------ |
| `x-envoy-decorator-operation`              | 覆盖由追踪机制产生的任何本地定义的跨度名称。                 |
| `x-envoy-downstream-service-cluster`       | 包含调用者的服务集群（对于外部请求则删除）。由 `-service-cluster` 命令行选项决定，要求 `user_agent` 设置为 `true`。 |
| `x-envoy-downstream-service-node`          | 和前面的头一样，数值由 `--service--node`选项决定。           |
| `x-envoy-expected-rq-timeout-ms`           | 指定路由器期望请求完成的时间，单位是毫秒。这是从 `x-envoy-upstream-rq-timeout-ms` 头值中读取的（假设设置了 `respect_expected_rq_timeout`）或从路由超时设置中读取（默认为 15 秒）。 |
| `x-envoy-external-address`                 | 受信任的客户端地址（关于如何确定，详见下面的 XFF）。         |
| `x-envoy-force-trace`                      | 强制收集的追踪。                                             |
| `x-envoy-internal`                         | 如果请求是内部的，则设置为 "true"（关于如何确定的细节，见下面的 XFF）。 |
| `x-envoy-ip-tags`                          | 如果外部地址在 IP 标签中被定义，由 HTTP IP 标签过滤器设置。  |
| `x-envoy-max-retries`                      | 如果配置了重试策略，重试的最大次数。                         |
| `x-envoy-retry-grpc-on`                    | 对特定 gRPC 状态代码的失败请求进行重试。                     |
| `x-envoy-retry-on`                         | 指定重试策略。                                               |
| `x-envoy-upstream-alt-stat-name`           | Emist 上游响应代码 / 时间统计到一个双统计树。                |
| `x-envoy-upstream-rq-per-try-timeout-ms`   | 设置路由请求的每次尝试超时。                                 |
| `x-envoy-upstream-rq-timeout-alt-response` | 如果存在，在请求超时的情况下设置一个 204 响应代码（而不是 504）。 |
| `x-envoy-upstream-rq-timeout-ms`           | 覆盖路由配置超时。                                           |
| `x-forwarded-client-certif`                | 表示一个请求流经的所有客户端 / 代理中的部分证书信息。        |
| `x-forwarded-for`                          | 表示 IP 地址请求通过了。更多细节见下面的 XFF。               |
| `x-forwarded-proto`                        | 设置来源协议（`http` 或 `https）`。                          |
| `x-request-id`                             | Envoy 用来唯一地识别一个请求。也用于访问日志和追踪。         |

是否对某个特定的头进行清理，取决于请求来自哪里。Envoy 通过查看 `x-forwarded-for` 头（XFF）和 `internal_address_config` 设置来确定请求是外部还是内部。

## XFF

XFF 或 `x-forwaded-for` 头表示请求在从客户端到服务器的途中所经过的 IP 地址。下游和上游服务之间的代理在代理请求之前将最近的客户的 IP 地址附加到 XFF 列表中。

Envoy 不会自动将 IP 地址附加到 XFF 中。只有当 `use_remote_address`（默认为 false）被设置为 true，并且 `skip_xff_append` 被设置为 false 时，Envoy 才会追加该地址。

当 `use_remote_address` 被设置为 true 时，HCM 在确定来源是内部还是外部以及修改头信息时，会使用客户端连接的真实远程地址。这个值控制 Envoy 如何确定**可信的客户端地址**。

**可信的客户端地址**

可信的客户端地址是已知的第一个准确的源 IP 地址。向 Envoy 代理发出请求的下游节点的源 IP 地址被认为是正确的。

请注意，完整的 XFF 有时不能被信任，因为恶意的代理可以伪造它。然而，如果一个受信任的代理将最后一个地址放在 XFF 中，那么它就可以被信任。例如，如果我们看一下请求路径 `IP1 -> IP2 -> IP3 -> Envoy`，`IP3` 是 Envoy 会认为信任的节点。

Envoy 支持通过 `original_ip_detection_extensions` 字段设置的扩展，以帮助确定原始 IP 地址。目前，有两个扩展：`custom_header` 和 `xff`。

通过自定义头的扩展，我们可以提供一个包含原始下游远程地址的头名称。此外，我们还可以告诉 HCM 将检测到的地址视为可信地址。

通过 `xff` 扩展，我们可以指定从 `x-forwarded-for` 头的右侧开始的额外代理跳数来信任。如果我们将这个值设置为 `1` 还使用上面的例子，受信任的地址将是 `IP2` 和 `IP3`。

Envoy 使用可信的客户端地址来确定请求是内部还是外部。如果我们把 `use_remote_address` 设置为 `true`，那么如果请求不包含 XFF，并且直接下游节点与 Envoy 的连接有一个内部源地址，那么就认为是内部请求。Envoy 使用 [RFC1918](https://datatracker.ietf.org/doc/html/rfc1918) 或 [RFC4193](https://datatracker.ietf.org/doc/html/rfc4193) 来确定内部源地址。

如果我们把 `use_remote_address` 设置为 `false`（默认值），只有当 XFF 包含上述两个 RFC 定义的单一内部源地址时，请求才是内部的。

让我们看一个简单的例子，把 `use_remote_address` 设为 `true`，`skip_xff_append` 设为 `false`。

```yaml
...
- filters:
  - name: envoy.filters.network.http_connection_manager
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
      use_remote_address: true
      skip_xff_append: false
      ...
```

如果我们从同一台机器向代理发送一个请求（即内部请求），发送到上游的头信息将是这样的。

```
':authority', 'localhost:10000'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.64.0'
'accept', '*/*'
'x-forwarded-for', '10.128.0.17'
'x-forwarded-proto', 'http'
'x-envoy-internal', 'true'
'x-request-id', '74513723-9bbd-4959-965a-861e2162555b'
'x-envoy-expected-rq-timeout-ms', '15000'
```

这些 Header 中的大部分与我们在标准 Header 例子中看到的相同。然而，增加了两个头——`x-forwarded-for` 和 `x-envoy-internal`。`x-forwarded-for` 将包含内部 IP 地址，而 `x-envoy-internal` 头将被设置，因为我们用 XFF 来确定地址。我们不是通过解析 `x-forwarded-for` 头来确定请求是否是内部的，而是检查 `x-envoy-internal` 头的存在，以快速确定请求是内部还是外部的。

如果我们从该网络之外发送一个请求，即客户端和 Envoy 不在同一个节点上，以下头信息会被发送到 Envoy。

```
':authority', '35.224.50.133:10000'
':path', '/'
':method', 'GET'
':scheme', 'http'
'user-agent', 'curl/7.64.1'
'accept', '*/*'
'x-forwarded-for', '50.35.69.235'
'x-forwarded-proto', 'http'
'x-envoy-external-address', '50.35.69.235'
'x-request-id', 'dc93fd48-1233-4220-9146-eac52435cdf2'
'x-envoy-expected-rq-timeout-ms', '15000'
```

注意 `:authority` 的值是一个实际的 IP 地址，而不只是 `localhost`。同样地，`x-forwarded-for` 头包含了被调用的 IP 地址。没有 `x-envoy-internal` 头，因为这个请求是外部的。然而，我们确实得到了一个新的头，叫做 `x-envoy-external-address`。Envoy 只为外部请求设置这个头。这个头可以在内部服务之间转发，并用于基于源客户端 IP 地址的分析。