---
title: Gateway Upgrades
description: How to upgrade gateways using multiple revisions
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

Before you continue, make sure you are familiar with [Istio Isolation Boundaries](../isolation-boundaries) feature.

# Approaches

Although the upgrades by default prefer and assume in-place Gateway upgrades, there are two ways you can upgrade Gateways with revisioned control plane and you can control this by setting `ENABLE_INPLACE_GATEWAY_UPGRADE` variable for XCP component in `ControlPlane` CR or Helm values file. 

1. `ENABLE_INPLACE_GATEWAY_UPGRADE=true` is the default behavior. When using in-place gateway upgrade, existing gateway deployment will be patched with new proxy image and will continue using the same gateway service. This means you don't have to make any changes to configure the gateway external IP.  
2. `ENABLE_INPLACE_GATEWAY_UPGRADE=false` means that a new gateway service and deployment for the canary version will be created, so now there could be two services:
    1. `<gateway-name>`/`<gateway-name>-old` which is handling the non-revisioned/old-revisioned control plane workload traffic.
    2. `<gateway-name>-1-6-0` which is handling the revisioned control plane workload traffic, a new external IP will be allocated to this newly created `<gateway-name>-canary` service.
  
  You can control traffic between two versions by using external load balancers or by updating DNS entry.

Since In-place gateway upgrade is default behavior you don't need to change existing `ControlPlane` CR. To use Canary gateway upgrade, you need to set `ENABLE_INPLACE_GATEWAY_UPGRADE` to `false` in `xcp` component below:  

```yaml
spec:
  ...
  components:
    xcp:
      kubeSpec:
        deployment:
          env:
          - name: ENABLE_INPLACE_GATEWAY_UPGRADE
            value: "false"        # Disable in-place upgrade to create canary deployment and service for gateway
      isolationBoundaries:
      - name: global
        revisions:
        - name: 1-6-0
```

Gateway upgrades are triggered by updating the `spec.revision` field in the `Ingress/Egress/Tier1Gateway` resource.
With `ENABLE_INPLACE_GATEWAY_UPGRADE=false` notice that there will be another set of Service/Deployment/other objects for the new revisioned that we are upgrading to.
The Gateway upgrade is triggered by updating the `spec.revision` field in `Ingress/Egress/Tier1Gateway` resources.

```bash{promptUser:alice}
kubectl get deployments -n bookinfo
```
```bash{promptUser:alice}
# Output
tsb-gateway-bookinfo          1/1     1            1           8m12s
tsb-gateway-bookinfo-1-6-0    1/1     1            1           4m19s
```

```bash{promptUser:alice}
kubectl get svc -n bookinfo
```
```bash{promptUser:alice}
# Output
tsb-gateway-bookinfo          LoadBalancer   10.255.10.81   172.29.255.151   15443:31159/TCP,8080:31789/TCP,...
tsb-gateway-bookinfo-1-6-0    LoadBalancer   10.255.10.85   172.29.255.152   15443:31159/TCP,8080:31789/TCP,...
```
