---
title: 在 AWS ECS 上使用工作负载快速入门
linktitle: AWS ECS
weight: 2
---

本指南将帮助你快速入门实际中的“工作负载载入”。

在本指南的一部分中，你将会：
1. 将 [Istio Bookinfo](https://istio.io/latest/docs/examples/bookinfo/) 示例部署到 Elastic Kubernetes Service (EKS) 集群中。
1. 将 `ratings` 应用程序部署为 AWS ECS 任务，并将其加入服务网格。
1. 验证 Kubernetes Pod(s) 与 AWS ECS 任务之间的流量。

本指南旨在演示工作负载加入功能的易于跟随的演示。

为了保持简单，你无需像在生产部署的情况下那样配置基础设施。

具体而言：
* 你无需设置可路由的 DNS 记录。
* 你无需使用受信任的 CA 机构（例如 Let's Encrypt）。

在继续之前，请确保完成以下先决条件：
* 创建一个 EKS 集群，以便安装 TSB 和示例应用程序。
* 按照 [TSB 演示](../../../../setup/self-managed/demo-installation) 安装说明进行安装。
* 按照 [安装 Bookinfo 示例](./../aws-ec2/bookinfo) 中的说明进行操作。
* 按照 [启用工作负载加入](./../aws-ec2/enable-workload-onboarding) 中的说明进行操作。

{{< list_children show_summary="false">}}
