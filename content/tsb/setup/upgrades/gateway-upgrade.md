---
title: 网关升级
description: 如何使用多个版本升级网关。
weight: 3
---

在继续之前，请确保你熟悉 [Istio 隔离边界](../../isolation-boundaries) 功能。

# 升级方法

尽管默认情况下首选并假定使用原地网关升级，但你可以通过在 `ControlPlane` CR 或 Helm 值文件中设置 `ENABLE_INPLACE_GATEWAY_UPGRADE` 变量来控制以版本为基础的网关升级的两种方式。

1. `ENABLE_INPLACE_GATEWAY_UPGRADE=true` 是默认行为。在使用原地网关升级时，现有的网关部署将使用新的代理映像进行修补，并将继续使用相同的网关服务。这意味着你无需进行任何更改以配置网关的外部 IP。
2. `ENABLE_INPLACE_GATEWAY_UPGRADE=false` 意味着将创建一个新的网关服务和部署以进行金丝雀版本的升级，因此现在可能会有两个服务：
    1. `<网关名称>`/`<网关名称>-old`，负责处理非版本/旧版本控制平面工作负载流量。
    2. `<网关名称>-1-6-0`，负责处理版本控制平面工作负载流量，将为此新创建的 `<网关名称>-canary` 服务分配新的外部 IP。

  你可以通过使用外部负载均衡器或更新 DNS 条目来控制两个版本之间的流量。

由于原地网关升级是默认行为，你无需更改现有的 `ControlPlane` CR。要使用金丝雀网关升级，你需要在以下 `xcp` 组件中将 `ENABLE_INPLACE_GATEWAY_UPGRADE` 设置为 `false`：

```yaml
spec:
  ...
  components:
    xcp:
      kubeSpec:
        deployment:
          env:
          - name: ENABLE_INPLACE_GATEWAY_UPGRADE
            value: "false"        # 禁用原地升级以创建网关的金丝雀部署和服务
      isolationBoundaries:
      - name: global
        revisions:
        - name: 1-6-0
```

网关升级是通过更新 `Ingress/Egress/Tier1Gateway` 资源中的 `spec.revision` 字段来触发的。
如果 `ENABLE_INPLACE_GATEWAY_UPGRADE=false`，请注意，将会有另一组新版本的 Service/Deployment/其他对象，我们正在对其进行升级。
网关升级是通过更新 `Ingress/Egress/Tier1Gateway` 资源中的 `spec.revision` 字段来触发的。

```bash
kubectl get deployments -n bookinfo
```

```bash
# 输出
tsb-gateway-bookinfo          1/1     1            1           8m12s
tsb-gateway-bookinfo-1-6-0    1/1     1            1           4m19s
```

```bash
kubectl get svc -n bookinfo
```

```bash
# 输出
tsb-gateway-bookinfo          LoadBalancer   10.255.10.81   172.29.255.151   15443:31159/TCP,8080:31789/TCP,...
tsb-gateway-bookinfo-1-6-0    LoadBalancer   10.255.10.85   172.29.255.152   15443:31159/TCP,8080:31789/TCP,...
```

