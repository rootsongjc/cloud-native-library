---
weight: 1
title: "Argo CD 中文文档"
linkTitle: "Argo CD 中文文档"
summary: "Argo CD 中文文档（非官方）"
date: '2023-06-30T16:20:00+08:00'
type: book
icon: book
icon_pack: fas
cascade:
  commentable: true
  level: 1
  type: book
  tags: ["Argo","Argo CD"]
  categories: ["GitOps"]
---

[Argo CD](https://argo-cd.readthedocs.io/en/stable/)是一种开源的持续交付工具，用于自动化和管理应用程序的部署、更新和回滚。它是一个声明式的工具，专为在 Kubernetes 集群中进行应用程序部署而设计。

🔔 注意：本文档根据 Argo CD v2.8  [Commit `4d2cd06f86`](https://github.com/argoproj/argo-cd/tree/4d2cd06f86c1117418bda5b943876291a4473d38)（北京时间 2023 年 6 月 30 日 19 时）翻译。

Argo CD 的主要功能包括：

1. **持续交付**：Argo CD 允许用户将应用程序的配置和清单文件定义为 Git 存储库中的声明式资源，从而实现持续交付。它能够自动检测 Git 存储库中的更改，并将这些更改应用于目标 Kubernetes 集群。

2. **健康监测和回滚**：Argo CD 能够监测应用程序的健康状态，并在检测到问题时触发回滚操作。这有助于确保应用程序在部署期间和运行时保持稳定和可靠。

3. 多环境管理：Argo CD 支持多个环境（例如开发、测试、生产）的管理。它可以帮助用户在不同环境中进行应用程序的部署和配置管理，并确保这些环境之间的一致性。

4. **基于 GitOps 的操作**：Argo CD 采用了 GitOps 的操作模式，即将应用程序的状态和配置定义为 Git 存储库中的声明式资源。这使得团队可以使用版本控制和代码审查等软件工程实践来管理应用程序的生命周期。

## 大纲

{{< list_children show_summary="false">}}

{{< cta cta_text="开始阅读" cta_link="overview" >}}
