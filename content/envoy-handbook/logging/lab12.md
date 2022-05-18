---
weight: 50
title: 实验 12：使用日志过滤器
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将学习使用日志过滤器，根据一些请求属性，只记录某些请求。

让我们想出几个我们想用过滤器来实现的日志要求。

- 将所有带有 HTTP 404 状态码的请求记录到一个名为 `not_found.log` 的日志文件中。
- 将所有带有 `env=debug` 头值的请求记录到一个名为 `debug.log` 的日志文件中。
- 将所有 POST 请求记录到标准输出

基于这些要求，我们将有两个访问记录器记录到文件（`not_found.log` 和 `debug.log`）和一个写到 stdout 的访问记录器。

`access_log` 字段是一个数组，我们可以在它下面定义多个记录器。在各个日志记录器里面，我们可以使用 `filter` 字段来指定何时将字符串写到日志中。

对于第一个要求，我们将使用状态码过滤器，而对于第二个要求，我们将使用 Header 过滤器。下面是配置的样子。

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
          access_log:
          - name: envoy.access_loggers.file
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
              path: ./debug.log
            filter:
              header_filter:
                header:
                  name: env
                  string_match:
                    exact: debug
          - name: envoy.access_loggers.file
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
              path: ./not_found.log
            filter:
              status_code_filter:
                comparison:
                  value:
                    default_value: 404
                    runtime_key: ingress_http_status_code_filter
          - name: envoy.access_loggers.stdout
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
            filter:
              header_filter:
                header:
                  name: ":method"
                  string_match:
                    exact: POST
          http_filters:
          - name: envoy.filters.http.router
          route_config:
            name: my_first_route
            virtual_hosts:
            - name: direct_response_service
              domains: ["*"]
              routes:
              - match:
                  prefix: "/404"
                direct_response:
                  status: 404
                  body:
                    inline_string: "404"
              - match:
                  prefix: "/"
                direct_response:
                  status: 200
                  body:
                    inline_string: "200"
```

将上述 YAML 保存为 `6-lab-1-logging-filters.yaml` 并在后台运行 Envoy。

```sh
func-e run -c 6-lab-1-logging-filters.yaml &
```

在 Envoy 运行的情况下，如果我们发送一个请求到 `http://localhost:10000`，那么我们会注意到没有任何东西被写入标准输出或日志文件。

接下来让我们试试 POST 请求。

```sh
$ curl -X POST localhost:10000
[2021-11-03T21:52:36.398Z] "POST / HTTP/1.1" 200 - 0 3 0 - "-" "curl/7.64.0" "528335ae-8f0d-4d22-934a-02d4702a9c62" "localhost:10000" "-"
```

你会注意到，日志条目被写到了配置中定义的标准输出。

接下来，让我们发送一个头信息 `env: debug` 与以下请求。

```sh
curl -H "env: debug" localhost:10000
```

像第一个例子一样，没有任何东西会被写入标准输出（这不是一个 POST 请求）。然而，如果我们在 `debug.log` 文件中查看，那么我们会看到日志条目。

```sh
$ cat debug.log
[2021-11-03T21:54:49.357Z] "GET / HTTP/1.1" 200 - 0 3 0 - "-" "curl/7.64.0" "ea2a11d6-6ccb-4f13-9686-4d30dbc3136e" "localhost:10000" "-"
```

同样地，让我们向 `/404` 发送一个请求，并查看 `not_found.log` 文件。

```sh
$ curl localhost:10000/404
404

$ cat not_found.log
[2021-11-03T21:55:37.891Z] "GET /404 HTTP/1.1" 404 - 0 3 0 - "-" "curl/7.64.0" "59bf1a1a-62b2-49e4-9226-7c49516ec390" "localhost:10000" "-"
```

在满足多个过滤条件的情况下（例如，我们有一个 POST 请求*，*我们将请求发送到 `/404`），在这种情况下，日志将被写入标准输出和 `not_found.log`。

