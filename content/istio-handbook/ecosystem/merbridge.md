---
weight: 30
title: Merbridge
date: '2022-05-18T00:00:00+08:00'
type: book
---

[Merbridge](https://github.com/merbridge/merbridge) 是由 DaoCloud 在 2022 年初开源的的一款利用 eBPF 加速 Istio 服务网格的插件。使用 Merbridge 可以在一定程度上优化数据平面的网络性能。

## 使用条件

要想使用 Merbridge，你的系统必须满足以下条件：

- Istio 网格中的主机使用 Linux 5.7 及以上版本内核

## 原理

在 [Istio 中的透明流量劫持详解](../concepts/transparent-traffic-hijacking.md)中，我们谈到 Istio 默认使用 IPtables 拦截数据平面中的流量到 Envoy 代理，这种拦截方式通用性最强。因为 Pod 中所有的 inbound 和 outbound 流量都会先通过 Envoy 代理，尤其是 Pod 接收的流量，都要先通过 IPtables 将流量劫持到 Envoy 代理后再发往 Pod 中的应用容器的端口。

![使用 IPtables 劫持流量发到当前 Pod 的应用端口](../../images/to-localhost.png "使用 IPtables 劫持流量发到当前 Pod 的应用端口")

利用 eBPF 的 sockops 和 redir 能力，可以直接将数据包从 inbound socket 传输到 outbound socket。eBPF 提供了 `bpf_msg_redirect_hash` 函数可以直接转发应用程序的数据包。

下图展示的是在不同主机上的 Pod 的利用 eBPF 来劫持流量的示意图。

![使用 Merbridge 的在不同主机上的 Pod](../../images/diff-host.png "使用 Merbridge 的在不同主机上的 Pod")

Pod 内部的流量劫持使用的是 Merbridge，而不同主机间依然需要使用 IPtables 来转发流量。

如果两个 Pod 位于同一台主机，那么流量转发全程都可以通过 Merbridge 完成。下图展示了的是在同一主机上使用 Merbridge 的示意图。

![使用 Merbridge 的同一个主机上的 Pod](../../images/same-host.png "使用 Merbridge 的同一个主机上的 Pod")

关于 Merbridge 原理的详细解释请参考 [Istio 文档](https://istio.io/latest/blog/2022/merbridge/)。

## 如何使用

只需要在 Istio 集群执行一条命令，即可直接使用 eBPF 代替 iptables 做透明流量拦截，实现网络加速。而且这对 Istio 是无感的，你可以随时安装和卸载 Merbridge。使用下面的命令启用 Merbridge：

```sh
kubectl apply -f https://raw.githubusercontent.com/merbridge/merbridge/main/deploy/all-in-one.yaml
```

Merbridge 是以 DaemonSet 的方式运行在 Istio 网格的每个节点上。它运行在服务网格的下层，对于 Istio 是透明的，要启用它时，无需对 Istio 做任何改动。

如果你想删除 Merbridge，请运行下面的命令：

```bash
kubectl delete -f https://raw.githubusercontent.com/merbridge/merbridge/main/deploy/all-in-one.yaml
```

## 参考

- [Merbridge - Accelerate your mesh with eBPF - istio.io](https://istio.io/latest/blog/2022/merbridge/)

{{< cta cta_text="下一章" cta_link="../../practice/" >}}