---
weight: 5
title: 网络策略
date: '2022-06-17T12:00:00+08:00'
type: book
---

如果你在 Kubernetes 上运行 Cilium，你可以从 Kubernetes 为你分发的策略中受益。在这种模式下，Kubernetes 负责在所有节点上分发策略，Cilium 会自动应用这些策略。三种格式可用于使用 Kubernetes 本地配置网络策略：

- 在撰写本文时，标准的 [NetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#networkpolicy) 资源支持指定三层/四层入口策略，并带有标记为 beta 的有限出口支持。
- 扩展的 [CiliumNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumnetworkpolicy) 格式可用作 [CustomResourceDefinition](https://docs.cilium.io/en/stable/glossary/#term-customresourcedefinition) 支持入口和出口的三层到七层层策略规范。
- `CiliumClusterwideNetworkPolicy` 格式，[它](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumclusterwidenetworkpolicy)是集群范围的[CustomResourceDefinition](https://docs.cilium.io/en/stable/glossary/#term-customresourcedefinition)，用于指定由 Cilium 强制执行的集群范围的策略。规范与 [CiliumNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumnetworkpolicy) 相同，没有指定命名空间。

Cilium 支持同时运行多个策略类型。但是，在同时使用多种策略类型时应谨慎，因为理解跨多种策略类型的完整允许流量集可能会令人困惑。如果不注意，这可能会导致意外的策略允许行为。

## 网络策略

有关详细信息，请参阅官方 [NetworkPolicy 文档](https://kubernetes.io/docs/concepts/services-networking/network-policies/)。

Kubernetes 网络策略的已知缺失功能：

| 特征                      | GItHub Issue                                                 |
| ------------------------- | ------------------------------------------------------------ |
| `ipBlock`使用 pod IP 设置 | [GitHub Issue 9209](https://github.com/cilium/cilium/issues/9209) |
| SCTP                      | [GitHub Issue 5719](https://github.com/cilium/cilium/issues/5719) |

## Cilium 网络策略

CiliumNetworkPolicy 与 [标准 NetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#networkpolicy) 非常相似。目的是提供 NetworkPolicy 尚不支持的功能 。理想情况下，所有功能都将合并到标准资源格式中，并且不再需要此 CRD。

Go 中资源的原始规范如下所示：

``` go
type CiliumNetworkPolicy struct {
        // +deepequal-gen=false
        metav1.TypeMeta `json:",inline"`
        // +deepequal-gen=false
        metav1.ObjectMeta `json:"metadata"`

        // Spec is the desired Cilium specific rule specification.
        Spec *api.Rule `json:"spec,omitempty"`

        // Specs is a list of desired Cilium specific rule specification.
        Specs api.Rules `json:"specs,omitempty"`

        // Status is the status of the Cilium policy rule
        //
        // +deepequal-gen=false
        // +kubebuilder:validation:Optional
        Status CiliumNetworkPolicyStatus `json:"status"`
}
```

- metadata

  描述策略。这包括：策略的名称，在命名空间中是唯一的注入策略的命名空间一组标签来识别 Kubernetes 中的资源。

- spec

  包含[规则基础的字段](https://docs.cilium.io/en/stable/policy/intro/#policy-rule)。

- Specs

  包含[Rule Basics](https://docs.cilium.io/en/stable/policy/intro/#policy-rule)列表的字段。如果必须自动删除或添加多个规则，则此字段很有用。

- Status

  提供有关策略是否已成功应用的可视性。

## 例子

有关示例策略的详细列表，请参阅 [三层示例](https://docs.cilium.io/en/stable/policy/language/#policy-examples)、[四层示例](https://docs.cilium.io/en/stable/policy/language/#l4-policy)和 [七层](https://docs.cilium.io/en/stable/policy/language/#l7-policy) 示例。

[CiliumClusterwideNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumclusterwidenetworkpolicy) 类似于 [CiliumNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumnetworkpolicy)，除了

1. [ CiliumClusterwideNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumclusterwidenetworkpolicy) 定义的策略是非命名空间和集群范围的
2. 它允许使用[节点选择器](https://docs.cilium.io/en/stable/policy/intro/#nodeselector)。在内部，该策略与 [CiliumNetworkPolicy](https://docs.cilium.io/en/stable/concepts/kubernetes/policy/#ciliumnetworkpolicy) 相同，因此该策略规范的效果也相同。

go 中资源的原始规范如下所示：

``` go
type CiliumClusterwideNetworkPolicy struct {
        // Spec is the desired Cilium specific rule specification.
        Spec *api.Rule

        // Specs is a list of desired Cilium specific rule specification.
        Specs api.Rules

        // Status is the status of the Cilium policy rule.
        //
        // The reason this field exists in this structure is due a bug in the k8s
        // code-generator that doesn't create a `UpdateStatus` method because the
        // field does not exist in the structure.
        //
        // +kubebuilder:validation:Optional
        Status CiliumNetworkPolicyStatus
}
```
