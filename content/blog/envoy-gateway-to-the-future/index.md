---
title: "面向未来的网关：新的 Kubernetes Gateway API 和 Envoy Gateway 0.2 介绍"
date: 2022-10-27T10:00:00+08:00
draft: false
authors: ["Matt Turner"]
summary: "最近 Envoy Gateway 0.2 发布了，API 网关的生态系统迎来了新的变化。这篇文章将向你介绍 Kubernetes API 网关领域的最新进展。"
tags: ["Istio", "Envoy","API Gateway","Envoy Gateway","Gateway"]
categories: ["Gateway"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://www.tetrate.io/blog/gateway-to-the-future-the-new-gateway-api-and-envoy-gateway-0-2/
---

最近 [Envoy Gateway 0.2](https://blog.envoyproxy.io/introducing-envoy-gateway-ad385cc59532) 发布了，API 网关的生态系统迎来了新的变化。这篇文章将想你介绍 Kubernetes API 网关领域的最新进展。

如何将外部的网络请求路由到 Kubernetes 集群？你可以使用入口控制器：一组 HTTP 反向代理，将流量转接到集群中，并由 operator 来管理。也可以使用 Ambassador、Contour、Traefik 或 HAproxy 这类软件。还可以使用云提供商的解决方案，或者只是用默认的的 Nginx Ingress。或者你可能使用一个功能更全面的 API 网关，如 Tyk 或 Kong，或者在 Kubernetes Ingress 前面的另一层有一个单独的网关，如 AWS 的 API 网关，或内部的 F5，可以选择的实在太多。

## 为什么我们需要一个新的入口控制器

因为很多入口控制器都有不同程度的限制：有些是基于旧的技术，如 Nginx、HAproxy，甚至是基于 Apache 建立的。这些技术的特性不适用于云原生环境，比如在配置改变时放弃已建立的连接（如果你想深入了解，Ambassador 发表了一篇[比较](https://blog.getambassador.io/envoy-vs-nginx-vs-haproxy-why-the-open-source-ambassador-api-gateway-chose-envoy-23826aed79ef)文章）。云供应商的产品确实倾向于基于更现代的东西（比如 [SDN](https://www.usenix.org/system/files/conference/nsdi18/nsdi18-dalton.pdf)），但是这可能产生厂商锁定。目前，你只需用一个 Kubernetes API 来指定所有不同选项的配置：Ingress。这个 API 的可配置项很少，几乎任何你想配置的设置都需要通过 annotation 来实现，而不是作为一类字段。

## Envoy Gateway：未来 Gateway 发展的基础

现在又有了新的选择：Envoy Gateway，简称 EG。顾名思义，这是一个基于 Envoy 代理的网关（入口控制器）。它是一个托管在 GitHub 上的 Envoy 社区项目。这不是第一个基于 Envoy 的入口；已经有流行的建立在 Envoy 之上的 Contour 和 Ambassador 等项目。但是这些项目的开发者和更多的人正在一起为 EG 做出贡献，Ambassador 和 Contour 都说他们会在适当的时候[在 Envoy Gateway 的代码上重构](https://blog.envoyproxy.io/introducing-envoy-gateway-ad385cc59532)（也就是说，我们 Tetrate 公司无可否认地为我们在这个项目中的领导作用感到自豪）。

Envoy 本身是久经考验的入口代理、sidecar 代理，并且正在准备取代[谷歌的 GFE](https://cloud.google.com/docs/security/infrastructure/design#google_front_end_service)。

### 代码演示

如果你想在了解更多关于 Envoy Gateway 的内容之前先演练一番，我已经写了[一篇姐妹篇](https://tetr8.io/3MPT6KT)，其中有详细的说明，可以自己设置 Envoy Gateway，如果你没有环境，那篇文章中也包括了我机器上所有的命令输出，这样你就可以看到会发生什么。

## 通往 API 的 Gateway

Envoy Gateway 以其最简单的形式 —— 你可能刚刚设置好的系统，将请求转发到其集群中。它根据 HTTP host 和 path 进行路由，也可以根据其他 header 进行路由。每个集群都需要这样做，很高兴看到 Envoy Gateway 在开发的短短 6 个月内就能做到这一点（要了解更多关于 Envoy Gateway 的信息，请看 [Gateway to a New Frontier](https://www.tetrate.io/envoy-gateway/)。

### 超越基本入口的高级功能

然而，许多组织需要比这个基本的 7 层网络路由更多的功能。如果需要像 WAF、body 的模式验证、bot 拦截等，许多人就会使用 API 网关。我们看到很多组织在他们的入口控制器前面部署了一个单独的 API 网关。然而，API 网关可以*取代*入口控制器，因为它也可以做路由和流量观察的基本功能。它们可以提供这些功能，因为它们是由与入口控制器相同的代理构建的，例如，Kong 是基于 nginx 的。API 网关产品在市场上很受欢迎，但如果你真的想一想 API 网关是什么，它就是一个 HTTP 代理，有一系列的附加功能（我之前提到的 WAF 等）。这并不是说它们不增加任何价值 —— 它们提供的功能是多种多样的，而且很强大，但有一个共同的功能基线和实现代码。

### 使用 Wasm 的动态可扩展性

因此，Envoy Gateway 完全有能力发展成为一个全功能的 API 网关。Envoy 实际上已经具备了一些更先进的功能，包括 JWT 验证、OIDC 认证流和速率限制。此外，Envoy 是动态可扩展的；它可以在不重启的情况下加载插件，这意味着可以很容易地按需添加更多的功能。这些插件是以 WASM 字节码的形式提供的，这意味着它们可以用任何可以编译成 WASM 的语言（Tiny Go、Rust 等）编写，而不仅仅是其他代理支持的脚本语言。社区正在开始编写这些插件：缓存可能会首先落地，[Coraza](https://coraza.io/) 项目是一个相对成熟的 `mod_security` 风格的 WAF，用 Go 编写，可以编译成 WASM，现在可以用于 Envoy 代理。

### Gateway API 鼓励扩展

在入口控制器市场上，扩展和竞争的另一大障碍是 API。需要特定于供应商的注解（或全新的特定于供应商的 API），这些注解很笨重，而且妨碍了交叉兼容。相比之下，Envoy Gateway 是由 Gateway API 配置的，这是 `gateway.networking.k8s.io `API 组的一组资源。这个 API 将最终取代 Ingress 资源。它的核心已经比 Ingress 更加灵活和富有表现力，而且它被设计成以可管理的方式增长和扩展。这将允许它发展成为所有南北流量控制的一流模型，从基本的路由到先进的 API 管理功能。这反过来又会将 Envoy Gateway 拥有的所有功能，以一种标准的、与供应商无关的方式暴露出来，让人们在使用这些功能时无需跳过障碍或担心锁定问题。Envoy Gateway 将在 2023 年 3 月的 0.3 版本中支持 Gateway API 的这些新部分。

### 为未来的网关发展提供一个共同的、最佳的基础

Envoy Gateway 的动力来自于对 API 网关功能堆栈的日益关注。基本的入口正在变得商业化，所以社区正在汇集其资源和专业知识，为未来的网关开发创造一个共同的、最好的基础。同时提供新的 Gateway API 供其实现是非常方便的，Envoy Gateway 的 0.2 版本标志着对目前定义的 Gateway API 核心类型的全面支持。

扩展到高级用例模型的工作已经开始，现在正在设计 [JWT auth 配置](https://docs.google.com/document/d/1TlQjBy1utEwgrxE_HVT4-EHpVJ51hgnfMuAh0Q_uNoE/view)，其他的也将陆续推出。插件本身的工作也已经开始（例如，Coraza，一个仿照无处不在的 `mod_security` 的 Golang WAF）。虽然这些都有很长的路要走，但我个人非常期待看到这一切在未来一两年的发展。

## 通往服务网格的 Gateway

你可能在想，已经有一类产品支持 OIDC 认证和速率限制等功能了：服务网格。这是真的；最突出的网格，Istio，在其默认配置中为入口部署了一套代理服务器。Istio 现在支持 Gateway API（就像 Envoy Gateway 一样）来配置该入口。我们在 Tetrate 对这种融合感到兴奋：企业现在可以采用 Envoy Gateway 来简单而快速地开展工作。Envoy Gateway 在管理这种南北流量方面做得很好，运行它可以让他们了解 Envoy 在生产中的性能和操作特点。当这些组织准备好控制他们的服务到服务，也就是东西向流量时，他们可以部署 Istio，因为他们已经熟悉了主要的基础组件（Envoy）。虽然他们可能会选择使用 Istio 的入口网关（以保持他们的控制平面数量减少到 1），但他们现有的 Gateway API 资源将继续工作。由于同样基于 Envoy，Istio 的 Ingress 也可以接受任何加载到 Envoy Gateway 的 API Gateway 风格的插件。所有这一切都使得在必要时增加服务网格的力量变得非常容易。

### 用于入口和服务网格的统一 Gateway API

更重要的是，现在已经有了一个工作组来协调网关和网格网络之间的重叠部分：[GAMMA 倡议](https://gateway-api.sigs.k8s.io/contributing/gamma/)。GAMMA 是 Gateway API for Mesh Management and Administration 的缩写，这是对 Gateway API 未来发展方向的一个倡议；计划是开始对服务网格的关注进行建模，即东西向流量也是如此。GAMMA 将确保 Envoy Gateway 和服务网格的良好合作，并将关注 Gateway API 的统一，以涵盖入口和网格。我们很高兴看到，这将为许多组织轻松和逐步地采用服务网格，基于一个与产品无关的 API，这对所有人都是好事。

## 结束语

这篇文章对新的标准 API、Gateway API 和参考实现 Envoy Gateway 作了很好的介绍，希望能对你了解当前的入口网关生态有所帮助。

如果你想关注 EG 的发展，你可以加入 Envoy slack 的 `#gateway` 频道，并在 https://github.com/envoyproxy/gateway 查看提交和问题。该项目有一个 [未来几个版本的路线图](https://github.com/envoyproxy/gateway/blob/main/docs/design/ROADMAP.md)，0.3.0 版本发布预期是在 2023 年 3 月。

如果你想测试一下 Envoy Gateway，我写了一个配套的教程，其中包含了启动和运行的步骤说明。

如果你正在开始使用 Istio 和 Envoy，请[查看 Tetrate 学院](https://academy.tetrate.io/)，你会发现大量的免费课程、研讨会，以及 Tetrate 的 Istio 管理员认证考试。

要想以最简单的方式安装、管理和升级 Istio，请查看[我们的开源 Tetrate Istio 发行版（TID）](https://istio.tetratelabs.io/)。TID 是一个经过审查的 Istio 的上游发行版 ——Istio 的加固镜像，具有持续的支持，更容易安装、管理和升级。
