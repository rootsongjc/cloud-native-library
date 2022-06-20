---
weight: 1
linkTitle: 介绍
title: Kubernetes 集成介绍
date: '2022-06-17T12:00:00+08:00'
type: book
---

## Cilium 能为 Kubernetes 集群提供什么？

在 Kubernetes 集群中运行 Cilium 时提供以下功能：

- [CNI](https://docs.cilium.io/en/stable/glossary/#term-cni) 插件支持，为 [pod 连接](https://docs.cilium.io/en/stable/concepts/kubernetes/intro/#pod-connectivity) 提供 [联网](https://docs.cilium.io/en/stable/concepts/networking/#multi-host-networking)。
- [NetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#networkpolicy) 资源的基于身份的实现，用于隔离 L3 和 L4 网络  [pod](https://docs.cilium.io/en/stable/glossary/#term-pod) 的连接。
- 以 `CustomResourceDefinition` 形式对 NetworkPolicy 的扩展，扩展策略控制以添加：
  - 针对以下应用协议的入口和出口执行 L7 策略：
    - HTTP
    - Kafka
  - 对 CIDR 的出口支持以保护对外部服务的访问
  - 强制外部无头服务自动限制为服务配置的 Kubernetes 端点集
- ClusterIP 实现为 pod 到 pod 的流量提供分布式负载平衡
- 完全兼容现有的 kube-proxy 模型

## Pod 间连接

在 Kubernetes 中，容器部署在称为 pod 的单元中，其中包括一个或多个可通过单个 IP 地址访问的容器。使用 Cilium，每个 pod 从运行 pod 的 Linux 节点的节点前缀中获取一个 IP 地址。有关其他详细信息，请参阅 [IP 地址管理（IPAM）](../../concepts/networking/ipam/#address-management)。在没有任何网络安全策略的情况下，所有的 pod 都可以互相访问。

Pod IP 地址通常位于 Kubernetes 集群本地。如果 pod 需要作为客户端访问集群外部的服务，则网络流量在离开节点时会自动伪装。

## 服务负载均衡

Kubernetes 开发了服务抽象，它为用户提供了将网络流量负载平衡到不同 pod 的能力。这种抽象允许 pod 通过单个 IP 地址（一个虚拟 IP 地址）与其他 pod 联系，而无需知道所有运行该特定服务的 pod。

如果没有 Cilium，kube-proxy 会安装在每个节点上，监视 kube-master 上的端点和服务的添加和删除，这允许它在 iptables 上应用必要的强制策略执行。因此，从 pod 接收和发送到的流量被正确地路由到为该服务服务的节点和端口。有关更多信息，您可以查看服务的 Kubernetes 用户 [指南](https://kubernetes.io/docs/concepts/services-networking/service/)。

在实现 ClusterIP 时，Cilium 的行为与 kube-proxy 相同，它监视服务的添加或删除，但不是在 iptables 上执行，而是更新每个节点上的 eBPF 映射条目。有关更多信息，请参阅 [GItHub PR](https://github.com/cilium/cilium/pull/109)。

## 延伸阅读

Kubernetes 文档包含有关 [Kubernetes 网络模型](https://kubernetes.io/docs/concepts/cluster-administration/networking/)和 [Kubernetes 网络插件](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)的更多背景信息 。
