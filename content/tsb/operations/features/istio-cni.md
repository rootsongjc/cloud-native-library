---
title: Istio CNI
description: 如何配置 Istio 控制平面以使用 Istio CNI 插件
weight: 3
---

默认情况下，Istio 会将 sidecar 代理注入到应用程序的 pod 中，以便处理该 pod 的流量。这些 sidecar 需要成为特权容器，因为它们需要在 pod 网络命名空间中操作 `iptables` 规则，以便拦截进出该 pod 的流量。

从安全性的角度来看，这种默认行为并不理想，因为它实际上授予了应用程序 pod 使用这些高级权限的权限。Istio 提供的替代方案是使用 [CNI 插件](https://istio.io/docs/setup/additional-setup/cni/)，它在 pod 创建时处理 pod 网络命名空间的修改。

## 在控制平面中启用 Istio CNI

为了在你的控制平面中启用 Istio CNI 插件，你需要编辑 `ControlPlane` CR 或 Helm 值，以包括 CNI 配置。

```yaml
spec:
  components:
    istio:
      kubeSpec:
        CNI:
          chained: true
          binaryDirectory: /opt/cni/bin
          configurationDirectory: /etc/cni/net.d
      traceSamplingRate: 100
  hub: <registry-location>
  managementPlane:
    host: <tsb-address>
    port: <tsb-port>
    clusterName: <cluster-name>
  telemetryStore:
    elastic:
      host: <elastic-hostname-or-ip>
      port: <elastic-port>
      version: <elastic-version>
```

上述片段显示了默认的 `ControlPlane` CR，其中包含了 `spec.components.istio.kubeSpec.CNI` 的附加部分。这将配置 Istio 控制平面以部署遵循所提供配置的 CNI 插件。

{{<callout note 注意>}}
配置值可能会根据你使用的 Kubernetes 发行版而发生变化，请参考[Istio 文档](https://istio.io/docs/setup/additional-setup/cni/)了解更多信息。
{{</callout>}}

{{<callout note 注意>}}
Istio CNI 也可以绑定到特定的 Istio 修订版，然后可以从一个 Istio 修订版升级到另一个。请参考 [Istio CNI 升级](../../../setup/upgrades/cni-upgrade)了解更多信息。
{{</callout>}}