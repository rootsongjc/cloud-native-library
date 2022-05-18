---
weight: 40
title: 安装
date: '2022-05-18T00:00:00+08:00'
type: book
icon: book-open
icon-pack: fas
---

有两种方法可以在单个 Kubernetes 集群上安装 Istio：
- 使用 Istioctl（istioctl）
- 使用 Istio Operator

在本章中，我们将使用 Istio Operator 在一个 Kubernetes 集群上安装 Istio。

### 使用 Istioctl 安装

Istioctl 是一个命令行工具，我们可以用它来安装和定制 Istio 的安装。使用该命令行工具，我们生成一个包含所有 Istio 资源的 YAML 文件，然后将其部署到 Kubernetes 集群上。

### 使用 Istio Operator 安装

与 istioctl 相比，Istio Operator 安装的优势在于，我们不需要手动升级 Istio。相反，我们可以部署 Istio Operator，为你管理安装。我们通过更新一个自定义资源来控制 Operator，而操作员则为你应用配置变化。

### 生产部署情况如何？

在决定 Istio 的生产部署模式时，还有一些额外的考虑因素需要牢记。我们可以配置 Istio 在不同的部署模型中运行 —— 可能跨越多个集群和网络，并使用多个控制平面。我们将在高级功能模块中了解其他部署模式、多集群安装以及在虚拟机上运行工作负载。

### 平台安装指南

Istio 可以安装在不同的 Kubernetes 平台上。关于特定云供应商的最新安装指南，请参考[平台安装文档](https://istio.io/latest/docs/setup/platform-setup/)。

{{< cta cta_text="阅读本章" cta_link="istio-installation" >}}