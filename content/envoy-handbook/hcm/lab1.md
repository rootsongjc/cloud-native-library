---
weight: 13
title: 实验1：请求匹配
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将学习如何配置使用不同的方式来匹配请求。我们将使用 `direct_response`，我们还不会涉及任何 Envoy 集群。

## 路径匹配

以下是我们想放入配置中的规则：

1. 所有请求都需要来自 `hello.io` 域名（即在向代理发出请求时，我们将使用 `Host: hello.io` 标头）
2. 所有向路径 `/api` 发出的请求将返回字符串 `hello - path`
3. 所有向根路径（即 `/`）发出的请求将返回字符串 `hello - prefix`
4. 所有以 `/hello` 开头并在后面加上数字的请求（如 `/hello/1`，`/hello/523`）都应返回 `hello - regex`字符串

让我们看一下配置：

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
            name: route
            virtual_hosts:
            - name: hello_vhost
              domains: ["hello.io"]
              routes:
              - match:
                  path: "/api"
                direct_response:
                  status: 200
                  body:
                    inline_string: "hello - path"
              - match:
                  safe_regex:
                    google_re2: {}
                    regex: ^/hello/\d+$
                direct_response:
                  status: 200
                  body:
                    inline_string: "hello - regex"
              - match:
                  prefix: "/"
                direct_response:
                  status: 200
                  body:
                    inline_string: "hello - prefix"
```

由于我们只有一个域名，我们将使用一个单一的虚拟主机。域名数组将包含一个单一的域名：`hello.io`。这是 Envoy 要做的第一层匹配。

然后，虚拟主机将有多个路径匹配。首先，我们将使用路径匹配，因为我们想准确匹配 `/api` 路径。其次，我们使用 `^/hello/\d+$` 正则表达式来定义正则表达式匹配。最后，我们定义前缀匹配。注意，定义这些匹配的顺序很重要。如果我们把前缀匹配放在最前面，那么其余的匹配就不会被评估，因为前缀匹配永远是真的。

将上述 YAML 保存为 `2-lab-1-request-matching-1.yaml`，然后运行 `func-e run -c 2-lab-1-request-matching-1.yaml` 来启动 Envoy 代理。

从另一个单独的终端，我们可以进行一些测试调用。

```sh
$ curl -H "Host: hello.io" localhost:10000
hello - prefix

$ curl -H "Host: hello.io" localhost:10000/api
hello - path

$ curl -H "Host: hello.io" localhost:10000/hello/123
hello - regex
```

## 标头匹配

匹配传入请求的头信息可以与路径匹配相结合，以实现复杂的场景。在这个例子中，我们将使用前缀匹配和不同头信息匹配的组合。

让我们设想一些规则：

- 所有带头信息 `debug: 1` 的 POST 请求发送到 `/1`，返回 422 状态码
- 所有发送至 `/2` 的头为 `path` 且与正则表达式 `^/hello/\d+$` 相匹配的请求都会返回一个 200 状态码和消息 `regex`
- 所有将头名称 `priority` 设置为 1 到 5 之间的请求，发送到 `/3` 会返回一个 200 状态码和消息 `priority`
- 所有发送到 `/4` 的请求，如果存在 `test` 头，都会返回一个 500 状态码

以下是翻译成 Envoy 配置的上述规则：

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
            name: route
            virtual_hosts:
            - name: vhost
              domains: ["*"]
              routes:
              - match:
                  path: "/1"
                  headers:
                  - name: ":method"
                    string_match:
                      exact: POST
                  - name: "debug"
                    string_match:
                      exact: "1"
                direct_response:
                  status: 422
              - match:
                  path: "/2"
                  headers:
                  - name: "path"
                    safe_regex_match:
                      google_re2: {}
                      regex: ^/hello/\d+$
                direct_response:
                  status: 200
                  body:
                    inline_string: "regex"
              - match:
                  path: "/3"
                  headers:
                  - name: "priority"
                    range_match:
                      start: 1
                      end: 6
                direct_response:
                  status: 200
                  body:
                    inline_string: "priority"
              - match:
                  path: "/4"
                  headers:
                  - name: "test"
                    present_match: true
                direct_response:
                  status: 500
```

将上述 YAML 保存为 `2-lab-1-request-matching-2.yaml` 并运行 

```sh
func-e run -c 2-lab-1-request-matching-2.yaml
```

让我们试着发送几个请求，测试一下规则：

```sh
$ curl -v -X POST -H "debug: 1" localhost:10000/1
...
> User-Agent: curl/7.64.0
> Accept: */*
> debug: 1
>
< HTTP/1.1 422 Unprocessable Entity

$ curl -H "path: /hello/123" localhost:10000/2
regex

$ curl -H "priority: 3" localhost:10000/3
priority


$ curl -v -H "test: tst" localhost:10000/4
...
> User-Agent: curl/7.64.0
> Accept: */*
> test: tst
>
< HTTP/1.1 500 Internal Server Error
```

## 查询参数匹配

与我们做路径和 Header 匹配的方式相同，我们也可以匹配特定的查询参数和它们的值。查询参数匹配支持与其他两项相同的匹配规则：匹配精确值、前缀和后缀，使用正则表达式，以及检查查询参数是否包含特定值。

让我们考虑配置中的以下情景：

- 所有发送到路径 `/1` 并带有查询参数 `test` 请求都返回 422 状态码
- 所有发送到路径 `/2` 的查询参数为 `env` 的请求，其值以 `env_`开头（忽略大小写），返回 200 状态代码
- 所有发送到路径 `/3` 的查询参数 `debug` 设置为 `true` 的请求，都返回 500 状态码

上述规则转化为以下 Envoy 配置：

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
            name: route
            virtual_hosts:
            - name: vhost
              domains: ["*"]
              routes:
              - match:
                  path: "/1"
                  query_parameters:
                  - name: test
                    present_match: true
                direct_response:
                  status: 422
              - match:
                  path: "/2"
                  query_parameters:
                  - name: env
                    string_match:
                      prefix: env_
                      ignore_case: true
                direct_response:
                  status: 200
              - match:
                  path: "/3"
                  query_parameters:
                  - name: debug
                    string_match:
                      exact: "true"
                direct_response:
                  status: 500
```

将上述 YAML 保存为 `2-lab-1-request-matching-3.yaml` 并运行 

```sh
func-e run -c 2-lab-1-request-matching-3.yaml
```

让我们试着发送几个请求，测试一下规则。

```sh
$ curl -v localhost:10000/1?test
...
> GET /1?test HTTP/1.1
> Host: localhost:10000
> User-Agent: curl/7.64.0
> Accept: */*
>
< HTTP/1.1 422 Unprocessable Entity

$ curl -v localhost:10000/2?env=eNv_prod
...
> GET /2?env=eNv_prod HTTP/1.1
> Host: localhost:10000
> User-Agent: curl/7.64.0
> Accept: */*
>
< HTTP/1.1 200 OK

$ curl -v localhost:10000/3?debug=true
...
> GET /3?debug=true HTTP/1.1
> Host: localhost:10000
> User-Agent: curl/7.64.0
> Accept: */*
>
< HTTP/1.1 500 Internal Server Error
```
