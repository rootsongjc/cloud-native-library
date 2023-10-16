---
title: 优雅关闭 istio-proxy 连接
description: 如何优雅地关闭 `istio-proxy` sidecar 并减少正在处理的连接失败。
weight: 13
---

本文档解释了当删除一个启用了 `istio-proxy` sidecar 的 pod 时会发生什么，特别是连接是如何处理的，以及如何配置 sidecar 以优雅地处理正在进行的连接。

{{<callout note 注意>}}
本文档仅适用于 TSB 版本 <= `1.4.x`。
{{</callout>}}

在开始之前，请确保您已经完成了以下工作：

- 熟悉 [TSB 概念](../../concepts/)
- 安装了 TSB 环境。您可以使用 [TSB 演示](../../setup/requirements-and-download) 进行快速安装
- 完成了 [TSB 使用快速入门](../../quickstart)。本文假设您已经创建了租户并熟悉了工作区和配置组。另外，您需要将 tctl 配置到 TSB 环境 
- [安装 httpbin](../../reference/samples/httpbin#deploy-the-httpbin-pod-and-service)

当您发出删除请求来删除 Kubernetes 集群中的一个 pod 时，将发送 SIGTERM 给该 pod 中的所有容器。如果 pod 中仅包含一个容器，则它将接收到 SIGTERM 并进入终止状态。
然而，如果 pod 包含一个 sidecar（在我们的情况下是一个 `istio-proxy` sidecar），则不能自动保证主应用程序在 sidecar 之前终止。

如果在应用程序之前终止了 `istio-proxy` sidecar，可能会发生以下问题：

1. 所有 TCP 连接（包括入站和出站）都会突然终止。
2. 来自应用程序的任何连接将失败。

虽然有一个[针对此问题的提案 KEP](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/753-sidecar-containers)，但目前没有直接的方法告诉 Kubernetes 在 sidecar 之前终止应用程序。

但是，可以通过配置 [`drainDuration`](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/) 参数来解决此问题。此配置参数控制底层的 `envoy` 代理在完全终止之前排空正在进行的连接的时间。

要利用 `drainDuration` 参数，您需要在容器 sidecar 和 TSB 网关中都对其进行配置。

## 为 `istio-proxy` 容器配置 `drainDuration` 时间

您需要向 `ControlPlane` CR 或 Helm 值应用一个 overlay 来设置 `drainDuration`。考虑以下示例。注意，只显示了适用部分 -- 您很可能需要为控制平面配置更多内容。

```yaml
spec: 
  ...
  components:
    istio:
      kubeSpec:
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.meshConfig.defaultConfig.drainDuration
            value: 50s
  ...
```

在将 overlay 添加到配置后，使用 `kubectl` 命令将其应用于 `ControlPlane` CR：

```bash
kubectl apply -f controlplane.yaml
```

如果使用 Helm，可以更新控制平面 Helm 值的 `spec` 部分，然后执行 `helm upgrade`。

## 验证 `drainDuration`

必须重新启动具有 `istio-proxy` 的工作负载，以使 `drainDuration` 生效。一旦重新启动了工作负载，您可以通过检查 `envoy` 的配置转储来验证它：

```bash
kubectl exec helloworld-v1-59fdd6b476-pjrtr -n helloworld -c istio-proxy -- pilot-agent request GET config_dump |grep -i drainDuration
       "drainDuration": "50s",
```

## 为 TSB 网关配置 `drainDuration`

如果您使用的是 TSB 网关（例如 `IngressGateway`、`EgressGateway` 或 `Tier1Gateway`），则需要使用 `connectionDrainDuration` 参数配置适当的网关类型。

您可以通过发出以下命令来查询网关自定义资源上的 `connectionDrainDuration` 字段的当前值：

```bash
kubectl get ingress helloworld-gateway  -n helloworld -oyaml | grep connectionDrainDuration:
  connectionDrainDuration: 22s
```

以下示例显示了如何设置 `connectionDrainDuration`。请阅读规范以获取有关此字段的更多信息。

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: helloworld-gateway
spec:
  connectionDrainDuration: 10s
#  ... <snip> ...
```

## 在 TSB 网关中验证 `drainDuration`

要检查在 pod 上设置的 `drainDuration` 值，您可以查询环境变量：

```bash{pomptUser: alice}
kubectl describe po helloworld-gateway-7d5d4c8d57-msfd6 -n helloworld | grep -i DRAIN
      TERMINATION_DRAIN_DURATION_SECONDS:  22
```

您还可以在终止网关时查看网关 pod 的日志来验证此值。如果在终止网关 pod 时观察日志，您应该会看到类似以下的消息：

```
2022-03-29T06:02:50.423789Z     info    Graceful termination period is 22s, starting...
2022-03-29T06:03:12.423988Z     info    Graceful termination period complete, terminating remaining proxies.
```
