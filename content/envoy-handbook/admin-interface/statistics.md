---
weight: 30
title: 统计
date: '2022-05-18T00:00:00+08:00'
type: book
---

管理接口的统计输出的主要端点是通过 `/stats` 端点访问的。这个输入通常是用来调试的。我们可以通过向 `/stats` 端点发送请求或从管理接口访问同一路径来访问该端点。

该端点支持使用 `filter` 查询参数和正则表达式来过滤返回的统计资料。

另一个过滤输出的维度是使用 `usedonly` 查询参数。当使用时，它将只输出 Envoy 更新过的统计数据。例如，至少增加过一次的计数器，至少改变过一次的仪表，以及至少增加过一次的直方图。

默认情况下，统计信息是以 StatsD 格式写入的。每条统计信息都写在单独的一行中，统计信息的名称（例如，`cluster_manager.active_clusters`）后面是统计信息的值（例如，`15`）。

例如：

```
...
cluster_manager.active_clusters。15
cluster_manager.cluster_added: 3
cluster_manager.cluster_modified:4
...
```

`format` 查询参数控制输出格式。设置为 `json` 将以 JSON 格式输出统计信息。如果我们想以编程方式访问和解析统计信息，通常会使用这种格式。

第二种格式是 Prometheus 格式（例如， `format=prometheus`）。这个选项以 Prometheus 格式格式化状态，可以用来与 Prometheus 服务器集成。另外，我们也可以使用 `/stats/prometheus` 端点来获得同样的输出。

## 内存

`/memory` 端点将输出当前内存分配和堆的使用情况，单位为字节。下面是 `/stats` 端点打印出来的信息的一个子集。

```sh
$ curl localhost:9901/memory
{
 "allocated": "5845672",
 "heap_size": "10485760",
 "pageheap_unmapped": "0",
 "pageheap_free": "3186688",
 "total_thread_cache": "80064",
 "total_physical_bytes": "12699350"
}
```

## 重置计数器

向  `/reset_counters  `发送一个 POST 请求，将所有计数器重置为零。注意，这不会重置或放弃任何发送到 statsd 的数据。它只影响到 `/stats ` 端点的输出。在调试过程中可以使用 `/stats` 端点和 `/reset_counters ` 端点。

## 服务器信息和状态

`/server_info` 端点输出运行中的 Envoy 服务器的信息。这包括版本、状态、配置路径、日志级别信息、正常运行时间、节点信息等。

该 [admin.v3.ServerInfo](https://www.envoyproxy.io/docs/envoy/latest/api-v3/admin/v3/server_info.proto#envoy-v3-api-msg-admin-v3-serverinfo) proto 解释了由端点返回的不同字段。

`/ready` 端点返回一个字符串和一个错误代码，反映 Envoy 的状态。如果 Envoy 是活的，并准备好接受连接，那么它返回 HTTP 200 和字符串 `LIVE`。否则，输出将是一个 HTTP 503。这个端点可以作为准备就绪检查。

`/runtime` 端点以 JSON 格式输出所有运行时值。输出包括活动的运行时覆盖层列表和每个键的层值堆栈。这些值也可以通过向 `/runtime_modify` 端点发送 POST 请求并指定键 / 值对来修改。例如，`POST /runtime_modify?my_key_1=somevalue`。

`/hot_restart_version` 端点，加上 `--hot-restart-version ` 标志，可以用来确定新的二进制文件和运行中的二进制文件是否热重启兼容。

**热重启**是指 Envoy 能够 "热" 或 " 实时 " 重启自己。这意味着 Envoy 可以完全重新加载自己（和配置）而不放弃任何现有的连接。

## Hystrix 事件流

`/hystrix_event_stream` 端点的目的是作为流源用于 [Hystrix 仪表盘](https://github.com/Netflix-Skunkworks/hystrix-dashboard/wiki)。向该端点发送请求将触发来自 Envoy 的统计流，其格式是 Hystrix 仪表盘所期望的。

注意，我们必须在引导配置中配置 Hystrix 统计同步，以使端点工作。

例如：

```yaml
stats_sinks: 
  - name: envoy.stat_sinks.hystrix
    typed_config:
      "@type": type.googleapis.com/envoy.config.metrics.v3.HystrixSink
      num_buckets: 10
```

## 争用

如果启用了互斥追踪功能，`/contention` 端点会转储当前 Envoy 互斥内容的统计信息。

## CPU 和堆分析器

我们可以使用 `/cpuprofiler` 和 `/heapprofiler` 端点来启用或禁用 CPU / 堆分析器。注意，这需要用 gperftools 编译 Envoy。Envoy 的 GitHub 资源库有[文档](https://github.com/envoyproxy/envoy/blob/main/bazel/PPROF.md)说明。