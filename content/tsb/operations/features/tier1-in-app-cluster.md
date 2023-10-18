---
title: 在应用集群中启用 Tier1 网关
description: "如何在应用集群中启用 Tier1 网关。"
weight: 1
---

[Tier1 网关](../../../concepts/terminology#gateway) 用于使用 Istio mTLS 在其他集群中跨一个或多个入口网关（或 Tier2 网关）分发流量。在 1.6 版本之前，Tier1 网关需要一个专用集群，并且不能与其他网关（例如入口网关）或应用工作负载一起使用。

从 TSB 1.6 版本开始，你无需为运行 Tier1 网关而提供一个专用的集群。你可以在任何应用程序集群中部署 Tier1 网关。目前此功能默认处于禁用状态；在将来的版本中将默认启用。

## 在应用集群中启用 Tier1 网关

为了在应用集群中部署 Tier1 网关，你首先需要编辑 `ControlPlane` CR 或 Helm 值中的 `xcp` 组件，并添加一个名为 `DISABLE_TIER1_TIER2_SEPARATION` 的环境变量，其值为 `true`。

```yaml
spec:
  components:
    xcp:
      ...
      kubeSpec:
        overlays:
          - apiVersion: install.xcp.tetrate.io/v1alpha1
            kind: EdgeXcp
            name: edge-xcp
            patches:
              ...
              - path: spec.components.edgeServer.kubeSpec.deployment.env[-1]
                value:
                  name: DISABLE_TIER1_TIER2_SEPARATION
                  value: "true"
  ...
```

有关如何部署和配置 Tier1 网关的示例，请参阅[使用 Tier-1 网关进行多集群流量转移](../../../howto/gateway/multi-cluster-traffic-shifting)。