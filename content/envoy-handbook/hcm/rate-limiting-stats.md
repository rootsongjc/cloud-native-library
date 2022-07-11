---
weight: 12
title: 速率限制的统计
date: '2022-05-18T00:00:00+08:00'
type: book
---

无论是使用全局还是局部的速率限制，Envoy 都会发出下表中描述的指标。我们可以在配置过滤器时使用 `stat_prefix` 字段来设置统计信息的前缀。

当使用局部速率限制器时，每个度量名称的前缀是 `<stat_prefix>.http_local_rate_limit.<metric_name>`，当使用全局速率限制器时，前缀是 `cluster.<route_target_cluster>.ratelimit.<metric_name>`。

| 速率限制器  | 指标名称               | 描述                                                      |
| ----------- | ---------------------- | --------------------------------------------------------- |
| 局部        | `enabled`              | 速率限制器被调用的请求总数                                |
| 局部 / 全局 | `ok`                   | 来自令牌桶的低于限制的响应总数                            |
| 局部        | `rate_limited`         | 没有可用令牌的答复总数（但不一定强制执行）                |
| 局部        | `enforced`             | 有速率限制的请求总数（例如，返回 HTTP 429）。             |
| 全局        | `over_limit`           | 速率限制服务的超限答复总数                                |
| 全局        | `error`                | 与速率限制服务联系的错误总数                              |
| 全局        | `failure_mode_allowed` | 属于错误但由于 `failure_mode_deny` 设置而被允许的请求总数 |