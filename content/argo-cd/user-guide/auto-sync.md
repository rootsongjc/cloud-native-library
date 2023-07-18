---
draft: false
title: "自动同步策略"
weight: 12
---

Argo CD 具有在检测到 Git 中所需清单与集群中的实际状态之间存在差异时自动同步应用程序的功能。自动同步的好处是，CI/CD 管道不再需要直接访问 Argo CD API 服务器以执行部署。相反，管道将更改的清单提交并推送到跟踪 Git 存储库中。

要配置自动同步，请运行：

```bash
 argocd app set <APPNAME> --sync-policy automated
```

或者，如果创建应用程序清单，则使用 `automated` 策略指定 syncPolicy。

```yaml
 spec:
   syncPolicy:
     automated: {}
```

## 自动修整

默认情况下（作为一种安全机制），当 Argo CD 检测到资源不再在 Git 中定义时，自动同步不会删除资源。始终可以执行手动同步（并检查修整）来修整资源。也可以通过运行以下命令设置自动修整：

```bash
 argocd app set <APPNAME> --auto-prune
```

或通过在自动同步策略中将 `prune` 选项设置为 true：

```yaml
 spec:
   syncPolicy:
     automated:
       prune: true
```

## **带有允许空值的自动修整（v1.8）**

默认情况下（作为一种安全机制），自动修整具有保护机制，可防止出现任何自动化或人为错误，因为没有目标资源。它会防止应用程序具有空资源。要允许应用程序具有空资源，请运行：

```bash
 argocd app set <APPNAME> --allow-empty
```

或通过在自动同步策略中将 allowEmpty 选项设置为 true：

```yaml
 spec:
   syncPolicy:
     automated:
       prune: true
       allowEmpty: true
```

## **自动自愈**

默认情况下，对实时集群进行的更改不会触发自动同步。要在实时集群的状态偏离在 Git 中定义的状态时启用自动同步，请运行：

```bash
 argocd app set <APPNAME> --self-heal
```

或通过在自动同步策略中将 `selfHeal` 选项设置为 true：

```yaml
 spec:
   syncPolicy:
     automated:
       selfHeal: true
```

## **自动同步语义**

- 仅当应用程序处于 OutOfSync 状态时，才会执行自动同步。已同步或错误状态的应用程序不会尝试自动同步。
- 自动同步将仅针对每个唯一的提交 SHA1 和应用程序参数组合尝试一次同步。如果历史记录中最近的成功同步已经针对相同的提交 SHA 和参数执行，那么不会尝试第二个同步，除非将 `selfHeal` 标志设置为 true。
- 如果将 `selfHeal` 标志设置为 true，则在自我修复超时（默认为 5 秒）之后，将再次尝试同步，该超时由 `argocd-application-controller` 部署的 `self-heal-timeout-seconds` 标志控制。
- 如果上一个同步尝试针对相同的提交 SHA 和参数失败，则自动同步不会重新尝试同步。
- 无法对启用了自动同步的应用程序执行回滚。
- 自动同步间隔由 `argocd-cm` ConfigMap 中的 [`timeout.reconciliation`](https://argo-cd.readthedocs.io/en/stable/faq/#how-often-does-argo-cd-check-for-changes-to-my-git-or-helm-repository) 值确定，默认为 `180s`（3 分钟）。
