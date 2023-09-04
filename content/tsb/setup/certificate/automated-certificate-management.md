---
title: 自动证书管理
description: 描述如何为 TSB 使用自动证书管理
weight: 3
---

TSB 支持为 TSB 组件进行自动证书管理。你可以启用 TSB 以创建自签名根 CA，用于签发证书，例如 TSB 管理平面的 TLS 证书，用于控制平面与管理平面之间的通信的 [内部证书](../certificate-requirements)，以及应用程序集群的中间 CA 证书，Istio 在集群中将使用它们来签发应用程序工作负载的证书。

{{<callout note "外部根 CA">}}
目前，TSB 的自动证书管理不支持使用外部根 CA。将来的版本将添加对外部根 CA 的支持。

{{</callout>}}

## 启用自动证书管理

要启用自动证书管理，你需要在 TSB 管理平面 CR 或 helm values 中设置 `certIssuer` 字段：

```yaml
spec:
  certIssuer:
    selfSigned: {}
    tsbCerts: {}
    clusterIntermediateCAs: {}
```

`certIssuer` 字段是一个你要启用的证书颁发者的映射。目前，TSB 支持以下颁发者：
1. `selfSigned`：这将创建一个自签名的根 CA，用于签发 TSB 组件的证书。
1. `tsbCerts`：这将为 TSB 端点提供 TSB TLS 证书，还将提供 TSB 内部证书。
1. `clusterIntermediateCAs`：这将为应用程序集群提供中间 CA 证书，Istio 将在集群中使用它们来签发应用程序工作负载的证书。

要启用自动集群中间 CA 证书管理，还需要在 TSB 控制平面 CR 或 helm values 中设置 `centralProvidedCaCert` 字段：

```yaml
spec:
  ...
  components:
    xcp:
      ...
      centralProvidedCaCert: true
```

## 使用外部证书管理

如果要使用外部证书提供程序，你需要从 TSB 管理平面 CR 或 helm values 中的 `certIssuer` 字段中删除相关的颁发者以避免冲突。例如：

1. 要使用 Let's Encrypt 提供 TSB TLS 证书，请从 `certIssuer` 字段中删除 `tsbCerts`。请注意，如果禁用此选项，还需要提供 TSB [内部证书](../certificate-requirements)。
1. 要使用 AWS PCA 提供集群中间 CA，请从 `certIssuer` 字段中删除 `clusterIntermediateCAs`，并在 TSB 控制平面 CR 或 helm values 中将 `centralProvidedCaCert` 设置为 `false`。

如果计划同时为 `tsbCerts` 和 `clusterIntermediateCAs` 使用外部证书管理，则可以从 TSB 管理平面 CR 或 helm values 中删除 `certIssuer` 字段。

## 证书轮换

TSB 将自动轮换 TSB 组件和应用程序集群的证书。集群中间 CA 证书每年轮换一次。TSB TLS 和内部证书每 90 天轮换一次。目前，TSB 不提供配置轮换周期的方法。