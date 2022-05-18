---
weight: 17
title: 实验5：局部速率限制
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将学习如何配置一个局部速率限制器。我们将使用运行在 3030 端口的 `httpbin` 容器。

```sh
docker run -d -p 3030:80 kennethreitz/httpbin
```

让我们创建一个有五个令牌的速率限制器。每隔 30 秒，速率限制器就会向桶里补充 5 个令牌。

```yaml
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: instance_1
              domains: ["*"]
              routes:
              - match:
                  prefix: /status
                route:
                  cluster: instance_1
              - match:
                  prefix: /headers
                route:
                  cluster: instance_1
                typed_per_filter_config:
                  envoy.filters.http.local_ratelimit:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
                    stat_prefix: headers_route
                    token_bucket:
                      max_tokens: 5
                      tokens_per_fill: 5
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
                          key: x-rate-limited
                          value: OH_NO
          http_filters:
          - name: envoy.filters.http.local_ratelimit
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
              stat_prefix: httpbin_rate_limiter
          - name: envoy.filters.http.router
  clusters:
  - name: instance_1
    connect_timeout: 0.25s
    type: STATIC
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: instance_1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 3030
admin:
  address:
    socket_address: 
      address: 127.0.0.1
      port_value: 9901
```

将上述 YAML 保存为 `2-lab-5-local-rate-limiter-1.yaml`，用 `func-e run -c 2-lab-5-local-rate-limiter-1.yaml` 运行 Envoy。

上述配置为路由 `/headers` 启用了一个局部速率限制器。此外，一旦达到速率限制，我们将在响应中添加一个头信息（`x-rate-limited`）。

如果我们在 30 秒内向 `http://localhost:10000/headers` 发出超过 5 个请求，我们会得到 HTTP 429 的响应。

```sh
$ curl -v localhost:10000/headers
...
> GET /headers HTTP/1.1
> Host: localhost:10000
> User-Agent: curl/7.64.0
> Accept: */*
>
< HTTP/1.1 429 Too Many Requests
< x-rate-limited: OH_NO
...
local_rate_limited
```

另外，注意到 Envoy 设置的 `x-rate-limited` 头。

一旦我们被限制了速率，我们将不得不等待 30 秒，让速率限制器再次用令牌把桶填满。我们也可以尝试向 `/status/200` 发出请求，你会发现我们不会在这个路径上受到速率限制。

如果我们打开统计页面（`localhost:9901/stats/prometheus`），我们会发现限速指标是使用我们配置的 `headers_route_rate_limiter` 统计前缀记录的。

```
# TYPE envoy_headers_route_http_local_rate_limit_enabled counter
envoy_headers_route_http_local_rate_limit_enabled{} 13

# TYPE envoy_headers_route_http_local_rate_limit_enforced counter
envoy_headers_route_http_local_rate_limit_enforced{} 8

# TYPE envoy_headers_route_http_local_rate_limit_ok counter
envoy_headers_route_http_local_rate_limit_ok{} 5

# TYPE envoy_headers_route_http_local_rate_limit_rate_limited counter
envoy_headers_route_http_local_rate_limit_rate_limited{} 8
```
