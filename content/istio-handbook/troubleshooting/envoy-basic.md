---
weight: 10
title: Envoy 基础问题
date: '2022-05-18T00:00:00+08:00'
type: book
---

为了排除 Istio 的问题，对 Envoy 的工作原理有一个基本的了解是很有帮助的。Envoy 配置是一个 JSON 文件，分为多个部分。我们需要了解 Envoy 的基本概念是监听器、路由、集群和端点。

这些概念映射到 Istio 和 Kubernetes 资源，如下图所示。

![Envoy 概念与 Istio 和 Kubernetes 的映射](../../images/008i3skNly1gtd68759rlj60zk0k0acj02.jpg "Envoy 概念与 Istio 和 Kubernetes 的映射")

监听器是命名的网络位置，通常是一个 IP 和端口。Envoy 对这些位置进行监听，这是它接收连接和请求的地方。

每个 sidecar 都有多个监听器生成。每个 sidecar 都有一个监听器，它被绑定到 `0.0.0.0:15006`。这是 IP Tables 将所有入站流量发送到 Pod 的地址。第二个监听器被绑定到 `0.0.0.0:15001`，这是所有从 Pod 中出站的流量地址。

当一个请求被重定向（使用 IP Tables 配置）到 15001 端口时，监听器会把它交给与请求的原始目的地最匹配的虚拟监听器。如果它找不到目的地，它就根据配置的 OutboundTrafficPolicy 来发送流量。默认情况下，请求被发送到 `PassthroughCluster`，该集群连接到应用程序选择的目的地，Envoy 没有进行任何负载均衡。