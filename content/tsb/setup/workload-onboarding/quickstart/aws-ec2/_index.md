---
title: 在 AWS EC2 上快速载入工作负载
linktitle: AWS EC2
weight: 1
---

本指南将帮助你实际开始使用“工作负载载入”。

作为本指南的一部分，你将：
1. 在你的 Kubernetes 集群中部署 [Istio Bookinfo](https://istio.io/latest/docs/examples/bookinfo/) 示例
1. 在 AWS EC2 实例上部署 `ratings` 应用程序并将其载入到服务网格
1. 验证 Kubernetes Pod(s) 与 AWS EC2 实例之间的流量
1. 在 AWS Auto Scaling Group 上部署 `ratings` 应用程序并将其载入到服务网格

本指南旨在演示工作负载载入功能，易于跟随。

为了保持简单，你无需配置基础设施，就像在生产部署的情况下所需的那样。

具体来说：
* 你无需设置可路由的 DNS 记录
* 你无需使用受信任的 CA 授权（如 Let's Encrypt）
* 你无需将 Kubernetes 集群和 AWS EC2 实例放在同一网络或对等网络上

在继续之前，请确保完成以下先决条件：
* 创建一个 Kubernetes 集群，以安装 TSB 和示例应用程序
* 按照 [TSB 演示](../../../../setup/self-managed/demo-installation) 安装说明操作
* 创建一个 AWS 帐户以启动 EC2 实例，在那里部署工作负载，并将其载入到服务网格。

{{< list_children show_summary="false">}}
