---
weight: 80
title: 高级路由
date: '2022-05-18T00:00:00+08:00'
type: book
---

在前面，我们了解了如何利用流量的比例（`weight` 字段）在多个子集之间进行流量路由。在某些情况下，纯粹的基于权重的流量路由或分割已经足够了。然而，在有些场景和情况下，我们可能需要对流量如何被分割和转发到目标服务进行更细化的控制。

Istio 允许我们使用传入请求的一部分，并将其与定义的值相匹配。例如，我们可以匹配传入请求的 **URI前缀**，并基于此路由流量。

| 属性      | 描述                                                         |
| --------- | ------------------------------------------------------------ |
| uri       | 将请求 URI 与指定值相匹配                                    |
| schema    | 匹配请求的 schema（HTTP、HTTPS...）                          |
| method    | 匹配请求的 method（GET、POST...）                            |
| authority | 匹配请求 authority 头                                        |
| headers   | 匹配请求头。头信息必须是小写的，并以连字符分隔（例如：`x-my-request-id`）。注意，如果我们使用头信息进行匹配，其他属性将被忽略（`uri`、`schema`、`method`、`authority`）。 |

上述每个属性都可以用这些方法中的一种进行匹配：

- 精确匹配：例如，`exact: "value"` 匹配精确的字符串

- 前缀匹配：例如，`prefix: "value"` 只匹配前缀

- 这则匹配：例如，`regex："value"` 根据 ECMAscript 风格的正则进行匹配

例如，假设请求的 URI 看起来像这样：`https://dev.example.com/v1/api`。为了匹配该请求的 URI，我们会这样写：

```yaml
http:
- match:
  - uri:
      prefix: /v1
```

上述片段将匹配传入的请求，并且请求将被路由到该路由中定义的目的地。

另一个例子是使用正则并在头上进行匹配。

```yaml
http:
- match:
  - headers:
      user-agent:
        regex: '.*Firefox.*'
```

上述匹配将匹配任何用户代理头与 Regex 匹配的请求。

## 重定向和重写请求

在头信息和其他请求属性上进行匹配是有用的，但有时我们可能需要通过请求 URI 中的值来匹配请求。

例如，让我们考虑这样一种情况：传入的请求使用 `/v1/api` 路径，而我们想把请求路由到 `/v2/api` 端点。

这样做的方法是重写所有传入的请求和与 `/v1/api` 匹配的 authority/host headers 到 `/v2/api`。

例如：

```yaml
...
http:
  - match:
    - uri:
        prefix: /v1/api
    rewrite:
      uri: /v2/api
    route:
      - destination:
          host: customers.default.svc.cluster.local
...
```

即使目标服务不在 `/v1/api` 端点上监听，Envoy 也会将请求重写到 `/v2/api`。

我们还可以选择将请求重定向或转发到一个完全不同的服务。下面是我们如何在头信息上进行匹配，然后将请求重定向到另一个服务：

```yaml
...
http:
  - match:
    - headers:
        my-header:
          exact: hello
    redirect:
      uri: /hello
      authority: my-service.default.svc.cluster.local:8000
...
```

`redirect` 和 `destination` 字段是相互排斥的。如果我们使用 `redirect`，就不需要设置 `destination`。

## AND 和 OR 语义

在进行匹配时，我们可以使用 AND 和 OR 两种语义。让我们看一下下面的片段：

```yaml
...
http:
  - match:
    - uri:
        prefix: /v1
      headers:
        my-header:
          exact: hello
...
```

上面的片段使用的是 AND 语义。这意味着 URI 前缀需要与 `/v1` 相匹配，并且头信息 `my-header` 有一个确切的值 `hello`。

要使用 OR 语义，我们可以添加另一个 `match` 项，像这样：

```yaml
...
http:
  - match:
    - uri:
        prefix: /v1
    ...
  - match:
    - headers:
        my-header:
          exact: hello
...
```

在上面的例子中，将首先对 URI 前缀进行匹配，如果匹配，请求将被路由到目的地。如果第一个不匹配，算法会转移到第二个，并尝试匹配头。如果我们省略路由上的匹配字段，它将总是评估为 `true`。