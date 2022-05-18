---
weight: 70
title: TLS 检查器监听器过滤器
date: '2022-05-18T00:00:00+08:00'
type: book
---

[TLS 监听器](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/listener_filters/tls_inspector)过滤器让我们可以检测到传输的是 TLS 还是明文。 如果传输是 TLS，它会检测服务器名称指示（SNI）和 / 或客户端的应用层协议协商（ALPN）。

**什么是 SNI？**

SNI 或服务器名称指示（Server Name Indication）是对 TLS 协议的扩展，它告诉我们在 TLS 握手过程的开始，哪个主机名正在连接。我们可以使用 SNI 在同一个 IP 地址和端口上提供多个 HTTPS 服务（使用不同的证书）。如果客户端以主机名 "hello.com" 进行连接，服务器可以出示该主机名的证书。同样地，如果客户以 "example.com" 连接，服务器就会提供该证书。

**什么是 ALPN？**

ALPN 或应用层协议协商是对 TLS 协议的扩展，它允许应用层协商应该在安全连接上执行哪种协议，而无需进行额外的往返请求。使用 ALPN，我们可以确定客户端使用的是 HTTP/1.1 还是 HTTP/2。

我们可以使用 SNI 和 ALPN 值来匹配过滤器链，使用 `server_names`（对于 SNI）和 / 或 `application_protocols`（对于 ALPN）字段。

下面的片段显示了我们如何使用 `application_protocols` 和 `server_names` 来执行不同的过滤器链。

```yaml
...
    listener_filters:
      - name: "envoy.filters.listener.tls_inspector"
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector
    filter_chains:
    - filter_chain_match:
        application_protocols: ["h2c"]
      filters:
      - name: some_filter
        ... 
    - filter_chain_match:
        server_names: "something.hello.com"
      transport_socket:
      ...
      filters:
      - name: another_filter
...
```

# 