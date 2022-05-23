---
weight: 100
title: 高级功能
date: '2022-05-18T00:00:00+08:00'
type: book
icon: book-open
icon-pack: fas
---

在本章中，我们将了解在多个集群上安装 Istio 的不同方法，以及如何将运行在虚拟机上的工作负载纳入服务网格。

当决定在多集群场景下运行 Istio 时，有多种组合需要考虑。在高层次上，我们需要决定以下几点：

- 单个集群或多个集群
- 单个网络或多个网络
- 单个控制平面或多个控制平面
- 单个网格或多个网格

上述模式的任何组合都是可能的，然而，并非所有的模式都有意义。在本章中，我们将重点讨论涉及多个集群的场景。

## 本章大纲

{{< list_children show_summary="false">}}

{{< cta cta_text="阅读本章" cta_link="multicluster-deployment" >}}