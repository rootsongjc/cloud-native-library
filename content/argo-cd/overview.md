---
weight: 1
linkTitle: 简介
title: "Argo CD 简介"
date: '2023-06-30T16:00:00+08:00'
type: book
---

## 什么是 Argo CD？

Argo CD 是一个基于声明式 GitOps 的 Kubernetes 应用程序交付工具。

![Argo CD UI](../assets/argocd-ui.gif)

## 为什么选择 Argo CD？

应用程序定义、配置和环境应该是声明式的，并进行版本控制。应用程序部署和生命周期管理应该是自动化的、可审计的和易于理解的。

## 入门指南

### 快速入门

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

请参阅我们的[入门指南](../getting-started/)。我们还为其他功能提供了面向用户的文档。如果您想升级 ArgoCD，请参阅升级指南。我们还为有兴趣构建第三方集成的开发人员提供面向开发者的文档。

## 工作原理

Argo CD 遵循使用 Git 存储库作为定义期望应用程序状态的真实来源的 GitOps 模式。Kubernetes 清单可以通过以下几种方式指定：

- [kustomize](https://kustomize.io/) 应用程序
- [helm](https://helm.sh/) chart
- [jsonnet](https://jsonnet.org/) 文件
- YAML/json 清单的普通目录
- 配置为配置管理插件的任何自定义配置管理工具

Argo CD 自动部署指定目标环境中所需的应用程序状态。应用程序部署可以跟踪分支、标签的更新或固定到 Git 提交的特定版本的清单。请参见[跟踪策略](../user-guide/tracking-strategies/)以了解有关可用跟踪策略的更多详细信息。

针对 Sig Apps 社区会议展示的快速 10 分钟的 Argo CD 概述，请查看演示：

{{<youtube "aWDIQMbp1cc">}}

## 架构

![ArgoCD 架构](../assets/argocd_architecture.png)

Argo CD 实现为 Kubernetes 控制器，它持续监视正在运行的应用程序，并将当前的实时状态与所需的目标状态（如 Git 存储库中指定的状态）进行比较。实时状态偏离目标状态的已部署应用程序被视为“OutofSync”。Argo CD 报告并可视化差异，同时提供自动或手动同步实时状态到所需目标状态的设施。对 Git 存储库中所需的目标状态所做的任何修改都可以自动应用并反映在指定的目标环境中。

有关详细信息，请参见[架构概述](../operator-manual/architecture/)。

## 功能

- 自动将应用程序部署到指定的目标环境
- 支持多个配置管理/模板工具（Kustomize、Helm、Jsonnet、plain-YAML）
- 能够管理和部署到多个集群
- SSO 集成（OIDC、OAuth2、LDAP、SAML 2.0、GitHub、GitLab、Microsoft、LinkedIn）
- 授权的多租户和 RBAC 策略
- 回滚/在任何提交到 Git 存储库中的应用程序配置中进行回滚
- 应用程序资源的健康状态分析
- 自动配置漂移检测和可视化
- 应用程序同步到其所需状态的自动或手动同步
- Web UI 提供应用程序活动的实时视图
- 用于自动化和 CI 集成的 CLI
- Webhook 集成（GitHub、BitBucket、GitLab）
- 访问令牌用于自动化
- 为覆盖 Git 中的 Helm 参数而提供的参数重写
- 用于支持复杂应用程序升级（例如蓝/绿和金丝雀升级）的 PreSync、Sync、PostSync 钩子
- 应用程序事件和 API 调用的审计跟踪
- Prometheus 指标

## 开发状态

Argo CD 正在由社区积极开发。我们的发布可以在[这里](https://github.com/argoproj/argo-cd/releases)找到。

## 采用情况

正式采用 Argo CD 的组织可以在[这里](https://github.com/argoproj/argo-cd/blob/master/USERS.md)找到。
