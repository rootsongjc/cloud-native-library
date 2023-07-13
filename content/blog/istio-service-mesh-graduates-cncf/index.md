---
title: "Istio 成为最快的 CNCF 毕业项目"
summary: "本文介绍了 Istio 作为 CNCF 项目的毕业生的成熟度、安全性、生产就绪、采用和生态系统、CNCF 支持和治理以及社区和企业支持。同时，介绍了 Tetrate 对 Istio 的影响，包括代码贡献、唯一的纯 OSS 企业产品、共同的专业知识、制定标准的安全领导力、社区参与、教育和培训、生态系统扩展等。Tetrate 和 Istio 的交织历史的简要时间线也被列出。最后，提供了使用 Istio 和 Tetrate Service Bridge 的方法和资源。"
date: '2023-07-13T07:00:00+08:00'
draft: false
featured: false
authors: ["Varun Talwar"]
tags: ["Istio"]
categories: ["Istio"]
links:
  - icon: language
    icon_pack: fa
    name: 阅读英文版原文
    url: https://tetrate.io/blog/istio-service-mesh-graduates-cncf/
---

Istio 成为 CNCF 项目的毕业生。这一历史性的时刻代表着 Istio 在云原生领域的成长和成熟，标志着最广泛部署的服务网格迎来了一个令人兴奋的新篇章。Kubernetes 是 [第一个获得毕业资格的项目](https://www.cncf.io/blog/2018/03/06/kubernetes-first-cncf-project-graduate/)，时间是 2018 年。今天，自它作为一个孵化项目进入 CNCF 不到一年的时间，Istio 就毕业了，成为 CNCF 历史上最快的一个。

Tetrate 是由 Istio 创始团队的成员创立的，旨在推广和扩大服务网格的应用，并自创立以来一直是 Istio 最重要的贡献者之一。我们为 Istio 及其社区的辛勤工作和奉献取得了这一里程碑式的认可而感到自豪和兴奋。

## Istio 毕业意味着什么？

CNCF 项目分为三个类别，作为项目成熟度的标志：

**沙盒。** CNCF“沙盒”是 CNCF 内新项目的入口。它为早期阶段的项目提供支持、指导和可见度，以便从 CNCF 社区中获得支持。沙盒旨在为这些项目提供一个安全和协作的环境，以便它们进行实验、创新和成熟。

**孵化。** 孵化项目已经超过了开发的早期阶段，并展示了成为成熟云原生技术的潜力。Istio 凭借其强大的社区和早期采用者的不断生产使用而被接纳为 CNCF 的孵化项目。

**毕业。** 毕业项目在云原生生态系统中已经具有了高度的成熟度、采用率和重要性。它们已经[满足了 CNCF 毕业标准](https://github.com/cncf/toc/blob/main/process/graduation_criteria.md)，被认为是稳定、适用于生产环境的解决方案，已经在现实世界的部署中证明了它们的有效性、可靠性和可扩展性。Istio 现在被 CNCF 正式认可为这样的解决方案，证明了它作为社区强大、开发速度快、在“早期多数”企业中的采用率增长强劲。

## Istio 毕业对用户意味着什么？

对于那些已经将其用作基础设施核心部分的用户，CNCF 毕业是对他们将 Istio 视为现代应用程序网络的关键组件的愿景的验证。对于那些正在寻求现代化基础设施的用户，Istio 的毕业地位是一个强有力的信号，表明它是一个经过验证和强大的选择，可用于在生产中扩展关键应用程序。

对于用户来说，Istio 的毕业地位具有几个含义和优势：

**稳定性和成熟度。** 潜在用户可以信任该项目的稳定性，知道它已经满足了 CNCF 对毕业的严格标准。

**安全性。** Istio 拥有长期而强大的 [发布及时的安全公告](https://istio.io/latest/news/security/)，以及行业最重要的安全思想领袖的战略指导。

**生产就绪。** 毕业地位为用户提供了必要的功能、可扩展性和健壮性，可用于生产环境。

**采用和生态系统。** 毕业项目已经在云原生生态系统中获得了显着的采用。它们被各种规模和行业的组织广泛认可和使用。Istio 的用户从其他采用者的经验中受益。毕业项目的广泛采用还促进了工具、扩展和集成的充满活力的生态系统，可以进一步增强其功能。

**CNCF 支持和治理。** 毕业项目也受益于 CNCF 的支持和治理。CNCF 提供资源、指导和协作框架和社区参与。用户可以信任该项目的长期可持续性和开发路线图，因为它是由致力于推进云原生技术的可信组织支持的。

**社区和企业支持。** 社区提供的集体知识、经验和支持提供了广泛用户群体的利益，可以获得诸如文档、论坛和用户组等资源，并在解决问题和解决问题方面提供潜在帮助。Istio 生态系统还享有来自众多供应商（包括 Tetrate）的企业支持，这些供应商为需要在需要时获得专家支持的组织提供了保证。

## Tetrate 对 Istio 的影响

Tetrate 从一开始就深度参与了 Istio 的开发，并在像美国国防部、Visa、FICO、Informatica、Freddie Mac、Box 等组织中推动了 Istio 的采用。Tetrate 和 Istio 在一些关键方面受益于云原生生态系统：

**代码贡献。** 在过去一年中，Tetrate 工程师积极为 Istio 和 Envoy 项目做出了比任何其他公司都多的代码贡献，这些贡献为 Istio 提供了代码和改进，帮助增强了其功能、性能和总体质量，并推动了 Istio 在社区中的增长和采用。

**唯一的纯 OSS 企业产品。** Tetrate 与 Istio 的合作为企业提供了专业的支持服务和支持，确保 Istio 在生产环境中的顺利采用和运行。 [Tetrate Istio Distro](https://istio.tetratelabs.io/)是第一个也是唯一一个 100% 纯上游 Istio 发行版，已经实现了 FIPS 合规并经过加固，适用于企业和 FedRAMP 环境如[美国空军](https://tetrate.io/press/tetrate-chosen-by-united-states-air-force-to-speed-delivery-of-secure-and-compliant-software-applications-in-1-75m-contract/)。

**共同的专业知识。** Tetrate 的工程师参与了 Istio 的创始和发展，深入了解 Istio 的内部结构，使他们能够为部署 Istio 的组织提供全面的支持和指导。

**制定标准的安全领导力。** Tetrate 是唯一一家与 NIST（负责定义美国联邦政府规定的零信任安全要求的机构）一起编写了微服务的安全标准和最佳实践的服务网格公司。Tetrate 的创始工程师 Zack Butcher 与 NIST 合作，作为微服务安全标准 SP 800-204 系列的共同作者，提供了有关企业如何使用 Istio 确保和简化合规的指导。

**社区参与、教育和培训。** Tetrate 与 Istio 的合作促进了社区参与和知识共享，Tetrate 的专家参加了活动和会议，并[创建了 Tetrate Academy](https://academy.tetrate.io/)，以教育和赋权 Istio 生态系统中的用户和开发人员。超过 5,000 名平台运营和开发人员已经参加了 Tetrate 的免费在线 Istio 和 Envoy 课程，还有数百名成为了[Tetrate 认证的 Istio 管理员](https://academy.tetrate.io/courses/certified-istio-administrator)。

**生态系统扩展。** Tetrate 的产品，例如[Tetrate Service Bridge](https://www.google.com/search?q=tetrate+service+bridge&oq=tetrate+service+bridge&aqs=chrome.0.69i59j0i22i30l2j69i60j69i61.3546j0j7&sourceid=chrome&ie=UTF-8)，扩展了 Istio 的功能，解决了寻求安全和高效服务网格解决方案的组织不断变化的需求。

Istio 和 Tetrate 之间的紧密合作以及 Tetrate 工程师的贡献在 Istio 的增长、发展和成功毕业作为 CNCF 项目中发挥了关键作用，将其确立为业界领先的服务网格解决方案。

## Tetrate 和 Istio 交织历史的简要时间线

- 2016 年：Istio 诞生。Lyft、Google 和 IBM 的一组工程师开发了 Istio，作为管理和保护微服务的开源服务网格平台。Tetrate 的联合创始人 Varun Talwar 担任了 Istio 的创始产品经理。Varun 在初始的 Istio 团队中与 Tetrate 创始工程师 Zack Butcher 一起工作，在 Google 时提供战略方向，推动了该项目的愿景和路线图。[观看 Varun Talwar 关于项目愿景和使命以及如何经受时间考验的讲话›](https://www.youtube.com/watch?v=G1-xOrh-oQE&list=PLm51GPKRAmTnk_VtOxnHe7QXMyFscV0IV&index=5)
- 2017 年：Istio 0.1 发布。
- 2018 年：成立 Tetrate 并发布 1.0 版本宣布 Istio 已准备好生产使用。
- 2019 年：[Istio 1.1 发布，宣布已经准备好用于企业级应用](https://istio.io/latest/news/releases/1.1.x/announcing-1.1/)；Tetrate 扩大 Istio 生态系统，为采用 Istio 的企业提供支持、咨询和培训服务。
- 2020 年。Tetrate 为 Istio 贡献了 VM 工作负载和多集群支持。
- 2021 年。Tetrate 领导了 Istio 生态系统的扩展，推出了 Istio 的[第一个也是唯一的认证考试](https://academy.tetrate.io/courses/certified-istio-administrator)认证 Istio 管理员 - 以及第一个自助式 Istio 课程，Istio Fundamentals[在 Tetrate Academy 上免费提供](https://academy.tetrate.io/courses/istio-fundamentals)。这门课程是[Linux 基金会官方的 Istio 入门课程](https://training.linuxfoundation.org/training/introduction-to-istio-lfs144x/)的基础，迄今已有超过 5,000 人报名。
- 2021 年。 Tetrate 还发布了Tetrate Istio Distro，[安装、管理和升级 Istio 的最简单方法](https://istio.tetratelabs.io/)，以及[其突破性应用程序安全和连接平台的 1.0 版本](https://tetrate.io/tetrate-service-bridge-general-availability/)，Tetrate Service Bridge。
- 2022 年。Tetrate Istio Distro 成为[第一个适用于 FedRAMP 环境的 FIPS 合规、100% 上游 Istio 发行版](https://tetrate.io/how-tetrate-istio-distro-became-the-first-fips-compliant-istio-distribution/)。
- 2022 年。[Istio 加入 CNCF](https://www.cncf.io/blog/2022/09/28/istio-sails-into-the-cloud-native-computing-foundation/)作为孵化器项目。
- 2023 年。Tetrate 宣布[Tetrate Service Express 简化 Istio 在 Amazon EKS 上的部署](https://tetrate.io/tetrate-service-express/)，使生产中的 Istio 部署更快。
- 2023 年。Istio 被 CNCF 晋升为毕业项目，标志着它在云原生生态系统中的重要性。

## 开始使用 Istio

如果您是服务网格和 Kubernetes 安全性方面的新手，我们在[Tetrate Academy](https://tetr8.io/academy)上提供了许多免费的在线课程，可以快速了解 Istio 和 Envoy。

如果您正在寻找快速进入 Istio 生产环境的方法，请查看[Tetrate Istio](https://tetr8.io/tid)

[Tetrate Istio Distro（TID）](https://tetr8.io/tid)，Tetrate 的硬化、完全上游的 Istio 分发，具备 FIPS 验证构建和可用的支持。这是一个很好的开始 Istio 的方式，您可以信任一个可信的分发，有一个专业的团队支持您，如果需要的话，还可以快速实现 FIPS 合规。

随着您向网格添加更多的应用程序，您需要一种统一的方式来管理这些部署，并协调涉及的不同团队的要求。这就是 Tetrate Service Bridge 的作用。了解有关 Tetrate Service Bridge 如何使服务网格更加安全、可管理和有弹性的更多信息，请单击[此处](https://tetr8.io/tsb)，或[联系我们进行快速演示](https://tetr8.io/contact)。
