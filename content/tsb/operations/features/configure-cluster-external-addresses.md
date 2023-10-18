---
title: 配置集群外部地址
description: 提供用于从集群外部访问网关服务的外部地址。
weight: 8
---

此功能允许通过 IngressGateway 或 Tier1Gateway 安装 CR 覆盖已注册集群的外部地址。然后将使用提供的 IP 地址/主机名从外部世界访问集群。请注意，此功能仅在你已经配置了其他 IP 地址/主机名以从外部世界访问你的 Kubernetes 集群时才有用。

## 数据平面

要在 IngressGateway 中使用此功能，请在你的 IngressGateway 安装（数据平面）CR 中的 `kubeSpec/service` 下设置 `xcp.tetrate.io/cluster-external-addresses` 注释，并使用 kubectl 应用它。你可以使用：
- 单个 IP 地址
- 单个 DNS 名称
- 多个 IP 地址（以逗号分隔）

但你不能配置多个 DNS 名称或将 IP 地址与 DNS 名称组合在一起。

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

上述 CR 将为网关服务设置 `kubernetesExternalAddresses` 为 `10.10.10.10` 和 `20.20.20.20`。你可以通过检查 Ingressgateway 中公开的主机名的 Service Entry 来验证此行为。