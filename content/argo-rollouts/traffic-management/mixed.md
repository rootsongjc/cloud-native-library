---
weight: 10
title: "多提供方"
linkTitle: "多提供方"
date: '2023-06-21T16:00:00+08:00'
type: book
---

🔔 提示：自 Argo Rollouts v1.2 起提供了多个 trafficRouting。

多个提供程序的使用旨在涵盖一些情况，例如我们必须在南北和东西流量路由或需要使用多个提供程序的任何混合架构的情况下。

## 何时可以使用多个提供程序的示例

### 避免在 Ingress 控制器上注入 Sidecars

这是服务网格的常见要求，通过使用多个 trafficRoutings，你可以利用南北交通转移到 NGiNX 和西东交通转移到 SMI，避免将 Ingress 控制器添加到网格中。

### 避免操作 Ingress 中的主机 Header

将一些 Ingress 控制器添加到网格中的另一个常见副作用是使用这些网格主机标头将其指向网格主机名以进行路由。

### 避免大爆炸

这发生在存在的机群中，其中停机时间非常短或几乎不可能。为了避免[大爆炸采用](https://en.wikipedia.org/wiki/Big_bang_adoption)，使用多个提供程序可以缓解团队如何逐步实施新技术。例如，现有机群正在使用提供程序（例如大使），已经在其推出的一部分中使用金丝雀方式进行南北方向的金丝雀测试，可以逐渐实现更多提供程序，例如 Istio，SMI 等。

### 混合方案

在这种情况下，它非常类似于避免大爆炸，无论是作为平台路线图的一部分还是架构的新重新设计，都有多种情况需要使用多个 trafficRoutings 的能力：逐步实施，简化架构回滚，甚至为了回退。

## 要求

使用多个提供程序要求两个提供程序分别独立地符合其最低要求。例如，如果要使用 Nginx 和 SMI，则需要同时安装 SMI 和 Nginx，并为两者生成推出配置。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: rollouts-demo
spec:
  strategy:
    canary:
      canaryService: rollouts-demo-canary # 引用指向金丝雀 ReplicaSet 的 Service
      stableService: rollouts-demo-stable # 引用指向稳定 ReplicaSet 的 Service
      trafficRouting:
        nginx:
          stableIngress: rollouts-demo-stable # 引用指向稳定 Service 的 Ingress，以便进行 NGINX 流量分离
        smi: {}
```

