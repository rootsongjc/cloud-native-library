---
title: DNS Resolution at Edge
description: How to enable DNS resolution at XCP edge
---

If you use DNS hostname when configuring [`cluster-external-addresses` annotation](./configure-cluster-external-addresses) for [EastWest gateway](../../howto/gateway/multi_cluster_traffic_routing_with_eastwest_gateway), you need to enable DNS resolution at XCP edge so that DNS resolution will happen at XCP Edge. 

## Enable DNS resolution at XCP edge

To enable DNS resolution at XCP edge, you will need to
edit `xcp` component in `ControlPlane` CR or Helm values and add an environment variable `ENABLE_DNS_RESOLUTION_AT_EDGE` with value `true`:

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

Refer to [Multi-cluster traffic failover with EastWest Gateways](../../howto/gateway/multi_cluster_traffic_routing_with_eastwest_gateway) for how to enable EastWest routing .
