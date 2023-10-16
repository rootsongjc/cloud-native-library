---
title: Edge 处的 DNS 解析
description: 如何在 XCP 边缘启用 DNS 解析。
weight: 6
---

如果在配置[东西向网关](../../../howto/gateway/multi_cluster_traffic_routing_with_eastwest_gateway)的[`cluster-external-addresses` 注释](../configure-cluster-external-addresses)时使用 DNS 主机名，您需要在 XCP 边缘启用 DNS 解析，以便 DNS 解析在 XCP 边缘发生。

## 在 XCP 边缘启用 DNS 解析

要在 XCP 边缘启用 DNS 解析，您需要在 `ControlPlane` CR 或 Helm 值中编辑 `xcp` 组件，并添加一个名为 `ENABLE_DNS_RESOLUTION_AT_EDGE` 的环境变量，并将其值设置为 `true`：

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
                  name: ENABLE_DNS_RESOLUTION_AT_EDGE
                  value: "true"
  ...
```

有关如何启用东西部路由的详细信息，请参阅[使用东西向网关进行多集群流量故障转移](../../../howto/gateway/multi-cluster-traffic-routing-with-eastwest-gateway)。