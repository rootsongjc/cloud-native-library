---
weight: 30
title: 数据平面
date: '2022-05-18T00:00:00+08:00'
type: book
icon: book-open
icon-pack: fas
---

Istio 中的数据平面默认使用的是 [Envoy 代理](https://envoyproxy.io)，你也可以根据 [xDS](./envoy-xds-protocol.md) 构建其他数据平面，例如蚂蚁开源的 [MOSN](https://mosn.io)。因为本书的重点是介绍 Istio，因此笔者不会在这一章节重点着墨，感兴趣的读者可以阅读 [Envoy 基础教程](https://jimmysong.io/envoy-handbook/)进行进一步的学习。

{{< cta cta_text="阅读本章" cta_link="envoy-terminology" >}}