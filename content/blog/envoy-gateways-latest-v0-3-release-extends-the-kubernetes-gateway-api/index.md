---
title: "Envoy Gateway 0.3 发布——扩展 Kubernetes Gateway API"
date: 2023-02-28T11:20:00+08:00
draft: false
authors: ["Matt Turner"]
summary: "Envoy Gateway 0.3 发布，对 Kubernetes Gateway API 的支持更进一步。"
tags: ["Envoy","Envoy Gateway","API Gateway","Gateway"]
categories: ["Envoy"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://tetrate.io/blog/envoy-gateways-latest-v0-3-release-extends-the-kubernetes-gateway-api/
---

[Envoy Gateway](https://github.com/envoyproxy/gateway) (EG)[首次公开发布](https://tetrate.io/blog/gateway-to-the-future-the-new-gateway-api-and-envoy-gateway-0-2/) 四个月后，我们很高兴地宣布发布 [版本 0.3](https://github.com/envoyproxy/gateway/releases/tag/v0.3.0) 起。这个最新版本是几位 Tetrate 同事和整个社区其他人辛勤工作的结晶。Envoy Gateway 现在支持整个 [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)，包括实验部分——添加了一些强大的新功能，使这个免费的开源软件更接近于功能齐全的 API 网关。

EG 的一大特点是它配置了新的网关 API，而不是旧的和非常有限的 [Ingress API](https://kubernetes.io/docs/concepts/services-networking/ingress/)，或任何为了弥补 Ingress 缺陷的专有 API。虽然 EG 0.2 实现了 Gateway API 的核心部分（完全支持“基本”HTTP 路由），但 EG 0.3 在其 Gateway API 支持方面更进了一步，这可能是了解其新功能的最佳方式：

- 支持更多 HTTP 功能，例如[URL Rewrite](https://gateway.envoyproxy.io/v0.3.0/user/http-urlrewrite.html)、[Response Header Operation](https://gateway.envoyproxy.io/v0.3.0/user/http-response-headers.html) 和流量镜像。这些来自 API 规范中的扩展字段。
- 支持路由 [gRPC](https://gateway.envoyproxy.io/v0.3.0/user/grpc-routing.html)、[UDP](https://gateway.envoyproxy.io/v0.3.0/user/udp-routing.html) 和原始 [TCP](https://gateway.envoyproxy.io/v0.3.0/user/tcp-routing.html)。这些来自 API 的实验性新部分。

请注意这些 API 扩展：我们正在努力为真实用户提供有用的功能。 [SIG-NETWORK COMMUNITY](https://github.com/kubernetes/community/tree/master/sig-network) 作为负责网关 API 规范的人员，有负责保护 API，因此他们的工作需要一些实践。作为实施者，我们有更多的自由在具体规范之前开辟一条道路——但我们已经在上游工作以标准化这些扩展。这种在工作实施中对新功能进行的实验是让任何团体接受提议的新 API 的重要一步——它对每个人都有好处。

这些令人兴奋的新功能确实使 Envoy Gateway 项目超越了人们的好奇心，可以为许多现实世界的用例提供服务。重要的是，它能够提供所有这些，同时基于开放标准 API 并且是免费和开源软件，没有付费层。

自己试用 Envoy Gateway 0.3 非常简单，只需转到 [快速入门指南](https://gateway.envoyproxy.io/v0.3.0/user/quickstart.html) 即可开始！如果您想更深入地了解如何使用 *minikube* 在本地进行尝试，大多数 [EG 0.2 动手指南](https://tetrate.io/blog/hands-on-with-the-gateway-api-using-envoy-gateway-0-2/) 仍然有效。
