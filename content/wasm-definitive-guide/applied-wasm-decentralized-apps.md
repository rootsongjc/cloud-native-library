---
linktitle: "第 16 章：WebAssembly 的去中心化应用"
summary: "这篇文章是《WebAssembly 权威指南》的第十六章，介绍了 WebAssembly 在去中心化场景下的应用。"
weight: 17
icon: book-reader
icon_pack: fas
draft: fasle
title: "WebAssembly 的去中心化应用"
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

> 译者注：这篇文章是《WebAssembly 权威指南》的第十六章，介绍了 WebAssembly 在去中心化场景下的应用。

软件的作用取决于它的部署位置和方式。 传统系统往往是接受输入、进行一些处理并产生输出的单一应用程序。 Unix 命令通常是嵌入在脚本工作流程中的工具。 在本书中，我们主要讨论了 WebAssembly 在客户端用户界面方面的优势，偶尔也会涉足服务器端技术。 今天，我们的软件通过微服务架构、嵌入式系统和移动设备以及无服务器函数在云中扮演许多其他角色。

这些不同的角色通常服务于架构目的，以试图管理变更、允许独立的技术选择、满足规模需求或促进重用并避免孤岛。 组织和协调这些不同的元素比较棘手。 大多数传统系统都是集中管理的，但我们看到越来越多的开发人员能够将广泛部署的分散式系统投入生产。 让我们首先讨论其中的一些权衡。

## 集中化与去中心化

我们的行业长期以来一直在集中化和去中心化之间徘徊。这两种安排都不是理想的； 两者各有与缺点。中心化易于控制、索引、优化并提供共同的体验。

权力下放可以是稳定的、有能力的和抗审查的。托管服务和孤立的社交媒体网站是集中化的例子。个人电脑、移动设备和文件共享系统是分散类型的例子。

拒绝人们访问集中资源很容易。如果不加以维护，它们往往很脆弱。去中心化系统努力使资源可用和有效，并且经常受到市场压力的影响，这些压力在某些时候会鼓励重新分化。

总的来说，网络在这两种力量之间取得了很好的平衡。一方面，任何人都可以发明一种新协议并在端口上监听使用它的客户端。在我们将命名纳入其中之前，没有必要集中化。DNS 有一个集中的方向。尽管为了速度和方便，它是分层分布的，但权限是一个。但是，一旦拥有域名，你就可以在该域名内创建任意数量的资源。你可以自由分享它们，并让你选择的任何人都可以访问它们。

部分问题是基于位置的身份的使用。我们要通过 HTTP 协议连接的名称就是我们要与之交互的名称，这非常有用。也就是说，如果我们决定停止托管这些资源，它们就会消失。在我的上一本书中，关于面向资源的架构模式[^1]。我将精选的 URI 模式确定为一种为交互带来稳定性的方式。但是，任何遇到过失效链接的人都可以证明，这种做法并未得到广泛应用。

网络的好处之一是内容制作者和内容消费者可以在很大程度上做出自己的技术选择。通过使用标准，我们可以交换声明式结构，以定义适用于一系列目标的布局和样式选择。JavaScript 长期以来一直是这个故事的一部分，现在，正如你所见，WebAssembly 也是如此。

去中心化受益于标准、协议和工程实践的一致使用，允许任意参与者交换内容。能够以可移植、安全和高效的方式交换可执行内容将扩大可能的范围。

当我们在 Parabon 构建我们的分布式计算系统时，我们不得不依赖 Java 语言和平台来获得我们需要的安全性和可移植性保证。我们最终得到了一个集中控制的平台，但在现代环境中，用 Java 语言构建一个类似的分散式系统会相当简单。

WebAssembly、WASI 和我们讨论过的各种机制。在上一章中，我们看到了这如何帮助改进我们的计算环境。

现在我们将讨论一些去中心化平台，包括：

- 比特币和传统的以太坊
- ewasm
- Polkadot 网络
- 星际文件系统（IPFS）

## 从比特币到以太坊

去中心化系统的典型代表之一是比特币，以及一般的加密货币[^2]。对于所有过度炒作和负面评论，从技术和社会的角度来看，中本聪在系统中的设计是非常了不起的。在讨论整个技术时，有许多外部因素需要考虑，但我想关注与手头主题相关的部分。

除了明显的金钱概念之外，比特币系统充满了驱动利益相关者行为的经济杠杆。它的主要成就之一是开发了一种共识机制，允许参与者就规则及其执行达成一致，而无需真实身份或薄弱的信任概念。现在，大多数人都知道它是如何工作的，但为了清楚起见，我将把它作为现代区块链思维的基础进行简要总结。当我们讨论以太坊作为后续平台时，我们会将其与 WebAssembly 联系起来。

比特币拥有有史以来最大的货币基础之一。 它使用一个计算难题来控制随着时间的推移逐渐减少的货币数量的稳定释放。 大约每隔 10 分钟左右，生态系统就会增加一点，但随着时间的推移逐渐减少。 矿工验证平台上执行的所有交易。 这是他们的主要目的。 但是，作为他们努力的回报，他们可以参与一个循环拼图，找到哈希问题的解决方案。 随着越来越多的矿工参与，解决问题的能力会越来越好，因此随着时间的推移会越来越难。 以目前的形式，一台计算机需要数十万年才能自行解决一轮问题。

没有人有那么多时间，所以矿工们通过矿池并行工作，以在几分钟内找到它。找到它的节点向其他验证结果的矿工宣布其解决方案。一旦每个人都对结果达成共识，这使该节点有权授予自己 coinbase 的交易[^3]。它将与池中的同伴分享。获胜的节点还必须决定 ，哪些其他交易将在当前区块中结束，然后将其链接到以前的区块。这就是区块链这个名字的由来。

节点上实际运行的内容相当有限。执行小交易时涉及的散列交易、通信协议和验证数量多得离谱。[类似 Forth](https://en.wikipedia.org/wiki/Forth_(programming_language)) 的脚本语言。这基本上验证了向另一个账户发送比特币的账户控制着与该账户关联的优先级密钥。它真的没什么用，你也不能用它做很多事情。有一些余地，但它是一种有意限制的语言，因此很容易在多个平台上得到支持。

我解释 Parabon 所做的事情的一种方式是，它类似于 [SETI@home 项目](https://en.wikipedia.org/wiki/SETI@home)，只是它是一个基于 Java 的抢占式通用编程解决方案。后者的区别是因为 SETI@home 最初只做了一件事[^4]。它只是将数据分块。因此，SETI@home 研究人员可以更轻松地使用其他人的计算机，因为它只执行固定数量的任务。

正如我在[第 15 章](../applied-wasm-cloud-and-edge/)中指出的那样，就在平台上运行的意义而言，我们实际上被限制在一个特定的问题类型上，但实际的代码可以是我们允许的任何东西（即没有磁盘或网络访问）。我们进行了起源搜索、基因序列比较、线性缩放、机器学习、热球模拟等等。由于我是公司的第一位工程师，我被问到的一个问题是：“你将如何控制失控过程？” 我们正在使用其他人的计算机，但我们正在考虑让客户运行不自然的代码。这与我们在计算机、手机、平板电脑和手表上安装的代码的安全性所面临的困境相同。

Bitcoin Core 开发者希望保留挖掘节点上的可能性，更像是 SETI@home。Vitalik Buterin 和其他人希望扩展可以在平台上运行的内容。当很明显这是不可能的时候，以太坊项目诞生了。这两个项目之间的主要区别是在节点上运行的内容的性质。以太坊开发人员想要一种图灵完备的语言[^5]。在不深入理论的情况下，这又回到了失控任务的问题上。因此，让我们快速了解一下它吧。

## 如何解决像停机问题这样的问题的？

如果我们想在一个计算平台上运行任意任务，有两种方法可以判断代码最终是否会停止。一个是推理，另一个是尝试。其中一个可能比另一个更难，而且事实证明，这并不是真正的尝试和等待（尽管仍然不推荐这样做）。

在可计算性理论中，这被称为[不可知论问题](https://en.wikipedia.org/wiki/Undecidable_problem)，这也是比特币开发人员没有接受运行图灵完备语言想法的原因之一。如果你要补偿人们使用计算机的时间，最好知道程序最终是否会完成[^6]。

以太坊平台上的挖矿节点必须运行任意合约代码。你在计算上使用的资源越多（存储、CPU 时间等），你支付的费用就越多。如果你开始执行合约，让它运行数千年却发现你永远也获得不了报酬，那将是非常恼人的。以太坊团队想出了一个很棒的解决方案，叫做“Gas”。这个想法是，如果你想开车穿越全国，你最好有足够的钱买汽油。否则，在中间的某个地方，你用完了，你就走不了了。以太坊合约使用快速启发式方法来大致确定运行成本，而启动合约的客户必须支付那么多或更多的费用。随着合约的执行，它会消耗 gas 并可能会用完。如果是这样，节点会因为他们的努力而得到补偿，而你可能什么也得不到。这是解决难题的合理妥协。它还迫使合约开发人员谨慎行事并在本地测试他们的代码。

以太坊项目还打算在各种硬件和软件平台上运行，因此对代码进行虚拟化是有意义的。设计师们创造了一些合约语言，但最开始流行的一种叫做 Solidity。它有一个基于 LLVM 的编译器，发出的字节码在他们的自定义虚拟机上运行。可以想象，这是一个非常重要的引擎，因此随着 WebAssembly 的出现，人们对迁移到新的虚拟机产生了浓厚的兴趣，因为它们不需要维护。

然而，gas 的概念仍然很重要。由于 WebAssembly 被设想为多个基于区块链的项目的引擎，因此这个想法开始出现在我们讨论的平台上也就不足为奇了。

在例 16-1 中，你可以看到直接在 Wat 中计算斐波那契数列的简单实现，它来自 Wasmtime 的 GitHub 存储库。如果你需要重温此算法，请查看我们在[第 4 章](../using-c-cpp-and-wasm/)中的示例。

例16-1. 斐波那契数的 Wat 实现

```c
(module
 (func $fibonacci (param $n i32) (result i32)
  (if
   (i32.lt_s (local.get $n) (i32.const 2)) 
   (return (local.get $n))
  )
  (i32.add
   (call $fibonacci (i32.sub (local.get $n) (i32.const 1)))
   (call $fibonacci (i32.sub (local.get $n) (i32.const 2))) 
  )
 )
 (export "fibonacci" (func $fibonacci))
)
```

请注意，此计算中没有时间或成本的概念。它是递归的，但它只是做你要求它做的事情。虽然这不是一个耗尽资源的计算，但你可以让节点忙于计算大量斐波那契数。我们想要的是一个类似于 gas 的概念，它允许我们做想做的事，但要衡量成本，如果超过成本就将其终止。

例 16-2 中的代码能够做到这一点，因为 Wasmtime 支持 “gas” 的概念。请记住，store 实例是运行时实例详细信息的保管人，因此我们在 store 中分配了 10000 个 gas 单元。我们将 `.wat` 文件的编译版本实例化为一个模块，以便我们可以调用 `fibonacci()` 函数。

例 16-2. 带 gas 的 Rust Wasmtime 示例

```rust
use anyhow::Result;
use wasmtime::*;
fn main()->Result<()>
{
	let mut config = Config::new();
	config.consume_fuel( true );
	let	engine	= Engine::new( &config ) ?;
	let mut store	= Store::new( &engine, () );
	store.add_fuel( 10_000 ) ?;
	let module = Module::from_file( store.engine(), "examples/fuel.wat" ) ?;
  let instance = Instance::new( &mut store, &module, &[] ) ?;
/*
 * 用越来越高的数字调用 "斐波那契" 的输出，直到我们把它变成一个新的数字。
 * 耗尽我们的燃料。
 */
	let fibonacci
		= instance.get_typed_func::< i32, i32, _ > (&mut store, "fibonacci") ?;
	fornin1..{
		let fuel_before = store.fuel_consumed().unwrap(); 
    let output = match fibonacci.call( &mut store, n )
		{
			Ok( v )		= > v,
			Err( _ )	= > {
				println !("Exhausted fuel computing fib({})", n);
				break;
			}
		};
		let fuel_consumed = store.fuel_consumed().unwrap() - fuel_before; 
    println !("fib({}) = {} [consumed {} fuel]", n, output, fuel_consumed);
    store.add_fuel( fuel_consumed ) ?;
	}
	Ok( () )
}
```

一旦我们有了这个实例，我们就开始一个从 1 到无限大的 n 的循环。显然，我们不想等待这段代码自行完成。所以，我们要使用 gas。个别指令被校准为有成本，因此我们跟踪每次迭代花费了多少，并从我们可用的 gas 存储中减去。一旦用完，我们调用该函数的尝试就会失败并跳出循环。

因此，我们拥有可以内置到各种运行时中的通用能力，使我们能够安全地运行任意代码，而不必担心它是否会失控。利用此功能构建通用区块链引擎显然是一种潜在用途。

## ewasm

传统的以太坊虚拟机称为 EVM1。新版本称为 ewasm。[文档和设计过程](https://ewasm.readthedocs.io/en/mkdocs/)都可以在线获得。这项工作正在进行中，可能会有很多变化，但目标仍然是在 WebAssembly 之上创建一个新的虚拟机，其原因现在应该是显而易见的。一个可能并不明显的结果是，这可能会更多地开放合约语言，因为基于 LLVM 的编译器可以很容易地重用。

开发者并没有轻率地做出这个决定。从 ewasm 文档的“与其他架构的比较”部分可以看出，他们考虑了各种中间表示和字节码格式作为这个新虚拟机的基础。

走这条路的主要理由显然是速度、效率和安全。我们谈论的是基于标准的指令集，W3C 将随着时间的推移对其进行策划和扩展。以太坊社区将从这项工作中受益，而不必自己做出所有设计决策。对更多语言的广泛传播和不断增长的工具链支持将为开发人员使用已经熟悉的语言创造一条自然路径，例如 C/C++、Rust、Go、AssemblyScript 等（包括一些新语言！）。

WebAssembly 本质上是可移植的，这也将减轻以太坊开发者社区的负担，因为他们的目标硬件平台越来越多。这种可移植性和性能提升还将允许更多的以太坊平台本身用 Wasm 指令表达，这将在支持多个平台的同时保持代码库大小。从代码分析的角度来看，这对于工作量和安全审计很有用。

但是，开发人员不想钻墙角，因此他们引入了一些新想法。 第一个是 ewasm 合约接口（ECI），它定义了合约模块的结构。 模块以 Wasm 的二进制格式进行通信。 合约将被允许导入定义为以太坊环境接口（EEI）一部分的符号。 这将核心以太坊 API 暴露给 ewasm 环境。 你可以把它想成有点像 WASI 和 WASI-host 环境之间的关系。 合约应该导出一个 `main()` 函数来启动合约，以及一个 Memory 实例来在合约和它的主机环境之间共享数据。 同样，这些现在对您来说应该有意义。

我无法在这里为你提供关于这个新平台的适当教程，但基本思想是合约需要能够获取和存储数据、调用其他合约中的函数、在已知地址部署等。这个概念仍然是合约给平台带来的负担越多，它的成本就越高。Gas 仍然存在，因此会有类似于我们在上一节中看到的复杂计量功能，但有更多细微差别。

由于不同的指令在不同平台上的成本或多或少，因此他们将每个 Wasm 操作码分配给一个或多个具有固定循环计数的 IA-32 (x86) 指令。这预计代表用于托管以太坊节点的平均 CPU，运行频率约为 2.2GHz。一秒钟的 CPU 使用率被配置为消耗 1000 万 gas。这些数字不会及时固定，会根据观察和硬件系统的演进进行仔细调整。

一条指令的成本等于该指令类型的周期数 x 每个周期的 gas 等效值。例如，`local.get` 指令需要 3 个周期，预计消耗 0.0135 gas。将数据放入和取出内存也会有类似的成本。访问常量值（如 i32.const ）不需要任何数据转换、计算或存储，因此它基本上是一个 0 gas 操作。

由于存在如此多的已编译 EVM1 字节码，因此还计划有一个反编译器，将 EVM1 字节码转换为 ewasm 字节码以实现向后兼容。它们之间存在一些差异，包括 EVM1 默认使用 256 位整数，而 ewasm 将使用 64 位整数，但会有一些补偿措施使其在新环境中都能正常工作，并相应定价。

最后，作为以太坊环境行为的一部分，正常运行所需的功能也将有预定义的合约。这包括用于验证和计量注入的哨兵合约、将 EVM1 反编译为 ewasm、各种哈希算法（例如 SHA2-256、RIPEMD160、KEC-CAK256）等等。

这仍然是一项正在进行中的冒险工作，但设计动机是有道理的，而且选择标准与我们强调的对 WebAssembly 感到兴奋的许多原因一致。去中心化系统具有很多固有的复杂性。无论他们能做些什么来标准化、保护、优化和扩展加密货币智能合约开发人员可用的合约语言范围，都可能会加强整个以太坊平台。

## Polkadot

虽然比特币是加密货币领域的整体市场领导者，但以太坊已位居第二。凭借对多种语言的支持以及其不断扩大的语言集合中的内容，如果你需要针对特定的非比特币平台，以太坊是一个可靠的选择。但是，如果你不想将自己束缚在像以太坊这样的单一平台上怎么办？ 这就是 Polkadot 的用武之地。它是一个从一开始就考虑到区块链互操作性的新区块链项目。

[Polkadot](https://polkadot.network/) 由以太坊黄皮书作者 Gavin Wood 博士创立的[^7]。为了实现可升级、可扩展和可互操作的区块链功能。它是 Web3 基金会的基石之一[^8]。

Web3 基金会资助了项目，将 ewasm 虚拟机引入 Polkadot 生态系统。合约授予了我们在上一章中介绍的 WasmEdge 平台的提供商 Second State。该项目名为 [Substrate](https://docs.substrate.io/)，你可以在 [GitHub](https://github.com/second-state/substrate-ewasm) 上找到它。随着对 ewasm 合约接口和执行环境的支持，这为以太坊合约被透明地部署到基于 Polkadot 的区块链打开了大门。这不仅避免了锁定，而且还增加了想法、合约和能力向越来越丰富的基于区块链的利益相关者的转移。其他基于 Second State ewasm 引擎的项目包括 [Oasis Ethereum](https://oasis.app/) 和 [Parastate](https://www.parastate.io/)。

这些只是 WebAssembly 和区块链风格的去中心化的几个例子。我预计还会有更多，但现在我想通过快速介绍另一个我最喜欢的去中心化项目来结束本章，它也是 Web3 世界的明星。它还将受益于 WebAssembly。

## 星际文件系统（IPFS）

我必须承认，我最初只是因为它的名字（InterPlanetary File System）而爱上了这个项目。当然，我已经开始尊重它，并且老实说对这个社区从那时起能够产生的东西感到敬畏，但这个名字仍然很重要。问题是，这不仅仅是一个聪明的名字。它同时是历史参考和对比我们大多数人预期更接近的未来的向往[^9]。人类将很快重返月球，并对火星进行早期探索。与这些行星上的基地通信所涉及的网络延迟将是一个问题。IPFS 设计标准的一个方面就是帮助解决这些问题。我不会费心解释他们打算如何做到这一点，但也许这会激起你的好奇心进行调查。该项目产生了大量代码、文档、视频和教程，但它的[网站](https://ipfs.tech/)是一个很好的起点。

IPFS 最酷的方面之一是它的开发人员围绕跨项目重用的想法设计他们的层。你不必购买他们的整个堆栈，尽管它很优雅。相反，你可以挑选项目中可能受益的部分，然后从那里开始。来自该社区的有用（和可重用）项目示例包括 Multiformats[^10]、libp2p[^11] 和 IPLD[^12]。

虽然 WebAssembly 以多种方式出现在这个社区中，但我想强调一个简单的方式。我不打算详细描述 IPFS 是如何工作的，但有一些核心思想。整个事情的基础是 [Merkle DAG](https://docs.ipfs.tech/concepts/merkle-dag/)。有向无环图（DAG）是一种图结构，其标识符基于节点内容的哈希值。Merkle DAG 类似于 [Merkle 树](https://en.wikipedia.org/wiki/Merkle_tree)，可用于检测基于内容的可寻址块的变化。

这些决定的最终效果是文件可以分解为由内容标识符（CID）标识的块之间的依赖关系，这些块由块的实际内容驱动。当文件更改时，唯一需要更新的部分是受影响的块。这样做不会使现有的不可变 Merkle DAG 失效，因此一个文件的多个版本可以同时存在。

如果你没有去中心化系统的背景，那么我们不需要关注幕后细节，我将直接阐述重点。为了隐藏这些细节，我将使用 IPFS 项目中基于 Go 的命令行工具。如果你有兴趣试用这些工具，可以在[附录](../appendix/)中找到如何安装这些工具。也有一些其他语言的库。如果你不想，其中许多不需要你在本地安装和运行。正如你很快就会看到的那样，有一些 HTTP 网关可以将你所知道的 Web 与 IPFS 网络连接起来。

要使用这些工具，你需要生成身份。这不涉及你的姓名或任何东西，它只是一个 RSA 密钥对，可用于对文件进行数字签名并与更大的网络通信。创建节点标识很容易。

```bash
brian@tweezer ~> ipfs init
initializing IPFS node at /Users/brian/.ipfs
generating 2048-bit RSA keypair...done
peer identity: QmZoRwJ7YYayf5eNWDweN5GCGJjuRnKGJA3susZqjV8Jcb to get started, enter:
        ipfs cat /ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/readme
```

以 QmZoRwJ 开头的长 CID 指的是我创建的节点。目前还没有任何服务在运行； 我们只拥有允许我们与 IPFS 网络通信的工具。这包括请求文件的能力。文件和块具有与节点相似的 CID。如果你深入研究前面提到的 IPLD 模型，你会发现它只是一个大型互连的命名、不可变节点集合。前面示例中生成的内容末尾的注释表明我们可以通过发出此命令了解更多信息。正如你很快就会看到的，你不需要涉及这些工具，但在这一点上，需要知道如何与网络通信。ipfs 命令行工具需要几个参数。其中一个参数使它像 Unix cat 命令一样显示文件的内容。在本例中，它是一个名为 readme 的文件，被引用为其所在目录的子元素。这种便利有点像 Web URL 上的片段标识符，以避免多次往返。我们可以一次全部请求。结果应该如图 16-1 所示。

![图 16-1. 从 IPFS 请求文件](../images/f16-1.png)

请注意，该目录中还有其他文件，因此你也可以请求它们。如果你不知道有哪些文件可用，你可以简单地询问 IPFS。请注意，这里我使用的是目录名称本身。如你所见，目录中的每个文件都有自己的 CID。

```bash
brian@tweezer ~/s/ipfs> ipfs ls /ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv
QmZTR5bcpQD7cFgTorqxZDYaew1Wqgfbd2ud9QqGPAkK2V 1677 about
QmYCvbfNbCwFR45HiNP45rwJgvatpiW38D961L5qAhUM5Y 189  contact
QmY5heUM5qgRubMDD1og9fhCPA6QdkMp3QCwd4s7gJsyE7 311  help
QmejvEPop4D7YUadeGqYWmZxHhLc4JBUCzJJHWMzdcMe2y 4    ping
QmXgqKTbzdh83pQtKFb19SpMCpDDcKR2ujqk3pKph9aCNF 1681 quick-start
QmPZ9gcCEpqKTo6aq61g2nXGUhM4iCL3ewB6LDXZCtioEB 1091 readme
QmQ5vhrL7uv6tuoN9KeVBwd4PwfQkXdVVmDLUZuTNxqgvm 1162 security-notes
```

将文件添加到 IPFS 很容易。我将以第 6 章中的示例为例。在[第 6 章](../apply-wasm-lagacy-code-in-the-browser/)的例子中，我们在浏览器中用 C++ 渲染了一个 Windows 位图文件。提醒一下，这是该目录中的内容。

```bash
brian@tweezer ~/s/i/bitmap> ls -alF
total 1816
drwxr-xr-x  12 brian  staff     384 Jan 16 20:30 ./
drwxr-xr-x  10 brian  staff     320 Mar  1 20:21 ../
-rw-r--r--   1 brian  staff    6148 Jan 16 20:30 .DS_Store
-rw-r--r--   1 brian  staff     893 Jan 16 20:30 Makefile
-rw-r--r--   1 brian  staff     948 Jan 16 20:30 Makefile.lib
-rw-r--r--   1 brian  staff     776 Jan 16 20:30 Makefile.orig
-rw-r--r--   1 brian  staff  247721 Jan 16 20:30 bitmap_image.hpp
-rw-r--r--   1 brian  staff   21026 Jan 16 20:30 bitmap_test.cpp
-rw-r--r--   1 brian  staff  249546 Jan 16 20:30 bitmap_test.js
-rwxr-xr-x   1 brian  staff  257810 Jan 16 20:30 bitmap_test.wasm*
-rw-r--r--   1 brian  staff  120054 Jan 16 20:30 image.bmp
-rw-r--r--   1 brian  staff    3127 Jan 16 20:30 index.html
```

要添加这些文件，我们只需进入该目录并发出以下指令。

```bash
brian@tweezer ~/s/i/bitmap> ipfs add -r .
added QmUViZoR2ZnnpGXyNxRyVp4kpG64kCYgHLp7w3SdmUsRcf bitmap/Makefile
added QmTPTTSvSdwgjGciTH5EgoPdujcrfXvqqSXDUB83uoFhR5 bitmap/Makefile.lib added QmWFi2rEqobqnz9RZbWrtjNRcftkbRUNmKSoxZxDuMzhDT bitmap/Makefile.orig added QmZbBUguGknW7wWAkJoZ2XXiDXAsa1zDQgLSuKn7JX7edy bitmap/bitmap_image.hpp added QmNffnsKcGhNveuEXUuwmLYUqMEW33ZpmY3Xke1oK7Y7Uh bitmap/bitmap_test.cpp added QmWcuK2svP5qyDaDksvtWanNqDGDoj3CfuqsJXkrKY3MNo bitmap/bitmap_test.js added QmRwyDerSuwq1VrP56gy28JsXTXyYhPyHxFWH1zctHHe5m bitmap/bitmap_test.wasm added QmQDwr7R6WxMJgiV4PWkLMJxpzAV8pXhafwfr5omoD93xp bitmap/image.bmp
added Qmdn3WDNXNm94c5FFBPUDq7kdfoeRP8JfgyjAd1BroQFni bitmap/index.html added QmZcJdVbvZKz9jB8ymAie6nqPLr6iBGQheEUC8bYraFFpB bitmap
      880.83 KiB / 880.83 KiB [=============================================] 100.00%
```

此时，目录和所有文件一样都有一个标识符。其他人没有办法看到这一点，即使他们可以猜出节点的身份[^13]。为了发布，你需要启动一个 IPFS Guardian 实例，它是一个后台服务器，可以与对等节点通信并响应来自其他节点的请求。一切都需要一段时间才能开始同步，但运行守护程序的结果将如下所示。

```bash
brian@tweezer ~> ipfs daemon 
Initializing daemon...
go-ipfs version: 0.9.1-dc2715af6 Repo version: 11
System version: amd64/darwin
Golang version: go1.16.6
Swarm listening on /ip4/127.0.0.1/tcp/4001
Swarm listening on /ip4/127.0.0.1/udp/4001/quic
Swarm listening on /ip4/169.254.245.235/tcp/4001
Swarm listening on /ip4/169.254.245.235/udp/4001/quic
Swarm listening on /ip4/192.168.1.169/tcp/4001
Swarm listening on /ip4/192.168.1.169/udp/4001/quic
Swarm listening on /ip6/::1/tcp/4001
Swarm listening on /ip6/::1/udp/4001/quic
Swarm listening on /ip6/fd4b:2552:d54e:3:1444:3cef:8a9b:25f3/tcp/4001
Swarm listening on /ip6/fd4b:2552:d54e:3:1444:3cef:8a9b:25f3/udp/4001/quic
Swarm listening on /ip6/fde3:9366:f229:3:18e0:193e:c7d2:8aaa/tcp/4001
Swarm listening on /ip6/fde3:9366:f229:3:18e0:193e:c7d2:8aaa/udp/4001/quic
Swarm listening on /p2p-circuit
Swarm announcing /ip4/127.0.0.1/tcp/4001
Swarm announcing /ip4/127.0.0.1/udp/4001/quic
Swarm announcing /ip4/192.168.1.169/tcp/4001
Swarm announcing /ip4/192.168.1.169/udp/4001/quic
Swarm announcing /ip6/::1/tcp/4001
Swarm announcing /ip6/::1/udp/4001/quic
API server listening on /ip4/127.0.0.1/tcp/5001
WebUI: http://127.0.0.1:5001/webui
Gateway (readonly) server listening on /ip4/127.0.0.1/tcp/8000
Daemon is ready
```

这些看起来很奇怪的标识符向你展示了我之前提到的多格式的强大功能。这些是自我描述的网络引用。我们的守护进程正在监听各种端口和协议，以便与其对等方进行通信。我们知道它正在监听的端口、绑定的 IP 地址（例如，localhost 或其他接口）、网络类型（例如，ip4 与 ip6）以及通信时首选传输方式的节点。请注意 QUIC over TCP 和 UDP 之间的区别。这是一个非常强大的想法，它支持整个技术堆栈的弹性、简单的交互模式和可扩展性。

守护进程退出并通过 DNS 查找引导程序节点。它可以使用多播 DNS（mDNS）来查找同一网络上的其他节点。它有许多与外界沟通的方式。但是，过一会儿，你就可以发现它在与谁通信，如下所示。我省略了一大堆结果，但我们看到了对等的多格式网络参考，包括他们的节点身份和与他们通信的首选方式。

```bash
brian@tweezer ~/s/ipfs> ipfs swarm peers 
/ip4/1.170.45.218/tcp/44262/p2p/QmbsXKVDhxFDgZW6zxrGfgPjXopvhNmGFqqqazv1kyZLkv 
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
```

守护进程只在有人请求时才开始发布文件，但它也会启动几个本地服务。第一个是监听 `/ip4/127.0.0.1/tcp/8000` 的只读 HTTP 网关。我们一直在使用 IPFS Go 命令行工具，但我们本地主机上的任何人都可以访问该服务。

例如，IPFS 中有一张著名的猫图片。你可以使用命令行工具向它询问详细信息。

```bash
brian@tweezer ~/s/ipfs> ipfs ls /ipfs/bafybeidsg6t7ici2osxjkukisd5inixiunqdpq2q5jy4a2ruzdf6ewsqk4/cat.jpg
QmPEKipMh6LsXzvtLxunSPP7ZsBM8y9xQ2SQQwBXy5UY6e 262144
QmT8onRUfPgvkoPMdMvCHPYxh98iKfFkBYM1ufYpnkHJn 181086
```

你看到的是与该文件相关的两个块。你还可以在守护程序中使用本机 HTTP 网关，如图 16-2 所示。URL 比较复杂，但没什么特别的； 浏览器只是通过 HTTP 请求一个文件。

![图 16-2. 通过 HTTP 网关从 IPFS 请求文件](../images/f16-2.png)

只有一个本地 HTTP 网关。IPFS 项目在 `https://ipfs.io/ipfs/<CID>` 运行了一个网关，另一个由 CloudFlare 在 `https://cloudflare-ipfs.com/ipfs/<CID>`  运行。只需将 CID 替换为猫图像节点名称和文件名，你也应该在那里看到它。

我刚刚向你展示的内容比你可能意识到的要酷，因为这两个都是 TLS 终止端点。这意味着你可以通过嗅探数据包来请求 IPFS 中的文件，而无需任何人知道你在请求什么。IPFS 在绕过审查方面非常成功。任何压制一个网关的尝试都有可能触发其他多个网关。

守护进程启动的另一项服务是一个 Web 应用程序，用于浏览节点详细信息并更自然地与平台交互。它在上面的守护程序输出中列为 WebUI，位于 <http://127.0.0.1:5001/webui>。作为一个绑定，只有同一台机器上的用户才能命中它，但是你可以将它配置为绑定到一个 IP 地址，这样任何其他本地网络机器都可以在不安装任何 IPFS 工具的情况下请求该文件。该应用程序如图 16-3 所示。

![图 16-3. 通过 WebUI 与 IPFS 交互](../images/f16-3.png)

你可以在 WebUI 中做很多其他很酷的事情，但要回到手头的主题，请仔细查看窗口的地址栏。端口 5001 正在为来自 IPFS 的 Web 应用程序提供服务。

```bash
brian@tweezer ~/s/ipfs> ipfs ls /ipfs/bafybeiflkjt66aetfgcrgv75izymd5kc47g6luepqmfq6zsf5w6ueth6y
bafkreigqagdyzmirtqln7dc4qfz5sb7tkdexbzmhwoxzbkma3ka 5324 asset-manifest.json
bafkreihc7efnl2prri6j6krcopelxms3xsh7undpsjqbfsasm7i 34494 favicon.ico
bafkreihmzivzfdhagatgqinzy6u4mfopfldebcc4mvim5rzrdpi 4530 index.html
bafkreicayih3vhhjugxshbar5ylocvcqz4xixuqk6cflyxpnuxf 24008 ipfs-logo-512-ice.png 
bafybeiadzwwymj72nnlyoy6bza4lhps6sofmgmyf6ew5klzwd -	locales/ 
bafkreicplcott4fe3nnwvz3bidothdtqdvpr5wygbxzoyfozm7t 298	manifest.json 
bafybeierqn364ton5lp5ogcu4l22gukzprwieaau7lvcan555n3 -	static/
```

浏览器请求 Web 应用程序所在目录的根 CID。`index.html` 一如既往地是默认文件。如果你使用 `ipfs cat` 查看该文件，你会看到它引用了静态资源、样式表等。有人在某地发布了这个应用程序。不是发布在云托管网站或传统意义上的任何地方。我不知道它来自哪里，但它是通过 HTTP 网关在本地提供给我的浏览器的。

我之前发布的包含用 C++ 呈现的位图文件的目录发生了什么变化？ 由于我的守护进程已经运行了一段时间，其他节点现在可以请求它了。请参见图 16-4 以查看我的应用程序在 CloudFlare over TLS 前端的惊人结果。

![图 16-4. 与我通过 IPFS HTTP 网关在本地发布的文件进行交互](../images/f16-4.png)

我不打算详细介绍，但我想强调这还意味着什么。请记住，Merkle DAG 是不可变的。如果我通过修改一两个文件来更改我的应用程序，那么这些是唯一需要重新发布的内容。请记住，发布只是将文件添加到 IPFS。编辑后的文件块将具有不同的哈希值，这也意味着目录具有不同的哈希值。有一个新的顶级 CID。但是旧的仍然有效。你可以使用 DNS 玩一些游戏，但我会留给你使用 IPFS 的文档和教程来解决这个问题。

这与 WebAssembly 有什么关系？ 这确实是我强调的平台优势的交集，以及它将作为另一个用例产生的影响。我刚刚演示了一个通过 CDN 提供服务的 Web 应用程序，该应用程序在地理上分布，没有任何其他托管需求。它在本地提供服务，其结果可以沿途缓存。这包括编译为 WebAssembly 的 C++ 代码，在你碰巧使用的任何浏览器或平台的沙箱中都可以运行。可同时支持多个版本，用户可自行决定何时升级。

你可以为世界上任何地方的任何客户端提供你的应用程序，而无需支付托管费用。你可以在用户喜欢的任何平台上以任何语言实现高性能的交互式系统。客户可以放心地运行你的应用程序，因为有安全保护措施，没有中央机构可以轻易关闭你的应用程序。

告诉我这酷不酷。

## 注释

[^1]: 《面向资源的数据网络架构模式》（Morgan & Claypool）。
[^2]: Crypto 是指密码学。
[^3]: coinbase 交易是如何以可控的速度铸造比特币的。
[^4]: 他们最终将他们所做的扩展到一个更普遍的框架，称为 [BOINC](https://en.wikipedia.org/wiki/Berkeley_Open_Infrastructure_for_Network_Computing)。
[^5]: 我不打算把这个问题变成一个有限自动机课程。如果你想挖掘更大的意义（注意，这是个很深的兔子洞），详见[维基百科](https://en.wikipedia.org/wiki/Turing_completeness)。

[^6]: 阿兰·图灵在1936年证明，这并不总是可能的。
[^7]: 著名的 [The  Yellow  Paper](https://ethereum.github.io/yellowpaper/paper.pdf) 描述了以太坊平台上的许多设计动机。如果你对区块链技术更感兴趣，这将值得你花时间阅读。
[^8]: [Web3 基金会](https://web3.foundation/)资助那些能够促进这一去中心化愿景的全面成功的项目研究。
[^9]: J.C. R. Licklider将新兴的ARPANET（后来成为互联网）的早期版本称为[银河系计算机网络](https://en.wikipedia.org/wiki/Intergalactic_Computer_Network)。
[^10]: [多重格式](https://multiformats.io/)允许你以一种自我描述的、灵活的状态来表达哈希值、网络地址和其他有用的值。
[^11]: [libp2p](https://libp2p.io/) 是一个了不起的、可插拔的、广泛的网络堆栈，允许交换传输、多路复用通道、处理高延迟环境等。
[^12]: [IPLD](https://ipld.io/) 是一种用于分散式系统的链接数据格式。
[^13]: 我敢打赌，这是不可能的。
