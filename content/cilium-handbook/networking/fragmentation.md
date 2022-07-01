---
weight: 4
title: IPv4 分片处理
date: '2022-06-17T12:00:00+08:00'
type: book
---

默认情况下，Cilium 将 eBPF 数据路径配置为执行 IP 分片跟踪，以允许不支持分片的协议（例如 UDP）通过网络透明地传输大型消息。IP 分片跟踪在 eBPF 中使用 LRU（最近最少使用）映射实现，需要 Linux 4.10 或更高版本。可以使用以下选项配置此功能：

- `--enable-ipv4-fragment-tracking`：启用或禁用 IPv4 分片跟踪。默认启用。
- `--bpf-fragments-map-max`：控制使用 IP 分片的最大活动并发连接数。对于默认值，请参阅[eBPF Maps](https://docs.cilium.io/en/stable/concepts/ebpf/maps/#bpf-map-limitations)。

**注意**

当使用 `kube-proxy` 运行 Cilium 时，碎片化的 NodePort 流量可能会由于内核错误而中断，其中路由 MTU 不受转发数据包的影响。纤毛碎片跟踪需要第一个逻辑碎片首先到达。由于内核错误，可能会在外部封装层上发生额外的碎片，从而导致数据包重新排序并导致无法跟踪碎片。

内核错误已被 [修复](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=02a1b175b0e92d9e0fa5df3957ade8d733ceb6a0) 并向后移植到所有维护的内核版本。如果您发现连接问题，请确保您的节点上的内核包最近已升级，然后再报告问题。

{{<callout note 提示>}}
这是一个测试版功能。如果你遇到任何问题，请提供反馈并提交 GitHub Issue。
{{</callout>}}

{{< cta cta_text="下一章" cta_link="../security" >}}
