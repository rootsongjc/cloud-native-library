---
title: Tier1 Gateway in an App Cluster
description: How to enable a Tier1 Gateway in an application cluster
---

A [Tier1 gateway](../../concepts/terminology#gateway) is used to distribute traffic across one or more ingress gateways (or Tier2 gateways) in other clusters using Istio mTLS. Prior to the 1.6 release, a Tier1 gateway required a dedicated cluster and could not be located with other gateways (e.g ingress gateways) or application workloads. 

Since TSB 1.6, you don't need to provision a dedicated cluster to run a Tier1 gateway. You can deploy a Tier1 gateway in any of your application clusters. Currently this feature is disabled by default; it will be enabled by default in a future release.

## Enable Running Tier1 Gateway in App Cluster

In order to deploy a Tier1 gateway gateway in an application cluster, you will first need to
edit the `xcp` component in the `ControlPlane` CR or Helm values and add an environment variable `DISABLE_TIER1_TIER2_SEPARATION` with value `true`

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

Refer to [Multi-cluster traffic shifting with Tier-1 Gateway](../../howto/gateway/multi-cluster-traffic-shifting) for an example of how to deploy and configure a Tier1 gateway.
