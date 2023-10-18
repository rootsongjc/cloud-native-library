---
title: 网关删除保持 Webhook
description: 如何启用网关删除保持 Webhook 以保持删除操作并允许配置更改在所有集群间传播。
weight: 4
---

如果删除网关（例如在缩容事件期间），远程集群将继续尝试将流量发送到网关 IP 地址，直到它们收到网关的 IP 地址已被移除的更新为止。这可能会导致 HTTP 流量的 `503` 错误或直通跨集群流量的 `000` 错误。

自 TSB 1.6 版以来，你可以通过可配置的周期来延迟网关删除，以便提供足够的时间使网关的 IP 地址移除传播到其他集群，以避免 `503` 或 `000` 错误。目前，此功能默认处于禁用状态。

## 启用网关删除保持 Webhook

为了在控制平面中启用网关删除保持 Webhook，你需要编辑 `ControlPlane` CR 或 Helm 值中的 `xcp` 组件，并添加以下环境变量：

1. `ENABLE_GATEWAY_DELETE_HOLD`，将其值设置为 `true`
2. `GATEWAY_DELETE_HOLD_SECONDS`。这是可选的，默认值为 10 秒

```yaml
spec:
  components:
    xcp:
      ...
      kubeSpec:
        deployment:
          env:
            - name: ENABLE_GATEWAY_DELETE_HOLD
              value: "true"
            - name: GATEWAY_DELETE_HOLD_SECONDS
              value: "20"
  ...
```

这将在删除的网关 IP 从远程集群中移除时延迟网关删除 20 秒。