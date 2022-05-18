---
weight: 90
title: 实验15：使用 HTTP 分接式过滤器
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将展示如何使用和配置 HTTP 分接式过滤器。我们将配置一个 `/error` 路由，它返回一个直接的响应，其主体为 `error` 值。然后，在分接式过滤器中，我们将配置匹配器，以匹配任何响应主体包含 `error` 字符串和请求头 `debug: true` 的请求。如果这两个条件都为真，那么我们就分接该请求并将输出写入一个前缀为 `tap_debug` 的文件。

让我们从创建匹配配置开始。我们将使用两个匹配器，一个用来匹配请求头（`http_request_headers_match`），另一个用来匹配响应体（`http_response_generic_body_match`）。我们将用逻辑上的 AND 来组合这两个条件。

下面是匹配配置的样子。

```yaml
- name: envoy.filters.http.tap
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.tap.v3.Tap
    common_config:
      static_config:
        match:
          and_match:
            rules:
              - http_request_headers_match:
                  headers:
                    name: debug
                    string_match:
                      exact: "true"
              - http_response_generic_body_match:
                  patterns:
                    - string_match: error
```

我们将使用 `JSON_BODY_AS_STRING` 格式，并将输出写入以 `tap_debug` 为前缀的文件。

```yaml
output_config:
  sinks:
    - format: JSON_BODY_AS_STRING
      file_per_tap:
        path_prefix: tap_debug
```

让我们把这两块放在一起，创建一个完整的配置。我们将使用 `direct_response`，所以我们不需要设置或运行任何额外的服务。

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
          http_filters:
          - name: envoy.filters.http.tap
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.tap.v3.Tap
              common_config:
                static_config:
                  match:
                    and_match:
                      rules:
                        - http_request_headers_match:
                            headers:
                              name: debug
                              string_match:
                                exact: "true"
                        - http_response_generic_body_match:
                            patterns:
                              - string_match: error
                  output_config:
                    sinks:
                      - format: JSON_BODY_AS_STRING
                        file_per_tap:
                          path_prefix: tap_debug
          - name: envoy.filters.http.router
          route_config:
            name: local_route
            virtual_hosts:
            - name: local_service
              domains: ["*"]
              routes:
              - match:
                  path: "/"
                direct_response:
                  status: 200
                  body:
                    inline_string: hello
              - match:
                  path: "/error"
                direct_response:
                  status: 500
                  body:
                    inline_string: error
```

将上述 YAML 保存为 `7-lab-1-tap-filter-1.yaml` 文件，并使用 func-e CLI 运行它：

```sh
func-e run -c 7-lab-1-tap-filter-1.yaml &
```

如果我们发送一个请求到 `http://localhost:10000`，我们会收到符合第一条路由的响应（HTTP 200 和 body `hello`）。这个请求不会被分接，因为我们没有提供任何头信息，响应体也没有包含 `error` 值。

让我们试着设置 `debug` 头并向 `/error` 端点发送一个请求。

```sh
$ curl -H "debug: true" localhost:10000/error
error
```

这一次，在同一个文件夹中创建了一个包含被挖掘的请求内容的 JSON 文件。下面是该文件的内容应该是这样的。

```json
{
 "http_buffered_trace": {
  "request": {
   "headers": [
    {
     "key": ":authority",
     "value": "localhost:10000"
    },
    {
     "key": ":path",
     "value": "/error"
    },
    {
     "key": ":method",
     "value": "GET"
    },
    {
     "key": ":scheme",
     "value": "http"
    },
    {
     "key": "user-agent",
     "value": "curl/7.64.0"
    },
    {
     "key": "accept",
     "value": "*/*"
    },
    {
     "key": "debug",
     "value": "true"
    },
    {
     "key": "x-forwarded-proto",
     "value": "http"
    },
    {
     "key": "x-request-id",
     "value": "4855ee5d-7798-4c50-8692-a6989e72ca9b"
    }
   ],
   "trailers": []
  },
  "response": {
   "headers": [
    {
     "key": ":status",
     "value": "500"
    },
    {
     "key": "content-length",
     "value": "5"
    },
    {
     "key": "content-type",
     "value": "text/plain"
    },
    {
     "key": "date",
     "value": "Mon, 29 Nov 2021 22:38:32 GMT"
    },
    {
     "key": "server",
     "value": "envoy"
    }
   ],
   "body": {
    "truncated": false,
    "as_string": "error"
   },
   "trailers": []
  }
 }
}
```

输出显示了所有的请求头和 Trailer，以及我们收到的响应。

我们将在下一个例子中使用同样的场景，但我们将使用 `/tap` 管理端点来实现它。

首先，让我们创建 Envoy 配置。

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
          http_filters:
          - name: envoy.filters.http.tap
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.tap.v3.Tap
              common_config:
                admin_config:
                  config_id: my_tap_id
          - name: envoy.filters.http.router
          route_config:
            name: local_route
            virtual_hosts:
            - name: local_service
              domains: ["*"]
              routes:
              - match:
                  path: "/"
                direct_response:
                  status: 200
                  body:
                    inline_string: hello
              - match:
                  path: "/error"
                direct_response:
                  status: 500
                  body:
                    inline_string: error
admin:
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 9901
```

这一次，我们使用 `admin_config` 字段并指定配置 ID。此外，我们要使管理接口使用 `/tap` 端点。

将上述 YAML 保存为 `7-lab-1-tap-filter-2.yaml`，并使用 func-e CLI 运行它。

```sh
func-e run -c 7-lab-1-tap-filter-2.yaml &
```

如果我们尝试向 `/` 和 `error` 路径发送请求，我们会得到预期的响应。我们必须用 tap 配置向 `/t`ap 端点发送一个 POST 请求，以启用请求分接。

让我们使用这个符合任何请求的 tap 配置。

```json
{
  "config_id": "my_tap_id",
  "tap_config": {
    "match": {
      "any_match": true
    },
    "output_config": {
      "sinks": [
        {
          "streaming_admin": {}
        }
      ]
    }
  }
}
```

注意，我们提供的是与我们在 Envoy 配置中定义的 ID 相匹配的配置 ID。如果我们提供了一个无效的配置 ID，那么在向 `/tap` 端点发送 POST 请求时，我们会得到一个错误。

```
Unknown config id 'some_tap_id'. No extension has registered with this id.
```

我们还使用 `streaming_admin` 字段作为输出汇，这意味着如果 `/tap` 的 POST 请求被接受，那么 Envoy 将流式处理序列化的 JSON 信息，直到我们终止请求。

让我们把上述 JSON 保存到 `tap-config-any.json`，然后用 cURL 向 `/tap` 端点发送一个 POST 请求。

```sh
curl -X POST -d @tap-config-any.json http://localhost:9901/tap
```

我们将打开第二个终端窗口，向 `localhost:10000` 发送一个 cURL 请求，以测试配置。由于我们对所有的请求都进行了匹配，我们将在第一个终端窗口中看到流式分接的输出。

```json
{
 "http_buffered_trace": {
  "request": {
   "headers": [
    {
     "key": ":authority",
     "value": "localhost:10000"
    },
    {
     "key": ":path",
     "value": "/"
    },
    {
     "key": ":method",
     "value": "POST"
    },
    {
     "key": ":scheme",
     "value": "http"
    },
    {
     "key": "user-agent",
     "value": "curl/7.64.0"
    },
    {
     "key": "accept",
     "value": "*/*"
    },
    {
     "key": "content-length",
     "value": "198"
    },
    {
     "key": "content-type",
     "value": "application/x-www-form-urlencoded"
    },
    {
     "key": "x-forwarded-proto",
     "value": "http"
    },
    {
     "key": "x-request-id",
     "value": "59ca4c38-6112-444d-9b64-ff30e1326338"
    }
   ],
   "trailers": []
  },
  "response": {
   "headers": [
    {
     "key": ":status",
     "value": "200"
    },
    {
     "key": "content-length",
     "value": "5"
    },
    {
     "key": "content-type",
     "value": "text/plain"
    },
    {
     "key": "date",
     "value": "Mon, 29 Nov 2021 23:09:25 GMT"
    },
    {
     "key": "server",
     "value": "envoy"
    },
    {
     "key": "connection",
     "value": "close"
    }
   ],
   "body": {
    "truncated": false,
    "as_bytes": "aGVsbG8="
   },
   "trailers": []
  }
 }
}
```

{{< cta cta_text="下一章" cta_link="../../extending-envoy/" >}}
