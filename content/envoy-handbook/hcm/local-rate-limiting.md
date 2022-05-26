---
weight: 13
title: 局部速率限制
date: '2022-05-18T00:00:00+08:00'
type: book
---

局部速率限制过滤器对过滤器链处理的传入连接应用一个**令牌桶**速率限制。

令牌桶算法的基础是令牌在桶中的类比。桶里的令牌以一个固定的速度被重新填满。每次收到一个请求或连接时，我们都会检查桶里是否还有令牌。如果有，就从桶中取出一个令牌，然后处理该请求。如果没有剩余的令牌，该请求就会被放弃（即速率限制）。

![令牌桶算法](../../images/008i3skNly1gz9ku76k2uj31ha0u0763.jpg "令牌桶算法")

局部速率限制可以在监听器层面或虚拟主机或路由层面进行全局配置，就像全局速率限制一样。我们还可以在同一配置中结合全局和局部速率限制。

`token_bucket` 指定了过滤器处理的请求所使用的配置。它包括桶可以容纳的最大令牌数量（`max_tokens`），每次填充的令牌数量（`tokens_per_fill`）以及填充间隔（`fill_interval`）。

下面是一个最多可以容纳 5000 个令牌的桶的配置实例。每隔 30 秒，向桶中添加 100 个令牌。桶中的令牌容量永远不会超过 5000。

```yaml
token_bucket:
  max_tokens: 5000
  tokens_per_fill: 100
  fill_interval:30s
```

为了控制令牌桶是在所有 worker 之间共享（即每个 Envoy 进程）还是按连接使用，我们可以设置 `local_rate_limit_per_downstream_connection` 字段。默认值是 `false`，这意味着速率限制被应用于每个 Envoy 进程。

控制是否启用或强制执行某一部分请求的速率限制的两个设置被称为 `filter_enabled `和 `filter_enforced`。这两个值在默认情况下都设置为 0%。

速率限制可以被启用，但不一定对一部分请求强制执行。例如，我们可以对 50% 的请求启用速率限制。然后，在这 50% 的请求中，我们可以强制执行速率限制。

![启用速率限制](../../images/008i3skNly1gz9ku7reawj309p08gweg.jpg "启用速率限制")

以下配置对所有传入的请求启用并执行速率限制。

```yaml
token_bucket:
  max_tokens: 5000
  tokens_per_fill: 100
  fill_interval: 30s
filter_enabled:
  default_value:
    numerator: 100
    denominator: HUNDRED
filter_enforced:
  default_value:
    numerator: 100
    denominator: HUNDRED
```

我们还可以为限制速率的请求添加请求和响应头信息。我们可以在 `request_headers_to_add_when_not_enforced` 字段中提供一个头信息列表，Envoy 将为每个转发到上游的限速请求添加一个请求头信息。请注意，这只会在过滤器启用但未强制执行时发生。

对于响应头信息，我们可以使用  `response_headers_to_add ` 字段。我们可以提供一个 Header 的列表，这些 Header 将被添加到已被限制速率的请求的响应中。这只有在过滤器被启用或完全强制执行时才会发生。

如果我们在前面的例子的基础上，这里有一个例子，说明如何在所有速率限制的请求中添加特定的响应头。

```yaml
token_bucket:
  max_tokens: 5000
  tokens_per_fill: 100
  fill_interval: 30s
filter_enabled:
  default_value:
    numerator: 100
    denominator: HUNDRED
filter_enforced:
  default_value:
    numerator: 100
    denominator: HUNDRED
response_headers_to_add:
  - append: false
    header:
      key: x-local-rate-limit
      value: 'true'
```

我们可以配置局部速率限制器，使所有虚拟主机和路由共享相同的令牌桶。为了在全局范围内启用局部速率限制过滤器（不要与全局速率限制过滤器混淆），我们可以在 `http_filters` 列表中为其提供配置。

例如：

```yaml
...
http_filters:
- name: envoy.filters.http.local_ratelimit
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
    stat_prefix: http_local_rate_limiter
    token_bucket:
      max_tokens: 10000
    ...
- name: envoy.filters.http.router
...
```

如果我们想启用每个路由的局部速率限制，我们仍然需要将过滤器添加到 `http_filters` 列表中，而不需要任何配置。然后，在路由配置中，我们可以使用  `typed_per_filter_config`  并指定局部速率限制的过滤器配置。

例如：

```yaml
...
route_config:
  name: my_route
  virtual_hosts:
  - name: my_service
    domains: ["*"]
    routes:
    - match:
        prefix: /
      route:
        cluster: some_cluster
      typed_per_filter_config:
        envoy.filters.http.local_ratelimit:
          "@type": type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
          token_bucket:
            max_tokens: 10000
            tokens_per_fill: 1000
            fill_interval: 1s
          filter_enabled:
            default_value:
              numerator: 100
              denominator: HUNDRED
          filter_enforced:
            default_value:
              numerator: 100
              denominator: HUNDRED
http_filters:
- name: envoy.filters.http.local_ratelimit
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
    stat_prefix: http_local_rate_limiter
- name: envoy.filters.http.router
```

上述配置在 `http_filter` 列表中加载了局部速率限制过滤器。我们在路由配置中使用  `typed_per_filter_config` 来配置它，并以  `envoy.filters.http.local_ratelimit` 的名字来引用这个过滤器。

## 使用描述符进行局部速率限制

就像我们在做全局速率限制时使用描述符一样，我们也可以把它们用于局部每条路由的速率限制。我们需要配置两个部分：路由上的操作和局部速率限制过滤器配置中的描述符列表。

我们可以用为全局速率限制定义动作的方式为局部速率限制定义动作。

```yaml
...
route_config:
  name: my_route
  virtual_hosts:
  - name: my_service
    domains: ["*"]
    routes:
    - match:
        prefix: /
      route:
        cluster: some_cluster
        rate_limits:
        - actions:
          - header_value_match:
              descriptor_value: post_request
              headers:
              - name: ":method"
                exact_match: POST
          - header_value_match:
              descriptor_value: get_request
              headers:
              - name: ":method"
                exact_match: GET
...
```

第二部分是编写配置以匹配生成的描述符，并提供令牌桶信息。这在 `descriptors 字段下的速率限制过滤器配置中得到完成。

例如：

```yaml
typed_per_filter_config:
  envoy.filters.http.local_ratelimit:
    "@type": type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
    stat_prefix: some_stat_prefix
    token_bucket:
      max_tokens: 1000
      tokens_per_fill: 1000
      fill_interval: 60s
    filter_enabled:
    ...
    filter_enforced:
    ...
    descriptors:
    - entries:
      - key: header_match
        value: post_request
      token_bucket:
        max_tokens: 20
        tokens_per_fill: 5
        fill_interval: 30s
    - entries:
      - key: header_match
        value: get_request
      token_bucket:
        max_tokens: 50
        tokens_per_fill: 5
        fill_interval: 20s
...
```

对于所有的 POST 请求（即 `（"header_match": "post_request"）`），桶被设置为 20 个令牌，它每 30 秒重新填充 5 个令牌。对于所有的 GET 请求，该桶最多可以容纳 50 个令牌，每 20 秒重新填充 5 个令牌。