---
title: "Tetrate 开源项目 Wazero 简介"
date: 2023-03-20T12:00:00+08:00
draft: false
summary: "这篇文章介绍了 wazero，一个由 Tetrate 开发的用 Go 语言编写的 WebAssembly 运行时。wazero 可以让开发者用不同的编程语言编写代码，并在安全的沙箱环境中运行。"
tags: ["WebAssembly","Tetrate","wazero"]
categories: ["WebAssembly"]
authors: ["Tetrate"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://tetrate.io/blog/introducing-wazero-from-tetrate/
---

> 译者注：本文译自 [Tetrate 博客](https://tetrate.io/blog/introducing-wazero-from-tetrate/)。这篇文章介绍了 wazero，一个由 Tetrate 开发的用 Go 语言编写的 WebAssembly 运行时。wazero 可以让开发者用不同的编程语言编写代码，并在安全的沙箱环境中运行。wazero 有以下几个特点：
>
> - 纯 Go，无依赖，支持跨平台和跨架构
> - 遵循 WebAssembly 核心规范 1.0 和 2.0
> - 支持 Go 的特性，如并发安全和上下文传递
> - 提供了丰富的编程接口和命令行工具
> - 性能优异，超过了其他同类运行时

WebAssembly，也称为 Wasm，是一种编译用一种编程语言（例如 C 或 Rust）编写的代码并在不同的运行时（例如 Web 浏览器或微服务）上运行它的方法。这使得它成为编写插件、扩展以及在安全沙箱环境中运行任意用户定义代码的绝佳选择。

WebAssembly 经常被误认为是一种仅限浏览器的技术，而实际上 Wasm 是一种跨平台的二进制文件，可以由任何 WebAssembly 运行时执行。从历史上看，Go 程序员没有太多好的选择，但这种情况已经改变。

本文介绍了 [wazero](https://wazero.io/)，它在用 Go 编程语言编写的基础设施中很重要，并涵盖了其最引人注目的功能。

## 在 Go 中运行 WebAssembly 的简史

最初，大多数 WebAssembly 运行时是用 C/C++ 和 Rust 编程语言编写的。许多云原生项目，包括 Docker、Istio 和 Kubernetes 都是用 Go 编写的。不是用 Go 编写的运行时可通过称为 CGO 的机制获得。然而，CGO 不是 Go，通过选择 CGO，您就放弃了 Go 运行时的许多杀手级功能，例如对广泛平台交叉编译的一流支持。围绕 CGO 的复杂性，尤其是隐含的本机库，是将 wasm 扩展到 Kubernetes 调度程序的请求被拒绝的原因。总之，Go 缺乏原生运行时延迟或限制了将 WebAssembly 引入核心基础设施。

## wazero 是为 Go 开发人员编写的

[wazero](https://wazero.io/) 是唯一用 Go 编写的**零依赖 WebAssembly 运行时**。这个开源项目最初是由 **Takeshi Yoneda** 作为爱好开始的。2021 年底，Tetrate 认识到其战略价值并投入了几名全职员工，以期有朝一日发布 1.0 版。

在过去的几个月里，该团队孜孜不倦地工作以支持多种平台、架构和编程接口。我们很高兴地宣布 wazero 1.0 发布！

Wazero 是一个功能齐全、符合标准、丰富且经过实战检验的 WebAssembly 运行时，它与 Go 运行时的最佳特性无缝集成，例如安全并发和上下文传播。它包括一个面向 Go 开发人员的编程接口和一个面向那些只想运行 Wasm 的人的 CLI。

## Wazero 有什么不同之处？

你可能想知道 wazero 的优势在哪里，考虑到 Go 与其他语言具有良好的互操作性。这允许您通过 CGO 选择多个不是用 Go 编写的运行时。以下是考虑 Wazero 的五个理由：

1. **最佳 Go 支持**。Wazero 是纯 Go 语言，不引入任何依赖，但支持更进一步。Wazero 包括惯用的 Go 函数，例如上下文集成。这允许您重用传入的截止日期，例如来自 gRPC 请求以限制在 wasm 函数中花费的时间。运行时是专门为 Go 设计的，因此在 Go 开发人员关注的问题（例如 goroutine security /wazero）方面[记录很好](https://pkg.go.dev/github.com/tetratelabs)。比如很多库可以同时使用 wazero 而不互相冲突，这些都是在 Go 中测试过的。
2. **API 兼容性**。WebAssembly 运行时嵌入在项目的底层位置，因此兼容性的变化可能会导致版本锁定，尤其是在中间件中。Wazero 是唯一已知的提供语义版本控制的运行时。函数可以制作成 1.1 版本，它们不会破坏 1.0 用户。Wazero 承诺保持零依赖并与 Go 的前两个版本一起工作。总之，wazero 的兼容性方法是模仿 Go 本身，为其用户引入最少的维护问题。
3. **平台兼容性**。wazero 完全支持 amd64、arm64、FreeBSD、Linux、macOS 和 Windows 在最新三个版本的 Go 上的任意组合。它还通过其“解释器运行时”将对 Go 的支持扩展到其他平台，它的执行速度比本机“编译器运行时”慢。wazero 在 Windows 上非常棒，因为它不仅是一流的平台，而且我们还在发布时生成签名的 MSI 安装程序。
4. **坚如磐石的测试方法**。Wazero 通过多项规范测试来测试平台支持，包括 WebAssembly 核心规范的 1.0 和 2.0 草案版本以及用于测试 I/O 功能的 WASI 测试套件。我们还运行由 Zig 和 TinyGo 编写的标准库测试。最后，我们运行基准测试并对每个更改进行“模糊测试”。所有这些都使得 wazero 的错误易于识别和修复。
5. **活跃的终端用户社区。** wazero 的社区包括许多公司的极强的开发人员。我们涉及一些与 Go 支持 WebAssembly 有关的方面，并为 Go 和 TinyGo 编译器做出贡献。请查看我们的[社区](https://wazero.io/community/)和[用户](https://wazero.io/community/users/)页面，了解更多关于我们以及您如何融入其中的信息！

## 将 wazero 嵌入您的项目中

Wazero 显然也是一个 Go 库，其主要目标是让您与运行时环境无缝集成，并使用 WebAssembly 扩展您的 Go 应用程序。例如，假设您想运行[经典的 Unix 程序 cowsay](https://en.wikipedia.org/wiki/Cowsay)（最初是用 Perl 编写的）。那么您可以输入：

```
// Download the executable from:
// https://github.com/evacchi/cowsay/releases/download/0.1.0/cowsay.wasm
//go:embed "cowsay.wasm"
var cowsay []byte

func main() {
	ctx := context.Background()
	r := wazero.NewRuntime(ctx)
	wasi_snapshot_preview1.MustInstantiate(ctx, r)
	r.InstantiateWithConfig(ctx, cowsay,
		wazero.NewModuleConfig().
			WithArgs("cowsay", // first arg is usually the executable name
				"wazero is awesome!").
			WithStdout(os.Stdout))
}
```

运行它会显示：

```
 ____________________
< wazero is awesome! >
 --------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
               ||----w |
                ||     ||
```

## 使用 wazero CLI 入门

该项目现在包括一个 CLI，用于运行 WebAssembly 二进制文件。我们发现许多用户无论使用哪种编程语言都选择它，因此我们决定使用这个例子。

现在，您可以使用一个简单的命令下载和安装 wazero CLI：

```
$ curl https://wazero.io/install.sh | sh
```

或者在 Windows 上，您可以[下载有 MSI 签名的](https://github.com/tetratelabs/wazero/releases/download/v1.0.0-rc.2/wazero_1.0.0-rc.2_windows_amd64.msi)。

然后您可以使用以下命令运行您的 WebAssembly 二进制文件：

```
$ ./bin/wazero run someApp.wasm
```

例如，假设您想在 CLI 上运行 cowsay，那么只需键入

```
$ curl -LO https://github.com/evacchi/cowsay/releases/download/0.1.0/cowsay.wasm
$ wazero run cowsay.wasm wazero is awesome!
 ____________________
< wazero is awesome! >
 --------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
               ||----w |
                ||     ||
```

或者，也许你更想玩 1977 年的 Infocom 文本冒险游戏 Zork。

你可以从 https://github.com/evacchi/zork-1/releases/tag/v0.0.1 获取一个 Wasm 二进制文件，然后使用以下命令调用：

```
$ curl -L https://github.com/evacchi/zork-1/releases/download/v0.0.1/zork-wasm-wasi.tgz | tar xzf -
$ wazero run -mount=.:/ zork.wasm
Welcome to Dungeon.			This version created 11-MAR-91.
You are in an open field west of a big white house with a boarded
front door.
There is a small mailbox here.
>open mailbox
Opening the mailbox reveals:
  A leaflet.
>read leaflet
Taken.
		    Welcome to Dungeon!

   Dungeon is a game of adventure, danger, and low cunning.  In it
you will explore some of the most amazing territory ever seen by mortal
man.  Hardened adventurers have run screaming from the terrors contained
within.

   In Dungeon, the intrepid explorer delves into the forgotten secrets
of a lost labyrinth deep in the bowels of the earth, searching for
vast treasures long hidden from prying eyes, treasures guarded by
fearsome monsters and diabolical traps!

   No DECsystem should be without one!
```

尽情玩吧！

## 最后的话

这是我们的第一个重大发布，但我们才刚刚开始！**有许多值得期待的事情**。

WebAssembly 规范正在不断更新，我们将密切关注它：例如，[tail call proposal](https://github.com/WebAssembly/tail-call/blob/main/README.md) 刚刚进入第 4 阶段，[GC proposal](https://github.com/WebAssembly/gc/blob/master/proposals/gc/Overview.md) 则是许多编程语言（如 Java）的支持者，最近进入了第 3 阶段。Wazero 将继续通过所有测试，随着 WebAssembly 的发展而发展。

我们还希望作为您 WebAssembly 运行时的战略性选择。您可以期待持续致力于性能，可观测性和可扩展性。一个例子是我们即将推出的低级文件系统插件。它支持比 Go 的 fs.FS 更多的功能，现在就可以使用，例如创建目录和文件。该设计支持自定义审计和访问控制，并可用于第三方主机函数。

最后，如果您在 3 月 23 日和 24 日参加巴塞罗那的 Wasm I/O 活动，就有机会认识我们团队的一部分！

如果您在会议结束后留在那里，或者您只是在那个晚上在城市里，**在 3 月 24 日星期五**，我们也很高兴[邀请您参加 wazero 1.0 自己的官方发布派对](https://www.eventbrite.com/e/wazero-10-launch-party-tickets-585204150367)。我们将提供小吃，饮料和许多社区贡献者，他们将展示他们如何使用我们所钟爱的 WebAssembly 运行时！一位幸运的参会者将有机会按下 1.0 的发布按钮！

我们很兴奋地看到您将如何使用 Wazero 构建项目。[加入我们不断增长的社区用户列表](https://wazero.io/community/users/)，并让我们知道您正在创造什么！
