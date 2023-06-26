---
weight: 1
title: "Argo Rollouts 中文文档"
linkTitle: "Argo Rollouts 中文文档"
summary: "Argo Rollouts 中文文档（非官方）"
date: '2023-06-21T16:20:00+08:00'
type: book
icon: book
icon_pack: fas
cascade:
  commentable: true
  level: 1
  tags: ["Argo","Argo Rollouts"]
  categories: ["GitOps"]
---

[Argo Rollouts](https://argo-rollouts.readthedocs.io/en/stable/) 是一个 Kubernetes 控制器，它提供了在应用程序部署过程中执行渐进式发布和蓝绿部署等高级部署策略的能力。它是基于 Kubernetes 原生的 `Deployment` 资源构建的，通过引入新的 `Rollout` 资源来扩展和增强部署控制。

🔔 注意：本文档根据 Argo Rollouts v1.5  [Commit `1d53b25`](https://github.com/argoproj/argo-rollouts/tree/1d53b251e1e1139f5e94314b5b121829edc5c88a)（北京时间 2023 年 6 月 21 日 3 时）翻译。

Argo Rollouts 具有以下主要功能：

1. **渐进式发布**（Progressive Delivery）：Argo Rollouts 允许你逐步增加新版本的流量并监控其性能，以确保新版本稳定可靠。你可以通过配置渐进式发布的步骤和条件来控制流量的切换和回滚。

2. **蓝绿部署**（Blue-Green Deployment）：Argo Rollouts 支持蓝绿部署模式，其中在新旧版本之间进行无缝切换。通过在新版本上运行一些或全部流量，并根据用户的反馈和性能指标来验证新版本的稳定性，可以确保零停机时间的部署。

3. **金丝雀部署**（Canary Deployment）：Argo Rollouts 支持金丝雀部署模式，可以将新版本的流量逐渐引入生产环境，并基于预定义的指标和策略来评估新版本的性能。这使你能够在生产中小范围测试新版本，并及时发现和修复潜在问题。

4. **自动回滚**（Automated Rollback）：如果新版本在部署过程中出现问题或未达到预期的性能指标，Argo Rollouts 具备自动回滚功能，可以快速将流量切换回稳定版本，以减少对用户的影响。

Argo Rollouts 使用自定义资源 `Rollout` 来描述部署的状态和策略，并通过控制器与 Kubernetes API 交互，实现部署的管理和控制。它提供了灵活且可扩展的部署流程定义，使你能够以可控的方式执行复杂的应用程序部署和更新操作。

## 大纲

{{< list_children show_summary="false">}}

{{< cta cta_text="开始阅读" cta_link="overview" >}}
