---
weight: 3
title: IP 地址伪装
date: '2022-06-17T12:00:00+08:00'
type: book
---

用于 Pod 的 IPv4 地址通常是从 RFC1918 私有地址块分配的，因此不可公开路由。Cilium 会自动将离开集群的所有流量的源 IP 地址伪装成节点的 IPv4 地址，因为节点的 IP 地址已经可以在网络上路由。

![IP 地址伪装示意图](../masquerade.png "IP 地址伪装示意图")

对于 IPv6 地址，只有在使用 iptables 实现模式时才会执行伪装。

可以使用 IPv4 选项和离开主机的 IPv6 流量禁用此行为。`enable-ipv4-masquerade: false``enable-ipv6-masquerade: false`

## 配置

- 设置可路由 CIDR

  默认行为是排除本地节点的 IP 分配 CIDR 内的任何目标。如果 pod IP 可在更广泛的网络中路由，则可以使用以下选项指定该网络：`ipv4-native-routing-cidr: 10.0.0.0/8 `，在这种情况下，该 CIDR 内的所有目的地都 **不会** 被伪装。

- 设置伪装接口

  请参阅[实现模式](https://docs.cilium.io/en/stable/concepts/networking/masquerading/#masq-modes)以配置伪装接口。

## 实现模式{#masq-modes}

### 基于 eBPF

基于 eBPF 的实现是最有效的实现。它需要 Linux 内核 4.19，并且可以使用 `bpf.masquerade=true` helm 选项启用。

当前的实现依赖于 [BPF NodePort 特性](https://docs.cilium.io/en/stable/gettingstarted/kubeproxy-free/#kubeproxy-free)。将来会删除该依赖项（[GitHub Issue 13732](https://github.com/cilium/cilium/issues/13732)）。

伪装只能在那些运行 eBPF 伪装程序的设备上进行。这意味着如果输出设备运行程序，从 pod 发送到外部的数据包将被伪装（到输出设备 IPv4 地址）。如果未指定，程序将自动附加到 [BPF NodePort 设备检测机制](https://docs.cilium.io/en/stable/gettingstarted/kubeproxy-free/#nodeport-devices)选择的设备上。要手动更改此设置，请使用 `devices` helm 选项。使用 `cilium status` 确定程序在哪些设备上运行：

```bash
$ kubectl exec -it -n kube-system cilium-xxxxx -- cilium status | grep Masquerading
Masquerading:   BPF (ip-masq-agent)   [eth0, eth1]  10.0.0.0/16
```

从上面的输出可以看出，程序正在 `eth0` 和 `eth1` 设备上运行。

基于 eBPF 的伪装可以伪装以下 IPv4 四层协议的数据包：

- TCP
- UDP
- ICMP（仅 Echo 请求和 Echo 回复）

默认情况下，来自 pod 的所有发往  `ipv4-native-routing-cidr` 范围外 IP 地址的数据包都会被伪装，但发往其他集群节点的数据包除外。排除 CIDR 显示在 （`cilium status` ) 的上述输出中（`10.0.0.0/16`）。

{{<callout note 提示>}}
启用 eBPF 伪装后，从 Pod 到集群节点外部 IP 的流量也不会被伪装。eBPF 实现在这方面不同于基于 iptables 的伪装。此限制在 [GitHub Issue 17177](https://github.com/cilium/cilium/issues/17177) 中进行了跟踪。
{{</callout>}}

为了实现更细粒度的控制，Cilium 在 eBPF 中实现了[ip-masq-agent](https://github.com/kubernetes-sigs/ip-masq-agent)，可以通过`ipMasqAgent.enabled=true` helm 选项启用。

基于 eBPF 的 `ip-masq-agent` 支持配置文件中设置的 `nonMasqueradeCIDRs` 和  `masqLinkLocal` 选项。从 pod 发送到属于任何 CIDR 的目的地的数据包 `nonMasqueradeCIDRs` 不会被伪装。如果配置文件为空，代理将配置以下非伪装 CIDR：

- `10.0.0.0/8`
- `172.16.0.0/12`
- `192.168.0.0/16`
- `100.64.0.0/10`
- `192.0.0.0/24`
- `192.0.2.0/24`
- `192.88.99.0/24`
- `198.18.0.0/15`
- `198.51.100.0/24`
- `203.0.113.0/24`
- `240.0.0.0/4`

此外，如果 `masqLinkLocal` 未设置或设置为 false，则 `169.254.0.0/16` 附加到非伪装 CIDR 列表中。

代理使用 Fsnotify 跟踪配置文件的更新，因此 `resyncInterval` 不需要原始选项。

下面的示例显示了如何通过配置代理 [`ConfigMap`](https://docs.cilium.io/en/stable/glossary/#term-configmap) 并对其进行验证：

```bash
$ cat agent-config/config
nonMasqueradeCIDRs:
- 10.0.0.0/8
- 172.16.0.0/12
- 192.168.0.0/16
masqLinkLocal: false

$ kubectl create configmap ip-masq-agent --from-file=agent-config --namespace=kube-system

$ # Wait ~60s until the ConfigMap is mounted into a cilium pod

$ kubectl -n kube-system exec -ti cilium-xxxxx -- cilium bpf ipmasq list
IP PREFIX/ADDRESS
10.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.168.0.0/16
```

{{<callout note>}}

IPv6 流量当前不支持基于 eBPF 的伪装。

{{</callout>}}

### 基于 iptables

这是适用于所有内核版本的遗留实现。

默认行为将伪装所有离开非 Cilium 网络设备的流量。这通常会导致正确的行为。为了限制应在其上执行伪装的网络接口，可以使用`egress-masquerade-interfaces: eth0` 选项。

{{<callout note 提示>}}
也可以指定接口前缀 `eth+`，匹配前缀的所有接口 `eth` 都将用于伪装。
{{</callout>}}
