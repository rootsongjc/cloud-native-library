---
weight: 30
title: 异常点检测
date: '2022-05-18T00:00:00+08:00'
type: book
---

第二种类型的健康检查被称为**被动健康检查**。**异常点检测（outlier detection）** 是一种被动的健康检查形式。说它 "被动" 是因为 Envoy 没有 "主动" 发送任何请求来确定端点的健康状况。相反，Envoy 观察不同端点的性能，以确定它们是否健康。如果端点被认为是不健康的，它们就会被移除或从健康负载均衡池中弹出。

端点的性能是通过连续失败、时间成功率、延迟等来确定的。

为了使异常点检测发挥作用，我们需要过滤器来报告错误、超时和重置。目前，有四个过滤器支持异常点检测。HTTP 路由器、TCP 代理、Redis 代理和 Thrift 代理。

检测到的错误根据起源点分为两类。

**1. 来自外部的错误**

这些错误是针对事务的，发生在上游服务器上，是对收到的请求的回应。这些错误是在 Envoy 成功连接到上游主机后产生的。例如，端点响应的是 HTTP 500。

**2. 本地产生的错误**

Envoy 产生这些错误是为了应对中断或阻止与上游主机通信的事件，例如超时、TCP 重置、无法连接到指定端口等。

这些错误也取决于过滤器的类型。例如，HTTP 路由器过滤器可以检测两种错误。相反，TCP 代理过滤器不理解 TCP 层以上的任何协议，只报告本地产生的错误。

在配置中，我们可以指定是否可以区分本地和外部产生的错误（使用 `split_external_local_origin_errors` 字段）。这允许我们通过单独的计数器跟踪错误，并配置异常点检测，对本地产生的错误做出反应，而忽略外部产生的错误，反之亦然。默认模式错误将不被分割（即 `split_external_local_origin_errors` 为 false）。

## 端点弹出

当一个端点被确定为异常点时，Envoy 将检查它是否需要从健康负载均衡池中弹出。如果没有端点被弹出，Envoy 会立即弹出异常（不健康的）端点。否则，它会检查 `max_ejection_percent` 设置，确保被弹出的端点数量低于配置的阈值。如果超过 `max_ejection_percent` 的主机已经被弹出，该端点就不会被弹出了。

每个端点被弹出的时间是预先确定的。我们可以使用 `base_ejection_time` 值来配置弹出时间。这个值要乘以端点连续被弹出的次数。如果端点继续失败，它们被弹出的时间会越来越长。这里的第二个设置叫做 `max_ejection_time `。它控制端点被弹出的最长时间——也就是说，端点被弹出的最长时间在 `max_ejection_time` 值中被指定。

Envoy 在 `internal` 字段中指定的间隔时间内检查每个端点的健康状况。每检查一次端点是否健康，弹出的倍数就会被递减。经历弹出时间后，端点会自动返回到健康的负载均衡池中。

现在我们了解了异常点检测和端点弹出的基本知识，让我们看看不同的异常点检测方法。

## 检测类型

Envoy 支持以下五种异常点检测类型。

**1. 连续的 5xx**

这种检测类型考虑到了所有产生的错误。Envoy 内部将非 HTTP 过滤器产生的任何错误映射为 HTTP 5xx 代码。

当错误类型被分割时，该检测类型只计算外部产生的错误，忽略本地产生的错误。如果端点是一个 HTTP 服务器，只考虑 5xx 类型的错误。

如果一个端点返回一定数量的 5xx 错误，该端点会被弹出。`consecutive_5xx` 值控制连续 5xx 错误的数量。

```yaml
  clusters:
  - name: my_cluster_name
    outlier_detection:
      interval: 5s
      base_ejection_time: 15s
      max_ejection_time: 50s
      max_ejection_percent: 30
      consecutive_5xx: 10
      ...
```

上述异常点检测，一旦它失败 10 次，将弹出一个失败的端点。失败的端点会被弹出 15 秒（`base_ejection_time`）。在多次弹出的情况下，单个端点被弹出的最长时间是 50 秒（`max_ejection_time`）。在一个失败的端点被弹出之前，Envoy 会检查是否有超过 30% 的端点已经被弹出（`max_ejection_percent`），并决定是否弹出这个失败的端点。

**2. 连续的网关故障**

连续网关故障类型与连续 5xx 类型类似。它将 5xx 错误的一个子集，称为 "网关错误"（如 502、503 或 504 状态代码）和本地源故障，如超时、TCP 复位等。

这种检测类型考虑了分隔模式下的网关错误，并且只由 HTTP 过滤器支持。连续错误的数量可通过 `contriable_gateway_failure` 字段进行配置。

```yaml
  clusters:
  - name: my_cluster_name
    outlier_detection:
      interval: 5s
      base_ejection_time: 15s
      max_ejection_time: 50s
      max_ejection_percent: 30
      consecutive_gateway_failure: 10
      ...
```

**3. 连续的本地源失败**

这种类型只在分隔模式下启用（`split_external_local_origin_errors` 为 true），它只考虑本地产生的错误。连续失败的数量可以通过 `contriable_local_origin_failure` 字段进行配置。如果未提供，默认为 5。

```yaml
  clusters:
  - name: my_cluster_name
    outlier_detection:
      interval: 5s
      base_ejection_time: 15s
      max_ejection_time: 50s
      max_ejection_percent: 30
      consecutive_local_origin_failure: 10
      ...
```

**4. 成功率**

成功率异常点检测汇总了集群中每个端点的成功率数据。基于成功率，它将在给定的时间间隔内弹出端点。在默认模式下，所有的错误都被考虑，而在分隔模式下，外部和本地产生的错误被分别处理。

通过 `success_rate_request_volume` 值，我们可以设置最小请求量。如果请求量小于该字段中指定的请求量，将不计算该主机的成功率。同样地，我们可以使用 `success_rate_minimum_hosts` 来设置具有最小要求的请求量的端点数量。如果具有最小要求的请求量的端点数量少于 `success_rate_minimum_hosts` 中设置的值，Envoy 将不会进行异常点检测。

`success_rate_stdev_factor` 用于确定弹出阈值。弹出阈值是平均成功率和该系数与平均成功率标准差的乘积之间的差。

```
平均值 - (stdev * success_rate_stdev_factor)
```

这个系数被除以一千，得到一个双数。也就是说，如果想要的系数是 1.9，那么运行时间值应该是 1900。

**5. 故障率**

故障率异常点检测与成功率类似。不同的是，它不依赖于整个集群的平均成功率。相反，它将该值与用户在 `failure_percentage_threshold ` 字段中配置的阈值进行比较。如果某个主机的故障率大于或等于这个值，该主机就会被弹出。

可以使用 `failure_percentage_minimum_hosts` 和 `failure_percentage_request_volume` 配置最小主机和请求量。