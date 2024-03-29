---
weight: 1
title: 2.1 文化变革
date: '2022-05-18T00:00:00+08:00'
type: book
---

企业 IT 采用云原生架构所需的变革根本不是技术性的，而是企业文化和组织的变革，围绕消除造成浪费的结构、流程和活动。在本节中，我们将研究必要的文化转变。

## 从信息孤岛到 DevOps

企业 IT 通常被组织成以下许多孤岛：

- 软件开发
- 质量保证
- 数据库管理
- 系统管理
- IT 运营
- 发布管理
- 项目管理

创建这些孤岛是为了让那些了解特定领域的人员来管理和指导那些执行该专业领域工作的人员。这些孤岛通常具有不同的管理层次，工具集、沟通风格、词汇表和激励结构。这些差异启发了企业 IT 目标的不同范式，以及如何实现这一目标。

但这里面存在很多矛盾，例如开发和运维分别对软件变更持有的观念就是个经常被提起的例子。开发的任务通常被视为通过开发软件功能为组织提供额外的价值。这些功能本身就是向 IT 生态系统引入变更。所以开发的使命可以被描述为“交付变化”，而且经常根据有多少次变更来进行激励。

相反，IT 运营的使命可以被描述为“防止变更”。IT 运营通常负责维护 IT 系统所需的可用性、弹性、性能和耐用性。因此，他们经常以维持关键绩效指标（KPI）来进行激励，例如平均故障间隔时间（MTBF）和平均恢复时间（MTTR）。与这些措施相关的主要风险因素之一是在系统中引入任何类型的变更。那么，不是设法将开发期望的变更安全地引入 IT 生态系统，而是通过将流程放在一起，使变更变得痛苦，从而降低了变化率。

这些不同的范式显然导致了许多额外的工作。项目工作中的协作、沟通和简单的交接变得乏味和痛苦，最糟糕的是导致绝对混乱（甚至是危险的）。企业 IT 通常通过创建基于单据的系统和委员会会议驱动的复杂流程来尝试“修复”这种情况。企业 IT 价值流在所有非增值浪费下步履瞒珊。

像这样的环境与云原生的速度思想背道而驰。专业的信息孤岛和流程往往是由创造安全环境的愿望所驱动。然而，他们通常提供很少的附加安全性，在某些情况下，会使事情变得更糟！

在其核心上，DevOps 代表着这样一种思想，即将这些信息孤岛构建成共享的工具集、词汇表和沟通结构，以服务于专注于单一目标的文化：快速、安全得交付价值。然后创建激励结构，强制和奖励领导组织朝着这一目标迈进的行为。官僚主义和流程被信任和责任所取代。

在这个新的世界中，开发和 IT 运营部门向共同的直接领导者汇报，并进行合作，寻找能够持续提供价值并获得期望的可用性、弹性、性能和耐久性水平的实践。今天，这些对背景敏感的做法越来越多地包括采用云原生应用架构，提供完成组织的新的共同目标所需的技术支持。

## 从间断均衡到持续交付

企业经常采用敏捷流程，如 Scrum，但是只能作为开发团队内部的本地优化。

在这个行业中，我们实际上已经成功地将个别开发团队转变为更灵活的工作方式。我们可以这样开始项目，撰写用户故事，并执行敏捷开发的所有例程，如迭代计划会议，日常站会，回顾和客户展示 demo。我们中的冒险者甚至可能会冒险进行工程实践，如结对编程和测试驱动开发。持续集成，这在以前是一个相当激进的概念，现在已经成为企业软件词典的标准组成部分。事实上，我已经是几个企业软件团队中的一部分，并建立了高度优化的“故事到演示”周期，每个开发迭代的结果在客户演示期间被热烈接受。

但是，这些团队会遇到可怕的问题：我们什么时候可以在生产环境中看到这些功能？

这个问题我们很难回答，因为它迫使我们考虑自己无法控制的力量：

- 我们需要多长时间才能浏览独立的质量保证流程？
- 我们什么时候可以加入生产发布的行列中？
- 我们可以让 IT 运营及时为我们提供生产环境吗？

在这一点上，我们意识到自己已经陷入了戴维・韦斯特哈斯（Dave Westhas）所说的 scrum 瀑布中了。我们的团队已经开始接受敏捷原则，但我们的组织却没有。所以，不是每次迭代产生一次生产部署（这是敏捷宣言的原始出发点），代码实际上是批量参与一个更传统的下游发布周期。

这种操作风格产生直接的后果。我们不是每次迭代都将价值交付给客户，并将有价值的反馈回到开发团队，我们继续保持“间断均衡”的交付方式。间断均衡实际上丧失了敏捷交付的两个主要优点：

- 客户可能需要几周的时间才能看到软件带来的新价值。他们认为，这种新的敏捷工作方式只是“像往常一样”，不会增强对开发团队的信任。因为他们没有看到可靠的交付节奏，他们回到了以前的套路将尽可能多的要求尽可能多地堆放到发布版上。为什么？因为他们对软件能够很快发布没有信心，他们希望尽可能多的价值被包括在最终交付时。
- 开发团队可能会好几周都没有得到真正的反馈。虽然演示很棒，但任何经验丰富的开发人员都知道，只有真实用户参与到软件之中才能获得最佳反馈。这些反馈能够帮助软件修正，使团队去做正确的事情。反馈推迟后，错误的可能性只能增加，并带来昂贵的返工。

获得云原生应用架构的好处需要我们转变为持续交付。我们拥抱端到端拥抱价值的原则，而不是 Water Scrum Fall 组织驱动的间断平衡。设想这样一个生命周期的模型是由 Mary 和 Tom Poppendieck 在《实施精益软件开发（Addison-Wesley）》一书中描述的“概念到现金”的想法中提出来的。这种方法考虑了所有必要的活动，将业务想法从概念传递到创造利润的角度，并构建可以使人们和过程达到最佳目标的价值流。

我们技术上支持这种使用连续交付的工程实践的方法，每次迭代（实际上是次每个源代码提交！）都被证明可以以自动化的方式部署。我们构建部署流水线，可自动执行每次测试，如果该测试失败，将会阻止生产部署。唯一剩下的决定是商业决策：现在部署可用的新功能有很好的业务意义吗？我们已经知道它已经如广告中的方式工作，但是我们要现在就把它们交给客户吗？因为部署管道是完全自动化的，所以企业能够通过点击按钮来决定是否采取行动。

## 从集中治理到分散自治

Waterscrumfall 文化中的一部分已经被特别提及，因为它已经被视为云原生架构采纳的一个关键。

企业通常采用围绕应用架构和数据管理的集中治理结构，负责维护指导方针和标准的委员会，以及批准个人设计和变更。集中治理旨在帮助解决以下几个问题：

- 可以防止技术栈的大范围不一致，降低组织的整体维护负担。
- 可以防止架构选型中的大范围不一致，从而形成组织的应用程序开发的共同观点。
- 整个组织可以一致地处理跨部门关切，例如合规性。
- 数据所有权可由具有全局视野的人来决定。

之所以创造这些结构，是因为我们相信它们将有助于提高质量、降低成本或两者兼而有之。然而，这些结构很少能够帮助我们提高质量节约成本，并且进一步妨碍了云原生应用架构寻求的交付速度。正如单体应用架构导致了限制技术创新速度的瓶颈一样，单一的治理结构同样如此。架构委员会经常只会定期召集，并且经常需要很长的等待时才能发挥工作。即使是很小的数据模型的变化 —— 可能在几分钟或几个小时内完成的更改，即将被委员会批准的变更 —— 将会把时间浪费在一个不断增长的待办事项中。

采用云原生应用架构时通常都会与分散式治理结合起来。建立云原生应用的团队拥有他们负责交付的能力的所有方面。他们拥有和管理数据、技术栈、应用架构、每个组件设计和 API 协议并将它们交付给组织的其余部分。如果需要对某事作出决策，则由团队自主制定和执行。

团队个体的分散自治和自主性是通过最小化、轻量级的结构进行平衡的，这些结构在可独立开发和部署的服务之间使用集成模式（例如，他们更喜欢 HTTP REST JSON API 而不是不同风格的 RPC）来实现。这些结构通常会在底层解决交叉问题，如容错。激励团队自己设法解决这些问题，然后自发组织与其他团队一起建立共同的模式和框架。随着整个组织中的最优解决方案出现，该解决方案的所有权通常被转移到云框架 / 工具团队，这可能嵌入到平台运营团队中也可能不会。当组织正在围绕对架构共识进行改革时，云框架 / 工具团队通常也将开创解决方案。