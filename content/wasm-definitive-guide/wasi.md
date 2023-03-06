---
linktitle: 第 11 章：WASI（WebAssembly 系统接口）
summary: "这篇文章是《WebAssembly 权威指南》一书的第十一章，这章介绍了 WASI（WebAssembly 系统接口）的概念、目标、架构和实现。WASI 是一种标准化的接口，旨在让 WebAssembly 程序能够在不同的宿主环境中运行，同时保持安全性和可移植性。文章分析了 WASI 的设计原理和优势，以及它如何与 WebAssembly 模块、内存、表和函数交互。文章还展示了如何使用 WASI SDK 和 Wasmtime 运行时来编译和执行一个简单的 C 程序，并给出了一些实用的命令行工具和资源。"
weight: 12
icon: book-reader
icon_pack: fas
draft: false
title: WASI（WebAssembly 系统接口）
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

> 译者注：这是《WebAssembly 权威指南》一书的第十一章，这章介绍了 WASI（WebAssembly 系统接口）的概念、目标、架构和实现。WASI 是一种标准化的接口，旨在让 WebAssembly 程序能够在不同的宿主环境中运行，同时保持安全性和可移植性。文章分析了 WASI 的设计原理和优势，以及它如何与 WebAssembly 模块、内存、表和函数交互。文章还展示了如何使用 WASI SDK 和 Wasmtime 运行时来编译和执行一个简单的 C 程序，并给出了一些实用的命令行工具和资源。

在 WebAssembly 做有些事情会异常困难，而在其他平台上却比较容易。在 C、C++ 或 Rust 这样的语言中，从文件系统中读取、向控制台写入和在内存中操作字符串都很简单。操作系统会允许有足够权限的用户来做这些事情。这里没有明确的、上下文的界限。

不幸的是，这也是大多数现代网络威胁背后的问题，如网络钓鱼攻击、特权升级、供应链攻击等等。如果攻击者能够说服一个有特权的用户运行不值得信任的代码，他们往往可以窃取其他资源的访问权，而这些资源不是他们应得的。沙盒环境的存在是为了防止这种情况，但它们往往很慢，很麻烦，对开发者来说是个负担。WebAssembly 想解决这个问题，而且它在很多方面都做到了。然而，从根本上说，WebAssembly 模块不能访问任何不由其托管环境提供的东西。

到目前为止，我们所看到的 MVP 和工具主要是使代码可移植。我们现在要学习的是如何使应用程序可移植。事实证明，这个解决方案从根本上说是关于是否能满足期望的问题。这不仅仅是语言的问题，也是 API 可用性、运行时环境配置、安全限制等的问题。因此，就像李小龙的语录一样，我们的主机环境并不总是能满足我们所运行的代码的期望。我们仍然可以控制。

## WebAssembly 系统接口（WASI）

到目前为止，你所看到的那些很酷的演示和代码示例，特别是那些涉及图形、声音、视频等的演示和代码样本，之所以能够实现，主要是因为它们在浏览器中运行。浏览器被设计成通用客户端的软件，是其他代码的主机。通过将任意程序下发到客户端执行，有可能扩展网络。它有内置的安全限制，但现在它实际上是一个相当有特色的编程环境，充满了诸如用于 3D 图形的 WebGL、加速视频、用于协作的 WebRTC 等 API。Emscripten 通过浏览器运行环境可用的东西提供标准 API 的实现，如 POSIX 和 OpenGL，这样标准的 C/C++ 应用程序就可以简单地编译并仍然可以工作。

我们已经看到了一种为模块实例提供函数的机制，以便通过它们导入的对象来调用。例如，传入一个打印到控制台的 JavaScript 函数，而不是依靠 C 语言标准库来提供对 `printf ()` 的访问。不过，这从根本上说是这种方法并不能令人满意。每一个需要打印到控制台的 WebAssembly 模块都应该有一个可以调用的函数，最好是已经写好的函数，无论何时都可以调用。这是为了安全和有效地满足期望。

然而，由于安全问题，程序想要读取或写入文件系统并不意味着它可以这样做。我们的电脑并不期待恶意软件的光临。我们希望控制应用程序对资源的访问环境，如果有的话。

关于预期的另一个问题是，浏览器之外的运行环境是 WebAssembly 潜在执行面的重要组成部分。在 Node.js 或 Deno 等环境中，许多 API 都不能以同样的方式使用。没有兼容的 Web IDL 定义的接口，暴露了对音频和视频播放、3D 图形和其他方面的访问 [^1]。当然也有其他类似的 API，但它们与浏览器内部的内容并不兼容，应用程序必须重写才能使用它们。

通常，POSIX 函数将在不同的操作系统中被一致定义，并将映射到较低级别的内核函数或特定平台的 API，如 Win32 [^2]。这些是可重复使用的功能的关键部分，我们希望它们是快速和稳定的实现。由应用程序开发人员提供的任意 JavaScript 封装函数不可能有足够的速度和稳定性。许多这些额外的浏览器 API 不具有与沙盒浏览器环境相同的安全保证，所以它们也不能直接在那里使用。

这些都是 WebAssembly 系统接口（WASI）试图解决的无数问题之一。这是一个很高的要求，而且这项工作正在扩大，在这个时间点上变得相当复杂，但基本原理是相当简单的，所以我们将从这里开始。

最终，我们希望有一个生态系统的功能，允许访问它的程序可以期待其可用性。我们希望这些功能能够跨越语言的界限，这意味着我们需要一些方法来引用高级结构，如字符串、列表和数组。我们需要受保护但快速的实现。我们希望有一些类型安全的方式，并且不必在我们编写的代码中依赖太多的功能测试。我们还希望诸如垃圾收集和异常处理这样的语言特性能够从支持它们的语言中获得，而不会给不支持它们的语言带来负担。为了满足这些要求，需要对 WebAssembly 平台进行扩展。在 [第 12 章](../extending-wasm-platform/) 中我将介绍其中一些主要的扩展，但现在我想留在这个讨论之上。

让我们重新审视一下 Rust 版本的著名例子。 [第 10 章](../rust/) 的例 11-1，我们再来一次。我们已经确定问题出在浏览器中没有 `println!` 宏。也没有 C 语言中的 `printf ()` 函数。我们已经看到了各种绕过这个问题的方法，但这些解决方案仍然令人困扰。

例 11-1. Rust "Hello, World!"

```rust
fn main () {println! ("Hello, World!");
}
```

出于马上就会明白的原因，我将重新创建这个基本的 Rust 程序的样本脚手架并运行它。`cargo new`命令将建立一个项目的目录结构，并生成一个简单的应用程序，它实际上就是之前的例子。

```bash
brian@tweezer ~/g/w/s/ch11> cargo new --bin hello-world
  Created binary (application) `hello-world` package
brian@tweezer ~/g/w/s/ch11> cd hello-world/
brian@tweezer ~/g/w/s/c/hello-world> cargo build --release
  Finished release [optimized] target (s) in 0.03s 
brian@tweezer ~/g/w/s/c/hello-world> cargo run --release
  Finished release [optimized] target (s) in 0.01s
   Running `target/release/hello-world`
Hello, world!
```

Cargo 构建工具通过在`src/main.rs` 中放置一个友好程序，为我们创建了项目脚手架。我们构建了这个程序的优化发布版本，然后运行相关的本地可执行文件。记住，Rust 是基于 LLVM 的，所以默认的后端将适用于你所安装的工具链的任何操作系统。

我们看到在 [第 10 章](../rust/) 中我们可以使用 WebAssembly 的后端来生成 Rust 的模块，但由于涉及到字符串、内存管理、与操作系统的交互等方面的限制，它并没有发挥作用。

```bash
brian@tweezer ~/g/w/s/c/hello-world> cargo build ↵ 
  --target wasm32-unknown-unknown --release
    Compiling hello-world v0.1.0
        (/Users/brian/git-personal/wasm_tdg/src/ch11/hello-world)
      Finished release [optimized] target (s) in 0.89s
brian@tweezer ~/g/w/s/c/hello-world> ls -laF ↵
  target/wasm32-unknown-unknown/release/
total 3008
drwxr-xr-x 10 brian staff	320 Jun 27 16:02 ./
drwxr-xr-x@ 5 brian staff	160 Jun 27 16:02 ../
drwxr-xr-x	2 brian staff	64 Jun 27 16:02 build/
drwxr-xr-x	4 brian staff	128 Jun 27 16:02 deps/
drwxr-xr-x	2 brian staff	64 Jun 27 16:02 examples/
-rw-r--r--	1 brian staff	228 Jun 27 16:02 hello-world.d
-rwxr-xr-x	2 brian staff 1534049 Jun 27 16:02 hello-world.wasm*
drwxr-xr-x	2 brian staff	64 Jun 27 16:02 incremental/ 
brian@tweezer ~/g/w/s/c/hello-world > wasm3 ↵
    target/wasm32-unknown-unknown/release/hello-world.wasm
Error: [Fatal] repl_call: function lookup failed
Error: function lookup failed ('_start')
```

一个基本问题是，基本模块结构没有像可执行程序那样定义相同类型的应用二进制接口（ABI）[^3]。它没有预期的初始化函数名称。开发人员认为`main ()` 是起点，但这一般是由非常小的 C 语言运行时环境从 start 的方法中调用。

另一个问题是，没有办法直接写到控制台或从 WebAssembly 模块读写文件。这似乎是 WebAssembly 的一个相当大的障碍，但我鼓励你不要轻易放弃，如果我们使用一个不同的后端会怎样？我们将使用 `wasm32-unknown-unknown`，而不是 `wasm32-wasi`。

```bash
brian@tweezer ~/g/w/s/c/hello-world> cargo build --target wasm32-wasi --release
    Compiling hello-world v0.1.0
       (/Users/brian/git-personal/wasm_tdg/src/ch11/hello-world)
    Finished release [optimized] target (s) in 0.74s
```

你看到了吗？

我们再检查一下模块：

```bash
brian@tweezer ~/g/w/s/c/hello-world > wasm-objdump ↵ -x target/wasm32-wasi/release/hello-world.wasm
hello-world.wasm:
Section Details:
file format wasm 0x1
    Type [18]:
     - type [0] () -> nil
     - type [1] (i32) -> nil
     - type [2] (i32) -> i64
     - type [3] (i32, i32) -> nil
     - type [4] (i32, i32) -> i32
     - type [5] (i32, i32) -> i64
     - type [6] (i32) -> i32
     - type [7] (i32, i32, i32) -> i32
     - type [8] (i32, i32, i32, i32) -> i32
     - type [9] () -> i32
    ...
    Import [4]:
     - func [0] sig=8 <_ZN4wasi13lib_generated22wasi_snapshot_preview18fd_write>
        <- wasi_snapshot_preview1.fd_write
     - func [1] sig=1 <__wasi_proc_exit> <- wasi_snapshot_preview1.proc_exit
     - func [2] sig=4 <__wasi_environ_sizes_get>
         <- wasi_snapshot_preview1.environ_sizes_get
     - func [3] sig=4 <__wasi_environ_get> <- wasi_snapshot_preview1.environ_get
...
    Export [5]:
     - memory [0] -> "memory"
     - global [1] -> "__heap_base"
     - global [2] -> "__data_end"
     - func [247] <_start.command_export> -> "_start"
     - func [248] <main.command_export> -> "main"
...
```

这是一个 WebAssembly 模块，但它也输出了一个已知的起点，所以 WASI 感知环境，如 wasm3，知道如何初始化和从哪里开始执行。不过，WASI 的内容远不止这个启动过程。它还提供了一个方便的方法，让模块导入它需要执行的函数。这就是 Rust wasm32-wasi 后端为我们做的事情。它正在发出对标准库实现的调用，这些标准库将由我们的代码运行的主机环境提供。同样，wasm3 至少是一个初级的 WASI 环境，所以它提供这些能力。它在 WASI 之前是一个浏览器外的 WebAssembly 引擎，但它正在积极支持不断发展的标准和较新的建议，我们将在下一章讨论。

如果你按照 [附录](../appendix/) 中的安装步骤，你可以再安装两个 WASI 环境，Wasmtime [^4] 和 Wasmer [^5]。两者都是开放源码和独立的倡议。

```bash
brian@tweezer ~/g/w/s/c/hello-world> wasmtime ↵ 
	target/wasm32-wasi/release/hello-world.wasm
Hello, world!
brian@tweezer ~/g/w/s/c/hello-world> wasmer ↵
	target/wasm32-wasi/release/hello-world.wasm
Hello, world!
```

最后，cargo 本身有一个扩展，它使用 Wasmtime，有助于使基于 Rust 的 WASI 应用程序的构建、运行和测试更加容易。

```bash
brian@tweezer ~/g/w/s/ch11 > cargo install cargo-wasi 
	Updating crates.io index
	...
brian@tweezer ~/g/w/s/c/hello-world> cargo wasi run
	Finished dev [unoptimized + debuginfo] target (s) in 0.03s
	 Running `target/wasm32-wasi/debug/hello-world.wasm`
Hello, world!
```

这一切工作的实际细节比我现在想的要复杂得多，但还是要给你一点窥视幕后的机会。 例 11-2 是一个来自 Wasmtime WASI 教程中的一个例子。它的工作层次比你以前做过的要低，但它是相当典型的系统编程。

```java
;; Taken from the Wasmtime WASI Tutorial
(module
    ;; Import the required fd_write WASI function which will write the given io vectors to stdout
    ;; The function signature for fd_write is:
    ;; (File Descriptor, *iovs, iovs_len, nwritten) -> Returns number of bytes written
    (import "wasi_unstable" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))

    (memory 1)
    (export "memory" (memory 0))

    ;; Write 'hello world\n' to memory at an offset of 8 bytes
    ;; Note the trailing newline which is required for the text to appear
    (data (i32.const 8) "hello world\n")

    (func $main (export "_start")
        ;; Creating a new io vector within linear memory
	;; iov.iov_base - This is a pointer to the start of the 'hello world\n' string
        (i32.store (i32.const 0) (i32.const 8))
	;; iov.iov_len - The length of the 'hello world\n' string
        (i32.store (i32.const 4) (i32.const 12))

        (call $fd_write
            (i32.const 1) ;; file_descriptor - 1 for stdout
            (i32.const 0) ;; *iovs - The pointer to the iov array, which is stored at memory location 0
            (i32.const 1) ;; iovs_len - We're printing 1 string stored in an iov - so one.
            (i32.const 20) ;; nwritten - A place in memory to store the number of bytes written
        )
        drop ;; Discard the number of bytes written from the top of the stack
    )
)
```

Unix 管道和过滤器的工具构成方法允许你将一个程序的输出重定向到另一个程序的输入 [^6]。这方面的例子包括使用 less 命令来暂停滚动的终端信息，或者使用 grep 命令来查找进程表中符合某种模式的元素。

文件是 Unix 中对磁盘上的真实文件以及虚拟文件（如程序的输入或输出）的共同抽象。向控制台打印的能力是通过写到一个特定的文件描述符来实现的。在这种环境下，程序中的文件描述符 0 代表标准输入，或被传入程序的内容。文件描述符 1 代表标准输出，或者是程序在正常情况下输出的内容。文件描述符 2 是标准错误，它通常用于错误信息。

我们已经有几章没有接触过 Wat 了，这比我们迄今为止看到的稍微复杂一些，但我认为在一些指导下你应该能够理出头绪。

我们做的第一件事是从 `wasi_unstable` 命名空间导入一个名为 `fd_write` 的函数。这是一个 WASI 环境将满足我们的期望的地方，如果它想的话。如果不提供给我们这种行为，我们将无法执行。

`fd_write` 函数需要四个参数，分别表示要使用哪个文件描述符，我们在内存中存储了一个要写入的字符串，它有多长，以及要在哪里写入的字节数。按照规定，这将是在我们内存中的字符串之后。

接下来我们定义我们的模块的 Memory 实例，并将其导出。我们刚刚导入的函数要根据我们发送的参数对其进行询问。我们使用一个数据元素将字符串 "hello world" 写入我们的内存中的第 8 字节。最后，我们导出一个方法，最终调用所有这些。

我们将字符串的基础指针的数字位置写入前四个字节，将其长度写入随后的四个字节。字符串本身将存在于这些数字之后。最后，我们调用我们导入的 `fd_write` 函数。

你会注意到我们甚至不需要把 Wat 文件编译成二进制模块。我们友好的 WASI 环境可以替我做到：

```bash
brian@tweezer ~/g/w/s/ch11> wasmtime hello.wat
hello world
brian@tweezer ~/g/w/s/ch11> wasmer hello.wat 
hello world
```

很明显，你不会想用 Wat 这样的方式写程序。我讨论这个只是为了让你了解幕后发生了什么。你将用 Rust 或 C 等语言写程序，并用 WASI 感知的工具链来编译它们。说到 C 语言，我们现在将在例 11-3 中最后一次重温我们信赖的"Hello, World!" 程序。

例 11-3. C 语言 "Hello, World!" 希望是最后一次！

```c
#include <stdio.h>

int main () {printf ("Hello, World!\n"); 
  return 0;
}
```

我们需要将其编译成对 WASI 友好的形式。有几种方法可以做到这一点，但最简单的方法是使用 Wasmer 中的 [wasienv 工具链](https://github.com/wasienv/wasienv)。C 语言的编译需要头文件和库，但在这种情况下，我们还需要一个能感知 WASI 的标准库功能的版本 [^7]。就像 Emscripten 替换 cc、c++、make 和 configure 一样，wasienv 也有。我删除了一些无关紧要的编译警告，但除此之外，你应该开始了解这一切是多么强大：

```bash
brian@tweezer ~/g/w/s/ch11> wasicc -o hello hello.c 
brian@tweezer ~/g/w/s/ch11> wasm3 hello.wasm Hello, World!
brian@tweezer ~/g/w/s/ch11> wasmer hello.wasm Hello, World!
brian@tweezer ~/g/w/s/ch11> wasmtime hello.wasm Hello, World!
brian@tweezer ~/g/w/s/ch11> ./hello
Hello, World!
```

我们现在使用相同的运行时来运行用 Rust 和 C 编译的未经修改的代码，同样的 WASI 形式的 WebAssembly 模块也可以在 Linux 或 Windows 上运行。只要我们的 WASI 主机能满足我们的期望，它就应该在任何 WebAssembly 运行的地方运行。请注意，wasienv 甚至还为我们生成了一个独立的本地应用程序。你将在下一章中了解到更多关于这一点的内容。

事实证明，Node.js 和 Deno 也都支持 WASI。甚至还有一个 JavaScript polyfill，可以让你的支持 WASI 的应用程序在浏览器中运行！[WASI  polyfill](https://wasi.dev/polyfill/) 中的例子如图 11-1 所示。

![图 11-1. 在浏览器中运行 polyfill 中的 WASI 应用程序](../images/f11-1.png)

WebAssembly 使你的代码可移植。WASI 努力使你的应用程序 在你希望的时候满足它的期望，从而实现可移植。

## 基于能力的安全

在无处不在的计算环境中，WASI 还有一个方面对 WebAssembly 的未来至关重要。我们不希望我们的软件被恶意程序窃取。由于我们经常无法分辨谁是谁，我们可能会把有限的沙盒环境作为默认环境。

从一开始，WASI 就被设想为一种对其赋予托管模块的行为实施基于能力的安全限制的手段 [^8]。

简而言之，这意味着，就像 WebAssembly 不给任意代码直接访问内存一样，WASI 也不给它直接访问敏感资源，如文件句柄、网络套接字或子进程细节。相反，这些资源将通过不可伪造的、不透明的句柄暴露出来，为代码提供能力。由于这需要在 WebAssembly 模块之间传递特定语言或操作系统级别的结构，我们将需要一种方法来进行外部引用。

在写这本书的时候，如何以及为什么这样做是一个复杂的目标。我一直在为关注多少细节而挣扎，并确定了这样一个立场，即目前大部分细节都将是分散注意力的。在某种程度上，这是因为提案正在进行中。这也是因为它在某些方面是超级复杂的，即使它作为一个越来越优雅的设计出现。我将在 [第 12 章](../extending-wasm-platform/) 中让你了解更多的细节。但现在，让我们专注于看到结果。

在例 11-4 中，我们有一个用 Rust 编写的简单程序，它把一个字符串写到一个文件中，然后再读回来。从编程的角度来看，这是很简单的。当然，最大的问题是对文件系统的访问。如果你还不是一个 Rust 大师，不要为这些细节担心；这个程序的流程应该还是有意义的。

```rust
use std::fs;
use std::io::{Read, Write};

fn main () {
    let greeting = "Hello, world!";
    let outfile = "hello.txt";
    let mut output_file = fs::File::create (outfile)
        .expect (&format!("error creating {}", outfile));

    output_file.write_all (greeting.as_bytes ())
        .expect (&format!("Error writing: {}", outfile));

    let mut input_file = fs::File::open (outfile)
        .expect (&format!("error opening {}", outfile));

    let mut input = String::new ();
    input_file.read_to_string (&mut input)
        .expect (&format!("Error reading: {}", outfile));

    println!("Read in from file: {}", input);
}
```

我在另一个 cargo 驱动的项目中有这段代码，所以生成一个本地可执行文件是小菜一碟。

```bash
brian@tweezer ~/g/w/s/c/hello-fs> cargo build --release 
	Finished release [optimized] target (s) in 0.01s
brian@tweezer ~/g/w/s/c/hello-fs> cargo run --release
	Finished release [optimized] target (s) in 0.01s
	 Running `target/release/hello-fs`
Read in from file: Hello, world!
brian@tweezer ~/g/w/s/c/hello-fs> ls -alF
total 32
drwxr-xr-x 10 brian staff 320 Jun 27 13:18 ./
drwxr-xr-x 10 brian staff 320 Jun 27 18:42 ../
-rw-r--r--	1 brian staff 177 Jun 27 12:18 Cargo.toml
-rw-r--r--	1 brian staff	13 Jun 27 18:47 hello.txt
drwxr-xr-x	3 brian staff	96 Jun 27 13:18 src/
drwxr-xr-x@ 7 brian staff 224 Jun 27 18:42 target/ 
brian@tweezer ~/g/w/s/c/hello-fs> cat hello.txt 
Hello, world!
```

正如你所看到的，我们可以建立和运行该程序。文件被创建并读回一个字符串，我们将其打印到控制台。这是可能的，因为作为这台机器的主要用户和管理员，我有权限做这些事情。

但是，如果我从网上随便下载一个程序并运行它呢？这可能不是一个好主意。我所获得的权限是通过一种我们称之为混乱的副手问题（confused deputy problem）[^9] 的情况下赋予随机的 代码的。如果它是恶意的 ，它可以删除文件，窃取我的比特币私钥 [^10]，或加密我的硬盘以提取赎金。

然而，让我们重新编译针对 WASI 的应用程序并尝试在 Wasmtime 中运行它：

```bash
brian@tweezer ~/g/w/s/c/hello-fs> cargo build --target wasm32-wasi --release
	Finished release [optimized] target (s) in 0.01s
brian@tweezer ~/g/w/s/c/hello-fs> wasmtime ↵ 
	target/wasm32-wasi/release/hello-fs.wasm
thread 'main' panicked at 'error creating hello.txt
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
Error: failed to run main module `target/wasm32-wasi/release/hello-fs.wasm`

Caused by:
	0: failed to invoke command default
	1: wasm trap: unreachable
		wasm backtrace:
		0: 0x838a - <unknown>! rust_start_panic
    1: 0x7fd5 - <unknown>!rust_panic
		2: 0x7c42 - <unknown>!std::panicking::rust_panic_with_hook
		3: 0x7190 - <unknown>!std::panicking::begin_panic_handler::{{closure}}
    4: 0x70d1 - <unknown>!std::sys_common:: rust_end_short_backtrace
		5: 0x7790 - <unknown>!rust_begin_unwind
		6: 0xdc62 - <unknown>!core::panicking::panic_fmt::h79dd662186e4ad97
    7: 0xebb2 - <unknown>!core::result::unwrap_failed::hc8762c9cd74198d4
    8: 0xce3 - <unknown>!hello_fs::main::h13132a06338f22dc
    9: 0x73d - <unknown>!std::sys_common:: rust_begin_short_backtrace 
    10: 0xe02 - <unknown>!std::rt::lang_start::{{closure}}
    11: 0x8139 - <unknown>!std::rt::lang_start_internal::hb132ad43e5d53599
    12: 0xdc9 - <unknown>! original_main
    13: 0x44d - <unknown>!_start
    14: 0x11bff - <unknown>!_start.command_export
  note: run with `WASMTIME_BACKTRACE_DETAILS=1` environment variable to display more information
```

好吧，这并不奏效。有相当多的噪音，但突出的一点是，我们没有能力做我们想要做的事情，因为 WASI 主机没有以不可伪造的句柄（在前面的例子中称为" 预打开的文件描述符 "）的形式给我们。

重新启动可执行文件，但调用允许目录访问的命令行参数，就可以解决问题：

```bash
brian@tweezer ~/g/w/s/c/hello-fs> wasmtime --dir=. ↵ 
	target/wasm32-wasi/release/hello-fs.wasm
Read in from file: Hello, world!
```

Wasmer 默对信息的框架略有不同，但这是同一个问题：

```bash
brian@tweezer ~/g/w/s/c/hello-fs> wasmer target/wasm32-wasi/release/hello-fs.wasm
thread 'main' panicked at 'error creating hello.txt: Os
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace error: failed to run `target/wasm32-wasi/release/hello-fs.wasm`
    │   1: WASI execution failed
    │   2: failed to run WASI `_start` function
    │   3: RuntimeError: unreachable
                at __rust_start_panic (hello-fs.wasm [171]:0x838a)
                at rust_panic (hello-fs.wasm [163]:0x7fd5)
                at std::panicking::rust_panic_with_hook (hello-fs.wasm [156]:0x7c42)
                at std::panicking::{{closure}} (hello-fs.wasm [145]:0x7190)
                at std::sys_common (hello-fs.wasm [144]:0x70d1)
                at rust_begin_unwind (hello-fs.wasm [155]:0x7790)
                at core::panicking::panic_fmt (hello-fs.wasm [239]:0xdc62)
                at core::result::unwrap_failed (hello-fs.wasm [262]:0xebb2)
                at hello_fs::main::h13132a06338f22dc (hello-fs.wasm [17]:0xce3)
                at std::sys_common (hello-fs.wasm [12]:0x73d)
                at std::rt::lang_start::{{closure}} (hello-fs.wasm [20]:0xe02)
                at std::rt::lang_start_internal:: (hello-fs.wasm [164]:0x8139)
                at __original_main (hello-fs.wasm [18]:0xdc9)
                at _start (hello-fs.wasm [10]:0x44d)
                at _start.command_export (hello-fs.wasm [310]:0x11bff)
╰─> 4: unreachable
```

而解决方案也是如此：

```bash
brian@tweezer ~/g/w/s/c/hello-fs> wasmer --dir=. ↵ 
	target/wasm32-wasi/release/hello-fs.wasm
Read in from file: Hello, world!
```

在可执行实例中添加一个命令行选项，似乎不是最强大的安全机制，但这忽略了更大的问题。你当然可以使用 Wasmer 或 Wasmtime 来启动你的应用程序，但这并不是必须的。在下一章中，你将学习如何编写你自己的支持 WASI 的代码，在这种情况下，你可以使用任何你想要的机制来启用或禁用行为。

最后让我们以更广泛的视角来看待 WASI，为本章作个总结。

## 愿景

WebAssembly 的全部愿景比大多数人所了解的要广泛得多 。人们对 MVP 的能力有一定的认识，但对大多数人来说，这就是它的终点。考虑到语言和 JavaScript 运行时引擎的进步，能够使用 JavaScript 以外的语言将代码部署到浏览器上的想法有点酷，但这不一定必要。

对我来说，愿景中更重要的部分是，我们将能够用我们想要的任何语言编写代码，并在我们想要的任何环境中使用它。这使我们能够在新的环境中利用现有的软件，而不需要重写它。而且，这允许我们挑选一种适合问题的语言，而不需要一个新的运行时。如果一个组织在生产中部署了 Java 虚拟机（JVM），那么转移到 Ruby on Rails 或基于 Python 的解决方案就可能需要安装它们各自的环境 [^11]。

这决不是一个全有或全无的前景。有时我们会因为性能的原因而想运行原生代码，有时我们会想获得网络零安装方面的好处。有时我们想在沙盒中运行，有时又不想。考虑到将这一设想付诸实施的所有变量，从头开始设计几乎是不可能的。

但你希望在这一章中开始看到的是，由于 WebAssembly 的设计者一直在刻意选择，这个愿景正在变成现实。他们试图避免过度或不足的工程化。MVP 遗漏了一些不是每一种语言都支持的语言特性，如线程、垃圾收集和异常等。所有这些东西都有技术建议和工作实例，但这在初期就显得太多。

显然，该平台目前存在着局限性。在有意义的地方和时候，有源源不断的建议被公布，以扩展平台的能力。WASI 已经成为一个焦点，允许这些建议独立出现，并被 Wasmtime、Wasmer 和 Wasm3 等平台逐步采用。诚然，这使得跟踪哪些内容被添加到哪里变得非常混乱，但通过程序机制，他们也开始整理出这个问题。

为了促进大量所需的行为，WASI 的设计者意识到，有必要将模块之间的链接方式标准化。我们需要一个解决方案，使我们能够在不暴露底层结构的情况下引用内存中的不可伪造的句柄。我们还需要一种方法来引用诸如字符串、列表和记录等类型。这成为了对提案设计和实现的依赖，这些提案将解锁一些额外的行为。其中一些建议将在下一章介绍，但 Wasmtime、Wasmer 和 Wasm3 已经开始实施这些基本建议中的几个。

这个过程将继续下去，新的 WASI 模块将被设计出来。虽然最初的行为集中在文件和控制台访问，但已经有关于一系列功能的建议，包括加密功能、加密货币合约、2D 和 3D 图形、网络和神经网络系统。不会有单一的 WASI 命名空间，而是会源源不断的出现。不是每个应用程序都需要每个模块。不是每个环境都会提供这些模块的完整实现。它们可以在上下文中被限制，被虚拟化，或在具有相同依赖性的多个模块中共享。为此，WASI 可能永远不会 "完成"。

在 图 11-2 中，你可以看到愿景的基本轮廓，及其如何达到目的的。在 [第 12 章](../extending-wasm-platform/) 和后续章节中，我将详细阐述其中的一些观点，但现在我认为这个愿景是一个合适的目标。

![图 11-2. WASI 的分层设想（来源：https://github.com/bytecodealliance/wasmtime/blob/main/docs/WASI-overview.md）](../images/f11-2.png)

在软件分层的顶部是我们的应用程序。这显然是我们编写的大部分内容，包括独立的可执行文件、Web 应用程序、框架、库、微服务、无服务器函数等等。这些将代表我们创造的商业价值的绝大部分。当我们做出糟糕的技术选择时，这些商业价值就会被锁在孤岛上。我们很难提取功能，所以通常我们唯一真正的选择是重新实施，这通常与增加商业价值相反。即使我们做出了好的技术选择，我们的行业也不会无所事事，而且重用的范围通常是有限的。

然而，在这个愿景中，我们可以想象出现一个通用的框架来表达我们对软件运行环境的期望。我们已经开始看到，我们是如何通过编写中间的、可移植的表示法来获得 WebAssembly 的语言独立性。这给我们留下了在我们希望扩展到的环境中经常无法满足的期望。现在，我们开始看到宿主环境如何能够模块化、可虚拟化、可交换等，以提供满足我们界面期望的功能。在浏览器中运行但期望访问文件系统的代码可以被赋予一个满足需求的抽象，使用本地存储或其他东西。你甚至可以想象这样的场景："文件系统" 抽象是一个用户文件系统，如 Fuse，由一个云存储供应商透明地支持 [^12]。

重点是，为了在这些环境之间转移，我们的代码不一定要重写，无论它们是完全特权的本地应用程序、虚拟化、托管、浏览器内，还是嵌入式。利用模块化编译器架构，如 LLVM，使我们有能力添加一个后端，以灵活的方式表达我们的期望。我们可以实现代码共享和动态链接策略，因为它是有意义的。

反过来说，我们周围的恶意软件、网络钓鱼攻击和勒索软件的安全地狱景象正如滚雪球般越滚越大。如果我们有能力在沙盒环境中用任何语言从任何地方运行代码，这对加强我们的默认安全态势会有很大帮助。

一个安全、可移植和快速的计算生态系统的愿景是如此强大，以至于 [字节码联盟（Bytecode Alliance）](https://bytecodealliance.org/) 的成立，以推动其发展。早期成员包括 Mozilla、英特尔、微软、Fastly 等。他们正在安全、保护环境和性能之间取得平衡。他们正在创造一种 "nanoprocess" 机制，而不是在孤立的模块之间进行大型的、重量级的通信过程，从而使许多不同的要求成为现实。他们正在为我们的行业想象一个更光明的未来，即能够开发高性能、安全的代码，以满足现代系统的需求，又能比我们目前能够更长时间地获取商业价值。对这一点，我们深信不疑。

## 注释

[^1]:  [Web IDL](https://en.wikipedia.org/wiki/Web_IDL) 是接口定义语言（IDL），用于表达浏览器提供的行为，是标准过程的一部分。
[^2]: 如今更普遍地被称为 [WinAPI](https://en.wikipedia.org/wiki/Windows_API)，这是微软在其操作系统全盛时期的最大优势之一。
[^3]: [应用程序二进制接口](https://en.wikipedia.org/wiki/Application_binary_interface) 是操作系统用来定义应用程序如何链接和执行的。
[^4]: [Wastime](https://wasmtime.dev/) 最初是 Mozilla 的一个项目，但现在是字节码联盟的一部分，我们将很快讨论这个问题。
[^5]: [Wasmer](https://wasmer.io/) 是一家公司和 WebAssembly 托管环境的名称。
[^6]: 这种架构风格是 [Unix](https://en.wikipedia.org/wiki/Pipeline_(Unix)) 是使它对发行商来说如此强大，对开发者来说如此富有成效的一方面。
[^7]: 目前，我正试图让你远离这些复杂的东西，但如果你坚持要了解更多，你可以查看 [GitHub](https://github.com/WebAssembly/wasi-libc)。
[^8]: [基于能力的安全](https://en.wikipedia.org/wiki/Capability-based_security) 已经超出了本书的范围。
[^9]: 当权限混合在一起时，就很难分清谁被允许做什么。
[^10]: 我从 2008 年开始关注比特币，如果我真的开采的，收入会很可观。哎！
[^11]: 是的，我知道 Jython 和 JRuby。
[^12]: [Fuse](https://en.wikipedia.org/wiki/Filesystem_in_Userspace) 是很多虚拟文件系统的基础。
