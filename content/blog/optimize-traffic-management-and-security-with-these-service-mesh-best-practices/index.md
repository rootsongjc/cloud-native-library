---
title: "服务网格安全性优化最佳实践"
date: 2023-02-01T11:00:00+08:00
draft: false
authors: ["Tetrate"]
summary: "本文推荐了服务网格安全性优化的一些最佳实践。"
tags: ["Istio"]
categories: ["Istio"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://tetrate.io/blog/optimize-traffic-management-and-security-with-these-service-mesh-best-practices/
---

这是 [服务网格最佳实践系列文章](https://tetrate.io/blog/how-service-mesh-layers-microservices-security-with-traditional-security-to-move-fast-safely/)中的第三篇，摘自Tetrate 创始工程师 Zack Butcher 即将出版的新书 Istio in Production。

Istio 就像一组乐高积木：它具有许多功能，可以按照您想要的任何方式进行组装。出现的结构取决于您如何组装零件。在[上一篇中](../service-mesh-deployment-best-practices-for-security-and-high-availability/)，我们描述了一种运行时拓扑结构，用于构建健壮、有弹性且可靠的基础架构。在本文中，我们将描述一组网格配置，以帮助在运行时实现稳健性、弹性、可靠性和安全性。

Istio 在其所谓的[根命名空间](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-root_namespace)中支持全局默认配置——默认在 `istio-system`。在根命名空间中发布的配置默认适用于所有服务，但在本地命名空间中发布的任何配置都会覆盖它。因此，一些配置应该在根命名空间中发布，并且不允许在其他任何地方发布（例如用于在传输中强制加密的 PeerAuthentication 策略）。其他配置应该在每个服务自己的命名空间中编写（例如 VirtualService 控制它的弹性设置）。

我们看到的最成功的网格采用将网格本身隐藏在另一个界面后面：例如 Helm 模板、Terraform 或更高级的解决方案，例如[Tetrate Service Bridge (TSB)](https://tetrate.io/tetrate-service-bridge/)。核心思想是只公开应用程序开发人员应该配置的一小部分网格功能，最好是使用他们理解的语言（例如，TSB 可以使用[带注释的 OpenAPI 规范](https://docs.tetrate.io/service-bridge/1.6.x/en-us/quickstart/apps)进行配置）。首先，我们通常只向应用程序开发人员公开流量设置和授权。身份验证和遥测由各自的团队或代表他们的平台团队集中控制。[NIST SP800-204 系列](https://tetrate.io/blog/nist-standards-for-zero-trust-the-sp-800-204-series/)，尤其是[SP 800-204A](https://csrc.nist.gov/publications/detail/sp/800-204a/final)和[SP 800-204B](https://csrc.nist.gov/publications/detail/sp/800-204b/final)。Istio 项目站点也有一组[最佳实践](https://istio.io/latest/docs/ops/best-practices/)，也值得收藏。

## 服务网格命名约定

**建议**：为 Istio 资源开发和维护一致的命名方案，最好基于它们配置的服务或主机。

**建议**：为跨集群的团队保持一致的名称。命名空间应该由一个团队拥有。

Istio 资源应该根据它们配置的服务或主机来命名：`ServiceEntry`添加 `api.example.com` 到网格的应该命名为`external-api-example-com`；服务的`DestinationRule`、`VirtualService`、`PeerAuthentication`和`Authorization`策略也都应该有相同的名称。PCI命名空间中的内部服务Payments（应用程序代码中的hostname `payments.pci`）应该被命名为`payment-pci`，其所有的网格配置名称也应该匹配。这些命名方案并不是硬性规定，但你应该在你的组织内建立并坚持一个一致的惯例。

这些资源应该全部发布在它们配置的服务的命名空间中，或者发布在 `istio-system` 命名空间中以进行网格范围的配置。外部服务通常发布到 `istio-system` 中并由中心团队（平台或安全团队）管理。

我们建议跨集群的团队使用一致的名称：无论集群租户模型如何，命名空间都应由单个团队拥有（请参阅下一节）。

## 服务网格全局设置

**配置可见性**。Istio 有一个配置可见性的想法：配置可以默认应用于整个集群，或者它可以只应用于本地命名空间，甚至可以只应用于单个服务（选择对整个集群可见，或者只是特定的命名空间）。为了性能和安全，您应该将该字段默认为`exportTo`本地名称空间（“.”）。您应该在安装时为[*Services*](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-default_service_export_to)、[*VirtualServices*](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-default_virtual_service_export_to)和[*DestinationRules*](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-default_destination_rule_export_to)设置这个默认值。查看 Istio 的[全局配置](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-default_service_export_to)来配置这些默认值：

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
 name: controlplane
 namespace: istio-system
spec:
 # profile: default
 # ...
 meshConfig:
   defaultServiceExportTo:
   - "."# only the namespace the resource is published in
   defaultVirtualServiceExportTo:
   - "."
   # equivalent, just different YAML syntax
   defaultDestinationRuleExportTo: ["."]
```

示例 1：默认全局设置

**每个命名空间的 Sidecar 资源配置**。Istio 的`Sidecar` （API）资源控制 Istio 将哪些配置发送到每个命名空间中的Sidecar。为了获得最佳性能和最低开销，您应该为每个命名空间管理一个配置，并管理egress部分以仅包括服务必须与之通信的主机。这将导致 Istio 向该命名空间中的 Envoy 实例发送更少的配置，从而减少它们的内存和 CPU 消耗。结合仅注册表出站流量策略（见下一条），Sidecar资源还可以帮助限制攻击者通过Envoy的表面区域，因为不在Sidecar的egress部分的主机将是该Envoy实例的 "出站流量"。这本身并不是一个足够的安全策略（见下面的安全部分），而是增加了一个攻击者必须穿越的额外防御层。

**编写明确的出站（egress）流量策略**。Istio 提供了一些选项来配置它如何处理网格中的服务，该服务试图与 Istio 未知的端点进行通信：[Outbound Traffic Policy](https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-OutboundTrafficPolicy-Mode)。Istio可以允许所有流量，也可以将流量限制在网格已知的服务上。你应该在安装时配置Istio，只允许连接到注册表中的服务。此外，你应该将所有需要与之通信的外部服务建模为Mesh中的ServiceEntries（例如，SaaS服务的DNS解析等），使用DestinationRules来配置与它们通信的TLS。这些外部服务应该由安全团队集中管理，或者由平台团队代表他们管理。

## 运行时流量管理配置

**为服务使用一致的全局名称，并使用 Istio 将它们映射到本地实例**。您应该使用一致的全局名称来访问服务。您可以使用 Istio 将这些全局名称映射到本地实例。例如，`payments.tetrate.internal` 可以被所有内部应用程序使用，而 Istio 可以用来将该名称映射到服务实例，例如“在`us-east-2` Kubernetes 集群中的 `payments.default.svc.cluster.local`服务”。这种全局命名方案使开发人员可以像 SaaS 一样考虑所有服务，而无需仔细考虑运行时拓扑的细节，并且可以轻松地执行故障转移、金丝雀和跨集群路由等操作，作为您的网格使用成熟或组织需求演变。

**在根配置中定义粗略的默认弹性设置**。您应该为网格中的所有服务定义粗略的超时、重试、熔断和异常值检测设置。您可以在根配置命名空间中使用 `VirtualService` 来实现此目的。各个团队应在其本地命名空间中指定自己的名称以覆盖默认值。

**为应用程序团队提供简化的“低/中/高”弹性设置**。将网格的底层 API 隐藏在更高级别接口后面的系统中，为配置默认断路和异常值检测设置的应用程序开发人员提供简化的“低/中/高”旋钮很有价值，因为很多领域容易配置错误，导致该应用程序性能不佳。

## 运行时安全配置

以下安全建议来自我们为微服务应用程序建立美国安全标准的工作，该标准由美国国家标准与技术研究院（NIST）在[SP 800-204 系列](https://tetrate.io/blog/nist-standards-for-zero-trust-the-sp-800-204-series/)中发布。[您可以在我们的综合指南](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/)中阅读 NIST 针对微服务应用程序的所有安全建议。

**最小控制**。运行时的零信任至少需要以下五个控制：

1. **加密传输中的所有内容**：提供消息真实性和窃听保护（[SP 800-204，§MS-SS-4](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/)）。
2. **验证服务到服务的通信**：每个应用程序都应验证与之通信的应用程序的身份（[SP 800-204A，§SM-DR16；SP 800-204B，§APE-SR-3](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/)）。
3. **授权服务到服务访问**：每个应用程序都应使用其运行时身份授权与之通信的应用程序（[SP 800-204B，§SAUZ-SR-1](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/)）。
4. **验证最终用户身份**：每个请求都必须在服务调用图中的每个跃点进行身份验证（[SP 800-204B，§EAUN-SR-1，§EUAZ-SR-3](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/)）。
5. **授权最终用户访问资源**：对每种资源的每次访问都应获得授权，而不仅仅是在前门访问一次（[SP 800-204B，§EAUZ-SR-3](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/)）。

Istio 提供传输中的加密（我们在上面讨论了全局启用），以及可验证的服务身份 ( [SPIFFE](https://tetrate.io/blog/why-would-you-need-spire-for-authentication-with-istio/) ) 和服务到服务的访问控制 (Istio `AuthorizationPolicy`)。此外，它可以配置为代表应用程序（JWT、OIDC 令牌）验证某些形式的最终用户身份，最后 Istio 支持可插拔授权系统（Envoy 的 `ext_authz`）以强制最终用户访问资源。

**安装限制性默认授权策略**。根据[Istio 最佳实践](https://istio.io/latest/docs/ops/best-practices/security/#use-default-deny-patterns)，您应该安装一个不允许流量的默认授权策略，为每个服务发布对象创建`AuthorizationPolicy`对象以管理允许它们与之通信的对象（[SP 800-204B，SAUZ-SR-1](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/)）。有助于实现这一目标的两个授权策略：

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all-audit
  namespace: istio-system
spec:
  action: AUDIT
```

示例 2： `IstioAuthorizationPolicy`会拒绝所有流量，并审计记录它。您可能会运行这样的策略几周，以了解在启用强制执行之前您需要的策略。

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: istio-system
spec:
  {} # or action: ALLOW
```

示例 3：拒绝所有流量的 Istio AuthorizationPolicy。或者，您可以创建一个允许但具有空规则集的策略，这与空主体相同。

**默认情况下需要 mTLS 进行服务到服务通信**。通过在由安全或平台团队管理的根命名空间中配置`PeerAuthentication`资源，应将传输中的加密设置为严格（即[需要 mTLS 才能与服务通信](https://tetrate.io/blog/how-istios-mtls-traffic-encryption-works-as-part-of-a-zero-trust-security-posture/)）。网格外部的服务调用网格中的应用程序应该通过应用程序入口网关进行通信，它可以向外部服务提供简单的 TLS（甚至明文），因为它不太可能有证书来对网格执行 mTLS。网格内部的服务呼出应配置为使用简单的 TLS 或明文，并带有用于外部服务的DestinationRule的明文 ( [NIST SP 800-204A, §SM-DR8](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/) )。

**TLS 配置默认值**。Istio 开箱即用，具有良好的 TLS 设置（[TLS 最低版本 1.2，具有一组有限的密码套件](https://istio.io/latest/docs/concepts/security/#mutual-tls-authentication)），但您可能需要根据您的环境对其进行调整（例如，在[FedRAMP](https://www.fedramp.gov/)环境中遵守[FIPS 140-3](https://csrc.nist.gov/publications/detail/fips/140/3/final) ）：

- Envoy 支持通过配置[网关](https://istio.io/latest/docs/reference/config/networking/gateway/#ServerTLSSettings-cipher_suites)为每个服务配置最低 TLS 版本和一组受支持的密码套件。
- 如果可能，我们建议将**TLS 1.3 作为最低版本**执行（如果您只执行 mTLS Envoy-to-Envoy），并为需要较旧或安全性较低的 TLS 配置的外部流量使用网关。

**为每个服务分配一个唯一的运行时身份，以促进表达性强、细粒度的授权策略并限制暴露于攻击**。为您正在部署的每个服务分配一个唯一的运行时标识。在 Kubernetes 中，不要在每个命名空间中使用默认的 Kubernetes 服务帐户，而是为每个命名空间中的每个服务分配一个唯一的服务帐户。授权策略只能在身份的粒度上轻松管理。当多个运行时组件共享相同的身份时，很难管理一个访问控制策略来表达您的预期访问权限，同时不允许使用共享身份的某些组件进行过于广泛的访问。这导致更大的表面积暴露给可能危及系统的一个组件的攻击者（[NIST SP 800-204A §SM-DR11，§SM-DR18](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/)）。

**将服务到服务的通信限制在本地命名空间**。默认情况下，服务间通信应限制在本地名称空间内。不幸的是，这不能写为根配置命名空间中的单个 AuthorizationPolicy。相反，可以将仅允许在本地命名空间中访问的默认 AuthorizationPolicy 模板化为默认值，并且应允许应用程序团队编写他们自己的更专业（受限）的策略（[NIST SP800-204B，§SAUZ-SR-1](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/)）。

## 下一步

我们希望从我们多年帮助客户构建成功的服务网格实践的经验中获得的这些最佳实践将有助于促进您的部署。如果您还没有，请查看服务网格最佳实践系列中的其他帖子： 

- [第 1 部分：如何将服务网格作为安全模型的一部分，以分层形式将微服务安全与传统安全结合起来](/blog/how-service-mesh-layers-microservices-security-with-traditional-security-to-move-fast-safely/)
- [第 2 部分：服务网格安全性和高可用性部署最佳实践](/blog/service-mesh-deployment-best-practices-for-security-and-high-availability/)

如需全面了解 NIST 微服务安全标准，请[下载我们的免费指南](https://tetrate.io/tetrates-guide-to-federal-security-requirements-for-microservices/)。

### 接下来：多租户的服务网格最佳实践

在我们关于服务网格最佳实践系列的下一篇文章中，我们将讨论我们看到客户正在努力解决的常见租赁决策点，并重点关注网格如何帮助促进这些决策。我们将涵盖的主题包括 Kubernetes 集群所有权、命名空间所有权、配置所有权，以及如何使用服务网格应用程序网关来缓解中断。
