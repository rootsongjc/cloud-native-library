---
weight: 4
title: Iptables 用法
date: '2022-06-17T12:00:00+08:00'
type: book
---

根据所使用的 Linux 内核版本，eBPF 数据路径可以完全在 eBPF 中实现不同的功能集。如果某些所需功能不可用，则使用旧版 iptables 实现提供该功能。有关详细信息，请参阅 [IPsec 要求。](https://docs.cilium.io/en/stable/operations/system_requirements/#features-kernel-matrix)

## kube-proxy 互操作性

下图显示了 `kube-proxy` 安装的 iptables 规则和 Cilium 安装的 iptables 规则的集成。

![图片](../images/kubernetes_iptables.svg "kube-proxy 与 Cilium 的 iptables 规则集成")

{{< cta cta_text="下一章" cta_link="../../policy" >}}
