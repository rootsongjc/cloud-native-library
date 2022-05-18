---
weight: 50
title: 集群
date: '2022-05-18T00:00:00+08:00'
type: book
---

集群端点（`/clusters`）将显示配置的集群列表，并包括以下信息：

- 每个主机的统计数据
- 每个主机的健康状态
- 断路器设置
- 每个主机的权重和位置信息

> 这里的主机指的是每个被发现的属于上游集群的主机。

下面的片段显示了信息的模样（注意，输出是经过裁剪的）。

```json
{
 "cluster_statuses": [
  {
   "name": "api_google_com",
   "host_statuses": [
    {
     "address": {
      "socket_address": {
       "address": "10.0.0.1",
       "port_value": 8080
      }
     },
     "stats": [
      {
       "value": "23",
       "name": "cx_total"
      },
      {
       "name": "rq_error"
      },
      {
       "value": "51",
       "name": "rq_success"
      },
      ...
     ],
     "health_status": {
      "eds_health_status": "HEALTHY"
     },
     "weight": 1,
     "locality": {}
    }
   ],
   "circuit_breakers": {
    "thresholds": [
     {
      "max_connections": 1024,
      "max_pending_requests": 1024,
      "max_requests": 1024,
      "max_retries": 3
     },
     {
      "priority": "HIGH",
      "max_connections": 1024,
      "max_pending_requests": 1024,
      "max_requests": 1024,
      "max_retries": 3
     }
    ]
   },
   "observability_name": "api_google_com"
  },
  ...
```

> 为了获得 JSON 输出，我们可以在发出请求或在浏览器中打开 URL 时附加 `?format=json`。

## 主机统计

输出包括每个主机的统计数据，如下表所解释。

| 指标名称          | 描述                    |
| ----------------- | ----------------------- |
| `cx_total`        | 连接总数                |
| `cx_active`       | 有效连接总数            |
| `cx_connect_fail` | 连接失败总数            |
| `rq_total`        | 请求总数                |
| `rq_timeout`      | 超时的请求总数          |
| `rq_success`      | 有非 5xx 响应的请求总数 |
| `rq_error`        | 有 5xx 响应的请求总数   |
| `rq_active`       | 有效请求总数            |

## 主机健康状况

主机的健康状况在 `health_status` 字段下报告。健康状态中的值取决于健康检查是否被启用。假设启用了主动和被动（断路器）健康检查，该表显示了可能包含在 `health_status` 字段中的布尔字段。

| 字段名称                         | 描述                                                         |
| -------------------------------- | ------------------------------------------------------------ |
| `failed_active_health_check`     | 真，如果该主机目前未能通过主动健康检查。                     |
| `failed_outlier_check`           | 真，如果该宿主目前被认为是一个异常，并已被弹出。             |
| `failed_active_degraded_check`   | 如果主机目前通过主动健康检查被标记为降级，则为真。           |
| `pending_dynamic_removal`        | 如果主机已经从服务发现中移除，但由于主动健康检查正在稳定，则为真。 |
| `pending_active_hc`              | 真，如果该主机尚未被健康检查。                               |
| `excluded_via_immediate_hc_fail` | 真，如果该主机应被排除在恐慌、溢出等计算之外，因为它被明确地通过协议信号从轮换中取出，并且不打算被路由到。 |
| `active_hc_timeout`              | 真，如果主机由于超时而导致活动健康检查失败。                 |
| `eds_health_status`              | 默认情况下，设置为`healthy`（如果不使用 EDS）。否则，它也可以被设置为`unhealthy` 或 `degraded`。 |

请注意，表中的字段只有在设置为真时才会被报告。例如，如果主机是健康的，那么健康状态将看起来像这样。

```json
"Health_status":{
    "eds_health_status":"HEALTHY"
}
```

如果配置了主动健康检查，而主机是失败的，那么状态将看起来像这样。

```json
"Health_status":{
    "failed_active_health_check": true,
    "eds_health_status":"HEALTHY"
}
```

# 