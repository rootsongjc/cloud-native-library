---
title: Configure cluster external addresses
description: Provide external addresses for accessing the gateway service from outside the cluster.
---

This feature allows overriding of external addresses of onboarded clusters through IngressGateway or Tier1Gateway install CR. The provided
IP addresses/hostnames will then be used to access the clusters from the outside world.
Note that this feature is useful only when you have some other IP address/hostname already configured to access your kubernetes
cluster from the outside world.

## Data Plane

To use this feature with IngressGateway, set the `xcp.tetrate.io/cluster-external-addresses` annotation under `kubeSpec/service` in your IngressGateway
install (DataPlane) CR and apply it with kubectl. You can use:
- Single IP address
- Single DNS name
- Multiple IP addresses (comma separated)

But you can't configure multiple DNS names or combine an IP address with a DNS name.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo
  namespace: bookinfo
spec:
  kubeSpec:
    deployment:
      hpaSpec:
        maxRepicas: 10
        minReplicas: 1
        metrics:
        - resource:
            name: cpu
            targetAverageUtilization: 75
          type: Resource
      replicaCount: 1
      strategy:
        rollingUpdate:
          maxUnavailable: 0
        type: RollingUpdate
    service:
      annotations:
        xcp.tetrate.io/cluster-external-addresses: "10.10.10.10,20.20.20.20"
      ports:
      - name: mtls
        port: 15443
        targetPort: 15443
      - name: http2
        port: 80
        targetPort: 8080
      - name: https
        port: 443
        targetPort: 8443
      type: NodePort
```

The above CR will set the `kubernetesExternalAddresses` to `10.10.10.10` and `20.20.20.20` for the gateway service.
You can verify this behaviour by checking at the Service Entry generated for the hostname exposed in the Ingressgateway.
