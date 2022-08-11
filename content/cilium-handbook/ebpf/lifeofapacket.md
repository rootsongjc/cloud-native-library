---
weight: 2
title: 数据包流程
date: '2022-06-17T12:00:00+08:00'
type: book
---

## 端点到端点

首先，我们使用可选的七层出口和入口策略显示本地端点到端点的流程。随后是启用了套接字层强制的同一端点到端点流。为 TCP 流量启用套接字层实施后，启动连接的握手将遍历端点策略对象，直到 TCP 状态为 ESTABLISHED。然后在建立连接后，只需要七层策略对象。

![端点到端点的流程](../images/cilium_bpf_endpoint.svg "端点到端点的流程")

## 端点到出口

接下来，我们使用可选的 overlay 网络显示本地端点到出口。在可选的覆盖网络中，网络流量被转发到与 overlay 网络对应的 Linux 网络接口。在默认情况下，overlay 接口名为 `cilium_vxlan`。与上面类似，当启用套接字层强制并使用七层代理时，我们可以避免在端点和 TCP 流量的七层策略之间运行端点策略块。如果启用，可选的 L3 加密块将加密数据包。

![端点到出口的流程](../images/cilium_bpf_egress.svg "端点到出口的流程")

## 入口到端点

最后，我们还使用可选的 overlay 网络显示到本地端点的入口。与上述套接字层强制类似，可用于避免代理和端点套接字之间的一组策略遍历。如果数据包在接收时被加密，则首先将其解密，然后通过正常流程进行处理。

![入口到端点流程](../images/cilium_bpf_ingress.svg "入口到端点流程")

这样就完成了数据路径概述。更多 BPF 细节可以在 [BPF 和 XDP 参考指南](../../../bpf/)中找到。