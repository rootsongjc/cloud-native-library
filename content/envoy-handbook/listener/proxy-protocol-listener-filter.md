---
weight: 60
title: 代理协议监听器过滤器
date: '2022-05-18T00:00:00+08:00'
type: book
---

[代理协议](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/listener_filters/proxy_protocol)监听器过滤器（`envoy.filters.listener.proxy_protocol`）增加了对 [HAProxy 代理协议](https://www.haproxy.org/download/1.9/doc/proxy-protocol.txt)的支持。

代理使用其 IP 堆栈连接到远程服务器，并丢失初始连接的源和目的地信息。PROXY 协议允许我们在不丢失客户端信息的情况下链接代理。该协议定义了一种在主 TCP 流之前通过 TCP 通信连接的元数据的方式。元数据包括源 IP 地址。

使用这个过滤器，Envoy 可以从 PROXY 协议中获取元数据，并将其传播到 `x-forwarded-for` 头中。