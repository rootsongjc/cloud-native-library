---
title: 仓库机密
description: 配置 TSB 以从远程私有仓库获取容器镜像。
weight: 12
---

从版本 1.5 开始，TSB 提供了一种自动获取来自远程私有 Docker 容器仓库的镜像的方式，方法是在 [ManagementPlane](../../refs/install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanespec) 和 [ControlPlane](../../refs/install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-controlplanespec) CRs 中定义 `imagePullSecrets`。
如果定义了 `imagePullSecrets`，则将使用秘密中的凭据对必需的 ServiceAccounts 进行补丁，从而允许安全地访问存储在远程私有仓库中的容器。以下步骤概述了配置过程：

## 同步镜像

TSB 镜像位于 Tetrate 的仓库中，只能复制到你的仓库（不允许直接在任何环境中下载）。第一步是将镜像传输到你的仓库。要同步镜像，你需要按照 [文档](../../setup/requirements-and-download) 使用 `tctl install image-sync`（需要 Tetrate 提供的许可密钥）。

## 获取私有仓库的 JSON 密钥

指定为 `imagePullSecrets` 的秘密将存储凭据，允许 Kubernetes 从私有仓库中拉取所需的容器。获取凭据的方式取决于仓库。请参考以下链接以获得主要云提供商的指导 - [AWS](https://medium.com/clarusway/how-to-use-images-from-a-private-container-registry-for-kubernetes-aws-ecr-hosted-private-13a759e2c4ea)、[GCP](https://blog.container-solutions.com/using-google-container-registry-with-kubernetes) 和 [Azure](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes)。

## 在 TSB 使用的每个命名空间中创建机密

如 [Kubernetes 文档](https://kubernetes.io/docs/concepts/configuration/secret/#details) 中所述，机密只能被在其创建的相同命名空间中的 pod 访问。因此，必须为 TSB 使用的每个命名空间创建一个单独的机密。请注意，可用的命名空间可能会根据 Kubernetes 平台而变化。

目前，以下命名空间需要一个单独的机密：

- 对于 TSB 管理平面集群 `tsb` 和 `cert-manager`（如果使用内部 TSB 打包的 cert-manager）
- 对于 TSB 控制平面集群 `istio-system`、`istio-gateway`、`cert-manager`（如果使用内部 TSB 打包的 cert-manager）和 `kube-system`（如果使用 Istio CNI）

{{<callout note 附加的命名空间>}}
上述提供的列表不是详尽无遗的。不同平台上可能会使用额外的命名空间来运行 TSB 组件，因此需要创建单独的机密。要检查是否有任何 pod 无法获取容器镜像的问题，可以使用命令 `kubectl get pods -A | grep ImagePullBackOff`。
{{</callout>}}

## 应用程序命名空间

为了确保启用 Istio 的应用程序能够下载镜像，需要在每个启用了 Istio Sidecar 的 pod 和 Ingress Gateway 的应用程序命名空间中存在仓库凭据机密。

## 安装 TSB 

要安装 TSB，请使用你喜欢的方法，但确保 ManagementPlane 和 ControlPlane CRs 配置为如下所示的 `imagePullSecrets`：

```yaml
  spec:
    ...
    imagePullSecrets:
    - name: <在上一步中创建的机密名称>
    ...
```

## 补丁 Operator ServiceAccounts

在 Operator 能够将 `imagePullSecrets` 传播到其余组件之前，TSB Operator 的镜像需要凭据。

步骤如下：
- 补丁 `istio-system` 和 `istio-gateway` 命名空间中 TSB 运算符的 ServiceAccounts：

    ```bash
    kubectl patch serviceaccount tsb-operator-control-plane -p '{"imagePullSecrets": [{"name": "<在上述步骤中创建的机密名称>"}]}' -n istio-system
    kubectl patch serviceaccount tsb-operator-data-plane -p '{"imagePullSecrets": [{"name": "<在上述步骤中创建的机密名称>"}]}' -n istio-gateway
    ```

- 在这些命名空间中重新启动运算符：

    ```bash
    kubectl delete pod -n istio-system -l=name=tsb-operator 
    kubectl delete pod -n istio-gateway -l=name=tsb-operator
    kubectl delete pod -n istio-gateway -l=name=istio-operator
    ```

{{<callout note "Helm chart 安装">}}
可以使用 [Helm 安装](../helm) 自动执行创建机密和定义 `imagePullSecrets` 的步骤。
{{</callout>}}
{{<callout note 步骤的顺序>}}
非常重要的是，在安装 TSB 之前创建私有仓库的 Kubernetes 机密。遵循这个正确的顺序将允许有效的部署并将任何停机时间降到最低。
{{</callout>}}
