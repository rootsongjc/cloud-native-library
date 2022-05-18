---
weight: 18
title: 实验6：全局速率限制
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将学习如何配置一个全局速率限制器。我们将使用[速率限制器服务](https://github.com/envoyproxy/ratelimit)和一个 Redis 实例来跟踪令牌。我们将使用 Docker Compose 来运行 Redis 和速率限制器服务容器。

让我们首先创建速率限制器服务的配置。

```yaml
domain: my_domain
descriptors:
- key: generic_key
  value: instance_1
  descriptors:
    - key: header_match
      value: get_request
      rate_limit:
        unit: MINUTE
        requests_per_unit: 5
```

我们指定一个通用键（`instance_1`）和一个名为 `header_match` 的描述符，速率限制为 5 个请求 / 分钟。

将上述文件保存到 `/config/rl-config.yaml` 文件中。

现在我们可以运行 Docker Compose 文件，它将启动 Redis 和速率限制器服务。

```yaml
version: "3"
services:
  redis:
    image: redis:alpine
    expose:
      - 6379
    ports:
      - 6379:6379
    networks:
      - ratelimit-network

  # Rate limit service configuration
  ratelimit:
    image:  envoyproxy/ratelimit:bd46f11b
    command: /bin/ratelimit
    ports:
      - 10001:8081
      - 6070:6070
    depends_on:
      - redis
    networks:
      - ratelimit-network
    volumes:
      - $PWD/config:/data/config/config
    environment:
      - USE_STATSD=false
      - LOG_LEVEL=debug
      - REDIS_SOCKET_TYPE=tcp
      - REDIS_URL=redis:6379
      - RUNTIME_ROOT=/data
      - RUNTIME_SUBDIRECTORY=config

networks:
  ratelimit-network:
```

将上述文件保存为 `rl-docker-compose.yaml`，并使用下面的命令启动所有容器：

```sh
$ docker-compose -f rl-docker-compose.yaml up
```

为了确保速率限制器服务正确读取配置，我们可以检查容器的输出或使用速率限制器服务的调试端口。

```sh
$ curl localhost:6070/rlconfig
my_domain.generic_key_instance_1.header_match_get_request: unit=MINUTE requests_per_unit=5
```

随着速率限制器和 Redis 的启动和运行，我们可以启动 `httpbin` 容器。

```sh
docker run -d -p 3030:80 kennethreitz/httpbin
```

接下来，我们将创建 Envoy 配置，定义速率限制动作。我们将设置描述符 `instance_1` 和 `get_request`，只要有 GET 请求被发送到 `httpbin`。

在 `http_filters` 下，我们通过指定域名（`my_domain`）和指向 Envoy 可以用来到达速率限制服务的集群来配置 `ratelimit` 过滤器。

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
            - name: namespace.local_service
              domains: ["*"]
              routes:
              - match:
                  prefix: /
                route:
                  cluster: instance_1
                  rate_limits:
                  - actions:
                    - generic_key:
                        descriptor_value: instance_1
                    - header_value_match:
                        descriptor_value: get_request
                        headers:
                        - name: ":method"
                          exact_match: GET
          http_filters:
          - name: envoy.filters.http.ratelimit
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.ratelimit.v3.RateLimit
              domain: my_domain
              enable_x_ratelimit_headers: DRAFT_VERSION_03
              rate_limit_service:
                transport_api_version: V3
                grpc_service:
                    envoy_grpc:
                      cluster_name: rate-limit
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
  - name: rate-limit
    connect_timeout: 1s
    type: STATIC
    lb_policy: ROUND_ROBIN
    protocol_selection: USE_CONFIGURED_PROTOCOL
    http2_protocol_options: {}
    load_assignment:
      cluster_name: rate-limit
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 10001
admin:
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 9901
```

将上述 YAML 保存为 `2-lab-6-global-rate-limiter-1.yaml`，并使用 `func-e run -c 2-lab-6-global-rate-limiter-1.yaml` 运行代理。

我们现在可以发送五个以上的请求，我们会得到速率限制。

```sh
$ curl -v localhost:10000
...
< HTTP/1.1 429 Too Many Requests
< x-envoy-ratelimited: true
< x-ratelimit-limit: 5, 5;w=60
< x-ratelimit-remaining: 0
< x-ratelimit-reset: 25
...
```

我们收到了 429 响应，以及表明我们受到速率限制的响应头；在受到速率限制之前我们可以发出多少个请求（`x-ratelimit-remaining）`以及速率限制何时重置（`x-ratelimit-reset`）。

{{< cta cta_text="下一章" cta_link="../../cluster/" >}}
