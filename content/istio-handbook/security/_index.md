---
weight: 80
title: 安全
date: '2022-05-18T00:00:00+08:00'
type: book
---

在本章中，我们将学习 Istio 的安全功能。具体来说，就是认证和授权策略、安全命名和身份。

在 Istio 中，有多个组件参与提供安全功能：

- 用于管理钥匙和证书的证书颁发机构（CA）。
- Sidecar 和周边代理：实现客户端和服务器之间的安全通信，它们作为政策执行点（Policy Enforcement Point，简称PEP）工作
- Envoy 代理扩展：管理遥测和审计
- 配置 API 服务器：分发认证、授权策略和安全命名信息

## 本章大纲

{{< list_children show_summary="false">}}

{{< cta cta_text="阅读本章" cta_link="authn" >}}
