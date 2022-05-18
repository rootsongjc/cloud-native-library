---
weight: 20
title: 主动健康检查
date: '2022-05-18T00:00:00+08:00'
type: book
---

Envoy 支持端点上不同的主动健康检查方法。HTTP、TCP、gRPC 和 Redis 健康检查。健康检查方法可以为每个集群单独配置。我们可以通过集群配置中的 `health_checks` 字段来配置健康检查。

无论选择哪种健康检查方法，都需要定义几个常见的配置设置。

**超时**（`timeout`）表示分配给等待健康检查响应的时间。如果在这个字段中指定的时间值内没有达到响应，健康检查尝试将被视为失败。**间隔**（`internal`）指定健康检查之间的时间节奏。例如，5 秒的间隔将每 5 秒触发一次健康检查。

其他两个必要的设置可用于确定一个特定的端点何时被认为是健康或不健康的。`healthy_threshold` 指定在一个端点被标记为健康之前所需的 "健康" 检查（例如，HTTP 200 响应）的数量。`unhealthy_threshold` 的作用与此相同，但是对于 "不健康" 的健康检查，它指定了在一个端点被标记为不健康之前所需的不健康检查的数量。

**1. HTTP 健康检查**

Envoy 向端点发送一个 HTTP 请求。如果端点回应的是 HTTP 200，Envoy 认为它是健康的。200 响应是默认的响应，被认为是健康响应。使用 `expected_statuses` 字段，我们可以通过提供一个被认为是健康的 HTTP 状态的范围来进行自定义。

如果端点以 HTTP 503 响应，`unhealthy_threshold` 被忽略，并且端点立即被认为是不健康的。

```yaml
  clusters:
  - name: my_cluster_name
    health_checks:
      - timeout: 1s
        interval: 0.25s
        unhealthy_threshold: 5
        healthy_threshold: 2
        http_health_check:
          path: "/health"
          expected_statuses:
            - start: 200
              end: 299
      ...
```

例如，上面的片段定义了一个 HTTP 健康检查，Envoy 将向集群中的端点发送一个 `/health` 路径的 HTTP 请求。Envoy 每隔 0.25s（`internal`）发送一次请求，在超时前等待 1s（`timeout`）。要被认为是健康的，端点必须以 200 和 299 之间的状态（`expected_statuses`）响应两次（`healthy_threshold`）。端点需要以任何其他状态代码响应五次（`unhealthy_threshold`）才能被认为是不健康的。此外，如果端点以 HTTP 503 响应，它将立即被视为不健康（`unhealthy_threshold` 设置被忽略）。

**2. TCP 健康检查**

我们指定一个 Hex 编码的有效载荷（例如：`68656C6C6F`），并将其发送给终端。如果我们设置了一个空的有效载荷，Envoy 将进行仅连接的健康检查，它只尝试连接到端点，如果连接成功就认为是成功的。

除了被发送的有效载荷外，我们还需要指定响应。Envoy 将对响应进行模糊匹配，如果响应与请求匹配，则认为该端点是健康的。

```yaml
  clusters:
  - name: my_cluster_name
    health_checks:
      - timeout: 1s
        interval: 0.25s
        unhealthy_threshold: 1
        healthy_threshold: 1
        tcp_health_check:
          send:
            text: "68656C6C6F"
          receive:
            - text: "68656C6C6F"
      ...
```

**3. gRPC 健康检查**

本健康检查遵循 [grpc.health.v1.Health](https://github.com/grpc/grpc/blob/master/src/proto/grpc/health/v1/health.proto) 健康检查协议。查看 [GRPC 健康检查协议文档](https://github.com/grpc/grpc/blob/master/doc/health-checking.md)以了解更多关于其工作方式的信息。

我们可以设置的两个可选的配置值是 `service_name` 和 `authority`。服务名称是设置在 grpc.health.v1.Health 的 HealthCheckRequest 的 `service` 字段中的值。授权是 `:authority` 头的值。如果它是空的，Envoy 会使用集群的名称。

```yaml
  clusters:
  - name: my_cluster_name
    health_checks:
      - timeout: 1s
        interval: 0.25s
        unhealthy_threshold: 1
        healthy_threshold: 1
        grpc_health_check: {}
      ...
```

**4. Redis 健康检查**

Redis 健康检查向端点发送一个 Redis PING 命令，并期待一个 PONG 响应。如果上游的 Redis 端点回应的不是 PONG，就会立即导致健康检查失败。我们也可以指定一个 `key`，Envoy 会执行  `EXIST <key>` 命令，而不是 PING 命令。如果 Redis 的返回值是 0（即密钥不存在），那么该端点就是健康的。任何其他响应都被视为失败。

```yaml
  clusters:
  - name: my_cluster_name
    health_checks:
      - timeout: 1s
        interval: 0.25s
        unhealthy_threshold: 1
        healthy_threshold: 1
        redis_health_check:
          key: "maintenance"
      ...
```

上面的例子检查键 "维护"（如 `EXIST maintainance`），如果键不存在，健康检查就通过。

## HTTP 健康检查过滤器

 HTTP 健康检查过滤器可以用来限制产生的健康检查流量。过滤器可以在不同的操作模式下运行，控制流量是否被传递给本地服务（即不传递或传递）。

**1. 非穿透模式**

当以非穿透模式运行时，健康检查请求永远不会被发送到本地服务。Envoy 会以 HTTP 200 或 HTTP 503 进行响应，这取决于服务器当前的耗尽状态。

非穿透模式的一个变种是，如果上游集群中至少有指定比例的端点可用，则返回 HTTP 200。端点的百分比可以用 `cluster_min_healthy_percentages` 字段来配置。

```yaml
...
  pass_through_mode: false
  cluster_min_healthy_percentages:
    value: 15
...
```

**2. 穿透模式**

在穿透模式下，Envoy 将每个健康检查请求传递给本地服务。该服务可以用 HTTP 200 或 HTTP 503 来响应。

穿透模式的另一个设置是使用缓存。Envoy 将健康检查请求传递给服务，并将结果缓存一段时间（`cache_time`）。任何后续的健康检查请求将使用缓存起来的值。一旦缓存失效，下一个健康检查请求会再次传递给服务。

```yaml
...
  pass_through_mode: true
  cache_time: 5m
...
```

上面的片段启用了穿透模式，缓存在 5 分钟内到期。