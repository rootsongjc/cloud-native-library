---
weight: 10
title: Aeraki
date: '2022-05-18T00:00:00+08:00'
type: book
---

[Aeraki](https://github.com/aeraki-framework/aeraki) 是腾讯云在 2021 年 3 月开源的一个服务网格领域的项目。Aeraki 提供了一个端到端的云原生服务网格协议扩展解决方案，以一种非侵入的方式为 Istio 提供了强大的第三方协议扩展能力，支持在 Istio 中对 Dubbo、Thrift、Redis，以及对私有协议进行流量管理。Aeraki 的架构如下图所示：

![Aeraki架构图](../../images/aeraki-arch.png "Aeraki架构图")

来源：<https://istio.io/latest/blog/2021/aeraki/>

从 Aeraki 架构图中可以看到，Aeraki 协议扩展解决方案包含了两个组件：

- Aeraki：Aeraki 作为一个 Istio 增强组件运行在控制面，通过自定义 CRD 向运维提供了用户友好的流量规则配置。Aeraki 将这些流量规则配置翻译为 Envoy 配置，通过 Istio 下发到数据面的 sidecar 代理上。Aeraki 还作为一个 RDS 服务器为数据面的 MetaProtocol Proxy 提供动态路由。Aeraki 提供的 RDS 和 Envoy 的 RDS 有所不同，Envoy RDS 主要为 HTTP 协议提供动态路由，而 Aeraki RDS 旨在为所有基于 MetaProtocol 框架开发的七层协议提供动态路由能力。
- MetaProtocol Proxy：基于 Envoy 实现的一个通用七层协议代理。依托 Envoy 成熟的基础库，MetaProtocol Proxy 是在 Envoy 代码基础上的扩展。它为七层协议统一实现了服务发现、负载均衡、RDS 动态路由、流量镜像、故障注入、本地 / 全局限流等基础能力，大大降低了在 Envoy 上开发第三方协议的难度，只需要实现编解码的接口，就可以基于 MetaProtocol 快速开发一个第三方协议插件。

如果没有使用 MetaProtocol Proxy，要让 Envoy 识别一个七层协议，则需要编写一个完整的 TCP filter，这个 filter 需要实现路由、限流、遥测等能力，需要投入大量的人力。对于大部分的七层协议来说，需要的流量管理能力是类似的，因此没有必要在每个七层协议的 filter 实现中重复这部分工作。Aeraki 项目采用了一个 MetaProtocol Proxy 来统一实现这些能力，如下图所示：

![MetaProtocol Proxy 架构图](../../images/metaprotocol-proxy.png "MetaProtocol Proxy 架构图")

基于 MetaProtocol Proxy，只需要实现编解码接口部分的代码就可以编写一个新的七层协议 Envoy Filter。除此之外，无需添加一行代码，Aeraki 就可以在控制面提供该七层协议的配置下发和 RDS 动态路由配置。

![采用 MetaProtocol 编写 Envoy Filter 的对比](../../images/metaprotocol-proxy-codec.png "采用 MetaProtocol 编写 Envoy Filter 的对比")

Aeraki + MetaProtocol 套件降低了在 Istio 中管理第三方协议的难度，将 Istio 扩展成为一个支持所有协议的全栈服务网格。目前 Aeraki 项目已经基于 MetaProtocol 实现了 Dubbo 和 Thrift 协议。相对 Envoy 自带的 Dubbo 和 Thrift Filter，基于 MetaProtocol 的 Dubbo 和 Thrift 实现功能更为强大，提供了 RDS 动态路由，可以在不中断存量链接的情况下对流量进行高级的路由管理，并且提供了非常灵活的 Metadata 路由机制，理论上可以采用协议数据包中携带的任意字段进行路由。QQ 音乐和央视频 APP 等业务也正在基于 Aeraki 和 MetaProtocol 进行开发，以将一些私有协议纳入到服务网格中进行管理。

除此之外，[Aeraki Framework](https://github.com/aeraki-framework) 中还提供了 xDS 配置下发优化的 lazyXDS 插件、Consul、etcd、Zookeeper 等各种第三方服务注册表对接适配，Istio 运维实战电子书等工具，旨在解决 Istio 在落地中遇到的各种实际问题，加速服务网格的成熟和产品化。

## 参考

- [Aeraki GitHub - github.com](https://github.com/aeraki-framework/aeraki)