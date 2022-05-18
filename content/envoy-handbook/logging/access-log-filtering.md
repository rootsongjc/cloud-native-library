---
weight: 30
title: 访问日志过滤
date: '2022-05-18T00:00:00+08:00'
type: book
---

Envoy 中访问日志的另一个特点是可以指定过滤器，决定是否需要写入访问日志。例如，我们可以有一个访问日志过滤器，只记录 500 状态代码，只记录超过 5 秒的请求，等等。下表显示了支持的访问日志过滤器。

| 访问日志过滤器名称        | 描述                                                         |
| ------------------------- | ------------------------------------------------------------ |
| `status_code_filter`      | 对状态代码值进行过滤。                                       |
| `duration_filter`         | 对总的请求持续时间进行过滤，单位为毫秒。                     |
| `not_health_check_filter` | 对非健康检查请求的过滤。                                     |
| `traceable_filter`        | 对可追踪的请求进行过滤。                                     |
| `runtime_filter`          | 对请求进行随机抽样的过滤器。                                 |
| `and_filter`              | 对过滤器列表中每个过滤器的结果进行逻辑 "和" 运算。过滤器是按顺序进行评估的。 |
| `or_filter`               | 对过滤器列表中每个过滤器的结果进行逻辑 "或" 运算。过滤器是按顺序进行评估的。 |
| `header_filter`           | 根据请求头的存在或值来过滤请求。                             |
| `response_flag_filter`    | 过滤那些收到设置了 Envoy 响应标志的响应的请求。              |
| `grpc_status_filter`      | 根据响应状态过滤 gRPC 请求。                                 |
| `extension_filter`        | 使用一个在运行时静态注册的扩展过滤器。                       |
| `metadata_filter`         | 基于匹配的动态元数据的过滤器。                               |

每个过滤器都有不同的属性，我们可以选择设置。这里有一个片段，显示了如何使用状态代码、Header 和一个 `and` 过滤器。

```yaml
...
access_log:
- name: envoy.access_loggers.stdout
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
  filter:
    and_filter:
      filters:
        header_filter:
          header:
            name: ":method"
            string_match:
              exact: "GET"
        status_code_filter:
          comparison:
            op: GE
            value:
              default_value: 400
...
```

上面的片段为所有响应代码大于或等于 400 的 GET 请求写了一条日志条目到标准输出。