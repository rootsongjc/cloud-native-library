---
weight: 3
title: eBPF Map
date: '2022-06-17T12:00:00+08:00'
type: book
---

所有 BPF Map 都是有使用容量上限的。超出限制的插入将失败，从而限制了数据路径的可扩展性。下表显示了映射的默认值。每个限制都可以在源代码中更改。如果需要，将根据要求添加配置选项。

| Map 名称   | 范围       | 默认限制        | 规模影响                                                     |
| ---------- | ---------- | --------------- | ------------------------------------------------------------ |
| 连接跟踪   | 节点或端点 | 1M TCP/256k UDP | 最大 1M 并发 TCP 连接，最大 256k 预期 UDP 应答               |
| NAT        | 节点       | 512k            | 最大 512k NAT 条目                                           |
| 邻居表     | 节点       | 512k            | 最大 512k 邻居条目                                           |
| 端点       | 节点       | 64k             | 每个节点最多 64k 个本地端点 + 主机 IP                        |
| IP 缓存    | 节点       | 512k            | 最大 256k 端点（IPv4+IPv6），最大 512k 端点（IPv4 或 IPv6）跨所有集群 |
| 负载均衡器 | 节点       | 64k             | 跨所有集群的所有服务的最大 64k 累积后端                      |
| 策略       | 端点       | 16k             | 特定端点的最大允许身份 + 端口 + 协议对 16k                   |
| 代理 Map   | 节点       | 512k            | 最大 512k 并发重定向 TCP 连接到代理                          |
| 隧道       | 节点       | 64k             | 跨所有集群最多 32k 节点（IPv4+IPv6）或 64k 节点（IPv4 或 IPv6） |
| IPv4 分片  | 节点       | 8k              | 节点上同时传输的最大 8k 个分段数据报                         |
| 会话亲和性 | 节点       | 64k             | 来自不同客户端的最大 64k 关联                                |
| IP 掩码    | 节点       | 16k             | 基于 BPF 的 ip-masq-agent 使用的最大 16k IPv4 cidrs          |
| 服务源范围 | 节点       | 64k             | 跨所有服务的最大 64k 累积 LB 源范围                          |
| Egess 策略 | 端点       | 16k             | 跨所有集群的所有目标 CIDR 的最大 16k 端点                    |

对于某些 BPF 映射，可以使用命令行选项 `cilium-agent` 覆盖容量上限。可以使用 `--bpf-lb-map-max`、 `--bpf-ct-global-tcp-max`、`--bpf-ct-global-any-max`、 `--bpf-nat-global-max`、`--bpf-neigh-global-max`、`--bpf-policy-map-max`和 `--bpf-fragments-map-max` 来设置给定容量。

{{<callout note 提示>}}
如果指定了`--bpf-ct-global-tcp-max`和 / 或`--bpf-ct-global-any-max` ，则 NAT 表大小 ( `--bpf-nat-global-max`) 不得超过组合 CT 表大小（TCP + UDP）的 2/3。`--bpf-nat-global-max` 如果未显式设置或使用动态 BPF Map 大小（见下文），这将自动设置。
{{</callout>}}

使用 `--bpf-map-dynamic-size-ratio` 标志，几个大型 BPF Map 的容量上限在代理启动时根据给定的总系统内存比率确定。例如，给定的 0.0025 比率导致 0.25% 的总系统内存用于这些映射。

此标志会影响以下消耗系统中大部分内存的 BPF Map： `cilium_ct_{4,6}_global`、`cilium_ct_{4,6}_any`、 `cilium_nodeport_neigh{4,6}`、`cilium_snat_v{4,6}_external` 和 `cilium_lb{4,6}_reverse_sk`

`kube-proxy`根据机器拥有的内核数设置为 linux 连接跟踪表中的最大条目数。 无论机器有多少内核，`kube-proxy` 默认每个内核的最大条目数是 32768 和最小条目数是 131072。

Cilium 有自己的连接跟踪表作为 BPF Map，并且此类映射的条目数是根据节点中的总内存量计算的，无论机器有多少内存，条目最少数是 131072。

下表介绍了当 Cilium 配置为 `-bpf-map-dynamic-size-ratio: 0.0025` 时，`kube-proxy` 和 Cilium为自己的连接跟踪表设置的数值：

| 虚拟 CPU | 内存 (GiB) | Kube-proxy CT 条目 | Cilium CT 条目 |
| -------- | ---------- | ------------------ | -------------- |
| 1        | 3.75       | 131072             | 131072         |
| 2        | 7.5        | 131072             | 131072         |
| 4        | 15         | 131072             | 131072         |
| 8        | 30         | 262144             | 284560         |
| 16       | 60         | 524288             | 569120         |
| 32       | 120        | 1048576            | 1138240        |
| 64       | 240        | 2097152            | 2276480        |
| 96       | 360        | 3145728            | 4552960        |