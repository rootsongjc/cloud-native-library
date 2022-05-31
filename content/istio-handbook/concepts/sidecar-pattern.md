---
weight: 50
title: Sidecar 模式
date: '2022-05-18T00:00:00+08:00'
type: book
---

Sidecar 模式是 Istio 服务网格采用的模式，在服务网格出现之前该模式就一直存在，尤其是当微服务出现后开始盛行，本文讲解 Sidecar 模式。

## 什么是 Sidecar 模式

将应用程序的功能划分为单独的进程可以被视为 **Sidecar 模式**。Sidecar 设计模式允许你为应用程序添加许多功能，而无需额外第三方组件的配置和代码。

就如 Sidecar 连接着摩托车一样，类似地在软件架构中， Sidecar 应用是连接到父应用并且为其扩展或者增强功能。Sidecar 应用与主应用程序松散耦合。

让我用一个例子解释一下。想象一下假如你有6个微服务相互通信以确定一个包裹的成本。

每个微服务都需要具有可观测性、监控、日志记录、配置、断路器等功能。所有这些功能都是根据一些行业标准的第三方库在每个微服务中实现的。

但再想一想，这不是多余吗？它不会增加应用程序的整体复杂性吗？如果你的应用程序是用不同的语言编写时会发生什么——如何合并那些特定用于 .Net、Java、Python 等语言的第三方库。

## 使用 Sidecar 模式的优势

- 通过抽象出与功能相关的共同基础设施到一个不同层降低了微服务代码的复杂度。
- 因为你不再需要编写相同的第三方组件配置文件和代码，所以能够降低微服务架构中的代码重复度。
- 降低应用程序代码和底层平台的耦合度。

## Sidecar 模式如何工作

Sidecar 是容器应用模式的一种，也是在服务网格中发扬光大的一种模式，详见 [Service Mesh 架构解析](https://cloudnative.to/blog/service-mesh-architectures/)，其中详细描述了**节点代理**和 **Sidecar** 模式的服务网格架构。

使用 Sidecar 模式部署服务网格时，无需在节点上运行代理（因此您不需要基础结构的协作），但是集群中将运行多个相同的 Sidecar 副本。从另一个角度看：我可以为一组微服务部署到一个服务网格中，你也可以部署一个有特定实现的服务网格。在 Sidecar 部署方式中，你会为每个应用的容器部署一个伴生容器。Sidecar 接管进出应用容器的所有流量。在 Kubernetes 的 Pod 中，在原有的应用容器旁边运行一个 Sidecar 容器，可以理解为两个容器共享存储、网络等资源，可以广义的将这个注入了 Sidecar 容器的 Pod 理解为一台主机，两个容器共享主机资源。

## 参考

- [理解 Istio 服务网格中 Envoy 代理 Sidecar 注入及流量劫持 - jimmysong.io](https://jimmysong.io/blog/envoy-sidecar-injection-in-istio-service-mesh-deep-dive/)
- [微服务中的 Sidecar 设计模式解析 - cloudnative.to](https://cloudnative.to/blog/sidecar-design-pattern-in-microservices-ecosystem/)
