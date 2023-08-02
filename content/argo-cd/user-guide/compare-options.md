---
draft: false
weight: 15
title: "对比选项"
date: '2023-06-30T16:00:00+08:00'
---

## 忽略无关资源

>v1.1

在某些情况下，你可能希望从应用程序的整体同步状态中排除资源。例如。如果它们是由工具生成的。这可以通过在你想要排除的资源上添加此注释来完成：

```yaml
metadata:
  annotations:
    argocd.argoproj.io/compare-options: IgnoreExtraneous
```

![对比选项需要修整](../../assets/compare-option-ignore-needs-pruning.png)

🔔 提示：这仅影响同步状态。如果资源的运行状况降级，那么应用程序也会降级。

Kustomize 具有允许你生成配置映射的功能（[了解更多](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/configGeneration.md)）。你可以设置 `generatorOptions` 添加此注释，以便你的应用保持同步：

```yaml
configMapGenerator:
  - name: my-map
    literals:
      - foo=bar
generatorOptions:
  annotations:
    argocd.argoproj.io/compare-options: IgnoreExtraneous
kind: Kustomization
```

🔔 提示：`generatorOptions` 向配置映射和秘密添加注释（[了解更多](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/generatorOptions.md)）。

你可能希望将其与 [`Prune=false` 同步选项](../sync-options/) 结合起来。
