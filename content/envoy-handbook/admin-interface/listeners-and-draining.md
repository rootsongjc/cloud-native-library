---
weight: 60
title: 监听器和监听器的排空
date: '2022-05-18T00:00:00+08:00'
type: book
---

`/listeners` 端点列出了所有配置的监听器。这包括名称以及每个监听器的地址和监听的端口。

例如：

```sh
$ curl localhost:9901/listeners
http_8080::0.0.0.0:8080
http_hello_world_9090::0.0.0.0:9090
```

对于 JSON 输出，我们可以在 URL 上附加 `?format=json`。

```json
$ curl localhost:9901/listeners?format=json
{
 "listener_statuses": [
  {
   "name": "http_8080",
   "local_address": {
    "socket_address": {
     "address": "0.0.0.0",
     "port_value": 8080
    }
   }
  },
  {
   "name": "http_hello_world_9090",
   "local_address": {
    "socket_address": {
     "address": "0.0.0.0",
     "port_value": 9090
    }
   }
  }
 ]
}
```

## 监听器排空

发生排空（draining）的一个典型场景是在热重启排空期间。它涉及到在 Envoy 进程关闭之前，通过指示监听器停止接受传入的请求来减少打开连接的数量。

默认情况下，如果我们关闭 Envoy，所有的连接都会立即关闭。要进行优雅的关闭（即不关闭现有的连接），我们可以使用 `/drain_listeners` 端点，并加入一个可选的 `graceful` 查询参数。

Envoy 根据通过 `--drain-time-s` 和 `--drain-strategy` 指定的配置来排空连接。

如果没有提供，排空时间默认为 10 分钟（600 秒）。该值指定了 Envoy 将排空连接的时间——即在关闭它们之前等待多久。

排空策略参数决定了排空序列中的行为（例如，在热重启期间），连接是通过发送 "Connection:CLOSE"（HTTP/1.1）或 GOAWAY 帧（HTTP/2）。

有两种支持的策略：渐进（默认）和立即。当使用渐进策略时，随着排空时间的推移，排空的请求的百分比慢慢增加到 100%。即时策略将使所有的请求在排空序列开始后立即排空。

排空是按监听器进行的。然而，它必须在网络过滤器层面得到支持。目前支持优雅排空的过滤器是 Redis、Mongo 和 HTTP 连接管理器。

端点的另一个选项是使用 `inboundonly` 查询参数（例如，`/drain_listeners?inboundonly`）排空所有入站监听器的能力。这使用监听器上的 `traffic_direction` 字段来确定流量方向。