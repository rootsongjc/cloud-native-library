---
weight: 10
title: 重试
date: '2022-05-18T00:00:00+08:00'
type: book
---

我们可以在虚拟主机和路由层面定义重试策略。在虚拟主机级别设置的重试策略将适用于该虚拟主机的所有路由。如果在路由级别上定义了重试策略，它将优先于虚拟主机策略，并被单独处理——即路由级别的重试策略不会继承虚拟主机级别的重试策略的值。即使 Envoy 将重试策略独立处理，配置也是一样的。

除了在配置中设置重试策略外，我们还可以通过请求头（即 `x-envoy-retry-on`  头）进行配置。

在 Envoy 配置中，我们可以配置以下内容。

1. 最大重试次数：Envoy 将重试请求，重试次数最多为配置的最大值。指数退避算法是用于确定重试间隔的默认算法。另一种确定重试间隔的方法是通过 Header（例如 `x-envoy-upstream-rq-per-try-timeout-ms`）。所有重试也包含在整个请求超时中，即 `request_timeout` 配置设置。默认情况下，Envoy 将重试次数设置为一次。
2. 重试条件：我们可以根据不同的条件重试请求。例如，我们只能重试 5xx 响应代码，网关失败，4xx 响应代码，等等。
3. 重试预算：重试预算规定了与活动请求数有关的并发请求的限制。这可以帮助防止过大的重试流量。
4. 主机选择重试插件：重试期间的主机选择通常遵循与原始请求相同的过程。使用重试插件，我们可以改变这种行为，指定一个主机或优先级谓词，拒绝一个特定的主机，并导致重新尝试选择主机。

让我们看看几个关于如何定义重试策略的配置例子。我们使用 httpbin 并匹配返回 500 响应代码的 `/status/500` 路径。

```yaml
  route_config:
    name: 5xx_route
    virtual_hosts:
    - name: httpbin
      domains: ["*"]
      routes:
      - match:
          path: /status/500
        route:
          cluster: httpbin
          retry_policy:
            retry_on: "5xx"
            num_retries: 5
```

在 `retry_policy` 字段中，我们将重试条件（`retry_on`）设置为 `500` ，这意味着我们只想在上游返回 HTTP 500 的情况下重试（将会如此）。Envoy 将重试该请求五次。这可以通过 `num_retries` 字段进行配置。

如果我们运行 Envoy 并发送一个请求，该请求将失败（HTTP 500），并将创建以下日志条目：

```
[2021-07-26T18:43:29.515Z] "GET /status/500 HTTP/1.1" 500 URX 0 0 269 269 "-" "curl/7.64.0" "1ae9ffe2-21f2-43f7-ab80-79be4a95d6d4" "localhost:10000" "127.0.0.1:5000"
```

注意到 `500URX` 部分告诉我们，上游响应为 500，`URX` 响应标志意味着 Envoy 拒绝了该请求，因为达到了上游重试限制。

重试条件可以设置为一个或多个值，用逗号分隔，如下表所示。

| 重试条件（`retry_on）`   | 描述                                                         |
| ------------------------ | ------------------------------------------------------------ |
| `5xx`                    | 在 `5xx` 响应代码或上游不响应时重试（包括 `connect-failure` 和 `refused-stream）`。 |
| `gatewayerror`           | 对 `502`、 `503`  或响应 `504`  代码进行重试。               |
| `reset`                  | 如果上游根本没有回应，则重试。                               |
| `connect-failure`        | 如果由于与上游服务器的连接失败（例如，连接超时）而导致请求失败，则重试。 |
| `envoy-ratelimited`      | 如果存在 `x-envoy-ratelimited` 头，则重试。                  |
| `retriable-4xx`          | 如果上游响应的是可收回的 `4xx` 响应代码（目前只有 HTTP `409`），则重试。 |
| `refused-stream`         | 如果上游以 `REFUSED_STREAM` 错误代码重置流，则重试。         |
| `retriable-status-codes` | 如果上游响应的任何响应代码与 `x-envoy-retriable-status-codes` 头中定义的代码相匹配（例如，以逗号分隔的整数列表，例如 `"502,409"`），则重试。 |
| `retriable-header`       | 如果上游响应包括任何在 `x-envoy-retriable-header-names` 头中匹配的头信息，则重试。 |

除了控制 Envoy 重试请求的响应外，我们还可以配置重试时的主机选择逻辑。我们可以指定 Envoy 在选择重试的主机时使用的 `retry_host_predicate`。

我们可以跟踪之前尝试过的主机（`envoy.retry_host_predicates.previous_host`），如果它们已经被尝试过，就拒绝它们。或者，我们可以使用 `envoy.retry_host_predicates.canary_hosts ` 拒绝任何标记为 canary 的主机（例如，任何标记为 `canary: true 的`主机）。

例如，这里是如何配置 `previous_hosts` 插件，以拒绝任何以前尝试过的主机，并重试最多 5 次的主机选择。

```yaml
  route_config:
    name: 5xx_route
    virtual_hosts:
    - name: httpbin
      domains: ["*"]
      routes:
      - match:
          path: /status/500
        route:
          cluster: httpbin
          retry_policy:
            retry_host_predicate:
            - name: envoy.retry_host_predicates.previous_hosts
            host_selection_retry_max_attempts: 5
```

在集群中定义了多个端点，我们会看到每次重试都会发送到不同的主机上。

## 请求对冲

请求对冲背后的想法是同时向不同的主机发送多个请求，并使用首先响应的上游的结果。请注意，我们通常为幂等的请求配置这个功能，在这种情况下，多次进行相同的调用具有相同的效果。

我们可以通过指定一个对冲策略来配置请求的对冲。目前，Envoy 只在响应请求超时的情况下进行对冲。因此，当一个初始请求超时时，会发出一个重试请求，而不取消原来超时的请求。Envoy 将根据重试策略向下游返回第一个良好的响应。

可以通过设置 `hedge_on_per_try_timeout` 字段为 `true` 来配置对冲。就像重试策略一样，它可以在虚拟主机或路由级别上启用。

```yaml
  route_config:
    name: 5xx_route
    virtual_hosts:
    - name: httpbin
      domains: ["*"]
      hedge_policy:
        hedge_on_per_try_timeout: true
      routes:
      - match:
      ...
```

# 