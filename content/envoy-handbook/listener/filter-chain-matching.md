---
weight: 20
title: Header 操作
date: '2022-05-18T00:00:00+08:00'
type: book
---

过滤器链匹配允许我们指定为监听器选择特定过滤器链的标准。

我们可以在配置中定义多个过滤器链，然后根据目标端口、服务器名称、协议和其他属性来选择和执行它们。例如，我们可以检查哪个主机名正在连接，然后选择不同的过滤器链。如果主机名 `hello.com` 连接，我们可以选择一个过滤器链来呈现该特定主机名的证书。

在 Envoy 开始过滤器匹配之前，它需要有一些由监听器过滤器从接收的数据包中提取的数据。之后，Envoy 要选择一个特定的过滤器链，必须满足所有的匹配条件。例如，如果我们对主机名和端口进行匹配，这两个值都需要匹配，Envoy 才能选择该过滤器链。

匹配顺序如下：

1. 目的地端口（当使用 `use_original_dst` 时）
2. 目的地 IP 地址
3. 服务器名称（TLS 协议的 SNI）
4. 传输协议
5. 应用协议（TLS 协议的 ALPN）
6. 直接连接的源 IP 地址（这只在我们使用覆盖源地址的过滤器时与源 IP 地址不同，例如，代理协议监听器过滤器）
7. 来源类型（例如，任何、本地或外部网络）
8. 源 IP 地址
9. 来源端口

具体标准，如服务器名称 / SNI 或 IP 地址，也允许使用范围或通配符。如果在多个过滤器链中使用通配符标准，最具体的值将被匹配。

例如，对于 `www.hello.com` 从最具体到最不具体的匹配顺序是这样的。

1. `www.hello.com`
2. `*.hello.com`
3. `*.com`
4. 任何没有服务器名称标准的过滤器链

下面是一个例子，说明我们如何使用不同的属性配置过滤器链匹配。

```yaml
filter_chains:
- filter_chain_match:
    server_names:
      - "*.hello.com"
  filters:
    ...
- filter_chain_match:
    source_prefix_ranges:
      - address_prefix: 192.0.0.1
        prefix_len: 32
  filters:
    ...
- filter_chain_match:
    transport_protocol: tls
  filters:
    ...
```

让我们假设一个 TLS 请求从 IP 地址进来，并且 `192.0.0.1` SNI 设置为 `v1.hello.com`。记住这个顺序，第一个满足所有条件的过滤器链匹配是服务器名称匹配（`v1.hello.com`）。因此，Envoy 会执行该匹配下的过滤器。

但是，如果请求是从 IP `192.0.0.1` 进来的，那就不是 TLS，而且 SNI 也不符合 `*.hello.com` 的要求。Envoy 将执行第二个过滤器链——与特定 IP 地址相匹配的那个。