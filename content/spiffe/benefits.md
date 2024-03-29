---
weight: 3
title: 收益
linktitle: 2. 收益
date: '2022-10-07T00:00:00+08:00'
type: book
description: "本章从业务和技术的角度解释了在基础设施中部署 SPIFFE 和 SPIRE 的好处。"
---

本章从业务和技术的角度解释了在基础设施中部署 SPIFFE 和 SPIRE 的好处。

## 任何人任何地方都适用

SPIFFE 和 SPIRE 旨在加强对软件组件的识别，以一种通用的方式，任何人在任何地方都可以在分布式系统中加以利用。现代基础设施的技术环境是错综复杂的。环境在硬件和软件投资的混合下变得越来越不一样。通过对系统定义、证明和维护软件身份标准化的方式来维护软件安全，无论系统部署在哪里，也无论谁来部署这些系统，都会带来许多好处。

对于专注于提高业务便利性和回报的企业领导人来说，SPIFFE 和 SPIRE 可以大大降低管理和签发加密身份文件（如 X.509 证书）的开销，开发人员无需了解服务间通信所需的身份和认证技术，从而加速开发和部署。

对于专注于提供强大、安全和可互操作产品的服务提供商和软件供应商来说，SPIFFE 和 SPIRE 解决了在将许多解决方案互连到最终产品时普遍存在的关键身份问题。例如，SPIFFE 可以作为产品的 TLS 功能和用户管理/认证功能的基础，一举两得。还有，SPIFFE 可以取代管理和发行平台访问的 API 令牌的需要，**免费**带来令牌轮换，并消除存储和管理访问所述令牌的客户负担。

对于希望不仅加强传输中的数据安全，而且实现监管合规并解决其信任根源问题的安全从业人员来说，SPIFFE 和 SPIRE 致力于在不信任的环境中提供相互认证，而不需要交换秘密。安全和管理边界可以很容易地划定，并且在策略允许的情况下，可以跨越这些边界进行通信。

对于需要身份管理抽象的开发人员、运维和 DevOps 从业人员，以及需要与现代云原生服务和解决方案互操作的工作负载和应用程序，SPIFFE 和 SPIRE 在整个软件开发生命周期中与许多其他工具兼容，以提供可靠的产品。开发人员可以继续他们的工作，直接进入业务逻辑，而不必担心证书、私钥和 JavaScript Web Token（JWT）等烦人的问题。

## 对于企业领导人

### 现代的组织有现代的需求

在今天的商业环境中，通过差异化的应用和服务快速提供创新的客户体验是保持竞争优势的必要条件。因此，企业见证了应用程序和服务的架构、构建和部署方式的变化。诸如云和容器等新技术帮助企业更快、更大规模地发布。服务需要高速构建并部署在大量的平台上。随着开发速度的加快，这些系统变得越来越相互依赖和相互联系，以提供一致的客户体验。

组织在实现高速发展和获得市场份额或任务保证方面可能会受到抑制，主要原因是合规性、专业知识的储备以及团队 / 组织之间和现有解决方案内的互操作性挑战。

**互操作性的影响**

随着系统的发展，对互操作性的需求也在无限地增长。脱节的团队建立的服务是孤立的，互不相识，尽管他们最终需要意识到彼此的存在。收购发生时，新的或从未见过的系统需要被整合到现有的系统中。商业关系的建立，需要与可能存在于堆栈深处的服务建立新的沟通渠道。所有这些挑战都围绕着“我如何以安全的方式将所有这些服务连接在一起，每个服务都有自己独特的属性和历史？”

当不同的技术栈必须结合在一起进行互操作时，由于组织融合而产生的技术整合可能是一个挑战。为系统与系统之间的通信与身份和认证制定一个共同的、行业认可的标准，可以简化跨多个堆栈的完全互操作性和整合的技术问题。

SPIFFE 带来了对构成软件身份的共识。通过进一步利用 SPIFFE Federation，不同组织或团队的不同系统中的组件可以建立信任，安全地进行通信，而不需要增加诸如 VPN 隧道、one-off 证书或用于这些系统之间的共享凭证等结构的开销。

**合规性和可审计性**

SPIRE 实施中的可审计性保证了执行行动的身份不会因为在环境中执行相互认证而被否定。此外，SPIFFE/SPIRE 发布的身份文件使相互认证的 TLS 得到广泛使用，有效地解决了与这种性质的项目相关的最困难的挑战之一。相互认证的 TLS 的其他好处包括对服务之间传输的数据进行本地加密，不仅保护了通信的完整性，还保证了敏感或专有数据的保密性。

![图 2.1: 使用 SPIFFE 无缝地满足合规和监管目标。](../images/f2-1.jpg)

另一个常见的合规要求是由《通用数据保护条例》（GDPR）带来的 —— 特别是要求欧盟（EU）的数据完全停留在欧盟内部，而不是在其管辖范围之外的实体中转或被处理。有了多个信任根基，全球组织可以确保欧盟实体只与其他欧盟实体沟通。

**专业知识库**

确保开发、安全和运营团队具备正确的知识和经验，以适当地处理安全敏感系统，仍然是一项重大挑战。企业需要雇用具有基于标准的技能组合的开发人员，以减少入职时间，并在减少风险的情况下改善产品效率。

解决以自动方式向每个软件实例提供加密身份的问题，并从根本上实现凭证轮换，是一项重大挑战。对于安全和运维团队来说，具有的实施此类系统所需的专业知识少之又少。在不依靠社区或行业知识的情况下维持日常运营会使问题恶化，导致中断和指责。

不能合理地期望开发人员了解或获得安全的实际问题的专业知识，特别是在组织环境中适用于服务身份。此外，在开发、运维和工作负载执行方面具有深度知识的安全从业人员的储备是非常少的。利用一个开放的标准和开放的规范来解决关键的身份问题，允许没有个人经验的人通过一个得到良好支持的、不断增长的 SPIFFE/SPIRE 终端用户和从业人员社区来扩展知识。

**节约**

采用 SPIFFE/SPIRE 可以在许多方面节省成本，包括减少云 / 平台锁定，提高开发人员的效率，以及减少对专业知识的依赖，等等。

通过将云提供商的身份接口抽象为一套建立在开放标准上的定义明确的通用 API，SPIFFE 大大减轻了开发和维护**云感知**应用的负担。由于 SPIFFE 是平台无关的，它几乎可以在任何地方部署。当需要改变平台技术时，这种差异化可以节省时间和金钱，甚至可以加强与现有平台供应商的谈判地位。从历史上看，身份和访问管理服务是由每个组织自己的部署指挥和控制平台 —— 云服务提供商知道这一点，并利用这一制约因素作为主要的锁定机制，与他们的平台完全整合。

在提高开发人员的效率方面也有很大的节省。SPIFFE/SPIRE 有两个重要方面可以节省开支：加密身份及其相关生命周期的完全自动化发布和管理，以及认证和服务间通信加密的统一性和加载性。通过消除与前者相关的手动流程，以及在后者中花费的研究和试验 / 错误时间，开发人员可以更好地专注于对他们重要的事情：业务逻辑。

| **提高开发人员的生产力**                                     | 值   |
| :----------------------------------------------------------- | :--- |
| 开发人员在获取证书和配置每个应用组件的认证 / 保密协议方面花费的平均时间（小时）。 | 2    |
| 减少开发人员在每个应用组件上对应的证书所花费的时间。         | 95%  |
| 开发人员在学习和实施特定 API 网关、秘密存储等控制方面花费的平均时间（小时） | 1    |
| 减少了开发人员学习和实施特定 API 网关、秘密存储等控制的时间。 | 75%  |
| 本年度开发的新应用组件的数量                                 | 200  |
| **预计因提高开发人员生产力而节省的时间**                     | 530  |

正如我们在历史上看到的那样，财富 50 强的技术组织雇用了高度熟练和专业的工程师，花了几十年时间来解决这个身份问题。将 SPIFFE/SPIRE 添加到企业的云原生解决方案目录中，可以让你在多年的超专业安全和开发人才的基础上构建，而不需要相应的成本。

凭借强大的社区支持几十个到几十万个节点的部署，SPIFFE/SPIRE 在复杂、大规模环境中的运作经验可以满足组织的需求。

## 对于服务提供商和软件供应商

减少客户在使用产品过程中的负担，始终是所有优秀产品经理的首要目标。了解那些表面上看起来无害的功能的实际意义是很重要的。例如，如果一个数据库产品需要支持 TLS，因为这是客户的要求，很简单，在产品中添加一些配置就可以了。

不幸的是，这给客户带来了一些重大的挑战。即使是看似简单的用户管理也面临类似的挑战。考虑一下这两个常见的功能在默认情况下引入的以下客户痛点：

- 谁生成证书和密码，以及如何生成？
- 它们如何被安全地分配给需要的应用程序？
- 如何限制对私钥和密码的访问？
- 这些秘密是如何存储的，才能让它们不会泄漏到备份中？
- 当证书过期，或必须改变密码时，会发生什么？这个过程是否具有破坏性？
- 在这些任务中，有多少是必须要有人类操作的？

在这些功能从客户的角度来看是可行的之前，所有这些问题都需要得到回答。通常，客户发明或安装的解决方案在操作上是很痛苦的。

这些客户的负担是非常真实的。有些组织有整个团队专门负责管理这些负担。通过简单地支持 SPIFFE，上述所有的担忧都会得到缓解。该产品可以集成进现有的基础设施，并**免费**增加 TLS 支持。此外，由 SPIFFE 赋予的客户（用户）身份可以直接取代管理用户凭证（如密码）的需要。

### 平台访问管理

访问一个服务或平台（如 SaaS 服务）也涉及类似的挑战。归根结底，这些挑战为凭证管理所带来的固有困难，尤其是当凭证是一个共享的秘密时。

考虑一下 API 令牌 —— 在 SaaS 提供商中，使用 API 令牌来验证非人类的 API 调用者是很普遍的。它们实际上是密码，而且每一个都必须由客户仔细管理。上面列出的所有挑战都适用于此。支持 SPIFFE 认证的平台大大减轻了与访问平台有关的客户负担，一次性解决了存储、发行和生命周期问题。利用 SPIFFE，问题被简化为简单地授予给定工作负载所需的权限。

## 对于安全从业人员

技术创新不能成为安全产品的抑制因素。开发、分发和部署工具需要与安全产品和方法无缝集成，不影响软件开发的自主性或为组织带来负担。组织需要易于使用的软件产品，并为现有工具增加额外的安全性。

SPIRE 不是所有安全问题的最终解决方案。它并不否定对强大的安全实践和深度防御或分层安全的需要。然而，利用 SPIFFE/SPIRE 提供跨不信任网络的信任根，使组织能够在通往[零信任架构](https://csrc.nist.gov/publications/detail/sp/800-207/final)的道路上迈出有意义的一步，作为全面安全战略的一部分。

### 默认安全

SPIRE 可以帮助减轻 [OWASP 的几个主要威胁](https://owasp.org/www-project-top-ten/)。为了减少通过凭证泄露的可能性，SPIRE 为整个基础设施的认证提供了一个强有力的证明身份。保持证明的自动化使平台默认安全，消除了开发团队的额外配置负担。

对于希望从根本上解决其产品或服务中的信任和身份问题的组织来说，SPIFFE/SPIRE 还通过实现普遍的相互 TLS 认证来解决客户的安全需求，以便在工作负载之间安全地进行通信，无论它们部署在何处。此外，与每个开源产品一样，代码库背后的社区和贡献者提供了更多双眼睛来审查合并前和合并后的代码。这个 [莱纳斯法则（Linus Law）](https://en.wikipedia.org/wiki/Linus's_law)的实施超越了**四只眼睛**的原则，以确保任何潜在的错误或已知的安全问题在进入发布阶段之前被发现。

### 策略执行

SPIRE 的 API 为安全团队提供了一种机制，以便以易于使用的方式在各平台和业务部门执行一致的认证策略。当与定义明确的策略相结合时，服务之间的互动可以保持在最低限度，确保只有授权的工作负载可以相互通信。这限制了恶意实体的潜在攻击面，并可以在策略引擎的默认拒绝规则中触发警报。

SPIRE 利用一个强大的多因素证明引擎，该引擎实时运行，可以肯定地确定加密身份的发放。它还自动发放、分配和更新短期凭证，以确保组织的身份架构准确反映工作负载的运行状态。

### 零信任

在架构中采用零信任模式，可以减少漏洞发生时的爆炸半径。相互认证和信任撤销可以阻止被破坏的前端应用服务器从网络上或集群内可能存在的不相关数据库中渗出数据。虽然不可能发生在网络安全严密的组织中，但 SPIFFE/SPIRE 肯定会增加额外的防御层，以减轻错误配置的防火墙或不变的默认登录带来的漏洞和暴露点。它还将安全决策从 IP 地址和端口号（可以用不可察觉的方式进行操纵）转移到享有完整性保护的加密标识符上。

### 记录和监控

SPIRE 可以帮助改善基础设施的可观测性。关键的 SPIRE 事件，如身份请求和发放，是可记录的事件，有助于提供一个更完整的基础设施视图。SPIRE 还将生成各种行动的事件，包括身份注册、取消注册、验证尝试、身份发放和轮换。然后，这些事件可以被汇总并发送到组织的安全信息和事件管理（SIEM）解决方案，以便进行统一监控。

## 对于开发、运维和 DevOps 来说

即使你可以通过采用和支持 SPIFFE/SPIRE 而不考虑环境，量化对开发人员甚至运维生产力的改善，但最终，它通过在日常工作中重新引入焦点、流程和快乐，缓解了团队所经历的大部分劳累。

### 聚焦

不能让安全成为技术创新的障碍。安全工具和控制需要与现代产品和方法进行无摩擦的整合，不影响开发的自主性或给运维团队带来负担。

SPIFFE 和 SPIRE 提供了一个统一的服务身份控制平面，可通过一致的 API 跨平台和跨域使用，因此团队可以专注于交付应用程序和产品，而不必担心或为目的地进行特殊配置。每个开发人员都可以利用这个 API，安全、轻松地进行跨平台和跨域的认证。

开发人员还可以请求并接收一个身份，然后可用于为所提供的身份建立额外的应用程序特定控制，而运维和 DevOps 团队可以以自动化的方式管理和扩展身份，同时实施和执行消耗这些身份的策略。此外，团队可以使用 OIDC 联盟将 SPIFFE 身份与各种云认证系统（如 AWS IAM）相关联，从而减少对复杂的秘密管理需求。

### 流程

每一个曾经生成的凭证都面临着同样的问题：在某些时候，它将不得不被改变或撤销。这个过程往往是手动的和痛苦的 —— 就像部署一样，越是不经常发生就越是痛苦。对过程的不熟悉和因缺乏及时性或不方便的更新程序而引起的中断是正常的。

当需要轮换时，常要求运维和开发人员进行昂贵的上下文切换。SPIFFE/SPIRE 通过将轮换作为一个关键的核心功能来解决这个问题。它是完全自动化的，并且定期发生，无需人工干预。轮换的频率由运维选择，而且涉及到权衡；然而，SPIFFE 证书每小时轮换一次的情况并不少见。这种频繁和自动化的轮换方式最大限度地减少了与证书生命周期管理有关的运维和开发人员的中断。

值得注意的是，不仅仅轮换是自动化的。证书的最初发放（最常见的是 X.509 证书的形式）也是完全自动化的。这有助于简化开发人员的流程，将生成或采购凭证的任务从启动新服务的检查清单中剔除。

### 互操作性

开发人员和集成商不再需要为组织的安全身份和认证解决方案缺乏互操作性而感到沮丧。SPIRE 提供了一个插件模型，允许开发人员和集成商扩展 SPIRE 以满足他们的需求。如果企业需要一套专有的 API 来生成 SPIRE 的密钥，或者 SPIRE 的中间签名密钥应该存在于特定的专有密钥管理服务（KMS）中，那么这种能力就特别重要。开发人员也不需要担心为即将上线的新工作负载开发定制的包装器，因为该组织正在遵守一个开放的规范。

许多团队不敢改变或删除允许网络间追踪的防火墙规则，因为这可能会对关键系统的可用性产生不利影响。运维可以将身份及其相关策略的范围扩大到应用而不是全局。运维将有信息更改本地范围的身份和策略，而不必担心对下游的影响。

### 改善日常工作

如果没有一个强大的软件身份系统，服务之间的访问管理通常是通过使用网络层面的控制（例如，基于 IP / 端口的策略）来完成的。不幸的是，这种方法产生了大量与管理网络访问控制列表（ACL）相关的操作。随着弹性基础设施的增减，以及网络拓扑结构的变化，这些 ACL 需要不间断的维护。它们甚至会妨碍新基础设施的启用，因为现有的系统现在需要被告知新组件的存在。

SPIFFE 和 SPIRE 致力于减少这种辛劳，因为与网络上的主机和工作负载的安排相比，软件身份的概念相对稳定。此外，它们还为将授权决策委托给服务所有者本身铺平了道路，因为他们最终处于做出这种决策的最佳位置。例如，希望向新的消费者授予访问权的服务所有者，他们不需要关心网络层面的细节就可以创建访问策略 —— 他们可以简单地声明他们希望授予访问权的服务名称，然后继续。

SPIFFE/SPIRE 还致力于提高可观测性、监测以及最终对服务水平目标（SLO）的遵守。通过在许多不同类型的系统中规范软件身份（不一定只是容器化或云原生），并提供身份发布和使用的审计跟踪，SPIFFE/SPIRE 可以在事件发生之前、期间和之后极大地提高态势感知。更成熟的团队甚至会发现，它可以提高预测影响服务可用性问题的能力。
