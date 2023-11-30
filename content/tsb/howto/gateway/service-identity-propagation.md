---
title: 多集群访问控制和身份传播
weight: 4
---

当流量通过网关转发时，通常会假定流量的身份为该网关的身份。这种默认行为简化了外部流量的访问控制配置。然而，在多集群环境中，通常需要更精细的访问控制。Tetrate Service Bridge（TSB）提供了通过网关跃点保留请求的原始身份的能力，从而实现跨集群身份验证和细粒度的访问控制。

本文档解释了如何在 TSB 中启用和利用身份传播，从而实现将消费者身份传播到远程服务、在不同集群之间实施详细的访问控制以及将访问控制规则应用于故障转移目标等场景。

在继续之前，假定你熟悉 TSB 的[概念](../../../concepts)和术语，如[入口网关、Tier-1 网关和东西网关](../../../concepts/glossary/)。

{{<callout note "GitOps">}}
本文档中的示例使用了 TSB 的 GitOps 功能，允许你使用 kubectl 应用 TSB 配置。要在你的 TSB 环境中启用 GitOps，请参见[启用 GitOps](../../../operations/features/configure-gitops)，并了解如何在 TSB 中使用 GitOps 工作流程的详细信息[GitOps 工作原理](../../../howto/gitops/gitops)。
{{</callout>}}

## 启用身份传播

默认情况下，由于网关处的 TLS 终止，服务身份不会通过网关跃点传播。TSB 使用每个网关跃点上的内部 WebAssembly（WASM）扩展实现身份传播。该扩展验证客户端身份并将其附加到请求的 XFCC 标头，然后将其转发。

要启用身份传播：

1. 在`ControlPlane` CR 或 Helm 值的`xcp`组件中添加`enableHttpMeshInternalIdentityPropagation`键：
```yaml
spec:
  ...
  components:
    xcp:
      centralAuthMode: JWT
      configProtection: {}
      enableHttpMeshInternalIdentityPropagation: true
      kubeSpec:
        ...
        ...
```

2. 在`ControlPlane` CR 或 Helm 值中配置 TSB 镜像注册表的`imagePullSecret`，这是必需的，以便拉取 WASM 扩展：
```yaml
spec:
  ...
  imagePullSecrets:
    - name: gcr-secret
  components:
    xcp:
      ...
      ...
```

## 验证身份传播

启用身份传播后，你可以通过检查 XCP 边缘中是否启用了`ENABLE_HTTP_MESH_INTERNAL_IDENTITY_PROPAGATION`来验证其状态：

```sh
kubectl get deployment edge -n istio-system -o yaml | grep ENABLE_HTTP_MESH_INTERNAL_IDENTITY_PROPAGATION -A 1
```

## 用例 1：通过 Tier 1 和 Tier 2 网关传播服务身份

在此用例中，我们演示了如何使用 Tier 1 和 Tier 2 网关在集群之间传播服务身份。

1. 配置两个集群，`cluster-1` 和 `cluster-2`，共享相同的信任根。按照[此处](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/)的指南和使用[此存储库](https://github.com/istio/istio/tree/master/tools/certs)设置 Istio 根和中间证书。

2. 在`tier-1` 集群中：
   - 创建一个专用集群，用于部署 `tier-1` 网关。
   - 配置[`networkReachability`](../multi-cluster-traffic-shifting#network-reachability)以建立`cluster-1`和`tier-1`，以及`tier-1`和`cluster-2`之间的可达性。

3. 在`cluster-1` 中：
   - 创建一个租户`tenant-1`，以及其命名空间、工作空间和组。
   - 在`tenant-1-ns`中部署[`sleep`](../../../reference/samples/sleep-service#deploy-the-sleep-pod-and-service) pod 或类似的文本客户端。

4. 在`cluster-2` 中：
   - 创建一个租户`tenant-2`，以及其命名空间、工作空间和组。
   - 在`tenant-2-ns`中部署[`bookinfo`](../../../quickstart/deploy-sample-app) 应用程序，以及一个[`入口网关`](../../../quickstart/ingress-gateway)。

5. 验证来自`cluster-1`中`sleep` pod 的请求是否可以通过 Tier 1 网关到达`cluster-2`中`bookinfo`应用程序的服务。

6. 通过使用适当的规则和设置，在不同级别的工作空间或租户之间拒绝通信，来实施访问控制。

## 用例 2：在东西网关故障转移中传播服务身份

在此用例中，我们关注在东西网关设置中的服务故障转移期间传播源身份。

1. 在`cluster-1` 中，为`Client`和`Bookinfo`租户创建命名空间。在`bookinfo-ns`中部署`bookinfo`和`bookinfo-gateway`服务。
2. 在`cluster-2` 中，为`Bookinfo`租户创建`bookinfo-ns`。在`bookinfo-ns`中部署`bookinfo`和`bookinfo-gateway`服务。
3. 使用`defaultEastWestGatewaySettings`配置`bookinfo-ns`/`bookinfo-gateway`以进行东西故障转移。
4. 实施`允许`和`拒绝`规则以控制不同租户和服务之间的通信。
5. 验证`Client`租户中的客户端是否可以访问适当的服务，同时强制执行访问控制。
6. 在服务故障转移场景中观察身份传播的行为。

## 故障排除

1. 确保`ControlPlane` CR 的`xcp`组件中正确设置了`enableHttpMeshInternalIdentityPropagation`。
2. 验证`ControlPlane` CR 中是否配置了`imagePullSecret`，以允许拉取必要的 WASM 扩展。
3. 确认已成功安装所需的 WASM 扩展在 Istio 环境中。
4. 确保 XFCC 标头传播正常工作。
5. 如果遇到问题，请参阅本页面末尾的故障排除部分以获取进一步的指导。
