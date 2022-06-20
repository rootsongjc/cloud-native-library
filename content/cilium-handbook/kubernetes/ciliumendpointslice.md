---
weight: 7
title: 端点切片 CRD
date: '2022-06-17T12:00:00+08:00'
type: book
---

在 Kubernetes 中管理 pod 时，Cilium 将为 Cilium 管理的每个 pod 创建一个 [`CiliumEndpoint`](../ciliumendpoint)（CEP）的自定义资源定义（CRD）。如果启用了 `enable-cilium-endpoint-slice`，那么 Cilium 还会创建一个 `CiliumEndpointSlice` （CES）类型的 CRD，将一组具有相同[安全身份](https://docs.cilium.io/en/stable/concepts/security/identity/#arch-id-security)的 CEP 对象分组到一个 CES 对象中，并广播 CES 对象来向其他代理传递身份，而不是通过广播 CEP 来实现。在大多数情况下，这减少了控制平面上的负载，可以使用相同的主资源维持更大规模的集群。

例如：

``` bash
$ kubectl get ciliumendpointslices --all-namespaces
NAME                  AGE
ces-548bnpgsf-56q9f   171m
ces-dy4d8x6j2-qgc2z   171m
ces-f6qfylrxh-84vxm   171m
ces-k29rv92f5-qb4sw   171m
ces-m9gs68csm-w2qg8   171m
```
