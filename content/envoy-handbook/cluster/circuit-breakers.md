---
weight: 40
title: 断路器
date: '2022-05-18T00:00:00+08:00'
type: book
---

断路是一种重要的模式，可以帮助服务的弹性。断路模式通过控制和管理对故障服务的访问来防止额外的故障。它允许我们快速失败，并尽快向下游反馈。

让我们看一个定义断路的片段。

```yaml
...
  clusters:
  - name: my_cluster_name
  ...
    circuit_breakers:
      thresholds:
        - priority: DEFAULT
          max_connections: 1000
        - priority: HIGH
          max_requests: 2000
...
```

我们可以为每条路由的优先级分别配置断路器的阈值。例如，较高优先级的路由应该有比默认优先级更高的阈值。如果超过了任何阈值，断路器就会断开，下游主机就会收到 HTTP 503 响应。

我们可以用多种选项来配置断路器。

**1. 最大连接数（`max_connections`）**

指定 Envoy 与集群中所有端点的最大连接数。如果超过这个数字，断路器会断开，并增加集群的 `upstream_cx_overflow` 指标。默认值是 1024。

**2. 最大的排队请求（`max_pending_requests）`**

指定在等待就绪的连接池连接时被排队的最大请求数。当超过该阈值时，Envoy 会增加集群的 `upstream_rq_pending_overflow` 统计。默认值是 1024。

**3. 最大请求（`max_requests`）**

指定 Envoy 向集群中所有端点发出的最大并行请求数。默认值是 1024。

**4. 最大重试（`max_retries）`**

指定 Envoy 允许给集群中所有终端的最大并行重试次数。默认值是 3，如果这个断路器溢出，`upstream_rq_retry_overflow` 计数器就会递增。

另外，我们可以将断路器与重试预算（`retry_budget`）相结合。通过指定重试预算，我们可以将并发重试限制在活动请求的数量上。