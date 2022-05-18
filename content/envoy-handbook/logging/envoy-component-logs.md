---
weight: 40
title: Envoy 组件日志
date: '2022-05-18T00:00:00+08:00'
type: book
---

到目前为止，我们已经谈到了向 Envoy 发送请求时产生的日志。然而，Envoy 也会在启动时和执行过程中产生日志。

我们可以在每次运行 Envoy 时看到 Envoy 组件的日志。

```
...
[2021-11-03 17:22:43.361][1678][info][main] [source/server/server.cc:368] initializing epoch 0 (base id=0, hot restart version=11.104)
[2021-11-03 17:22:43.361][1678][info][main] [source/server/server.cc:370] statically linked extensions:
[2021-11-03 17:22:43.361][1678][info][main] [source/server/server.cc:372]   envoy.filters.network: envoy.client_ssl_auth, envoy.echo, envoy.ext_authz, envoy.filters.network.client_ssl_auth
...
```

组件日志的默认格式字符串是 `[%Y-%m-%d %T.%e][%t][%l][%n] [%g:%#] %v`。格式字符串的第一部分代表日期和时间，然后是线程 ID（`%t`）、消息的日志级别（`%l`）、记录器名称（`%n`）、源文件的相对路径和行号（`%g:%#`），以及实际的日志消息（`%v`）。

在启动 Envoy 时，我们可以使用 `--log-format` 命令行选项来定制格式。例如，如果我们想记录时间记录器名称、源函数名称和日志信息，那么我们可以这样写格式字符串：`[%T.%e][%n][%！] %v`。

然后，在启动 Envoy 时，我们可以设置格式字符串，如下所示。

```sh
func-e run -c someconfig.yaml --log-format '[%T.%e][%n][%!] %v'
```

如果我们使用格式字符串，日志条目看起来像这样：

```
[17:43:15.963][main][initialize]   response trailer map: 160 bytes: grpc-message,grpc-status
[17:43:15.965][main][createRuntime] runtime: {}
[17:43:15.965][main][initialize] No admin address given, so no admin HTTP server started.
[17:43:15.966][config][initializeTracers] loading tracing configuration
[17:43:15.966][config][initialize] loading 0 static secret(s)
[17:43:15.966][config][initialize] loading 0 cluster(s)
[17:43:15.966][config][initialize] loading 1 listener(s)
[17:43:15.969][config][initializeStatsConfig] loading stats configuration
[17:43:15.969][runtime][onRtdsReady] RTDS has finished initialization
[17:43:15.969][upstream][maybeFinishInitialize] cm init: all clusters initialized
[17:43:15.969][main][onRuntimeReady] there is no configured limit to the number of allowed active connections. Set a limit via the runtime key overload.global_downstream_max_connections
[17:43:15.970][main][operator()] all clusters initialized. initializing init manager
[17:43:15.970][config][startWorkers] all dependencies initialized. starting workers
[17:43:15.971][main][run] starting main dispatch loop
```

Envoy 具有多个日志记录器，对于每个日志记录器（例如 `main`、`config`、`http...`），我们可以控制日志记录级别（`info`、`debug`、`trace`）。如果我们启用 Envoy 管理界面并向 `/logging` 路径发送请求，就可以查看所有活动的日志记录器的名称。另一种查看所有可用日志的方法是通过[源码](https://github.com/envoyproxy/envoy/blob/82261f5a401418df13626ca3fa52fa65fea10c81//source/common/common/logger.h)。

下面是 `/logging` 终端的默认输出的样子。

```
active loggers:
  admin: info
  alternate_protocols_cache: info
  aws: info
  assert: info
  backtrace: info
  cache_filter: info
  client: info
  config: info
  connection: info
  conn_handler: info
  decompression: info
  dns: info
  dubbo: info
  envoy_bug: info
  ext_authz: info
  rocketmq: info
  file: info
  filter: info
  forward_proxy: info
  grpc: info
  hc: info
  health_checker: info
  http: info
  http2: info
  hystrix: info
  init: info
  io: info
  jwt: info
  kafka: info
  key_value_store: info
  lua: info
  main: info
  matcher: info
  misc: info
  mongo: info
  quic: info
  quic_stream: info
  pool: info
  rbac: info
  redis: info
  router: info
  runtime: info
  stats: info
  secret: info
  tap: info
  testing: info
  thrift: info
  tracing: info
  upstream: info
  udp: info
  wasm: info
```

请注意，每个日志记录器的默认日志级别都被设置为 `info`。其他的日志级别有以下几种:

- trace
- debug
- info
- warning/warn
- error
- critical
- off

为了配置日志级别，我们可以使用 `--log-level` 选项或 `--component-log-level` 来分别控制每个组件的日志级别。组件的日志级别可以用 `log_name:log_level` 格式来写。如果我们要为多个组件设置日志级别，那么就用逗号来分隔它们。例如：`upstream:critical,secret:error,router:trace`。

例如，要将 `main` 日志级别设置为 `trace`，`config` 日志级别设置为 `error`，并关闭所有其他日志记录器，我们可以键入以下内容。

```sh
func-e run -c someconfig.yaml --log-level off --component-log-level main:trace, config:error
```

默认情况下，所有 Envoy 应用程序的日志都写到标准错误（stderr）。要改变这一点，我们可以使用 `--log-path` 选项提供一个输出文件。

```sh
func-e run -c someconfig.yaml --log-path app-logs.log
```

在其中一个试验中，我们还将展示如何配置 Envoy，以便将应用日志写入谷歌云操作套件（以前称为 Stackdriver）。