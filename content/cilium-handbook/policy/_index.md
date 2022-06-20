---
weight: 20
title: 网络策略
date: '2022-06-07T12:00:00+08:00'
type: book
hide_toc_title: true
---

本章记录了用于在 Cilium 中配置网络策略的策略语言。安全策略可以通过以下机制指定和导入：

- 使用 Kubernetes NetworkPolicy、`CiliumNetworkPolicy` 和 `CiliumClusterwideNetworkPolicy` 资源。更多细节请参见网络策略一节。在这种模式下，Kubernetes 将自动向所有代理分发策略。
- 通过代理的 CLI 或 API 参考直接导入到代理中。这种方法不会自动向所有代理分发策略。用户有责任在所有需要的代理中导入策略。

本章内容包括：

- [策略执行模式](intro/)
- [规则基础](intro/#rule-basics)
- [三层示例](https://docs.cilium.io/en/stable/policy/language/)
- [四层示例](https://docs.cilium.io/en/stable/policy/language/#layer-4-examples)
- [七层示例](https://docs.cilium.io/en/stable/policy/language/#layer-7-examples)
- [拒绝政策](https://docs.cilium.io/en/stable/policy/language/#deny-policies)
- [主机策略](https://docs.cilium.io/en/stable/policy/language/#host-policies)
- [七层协议可视性](visibility/)
- [在策略中使用 Kubernetes 构造](kubernetes/)
- [端点生命周期](lifecycle/)
- [故障排除](troubleshooting/)

{{< cta cta_text="阅读本章" cta_link="intro" >}}
