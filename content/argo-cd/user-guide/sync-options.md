---
draft: false
title: "同步选项 "
weight: 16
---

Argo CD 允许用户定制同步目标集群中所需状态的某些方面。某些同步选项可以定义为特定资源中的注释。大多数同步选项在应用程序资源 `spec.syncPolicy.syncOptions` 属性中配置。使用 `argocd.argoproj.io/sync-options` 注释配置的多个同步选项可以在注释值中使用 `,` 进行连接；空格将被删除。

下面你可以找到有关每个可用同步选项的详细信息：

## 无修整资源

> v1.1

你可能希望防止修整对象：

```yaml
 metadata:
   annotations:
     argocd.argoproj.io/sync-options: Prune=false
```

在 UI 中，Pod 将仅显示为不同步：

![同步选项无修整](../../assets/sync-option-no-prune.png)

同步状态面板显示跳过修整的原因：

![同步选项无修正](../../assets/sync-option-no-prune-sync-status.png)

如果 Argo CD 期望剪切资源，则应用程序将失去同步。你可能希望与 [比较选项](../compare-options/) 结合使用。

## **禁用 Kubectl 验证**

对于某些对象类，需要使用 `--validate=false` 标志使用 `kubectl apply` 将其应用。例如使用 `RawExtension` 的 Kubernetes 类型，例如 [ServiceCatalog](https://github.com/kubernetes-incubator/service-catalog/blob/master/pkg/apis/servicecatalog/v1beta1/types.go#L497)。你可以使用以下注释执行此操作：

```yaml
 metadata:
   annotations:
     argocd.argoproj.io/sync-options: Validate=false
```

如果要全局排除整个对象类，请考虑在 系统级配置 中设置 `resource.customizations`。

## **跳过新的自定义资源类型的干预运行**

在同步尚未知道集群的自定义资源时，通常有两个选项：

1. CRD 清单是同步的一部分。然后，Argo CD 将自动跳过干预运行，将应用 CRD 并创建资源。
2. 在某些情况下，CRD 不是同步的一部分，但可以通过其他方式创建，例如通过集群中的控制器。例如是 [gatekeeper](https://github.com/open-policy-agent/gatekeeper)，它根据用户定义的 `ConstraintTemplates` 创建 CRD。Argo CD 无法在同步中找到 CRD，并将出现错误 `the server could not find the requested resource`。

要跳过缺少资源类型的干预运行，请使用以下注释：

```
 metadata:
   annotations:
     argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
```

如果 CRD 已经存在于集群中，则仍将执行干预运行。

## 无资源删除

对于某些资源，你可能希望在删除应用程序后仍保留它们，例如持久卷索赔。在这种情况下，你可以使用以下注释阻止在删除应用程序时清除这些资源：

```
 metadata:
   annotations:
     argocd.argoproj.io/sync-options: Delete=false
```

## 选择性同步

当前，在使用自动同步进行同步时，Argo CD 应用程序中的每个对象都会应用。对于包含数千个对象的应用程序，这需要相当长的时间，并对 API 服务器施加不必要的压力。打开选择性同步选项，仅同步不同步的资源。

你可以通过以下方式添加此选项

1) 在清单中添加 `ApplyOutOfSyncOnly=true`

示例：

```yaml
 apiVersion: argoproj.io/v1alpha1
 kind: Application
 spec:
   syncPolicy:
     syncOptions:
     - ApplyOutOfSyncOnly=true
```

2) 通过 argocd cli 设置同步选项

示例：

```bash
 $ argocd app set guestbook --sync-option ApplyOutOfSyncOnly=true
```

## 资源修整删除传播策略

默认情况下，使用前台删除策略删除多余的资源。可以控制传播策略 使用 `PrunePropagationPolicy` 同步选项。支持的策略是 background、foreground 和 orphan。有关这些策略的更多信息可以在 [这里](https://kubernetes.io/docs/concepts/workloads/controllers/garbage-collection/#controlling-how-the-garbage-collector-deletes-dependents) 找到。

```yaml
 apiVersion: argoproj.io/v1alpha1
 kind: Application
 spec:
   syncPolicy:
     syncOptions:
     - PrunePropagationPolicy=foreground
```

## 修整最后

此功能是为了允许在同步操作的最后一个隐式波之后，对资源进行修整，在其他资源已部署并变得健康之后，所有其他波成功完成之后。

```yaml
 apiVersion: argoproj.io/v1alpha1
 kind: Application
 spec:
   syncPolicy:
     syncOptions:
     - PruneLast=true
```

这也可以在个体资源级别进行配置。

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-options: PruneLast=true
```

## 替换资源而不是应用更改

默认情况下，Argo CD 执行 `kubectl apply` 操作以应用存储在 Git 中的配置。在某些情况下， `kubectl apply` 不适用。例如，资源规范可能太大，无法适合 添加的 `kubectl.kubernetes.io/last-applied-configuration` 注释。在这种情况下，你 可能会使用 `Replace=true` 同步选项：


```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  syncPolicy:
    syncOptions:
    - Replace=true
```

如果设置了 `Replace=true` 同步选项，Argo CD 将使用 `kubectl replace` 或 `kubectl create` 命令来应用更改。

🔔 警告：在同步过程中，资源将使用 'kubectl replace/create' 命令进行同步。此同步选项具有破坏性，可能导致必须重新创建资源，从而可能导致你的应用程序停机。

这也可以在单个资源级别进行配置。

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-options: Replace=true
```

## 服务器端应用

此选项启用 Kubernetes [服务器端应用](https://kubernetes.io/docs/reference/using-api/server-side-apply/)。

默认情况下，Argo CD 执行 `kubectl apply` 操作以应用存储在 Git 中的配置。这是一个客户端操作，依赖于 `kubectl.kubernetes.io/last-applied-configuration` 注释以存储上一个资源状态。

但是，有些情况下，你希望使用 `kubectl apply --server-side` 而不是 `kubectl apply`：

- 资源太大，无法适应允许的注释大小 262144 字节。在这种情况下，可以使用服务器端应用程序来避免此问题，因为在此情况下不使用注释。
- 对集群上不完全由 Argo CD 管理的现有资源进行修补。
- 使用更具声明性的方法，它跟踪用户的字段管理，而不是用户的上一次应用状态。

如果设置了 `ServerSideApply=true` 同步选项，Argo CD 将使用 `kubectl apply --server-side` 命令来应用更改。

它可以在应用程序级别启用，如下例所示：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  syncPolicy:
    syncOptions:
    - ServerSideApply=true
```

要为单个资源启用 ServerSideApply，可以使用 sync-option 注释：

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-options: ServerSideApply=true
```

ServerSideApply 还可用于通过提供部分 yaml 来修补现有资源。例如，如果有一个要求仅更新给定部署中的副本数的部署，可以向 Argo CD 提供以下 yaml：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 3
```

请注意，根据部署模式规范，这不是有效的清单。在这种情况下，必须提供一个额外的同步选项 *必须* 以跳过模式验证。下面的示例显示了如何配置应用程序以启用两个必要的同步选项：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  syncPolicy:
    syncOptions:
    - ServerSideApply=true
    - Validate=false
```

在这种情况下，Argo CD 将使用 `kubectl apply --server-side --validate=false` 命令应用更改。

注意：`Replace=true` 优先于 `ServerSideApply=true`。

## 如果发现共享资源，则同步失败

默认情况下，Argo CD 将应用在 Application 中配置的 Git 路径中找到的所有清单，而不管 yamls 中定义的资源是否已被另一个应用程序应用。如果设置了 `FailOnSharedResource` 同步选项，则在当前应用程序中发现已由另一个应用程序在集群中应用的资源时，Argo CD 将使同步失败。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  syncPolicy:
    syncOptions:
    - FailOnSharedResource=true
```

## 尊重忽略差异配置

此同步选项用于使 Argo CD 在同步阶段期间也考虑 `spec.ignoreDifferences` 属性中所做的配置。默认情况下，Argo CD 仅使用 `ignoreDifferences` 配置来计算实际状态和期望状态之间的差异，从而定义应用程序是否已同步。但是，在同步阶段期间，将按原样应用期望状态。使用三方合并计算补丁，其中包括实际状态、期望状态和 `last-applied-configuration` 注释。这有时会导致不希望的结果。可以通过将 `RespectIgnoreDifferences=true` 同步选项设置如下来更改此行为：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:

  ignoreDifferences:
  - group: "apps"
    kind: "Deployment"
    jsonPointers:
    - /spec/replicas

  syncPolicy:
    syncOptions:
    - RespectIgnoreDifferences=true
```

上面的示例显示了如何配置 Argo CD 应用程序，以便在同步阶段期间它将忽略期望状态（git）中的 `spec.replicas` 字段。这是通过在应用之前计算和预打补丁期望状态来实现的。请注意，仅当资源已在集群中创建时，`RespectIgnoreDifferences` 同步选项才有效。如果正在创建应用程序并且不存在实际状态，则期望状态将按原样应用。

## 创建命名空间

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  namespace: argocd
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: some-namespace
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
```

上面的示例显示了如何配置 Argo CD 应用程序，以便在不存在时创建 `spec.destination.namespace` 中指定的命名空间。如果不在应用程序清单中声明此选项或通过 `--sync-option CreateNamespace=true` 通过 CLI 传递，应用程序将无法同步，如果命名空间不存在。

请注意，要创建的命名空间必须在 Application 资源的 `spec.destination.namespace` 字段中进行通知。应用程序的子清单中的 `metadata.namespace` 字段必须与此值匹配，或者可以省略，以便在适当的目标中创建资源。

### 命名空间元数据

我们还可以通过 `managedNamespaceMetadata` 向命名空间添加标签和注释。如果我们扩展上面的示例，我们可以像下面这样做：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  namespace: test
spec:
  syncPolicy:
    managedNamespaceMetadata:
      labels: # 要设置在应用程序命名空间上的标签
        any: label
        you: like
      annotations: # 要设置在应用程序命名空间上的注释
        the: same
        applies: for
        annotations: on-the-namespace
    syncOptions:
    - CreateNamespace=true
```

为了使 ArgoCD 管理命名空间上的标签和注释，需要将 `CreateNamespace=true` 设置为同步选项，否则什么也不会发生。如果命名空间不存在，或者如果已经存在且没有在其上设置标签和/或注释，则可以继续执行。使用 `managedNamespaceMetadata` 还将在命名空间上设置资源跟踪标签（或注释），因此你可以轻松跟踪由 ArgoCD 管理的命名空间。

在 ArgoCD 管理的标签和注释上下文中，如果你没有自定义注释或标签，但仍希望有资源跟踪设置在你的命名空间上，那可以通过将 `managedNamespaceMetadata` 与空的 `labels` 和/或 `annotations` 映射来完成，如下例所示：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  namespace: test
spec:
  syncPolicy:
    managedNamespaceMetadata:
      labels: # 要设置在应用程序命名空间上的标签
      annotations: # 要设置在应用程序命名空间上的注释
    syncOptions:
    - CreateNamespace=true
```

在 ArgoCD "采用" 已经具有在其上设置元数据的现有命名空间的情况下，我们依赖使用服务器端应用程序，以便不会丢失已经设置的元数据。这里的主要影响是需要几个额外的步骤才能摆脱已经存在的字段。

想象一下我们有一个预先存在的命名空间，如下所示：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: foobar
  annotations:
    foo: bar
    abc: "123"
```

如果我们想要使用 ArgoCD 管理 `foobar` 命名空间，然后还要删除 `foo: bar` 注释，则在 `managedNamespaceMetadata` 中，我们需要先重命名 `foo` 值：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  syncPolicy:
    managedNamespaceMetadata:
      annotations:
        abc: 123 # 这个是 SSA 中的信息，无论如何在任何情况下都会保留，直到我们设置新值
        foo: remove-me
    syncOptions:
      - CreateNamespace=true
```

同步后，我们可以删除 `foo`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  syncPolicy:
    managedNamespaceMetadata:
      annotations:
        abc: 123 # 这个是 SSA 中的信息，无论如何在任何情况下都会保留，直到我们设置新值
    syncOptions:
      - CreateNamespace=true
```

另一个要注意的是，如果你在 ArgoCD 应用程序中有一个与命名空间的 k8s 清单相同的 k8s 清单，那么它将优先于 `managedNamespaceMetadata` 中设置的任何值，并将 *覆盖在 `managedNamespaceMetadata` 中设置的任何值*。换句话说，如果你有一个应用程序设置了 `managedNamespaceMetadata`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  syncPolicy:
    managedNamespaceMetadata:
      annotations:
        abc: 123
    syncOptions:
      - CreateNamespace=true
```

但是你还有一个 k8s 清单与之匹配的名称

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: foobar
  annotations:
    foo: bar
    something: completely-different
```

结果的命名空间将其注释设置为

```yaml
  annotations:
    foo: bar
    something: completely-different
```
