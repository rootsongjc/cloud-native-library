---
weight: 4
title: 请求匹配
date: '2022-05-18T00:00:00+08:00'
type: book
---

本节将为你介绍 HTTP 连接管理器中的请求匹配。

## 路径匹配

我们只谈了一个使用`前缀`字段匹配前缀的匹配规则。下面的表格解释了其他支持的匹配规则。

| 规则名称          | 描述                                                         |
| ----------------- | ------------------------------------------------------------ |
| `prefix`          | 前缀必须与`path`标头的开头相匹配。例如，前缀 `/api` 将匹配路径 `/api` 和 `/api/v1`，而不是 `/`。 |
| `path`            | 路径必须与确切的`path`标头相匹配（没有查询字符串）。例如，路径 `/api` 将匹配路径 `/api`，但不匹配 `/api/v1` 或 `/`。 |
| `safe_regex`      | 路径必须符合指定的正则表达式。例如，正则表达式 `^/products/\d+$` 将匹配路径 `/products/123` 或 `/products/321`，但不是 `/products/hello` 或 `/api/products/123`。 |
| `connect_matcher` | 匹配器只匹配 CONNECT 请求（目前在 Alpha 中）。               |


默认情况下，前缀和路径匹配是大小写敏感的。要使其不区分大小写，我们可以将 `case_sensitive` 设置为 `false`。注意，这个设置不适用于 `safe_regex` 匹配。

## Header 匹配

另一种匹配请求的方法是指定一组 Header。路由器根据路由配置中所有指定的 Header 检查请求 Header。如果所有指定的头信息都存在于请求中，并且设置了相同的值，则进行匹配。

多个匹配规则可以应用于Header。

**范围匹配**

`range_match` 检查请求 Header 的值是否在指定的以十进制为单位的整数范围内。该值可以包括一个可选的加号或减号，后面是数字。

为了使用范围匹配，我们指定范围的开始和结束。起始值是包含的，而终止值是不包含的（`[start, end)`）。

```yaml
- match:
    prefix: "/"
    headers:
    - name: minor_version
      range_match:
        start: 1
        end: 11
```

上述范围匹配将匹配 `minor_version` 头的值，如果它被设置为 1 到 10 之间的任何数字。

**存在匹配**

`present_match` 检查传入的请求中是否存在一个特定的头。

```yaml
- match:
    prefix: "/"
    headers:
    - name: debug
      present_match: true
```

如果我们设置了`debug`头，无论头的值是多少，上面的片段都会评估为`true`。如果我们把 `present_match` 的值设为 `false`，我们就可以检查是否有 Header。

**字符串匹配**

`string_match` 允许我们通过前缀或后缀，使用正则表达式或检查该值是否包含一个特定的字符串，来准确匹配头的值。

```yaml
- match:
    prefix: "/"
    headers:
    # 头部`regex_match`匹配所提供的正则表达式
    - name: regex_match
      string_match:
        safe_regex_match:
          google_re2: {}
          regex: "^v\\d+$"
    # Header `exact_match`包含值`hello`。
    - name: exact_match
      string_match:
        exact:"hello"
    # 头部`prefix_match`以`api`开头。
    - name: prefix_match
      string_match:
        prefix:"api"
    # 头部`后缀_match`以`_1`结束
    - name: suffix_match
      string_match:
        suffix: "_1"
    # 头部`contains_match`包含值 "debug"
    - name: contains_match
      string_match:
        contains: "debug"
```

**反转匹配**

如果我们设置了 `invert_match`，匹配结果就会反转。

```yaml
- match:
    prefix: "/"
    headers:
    - name: version
      range_match: 
        start: 1
        end: 6
      invert_match: true
```

上面的片段将检查 `version` 头中的值是否在 1 和 5 之间；然而，由于我们添加了 `invert_match` 字段，它反转了结果，检查头中的值是否超出了这个范围。

`invert_match` 可以被其他匹配器使用。例如：

```yaml
- match:
    prefix: "/"
    headers:
    - name: env
      contains_match: "test"
      invert_match: true
```

上面的片段将检查 `env` 头的值是否包含字符串`test`。如果我们设置了 `env` 头，并且它不包括字符串`test`，那么整个匹配的评估结果为真。

## 查询参数匹配

使用 `query_parameters` 字段，我们可以指定路由应该匹配的 URL 查询的参数。过滤器将检查来自`path`头的查询字符串，并将其与所提供的参数进行比较。

如果有一个以上的查询参数被指定，它们必须与规则相匹配，才能评估为真。

请考虑以下例子。

```yaml
- match:
    prefix: "/"
    query_parameters:
    - name: env
      present_match: true
```

如果有一个名为 `env` 的查询参数被设置，上面的片段将评估为真。它没有说任何关于该值的事情。它只是检查它是否存在。例如，使用上述匹配器，下面的请求将被评估为真。

```sh
GET /hello?env=test
```

我们还可以使用字符串匹配器来检查查询参数的值。下表列出了字符串匹配的不同规则。

| 规则名称     | 描述                                     |
| ------------ | ---------------------------------------- |
| `exact`      | 必须与查询参数的精确值相匹配。           |
| `prefix`     | 前缀必须符合查询参数值的开头。           |
| `suffix`     | 后缀必须符合查询参数值的结尾。           |
| `safe_regex` | 查询参数值必须符合指定的正则表达式。     |
| `contains`   | 检查查询参数值是否包含一个特定的字符串。 |

除了上述规则外，我们还可以使用 `ignore_case` 字段来指示精确、前缀或后缀匹配是否应该区分大小写。如果设置为 "true"，匹配就不区分大小写。

下面是另一个使用前缀规则进行不区分大小写的查询参数匹配的例子。

```yaml
- match:
    prefix: "/"
    query_parameters:
    - name: env
      string_match:
        prefix: "env_"
        ignore_case: true
```

如果有一个名为 `env` 的查询参数，其值以 `env_`开头，则上述内容将评估为真。例如，`env_staging` 和 `ENV_prod` 评估为真。

## gRPC 和 TLS 匹配器

我们可以在路由上配置另外两个匹配器：gRPC 路由匹配器（`grpc`）和 TLS 上下文匹配器（`tls_context`）。

gRPC 匹配器将只在 gRPC 请求上匹配。路由器检查内容类型头的 `application/grpc` 和其他 `application/grpc+` 值，以确定该请求是否是 gRPC 请求。

例如：

```yaml
- match:
    prefix: "/"
    grpc: {}
```

> 注意 gRPC 匹配器没有任何选项。

如果请求是 gRPC 请求，上面的片段将匹配路由。

同样，如果指定了 TLS 匹配器，它将根据提供的选项来匹配 TLS 上下文。在 `tls_context` 字段中，我们可以定义两个布尔值——presented 和 validated。`presented`字段检查证书是否被出示。`validated`字段检查证书是否被验证。

例如：

```yaml
- match:
    prefix: "/"
    tls_context:
      presented: true
      validated: true
```

如果一个证书既被出示又被验证，上述匹配评估为真。