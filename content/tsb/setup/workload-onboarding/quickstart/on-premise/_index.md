---
title: 在本地快速入门工作负载
linktitle: 本地工作负载
weight: 3
---

本指南将帮助你在实践中开始使用“工作负载载入”。

作为这个指南的一部分，你将会：
1. 将 [Istio Bookinfo](https://istio.io/latest/docs/examples/bookinfo/) 示例部署到你的 Kubernetes 集群中。
1. 在本地虚拟机上部署 `ratings` 应用程序，并将其加入到服务网格中。
1. 验证 Kubernetes Pod(s) 和本地虚拟机之间的流量。

本指南旨在演示工作负载载入功能的易于跟随的示例。

为了保持简单，你无需像在生产部署的情况下那样配置基础设施。

具体来说：
* 你无需设置可路由的 DNS 记录。
* 你无需使用受信任的 CA 机构（例如 Let's Encrypt）。

在继续之前，请确保完成以下先决条件：
* 创建一个 Kubernetes 集群，以安装 TSB 和示例应用程序。
* 按照 [TSB 演示](../../../../setup/self-managed/demo-installation) 安装的说明进行操作。
* 按照 [安装示例 Bookinfo](../aws-ec2/bookinfo) 的说明进行操作。
* 按照 [启用工作负载载入](../aws-ec2/enable-workload-onboarding) 的说明进行操作。
* 确保本地虚拟机和 Kubernetes 集群位于相同的网络或对等网络上。

{{< list_children show_summary="false">}}
