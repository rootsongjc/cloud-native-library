---
weight: 60
title: 实验7：断路器
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将演示如何使用断路器。我们将运行一个 Python HTTP 服务器和一个 Envoy 代理在它前面。要启动在 8000 端口监听的 Python 服务器，请运行：

```sh
python3 -m http.server 8000
```

接下来，我们将用下面的断路器创建 Envoy 配置：

```yaml
...
    circuit_breakers:
      thresholds:
        max_connections: 20
        max_requests: 100
        max_pending_requests: 20
```

因此，如果我们超过了 20 个连接或 100 个请求或 20 个待处理请求，断路器就会断开。下面是完整的 Envoy 配置：

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
          stat_prefix: listener_http
          http_filters:
          - name: envoy.filters.http.router
          route_config:
            name: route
            virtual_hosts:
            - name: vh
              domains: ["*"]
              routes:
              - match:
                  prefix: "/"
                route:
                  cluster: python_server
  clusters:
  - name: python_server
    connect_timeout: 5s
    circuit_breakers:
      thresholds:
        max_connections: 20
        max_requests: 100
        max_pending_requests: 20
    load_assignment:
      cluster_name: python_server
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 8000
admin:
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 9901
```

将上述配置保存为 `3-lab-1-circuit-breaker.yaml`，然后运行 Envoy 代理。

```sh
func-e run -c 3-lab-1-circuit-breaker.yaml
```

为了向代理发送多个并发请求，我们将使用一个名为 [hey](https://github.com/rakyll/hey) 的工具。默认情况下，hey 运行 50 个并发，发送 200 个请求，所以我们在请求 [http://localhost:1000](http://localhost:1000/)，甚至不需要传入任何参数。

```sh
hey http://localhost:10000
...
Status code distribution:
  [200] 104 responses
  [503] 96 responses
```

`hey` 将输出许多统计数字，但我们感兴趣的是状态码的分布。它显示我们在收到了 104 个 HTTP 200 响应，在 96 个 HTTP 503 响应 —— 这就是断路器断开的地方。

我们可以使用 Envoy 的管理接口（运行在 9901 端口）来查看详细的指标，比如说：

```
...
envoy_cluster_upstream_cx_overflow{envoy_cluster_name="python_server"} 104
envoy_cluster_upstream_rq_pending_overflow{envoy_cluster_name="python_server"} 96
```

{{< cta cta_text="下一章" cta_link="../../dynamic-config/" >}}
