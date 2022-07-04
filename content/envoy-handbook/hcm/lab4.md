---
weight: 16
title: 实验4:重试
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将学习如何配置不同的重试策略。我们将使用 `httpbin` Docker 镜像，因为我们可以向不同的路径（例如 `/status/[statuscode]`）发送请求，而 `httpbin` 会以该状态码进行响应。

确保你有 `httpbin` 容器在 3030 端口监听。

```sh
docker run -d -p 3030:80 kennethreitz/httpbin
```

让我们创建 Envoy 配置，定义一个关于 `5xx` 响应的简单重试策略。我们还将启用管理接口，这样我们就可以在指标中看到重试的报告。

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
          stat_prefix: hello_service
          http_filters:
          - name: envoy.filters.http.router
          route_config:
            virtual_hosts:
            - name: httpbin
              domains: ["*"]
              routes:
                - match:
                    prefix: "/"
                  route:
                    cluster: httpbin
                    retry_policy:
                      retry_on: "5xx"
                      num_retries: 5
  clusters:
  - name: httpbin
    connect_timeout: 5s
    load_assignment:
      cluster_name: single_cluster
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

将上述 YAML 保存为 `2-lab-4-retries-1.yaml`，然后运行 Envoy 代理：

```sh
func-e run -c 2-lab-4-retries-1.yaml
```

让我们向 `/status/500` 路径发送一个单一请求。

```sh
$ curl -v localhost:10000/status/500
...
< HTTP/1.1 500 Internal Server Error
< server: envoy
...
< content-length: 0
< x-envoy-upstream-service-time: 276
```

正如预期的那样，我们收到了一个 500 响应。另外，注意到 `x-envoy-upstream-service-time`（上游主机处理该请求所花费的时间，以毫秒为单位）比我们发送 `/status/200` 请求时要大得多。

```sh
$ curl localhost:10000/status/200
...
< HTTP/1.1 200 OK
< server: envoy
...
< content-length: 0
< x-envoy-upstream-service-time: 2
```

这是因为 Envoy 执行了重试，但最后还是失败了。同样，如果我们在管理界面（`http://localhost:9901/stats/prometheus>`）上打开统计页面，我们会发现代表重试次数的指标（`envoy_cluster_retry_upstream_rq`）的数值为 5。

```
# TYPE envoy_cluster_retry_upstream_rq counter
envoy_cluster_retry_upstream_rq{envoy_response_code="500",envoy_cluster_name="httpbin"} 5
```
