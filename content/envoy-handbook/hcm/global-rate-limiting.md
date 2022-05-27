---
weight: 13
title: 全局速率限制
date: '2022-05-18T00:00:00+08:00'
type: book
---

当许多主机向少数上游服务器发送请求，且平均延迟较低时，全局或分布式速率限制很有用。

![许多主机上少许上游服务器发送请求](../../images/008i3skNly1gz9ktvfffyj31ha0u0dhn.jpg "许多主机上少许上游服务器发送请求")

由于服务器不能快速处理这些请求，请求就会变得滞后。在这种情况下，众多的下游主机可以压倒少数的上游主机。全局速率限制器有助于防止级联故障。

![速率限制](../../images/008i3skNly1gz9ktuyp50j31ha0u0wga.jpg "速率限制")

Envoy 与任何实现定义的 RPC/IDL 协议的外部速率限制服务集成。该服务的参考实现使用 Go、gRPC 和 Redis 作为其后端，可参考[这里](https://github.com/envoyproxy/ratelimit)。

Envoy 调用外部速率限制服务（例如，在 Redis 中存储统计信息并跟踪请求），以得到该请求是否应该被速率限制的响应。

使用外部速率限制服务，我们可以将限制应用于一组服务，或者，如果我们谈论的是服务网格，则应用于网格中的所有服务。我们可以控制进入网格的请求数量，作为一个整体。

为了控制单个服务层面的请求率，我们可以使用局部速率限制器。局部速率限制器允许我们对每个服务有单独的速率限制。局部和全局速率限制通常是一起使用的。

## 配置全局速率限制

在配置全局速率限制时，我们必须设置两个部分——客户端（Envoy）和服务器端（速率限制服务）。

我们可以在 Envoy 侧将速率限制服务配置为**网络级速率限制过滤器**或 **HTTP 级速率限制过滤器**。

当在网络层面上使用速率限制过滤器时，Envoy 对我们配置了过滤器的监听器的每个新连接调用速率限制服务。同样，使用 HTTP 级别的速率限制过滤器，Envoy 对安装了过滤器的监听器上的每个新请求调用速率限制服务，**并且**路由表指定应调用全局速率限制服务。所有到目标上游集群的请求以及从发起集群到目标集群的请求都可以被限制速率。

在配置速率限制服务之前，我们需要解释**动作**、**描述符**（键 / 值对）和**描述符列表**的概念。

![速率限制概念](../../images/008i3skNly1gz9ktuq5l9j32i40u0tbn.jpg "速率限制概念")

在路由或虚拟主机层面的 Envoy 配置中，我们定义了一组**动作**。每个动作都包含一个速率限制动作的列表。让我们考虑下面的例子，在虚拟主机级别上定义速率限制。

```yaml
rate_limits:
- actions:
  - header_value_match:
      descriptor_value: get_request
      headers:
      - name: :method
        prefix_match: GET
  - header_value_match:
      descriptor_value: path
      headers:
        - name: :path
          prefix_match: /api
- actions:
  - header_value_match:
      descriptor_value: post_request
      headers:
      - name: :method
        prefix_match: POST
- actions:
  - header_value_match:
      descriptor_value: get_request
      headers:
      - name: :method
        prefix_match: GET
```

上面的片段定义了三个独立的动作，其中包含速率限制动作。Envoy 将尝试将请求与速率限制动作相匹配，并生成描述符发送到速率限制服务。如果 Envoy 不能将任何一个速率限制动作与请求相匹配，则不会创建描述符 ——即所有速率限制动作都必须相匹配。

例如，如果我们收到一个到 `/api` 的 GET 请求，第一个动作与两个速率限制动作相匹配；因此会创建一个如下描述符。

```
("header_match": "get_request"), ("header_match": "path")
```

第二个动作是不会匹配的。然而，最后一个也会匹配。因此，Envoy 将向速率限制服务发送以下描述符。

```
("header_match": "get_request"), ("header_match": "path")
("header_match": "get_request")
```

让我们来看看另一个满足以下要求的客户端配置的例子。

- 对 /users 的 POST 请求被限制在每分钟 10 个请求。
- 对 /users 的请求被限制在每分钟 20 个请求。
- 带有 `dev: true` 头的 /api 请求被限制在每秒 10 个请求的速率。
- 向 /api 发出的带有 `dev: false` 头的请求被限制在每秒 5 个请求。
- 对 /api 的任何其他请求都没有速率限制。

请注意，这次我们是在路由层面上定义速率限制。

```yaml
routes:
- match:
    prefix: "/users"
  route:
    cluster: some_cluster
    rate_limits:
    - actions:
      - generic_key:
          descriptor_value: users
      - header_value_match:
          descriptor_value: post_request
          headers:
          - name: ":method"
            exact_match: POST
    - actions:
      - generic_key:
          descriptor_value: users
- match:
    prefix: "/api"
  route:
    cluster: some_cluster
    rate_limits:
    - actions:
      - generic_key:
          descriptor_value: api
      - request_headers:
          header_name: dev
          descriptor_key: dev_request
...
http_filters:
- name: envoy.filters.http.ratelimit
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.ratelimit.v3.RateLimit
    domain: some_domain
    enable_x_ratelimit_headers: DRAFT_VERSION_03
    rate_limit_service:
      transport_api_version: V3
      grpc_service:
          envoy_grpc:
            cluster_name: rate-limit-cluster
```

上述配置包含每条路由的 `rate_limits` 配置和 `envoy. filters.http.ratelimit` 过滤器配置。过滤器的配置指向速率限制服务的上游集群。我们还设置了域名（`domain`）和 `enabled_x_ratelimit_headers ` 字段，指定我们要使用 `x-ratelimit ` 头。我们可以按任意的域名来隔离一组速率限制配置。

如果我们看一下路由中的速率限制配置，注意到我们是如何拆分动作以匹配我们想要设置的不同速率限制的。例如，我们有一个带有 `api` 通用密钥和请求头的动作。然而，在同一个配置中，我们也有一个只设置了通用密钥的动作。这使得我们可以根据这些动作配置不同的速率限制。

让我们把动作翻译成描述符。

```
GET /users --> ("generic_key": "users")

POST /users --> ("generic_key": "users"), ("header_match": "post_request")

GET /api 
dev: some_header_value --> ("generic_key": "api"), ("dev_request": "some_header_value")
```

`header_match` 和 `request_headers` 之间的区别是，对于后者，我们可以根据特定的头信息值来创建速率限制（例如，`dev: true` 或 `dev: something`，因为头信息的值成为描述符的一部分）。

在速率限制服务方面，我们需要开发一个配置，根据 Envoy 发送的描述符来指定速率限制。

例如，如果我们向 `/users` 发送一个 GET 请求，Envoy 会向速率限制服务发送以下描述符。`("generic_key": "users")`。然而，如果我们发送一个 POST 请求，描述符列表看起来像这样。

```
("generic_key": "users"), ("header_match": "post_request")
```

速率限制服务配置是分层次的，允许匹配嵌套描述符。让我们看看上述描述符的速率限制服务配置会是什么样子。

```yaml
domain: some_domain
descriptors:
- key: generic_key
  value: users
  rate_limit:
    unit: MINUTE
    requests_per_unit: 20
  descriptors:
  - key: header_match
    value: post_request
    rate_limit:
      unit: MINUTE
      requests_per_unit: 10
- key: generic_key
  value: api
  descriptors:
  - key: dev_request
    value: true
    rate_limit:
      unit: SECOND
      requests_per_unit: 10
  - key: dev_request
    value: false
    rate_limit:
      unit: SECOND
      requests_per_unit: 5
```

我们之前在 Envoy 方面的配置中提到了 `domain` 值。现在我们可以看看如何使用域名。我们可以在整个代理机群中使用相同的描述符名称，但要用域名来分隔它们。

让我们看看速率限制服务上的匹配对不同请求是如何工作的。

|收到的请求| 生成的描述符|速率限制 |解释|
| ------------------------------------ | ------------------------------------------------------------ | --------------- | ------------------------------------------------------------ |
|`GET /users` |`("generic_key": "users")`| `20 req/min` | 键 `users` 与配置中的第一层相匹配。由于配置中的第二层（`header_match`）没有包括在描述符中，所以使用了 `users` 键的速率限制。 |
|`POST /users` |`("generic_key": "users"), ("header_match": "post_request")` |`10 req/min` |发送的描述符和 `header_match` 一样匹配 `users`，所以使用 `header_match` 描述符下的速率限制。|
|`GET /api`| `("generic_key": "api")` |无速率限制 |我们只有 `api描述符`的第一级匹配。然而，并没有配置速率限制。为了执行速率限制，我们需要第二级描述符，这些描述符只有在传入的请求中存在 Header `dev` 时才会被设置。|
|`GET /api`</br>`dev: true`|`("generic_key": "api"), ("dev_request": "true")` | `10 req/second`| 列表中的第二个描述符与配置中的第二层相匹配（即我们匹配 `api`，然后也匹配 `dev_request：true`）。|
|`GET /api`</br>`dev: false`|`("generic_key": "api"), ("dev_request": "false")`| `5 req/second`| 列表中的第二个描述符与配置中的第二层相匹配（即我们匹配 `api`，然后也匹配 `dev_request：true`）。|
|`GET /api`</br>`dev: hello`|`("generic_key": "api"), ("dev_request": "hello")` |无速率限制 |列表中的第二个描述符与配置中的任何二级描述符都不匹配。|

除了我们在上面的例子中使用的动作外，下表显示了我们可以用来创建描述符的其他动作。

|动作名称 |描述 |
| --------------------- | ---------------------------------------------- |
|`source_cluster`| 源集群的速率限制 |
|`destination_cluster` |目的地集群的速率限制 |
|`request_headers` |对请求头的速率限制 |
|`remote_address` |远程地址的速率限制 |
|`generic_key`| 对一个通用键的速率限制 |
|`header_value_match`| 对请求头的存在进行速率限制 |
|`metadata`| 元数据的速率限制|

下图总结了这些操作与描述符和速率限制服务上的实际速率限制配置的关系。

![行为、描述符和配置的关系](../../images/008i3skNly1gz9ktvzbvyj30s60eqjsl.jpg "行为、描述符和配置的关系")