---
weight: 1
title: "SPIFFE 基本概念"
linkTitle: "SPIFFE"
---

SPIFFE，即普适安全生产身份框架（Secure Production Identity Framework for Everyone），是一套开源标准，用于在动态和异构环境中安全地进行身份识别。采用 SPIFFE 的系统无论在哪里运行，都可以轻松可靠地相互认证。

SPIFFE 开源规范的核心是——通过简单 API 定义了一个短期的加密身份文件 SVID。然后，工作负载进行认证时可以使用该身份文件，例如建立 TLS 连接或签署和验证 JWT 令牌等。

SPIFFE 已经在云原生应用中得到了大量的应用，尤其是在 Istio 和 Envoy 中。下面将向你介绍 SPIFFE 的一些基本概念。

## 工作负载

工作负载是一个单一的软件实体，通过特定配置部署，用于单一目的；它可能包括多个运行中的软件实例，所有这些实例执行相同的任务。术语“工作负载”可能涵盖软件系统的各种不同定义，包括：

- 运行 Python Web 应用程序的 Web 服务器，部署在一组虚拟机上，前面有一个负载均衡器。
- 一个 MySQL 数据库的实例。
- 处理队列中条目的工作程序。
- 一组独立部署的系统共同工作，例如使用数据库服务的 Web 应用程序。Web 应用程序和数据库也可以分别被视为工作负载。

对于 SPIFFE 来说，工作负载往往比物理或虚拟节点更精细 - 通常精细到节点上的单个进程。对于在容器编排器中托管的工作负载而言，这对于多个工作负载可以共存（但在彼此之间隔离）于单个节点的情况非常重要。

对于 SPIFFE 来说，工作负载也可能跨越多个节点 - 例如，一个可以在多台机器上同时运行的弹性缩放的 Web 服务器。

尽管在不同的上下文中，将何为工作负载的粒度会有所不同，但对于 SPIFFE 的目的而言，*假定*工作负载与其他工作负载隔离得足够好，以至于恶意的工作负载在发放证书后无法窃取另一个工作负载的凭据。此隔离的稳固性以及其实现机制超出了 SPIFFE 的范围。

## SPIFFE ID

SPIFFE ID 是一个字符串，唯一且具体地标识一个工作负载。SPIFFE ID 也可以分配给工作负载运行在的中间系统（如一组虚拟机）。例如，**spiffe://acme.com/billing/payments** 是一个有效的 SPIFFE ID。

SPIFFE ID 是一个[统一资源标识符 (URI)](https://tools.ietf.org/html/rfc3986)，其格式如下：**spiffe://信任域/工作负载标识符**

*工作负载标识符*唯一地标识[信任域](https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts/#trust-domain)中的特定工作负载。

[SPIFFE 规范](https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE.md)详细描述了 SPIFFE ID 的格式和用途。

## 信任域

信任域对应于系统的信任根。信任域可以代表运行其独立 SPIFFE 基础设施的个人、组织、环境或部门。在相同信任域中标识的所有工作负载都会收到可以与信任域的根密钥进行验证的身份文件。

通常建议将位于不同物理位置（例如不同数据中心或云区域）或应用不同安全实践的环境（例如与生产环境相比的暂存或实验环境）的工作负载保持在不同的信任域中。

## SPIFFE 可验证身份文件（SVID）

SVID 是工作负载用于向资源或调用方证明其身份的文档。如果由 SPIFFE ID 信任域内的权威签名，SVID 被认为是有效的。

一个 SVID 包含一个单一的 SPIFFE ID，代表了呈现它的服务的身份。它将 SPIFFE ID 编码在一个密码学可验证的文档中，支持两种当前支持的格式之一：X.509 证书或 JWT 令牌。

由于令牌容易受到*重放攻击*，在传输中获取了令牌后，攻击者可以使用它来冒充一个工作负载，因此建议尽可能使用 X.509-SVIDs。但是，在某些情况下，JWT 令牌格式可能是唯一的选择，例如当你的架构在两个工作负载之间有一个 L7 代理或负载均衡器时。

有关 SVID 的详细信息，请参阅[SVID 规范](https://github.com/spiffe/spiffe/blob/main/standards/X509-SVID.md)。

## SPIFFE 工作负载 API

工作负载 API 提供以下功能：

对于 X.509 格式的身份文件（X.509-SVID）：

- 其身份，以 SPIFFE ID 形式描述。
- 与该 ID 相关的私钥，可用于代表工作负载对数据进行签名。还创建了相应的短暂的 X.509 证书，即 X509-SVID。这可用于建立 TLS 连接或以其他方式对其他工作负载进行身份验证。
- 一组证书 - 称为[信任捆绑包](https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts/#trust-bundle) - 可用于验证另一个工作负载呈现的 X.509-SVID。

对于 JWT 格式的身份文件（JWT-SVID）：

- 其身份，以 SPIFFE ID 形式描述。
- JWT 令牌
- 一组证书 - 称为[信任捆绑包](https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts/#trust-bundle) - 可用于验证其他工作负载的身份。

与[Amazon EC2 实例元数据 API](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)和[Google GCE 实例元数据 API](https://cloud.google.com/compute/docs/storing-retrieving-metadata)类似，工作负载 API 不要求调用工作负载具有自己的身份知识，或在调用 API 时拥有任何身份验证令牌。这意味着你的应用程序无需将任何身份验证密钥与工作负载一起部署。

然而，与这些其他 API 不同，工作负载 API 是平台无关的，并且可以在进程级别以及内核级别识别运行的服务 - 这使其适用于与容器调度器（如 Kubernetes）一起使用。

为了最小化由于密钥泄露或被破坏而造成的风险，所有私钥（及相应的证书）都是短暂的，会经常自动轮换。在相应的密钥到期之前，工作负载可以从工作负载 API 请求新的密钥和信任捆绑包。

## 信任捆绑包

在使用 X.509-SVID 时，信任捆绑包用于由目标工作负载验证源工作负载的身份。信任捆绑包是一个包含一个或多个证书颁发机构（CA）根证书的集合，工作负载应将其视为可信任的。信任捆绑包包含了验证 X.509 和 JWT SVID 的公钥材料。

用于验证 X.509 SVID 的公钥材料是一组证书。用于验证 JWT 的公钥材料是一个原始的公钥。信任捆绑包的内容经常会发生变化。在调用工作负载 API 时，工作负载会检索信任捆绑包。