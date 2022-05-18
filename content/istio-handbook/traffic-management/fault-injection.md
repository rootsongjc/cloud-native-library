---
weight: 60
title: 错误注入
date: '2022-05-18T00:00:00+08:00'
type: book
---

为了帮助我们提高服务的弹性，我们可以使用故障注入功能。我们可以在 HTTP 流量上应用故障注入策略，在转发目的地的请求时指定一个或多个故障注入。

有两种类型的故障注入。我们可以在转发前延迟（delay）请求，模拟缓慢的网络或过载的服务，我们可以中止（abort） HTTP 请求，并返回一个特定的 HTTP 错误代码给调用者。通过中止，我们可以模拟一个有故障的上游服务。

下面是一个中止 HTTP 请求并返回 HTTP 404 的例子，针对 30% 的传入请求。

```yaml
- route:
  - destination:
      host: customers.default.svc.cluster.local
      subset: v1
  fault:
    abort:
      percentage:
        value: 30
      httpStatus: 404
```

如果我们不指定百分比，所有的请求将被中止。请注意，故障注入会影响使用该 VirtualService 的服务。它并不影响该服务的所有消费者。

同样地，我们可以使用 `fixedDelay` 字段对请求应用一个可选的延迟。

```yaml
- route:
  - destination:
      host: customers.default.svc.cluster.local
      subset: v1
  fault:
    delay:
      percentage:
        value: 5
      fixedDelay: 3s
```

上述设置将对 5% 的传入请求应用 3 秒的延迟。

注意，故障注入将不会触发我们在路由上设置的任何重试策略。例如，如果我们注入了一个 HTTP 500 的错误，配置为在 HTTP 500 上的重试策略将**不会**被触发。
