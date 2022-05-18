---
weight: 50
title: 弹性
date: '2022-05-18T00:00:00+08:00'
type: book
---

弹性（Resiliency）是指在面对故障和对正常运行的挑战时，提供和保持可接受的服务水平的能力。这不是为了避免故障。它是以一种没有停机或数据丢失的方式来应对它们。弹性的目标是在故障发生后将服务恢复到一个完全正常的状态。

使服务可用的一个关键因素是在提出服务请求时使用超时（timeout）和重试（retry）策略。我们可以在 Istio 的 VirtualService 上配置这两者。

使用超时字段，我们可以为 HTTP 请求定义一个超时。如果请求的时间超过了超时字段中指定的值，Envoy 代理将放弃请求，并将其标记为超时（向应用程序返回一个 HTTP 408）。连接将保持开放，除非触发了异常点检测。下面是一个为路由设置超时的例子：

```yaml
...
- route:
  - destination:
      host: customers.default.svc.cluster.local
      subset: v1
  timeout: 10s
...
```

除了超时之外，我们还可以配置更细化的重试策略。我们可以控制一个给定请求的重试次数，每次尝试的超时时间，以及我们想要重试的具体条件。

例如，我们可以只在上游服务器返回任何 5xx 响应代码时重试请求，或者只在网关错误（HTTP 502、503 或 504）时重试，或者甚至在请求头中指定可重试的状态代码。重试和超时都发生在客户端。当 Envoy 重试一个失败的请求时，最初失败并导致重试的端点就不再包含在负载均衡池中了。假设 Kubernetes 服务有 3 个端点（Pod），其中一个失败了，并出现了可重试的错误代码。当 Envoy 重试请求时，它不会再向原来的端点重新发送请求。相反，它将把请求发送到两个没有失败的端点中的一个。

下面是一个例子，说明如何为一个特定的目的地设置重试策略。

```yaml
...
- route:
  - destination:
      host: customers.default.svc.cluster.local
      subset: v1
  retries:
    attempts: 10
    perTryTimeout: 2s
    retryOn: connect-failure,reset
...
```

上述重试策略将尝试重试任何连接超时（`connect-failure`）或服务器完全不响应（reset）的失败请求。我们将每次尝试的超时时间设置为 2 秒，尝试的次数设置为 10 次。注意，如果同时设置重试和超时，超时值将是请求等待的最长时间。如果我们在上面的例子中指定了 10 秒的超时，那么即使重试策略中还剩下一些尝试，我们也只能最多等待 10 秒。

关于重试策略的更多细节，请参阅 [`x-envoy-retry-on` 文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#x-envoy-retry-on)。