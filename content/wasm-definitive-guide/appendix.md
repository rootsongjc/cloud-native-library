---
linktitle: 附录
summary: "这篇文章是《WebAssembly 权威指南》一书的附录，提供了一些有用的参考资料和链接。"
weight: 18
icon: book-reader
icon_pack: fas
title: 附录
draft: false
date: '2023-01-16T00:00:00+08:00'
type: book # Do not modify
---

> 译者注：这篇文章是《WebAssembly 权威指南》一书的附录，提供了一些有用的参考资料和链接。

鉴于我们在本书中讨论的所有语言、工具和框架，有相当多的东西需要安装，这一点并不奇怪。本附录并不全面，但会尝试为你指出正确的方向，让你的一切都能顺利进行。有些工具在 Linux 或 macOS 上更容易安装，但大多数在 Windows 上也能工作。

## 安装 WebAssembly Binary Toolkit (WABT)

WebAssembly 二进制工具包（WABT）提供了一套工具，用于将东西转换成我们讨论过的各种格式以及其他一些格式。它包括用于导出模块的细节、验证其结构等的工具。

在 GitHub 仓库中有相当好的说明，可以在所有三个主要的操作系统上构建，所以在这里没有必要复制。该软件库位于这里：<https://github.com/WebAssembly/wabt>

我想指出的一件事是，一些工具也可以在网上找到。WebAssembly 工具也可以在浏览器中运行，这不应该太令人惊讶。如果你想尝试在不安装工具的情况下转换格式，你可以在这里试试：<https://webassembly.github.io/wabt/demo>

此外，还有一个叫 Wabt.js 的衍生项目，可以让你在浏览器中使用工具包的大部分功能。它的 GitHub 仓库在这里：<https://github.com/AssemblyScript/wabt.js>

## 安装 LLVM

LLVM 看起来像是代表着什么，但它并不代表。它只是一个非常酷的模块化编译器架构的名字，是 Rust、Swift、Julia 等语言的基础。

如果你安装了正确的工具，LLVM 甚至能够为不同的平台输出特定的代码。它对于实验优化、在虚拟机中运行中间形式和产生 WebAssembly 也很有用。

我强烈建议你通过其中一个安装程序来安装 LLVM，而不是从头开始构建它，因为这需要很长的时间，而且会消耗大量的磁盘空间。根据你的操作系统，你可能已经安装了一个版本。macOS 的工具链是基于 LLVM 的，但该版本还不能与 WebAssembly 互操作。

主要网站在这里：<https://llvm.org>

大多数主要的操作系统都有安装程序，所以你应该不难找到可以使用的程序。

## 安装 Emscripten

Emscripten 工具链是一套包裹 LLVM 工具的工具。最初，它支持 asm.js，但现在它直接支持 WebAssembly。除了协助编译现有的 C 和 C++ 代码外，它还有其他用于构建软件的命令行工具，如 Make 和 configure 的滴入式替换。

通过它的宏和编译器指令，它可以相当直接地简化浏览器或 Node.js 中的 JavaScript 主机环境之间的通信。它支持广泛使用的依赖性，如标准库和 OpenGL。

入门指南对多个操作系统有很好的说明，所以你最好的选择是这个网站：<https://emscripten.org/docs/getting_started/index.html>

## 安装 Wasm3

Wasm3 自称是 "最快的 WebAssembly 解释器和最通用的运行时"。GitHub 仓库在这里：<https://github.com/wasm3/wasm3>

考虑到它所运行的平台和语言的多样性，我不打算在这一点上挑战他们。目前，它可以在以下平台上运行：

- Linux、Windows、macOS、FreeBSD、Android、iOS
- OpenWrt、Yocto、Buildroot (网络设备)
- 树莓派和其他单片机
- 各种各样的微控制器
- 大多数现代浏览器

它在跟踪各种新提案方面也做得很好。

从源代码构建它是很容易的，但有几个安装程序在这里：<https://github.com/wasm3/wasm3/blob/main/docs/Installation.md>

我也鼓励你看看这里的有用的使用手册：<https://github.com/wasm3/wasm3/blob/main/docs/Cookbook.md>

## 安装 Wasmtime

Wasmtime 最初是一个 Mozilla 项目，但现在由 Bytecode Alliance 维护，它被称为 "一个独立的只针对 WebAssembly 和 WASI 的 wasm 优化运行时"。

它是各种提案中最新的运行时之一，并有一套广泛的程序库，正如你在书中看到的那样。

这里有相当多的文档：<https://docs.wasmtime.dev>

你可以在这里找到安装说明：<https://docs.wasmtime.dev/cli-install.html>

## 安装 Wasmer

Wasmer 是我遇到的第一批非浏览器和非 Node.js WebAssembly 运行时之一。它比 WASI 早，但很快就增加了支持。

Wasmer 的主要网站是：<https://wasmer.io>

除了是一个独立的运行时外，它还集成了对以下的支持：

- Rust
- C 和 C++
- JavaScript
- Go
- Python
- PHP
- Ruby

它还维护 WebAssembly 包管理器（WAPM）、WebAssembly.sh 和 Wasienv 工具包。

从这个文档开始和安装运行时：<https://docs.wasmer.io/ecosystem/wasmer/getting-started>

## 安装 Rust 工具

Rust 在 WebAssembly 生态系统中显然有很大的地位，但它作为一种安全、快速的编程语言，也有很多值得一说的地方，而且正在迅速发展。

主要网站是：<https://rust-lang.org>

一般来说，你会想使用 rustup 工具来管理你的 Rust 工具链。它支持 nightly、beta 和稳定版。根据你自己的舒适程度或对最新和最伟大的功能的渴望，你可以快速和容易地在所安装的各种通道之间切换。只要你想，很容易安装多个频道。如果你对交叉编译感兴趣，也可以安装其他架构的后端。

首先安装这里记录的 rustup 工具链：<https://www.rust-lang.org/tools/install>

为了直接生成 WebAssembly，你必须安装后端。你可以选择你想要的渠道，但要安装 nightly 的 WebAssembly 后端，你要这样做：

```bash
~/s/r/wasm> rustup target add wasm32-unknown-unknown --toolchain nightly
```

要在编译 Rust 时使用后端，你应该这样做，如果你不把它作为默认工具链：

```bash
~/s/r/wasm> rustc +nightly --target wasm32-unknown-unknown ↵ -O --cate-type=cdylib add.rs -o add.wasm
```

为了生成 WASI 代码，你将需要安装 WASI 后端：

```bash
~/s/r/wasm> rustup target add wasm32-wasi --toolchain nightly
```

如果它不是默认工具链，要使用它：

```bash
~/s/r/wasm> rustc hello.rs --target wasm32-wasi
```

注意，常规的 Rust 本地后端、常规的 WebAssembly 和 WASI 后端是不同的，这取决于你想要的目标是什么。

如果你想在 Rust 和 JavaScript 之间无缝交互，你可能想安装 wasm-bindgen。

关于这个工具的介绍在这里：<https://rustwasm.github.io/wasm-bindgen>

在安装了 Rust 工具后，你应该可以用以下方式安装它：

```bash
~/s/rust> cargo install -f wasm-bindgen-cli 
```

## 安装.NET 工具

正如你在书中看到的，.NET 已经成为一个强大的 WebAssembly 环境，特别是现在它是跨平台的。

好消息是，它的安装是小菜一碟。主要操作系统的说明位于这里：<https://dotnet.microsoft.com/download>

一旦安装了这些，你应该能够运行我们在书中介绍的命令行例子。

## 安装 AssemblyScript

AssemblyScript 正在成为 WebAssembly 世界中的一个强有力的参与者。它在过去和未来之间取得了一个很好的平衡。你不必学习 C 或 C++ 代码，可以在一个熟悉的语言空间里，同时还能产生更高性能的软件。

主网站在这里：<https://www.assemblyscript.org>

安装说明在这里：<https://www.assemblyscript.org/quick-start.html>

## 安装 IPFS

InterPlanetary File System（IPFS）与 WebAssembly 没有直接关系，但作为分散空间的一个关键角色，它们有几个交集。我在书中着重介绍了一个例子。

如果你想了解更多关于这个项目的信息，网站在这里：<https://ipfs.io>

你有一些安装的选择，详细情况在这里：<https://ipfs.io/#install>

## 安装 TinyGo

正如我在上一章所指出的，TinyGo 除了支持微控制器和其他嵌入式系统外，还是 Go 和 WebAssembly 整合的一个不错的起点。

主网站在这里：<https://tinygo.org>

在各种操作系统或 Docker 上的安装说明可以在这里找

## 安装 Artichoke

Artichoke 是让 Ruby 加入 WebAssembly 大家庭的一个引人注目的开始。现在还是早期，但正如我提到的，他们正在寻找贡献者。

你可以在这里找到安装说明：<https://www.artichokeruby.org/install>

## 安装 SwiftWasm

SwiftWasm 也处于早期阶段，但对于这种摆脱了 macOS 起源的越来越有趣的语言，它显示了很大的前景。这里有各种安装选项：<https://book.swiftwasm.org/getting-started/setup.html>

## 安装 Zig 和 Grain

Zig 和 Grain 都是引人注目的新语言，我非常有兴趣去研究。虽然它们在任何方面都没有被广泛使用，但人们对它们的兴趣正在增长。它们有强大的新兴 WebAssembly 策略，这可能会迅速放大它们的影响，因为在很多情况下你不需要新的运行时工具。

尽管它们是独立的、不相关的，但我把它们捆绑在一起，因为我认为它们有类似的作用，处于类似的位置。

我鼓励你进一步挖掘这两者。

Zig 可以在这里找到：<https://ziglang.org/download>

Grain 可在此查阅：<https://grain-lang.org/docs/getting_grain>
