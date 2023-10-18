---
title: 跨集群实现高可用性
weight: 7
---

通过 TSB 和 TSE，你有多种选项可以配置你的平台，使应用程序在集群间以高可用性的方式运行。在每种情况下，一旦平台所有者（"平台"）合适地准备了平台，应用程序所有者（"应用"）只需要从两个或多个集群中部署和发布其服务，即可利用 HA 的优势。

## 高可用性的选项

1. 选项 1：使用 Tetrate 的 Edge Gateway 解决方案
   使用 Tetrate 的 Edge Gateway 来为多个集群提供前端，并在它们之间分发流量。

2. 选项 2：使用 Tetrate 的 Route 53 控制器与 AWS Route 53
   使用 AWS Route 53 控制器为从 TSE 或 TSB 发布的服务自动配置 Route 53。

3. 选项 3：手动配置 GSLB 解决方案
   手动配置 GSLB 解决方案，以在集群入口点之间分发流量并执行健康检查。

## 开始之前

在跨集群负载均衡时，你可能需要依赖 DNS GSLB 解决方案将流量分发到每个服务的入口点（边缘网关等）。在这种情况下，你需要考虑健康检查的功能。

一旦在集群上部署了应用程序，可能需要详细的每应用程序健康检查，但首先，基础设施健康检查是一个很好的起点。健康检查的目的有两个：

* **验证工作负载集群的功能和可达性**：为此，通常只需运行一个简单的 'canary' 服务，如 **[httpbin](http://httpbin.org)**，并验证它是否可以通过每个入口点访问。
* **确定到达每个工作负载集群的最佳方式**：边缘和内部负载均衡器通常配置为在本地和远程代理或集群之间进行负载平衡。这确保了它们始终可以满足请求，即使这意味着使用远程目标。对于 GSLB 健康检查请求，请配置每一跃点只使用下一个本地跃点，如果不可用，则失败，以便对使用快速本地路径的入口点进行健康检查成功。

## 选项 1：配置 Tetrate 的 Edge Gateway

[Edge Gateway 解决方案](https://docs.tetrate.io/service-bridge/howto/gateway/multi-cluster-traffic-shifting) 在 [HA 设计指南](../ha-multicluster/) 中有详细说明。通过 Edge Gateway，你可以在工作负载或专用集群中部署边缘负载均衡器。这些网关的目的是接收流量并将其（负载平衡）转发到目标服务的工作中的 Ingress Gateway。

### 背景信息

Edge Gateways 由 Tetrate 平台管理，考虑到稳定性和可靠性。它们很少更新，并以尽可能简单的配置运行。它们通常部署在专用的 K8s 集群中，以最小化来自相邻工作负载的干扰或中断的可能性。如果你希望部署多个 Edge Gateway 以实现最大的高可用性，可以使用基本的 GSLB 解决方案来分发流量。

请查看以下背景资源：

* [Tetrate HA 设计指南](../ha-multicluster/)
* 你的 GSLB 供应商的最佳实践指南

### 启动一个新应用程序

当你使用 Tetrate 的 Edge Gateway 启动一个新应用程序时，需要在多个接触点配置流量流向：

* 为工作负载集群上的 Ingress Gateways 的 Gateway 资源配置应用程序以从集群中发布应用程序。有关详细信息，请参阅 [部署服务](deploy-service) 内容。通常情况下，不需要为应用程序的工作负载集群实例配置 DNS
* 为边缘集群上的 Edge Gateways 的 Gateway 资源配置应用程序，以从 Edge Gateway 中发布应用程序并将流量分发到正常工作的工作负载集群实例。有关如何执行此操作以及可能适用的高可用性考虑事项的详细信息，请参阅 [Tetrate HA 设计指南](../ha-multicluster/)。
* 为应用程序的 FQDN 配置 DNS，以将流量定向到 Edge Gateway 的正常实例。通常情况下，可以使用第三方的基于 DNS 的 GSLB 服务（例如，由你的云提供商提供的 AWS Route 53）或诸如 NS1、CloudFlare 或 Akamai 等云中立解决方案执行此操作。

具体的步骤由你选择的 Edge Gateway 配置和正在使用的 DNS GSLB 解决方案的性质密切定义。

## 选项 2：使用 Tetrate 的 AWS Route 53 控制器与 AWS Route 53

在 Amazon EKS 上部署工作负载或 Edge Gateways 时，Tetrate 平台可以自动维护反映应用程序所有者或平台所有者对公开的应用程序和服务的意图的 Route 53 DNS 条目。Tetrate 的 Route 53 控制器监视 Gateway 资源并识别其中的 **hostname** DNS 值。只要匹配的 Route 53 托管区存在并且平台所有者已经允许访问，Route 53 控制器将配置并维护必要的 DNS 条目，以便客户可以通过网关访问工作负载。

### 背景信息

请查看以下背景资源：

* [Tetrate Service Express - AWS Route 53 集成](https://docs.tetrate.io/service-express/integrations/route53)
* [Tetrate Service Express - 入门 - 发布服务](https://docs.tetrate.io/service-express/getting-started/publish-service)
* [Tetrate Service Express - 入门 - 多集群和 Route 53](https://docs.tetrate.io/service-express/getting-started/ha-route53)

### 平台：准备集群

要使此功能可用于你的应用程序所有者，你需要执行三件事：

1. 创建 Route 53 托管区
   为你计划使用的 dns 条目（域）创建必要的 Route 53 托管区，例如 `.tetratelabs.io`

2. 在每个集群上部署 Route 53 控制器
   在每个集群上启用适当的 IAM 服务帐户，并部署 **Tetrate Route 53 控制器**。你可以使用 **spec.providerSettings.route53.domainFilter** 设置来限制可以从集群中管理哪些 Route 53 托管区。
   我们强烈建议在每个集群上 [安装 AWS 负载均衡器控制器](https://docs.tetrate.io/service-express/installation/eks-cluster#install-aws-load-balancer-controller)，以实现 Tetrate 平台、Ingress Gateways 和 Route 53 配置及健康检查的最佳集成。

3. 解释应用程序所有者需要知道的内容
   分享应用程序所有者需要知道以使用 Route 53 自动化的详细信息：
   - 对于简单的 Ingress 情况，在 Ingress **Gateway** 资源中使用正确的主机名就足够了，Route 53 控制器将提供 Route 53 简单的 DNS 资源
   - 对于多集群、GSLB 情况，应用程序所有者将需要 [使用 AWS 特定的注释来扩展其 Ingress **Gateway** 资源](https://docs.tetrate.io/service-express/getting-started/ha-route53)

## 选项 3：手动配置 GSLB 解决方案

**选项 3：** 你还可以选择使用第三方的 GSLB 解决方案来在 Tetrate 管理的端点（Edge Gateways 或 Ingress Gateways）之间分发流量。另外，CDN 可以为一组 Edge Gateways 和 Ingress Gateways 提供前端。

## 应用程序：部署应用程序

你的管理员（平台所有者）将解释你需要了解的内容，以在集群间部署应用程序，配置健康检查并测试高可用性。评估标准取决于他们为准备平台采取的方法。

通过适当的配置，你应该可以很好地控制你的服务是如何发布的，并在集群间共享流量。这将使你能够创建一个高可用性部署，以管理健康检查并操作常见任务，如为应用程序升级做准备之前排放集群。
