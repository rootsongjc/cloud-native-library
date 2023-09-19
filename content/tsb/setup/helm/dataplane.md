---
title: 数据平面安装
description: 如何使用 Helm 安装数据平面元素。
weight: 4
---

此图表安装 TSB 数据平面 Operator，用于管理 [网关](../../../refs/install/dataplane/v1alpha1/spec)，如 Ingress 网关、Tier-1 网关和 Egress 网关的生命周期。

{{<callout note 注意>}}
如果你正在使用基于版本的控制平面，则不再需要数据平面 Operator 来管理 Istio 网关。要了解有关基于版本的控制平面的更多信息，请参阅 [Istio 隔离边界](../../isolation-boundaries) 文档。
{{</callout>}}

## 安装

要安装数据平面 Operator，请运行以下 Helm 命令。确保将 `<tsb-version>` 和 `<registry-location>` 替换为正确的值。

```shell
helm install dp tetrate-tsb-helm/dataplane \
  --version <tsb-version> \
  --namespace istio-gateway --create-namespace \
  --set image.registry=<registry-location>
```

## 配置

### 镜像配置

这是一个 **必填** 字段。将 `image.registry` 设置为你的私有注册表位置，你已经同步了 TSB 镜像，将 `image.tag` 设置为要部署的 TSB 版本。

| 名称             | 描述                       | 默认值                     |
| ---------------- | -------------------------- | -------------------------- |
| `image.registry` | 用于下载 Operator 镜像的注册表 | `containers.dl.tetrate.io` |
| `image.tag`      | Operator 镜像的标签           | *与图表版本相同*           |

### Operator 扩展配置

这是一个 **可选** 字段。你可以使用以下可选属性自定义与 TSB Operator 相关的资源，如部署、服务或服务帐户：

| 名称                                           | 描述                                                         | 默认值 |
| ---------------------------------------------- | ------------------------------------------------------------ | ------ |
| `operator.deployment.affinity`                 | 用于 pod 的亲和性配置                                        |        |
| `operator.deployment.annotations`              | 自定义的注释集，用于添加到部署中                             |        |
| `operator.deployment.env`                      | 自定义的环境变量集，用于添加到容器中                         |        |
| `operator.deployment.podAnnotations`           | 自定义的注释集，用于添加到 pod 中                            |        |
| `operator.deployment.replicaCount`             | 部署管理的副本数量                                           |        |
| `operator.deployment.strategy`                 | 要使用的部署策略                                             |        |
| `operator.deployment.tolerations`              | 适用于 pod 调度的容忍集合                                    |        |
| `operator.deployment.podSecurityContext`       | [SecurityContext](../../../refs/install/kubernetes/k8s#tetrateio-api-install-kubernetes-podsecuritycontext) 用于应用于 pod 的属性 |        |
| `operator.deployment.containerSecurityContext` | [SecurityContext](../../../refs/install/kubernetes/k8s#tetrateio-api-install-kubernetes-securitycontext) 用于应用于 pod 的容器的属性 |        |
| `operator.service.annotations`                 | 自定义的注释集，用于添加到服务中                             |        |
| `operator.serviceAccount.annotations`          | 自定义的注释集，用于添加到服务帐户中                         |        |
| `operator.serviceAccount.imagePullSecrets`     | 需要能够从注册表中拉取镜像的密钥名称集合                     |        |
| `operator.pullSecret`                          | 将存储为图像拉取密钥的 Docker JSON 配置字符串                |        |
```