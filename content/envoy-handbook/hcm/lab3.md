---
weight: 15
title: 实验3：Header操作
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将学习如何在不同的配置级别上操作请求和响应头。

我们将使用一个单一的例子，它的作用如下：

- 对所有的请求添加一个响应头 `lab: 3`
- 在虚拟主机上添加一个请求头 `vh: one`
- 为 `/json` 路由匹配添加一个名为 `json` 响应头。响应头有来自请求头 `hello` 的值

我们将只有一个名为 `single_cluster` 的上游集群，监听端口为 `3030`。让我们运行监听该端口的 `httpbin` 容器：

```sh
docker run -d -p 3030:80 kennethreitz/httpbin
```

让我们创建遵循上述规则的 Envoy 配置：

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
            response_headers_to_add:
              - header:
                  key: "lab"
                  value: "3"
            virtual_hosts:
            - name: vh_1
              request_headers_to_add:
                - header: 
                    key: vh
                    value: "one"
              domains: ["*"]
              routes:
                - match:
                    prefix: "/json"
                  route:
                    cluster: single_cluster
                  response_headers_to_add:
                    - header: 
                        key: "json"
                        value: "%REQ(hello)%"
                - match:
                    prefix: "/"
                  route:
                    cluster: single_cluster
  clusters:
  - name: single_cluster
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
```

将上述 YAML 保存为 `2-lab-3-header-manipulation-1.yaml` 并运行 Envoy 代理：

```sh
func-e run -c 2-lab-3-header-manipulation-1.yaml
```

让我们先对 `/headers` 做一个简单的请求，这将匹配 `/` 前缀：

```sh
$ curl -v localhost:10000/headers
...
< x-envoy-upstream-service-time: 2
< lab: 3
<
{
  "headers": {
    "Accept": "*/*",
    "Host": "localhost:10000",
    "User-Agent": "curl/7.64.0",
    "Vh": "one",
    "X-Envoy-Expected-Rq-Timeout-Ms": "15000"
  }
}
```

我们会注意到响应 Header `lab: 3` 被设置了。这来自路由配置，并将被添加到我们的所有请求中。

在响应中，我们可以看到 `Vh: one` 头（注意这个大写字母来自 `httpbin` 代码）被添加到请求中。`httpbin` 的响应显示了所收到的头信息（即请求头信息）。

让我们试着向 `/json` 路径发出请求。发送到该路径上的 `httpbin` 的请求将返回一个 JSON 样本。此外，这一次我们将包括一个名为 `hello: world` 的请求头。

```sh
$ curl -v -H "hello: world" localhost:10000/json
> GET /json HTTP/1.1
> Host: localhost:10000
> User-Agent: curl/7.64.0
> Accept: */*
> hello: world
>
< HTTP/1.1 200 OK
< server: envoy
< json: world
< lab: 3
...
```

注意这次我们设置的请求头（`hello: world`），在响应路径上，我们看到 `json: world` 头，它的值来自我们设置的请求头。同样地，`lab: 3` 响应头被设置。请求头 `Vh: one` 也同时被设置，但这次我们看不到它，因为它没有被输出。
