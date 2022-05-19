---
weight: 10
title: 访问日志
date: '2022-05-18T00:00:00+08:00'
type: book
---

本节将为你讲解 Envoy 中的访问日志配置。

## 什么是访问日志？

每当你打开浏览器访问谷歌或其他网站时，另一边的服务器就会收集你的访问信息。具体来说，它在收集和储存你从服务器上请求的网页数据。在大多数情况下，这些数据包括来源（即主机信息）、请求网页的日期和时间、请求属性（方法、路径、Header、正文等）、服务器返回的状态、请求的大小等等。所有这些数据通常被存储在称为**访问日志（access log）** 的文本文件中。

通常，来自网络服务器或代理的访问日志条目遵循标准化的通用日志格式。不同的代理和服务器可以使用自己的默认访问日志格式。Envoy 有其默认的日志格式。我们可以自定义默认格式，并配置它，使其以与其他服务器（如 Apache 或 NGINX）有相同的格式写出日志。有了相同的访问日志格式，我们就可以把不同的服务器放在一起使用，用一个工具把数据记录和分析结合起来。

本模块将解释访问日志在 Envoy 中是如何工作的，以及如何配置和定制。

## 捕获和读取访问日志

我们可以配置捕获任何向 Envoy 代理发出的访问请求，并将其写入所谓的访问日志。让我们看看几个访问日志条目的例子。

```
[2021-11-01T20:37:45.204Z] "GET / HTTP/1.1" 200 - 0 3 0 - "-" "curl/7.64.0" "9c08a41b-805f-42c0-bb17-40ec50a3377a" "localhost:10000" "-"
[2021-11-01T21:08:18.274Z] "POST /hello HTTP/1.1" 200 - 0 3 0 - "-" "curl/7.64.0" "6a593d31-c9ac-453a-80e9-ab805d07ae20" "localhost:10000" "-"
[2021-11-01T21:09:42.717Z] "GET /test HTTP/1.1" 404 NR 0 0 0 - "-" "curl/7.64.0" "1acc3559-50eb-463c-ae21-686fe34abbe8" "localhost:10000" "-"
```

输出包含三个不同的日志条目，并遵循相同的默认日志格式。默认的日志格式看起来像这样。

```
[%START_TIME%] "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%"
%RESPONSE_CODE% %RESPONSE_FLAGS% %BYTES_RECEIVED% %BYTES_SENT% %DURATION%
%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%"
"%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%UPSTREAM_HOST%"
```

诸如 `%RESPONSE_FLAGS%`、`%REQ(:METHOD)%` 等值被称为**命令操作符（command operator）**。

### 命令操作符

命令操作符提取相关数据并插入到 TCP 和 HTTP 的日志条目中。如果这些值没有设置或不可用（例如，TCP 中的 RESPONSE_CODE），日志将包含字符 `-`（或 JSON 日志的 `"-"`）。

每个命令操作符都以字符 `%` 开始和结束，例如，`%START_TIME%`。如果命令操作符接受任何参数，那么我们可以在括号内提供这些参数。例如，如果我们想使用 `START_TIME` 命令操作符只记录日、月、年，那么我们可以通过在括号中指定这些值来进行配置：`%START_TIME(%d-%m-%Y)%`。

让我们来看看不同的命令操作符。我们试图根据它们的共同属性将它们归入单独的表格。

| 命令操作符                     | 描述                                                         | 示例                                   |
| ------------------------------ | ------------------------------------------------------------ | -------------------------------------- |
| START_TIME                     | 请求开始时间，包括毫秒。                                     | `%START_TIME(%Y/%m/%dT%H:%M:%S%z ^%)%` |
| PROTOCOL                       | 协议（HTTP/1.1、HTTP/2 或 HTTP/3）                           | `％PROTOCOL％`                         |
| RESPONSE_CODE                  | HTTP 响应代码。如果下游客户端断开连接，响应代码将被设置为 0。 | `%RESPONSE_CODE%`                      |
| RESPONSE_CODE_DETAIL           | 关于 HTTP 响应的额外信息（例如，谁设置的以及为什么设置）。   | `RESPONSE_CODE_DETAIL%。`              |
| CONNECTION_TERMINATION_DETAILS | 提供关于 Envoy 因 L4 原因终止连接的额外信息。                | `%CONNECTION_TERMINATION_DETAILS%`     |
| ROUTE_NAME                     | 路由的名称。                                                 | `%ROUTE_NAME%`                         |
| CONNECTION_ID                  | 下游连接的一个标识符。它可以用来交叉引用多个日志汇聚中的 TCP 访问日志，或交叉引用同一连接的基于计时器的报告。该标识符在一个执行过程中很可能是唯一的，但在多个实例或重新启动之间可能会重复。 | `%CONNECTION_ID%`                      |
| GRPC_STATUS                    | gRPC 状态代码，包括文本信息和一个数字。                      | `%GRPC_STATUS%`                        |
| HOSTNAME                       | 系统主机名。                                                 | `%HOSTNAME%`                           |
| LOCAL_REPLY_BODY               | 被 Envoy 拒绝的请求的正文。                                  | `%LOCAL_REPLY_BODY%`                   |
| FILTER_CHAIN_NAME              | 下游连接的网络过滤器链名称。                                 | `%FILTER_CHAIN_NAME%`                  |

#### 大小

该组包含所有代表大小的命令操作符——从请求和响应头字节到接收和发送的字节。

| 命令操作符                       | 描述                                                    | 示例                                 |
| -------------------------------- | ------------------------------------------------------- | ------------------------------------ |
| REQUEST_HEADER_BYTES             | 请求头的未压缩字节。                                    | `%REQUEST_HEADER_BYTES%`             |
| RESPONSE_HEADERS_BYTES           | 响应 Header 的未压缩字节数。                            | `%RESPONSE_HEADERS_BYTES％`          |
| RESPONSE_TRAILERS_BYTES          | 响应 trailer 的未压缩字节。                             | `%RESPONSE_TRAILERS_BYTES%`          |
| BYTES_SENT                       | 为 HTTP 发送的正文字节和为 TCP 发送的连接上的下游字节。 | `%BYTES_SENT%`                       |
| BYTES_RECEIVED                   | 收到的正文字节数。                                      | `%BYTES_RECEIVED%`                   |
| UPSTREAM_WIRE_BYTES_SENT         | 由 HTTP 流向上游发送的总字节数。                        | `%UPSTREAM_WIRE_BYTES_SENT％`        |
| UPSTREAM_WIRE_BYTES_RECEIVED     | 从上游 HTTP 流收到的字节总数。                          | `%upstream_wire_bytes_received％`    |
| UPSTREAM_HEADER_BYTES_SENT       | 由 HTTP 流向上游发送的头字节的数量。                    | `%UPSTREAM_HEADER_BYTES_SENT％`      |
| UPSTREAM_HEADER_BYTES_RECEIVED   | HTTP 流从上游收到的头字节的数量。                       | `%UPSTREAM_HEADER_BYTES_RECEIVED%`   |
| DOWNSTREAM_WIRE_BYTES_SENT       | HTTP 流向下游发送的总字节数。                           | `%downstream_wire_bytes_sent%`       |
| DOWNSTREAM_WIRE_BYTES_RECEIVED   | HTTP 流从下游收到的字节总数。                           | `%DOWNSTREAM_WIRE_BYTES_RECEIVED%`   |
| DOWNSTREAM_HEADER_BYTES_SENT     | 由 HTTP 流向下游发送的头字节的数量。                    | `%DOWNSTREAM_HEADER_BYTES_SENT%`     |
| DOWNSTREAM_HEADER_BYTES_RECEIVED | HTTP 流从下游收到的头字节的数量。                       | `%downstream_header_bytes_received%` |

#### 时长

| 命令操作符           | 描述                                                         | 示例                     |
| -------------------- | ------------------------------------------------------------ | ------------------------ |
| DURATION             | 从开始时间到最后一个字节输出，请求的总持续时间（以毫秒为单位）。 | `%DURATION%`             |
| REQUEST_DURATION     | 从开始时间到收到下游请求的最后一个字节，请求的总持续时间（以毫秒计）。 | `%REQUEST_DURATION%`     |
| RESPONSE_DURATION    | 从开始时间到从上游主机读取的第一个字节，请求的总持续时间（以毫秒计）。 | `RESPONSE_DURATION`      |
| RESPONSE_TX_DURATION | 从上游主机读取的第一个字节到下游发送的最后一个字节，请求的总时间（以毫秒为单位）。 | `%RESPONSE_TX_DURATION%` |

#### 响应标志

`RESPONSE_FLAGS` 命令操作符包含关于响应或连接的额外细节。下面的列表显示了 HTTP 和 TCP 连接的响应标志的值和它们的含义。

**HTTP 和 TCP**

- UH：除了 503 响应代码外，在一个上游集群中没有健康的上游主机。
- UF：除了 503 响应代码外，还有上游连接失败。
- UO：上游溢出（断路），此外还有 503 响应代码。
- NR：除了 404 响应代码外，没有为给定的请求配置路由，或者没有匹配的下游连接的过滤器链。
- URX：请求被拒绝是因为达到了上游重试限制（HTTP）或最大连接尝试（TCP）。
- NC：未找到上游集群。
- DT：当一个请求或连接超过 `max_connection_duration` 或 `max_downstream_connection_duration`。

**仅限 HTTP**

- DC: 下游连接终止。
- LH：除了 503 响应代码，本地服务的健康检查请求失败。
- UT：除 504 响应代码外的上行请求超时。
- LR：除了 503 响应代码外，连接本地重置。
- UR：除 503 响应代码外的上游远程复位。
- UC：除 503 响应代码外的上游连接终止。
- DI：请求处理被延迟了一段通过故障注入指定的时间。
- FI：该请求被中止，并有一个通过故障注入指定的响应代码。
- RL：除了 429 响应代码外，该请求还被 HTTP 速率限制过滤器在本地进行了速率限制。
- UAEX：该请求被外部授权服务拒绝。
- RLSE：请求被拒绝，因为速率限制服务中存在错误。
- IH：该请求被拒绝，因为除了 400 响应代码外，它还为一个严格检查的头设置了一个无效的值。
- SI：除 408 响应代码外，流空闲超时。
- DPE：下游请求有一个 HTTP 协议错误。
- UPE：上游响应有一个 HTTP 协议错误。
- UMSDR：上游请求达到最大流时长。
- OM：过载管理器终止了该请求。

#### 上游信息

| 命令操作符                        | 描述                                                         | 示例                                  |
| --------------------------------- | ------------------------------------------------------------ | ------------------------------------- |
| UPSTREAM_HOST                     | 上游主机 URL 或 TCP 连接的 `tcp://ip:端口`。                 | `%UPSTREAM_HOST%`                     |
| UPSTREAM_CLUSTER                  | 上游主机所属的上游集群。如果运行时特性 `envoy.reloadable_features.use_observable_cluster_name` 被启用，那么如果提供了 `alt_stat_name` 就会被使用。 | `%UPSTREAM_CLUSTER%`                  |
| UPSTREAM_LOCAL_ADDRESS            | 上游连接的本地地址。如果是一个 IP 地址，那么它包括地址和端口。 | `%UPSTREAM_LOCAL_ADDRESS％`           |
| UPSTREAM_TRANSPORT_FAILURE_REASON | 如果由于传输套接字导致连接失败，则提供来自传输套接字的失败原因。 | `%UPSTREAM_TRANSPORT_FAILURE_REASON%` |

#### 下游信息

| 命令描述符                                    | 描述                                                         | 示例                                               |
| --------------------------------------------- | ------------------------------------------------------------ | -------------------------------------------------- |
| DOWNSTREAM_REMOTE_ADDRESS                     | 下游连接的远程地址。如果是一个 IP 地址，那么它包括地址和端口。 | `%DOWNSTREAM_REMOTE_ADDRESS％`                     |
| DOWNSTREAM_REMOTE_ADDRESS_WITHOUT_PORT        | 下游连接的远程地址。如果是一个 IP 地址，那么它只包括地址。   | `%DOWNSTREAM_REMOTE_ADDRESS_WITHOUT_PORT%`         |
| DOWNSTREAM_DIRECT_REMOTE_ADDRESS              | 下游连接的直接远程地址。如果是一个 IP 地址，那么它包括地址和端口。 | `%DOWNSTREAM_DIRECT_REMOTE_ADDRESS%`               |
| DOWNSTREAM_DIRECT_REMOTE_ADDRESS_WITHOUT_PORT | 下游连接的直接远程地址。如果是一个 IP 地址，那么它只包括地址。 | `%DOWNSTREAM_DIRECT_REMOTE_ADDRESS_WITHOUT_PORT%`  |
| DOWNSTREAM_DIRECT_REMOTE_ADDRESS_WITHOUT_PORT | 下游连接的本地地址。如果它是一个 IP 地址，那么它包括地址和端口。如果原始连接是由 iptables REDIRECT 重定向的，那么这个值代表由原始目标过滤器恢复的原始目标地址。如果由 iptables TPROXY 重定向，并且监听器的透明选项被设置为 "true"，那么这个值代表原始目标地址和端口。 | `%DOWNSTREAM_DIRECT_REMOTE_ADDRESS_WITHOUT_PORT％` |
| DOWNSTREAM_LOCAL_ADDRESS_WITHOUT_PORT         | 与 `DOWNSTREAM_LOCAL_ADDRESS` 相同，如果该地址是一个 IP 地址，则不包括端口。 | `%DOWNSTREAM_LOCAL_ADDRESS_WITHOUT_PORT%`          |
| DOWNSTREAM_LOCAL_PORT                         | 与 `DOWNSTREAM_LOCAL_ADDRESS_WITHOUT_PORT` 类似，但只提取 `DOWNSTREAM_LOCAL_ADDRESS` 的端口部分。 | `%DOWNSTREAM_LOCAL_PORT%`                          |

#### Header 和 Trailer

`REQ`、`RESP` 和 `TRAILER` 命令操作符允许我们提取请求、响应和 Trailer header 的信息，并将其纳入日志。

> **Trailer** 是一个响应首部，允许发送方在分块发送的消息后面添加额外的元信息，这些元信息可能是随着消息主体的发送动态生成的，比如消息的完整性校验，消息的数字签名，或者消息经过处理之后的最终状态等。

| 命令操作符      | 描述                                                         | 示例                                                         |
| --------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| REQ (X?Y):Z     | HTTP 请求头，其中 X 是主要的 HTTP 头，Y 是备选的 HTTP 头，Z 是一个可选的参数，表示最长为 Z 个字符的字符串截断。如果头信息 X 的值没有被设置，那么将使用请求头信息 Y。如果任何一个头都不存在，`-` 将出现在日志中。 | `%REQ(HELLO?BYE):5%` 包括头信息 `hello` 的值。如果没有设置，则使用 Header `bye` 的值。它将值截断为 5 个字符。 |
| RESP (X?Y):Z    | 与 REQ 相同，但取自 HTTP 响应头。                            | `%RESP(HELLO?BYE):5%` 包括头信息 `hello` 的值。如果没有设置，则使用头条 `bye` 的值。它将值截断为 5 个字符。 |
| TRAILER (X?Y):Z | 与 REQ 相同，但取自 HTTP 响应 Trailer。                      | `%TRAILER(HELLO?BYE):5%` 包括头信息 `hello` 的值。如果没有设置，则使用头条 `bye` 的值。它将该值截断为 5 个字符。 |

#### 元数据

| 命令操作符                         | 描述                                                         | 示例                              |
| ---------------------------------- | ------------------------------------------------------------ | --------------------------------- |
| DYNAMIC_METADATA(NAMESPACE:KEY*):Z | 动态元数据信息，其中 NAMESPACE 是设置元数据时使用的过滤器。KEY 是命名空间中的一个可选的查找键，可以选择指定用`:` 分隔的嵌套键。Z 是一个可选的参数，表示字符串截断，长度不超过 Z 个字符。 例如，`my_filter。{"my_key":"hello", "json_object":{"some_key":"foo"}}` 元数据可以用 `%DYNAMIC_METADATA(my_filter)%` 进行记录。要记录一个特定的键，我们可以写 `%DYNAMIC_METADATA(my_filter:my_key)%`。 |                                   |
| CLUSTER_METADATA(NAMESPACE:KEY*):Z | 上游集群元数据信息，其中 NAMESPACE 是设置元数据时使用的过滤器命名空间，KEY 是命名空间中一个可选的查找键，可选择指定由`:` 分隔的嵌套键。Z 是一个可选的参数，表示字符串截断，长度不超过 Z 个字符。 | 见 `DYNAMIC_METADATA` 的例子。    |
| FILTER_STATE(KEY:F):Z              | 过滤器状态信息，其中的 KEY 是需要查询过滤器状态对象的。如果可能的话，序列化的 proto 将被记录为一个 JSON 字符串。如果序列化的 proto 是未知的，那么它将被记录为一个 protobuf 调试字符串。F 是一个可选的参数，表示 FilterState 使用哪种方法进行序列化。如果设置了 `PLAIN`，那么过滤器状态对象将被序列化为一个非结构化的字符串。如果设置了 `TYPED` 或者没有提供 F，那么过滤器状态对象将被序列化为一个 JSON 字符串。Z 是一个可选的参数，表示字符串的截断，长度不超过 Z 个字符。 | `%FILTER_STATE(my_key:PLAIN):10%` |

#### TLS

| 命令操作符                      | 描述                                                         | 示例                                                         |
| ------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| REQUESTED_SERVER_NAME           | 在 SSL 连接套接字上为服务器名称指示（SNI）设置的字符串值。   | `%REQUESTED_SERVER_NAME%`                                    |
| DOWNSTREAM_LOCAL_URI_SAN        | 用于建立下游 TLS 连接的本地证书的 SAN 中存在的 URI。         | `%DOWNSTREAM_LOCAL_URI_SAN%`                                 |
| DOWNSTREAM_PEER_URI_SAN         | 用于建立下游 TLS 连接的同行证书 SAN 中存在的 URI。           | `%DOWNSTREAM_PEER_URI_SAN%`                                  |
| DOWNSTREAM_LOCAL_SUBJECT        | 用于建立下游 TLS 连接的本地证书中存在的主题。                | `%DOWNSTREAM_LOCAL_SUBJECT%`                                 |
| DOWNSTREAM_PEER_SUBJECT         | 用于建立下游 TLS 连接的对等证书中的主题。                    | `%DOWNSTREAM_PEER_SUBJECT%`                                  |
| DOWNSTREAM_PEER_ISSUER          | 用于建立下游 TLS 连接的对等证书中存在的签发者。              | `%DOWNSTREAM_PEER_ISSUER%`                                   |
| DOWNSTREAM_TLS_SESSION_ID       | 已建立的下游 TLS 连接的会话 ID。 `%DOWNSTREAM_TLS_SESSION_ID%` |                                                              |
| DOWNSTREAM_TLS_CIPHER           | 用于建立下游 TLS 连接的密码集的 OpenSSL 名称。               | `%downstream_tls_cipher％`                                   |
| DOWNSTREAM_TLS_VERSION          | 用于建立下游 TLS 连接的 TLS 版本（`TLSv1.2` 或 `TLSv1.3`）。 | `%downstream_tls_version%`                                   |
| DOWNSTREAM_PEER_FINGERPRINT_256 | 用于建立下游 TLS 连接的客户证书的十六进制编码的 SHA256 指纹。 | `%DOWNSTREAM_PEER_FINGERPRINT_256%`                          |
| DOWNSTREAM_PEER_FINGERPRINT_1   | 用于建立下游 TLS 连接的客户证书的十六进制编码的 SHA1 指纹。  | `%DOWNSTREAM_PEER_FINGERPRINT_1%`                            |
| DOWNSTREAM_PEER_SERIAL          | 用于建立下游 TLS 连接的客户证书的序列号。                    | `%DOWNSTREAM_PEER_SERIAL%`                                   |
| DOWNSTREAM_PEER_CERT            | 用于建立下游 TLS 连接的 URL - 安全编码的 PEM 格式的客户证书。 | `%DOWNSTREAM_PEER_CERT％`                                    |
| DOWNSTREAM_PEER_CERT_V_START    | 用于建立下游 TLS 连接的客户证书的有效期开始日期。            | `%DOWNSTREAM_PEER_CERT_V_START%`可以像 `START_TIME` 一样定制。 |
| DOWNSTREAM_PEER_CERT_V_END      | 用于建立下游 TLS 连接的客户证书的有效期结束日期。            | `%downstream_peer_cert_v_end%`                               |

# 