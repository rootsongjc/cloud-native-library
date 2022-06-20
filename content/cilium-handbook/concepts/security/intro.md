---
weight: 1
title: 介绍
date: '2022-06-17T12:00:00+08:00'
type: book
hide_toc_title: true
---

Cilium 在多个层面上提供安全性。可以单独使用或组合使用。

- [基于身份](../identity/)：端点之间的连接策略（L3），例如任何带有标签的端点 `role=frontend` 都可以连接到任何带有标签的端点 `role=backend`。
- 限制传入和传出连接的可访问端口（L4），例如带标签的端点 `role=frontend`只能在端口 443（https）上进行传出连接，端点`role=backend` 只能接受端口 443（https）上的连接。
- 应用程序协议级别的细粒度访问控制，以保护 HTTP 和远程过程调用（RPC）协议，例如带有标签的端点 `role=frontend` 只能执行 REST API 调用 `GET /userdata/[0-9]+`，所有其他与 `role=backend` API 的交互都受到限制。
