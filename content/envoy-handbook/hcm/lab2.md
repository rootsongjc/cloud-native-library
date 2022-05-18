---
weight: 14
title: 实验2：流量分割
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将学习如何使用运行时分数和加权集群来配置 Envoy 的流量分割。

## 使用运行时分数

当我们只有两个上游集群时，运行时分数是一种很好的流量分割方法。运行时分数的工作原理是提供一个运行时分数（例如分子和分母），代表我们想要路由到一个特定集群的流量的分数。然后，我们使用相同的条件（即，在我们的例子中相同的前缀）提供第二个匹配，但不同的上游集群。

让我们创建一个 Envoy 配置，对 70% 的流量返回状态为 201 的直接响应。其余的流量返回状态为 202。

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
            - name: hello_vhost
              domains: ["*"]
              routes:
                - match:
                    prefix: "/"
                    runtime_fraction:
                      default_value:
                        numerator: 70
                        denominator: HUNDRED
                      runtime_key: routing.hello_io
                  direct_response:
                    status: 201
                    body:
                      inline_string: "v1"
                - match:
                    prefix: "/"
                  direct_response:
                    status: 202
                    body:
                      inline_string: "v2"
```

将上述 Envoy 配置保存为 `2-lab-2-traffic-splitting-1.yaml`，并以该配置运行 Envoy。

```sh
func-e run -c 2-lab-2-traffic-splitting-1.yaml
```

在 Envoy 运行时，我们可以使用 `hey` 工具向代理发送 200 个请求。

```sh
$ hey http://localhost:10000
...
Status code distribution:
  [201] 142 responses
  [202] 58 responses
```

看一下状态代码的分布，我们会注意到，我们收到 HTTP 201 响应大概占 71%，其余的响应是 HTTP 202 响应。

## 使用加权集群

当我们有两个以上的上游集群，我们想把流量分给它们，我们可以使用加权集群的方法。在这里，我们单独给每个上游集群分配权重。我们在以前的方法中使用了多个匹配，而在加权集群中，我们将使用一个路由和多个加权集群。

对于这种方法，我们必须定义实际的上游集群。我们将运行 `httpbin` 镜像的三个实例。让我们在 3030、4040 和 5050 端口上运行三个不同的实例；我们将在 Envoy 配置中把它们称为 `instance_1`、`instance_2` 和 `instance_3`。

```sh
docker run -d -p 3030:80 kennethreitz/httpbin
docker run -d -p 4040:80 kennethreitz/httpbin
docker run -d -p 5050:80 kennethreitz/httpbin
```

一个上游集群可以通过以下片段来定义。

```yaml
  clusters:
  - name: instance_1
    connect_timeout: 5s
    load_assignment:
      cluster_name: instance_1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 3030
```

让我们创建 Envoy 配置，将 50% 的流量分给 `instance_1`，30% 分给 `instance_2`，20% 分给 `instance_3`。

我们还将启用管理接口来检索指标，这些指标将显示向不同集群发出的请求数量。

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
                  weighted_clusters:
                    clusters:
                      - name: instance_1
                        weight: 50
                      - name: instance_2
                        weight: 30
                      - name: instance_3
                        weight: 20
  clusters:
  - name: instance_1
    connect_timeout: 5s
    load_assignment:
      cluster_name: instance_1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 3030
  - name: instance_2
    connect_timeout: 5s
    load_assignment:
      cluster_name: instance_1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 4040
  - name: instance_3
    connect_timeout: 5s
    load_assignment:
      cluster_name: instance_1
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 5050
admin:
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 9901
```

将上述 YAML 保存为 `2-lab-2-traffic-splitting-2.yaml` 并运行代理程序：`func-e run -c 2-lab-2-traffic-splitting-2.yaml`。

一旦代理运行，我们将使用 `hey` 来发送 200 个请求。

```sh
hey http://localhost:10000
```

来自 `hey` 的响应不会帮助我们确定分割，因为每个上游集群的响应都是 HTTP 200。

要想看到流量的分割，请在 `http://localhost:9901/stats/prometheus` 上打开统计表。在指标列表中，寻找 `envoy_cluster_external_upstream_rq` 指标，该指标计算外部上游请求的数量。我们应该看到与此类似的分割。

```
# TYPE envoy_cluster_external_upstream_rq counter
envoy_cluster_external_upstream_rq{envoy_response_code="200",envoy_cluster_name="instance_1"} 99
envoy_cluster_external_upstream_rq{envoy_response_code="200",envoy_cluster_name="instance_2"} 63
envoy_cluster_external_upstream_rq{envoy_response_code="200",envoy_cluster_name="instance_3"} 38
```

如果我们计算一下百分比，我们会发现它们与我们在配置中设置的百分比相对应。
