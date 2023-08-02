---
draft: false
weight: 3
linktitle: "用例"
title: "ApplicationSet 控制器用例"
date: '2023-06-30T16:00:00+08:00'
---

使用生成器的概念，应用集控制器提供了一组强大的工具，用于自动化模板化和修改 Argo CD 应用程序。生成器从各种来源（包括 Argo CD 集群和 Git 存储库）生成模板参数数据，支持和启用新的用例。

虽然可以将这些工具用于任何目的，但这里是应用集控制器旨在支持的一些特定用例。

## 用例：集群附加组件

应用集控制器的初始设计重点是允许基础架构团队的 Kubernetes 集群管理员自动创建大量不同的 Argo CD 应用程序，跨多个集群，并将这些应用程序作为单个单元进行管理。 *集群附加组件用例* 就是其中一个例子。

在 *集群附加组件用例* 中，管理员负责为一个或多个 Kubernetes 集群配置集群附加组件：集群附加组件是 Operator，例如 [Prometheus  Operator](https://github.com/prometheus-operator/prometheus-operator) 或控制器，例如 [argo-workflows 控制器](https://argoproj.github.io/argo-workflows/)（[Argo 生态系统](https://argoproj.github.io/)的一部分）。

通常，这些附加组件是开发团队的应用程序所需的（例如作为多租户集群的租户，他们可能希望向 Prometheus 提供度量数据或通过 Argo Workflows 编排工作流程）。

由于安装这些插件需要集群级别的权限，而这些权限不被单个开发团队持有，因此安装是组织的基础架构/运营团队的责任，在大型组织内，这个团队可能负责数十、数百或数千个 Kubernetes 集群（新集群定期添加/修改/删除）。

需要在大量集群上扩展，并自动响应新集群的生命周期，这必然需要某种形式的自动化。进一步的要求是允许使用特定标准（例如，staging vs production）将附加组件针对子集群进行定位。

![集群附加组件图](../../../assets/applicationset/Use-Cases/Cluster-Add-Ons.png)

在这个例子中，基础架构团队维护一个包含 Argo Workflows 控制器和 Prometheus  Operator 应用程序清单的 Git 存储库。

基础架构团队希望使用 Argo CD 将这两个插件部署到大量集群，并希望轻松管理新集群的创建/删除。

在这个用例中，我们可以使用应用集控制器的 List、Cluster 或 Git 生成器中的任一个来提供所需的行为：

- List 生成器：管理员维护两个 `ApplicationSet` 资源，每个应用程序（工作流和 Prometheus）都包含它们希望在 List 生成器元素中定位的集群列表。
  - 在该生成器中，添加/删除集群需要手动更新 `ApplicationSet` 资源的列表元素。
- Cluster 生成器：管理员维护两个 `ApplicationSet`  资源，每个应用程序（工作流和 Prometheus）都确保在 Argo CD 中定义所有新集群。
  - 由于 Cluster 生成器自动检测并针对 Argo CD 中定义的集群，添加/删除 Argo CD 中的集群 将自动导致应用集控制器创建 Application 资源（每个应用程序）。
- Git 生成器：Git 生成器是生成器中最灵活/最强大的，因此有多种不同的方法来处理此用例。以下是其中的几个：
  - 使用 Git 生成器的 `files` 字段：将集群列表作为 JSON 文件保存在 Git 存储库中。通过 Git 提交更新 JSON 文件，会导致添加/删除新集群。
  - 使用 Git 生成器的 `directories` 字段：对于每个目标集群，都在 Git 存储库中存在一个对应的同名目录。通过 Git 提交添加/修改目录，将触发共享目录名称的集群的更新。

有关每个生成器的详细信息，请参见 [生成器部分](../generator/)。

## 用例：单体库

在 *单体库用例* 中，Kubernetes 集群管理员从单个 Git 存储库管理单个 Kubernetes 集群的整个状态。

合并到 Git 存储库的清单更改应自动部署到集群。

在这个例子中，基础架构团队维护一个包含 Argo Workflows 控制器和 Prometheus  Operator 应用程序清单的 Git 存储库。独立的开发团队还添加了他们希望部署到集群的其他服务。

对 Git 生成器可能用于支持此用例：

- Git 生成器的 `directories` 字段可用于指定包含要部署的各个应用程序的特定子目录（使用通配符）。
- Git 生成器的 `files` 字段可以引用包含 JSON 元数据的 Git 存储库文件，该元数据描述要部署的各个应用程序。
- 更多详情请参见 Git 生成器文档。

## 用例：多租户集群上的 Argo CD 应用程序自助服务

*自助服务用例* 旨在允许开发人员（作为多租户 Kubernetes 集群的最终用户）以自动化方式更灵活地执行以下操作：

- 使用 Argo CD 将多个应用程序部署到单个集群
- 使用 Argo CD 自动化地部署到多个集群
- 但在这两种情况下，使开发人员能够在不需要涉及集群管理员的情况下执行此操作（以代表他们创建所需的 Argo CD 应用程序/AppProject 资源）

这个用例的一个潜在解决方案是，开发团队在 Git 存储库中定义 Argo CD `Application` 资源（包含他们希望部署的清单），在 [app-of-apps 模式](../../cluster-bootstrapping/#app-of-apps-pattern) 中，并且集群管理员通过合并请求审查/接受对此存储库的更改。

虽然这听起来像是一种有效的解决方案，但一个主要的劣势是需要高度的信任/审查来接受包含 Argo CD `Application` 规范更改的提交。这是因为 `Application` 规范中包含许多敏感字段，包括 `project`、`cluster` 和 `namespace`。意外合并可能会允许应用程序访问其不属于的命名空间/集群。

因此，在自助服务用例中，管理员希望仅允许开发人员控制 `Application` 规范的某些字段（例如 Git 源存储库），但不允许控制其他字段（例如目标命名空间或目标集群应受到限制）。

幸运的是，应用集控制器提供了另一种解决方案：集群管理员可以安全地创建包含 Git 生成器的 `ApplicationSet` 资源，该生成器使用 `template` 字段将应用程序资源的部署限制为固定值，同时允许开发人员随意自定义 'safe' 字段。

```yaml
 kind: ApplicationSet
 # (...)
 spec:
   generators:
   - git:
       repoURL: <https://github.com/argoproj/argo-cd.git>
       files:
       - path: "apps/**/config.json"
   template:
     spec:
       project: dev-team-one # 项目受到限制
       source:
         # 开发人员可以使用上述 repo URL 中的 JSON 文件自定义应用程序详细信息
         repoURL: {{app.source}}
         targetRevision: {{app.revision}}
         path: {{app.path}}
       destination:
         name: production-cluster # 集群受到限制
         namespace: dev-team-one # 命名空间受到限制
```

有关更多详细信息，请参见 [Git 生成器](../generators-git/)。
