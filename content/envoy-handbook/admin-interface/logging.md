---
weight: 40
title: 日志
date: '2022-05-18T00:00:00+08:00'
type: book
---

`/logging` 端点启用或禁用特定组件或所有记录器的不同日志级别。

要列出所有的记录器，我们可以向 `/logging` 端点发送一个 POST 请求。

```sh
$ curl -X POST localhost:9901/logging
active loggers:
  admin: info
  alternate_protocols_cache: info
  aws: info
  assert: info
  backtrace: info
  cache_filter: info
  client: info
  config: info
...
```

输出将包含记录器的名称和每个记录器的日志级别。要改变所有活动日志记录器的日志级别，我们可以使用 `level` 参数。例如，我们可以运行下面的程序，将所有日志记录器的日志记录级别改为 `debug`。

```sh
$ curl -X POST localhost:9901/logging?level=debug
active loggers:
  admin: debug
  alternate_protocols_cache: debug
  aws: debug
  assert: debug
  backtrace: debug
  cache_filter: debug
  client: debug
  config: debug
...
```

要改变某个日志记录器的级别，我们可以用日志记录器的名称替换 `level` 查询参数名称。例如，要将 `admin` 日志记录器级别改为 `warning`，我们可以运行以下程序。

```sh
$ curl -X POST localhost:9901/logging?admin=warning
active loggers:
  admin: warning
  alternate_protocols_cache: info
  aws: info
  assert: info
  backtrace: info
  cache_filter: info
  client: info
  config: info
```

为了触发所有访问日志的重新开放，我们可以向 `/reopen_logs` 端点发送一个 POST 请求。