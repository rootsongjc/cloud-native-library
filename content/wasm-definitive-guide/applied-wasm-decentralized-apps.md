---
linktitle: 第 16 章：应用 WebAssembly——去中心化应用
summary: 去中心化应用 WebAssembly。
weight: 17
icon: book-reader
icon_pack: fas
draft: true
title: 应用 WebAssembly：去中心化应用
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

> 当代技术确实允许分散化，但也允许集中化。这取决于你如何使用这些技术。
> -诺姆-乔姆斯基

我们编写的软件的角色取决于它的部署地点和方式。传统的系统往往是单一的应用程序，接受输入，做一些处理，并产生输出。Unix命令往往是协调在一起的工具，成为脚本化的工作流程。在本书中，我们主要讨论了WebAssembly在客户端用户界面方面的优势，偶尔也会涉足服务器端的技术。如今，我们的软件在云端，通过微服务架构，在嵌入式系统和移动设备中，以及通过无服务器功能，扮演着许多其他角色。
这些不同的角色往往服务于一个架构的目的，试图管理变化，允许独立的技术选择，满足规模需求，或促进重复使用和避免孤岛。对于如何组织和协调这些不同的元素，存在着一种潜在的张力。大多数传统的系统都是集中管理的，但是我们看到越来越多的开发者能够将广泛部署的、分散的系统用于生产。让我们先来讨论一下其中的一些权衡。
集中化与分散化
我们的行业长期以来一直在集中化和分散化之间徘徊。两种安排都不理想；两者都有其好处和负面的副作用。集中化易于控制、索引、优化，并提供共同的经验。

去中心化可以是稳定的，有能力的，并能抵制审查制度。主机、托管服务和孤立的社交媒体网站是中心化的例子。个人电脑、移动设备和文件共享系统是去中心化类型的例子。
拒绝人们使用集中式资源是很容易的。如果不加以维护，它们往往是脆弱的。许多政府试图通过控制信息的获取来控制某些类型的思维。分散的系统很难使其可用和有效，而且经常受到市场压力的影响，在某些时候会鼓励重新分化。
一般来说，网络在这两种力量之间取得了相当好的平衡。一方面，任何人都可以发明一个新的协议，并在一个端口上监听使用它的客户端。在我们将命名纳入其中之前，没有必要的集中化。DNS有一个中心化的方向。尽管为了速度和方便，它是分层分布的，但还是有一个权威。然而，一旦你有了一个域名，你就能够在这个域名中创建你想要的许多资源。你可以自由地分享它们，让你选择的人访问。但是，DNS也可以被控制，正如那些在咖啡馆、飞机上或具有压迫性政权的国家中获得WiFi的人所悲哀地发现的那样。
问题的一部分是基于位置的身份的使用。我们希望通过HTTP协议连接的名字是我们将与之互动的东西，这一点超级有用。也就是说，如果我们决定停止托管这些资源，它们就会消失。在我之前的书中，关于面向资源的架构模式。1我把策划的URI模式确定为一种为交互带来稳定性的方式。但正如任何遇到过断裂链接的人可以证明的那样，这种做法并没有得到广泛的实践。
网络的好处之一是，内容生产者和内容消费者在很大程度上可以做出自己的技术选择。通过使用标准，我们可以交换定义布局和风格选择的声明性结构，在一系列目标中都能很好地工作。长期以来，JavaScript一直是这个故事的一部分，现在，正如你所看到的，WebAssembly也是。
去中心化得益于对标准、协议和工程实践的一致使用，允许任意参与者交换内容。有能力可移植地、安全地、高性能地交换可执行的内容，将扩大可能的范围。
当我们在Parabon建立我们的分布式计算系统时，我们不得不依靠Java语言和平台来获得我们需要的安全和可移植性保证。我们最终是一个集中控制的平台，但在现代环境中，用Java语言建立一个类似的分散系统将是相当简单的。



1面向资源的数据网络架构模式》（Morgan & Claypool）。

WebAssembly、WASI和我们讨论过的各种运行机制。在上一章中，我们看到了这是如何帮助进化我们的计算环境的。正如乔姆斯基所说，我们可以支持任何一种方法；至于我们怎么做，则取决于我们。
我们现在将讨论少数几个去中心化的平台，包括。
•比特币和传统的以太坊
•ewasm
•Polkadot网络
•星际文件系统(IPFS)
从比特币到以太坊
去中心化系统的海报儿童之一是比特币，特别是一般的加密货币。2对于所有的过度炒作和负面评论，从技术和社会角度来看， 中本聪在系统中设计的东西是相当了不起的。在讨论一项技术的整体时，有很多未计算的外部因素需要考虑，但我想把重点放在与当前主题相关的部分。
除了明显的货币概念外，比特币系统充满了经济杠杆，可以推动利益相关者的行为。它的主要成就之一是开发了一个共识机制，允许参与者在不需要真实身份或薄弱的信任概念的情况下就规则及其执行达成一致。现在，大多数人都知道它是如何工作的，但为了清晰起见，我将简要地总结它作为现代区块链思想的基础。当我们讨论Ethereum作为后续平台时，我们将把它与WebAssembly联系起来。
比特币有一个将被释放的最大货币基数。它利用计算上的困难问题来控制随着时间的推移，货币数量不断减少的稳定释放。大致上每隔10分钟左右，就会有一点增加到生态系统中，但随着时间的推移，会逐渐减少。矿工验证了平台上执行的所有交易。这是他们的主要目的。但是，作为对他们努力的回报，他们可以参与一个循环的谜题，找到哈希问题的解决方案。随着越来越多的矿工参与，有更多的力量来攻击这个问题，所以随着时间的推移，它变得越来越难。在目前的形式下，一台计算机需要几十万年才能独自解决一轮。
没有人有这样的时间，所以矿工们通过矿池并行工作，在几分钟内找到它。找到它的节点向其他矿工宣布其解决方案，由他们验证结果。一旦每个人都得出了一个


2Crypto是指密码学。

从比特币到以太坊 | 265

对结果达成共识，这使该节点有权授予自己coinbase的交易。3它将与池中的同伴分享。获胜的节点还必须决定 ，哪些其他交易将在当前区块中结束，然后将其链接到以前的区块。这就是区块链这个名字的由来。
节点上实际运行的东西是相当受限制的。是数量可笑的哈希交易、通信协议，以及涉及执行小的交易的验证。 类似Forth的脚本语言。这主要是验证向另一个账户发送比特币的账户是否控制着与该账户相关的优先密钥。真的没有太多的东西，你也不能用它做什么。有一些回旋余地，但它是一种有意限制的语言，因此很容易在多个平台上支持。
我解释Parabon所做的事情的一种方式是，它就像 SETI@home项目除了它是一个基于Java的先发制人的通用编程解决方案。后面这个区别是因为SETI@home最初只做了一件事。4它只是对数据进行分块处理。因此，SETI@home的研究人员在使用其他人的计算机时可以更自如，因为它只做固定数量的任务。
正如我在 第十五章正如我在第15章所指出的，我们实际上被限制在一个特定类型的问题上，即在平台上运行的意义，但实际代码可以是我们允许的任何东西（即没有磁盘或网络访问）。我们做了原点搜索，基因序列比较，线性扩展，机器学习，热球模拟，以及更多。由于我是公司的第一个工程师，我被问到的一个问题是："你将如何控制一个失控的过程？"我们正在使用其他人的计算机，但我们正在考虑允许客户运行反常的代码。这与我们在电脑、手机、平板电脑和手表上安装的代码的安全性所面临的困境相同。
比特币核心开发者希望保持采矿节点上可能发生的事情 ，更像是SETI@home。Vitalik Buterin和其他人想扩大平台上可以运行的内容。当很明显这是不可能的时候，以太坊项目就应运而生。这两个项目之间的主要区别之一是在节点上运行的东西的性质。以太 eum开发者希望有一种图灵完备的语言。5在不涉及大量理论的情况下，这又回到了失控任务的问题上。因此，让我们快速地走一趟 ，谈谈这个问题。



3coinbase交易是如何以可控的速度铸造比特币的。
4他们最终将他们所做的扩展到一个更普遍的框架，称为 BOINC.
5我不打算把这个问题变成一个有限自动机课程。如果你想挖掘更大的意义（注意，这是个很深的兔子洞），请查看 这篇 维基百科文章.

你是如何解决像停顿问题这样的问题的？
如果我们想在一个计算平台上运行任意的任务，有两种方法可以确定代码是否最终会停止。一种是推理，另一种是尝试，其不幸的副作用是有可能在我们回答这个问题之前等待宇宙的热死亡发生。其中一个也许比另一个更难，而且，事实证明，这并不是尝试和等待（尽管这仍然不被推荐）。
在可计算性理论中，这被称为是一个 不可知 问题 ，这也是比特币开发者对运行图灵完整语言的想法不感冒的原因之一。如果你要补偿人们使用他们的计算机的时间，最好能知道程序是否会完成。6
然而，一切并没有失去。以太坊平台上的采矿节点必须运行arbi-trary合约代码。你在计算上使用的资源越多（存储、CPU时间等），你要支付的费用就越多。如果你开始执行一个合约，让它运行几千年后才意识到你永远无法从 ，那将是非常恼人的。以太坊团队想出了一个很好的解决方案，叫做 "气体"。这个想法是，如果你想开车穿越整个国家，你最好有足够的钱买汽油。否则，在中间的某个地方，你会耗尽，你可能会被卡住。以太坊合约通过快速的启发式评估来确定它的运行成本大概是多少，而启动合约的客户必须拿出那么多或更多。随着合约的执行，它消耗气体并可能耗尽。如果是这样，节点的努力得到了补偿，而你可能会一无所获。这是一个合理的折中方案，可以解决一个难以解决的问题。它也同时迫使合同开发者谨慎行事，在本地测试他们的代码。
以太坊项目还打算在各种硬件和软件平台上运行，所以被执行的代码被虚拟化是有意义的。设计师们创造了少数几种合约语言，但最初流行的一种叫做Solidity。它有一个基于LLVM的编译器，但它发出的字节码可以在他们定制的虚拟机上运行。你可以想象，这是一个不简单的引擎，所以随着WebAssembly的出现，人们对迁移到一个新的虚拟机上产生了浓厚的兴趣，因为他们不需要维护。
然而，气体的概念仍然很重要。由于WebAssembly被想象为几个基于区块链的项目的引擎，所以这个想法也开始出现在我们讨论的平台上，这并不令人惊讶。





6阿兰-图灵在1936年证明，这并不总是可能的。

你如何解决类似于停顿问题的问题？  | 267

在 例 16-1中，你可以看到一个直接在Wat中计算斐波那契数的简单实现，该实现来自Wasmtime的GitHub仓库。如果你需要复习一下这个算法，可以看看我们在 Chapter 第四章.

例16-1.斐波那契数的Wat实现
(模块
(func $fibonacci (param $n i32) (result i32) (if
(i32.lt_s (local.get $n) (i32.const 2)) (返回 (local.get $n))
)
(i32.add
(调用$fibonacci (i32.sub (local.get $n) (i32.const 1))(调用$fibonacci (i32.sub (local.get $n) (i32.const 2))
)
)
(导出 "fibonacci"(func $fibonacci))
)
注意在这个计算中没有时间或成本的概念。它是递归的，但它只是做你要求它做的事情。虽然这不是一个过度饥饿的计算，但你可以让一个节点忙于计算大量的斐波那契数。我们想要的是一个类似gas的概念，它允许我们做我们想做的事情，但要衡量成本，如果超过了这个成本，就把它切断。
中的代码 例16-2 能够做到这一点是因为Wasmtime支持 "燃料 "的概念。请记住，商店实例是运行时实例细节的保存者，所以我们在商店中分配了10,000个燃料单位。我们将.wat文件的编译版本实例化为一个模块，这样我们就可以调用fibonacci()函数。

例16-2.带有燃料的Rust Wasmtime例子
使用anyhow::Result。
使用wasmtime::*;

fn main() -> Result<()> {
let mut config = Config::new(); config.consumere_fuel(true);
让引擎=引擎::new(&config)?
let mut store = Store::new(&engine, ()); store.add_fuel(10_000)?
let module = Module::from_file(store.engine(), "examples/fuel.wat") ?
let instance = Instance::new(&mut store, &module, &[])?

//用越来越高的数字调用 "斐波那契 "的输出，直到我们把它变成一个新的数字。
//耗尽我们的燃料。
让Fibonacci

= instance.get_typed_func::<i32, i32, _>(&mut store, "fibonacci") ?

for n in 1...{
让 fuel_before = store.fuel_consumed().unwrap()。
让输出 = 匹配 fibonacci.call(&mut store, n) { Ok(v) => v。
Err(_) => {
println! ("耗尽燃料计算纤维({})", n);
突破。
}
};
let fuel_consumed = store.fuel_consumed().unwrap() - fuel_before; println!("fib({}) = {}.[消耗了{}燃料]", n, output, fuel_consumed); store.add_fuel(fuel_consumed)?
}
Ok(())
}
一旦我们有了这个实例，我们就开始一个从1到无限大的n的无界循环。很明显，我们不想等待这段代码自己完成。所以，我们要利用燃料。单个指令被标定为有成本，所以我们跟踪我们在每个迭代中花费多少，并从我们的可用燃料存款中减去。一旦我们用完了，我们调用函数的尝试就会失败并脱离循环。
因此，我们有一种通用的能力，可以内置于各种运行时中，使我们能够安全地运行任意代码，而不必担心它是否会失控。从这种能力中建立一个通用的区块链引擎显然是一个潜在的用途。
ewasm
传统的Ethereum虚拟机被称为EVM1。新版本被称为ewasm。编写的 文档和设计过程 都可以在网上找到。这是一项正在进行的工作，一路上有许多变化，但目标仍然是在WebAssembly基础上创建一个新的虚拟机，所有的原因现在应该是显而易见的。一个可能不明显的后果是，鉴于基于LLVM的编译器可以很容易地被重用，这可能会使合同语言开放得更多。
开发人员并没有轻易地做出这个决定。从ewasm文档的 "与其他架构的比较 "部分可以看出，他们考虑了各种中间表示和字节码格式作为这个新虚拟机的可能基础。
走这条路的主要论据显然是速度、效率和安全。我们正在谈论的是一个基于标准的指令集，它将被策划为


辽宁沈阳

并随着时间的推移由W3C扩展。以太坊社区将从这项工作中受益，不必自己做出所有的设计决定。对更多语言的广泛传播和不断增长的工具链支持将为使用开发者已经熟悉的语言创造一条自然的道路，如C/C++、Rust、Go、AssemblyScript等（包括我们将在最后一章讨论的一些新语言！）。
WebAssembly具有内在的可移植性，这也将减轻以太坊开发者社区的负担，因为他们要针对越来越多的硬件平台。这种可移植性和性能提升也将允许更多的以太坊平台本身用Wasm指令来表达，这将在支持多个平台时保持代码库的规模下降。从努力程度和安全审计的代码分析的角度来看，这很有用。
然而，开发人员不想把自己设计成一个角落，所以他们在 ，引入了一些新的想法。第一个是Ewasm合同接口（ECI），它定义了合同模块的结构。模块是以Wasm 的二进制格式进行通信的。合约将被允许导入定义为 以太坊环境接口（EEI）的一部分的符号。这将核心以太坊API暴露给ewasm环境。你可以认为它有点像WASI和WASI-host环境之间的关系。合约被期望输出一个main()函数来启动合约，以及一个Memory实例，用于在合约和其主机环境之间共享数据。同样，现在这些对你来说应该是有意义的。
我不能在这里给你一个关于这个新平台的适当教程，但基本的想法是，合同将需要能够获取和存储数据，调用其他合同中的功能，部署在可知的地址，等等。这个概念仍然是，合同给平台带来的负担越大，它的成本就越高。气体仍然存在，因此将有一个复杂的计量能力，类似于我们在上一节看到的，但有更多细微差别。
由于不同的指令在不同的平台上可能花费更多或更少，他们正在将每个Wasm操作码分配给一个或多个具有固定周期计数的IA-32（x86）指令。预计这将代表用于托管以太坊节点的平均CPU，运行速度约为2.2GHz。一秒钟的CPU使用被配置为花费1000万气。这些数字在时间上不会是固定的，将根据观察和硬件系统的演变进行周密的调整。
一条指令的成本相当于一个周期数×该指令类型的每周期等值气体。例如，get_local指令花费3个周期，预计花费0.0135个气体。将东西装入和装出内存将有类似的成本。访问常量值（如i32.const）不需要任何数据的转换、计算或存储，所以它基本上是一个0气体操作。

由于存在如此多的编译过的EVM1字节码，所以还计划有一个反编译器，将EVM1字节码转换为ewasm字节码，以便向后兼容。有一些不同之处，包括EVM1默认使用256位整数，而ewasm将使用64位整数，但会有一些补偿性的动作，使其在新的环境中都能正常工作，并相应地定价。
最后，还将有预定义的功能合同，这些功能将作为以太坊环境行为的一部分而需要正常运作。这包括用于验证和计量注入的哨兵合约，EVM1到ewasm的反编译，各种散列算法（例如，SHA2-256，RIPEMD160，KEC- CAK256），等等。
这仍然是一项正在进行中的冒险工作，但设计动机是有意义的，而且选择标准与我们强调的对WebAssembly感到兴奋的许多原因一致。分散的系统有很多天生的复杂性。无论他们能做什么，以标准化、安全、优化和扩大可供加密货币智能 合同开发人员选择的合同语言的范围，都可能会加强以太坊平台的整体。
波尔卡多
虽然比特币是加密货币领域的整体市场领导者，但以太坊已经成为第二位。由于它支持多种语言和不断扩大的语言集合中的任意内容，如果你需要针对一个特定的、非比特币的平台，以太坊将是一个可辩护的选择，即使它多年来经历了一些成长的痛苦。但是，如果你不想把自己绑在以太坊这样的单一平台上呢？这就是Polkadot出现的地方。它是一个新的区块链项目，从一开始就考虑到了区块链的互操作性。
Polkadot是由以太坊黄皮书的作者Gavin Wood博士创立。7创立，旨在实现可升级、可扩展、可互操作的区块链能力。它是Web3基金会的基石之一。8
Web3基金会资助的项目之一是将ewasm虚拟 机器引入Polkadot生态系统。该合同被授予Second State，即我们在前一章介绍的WasmEdge平台的制造商。该项目被称为 基板，你可以在以下网站找到该项目 GitHub.有了对ewasm合同接口和执行环境的支持，这就为以下工作打开了大门


7The  Yellow  PaperPaper 著名地描述了以太坊平台上的许多设计动机。如果你对区块链技术更感兴趣，这将值得你花时间阅读。
8基金会 Web3基金会 资助那些能够促进这一分散化愿景的全面成功的项目研究。

波尔卡多特 | 271

以太坊合约可以透明地部署到基于Polkadot的区块链上。这不仅避免了锁定，而且还增加了思想、合同和能力向基于区块链的利益相关者的日益丰富的集合的转移。基于Second State ewasm引擎的其他项目包括 绿洲以太坊和 陴州.
这些只是WebAssembly和区块链风味的去中心化的几个例子。我预计还会有很多很多，但现在我想用我最喜欢的另一个去中心化项目的快速介绍来结束本章，它也是Web3世界的明星。它也将从WebAssembly中受益。
国际文件系统(IPFS)
我必须承认，我最初爱上这个项目只是因为它的名字。当然，我已经开始尊重它，并且诚实地对这个社区自那时以来所能产生的东西感到敬畏，但这个名字仍然很重要。问题是，它不仅仅是一个聪明的名字。它同时也是一种历史的参考，也是对未来的一种向往，而这种向往比我们大多数人所期待的更接近。9人类很快就会重返月球，并向火星进行早期探索。与这些星球上的基地进行通信所涉及的网络延迟将是个问题。IPFS的设计标准的一个方面是帮助解决这些问题。我不会费力解释他们计划如何做到这一点，但也许这将激起你的好奇心去调查。该项目产生了大量的代码、文档、视频和教程，但其 主 website网站 是一个很好的起点。
IPFS最酷的一个方面是，它的开发者围绕着跨项目重复使用的理念设计他们的层。你不必购买他们的整个堆栈，尽管它很优雅。相反，你可以挑选你的项目可能受益的部分，然后从那里开始。这个社区的有用（和可重用）项目的例子包括Multiformats。10libp2p。11和IPLD。12
虽然WebAssembly有很多方式在这个社区出现，但我想强调一个简单的方式。我不打算详细描述IPFS的工作原理，但有一些核心思想。整个事情的基础是 Merkle  DAGs.一个有向无环的


9J.C. R. Licklider将新兴的ARPANET（后来成为互联网）的早期版本称为 银河系 Computer 计算机网络.
10格式 多重允许你以一种自我描述的、灵活的状态来表达哈希值、网络地址和其他有用的值。
11libp2plibp2p 是一个了不起的、可插拔的、广泛的网络堆栈，允许交换传输、多路复用通道、处理高延迟环境，以及更多。
12IPLDIPLD 是一种用于分散式系统的链接数据格式。

图（DAG）是一种图结构，它的标识符是基于节点内容的哈希值。默克尔DAG类似于 Merkle树，对于检测基于内容的可寻址块的变化很有用。
这些决定的净效果是，文件可以被分解成依赖关系 ，这些块之间的依赖关系是由块的实际内容驱动的内容标识符（CIDs）识别的。当文件改变时，唯一需要更新的部分是受影响的块。这样做不会使现有的不可变的Merkle DAG失效，所以多个版本的文件可以同时存在。
如果你没有这类去中心化系统的背景，有很多幕后的细节，我们不需要为了表达我更大的观点而关注。为了隐藏这些细节，我将使用IPFS项目中基于Go的命令行工具。你可以在附录中找到如何安装这些 附录 你可以在附录中找到如何安装这些工具，如果你有兴趣尝试的话。还有很多其他语言的库。如果你不愿意的话，其中很多都不需要你在本地安装和运行东西。正如你很快就会看到的，有HTTP网关用于连接你所知道的网络和IPFS网络。
要使用这些工具，你需要生成一个身份。这不涉及你的名字或任何东西，它只是一个RSA密钥对，可用于数字签名文件和与大网络通信。创建一个节点身份很容易。
brian@tweezer ~> ipfs init
初始化位于/Users/brian/.ipfs的IPFS节点，生成2048位RSA密钥对...完成
同行身份。QmZoRwJ7YYayf5eNWDweN5GCGJjuRnKGJA3susZqjV8Jcb开始，输入。
ipfs cat /ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/readme
以QmZoRwJ开头的长CID指的是我创建的节点。目前还没有任何服务在运行；我们只是拥有允许我们与IPFS网络通信的工具。这包括请求文件的能力。文件与节点有类似的CID，块也是如此。如果你深入研究前面提到的IPLD模型，你会发现它只是一个由命名的、不可改变的节点组成的相互联系的大集合。前面的例子中产生的内容结尾处的注释表明，我们可以通过发出该命令来了解更多的信息。正如你很快会看到的，你不需要让这些工具参与进来，但在这一点上，有些东西需要知道如何与网络进行通信。ipfs命令行工具需要多个参数。其中一个参数使它像Unix的cat命令一样，显示一个文件的内容。在这种情况下，它是一个叫做readme的文件，作为它所在的目录的一个子元素被引用。这种便利性有点像网络URL上的片段标识符，以避免多次往返。我们可以一次性地要求它。结果应该像你在图中看到的那样 图 16-1.


图16-1.从IPFS请求文件
请注意，在该目录中还有其他文件，所以你也可以向他们索取。如果你不知道有哪些文件可用，你可以简单地询问IPFS。注意，这里我使用的是目录名称本身。正如你所看到的，目录中的每个文件都有自己的CID。
brian@tweezer ~/s/ipfs> ipfs ls ↵
/ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv
QmZTR5bcpQD7cFgTorqxZDYaew1Wqgfbd2ud9QqGPAkK2V 1677关于
QmYCvbfNbCwFR45HiNP45rwJgvatpiW38D961L5qAhUM5Y 189 联系方式
QmY5heUM5qgRubMDD1og9fhCPA6QdkMp3QCwd4s7gJsyE7 311 帮助
QmejvEPop4D7YUadeGqYWmZxHhLc4JBUCzJJHWMzdcMe2y 4	ping
QmXgqKTbzdh83pQtKFb19SpMCpDDcKR2ujqk3pKph9aCNF 1681快速启动
QmPZ9gcCEpqKTo6aq61g2nXGUhM4iCL3ewB6LDXZCtioEB 1091 readme
QmQ5vhrL7uv6tuoN9KeVBwd4PwfQkXdVVmDLUZuTNxqgvm 1162 安全-注释
向IPFS添加文件很容易。我将以第6章中的例子为例 Chapter 6第六章 中的例子，我们在浏览器中用C++渲染了一个Windows位图文件。作为提醒，这是该目录中的内容。
brian@tweezer ~/s/i/bitmap> ls -alF
共计1800
drwxr-xr-x 11 brian staff	352 Aug 18 12:27 ./
drwxr-xr-x	3 brian staff	96 Aug 18 12:26 .../
-rw-r-r--@ 1 brian staff	893 Aug 18 12:26 Makefile
-rw-r-r--@ 1 brian staff	948 Aug 18 12:26 Makefile.lib
-rw-r-r--@ 1 brian staff	776 Aug 18 12:26 Makefile.orig
-rw-r-r-@ 1 brian staff 247721 Aug 18 12:26 bitmap_image.hpp
-rw-r-r--@ 1 brian staff	21026 Aug 18 12:26 bitmap_test.cpp
-rw-r--r--	1 brian staff 249496 Aug 18 12:26 bitmap_test.js
-rwxr-xr-x	1 brian staff 257924 Aug 18 12:26 bitmap_test.wasm*.

-rw-r-r-@ 1 brian staff 120054 Aug 18 12:26 image.bmp
-rw-r--r--	1 brian staff	3127 Aug 18 12:26 index.html
要添加这些文件，我们只需进入该目录并发出以下指令。
brian@tweezer ~/s/i/bitmap> ipfs add -r .
添加了 QmUViZoR2ZnnpGXyNxRyVp4kpG64kCYgHLp7w3SdmUsRcf bitmap/Makefile 添加了 QmTPTTSvSdwgjGciTH5EgoPdujcrfXvqqSXDUB83uoFhR5 bitmap/Makefile。lib添加了QmWFi2rEqobqnz9RZbWrtjNRcftkbRUNmKSoxZxDuMzhDT位图/Makefile.origin。
添加了QmZbBUguGknW7wWAkJoZ2XXiDXAsa1zDQgLSuKn7JX7edy bitmap/bitmap_image.hpp 添加了QmNffnsKcGhNveuEXUuwmLYUqMEW33ZpmY3Xke1oK7Y7Uh bitmap/bitmap_test。cpp添加了QmWcuK2svP5qyDaDksvtWanNqDGDoj3CfuqsJXkrKY3MNo bitmap/bitmap_test。js 添加了 QmRwyDerSuwq1VrP56gy28JsXTXyYhPyHxFWH1zctHHe5m bitmap/bitmap_test.wasm 添加了 QmQDwr7R6WxMJgiV4PWkLMJxpzAV8pXhafwfr5omoD93xp bitmap/image.bmp
添加了Qmdn3WDNXNm94c5FFBPUDq7kdfoeRP8JfgyjAd1BroQFni位图/index.html添加了QmZcJdVbvZKz9jB8ymAie6nqPLr6iBGQheEUC8bYraFFpB位图
880.83 KiB / 880.83 KiB [=============================================] 100.00%.
在这一点上，目录有一个标识符，所有的文件也是如此。世界上还没有其他人能够看到这些，即使他们能够猜到节点的身份。13为了发布，你需要启动一个IPFS守护者的实例，这是一个后台服务器，与对等体进行通信并响应来自其他节点的请求。一切都需要一段时间才能开始同步，但运行守护进程的结果看起来像下面这样。
brian@tweezer ~> ipfs daemon
初始化守护进程...
go-ipfs版本：0.9.1-dc2715af6 Repo版本：11
系统版本：amd64/darwin Golang版本：go1.16.6
Swarm监听/ip4/127.0.0.1/tcp/4001 Swarm监听/ip4/127.0.0.1/udp/4001/quic
Swarm listening on /ip4/169.254.245.235/tcp/4001 Swarm listening on /ip4/169.254.245.235/udp/4001/quic Swarm listening on /ip4/192.168.1.169/tcp/4001
Swarm监听/ip4/192.168.1.169/udp/4001/quic Swarm监听/ip6/:1/tcp/4001
Swarm在监听/ip6/::1/udp/4001/quic
Swarm listening on /ip6/fd4b:2552:d54e:3:1444:3cef:8a9b:25f3/tcp/4001 Swarm listening on /ip6/fd4b:2552:d54e:3:1444:3cef:8a9b:25f3/udp/4001/quic Swarm listening on /ip6/fde3:9366:f229:3:18e0:193e:c7d2:8aaa/tcp/4001 Swarm listening on /ip6/fde3:9366:f229:3:18e0:193e:c7d2:8aaa/udp/4001/quic Swarm listening on /p2p-circuit
Swarm announcing /ip4/127.0.0.1/tcp/4001 Swarm announcing /ip4/127.0.0.1/udp/4001/quic Swarm announcing /ip4/192.168.1.169/tcp/4001
Swarm announcing /ip4/192.168.1.169/udp/4001/quic Swarm announcing /ip6/:1/tcp/4001

13我敢打赌，这是不可能的。

Swarm宣布/ip6/::1/udp/4001/quic
API服务器在监听/ip4/127.0.0.1/tcp/5001 WebUI: http://127.0.0.1:5001/webui
网关（只读）服务器在/ip4/127.0.0.1/tcp/8000上监听 守护程序准备就绪
这些看起来很奇怪的标识符向你展示了我前面提到的Multiformats的力量。这些是自我描述的网络引用。我们有各种端口和协议，我们的守护进程正在监听这些端口和协议，以便与它的同伴进行通信。我们有它正在监听的端口，它正在绑定的IP地址（例如，localhost或其他inter-face），它是什么网络类型（例如，ip4与ip6），以及与我们的节点对话时使用的首选传输。注意TCP和UDP上的QUIC之间的区别。这是一个非常强大的想法，它支持弹性、简单的交互模式，以及整个技术栈的可扩展性。
守护进程出去，通过DNS查找引导节点。它可以使用多播DNS（mDNS）来寻找同一网络上的其他节点。它有很多方法与外界沟通。但是，经过一段时间，你可以发现它在与谁交谈，如下所示。我省略了一大堆结果，但我们看到了对等体的多格式网络引用，包括它们的节点身份和与它们对话的首选方式。
brian@tweezer ~/s/ipfs> ipfs swarm peers
/ip4/1.170.45.218/tcp/44262/p2p/QmbsXKVDhxFDgZW6zxrGfgPjXopvhNmGFqqazv1kyZLkv
/ip4/1.254.1.205/tcp/45622/p2p/QmRePjhxRLWJoAXan79JzvxeUwqW5DyeZbHfxi3y1bSke7
/ip4/101.18.52.217/udp/38214/quic/p2p/12D3KooWBjaFGCZ1heSh4HBy6tsj3i348hDeGZhBnR
/ip4/101.70.141.179/udp/7962/quic/p2p/12D3KooWAwcdxRJbDXcYh4FxrNkarnT1BGmqYTedc1
/ip4/104.131.131.82/udp/4001/quic/p2p/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQL
/ip4/104.207.140.198/udp/4001/quic/p2p/12D3KooWFgmp9SgKqGvcE5zEs19iGq16gpMqeV5CY
/ip4/104.236.47.160/tcp/4001/p2p/QmXhDHnhAr1PAE6pK1GbxN1Ez5zmkJHqvSN1GHSgPiuLWP
/ip4/104.238.220.184/tcp/4001/p2p/QmRi2tR7Uf33VmKhGBUNZvFEuCnFwaLLf2FsdYNcLCm4gu
/ip4/104.248.69.187/tcp/4001/p2p/12D3KooWHoqCWMkMuDrauyD6wuJUrPoQfZGPULj99hX94eu
/ip4/107.173.84.101/tcp/4001/p2p/12D3KooWNKQGwEMJXqta2uV2xBSsVrN1jZKd78CF4QossGg
/ip4/107.184.158.170/udp/35299/quic/p2p/12D3KooWQMeiAvzKWGM7V83ENkNqtgJJhdQeQ2xL
/ip4/109.153.171.191/tcp/4001/p2p/12D3KooWK2mqKoGUtZeiJpKCJc3XWLwyk2oC9isNPzvW6f
/ip4/109.194.47.83/tcp/4001/p2p/QmQmfPz9Xn4cNE6vfWcfrozeNDCx9BJFCdRMM3Cnmx2226
/ip4/109.206.48.199/tcp/35317/p2p/QmaY9GdxBY2ovzD1HNhcyBhawTda7gu6QU8rHv6w4pTfqv
/ip4/111.229.166.178/tcp/4001/p2p/12D3KooWAjVr5JL7VgfoNqT8zro2bp9fMKUamF2WAYE4sy
/ip4/111.92.180.99/tcp/53353/p2p/QmYNmBBbzV7AVytNHmVgoHAKd9CvFRWDj32qvHDyjCgJMe
...
守护进程在有人要求时才开始发布文件，但它也启动了几个本地服务。第一个是一个只读的HTTP网关，监听在/ip4/127.0.0.1/tcp/8000。我们一直在使用IPFS Go命令行工具，但我们本地主机上的任何人都可以访问这个服务，而不必考虑这些。
作为一个例子，在IPFS中有一张著名的猫的图片。你可以使用命令行工具询问它的细节。

brian@tweezer ~/s/ipfs> ipfs ls ↵
/ipfs/bafybeidsg6t7ici2osxjkukisd5inixiunqdpq2q5jy4a2ruzdf6ewsqk4/cat.jpg
QmPEKipMh6LsXzvtLxunSPP7ZsBM8y9xQ2SQQwBXy5UY6e 262144
QmT8onRUfPgvkoPMdMvCHPYxh98iKfFkBYM1ufYpnkHJn 181086
你所看到的是与该文件相关的两个块。你也可以使用守护进程中的本地HTTP网关，如图所示 图16-2.URL被遮住了，但没有什么花哨的东西；浏览器只是通过HTTP请求一个文件。

图16-2.通过HTTP网关从IPFS请求文件
本地HTTP网关只有一个。还有一个是由IPFS项目运行的，在https://ipfs.io/ipfs/<CID>，还有一个是由CloudFlare运行的，在https://cloudflare-ipfs.com/ ipfs/<CID>。只要把CID替换成猫图像节点名称和文件名称，你也应该在那里看到它。
我刚才给你看的东西比你可能意识到的要酷，因为这两个都是TLS终止的端点。这意味着你可以通过嗅探数据包来请求IPFS中的文件，而没有人知道你在请求什么。IPFS在绕过审查制度方面是相当成功的。任何试图压制一个网关的行为都有可能引发其他几个网关。

守护进程启动的另一个服务是一个Web应用程序，用于浏览节点的详细信息，并与平台进行更自然的互动。它在上面的守护进程输出中被列为 WebUI，它位于 http://127.0.0.1:5001/webui。作为绑定，只有同一台机器上的用户可以点击它，但你可以将其配置为绑定到一个IP地址，这样任何其他本地网络机器都可以请求文件，而无需安装任何IPFS工具。这个应用程序显示在 图 16-3.

图16-3.通过 WebUI 与 IPFS 交互
在 WebUI 中还有很多其他很酷的事情可以做，但为了回到手头的话题，仔细看看这个窗口的地址栏。5001端口正在为一个网络应用提供服务......来自IPFS。
brian@tweezer ~/s/ipfs> ipfs ls ↵
/ipfs/bafybeiflkjt66aetfgcrgv75izymd5kc47g6luepqmfq6zsf5w6ueth6y
bafkreigqagdyzmirtqln7dc4qfz5sb7tkdexbzmhwoxzbkma3ka 5324 asset-manifest.json
bafkreihc7efnl2prri6j6krcopelxms3xsh7undpsjqbfsasm7i 34494 favicon.ico
bafkreihmzivzfdhagatgqinzy6u4mfopfldebcc4mvim5rzrdpi 4530 index.html
bafkreicayih3vhhjugxshbar5ylocvcqz4xixuqk6cflyxpnuxf 24008 ipfs-logo-512-ice.png bafybeiadzwwymj72nnlyoy6bza4lhps6sofmgmyf6ew5klzwd -	locales/ bafkreicplcott4fe3nnwvz3bidothdtqdvpr5wygbxzoyfozm7t 298	manifest.json bafybeierqn364ton5lp5ogcu4l22gukzprwieaau7lvcan555n3 -	静态/

浏览器会请求网络应用程序所在目录的根CID。 index.html，一如既往，是默认文件。如果你用ipfs cat查看该文件，你会发现它引用了静态资源、样式表等。在某个地方，有人已经发布了这个应用程序。它没有被托管在传统意义上的云托管网站 或任何地方。我对它的来源没有直接的了解，但它是通过HTTP网关在本地提供给我的浏览器。
我之前发布的带有C++渲染的位图文件的目录怎么样了？因为我的守护程序已经运行了一段时间，其他节点现在可以要求得到这个。请看 图16-4 来看我的应用程序被CloudFlare通过TLS前置的惊人的结果。

图16-4.与我通过IPFS HTTP网关在本地发布的文件进行互动
我不打算讨论更多的细节，但我想强调这还意味着什么。请记住，Merkle DAGs是不可改变的。如果我通过修改一两个文件来改变我的应用程序，这些是唯一需要重新发布的东西。记住，发布只是将文件添加到IPFS。他们的编辑将导致其块的哈希值不同，这意味着文件的哈希值不同，这意味着目录的哈希值不同。有一个新的顶级CID。但旧的仍然有效。你可以用DNS玩一些游戏，但我将留给你用IPFS的文档和教程来解决这个问题。

这与WebAssembly有什么关系？这确实是我强调的平台优势的交集，以及它作为另一个用例将产生的影响。我刚刚演示了一个网络应用通过CDN提供服务，其地理分布没有任何其他托管需求。它是在本地提供的，其结果可以沿途被缓存。这包括编译成WebAssem- bly的C++代码，在你碰巧使用的任何浏览器或平台的沙盒中运行。可以同时支持多个版本，用户可以决定何时升级。
你可以在不支付托管费的情况下为世界上任何地方的任意客户提供应用程序。你可以使用你想要的任何语言，在你的用户喜欢的任何平台上实现高性能、互动的系统。由于有安全保护，客户可以放心地运行你的应用程序，没有任何中央机构可以轻易关闭你。
告诉我这不酷。
