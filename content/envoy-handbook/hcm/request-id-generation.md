---
weight: 8
title: 生成请求 ID
date: '2022-05-18T00:00:00+08:00'
type: book
---

唯一的请求 ID 对于通过多个服务追踪请求、可视化请求流和精确定位延迟来源至关重要。

我们可以通过 `request_id_extension` 字段配置请求 ID 的生成方式。如果我们不提供任何配置，Envoy 会使用默认的扩展，称为 `UuidRequestIdConfig`。

默认扩展会生成一个唯一的标识符（[UUID4](https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_4_(random))）并填充到 `x-request-id `HTTP 头中。Envoy 使用 UUID 的第 14 个位点来确定跟踪的情况。

如果第 14 个比特位（nibble）被设置为 `9`，则应该进行追踪采样。如果设置为 `a`，应该是由于服务器端的覆盖（`a`）而强制追踪，如果设置为 `b`，应该是由客户端的请求 ID 加入而强制追踪。

之所以选择第 14 个位点，是因为它在设计上被固定为 `4`。因此，`4` 表示一个默认的 UUID 没有跟踪状态，例如 `7b674932-635d-4ceb-b907-12674f8c7267`（说明：第 14 比特位实际为第 13 个数字）。

我们在 `UuidRequestIdconfig` 中的两个配置选项是 `pack_trace_reason` 和 `use_request_id_for_trace_sampling`。

```yaml
...
..
  route_config:
    name: local_route
  request_id_extension:
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.request_id.uuid.v3.UuidRequestIdConfig
      pack_trace_reason: false
      use_request_id_for_trace_sampling: false
  http_filters:
  - name: envoy.filters.http.router
...
```

`pack_trace_reaseon` 是一个布尔值，控制实现是否改变 UUID 以包含上述的跟踪采样决定。默认值是 true。`use_request_id_for_trace_sampling` 设置是否使用 `x-request-id` 进行采样。默认值也是 true。