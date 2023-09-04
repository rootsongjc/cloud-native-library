---
title: 控制平面安装
description: 如何使用 Helm 安装控制平面组件。
weight: 3
---

此Chart安装 TSB 控制平面Operator以将集群引入。与[管理平面 Helm Chart](../managementplane)类似，它还允许你使用[TSB `ControlPlane` CR](../../refs/install/controlplane/v1alpha1/spec)安装 TSB 控制平面组件，以及使其正常运行所需的所有密钥。

在开始之前，请确保你已完成以下操作：

- 检查 [Helm 安装过程](../helm#installation-process)
- [已安装 TSB 管理平面](../managementplane)
- [使用 tctl 登录到管理平面](../tctl_connect)
- 安装 [yq](https://github.com/mikefarah/yq#install)。这将用于从创建集群响应中获取 Helm 值。

{{<callout note  "隔离边界">}}
TSB 1.6 引入了隔离边界，允许你在 Kubernetes 集群内或跨多个集群中拥有多个 TSB 管理的 Istio 环境。隔离边界的好处之一是你可以执行控制平面的金丝雀升级。

要启用隔离边界，你必须使用环境变量 `ISTIO_ISOLATION_BOUNDARIES=true` 更新Operator部署，并在控制平面 CR 中包括 `isolationBoundaries` 字段。
有关更多信息，请参见[隔离边界](../isolation-boundaries)。
{{</callout>}}

## 先决条件

在开始之前，你需要创建一个 [集群对象](../../refs/tsb/v2/cluster) 在 TSB 中表示你将安装 TSB 控制平面的集群。将 `<cluster-name-in-tsb>` 和 `<organization-name>` 替换为你的环境中的正确值：

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: <cluster-name-in-tsb>
  organization: <organization-name>
spec:
  displayName: "App Cluster"
```

要创建集群对象，请运行以下命令：

```bash
tctl apply -f cluster.yaml -o yaml | yq .spec.installTemplate.helm > cluster-cp-values.yaml
```

文件 cluster-cp-values.yaml 包含了 TSB 控制平面Operator的默认配置，包括与 TSB 管理平面进行身份验证所需的任何必要密钥。要自定义安装，你可以通过在继续下一步之前向此文件添加所需的额外配置值来修改此文件。

## 安装

使用以下 helm install 命令安装 TSB 控制平面。确保替换 `<tsb-version>` 和 `<registry-location>` 为正确的值。

```bash
helm install cp tetrate-tsb-helm/controlplane \
  --version <tsb-version> \
  --namespace istio-system --create-namespace \
  --timeout 5m \
  --values cluster-cp-values.yaml \
  --set image.registry=<registry-location>
```

等待 TSB 控制平面组件成功部署。要验证安装是否成功，你可以尝试登录到 TSB UI 或使用 [tctl](../tctl_connect) 连接到 TSB，然后检查集群列表，看看是否已经加入了集群。

## 故障排除

如果在安装过程中遇到任何问题，请尝试以下几种故障排除方法：

- 确保按照正确的顺序执行了所有步骤。
- 仔细检查 `cluster-cp-values.yaml` 文件中的配置值，确保它们是正确的。
- 检查 TSB 控制平面Operator的日志，查看是否有任何错误消息或堆栈跟踪，以帮助诊断问题。
- 如果你正在使用私有注册表来托管 TSB 控制平面Operator镜像，请确保已在

注册表进行了身份验证，并且 `image.registry` 值是正确的。
- 检查集群引入故障排除 [指南](../../../troubleshooting/cluster-onboarding)。

## 配置

### 镜像配置

这是一个 **必填** 字段。将 `registry` 设置为你同步了 TSB 镜像的私有注册表，将 `tag` 设置为要部署的 TSB 版本。仅指定此字段将安装 TSB 控制平面Operator，而不安装其他 TSB 组件。

| 名称             | 描述                       | 默认值                     |
| ---------------- | -------------------------- | -------------------------- |
| `image.registry` | 用于下载Operator镜像的注册表 | `containers.dl.tetrate.io` |
| `image.tag`      | Operator镜像的标签           | *与Chart版本相同*           |

### 控制平面资源配置

这是一个 **可选** 字段。你可以在 Helm 值文件中设置 [TSB `ControlPlane` CR](../../refs/install/controlplane/v1alpha1/spec)，以使 TSB 控制平面正常运行。

| 名称   | 描述                                  | 默认值 |
| ------ | ------------------------------------- | ------ |
| `spec` | 包含 `ControlPlane` CR 的 `spec` 部分 |        |

### 密钥配置

这是一个 **可选** 字段。你可以在安装 TSB 控制平面之前将密钥应用到你的集群，或者你可以使用 Helm 值来指定所需的密钥。请注意，如果要将密钥与控制平面规范分开，可以使用不同的 Helm 值文件。

{{<callout warning "注意">}}
请牢记这些选项只有助于创建密钥，并且必须遵守 TSB `ManagementPlane` CR 中提供的配置，否则安装将配置不正确。
{{</callout>}}

| 名称                                       | 描述                                                         | 默认值  |
| ------------------------------------------ | ------------------------------------------------------------ | ------- |
| `secrets.keep`                             | 启用此选项会在卸载Chart后使生成的密钥持久存在于集群中，如果它们在未来的更新中没有提供的话。（请参阅 [Helm 文档](https://helm.sh/docs/howto/charts_tips_and_tricks/#tell-helm-not-to-uninstall-a-resource)） | `false` |
| `secrets.tsb.cacert`                       | 用于验证公开的管理平面（前端 envoy）TLS 证书的 CA 证书       |         |
| `secrets.elasticsearch.username`           | 访问 Elasticsearch 的用户名                                  |         |
| `secrets.elasticsearch.password`           | 访问 Elasticsearch 的密码                                    |         |
| `secrets.elasticsearch.cacert`             | 控制平面用于验证 TLS 连接的 Elasticsearch CA 证书            |         |
| `secrets.oapToken`                         | 用于对接口进行身份验证的 JWT 令牌，该接口与管理平面（OAP）交互 |         |
| `secrets.otelToken`                        | 用于对接口进行身份验证的 JWT 令牌，该接口与管理平面（Otel Collector）交互 |         |
| `secrets.clusterServiceAccount.clusterFQN` | 集群资源的 TSB FQN。这将为所有控制平面代理生成令牌。         |         |
| `secrets.clusterServiceAccount.JWK`        | 用于生成和签名所有控制平面代理令牌的文字 JWK                 |         |
| `secrets.clusterServiceAccount.encodedJWK` | 用于生成和签名所有控制平面代理令牌的 Base64 编码 JWK         |         |

#### XCP 密钥配置

XCP 使用 JWT 进行 Edge 和 Central 之间的身份验证。

如果提供了 XCP 根 CA (`secrets.xcp.rootca`)，它将用于验证 XCP Central 提供的 TLS 证书。

此外，需要 `secrets.xcp.edge.token` 或 `secrets.clusterServiceAccount` 以对接 XCP Central 进行身份验证。

以下是允许用于配置 XCP 身份验证模式的配置属性：

| 名称                            | 描述                                                     | 默认值 |
| ------------------------------- | -------------------------------------------------------- | ------ |
| `secrets.xcp.rootca`            | XCP 组件的 CA 证书                                       |        |
| `secrets.xcp.edge.token`        | 用于对接 XCP Edge 和 XCP Central 进行身份验证的 JWT 令牌 |        |
| `secrets.clusterServiceAccount` | 用于生成和签名所有控制平面代理令牌的 Base64 编码 JWK     |        |

### Operator扩展配置

这是一个 **可选** 字段。你可以使用以下可选属性自定义 TSB Operator相关资源，如部署、服务或服务帐户：

| 名称                                           | 描述                                                         | 默认值 |
| ---------------------------------------------- | ------------------------------------------------------------ | ------ |
| `operator.deployment.affinity`                 | Pod 的亲和性配置                                             |        |
| `operator.deployment.annotations`              | 要添加到部署的自定义注释集                                   |        |
| `operator.deployment.env`                      | 要添加到容器的自定义环境变量集                               |        |
| `operator.deployment.podAnnotations`           | 要添加到 Pod 的自定义注释集                                  |        |
| `operator.deployment.replicaCount`             | 部署管理的副本数                                             |        |
| `operator.deployment.strategy`                 | 要使用的部署策略                                             |        |
| `operator.deployment.tolerations`              | 适用于 Pod 调度的耐受性集合                                  |        |
| `operator.deployment.podSecurityContext`       | 应用于 Pod 的 [SecurityContext](../../refs/install/kubernetes/k8s#tetrateio-api-install-kubernetes-podsecuritycontext) 属性 |        |
| `operator.deployment.containerSecurityContext` | 应用于 Pod 的容器的 [SecurityContext](../../refs/install/kubernetes/k8s#tetrateio-api-install-kubernetes-securitycontext) 属性 |       |
| `operator.service.annotations`                 | 要添加到服务的自定义注释集                   |       |
| `operator.serviceAccount.annotations`          | 要添加到服务帐户的自定义注释集               |       |
| `operator.serviceAccount.imagePullSecrets`     | 从注册表拉取镜像所需的密钥名称集合            |       |
| `operator.pullSecret`                          | JSON 编码的 Docker 配置，将存储为镜像拉取密钥 |       |