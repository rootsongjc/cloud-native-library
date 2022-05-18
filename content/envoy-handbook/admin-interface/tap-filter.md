---
weight: 70
title: 分接式过滤器
date: '2022-05-18T00:00:00+08:00'
type: book
---

分接式过滤器（Tap Filter）的目的是根据一些匹配的属性来记录 HTTP 流量。有两种方法来配置分接式过滤器。

1. 使用 Envoy 配置里面的 `static_config` 字段

2. 使用 `admin_config` 字段并指定配置 ID。

不同的是，我们在静态配置（`static_config`）中一次性提供所有东西——匹配配置和输出配置。当使用管理配置（`admin_config`）时，我们只提供配置 ID，然后在运行时使用 `/tap` 管理端点来配置过滤器。

正如我们所提到的，过滤器的配置被分成两部分：**匹配配置**和**输出配置**。

我们可以用匹配配置指定匹配谓词，告诉分接式过滤器要分接哪些请求并写入配置的输出。

例如，下面的片段显示了如何使用 `any_match` 来匹配所有的请求，无论其属性如何。

```yaml
common_config:
  static_config:
    match:
      any_match: true
...
```

我们也有一个选项，可以在请求和响应 Header、Trailer 和正文上进行匹配。

## Header/Trailer 匹配

Header/Trailer 匹配器使用 `HttpHeadersMatch ` proto，在这里我们指定一个头数组来匹配。例如，这个片段匹配任何请求头 `my-header` 被精确设置为 `hello` 的请求。

```yaml
common_config:
  static_config:
    match:
      http_request_headers_match:
        headers:
          name: "my-header"
          string_match:
            exact: "hello"
...
```

> 请注意，在 `string_match` 中，我们可以使用其他匹配器（例如 `prefix`、`surffix`、`safe_regex`），正如前面解释的那样。

## 正文匹配

通用请求和响应正文（body）匹配使用 `HttpGenericBodyMatch` 来指定字符串或二进制匹配。顾名思义，字符串匹配（`string_match`）是在 HTTP 正文中寻找一个字符串，而二进制匹配（`binary_match`）是在 HTTP 正文中寻找一串字节的位置。

例如，如果响应体包含字符串 `hello`，则下面的片段可以匹配。

```yaml
common_config:
  static_config:
    match:
      http_response_generic_body_match:
        patterns:
          string_match: "hello"
...
```

## 匹配谓词

我们可以用 `or_match`、`and_match` 和 `not_match` 等匹配谓词来组合多个 Header、Trailer 和正文匹配器。

`or_match` 和 `and_match` 使用 `MatchSet` 原语，描述逻辑 OR 或逻辑 AND。我们在匹配集内的 `rules` 字段中指定构成一个集合的规则列表。

下面的例子显示了如何使用 `and_match` 来确保响应体包含 `hello` 这个词，以及请求头 `my-header` 被设置为 `hello`。

```yaml
common_config:
  static_config:
    match:
      and_match:
        rules:
         - http_response_generic_body_match:
            patterns:
              - string_match: "hello"
          - http_request_headers_match:
              headers:
                name: "my-header"
                string_match:
                  exact: "hello"
...
```

如果我们想实现逻辑 OR，那么我们可以用 `or_match` 字段替换 `and_match` 字段。字段内的配置将保持不变，因为两个字段都使用 `MatchSet ` proto。

让我们使用与之前相同的例子来说明 `not_match` 是如何工作的。假设我们想过滤所有没有设置头信息 `my-header: hello` 的请求，以及响应体不包括 `hello` 这个字符串的请求。

下面是我们如何写这个配置。

```yaml
common_config:
  static_config:
    match:
      not_match:
        and_match:
          rules:
          - http_response_generic_body_match:
              patterns:
                - string_match: "hello"
            - http_request_headers_match:
                headers:
                  name: "my-header"
                  string_match:
                    exact: "hello"
...
```

`not_match ` 字段和父 `match` 字段一样使用 `MatchPredicate  ` 原语。匹配字段是一个递归结构，它允许我们创建复杂的嵌套匹配配置。

这里要提到的最后一个字段是 `any_match`。这是一个布尔字段，当设置为 `true` 时，将总是匹配。

## 输出配置

一旦请求被过滤出来，我们需要告诉过滤器将输出写入哪里。目前，我们可以配置一个单一的输出沉积。

下面是一个输出配置示例。

```yaml
...
output_config:
  sinks:
    - format: JSON_BODY_AS_STRING
      file_per_tap:
        path_prefix: tap
...
```

使用 `file_per_tap`，我们指定要为每个被监听的数据流输出一个文件。`path_prefix` 指定了输出文件的前缀。文件用以下格式命名：

```
<path_prefix>_<id>.<pb | json>
```

`id` 代表一个标识符，使我们能够区分流实例的记录跟踪。文件扩展名（`pb` 或 `json`）取决于格式选择。

捕获输出的第二个选项是使用 `streaming_admin` 字段。这指定了 `/tap` 管理端点将流式传输被捕获的输出。请注意，要使用 `/tap` 管理端点进行输出，还必须使用 `admin_config` 字段配置分接式过滤器。如果我们静态地配置了分接式过滤器，我们就不会使用 `/tap` 端点来获取输出。

### 格式选择

我们有多种输出格式的选项，指定消息的书写方式。让我们看看不同的格式，从默认格式开始，`JSON_BODY_AS_BYTES`。

`JSON_BODY_AS_BYTES` 输出格式将消息输出为 JSON，任何响应的 body 数据将在 `as_bytes` 字段中，其中包含 base64 编码的字符串。

例如，下面是分接输出的示例。

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
     "key": "my-header",
     "value": "hello"
    },
    {
     "key": "x-forwarded-proto",
     "value": "http"
    },
    {
     "key": "x-request-id",
     "value": "67e3e8ac-429a-42fb-945b-ec25927fdcc1"
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
     "value": "Mon, 29 Nov 2021 19:31:43 GMT"
    },
    {
     "key": "server",
     "value": "envoy"
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

注意 `body` 中的 `as_bytes` 字段。该值是 body 数据的 base64 编码表示（本例中为 `hello`）。

第二种输出格式是 `JSON_BODY_AS_STRING`。与之前的格式不同的是，在 `JSON_BODY_AS_STRING` 中，body 数据是以字符串的形式写在 `as_string` 字段中。当我们知道 body 是人类可读的，并且不需要对数据进行 base64 编码时，这种格式很有用。

```json
...
   "body": {
    "truncated": false,
    "as_string": "hello"
   },
...
```

其他三种格式类型是 `PROTO_BINARY`、`PROTO_BINARY_LENGTH_DELIMITED` 和 `PROTO_TEXT`。

`PROTO_BINARY` 格式以二进制 proto 格式写入输出。这种格式不是自限性的，这意味着如果分接写了多个没有任何长度信息的二进制消息，那么数据流将没有用处。如果我们在每个文件中写一个消息，那么输出格式将更容易解析。

我们也可以使用 `PROTO_BINARY_LENGTH_DELIMITED` 格式，其中消息被写成序列元组。每个元组是消息长度（编码为 32 位 protobuf varint 类型），后面是二进制消息。

最后，我们还可以使用 `PROTO_TEXT` 格式，在这种格式下，输出结果以下面的 protobuf 格式写入。

```protobuf
http_buffered_trace {
  request {
    headers {
      key: ":authority"
      value: "localhost:10000"
    }
    headers {
      key: ":path"
      value: "/"
    }
    headers {
      key: ":method"
      value: "GET"
    }
    headers {
      key: ":scheme"
      value: "http"
    }
    headers {
      key: "user-agent"
      value: "curl/7.64.0"
    }
    headers {
      key: "accept"
      value: "*/*"
    }
    headers {
      key: "debug"
      value: "true"
    }
    headers {
      key: "x-forwarded-proto"
      value: "http"
    }
    headers {
      key: "x-request-id"
      value: "af6e0879-e057-4efc-83e4-846ff4d46efe"
    }
  }
  response {
    headers {
      key: ":status"
      value: "500"
    }
    headers {
      key: "content-length"
      value: "5"
    }
    headers {
      key: "content-type"
      value: "text/plain"
    }
    headers {
      key: "date"
      value: "Mon, 29 Nov 2021 22:32:40 GMT"
    }
    headers {
      key: "server"
      value: "envoy"
    }
    body {
      as_bytes: "hello"
    }
  }
}
```

## 静态配置分接式过滤器

我们把匹配的配置和输出配置（使用 `file_per_tap` 字段）结合起来，静态地配置分接式过滤器。

下面是一个通过静态配置来配置分接式过滤器的片段。

```yaml
- name: envoy.filters.http.tap
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.filters.http.tap.v3.Tap
    common_config:
      static_config:
        match_config:
          any_match: true
        output_config:
          sinks:
            - format: JSON_BODY_AS_STRING
              file_per_tap:
                path_prefx: my-tap
```

上述配置将匹配所有的请求，并将输出写入带有 `my-tap` 前缀的文件名中。

## 使用 `/tap` 端点配置分接式过滤器

为了使用 `/tap` 端点，我们必须在分接式过滤器配置中指定 `admin_config` 和 `config_id`。

```yaml
- name: envoy.filters.http.tap
  typed_config:
    "@type": type.googleapis.com/envoy.extensions. filters.http.tap.v3.Tap
    common_config:
      admin_config:
        config_id: my_tap_config_id
```

一旦指定，我们就可以向 `/tap` 端点发送 POST 请求以配置分接式过滤器。例如，下面是配置 `my_tap_config_id` 名称所引用的分接式过滤器的 POST 正文。

```yaml
config_id: my_tap_config_id
tap_config:
  match_config:
    any_match: true
  output_config:
    sinks:
      - streaming_admin:{}
```

我们指定匹配配置的格式等同于我们为静态提供的配置所设置的格式。

使用管理配置和 `/tap` 端点的明显优势是，我们可以在运行时更新匹配配置，而且不需要重新启动 Envoy 代理。