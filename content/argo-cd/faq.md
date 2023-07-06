---
weight: 9
title: FAQ
date: '2023-06-30T16:00:00+08:00'
type: book
---

## 我删除/损坏了我的存储库，无法删除我的应用程序。

如果 Argo CD 无法生成清单，则无法删除应用程序。您需要：

1. 恢复/修复您的存储库。
2. 使用`cascade=false`删除应用程序，然后手动删除资源。

## 为什么我的应用程序在成功同步后仍然处于 `OutOfSync` 状态？

请查看 差异比较 文档，了解资源可能处于 `OutOfSync` 状态的原因，以及配置 Argo CD 忽略字段的方法 当存在不同之处时。

## 为什么我的应用程序一直处于“Progressing”状态？

Argo CD 为几种标准 Kubernetes 类型提供健康状态。 `Ingress`、`StatefulSet` 和 `SealedSecret` 类型存在已知问题，可能会导致健康检查返回 `Progressing` 状态而不是 `Healthy`。

- `Ingress` 如果 `status.loadBalancer.ingress` 列表是非空的，并且至少有一个值为 `hostname` 或 `IP`，则被视为健康状态。一些 Ingress 控制器（[contour](https://github.com/heptio/contour/issues/403)、[traefik](https://github.com/argoproj/argo-cd/issues/968#issuecomment-451082913)）不会更新 `status.loadBalancer.ingress` 字段，这会导致 `Ingress` 永久停留在 `Progressing` 状态。
- `StatefulSet` 如果 `status.updatedReplicas` 字段的值与 `spec.replicas` 字段匹配，则被视为健康状态。由于 Kubernetes bug [kubernetes/kubernetes#68573](https://github.com/kubernetes/kubernetes/issues/68573)，`status.updatedReplicas` 没有填充。因此，除非您运行包括修复程序 [kubernetes/kubernetes#67570](https://github.com/kubernetes/kubernetes/pull/67570) 的 Kubernetes 版本，否则 `StatefulSet` 可能会保持在 `Progressing` 状态。
- 您的 `StatefulSet` 或 `DaemonSet` 正在使用 `OnDelete` 而不是 `RollingUpdate` 策略。请参见 [#1881](https://github.com/argoproj/argo-cd/issues/1881)。
- 对于 `SealedSecret`，请参阅 为什么 `SealedSecret` 类型的资源处于 `Progressing` 状态？

作为解决方法，Argo CD 允许提供 健康检查 自定义，覆盖默认行为。

## 我忘记了管理员密码，如何重置密码？

对于 Argo CD v1.8 及更早版本，初始密码设置为服务器 pod 的名称，如 [入门指南](../gettting-started/) 中所述。对于 Argo CD v1.9 及更高版本，初始密码可从名为 `argocd-initial-admin-secret` 的 secret 中获取。

要更改密码，请编辑 `argocd-secret` secret，并使用新的 bcrypt 哈希更新 `admin.password` 字段。

{{<callout note "生成 bcrypt 哈希">}}

使用以下命令生成 `admin.password` 的 bcrypt 哈希：
```bash
argocd account bcrypt --password <YOUR-PASSWORD-HERE>
```
{{</callout>}}

要应用新的密码哈希，请使用以下命令（用您自己的哈希替换哈希）：

```bash
 # bcrypt(password)=$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa
 kubectl -n argocd patch secret argocd-secret \\\\
   -p '{"stringData": {
     "admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa",
```

另一个选项是删除 `admin.password` 和 `admin.passwordMtime` 两个键，然后重新启动 argocd-server。这将根据 [入门指南](../getting-started/) 生成新密码，因此要么使用 pod 名称 (Argo CD 1.8 及更早版本)，要么使用存储在 secret 中的随机生成的密码 (Argo CD 1.9 及更高版本)。

## 如何禁用管理员用户？

将 `admin.enabled: "false"` 添加到 `argocd-cm` ConfigMap 中 ( 参见 [用户管理](../user-guide/))。

## Argo CD 无法在没有互联网访问的情况下部署基于 Helm Chart 的应用程序，该怎么办？

如果 Helm Chart 有位于外部存储库中的依赖项，则 Argo CD 可能无法生成 Helm Chart 清单。要解决此问题，您需要确保 `requirements.yaml` 仅使用内部可用的 Helm 存储库。即使 chart 仅使用来自内部存储库的依赖项，Helm 也可能决定刷新 `stable` 存储库。作为解决方法，可以在 `argocd-cm` config map 中覆盖 `stable` 存储库 URL：

```yaml
 data:
   repositories: |
     - type: helm
       url: http://<internal-helm-repo-host>:8080
       name: stable
```

## 使用 Argo CD 部署 Helm 应用程序后，我无法使用 `helm ls` 和其他 Helm 命令看到它

在部署 Helm 应用程序时，Argo CD 仅使用 Helm 作为模板机制。它运行 `helm template`，然后在集群上部署生成的清单，而不是执行 `helm install`。这意味着您无法使用任何 Helm 命令查看/验证应用程序。它由 Argo CD 完全管理。请注意，Argo CD 支持一些 Helm 中可能缺少的本地功能（例如历史记录和回滚命令）。

做出这个决定是为了使 Argo CD 对所有清单生成器都是中立的。

## 我已经配置了 cluster secret，但是在 CLI/UI 中没有显示，我该如何修复？

检查集群机密是否具有 `argocd.argoproj.io/secret-type: cluster` 标签。如果机密具有该标签但仍然无法看到集群，则可能是权限问题。尝试使用 `admin` 用户列出集群 ( 例如，`argocd login --username admin && argocd cluster list`)。

## Argo CD 无法连接到我的集群，我该如何进行故障排除？

使用以下步骤重建配置的集群配置并使用 kubectl 手动连接到集群：

```bash
 kubectl exec -it <argocd-pod-name> bash # ssh 到任何 argocd 服务器 pod
 argocd admin cluster kubeconfig https://<cluster-url> /tmp/config --namespace argocd # 生成您的集群配置
 KUBECONFIG=/tmp/config kubectl get pods # 手动测试连接
```

现在，您可以手动验证 Argo CD pod 可以访问集群。

## 如何终止同步？

要终止同步，请单击“synchronisation”，然后单击“terminate”：

## 即使同步了，我的应用程序仍然“Out Of Sync”，为什么？

在某些情况下，您使用的工具可能会通过添加 `app.kubernetes.io/instance` 标签与 Argo CD 冲突。例如，使用 Kustomize 的常见标签功能。

Argo CD 自动设置 `app.kubernetes.io/instance` 标签，并使用它来确定哪些资源形成应用程序。如果工具也这样做，这会导致混淆。您可以通过在 `argocd-cm` configmap 中设置 `application.instanceLabelKey` 值来更改此标签。我们建议您使用 `argocd.argoproj.io/instance`。

🔔 提示：更改此设置后，您的应用程序将变为“不同步”，需要重新同步。

请参见 [#1482](https://github.com/argoproj/argo-cd/issues/1482)。

## Argo CD 每隔多长时间检查我的 Git 或 Helm 存储库中的更改？

默认轮询间隔为 3 分钟 (180 秒)。您可以通过更新 [argocd-cm](https://github.com/argoproj/argo-cd/blob/2d6ce088acd4fb29271ffb6f6023dbb27594d59b/docs/operator-manual/argocd-cm.yaml#L279-L282) config map 中的 `timeout.reconciliation` 值来更改此设置。如果有任何 Git 更改，ArgoCD 仅会更新启用了 auto-sync setting 的应用程序。如果将其设置为 `0`，则 Argo CD 将停止自动轮询 Git 存储库，您只能使用替代方法（例如 webhooks 和/或手动同步）来部署应用程序。

## 为什么我的资源限制“不同步”？

Kubernetes 在应用资源限制时对其进行了规范化，然后 Argo CD 比较了生成清单中的版本和 K8s 中的规范化版本 - 它们不会匹配。

例如：

- `'1000m'` 规范化为 `'1'`
- `'0.1'` 规范化为 `'100m'`
- `'3072Mi'` 规范化为 `'3Gi'`
- `3072` 规范化为 `'3072'` (添加引号)

要解决此问题，请使用差异化自定义[设置](../user-guide/diffing/)。

## 如何修复“invalid cookie, longer than max length 4093”？

Argo CD 使用 JWT 作为身份验证令牌。您可能是许多组的一部分，并超过了设置为 cookie 的 4KB 限制。您可以通过打开“开发人员工具->网络”来获取组列表：

- 单击登录
- 找到调用 `<argocd_instance>/auth/callback?code=<random_string>`

在 https://jwt.io/ 上解码令牌。这将提供您可以从中删除自己的团队列表。

请参见 [#2165](https://github.com/argoproj/argo-cd/issues/2165)。

## 在使用 CLI 时为什么会出现“rpc error: code = Unavailable desc = transport is closing”？

也许您在使用不支持 HTTP 2 的代理？尝试使用 `--grpc-web` 标志：

```bash
 argocd ... --grpc-web
```

## 在使用 CLI 时为什么会出现“x509: certificate signed by unknown authority”？

Argo CD 默认创建的证书未被 Argo CD CLI 自动识别，为了创建安全的系统，您必须遵循[安装证书](../operator-manual/tls/)的说明，并配置客户端操作系统以信任该证书。

如果您不在生产系统中运行（例如，您正在测试 Argo CD），请尝试使用 `--insecure` 标志：

```bash
 argocd ... --insecure
```

🔔 警告：不要在生产中使用 `--insecure`。

## 我已经通过 `dex.config` 在 `argocd-cm` 中配置了 Dex，但它仍然显示 Dex 未配置。为什么？

很可能您忘记将 `argocd-cm` 中的 `url` 设置为指向您的 ArgoCD。另请参见 [文档](../operator-manual/user-management/)。

## 为什么`SealedSecret`资源会报告`Status`?

`SealedSecret`的版本包括`v0.15.0`（特别是通过 helm `1.15.0-r3`）不包括现代 CRD，因此状态字段将不会在 k8s `1.16+`上公开。如果您的 Kubernetes 部署是[modern](https://www.openshift.com/blog/a-look-into-the-technical-details-of-kubernetes-1-16)，请确保使用固定的 CRD，如果您想要此功能工作。

## `SealedSecret`类型资源为什么停留在`Progressing`状态中？

`SealedSecret`资源的控制器可以在它提供的资源上公开状态条件。自`v2.0.0`版本以来，ArgoCD 会获取该状态条件以为`SealedSecret`推导出健康状态。

`SealedSecret`控制器的`v0.15.0`版本之前受到有关此状态条件更新的问题的影响，因此在这些版本中默认禁用此功能。可以通过使用`--update-status`命令行参数启动`SealedSecret`控制器或通过设置`SEALED_SECRETS_UPDATE_STATUS`环境变量来启用状态条件更新。

要禁用 ArgoCD 检查`SealedSecret`资源上的状态条件，请通过`resource.customizations.health.<group_kind>`键在`argocd-cm` ConfigMap 中添加以下资源自定义。

```
resource.customizations.health.bitnami.com_SealedSecret: |
 hs = {}
 hs.status = "Healthy"
 hs.message = "Controller doesn't report resource status"
 return hs
```

## 如何修复`The order in patch list … doesn't match $setElementOrder list: …`?

应用程序可能会触发一个同步错误，标记为`ComparisonError`，其消息如下：

> The order in patch list: [map[name:KEY_BC value:150] map[name:KEY_BC value:500] map[name:KEY_BD value:250] map[name:KEY_BD value:500] map[name:KEY_BI value:something]] doesn't match $setElementOrder list: [map[name:KEY_AA] map[name:KEY_AB] map[name:KEY_AC] map[name:KEY_AD] map[name:KEY_AE] map[name:KEY_AF] map[name:KEY_AG] map[name:KEY_AH] map[name:KEY_AI] map[name:KEY_AJ] map[name:KEY_AK] map[name:KEY_AL] map[name:KEY_AM] map[name:KEY_AN] map[name:KEY_AO] map[name:KEY_AP] map[name:KEY_AQ] map[name:KEY_AR] map[name:KEY_AS] map[name:KEY_AT] map[name:KEY_AU] map[name:KEY_AV] map[name:KEY_AW] map[name:KEY_AX] map[name:KEY_AY] map[name:KEY_AZ] map[name:KEY_BA] map[name:KEY_BB] map[name:KEY_BC] map[name:KEY_BD] map[name:KEY_BE] map[name:KEY_BF] map[name:KEY_BG] map[name:KEY_BH] map[name:KEY_BI] map[name:KEY_BC] map[name:KEY_BD]]

该消息有两个部分：

1. `The order in patch list: [`

   这标识了每个项目的值，特别是多次出现的项目的值：

   > map[name:KEY_BC value:150] map[name:KEY_BC value:500] map[name:KEY_BD value:250] map[name:KEY_BD value:500] map[name:KEY_BI value:something]

   您需要确定重复的键 -- 您可以专注于第一部分，因为每个重复的键将出现，每个值都与其值一起出现在第一个列表中。第二个列表实际上只是

   `]`

2. `doesn't match $setElementOrder list: [`

   这包括所有的键。为了调试目的，它被包含在内——您不需要太注意它。它将为您提供有关重复键的精确位置的提示：

   > map[name:KEY_AA] map[name:KEY_AB] map[name:KEY_AC] map[name:KEY_AD] map[name:KEY_AE] map[name:KEY_AF] map[name:KEY_AG] map[name:KEY_AH] map[name:KEY_AI] map[name:KEY_AJ] map[name:KEY_AK] map[name:KEY_AL] map[name:KEY_AM] map[name:KEY_AN] map[name:KEY_AO] map[name:KEY_AP] map[name:KEY_AQ] map[name:KEY_AR] map[name:KEY_AS] map[name:KEY_AT] map[name:KEY_AU] map[name:KEY_AV] map[name:KEY_AW] map[name:KEY_AX] map[name:KEY_AY] map[name:KEY_AZ] map[name:KEY_BA] map[name:KEY_BB] map[name:**KEY_BC**] map[name:**KEY_BD**] map[name:KEY_BE] map[name:KEY_BF] map[name:KEY_BG] map[name:KEY_BH] map[name:KEY_BI] map[name:**KEY_BC**] map[name:**KEY_BD**]

   `]`

在这种情况下，重复的键已被**加粗**以帮助您识别有问题的键。许多编辑器都有突出显示所有字符串实例的功能，使用这样的编辑器可以帮助解决此类问题。

此错误的最常见实例是针对`containers`的`env:`字段。

{{<callout note "动态应用程序">}}

可能您的应用程序是由工具生成的，因此在单个文件的范围内可能不会显现出重复。如果您在调试此问题时遇到麻烦，请考虑向生成器工具的所有者提交工单，要求他们改进其验证和错误报告功能。

{{</callout>}}
