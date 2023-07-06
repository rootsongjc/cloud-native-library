---
title: "第六章：eBPF 工具"
weight: 6
type: book
date: '2022-06-02T12:00:00+08:00'
---

现在你已经了解了什么是 eBPF 以及它是如何工作的，我们再探索一些可能会在生产部署中使用的基于 eBPF 技术的工具。我们将举一些基于 eBPF 的开源项目的例子，这些项目提供了三方面的能力：网络、可观测性和安全。

## 网络

eBPF 程序可以连接到网络接口和内核的网络堆栈的各个点。在每个点上，eBPF 程序可以丢弃数据包，将其发送到不同的目的地，甚至修改其内容。这就实现了一些非常强大的功能。让我们来看看通常用 eBPF 实现的几个网络功能。

### 负载均衡

Facebook 正在大规模的使用 eBPF 的网络功能，因此你不必对 eBPF 用于网络的可扩展性有任何怀疑。他们是 BPF 的早期采用者，并在 2018 年推出了 [Katran](https://engineering.fb.com/2018/05/22/open-source/open-sourcing-katran-a-scalable-network-load-balancer/)，一个开源的四层负载均衡器。

另一个高度扩展的负载均衡器的例子是来自 Cloudflare 的 [Unimog](https://blog.cloudflare.com/unimog-cloudflares-edge-load-balancer/) 边缘负载均衡器。通过在内核中运行，eBPF 程序可以操作网络数据包，并将其转发到适当的目的地，而不需要数据包通过网络堆栈和用户空间。

Cilium 项目作为一个 eBPF Kubernetes 网络插件更为人所知（我一会儿会讨论），但作为独立的负载均衡器，它也被用于大型电信公司和企业内部部署。同样，因为它能够在早期阶段处理数据包，而不需要进入到用户空间，它具有很高的性能。

### Kubernetes 网络

CNCF 项目 Cilium 最初基于 eBPF 的 CNI 实现。它最初是由一群从事 eBPF 工作的内核维护者发起的，他们认识到 eBPF 在云原生网络中的应用潜力。它现在被用作谷歌 Kubernetes 引擎、亚马逊 EKS Anywhere 和阿里云的默认数据平面。

在云原生环境下，pod 在不断的启停，每个 pod 都会被分配一个 IP 地址。在启用 eBPF 网络之前，当 pod 启停的时候，每个节点都必须为它们更新 iptables 规则，以便在 pod 之间进行路由；而当这些 iptable 规则规模变大后，将十分不便于管理。如 [图 6-1](#figure-f-6-1) 所示，Cilium 极大地简化了路由，仅需在 eBPF 中创建的一个简单的查找表，就可以获得 [可观的性能改进](https://cilium.io/blog/2021/05/11/cni-benchmark/)。

另一个在传统的 iptables 版本之外还增加了 eBPF 实现的 Kubernetes CNI 是 [Calico](https://github.com/projectcalico/calico)。

{{<figure title="图 6-1. 用 eBPF 绕过主机网络堆栈" alt="图 6-1" id="f-6-1" src="../images/f-6-1.jpg" >}}

### 服务网格

eBPF 作为服务网格数据平面的基础也是非常有意义的。许多服务网格在七层，即应用层运行，并使用代理组件（如 Envoy）来辅助应用程序。在 Kubernetes 中，这些代理通常以 sidecar 模式部署，每个 pod 中有一个代理容器，这样代理就可以访问 pod 的网络命名空间。正如你在 [第五章](../ebpf-in-cloud-native-environments) 中看到的，eBPF 有一个比 sidecar 模型更有效的方法。由于内核可以访问主机中所有 pod 的命名空间，我们可以使用 eBPF 连接 pod 中的应用和主机上的代理，如 [图 6-2](#figure-f-6-2) 所示。

{{<figure title="图 6-2. eBPF 实现了服务网格的高效无 sidecar 模型，每个节点一个代理，而不是每个应用 pod 一个代理" src="../images/f-6-2.jpg" id="f-6-2" alt="图 6-2" >}}

我还有一篇关于使用 eBPF 实现更高效的服务网格数据平面的文章，Solo.io 上也有发布过类似文章。在写这篇文章的时候，Cilium 服务网格已进入测试阶段，并显示出比传统的 sidecar 代理方法具有更大的 [性能提升](https://isovalent.com/blog/post/2021-12-08-ebpf-servicemesh)。

## 可观测性

正如你在本报告前面所看到的，eBPF 程序可以获得对机器上发生的一切的可观测性。通过收集事件数据并将其传递给用户空间，eBPF 实现了一系列强大的可观测性工具，可以向你展示你的应用程序是如何执行和表现的，而不需要对这些应用程序做任何改变。

在本报告的前面，你已经看到了 BCC 项目，几年来，Brendan Gregg 在 Netflix 做了开创性的工作，展示了这些 eBPF 工具如何被用来 [观测我们感兴趣的几乎任何指标](https://www.brendangregg.com/)，而且是大规模和高性能的。

Kinvolk 的 [Inspektor Gadget](https://github.com/kinvolk/inspektor-gadget) 将其中一些起源于 BCC 的工具带入了 Kubernetes 的世界，这样你就可以在命令行上轻松观测特定的工作负载。

新一代的项目和工具正在这项工作的基础上，提供基于 GUI 的观测能力。CNCF 项目 [Pixie](https://px.dev/) 可以让你运行预先写好的或自定义的脚本，通过一个强大的、视觉上吸引人的用户界面查看指标和日志。因为它是基于 eBPF 的，这意味着你可以自动检测所有应用程序，获得性能数据，而无需进行任何代码修改或配置。[图 6-3](#figure-f-6-3) 显示的只是 Pixie 中众多可视化的一个例子。

{{<figure title="图 6-3. 一个小型 Kubernetes 集群上运行的所有东西的 Pixie 火焰图" alt="图 6-3" id="f-6-3" src="../images/f-6-3.jpg" >}}

另一个名为 [Parca](https://github.com/parca-dev/parca) 的可观测性项目专注于连续剖析，使用 eBPF 对 CPU 使用率等指标进行有效采样，可以用来检测性能瓶颈。

Cilium 的 [Hubble](https://github.com/cilium/hubble) 组件是一个具有命令行界面和用户界面的可观测性工具（如 [图 6-4](#figure-f-6-4) 所示），它专注于 Kubernetes 集群中的网络流。

{{<figure title="图 6-4. Cilium 的 Hubble 用户界面显示了 Kubernetes 集群中的网络流量" src="../images/f-6-4.jpg" id="f-6-4" alt="图 6-4" >}}

在云原生环境中，IP 地址不断被动态重新分配，基于 IP 地址的传统网络观测工具的作用非常有限。作为一个 CNI，Cilium 可以访问工作负载身份信息，这意味着 Hubble 可以显示由 Kubernetes pod、服务和命名空间标识的服务映射和流量数据。这对于诊断网络问题十分有用。

能够观测到活动，这是安全工具的基础，这些工具将正在发生的事情与策略或规则相比较，以了解该活动是预期的还是可疑的。让我们来看看一些使用 eBPF 来提供云原生安全能力的工具。

## 安全

有一些强大的云原生工具，通过使用 eBPF 检测甚至防止恶意活动来增强安全性。我将其分为两类：一类是确保网络活动的安全，另一类是确保应用程序在运行时的预期行为。

### 网络安全

由于 eBPF 可以检查和操纵网络数据包，它在网络安全方面有许多用途。基本原理是，如果一个网络数据包被认为是恶意的或有问题的，因为它不符合一些安全验证标准，就可以被简单地丢弃。eBPF 可以很高效的来验证这一点，因为它可以钩住内核中网络堆栈的相关部分，甚至在网卡上 [^1]。这意味着策略外的或恶意的数据包可以在产生网络堆栈处理和传递到用户空间的处理成本之前被丢弃。

这里有一个 eBPF 早期在生产中大规模使用的一个例子 —— [Cloudflare](https://blog.cloudflare.com/how-to-drop-10-million-packets/) 的 DDoS（分布式拒绝服务）保护。DDoS 攻击者用许多网络信息淹没目标机，希望目标机忙于处理这些信息，导致无法提供有效工作。Cloudflare 的工程师使用 eBPF 程序，在数据包到达后立即对其进行检查，并迅速确定一个数据包是否是这种攻击的一部分，如果是，则将其丢弃。数据包不必通过内核的网络堆栈，因此需要的处理资源要少得多，而且目标可以应对更大规模的恶意流量。

eBPF 程序也被用于动态缓解”死亡数据包“的内核漏洞 [^2]。攻击者以这样的方式制作一个网络工作数据包——利用了内核中的一个错误，使其无法正确处理该数据包。与其等待内核补丁的推出，不如通过加载一个 eBPF 程序来缓解攻击，该程序可以寻找这些特别制作的数据包并将其丢弃。这一点的真正好处是，eBPF 程序可以动态加载，而不必改变机器上的任何东西。

在 Kubernetes 中，[网络策略](https://networkpolicy.io/) 是一等资源，但它是由网络插件来执行的。一些 CNI，包括 Cilium 和 Calico，为更强大的规则提供了扩展的网络策略功能，例如允许或禁止流量到一个由完全限定域名而不是仅仅由 IP 地址指定的目的地。在 [app.networkpolicy.io](https://app.networkpolicy.io/) 有一个探索网络策略及其效果的好工具，如 [图 6-5](#figure-f-6-5) 所示。

{{<figure title="图 6-5. 网络策略编辑器显示了一个策略效果的可视化表示" src="../images/f-6-5.jpg" id="f-6-5" alt="图 6-5" >}}

标准的 Kubernetes 网络策略规则适用于进出应用 pod 的流量，但由于 eBPF 对所有网络流量都有可视性，它也可用于主机防火墙功能，限制进出主机（虚拟机）的流量 [^3]。

eBPF 也可以被用来提供透明的加密，无论是通过 WireGuard 还是 IPsec [^4]。在这里，**透明** 意味着应用程序不需要任何修改 —— 事实上，应用程序可以完全不知道其网络流量是被加密的。

### 运行时安全

eBPF 也被用来构建工具，检测恶意程序，防止恶意行为。这些恶意程序包括访问未经许可的文件，运行可执行程序，或试图获得额外的权限。

事实上，你很可能已经以 seccomp 的形式使用了基于 BPF 的安全策略，这是一个 Linux 功能，限制应用程序可以调用的系统调用集。

CNCF 项目 [Falco](https://falco.org/) 扩展了这种限制应用程序可以进行系统调用的想法。Falco 的规则定义是用 YAML 创建的，这比 seccomp 配置文件更容易阅读和理解。默认的 Falco 驱动是一个内核模块，但也有一个 eBPF 探针驱动，它与”原始系统调用“事件相联系。它不会阻止这些系统调用的完成，但它可以生成日志或其他通知，提醒操作人员注意潜在的恶意程序。

正如我们在 [第三章](../ebpf-programs) 中看到的，eBPF 程序可以附加到 LSM 接口上，以防止恶意行为或修复已知的漏洞。例如，Denis Efremov 写了一个 [eBPF 程序](https://github.com/evdenis/lsm_bpf_check_argc0) 来防止 `exec()` 系统调用在没有传递任何参数的情况下运行，以修复 PwnKit [^5] 的高危漏洞。eBPF 也可用于缓解投机执行的”Spectre“攻击 [^6]。

[Tracee](https://github.com/aquasecurity/tracee) 是另一个使用 eBPF 的运行时安全开源项目。除了基于系统调用的检查之外，它还使用 LSM 接口。这有助于避免受到 [TOCTTOU 竞争](https://lwn.net/Articles/245630/) 条件的影响，因为只检查系统调用时可能会出现这种情况。Tracee 支持用 Open Policy Agent 的 Rego 语言定义的规则，也允许用 Go 定义的插件规则。

Cilium 的 [Tetragon](https://github.com/cilium/tetragon) 组件提供了另一种强大的方法，使用 eBPF 来监控 **容器安全可观测性的四个黄金信号**：进程执行、网络套接字、文件访问和七层网络身份。这使操作人员能够准确地看到所有恶意或可疑事件，直击特定 pod 中的可执行文件名称和用户身份。例如，如果你受到加密货币挖矿的攻击，你可以看到到底是什么可执行程序打开了与矿池的网络连接，什么时候，从哪个 pod。这些取证是非常有价值的，可以了解漏洞是如何发生的，并使其容易建立安全策略，以防止类似的攻击再次发生。

如果你想更深入地了解 eBPF 的安全可观测性这一主题，请查看 Natália Ivánkó 和 Jed Salazar 的报告 [^7]。请关注云原生 eBPF 领域，因为不久之后我们就会看到利用 BPF LSM 和其他 eBPF 定制的工具来提供安全执行和可以观测能力。

我们在网络、可观测性和安全方面对几个云原生工具进行了考察。与前几代相比，eBPF 的使用为它们两个关键优势：

1. 从内核中的有利位置来看，eBPF 程序对所有进程都有可视性。
2. 通过避免内核和用户空间执行之间的转换，eBPF 程序为收集事件数据或处理网络数据包提供了一种极其有效的方式。

这并不意味着我们应该使用 eBPF 来处理所有的事情！在 eBPF 中编写特定业务的应用程序是没有意义的，就像我们不可能将应用程序写成内核模块一样。但是也有一些例外情况，比如对于高频交易这样对性能有极高的情况下。正如我们在本章中所看到的那样，eBPF 主要是用于为其他应用程序提供工具。

## 参考

[^1]: 有些网卡或驱动支持 XDP 或 eXpress Data Path 钩子，允许 eBPF 程序完全从内核中卸载出来。
[^2]: Daniel Borkmann 在他的[演讲](https://www.youtube.com/watch?v=Qhm1Zn_BNi4&ab_channel=eBPF%26CiliumCommunity)中讨论了这个问题，《BPF 更适合作为数据平面》（eBPF 峰会（线上），2020 年）。
[^3]: 见 Cilium 的主机防火墙[文档](https://docs.cilium.io/en/stable/gettingstarted/host-firewall/)。
[^4]: Tailscale 有这两种加密协议的[比较](https://tailscale.com/kb/1173/ipsec-vs-wireguard/)。
[^5]: 见 Bharat Jogi 的[博客](https://blog.qualys.com/vulnerabilities-threat-research/2022/01/25/pwnkit-local-privilege-escalation-vulnerability-discovered-in-polkits-pkexec-cve-2021-4034)，《PwnKit: 本地权限升级漏洞》（Qualys，2022 年 1 月 25 日）。
[^6]: 见 Daniel Borkmann 的[演讲](https://www.youtube.com/watch?v=6N30Yp5f9c4&ab_channel=eBPF%26CiliumCommunity)，《BPF 和 Spectre：缓解瞬时执行攻击问题》（eBPF 峰会（线上），2021 年 8 月 18-19 日）。
[^7]: Natália Ivánkó 和 Jed Salazar，《[Security Observability with eBPF](https://learning.oreilly.com/library/view/security-observability-with/9781492096719/)》（O’Reilly，2022）。

