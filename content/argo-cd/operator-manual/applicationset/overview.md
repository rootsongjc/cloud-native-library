---
draft: false
title: "ApplicationSet 控制器介绍"
weight: 1
linktitle: "介绍"
date: '2023-06-30T16:00:00+08:00'
---

## 介绍

应用程序集控制器是一个[Kubernetes 控制器](https://kubernetes.io/docs/concepts/architecture/controller/)，它添加了对`ApplicationSet`[自定义资源定义](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) (CRD) 的支持。这个控制器/CRD 使得自动化和更大的灵活性在管理 Argo CD 应用程序跨大量的集群和在 monorepos 内成为可能，同时它使多租户 Kubernetes 集群上的自助式使用成为可能。

应用程序集控制器与现有的 Argo CD 安装一起工作。Argo CD 是一个声明性的、GitOps 持续交付工具，允许开发人员从他们现有的 Git 工作流程中定义和控制 Kubernetes 应用程序资源的部署。

从 Argo CD v2.3 开始，应用程序集控制器与 Argo CD 捆绑在一起。

应用程序集控制器通过添加支持面向集群管理员的附加功能来补充 Argo CD。`ApplicationSet`控制器提供：

- 使用单个 Kubernetes 清单定位多个 Kubernetes 集群的能力，使用 Argo CD 部署多个应用程序的能力
- 使用单个 Kubernetes 清单从一个或多个 Git 存储库中部署多个应用程序的能力
- 改进了对 monorepos 的支持：在 Argo CD 的上下文中，monorepo 是一个单个 Git 存储库中定义的多个 Argo CD 应用程序资源
- 在多租户集群中，提高了各个集群租户使用 Argo CD 部署应用程序的能力（无需涉及特权集群管理员以启用目标集群/命名空间）

🔔 注意：在使用 ApplicationSets 之前，请注意其安全影响。

## 应用程序集资源

此示例定义了一个名为`guestbook`的`ApplicationSet`资源：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: guestbook
spec:
  generators:
  - list:
      elements:
      - cluster: engineering-dev
        url: https://1.2.3.4
      - cluster: engineering-prod
        url: https://2.4.6.8
      - cluster: finance-preprod
        url: https://9.8.7.6
  template:
    metadata:
      name: '{{cluster}}-guestbook'
    spec:
      project: my-project
      source:
        repoURL: <https://github.com/infra-team/cluster-deployments.git>
        targetRevision: HEAD
        path: guestbook/{{cluster}}
      destination:
        server: '{{url}}'
        namespace: guestbook
```

在此示例中，我们想要将我们的`guestbook`应用程序（由于这是 GitOps，该应用程序的 Kubernetes 资源来自 Git）部署到一系列 Kubernetes 集群（目标集群的列表在`ApplicationSet`资源的 List 项元素中定义）。

虽然`ApplicationSet`资源可以使用多种类型的*生成器*，但此示例使用了列表生成器，它只包含一个固定的、字面的集群列表。这个集群列表将是 Argo CD 在处理了`ApplicationSet`资源后部署`guestbook`应用程序资源的集群。

生成器（如 List 生成器）负责生成*参数*。参数是键值对，在模板渲染期间被替换到`ApplicationSet`资源的`template:`部分中。

当前支持的多个生成器：

- **List 生成器**：基于固定的集群名称/URL 值列表生成参数，如上面的示例所示。
- **Cluster 生成器**：而不是一个字面的集群列表（如列表生成器），集群生成器根据在 Argo CD 中定义的集群自动生成集群参数。
- **Git 生成器**：Git 生成器基于包含在生成器资源中的文件或文件夹生成参数。 - 包含 JSON 值的文件将被解析并转换为模板参数。 - Git 存储库中的单个目录路径也可以用作参数值。
- **Matrix 生成器**：矩阵生成器结合了两个其他生成器的生成参数。

有关各个生成器的更多信息以及未列出的其他生成器，请参见生成器部分。

## 将参数替换为模板

不管使用哪个生成器，由生成器生成的参数都会被替换为`{{parameter name}}`值，而这些值位于`ApplicationSet`资源的`template:`部分中。在此示例中，列表生成器定义了`cluster`和`url`参数，这些参数随后分别被替换为模板的`{{cluster}}`和`{{url}}`值。

在将参数替换后，将此`guestbook` `ApplicationSet`资源应用于 Kubernetes 集群：

1.应用程序集控制器处理生成器条目，生成一组模板参数。2.这些参数被替换到模板中，每组参数替换一次。3.每个渲染的模板都被转换为一个 Argo CD `Application`资源，然后创建（或更新）在 Argo CD 名称空间中。4.最后，Argo CD 控制器会收到这些`Application`资源的通知，并负责处理它们。

对于我们的示例中定义的三个不同集群——`engineering-dev`、`engineering-prod`和`finance-preprod`，这将产生三个新的 Argo CD`Application`资源：每个集群一个。

这是将创建的`Application`资源之一的示例，为`engineering-dev`集群在`1.2.3.4`处：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: engineering-dev-guestbook
spec:
  source:
    repoURL: https://github.com/infra-team/cluster-deployments.git
    targetRevision: HEAD
    path: guestbook/engineering-dev
  destination:
    server: https://1.2.3.4
    namespace: guestbook
```

我们可以看到生成的值已被替换到模板的`server`和`path`字段中，模板已被渲染成一个完整的 Argo CD 应用程序。

现在这些 Application 也可以在 Argo CD UI 中看到：

![ArgoCD Web UI 中的列表生成器示例](../../../assets/applicationset/Introduction/List-Example-In-Argo-CD-Web-UI.png)

应用程序集控制器将确保将对`ApplicationSet`资源所做的任何更改、更新或删除自动应用于相应的`Application`。

例如，如果向列表生成器添加了新的集群/URL 列表条目，则将为此新集群相应地创建一个新的 Argo CD`Application`资源。对`guestbook` `ApplicationSet`资源所做的任何编辑都将影响由该资源实例化的所有 Argo CD 应用程序，包括新应用程序。

虽然列表生成器的字面集群列表相当简单，但 ApplicationSet 控制器支持其他可用生成器的更复杂的场景。
