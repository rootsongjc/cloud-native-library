---
title: 警报指南
description: 设置 Tetrate Service Bridge 监控警报的通用指南。
weight: 4
---

{{<callout note 注意>}}
Tetrate Service Bridge 收集了大量的指标，而你设置的指标和阈值限制将因环境而异。本文档概述了通用的警报指南，而不是提供详尽的警报配置和阈值列表，因为这些将因不同环境和不同工作负载配置而异。
{{</callout>}}

## TSB 运维状态

### TSB 可用性

TSB API 的成功请求率。这是一个非常容易被用户看到的信号，应该作为这样对待。

根据在你的环境中捕获的历史度量数据作为基线来确定 `THRESHOLD` 值。首次迭代的合理值可能为 `0.99`。

示例 PromQL 表达式：

```
sum(
  rate(
    grpc_server_handled_total{
      component="tsb",
      grpc_code="OK",
      grpc_type="unary",
      grpc_method!="SendAuditLog"
    }[1m]
  )
) BY (grpc_method) / sum(
  rate(
    grpc_server_handled_total{
      component="tsb",
      grpc_type="unary",
      grpc_method!="SendAuditLog"
    }[1m]
  )
) BY (grpc_method) < THRESHOLD
```

### TSB 请求延迟

由于度量数据基数高，TSB gRPC API 请求延迟度量意图不会被发出。

### TSB 请求流量

对 TSB API 的请求速率。监控值主要来自于检测异常值和意外行为，例如意外高或低的请求速率。要建立合理的阈值，有历史度量数据的记录是至关重要的，以便衡量基线。

示例 PromQL 表达式：

```
sum(
  rate(
    grpc_server_handled_total{
      component="tsb",
      grpc_type="unary",
      grpc_method!="SendAuditLog"}[1m]
  )
) BY (grpc_method) < THRESHOLD
# 或 > THRESHOLD
```

### TSB 缺失指标

TSB 即使没有持续的外部负载也会与其持久性后端通信。请求的缺失可靠地指示了 TSB 指标收集存在问题，并应视为高优先级事件，因为缺少指标意味着无法查看 TSB 的状态。

示例 PromQL 表达式：

```
sum(rate(persistence_operation[10m])) == 0
```

### 持久性后端可用性

来自 TSB 的持久性后端可用性，没有内部 Postgres 操作的洞察。

TSB 将其所有状态存储在持久性后端中，因此其运营状态（可用性、延迟、吞吐量等）与持久性后端的状态密切相关。TSB 记录了可能用作警报信号的持久性后端操作的度量标准。

重要的是要注意，持久性后端操作的任何降级都必然会导致 TSB 整体降级，无论是可用性、延迟还是吞吐量。这意味着警报持久性后端状态可能是多余的，当需要关注需要注意的 Postgres 问题时，值班人员将收到两个页面而不是一个。然而，这样的信号仍然具有显著的价值，可以提供重要的上下文，以减少解决问题和解决根本原因/升级所需的时间。

{{<callout note 注意>}}
"未找到资源" 错误的处理：少量的 "未找到" 响应是正常的，因为为了优化，TSB 通常使用 `Get` 查询而不是 `Exists` 查询来确定资源是否存在。然而，大量 "未找到"（类似 404 的）响应很可能表示持久性后端设置存在问题。
{{</callout>}}

示例 PromQL 表达式：

- 查询：

```
1 - (
  sum(
    rate(
      persistence_operation{
        error!="", error!="resource not found"
      }[1m]
    )
) / sum(
    rate(persistence_operation[1m])
  ) OR on() vector(0)
) < THRESHOLD
```

- 过多的 "未找到资源" 查询：

```
( 
  sum(
    rate(persistence_operation{error="resource not found"}[1m])
  ) OR on() vector(0) / sum(
    rate(persistence_operation[1m])
  )
) > THRESHOLD # 例如 0.50
```

- 事务：

```
sum(
  rate(persistence_transaction{error=""}[1m])
) / sum(
  rate(persistence_transaction[1m])
) < THRESHOLD
```

### 持久性后端延迟

持久性后端操作的延迟，由持久性后端客户端（TSB）记录。这个延迟实际上转化为用户看到的延迟，因此是一个重要的信号。

`THRESHOLD` 值应该从历史度量数据中建立，作为基线使用。首次迭代的合理值可能是 `300ms` 的第 99 百分位延迟。

示例 PromQL 表达式：

- 查询：

```
histogram_quantile(
  0.99,
  sum(rate(persistence_operation_duration_bucket[1m])) by (le, method)
) > THRESHOLD
```

- 事务：

```
histogram_quantile(
  0.99,
  sum(rate(persistence_transaction_duration_bucket[1m])) by (le)
) > THRESHOLD
```

## XCP 运维状态

### 最后一次管理平面同步

XCP Edge 最后一次与管理平面（XCP 中央）同步的最长时间间隔，对于每个已注册的集群。这表示从管理平面接收的配置在给定集群中的陈旧程度。首次迭代的合理阈值为 `30`（秒）。

示例 PromQL 表达式：

```
time() - min(
  xcp_central_last_config_propagation_event_timestamp_ms{edge!=""} / 1000
) by (edge, status) > THRESHOLD
```

### XCP Edge 饱和度

TSB 控制平面组件主要受限于 CPU。因此，CPU 利用率作为重要信号应该进行警报。在选择警报 `THRESHOLD` 时，请记住不仅云提供商 tend to tend to 超额提供 CPU，而且即使在 <~80% CPU 利用率下，超线程也可能对 Linux 调度器效率产生负面影响，导致延迟/错误增加。