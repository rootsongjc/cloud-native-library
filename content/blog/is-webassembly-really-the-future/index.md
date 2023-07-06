---
title: "WebAssembly 真的代表着未来吗？"
summary: "这篇文章从多个角度探讨了 WebAssembly（Wasm）的现状和未来。首先，文章引用了 Cloud Native Computing Foundation（CNCF）的报告，指出 WebAssembly 在网页、无服务器、游戏和容器化应用中的应用越来越广泛，并预测 WebAssembly 将显著影响这些应用。其次，文章讨论了 WebAssembly 在容器、边缘计算、编程语言和无服务器应用等方面的应用。虽然 WebAssembly 已经成熟地应用于浏览器，但是在后端应用方面，如边缘设备的应用和部署，仍需要更多的工作。WASI 已经成为将 WebAssembly 扩展到浏览器之外的最佳选择，可以帮助解决在任何配置正确的 CPU 上运行 WebAssembly 运行时的复杂性。WebAssembly 和容器的应用预计将共同增长，尽管 WebAssembly 在某些用例中可以取代容器，但总体来说，两者是互补的产品。WebAssembly 的未来看起来非常光明，但是在可靠和高效地支持 WebAssembly 在浏览器之外的生产用例方面，仍有很多工作要做。"
date: '2023-03-07T11:00:00+08:00'
draft: false
featured: false
authors: ["B. Cameron Gain"]
tags: ["WebAssembly"]
categories: ["WebAssembly"]
links:
  - icon: language
    icon_pack: fa
    name: 阅读英文版原文
    url: https://thenewstack.io/is-webassembly-really-the-future
---

> 译者注：这篇文章从多个角度探讨了 WebAssembly（Wasm）的现状和未来。首先，文章引用了 Cloud Native Computing Foundation（CNCF）的报告，指出 WebAssembly 在网页、无服务器、游戏和容器化应用中的应用越来越广泛，并预测 WebAssembly 将显著影响这些应用。其次，文章讨论了 WebAssembly 在容器、边缘计算、编程语言和无服务器应用等方面的应用。虽然 WebAssembly 已经成熟地应用于浏览器，但是在后端应用方面，如边缘设备的应用和部署，仍需要更多的工作。WASI 已经成为将 WebAssembly 扩展到浏览器之外的最佳选择，可以帮助解决在任何配置正确的 CPU 上运行 WebAssembly 运行时的复杂性。WebAssembly 和容器的应用预计将共同增长，尽管 WebAssembly 在某些用例中可以取代容器，但总体来说，两者是互补的产品。WebAssembly 的未来看起来非常光明，但是在可靠和高效地支持 WebAssembly 在浏览器之外的生产用例方面，仍有很多工作要做。

[云原生计算基金会 (CNCF)](https://cncf.io/?utm_content=inline-mention) 最近的[年度调查包括](https://www.cncf.io/reports/cncf-annual-survey-2022/)[WebAssembly (Wasm)](https://thenewstack.io/how-webassembly-could-streamline-cloud-native-computing/) 大胆声明：“容器是新常态，WebAssembly 是未来”。

这句话预示了很多事情，不仅是关于 WebAssembly 的路线图和发展，还有它目前在计算领域的地位。据 CNCF 称，37% 的最终用户组织已经具有使用 WebAssembly 部署应用程序的经验。根据 CNCF 报告，虽然其中许多用途是为了测试 Wasm 的优点，但 [WasmEdge](https://wasmedge.org/) 和 [WAMR](https://github.com/bytecodealliance/wasm-micro-runtime) 是最常用的运行时。

CNCF 生态系统负责人 Taylor Dolezal 在对 TheNewStack 电子邮件回复中说。

但是 WebAssembly 的采用将走向何方，它的路线图和未来在计算中的位置是什么样的？让我们看看 Wasm 在[容器](https://thenewstack.io/containers/)、[边缘](https://thenewstack.io/edge-computing/)和其他应用程序、[编程语言](https://thenewstack.io/25-most-popular-programming-languages-used-by-devops-pros/) 和无服务器集成及其未来。

## 未来

可以说，您可能会争辩说 Wasm 与未来无关，但它在最初创建的所有主要网络浏览器中的使用已经很重要了。但是，虽然 Wasm 在浏览器中已经成熟，但在它成为未来的一部分用于后端应用程序之前，还需要做更多的工作，例如它在边缘设备中的使用和部署。

事实上，它并不像将 [Python](https://thenewstack.io/an-introduction-to-python-for-non-programmers/) 添加到 Wasm 然后通过托管 Wasm 运行时的 Wasi 运行包那么简单。 [用于机器学习](https://thenewstack.io/machine-learning/)和 Python 专门适配的数据分析等后端应用，其在刚刚开发编译的大量第三方依赖的 Wasm 中的应用密切相关。

Wasm [平台即服务 (PaaS)](https://thenewstack.io/pipelines-paas-continuously-delivering-continuous-delivery/) 产品或平台尚不存在，可轻松用于将 WebAssembly 借给后端应用程序。也就是说，Wasm 在浏览器之外的应用才刚刚兴起。

Enterprise Management Associates 的分析师 [Torsten Volk](https://www.linkedin.com/in/torstenvolk)  告诉 The New Stack。缺少什么，我们会一路找到。届时，开源项目和商业供应商将介入以填补这些空白，并提供最佳的开发人员和 [DevOps](https://thenewstack.io/the-what-why-and-how-of-devops/) 体验。 ”

将服务器端（ss-Wasm）WebAssembly 与用于浏览器应用程序的 Wasm 区分开来，ss-Wasm 有着光明的未来，而采用 ss-Wasm 的道路很长，而且“其中很多仍然需要映射”，[Wiqar Chaudry](https://www.linkedin.com/in/wiqar?miniProfileUrn=urn%3Ali%3Afs_miniProfile%3AACoAAACh3tYBq_83ujeBLYcODDpkucuxdpr-KhU&lipi=urn%3Ali%3Apage%3Ad_flagship3_detail_base1H2B1rTin6PqQia%3D)，Xmbia 项目协作平台的创始人和 CEO，告诉 The New Stack。

“有两个非常简单的指标：Wasm 在创建软件时是否有明确的经济价值主张？它会降低成本，帮助公司和开发商赚更多钱，还是帮助释放其他类型的未实现价值？”Chaudry 说，他也参与了 [Wasmer](https://wasmer.io/) 项目，目前担任顾问。

“第二个是它的技术价值主张。它是否吸引了足够多的开发人员并解决了足够多的技术难题，使他们能够负担得起使用 Wasm 作为其技术栈的一部分？”

## WASI

就目前而言，WASI 已成为将 Wasm 范围扩展到浏览器之外的最佳选择。被描述为 WebAssembly 的[模块化系统接口](https://wasi.dev/)，它已被证明有助于解决在任何有正确配置的 CPU 的地方运行 Wasm 运行时的复杂性——这一直是 WebAssembly 自创建以来的主要卖点之一。

Fermyon Technologies 的联合创始人兼首席执行官 [Matt Butcher](https://www.linkedin.com/in/mattbutcher/) 告诉 The New Stack：“我相信 WebAssembly 作为一种通用技术的关键特性是为了支持 [WebAssembly 系统接口 (WASI)](https://thenewstack.io/mozilla-extends-webassembly-beyond-the-browser-with-wasi/)”。 “WASI 允许开发人员在他们的代码中使用熟悉的系统习惯用法，例如打开文件和读取环境变量，而不会破坏 WebAssembly 安全模型。随着 WASI 支持变得更加广泛，我们将看到 WebAssembly 用例的爆炸式增长。” 

然而，WASI 仍在走向成熟。 “WASI 的第一个版本向我们展示了 WebAssembly 的潜力。第二个版本 Preview 2 将在几个月后发布，”Butcher 说。 “Preview 2 中添加的网络功能将开辟大量新用途。”

Cosmonic 首席执行官兼联合创始人 [Liam Randall](https://www.linkedin.com/in/hectaman) 表示，WebAssembly 将利用组件和 WASI 将通用应用程序库抽象为通用可拔插组件。他说，发布 - 订阅消息传递或特定 SQL 服务器等组件作为抽象而不是与特定库的紧密耦合交付给应用程序。

“当容器出现时，它们更小，启动速度更快，并为开发人员提供了比虚拟机更小的表面区域来配置和维护，”Randall 说。 “WebAssembly 模块延续了这一趋势，体积更小，启动速度更快，并利用组件来减少开发人员编写和维护的代码量。”

“更重要的是，组件模型是一种新的应用程序方法，它允许面向能力的安全性，并使平台运营商更容易安全地运行应用程序。”

Wasm 使用 WASI 进行系统级集成 API 进一步提高了它作为通用运行时的可行性，Dolezal 说：“WebAssembly 在安全环境中托管不受信任代码的能力也是一个重要的好处。”

## 与容器的关系

正如 CNCF 报告所述，[容器](https://thenewstack.io/containers/) 确实是“新常态”，尤其是在云原生领域。在某些用例中，Wasm 可以取代容器，但总的来说，WebAssembly 和容器的采用将同步增长。

“我绝对相信 Kubernetes 和 Wasm 是互补的产品，Kubernetes 负责配置和扩展基础设施，而 Wasm 在该基础设施之上提供应用程序，包括其运行时，”Volk 说。

Kubernetes 采用的路径可以作为 Wasm 如何以及何时大规模采用的可能模型。 “由于 Kubernetes 的广泛可用性以及使用、扩展和支持它的工具，Kubernetes 被广泛采用，”Chaudry 说。 “如果 Kubernetes 不像 AKS、EKS 或 GKE 那样容易获得，我们就会看到更少的采用和使用。WebAssembly 也会走同样的路。”

Wasm 也只解决了容器所做的一些问题，他说：“容器更复杂，运营开销更高。两者之间的权衡使得两者同步增长是合理的。”

Butcher 表示，当 DockerHub 开始支持新的工件存储规范时，Wasm 社区意识到，与其重新发明轮子，不如将 Wasm 运行时存储在 Docker Hub 等 [Open Container Initiative registries](https://thenewstack.io/oci-reveals-governance-structure-amid-debate-focus/) 中会更好。 

例如，本月 Fermyon 的 Spin 0.8 开始支持 OCI 注册表。 “虽然我们最初不确定 OCI 注册表是否是正确的分发机制，但标准的演变加上 Docker Hub 的支持改变了我们的想法，”Butcher 说。 “我们致力于使用 OCI 注册表分发 WebAssembly 应用程序，并且今天已经实现了。”
