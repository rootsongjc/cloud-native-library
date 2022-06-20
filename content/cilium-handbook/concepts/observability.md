---
weight: 3
title: 可观测性
date: '2022-06-17T12:00:00+08:00'
type: book
---

可观测性由 Hubble 提供，它可以以完全透明的方式深入了解服务的通信和行为以及网络基础设施。[Hubble 能够在多集群（集群网格）](../clustermesh/) 场景中提供节点级别、集群级别甚至跨集群的可视性。有关 Hubble 的介绍以及它与 Cilium 的关系，请阅读 [Cilium 和 Hubble 简介](../../intro/)部分。

默认情况下，Hubble API 的范围仅限于 Cilium 代理运行的每个单独节点。换句话说，网络可视性仅提供给本地 Cilium 代理观察到的流量。在这种情况下，与 Hubble API 交互的唯一方法是使用 Hubble CLI（`hubble`）查询通过本地 Unix Domain Socket 提供的 Hubble API。Hubble CLI 二进制文件默认安装在 Cilium 代理 pod 上。

部署 Hubble Relay 后，Hubble 提供完整的网络可视性。在这种情况下，Hubble Relay 服务提供了一个 Hubble API，它在 ClusterMesh 场景中涵盖整个集群甚至多个集群。可以通过将 Hubble CLI（`hubble`）指向 Hubble Relay 服务或通过 Hubble UI 访问 Hubble 数据。Hubble UI 是一个 Web 界面，可以自动发现三层/四层甚至七层的服务依赖图，允许用户友好的可视化和过滤数据流作为服务图。

{{< cta cta_text="下一章" cta_link="../networking" >}}
