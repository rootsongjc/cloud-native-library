---
title: 配置保护
description: 如何为 TSB 创建的资源配置配置保护。
weight: 5
---

配置保护是一个功能，它有助于保护你的 Istio 配置免受意外更改。这允许你配置允许对 TSB 生成的 Istio 配置进行更改的用户，从而保护你的 Istio 配置免受意外更改的影响。默认情况下，拥有 Kube 命名空间特权的用户可以创建新的 Istio 配置或编辑 TSB 创建的配置。尽管用户管理的配置不会被更改，但当更改 TSB 管理的配置时，它们将在下一个同步周期中被 TSB 覆盖。

此功能有两个变体：
- `enableAuthorizedUpdateDeleteOnXcpConfigs`：允许用户创建和管理不受 TSB 管理的 Istio 配置。你可以将一组特定的用户添加到 authorizedUsers 列表中，以赋予这些用户编辑或删除 TSB 管理的配置的权限。
- `enableAuthorizedCreateUpdateDeleteOnXcpConfigs`：阻止未经授权的用户在集群中创建、更新或删除任何 Istio 配置。

你可以通过在你的 `ControlPlane` CR 中为 XCP 组件添加以下内容来配置允许对 TSB 生成的 Istio 配置进行更改的用户：

```yaml
 configProtection:
   enableAuthorizedUpdateDeleteOnXcpConfigs: true
   enableAuthorizedCreateUpdateDeleteOnXcpConfigs: true
   authorizedUsers:
     - user1
     - system:serviceaccount:ns1:serviceaccount-1
```

有关 ConfigProtection 配置的更多详细信息，请参阅以下部分[Config Protection](../../../refs/install/common/common-config#configprotection)。