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

有些事情在 WebAssembly 中很难做到，但在其他平台上却很容易。 从文件系统读取、写入控制台以及在内存中操作字符串在 C、C++ 或 Rust 等语言中都很简单。 操作系统将允许具有足够权限的用户执行这些操作。 这里没有明确的上下文界限。

不幸的是，这也是大多数现代网络威胁背后的问题，例如网络钓鱼攻击、特权升级、供应链攻击等。 如果攻击者可以说服特权用户运行不可信的代码，他们通常可以窃取他们不应该访问的其他资源。 沙盒环境的存在是为了防止这种情况发生，但它们通常很慢、很麻烦，并且对开发人员来说是一种负担。 WebAssembly 想要解决这个问题，而且它在很多方面都做到了。 然而，从根本上说，WebAssembly 模块无法访问其托管环境未提供的任何内容。

到目前为止，我们看到的 MVP 和工具主要是关于使代码可移植的。 我们现在要学习的是如何使应用程序可移植。 事实证明，解决方案从根本上讲是为了满足期望。 这不仅仅是语言的问题，还有 API 可用性、运行时环境配置、安全限制等方面的问题。 我们的宿主环境并不总是符合我们运行的代码的预期。 我们仍然可以控制它。

## WebAssembly 系统接口（WASI）

到目前为止，您所看到的所有很酷的演示和代码示例，尤其是那些涉及图形、声音、视频等的演示和代码示例，都是因为它们在浏览器中运行才成为可能。 浏览器被设计为软件的通用客户端，是其他代码的宿主。 可以通过发送任意程序到客户端执行来扩展网络。 它具有内置的安全限制，但现在它实际上是一个功能丰富的编程环境，充满了 API，例如用于 3D 图形的 WebGL、加速视频、用于协作的 WebRTC 等等。 Emscripten 在浏览器运行时可用的基础上提供标准 API（例如 POSIX 和 OpenGL）的实现，因此标准 C/C++ 应用程序可以简单地编译并仍然工作。

我们已经看到了一种为模块实例提供函数的机制，这些函数可以通过它们导入的对象来调用。 例如，传入一个打印到控制台的 JavaScript 函数，而不是依赖 C 标准库来提供对 `printf()` 的访问。 然而，这基本上是一种不能令人满意的方法。 每个需要打印到控制台的 WebAssembly 模块都应该有一个可调用的函数，最好是已经写好的，可以随时调用。 这是为了安全有效地满足期望。

但是，出于安全考虑，仅仅因为程序想要读取或写入文件系统并不意味着它可以这样做。 我们不需要遇到恶意软件。 我们想要控制应用程序访问资源的环境（如果有的话）。

另一个关于预期的问题是，浏览器之外的运行时是 WebAssembly 潜在执行面的重要组成部分。 许多 API 无法在 Node.js 或 Deno 等环境中以相同的方式使用。 没有兼容的 Web IDL 定义接口，公开对音频和视频播放、3D 图形等的访问[^1]。 当然还有其他类似的 API，但是它们与浏览器内部内容不兼容，必须重写应用程序才能使用它们。

通常，POSIX 函数将在不同的操作系统中以一致的方式定义，并将映射到较低级别的内核函数或特定于平台的 API，例如 Win32 [^2]。 这些是可重用功能的关键部分，我们希望它们能够快速稳定地实现。 应用程序开发人员提供的任意 JavaScript 包装函数不太可能足够快和稳定。 许多这些额外的浏览器 API 没有与沙盒浏览器环境相同的安全保证，因此它们也不能在那里直接使用。

这些是 WebAssembly 系统接口 (WASI) 试图解决的无数问题之一。 这是一项艰巨的任务，而且工作正在扩展，此时变得相当复杂，但基础相当简单，所以我们将从这里开始。

最终，我们希望拥有一个函数生态系统，允许访问它的程序可以期望它的可用性。 我们希望这些函数能够跨语言边界工作，这意味着我们需要一些方法来引用高级结构，如字符串、列表和数组。 我们需要受保护但快速的实施。 我们希望有某种类型安全的方法，而不必在我们编写的代码中依赖太多的功能测试。 我们还希望支持它们的语言可以使用垃圾收集和异常处理等语言特性，而不会给不支持它们的语言增加负担。 为了满足这些要求，需要对 WebAssembly 平台进行扩展。 我将在[第 12 章](../extending-wasm-platform/)中介绍其中一些主要扩展，但我现在想继续讨论这个问题。

让我们重温 Rust 版本的著名示例。 [第10章](../rust/)的例 11-1，我们再来一遍。 我们确定问题出在浏览器中没有 `println!` 宏。 C 语言中也没有 `printf()` 函数。 我们已经看到了解决这个问题的各种方法，但解决方案仍然很烦人。

例 11-1. Rust "Hello, World!"

```rust
fn main () {println! ("Hello, World!");
}
```

我将重新创建一个基本 Rust 程序的示例脚手架并运行它。 `cargo new` 命令将设置一个项目的目录结构并生成一个简单的应用程序，这基本上就是前面的示例。

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

Cargo 构建工具通过在 `src/main.rs` 中放置一个友好的程序来为我们创建项目脚手架。 我们构建该程序的优化发布版本，然后运行关联的本地可执行文件。 请记住，Rust 基于 LLVM，因此默认后端将在您安装了工具链的任何操作系统上运行。

我们在[第 10 章](../rust/) 中看到，我们可以使用 WebAssembly 的后端来生成 Rust 模块，但是由于字符串、内存管理和与操作系统交互相关的限制，它无法运行。

```bash
brian@tweezer ~/g/w/s/c/hello-world> cargo build --target wasm32-unknown-unknown --release
    Compiling hello-world v0.1.0
        (/Users/brian/git-personal/wasm_tdg/src/ch11/hello-world)
      Finished release [optimized] target (s) in 0.89s
brian@tweezer ~/g/w/s/c/hello-world> ls -laF target/wasm32-unknown-unknown/release/
total 3008
drwxr-xr-x 10 brian staff	320 Jun 27 16:02 ./
drwxr-xr-x@ 5 brian staff	160 Jun 27 16:02 ../
drwxr-xr-x	2 brian staff	64 Jun 27 16:02 build/
drwxr-xr-x	4 brian staff	128 Jun 27 16:02 deps/
drwxr-xr-x	2 brian staff	64 Jun 27 16:02 examples/
-rw-r--r--	1 brian staff	228 Jun 27 16:02 hello-world.d
-rwxr-xr-x	2 brian staff 1534049 Jun 27 16:02 hello-world.wasm*
drwxr-xr-x	2 brian staff	64 Jun 27 16:02 incremental/ 
brian@tweezer ~/g/w/s/c/hello-world > wasm3 target/wasm32-unknown-unknown/release/hello-world.wasm
Error: [Fatal] repl_call: function lookup failed
Error: function lookup failed ('_start')
```

根本问题是基本模块结构没有定义与可执行程序相同类型的应用程序二进制接口 (ABI) [^3]。 它没有预期的初始化函数名称。 开发人员将 `main()` 视为起点，但这通常由非常小的 C 语言运行时从 start 方法调用。

另一个问题是无法直接写入控制台或从 WebAssembly 模块读取和写入文件。 对于 WebAssembly 来说，这似乎是一个相当大的障碍，但我鼓励你不要轻易放弃，如果我们使用不同的后端怎么办？ 我们将使用 `wasm32-unknown-unknown` 而不是 `wasm32-wasi`：

```bash
brian@tweezer ~/g/w/s/c/hello-world> cargo build --target wasm32-wasi --release
    Compiling hello-world v0.1.0
       (/Users/brian/git-personal/wasm_tdg/src/ch11/hello-world)
    Finished release [optimized] target (s) in 0.74s
```

你看到了吗？

我们再检查一下模块：

```bash
brian@tweezer ~/g/w/s/c/hello-world > wasm-objdump -x target/wasm32-wasi/release/hello-world.wasm
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

这是一个 WebAssembly 模块，但它也导出一个已知的起点，因此 WASI 感知环境（如 wasm3）知道如何初始化以及从哪里开始执行。 然而，WASI 远不止这个引导过程。 它还为模块提供了一种方便的方法来导入它需要执行的函数。 这就是 Rust wasm32-wasi 后端为我们所做的。 它正在发出对标准库实现的调用，这些实现将由我们的代码运行的主机环境提供。 此外，wasm3 至少是一个基本的 WASI 环境，因此它提供了这些功能。 它是 WASI 之前的浏览器外 WebAssembly 引擎，但它积极支持不断发展的标准和更新的提案，我们将在下一章讨论这些内容。

如果按照[附录](../appendix/)中的安装步骤，您可以再安装两个 WASI 环境，Wasmtime [^4] 和 Wasmer [^5]。 两者都是开源和独立的运行时。

```bash
brian@tweezer ~/g/w/s/c/hello-world> wasmtime target/wasm32-wasi/release/hello-world.wasm
Hello, world!
brian@tweezer ~/g/w/s/c/hello-world> wasmer target/wasm32-wasi/release/hello-world.wasm
Hello, world!
```

最后，cargo 本身有一个扩展，它使用 Wasmtime，可以使基于 Rust 的 WASI 应用程序的构建、运行和测试更加容易。

```bash
brian@tweezer ~/g/w/s/ch11 > cargo install cargo-wasi 
	Updating crates.io index
	...
brian@tweezer ~/g/w/s/c/hello-world> cargo wasi run
	Finished dev [unoptimized + debuginfo] target (s) in 0.03s
	 Running `target/wasm32-wasi/debug/hello-world.wasm`
Hello, world!
```

这一切如何运作的实际细节比我现在想象的要复杂得多，但仍然可以让您稍微了解一下幕后情况。 例 11-2 是 Wasmtime WASI 教程中的示例。 这是一项比您过去从事的工作级别更低的工作，但它是相当典型的系统编程。

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

Unix 管道和过滤器工具方法允许您将一个程序的输出重定向到另一个程序的输入 [^6]。 这方面的示例包括使用 less 命令暂停滚动终端消息，或使用 grep 命令在进程表中查找与特定模式匹配的元素。

文件是 Unix 中磁盘上真实文件以及程序输入或输出等虚拟文件的常见抽象。 打印到控制台的能力是通过写入特定的文件描述符来实现的。 在此上下文中，程序中的文件描述符 0 表示标准输入，或传递到程序中的任何内容。 文件描述符 1 表示标准输出，或程序通常输出的任何内容。 文件描述符 2 是标准错误，通常用于错误信息。

我们有几章没有接触过 Wat，它比我们目前看到的要复杂一点，但我认为只要有一点指导，你应该能够弄明白。

我们做的第一件事是从 `wasi_unstable` 命名空间导入一个名为 `fd_write` 的函数。 如果需要，这就是 WASI 环境可以满足我们期望的地方。 如果我们不这样做的话，程序将无法执行。

`fd_write` 函数有四个参数，指示要使用哪个文件描述符，我们在内存中存储要写入的字符串、长度以及写入位置的字节数。 正如指定的那样，这将在内存中的字符串之后。

接下来我们定义模块的 Memory 实例并将其导出。 我们刚刚导入的函数将根据我们发送给它的参数来询问它。 我们使用数据元素将字符串 “hello world” 写入内存中的第八个字节。 最后，我们导出一个最终调用所有这些的方法。

我们将字符串底层指针的数字位置写入前四个字节，将其长度写入接下来的四个字节。 字符串本身将存在于这些数字之后。 最后，我们调用导入的 `fd_write` 函数。

您会注意到我们甚至不需要将 Wat 文件编译成二进制模块。 我们友好的 WASI 环境可以为我做到：

```bash
brian@tweezer ~/g/w/s/ch11> wasmtime hello.wat
hello world
brian@tweezer ~/g/w/s/ch11> wasmer hello.wat 
hello world
```

显然，您不想像 Wat 那样编写程序。 我讨论这个只是为了让您了解幕后发生的事情。 您将使用 Rust 或 C 等语言编写程序，并使用 WASI 感知工具链编译它们。 说到 C 语言，我们现在将重温我们值得信赖的“Hello, World!”。 在示例 11-3 中最后一次编程。

例 11-3. C 语言 "Hello, World!" 希望是最后一次！

```c
#include <stdio.h>

int main () {printf ("Hello, World!\n"); 
  return 0;
}
```

我们需要将其编译成 WASI 友好的形式。 有几种方法可以做到这一点，但最简单的方法是使用 Wasmer 中的 [wasienv 工具链](https://github.com/wasienv/wasienv)。 C 语言编译需要头文件和库，但在这种情况下，我们还需要标准库函数的 WASI 感知版本[^7]。 就像 Emscripten 取代了 cc、c++、make 和 configure 一样，wasienv 也是如此。 我删除了一些不相关的编译警告，但除此之外，您应该开始了解这一切的强大之处：

```bash
brian@tweezer ~/g/w/s/ch11> wasicc -o hello hello.c 
brian@tweezer ~/g/w/s/ch11> wasm3 hello.wasm Hello, World!
brian@tweezer ~/g/w/s/ch11> wasmer hello.wasm Hello, World!
brian@tweezer ~/g/w/s/ch11> wasmtime hello.wasm Hello, World!
brian@tweezer ~/g/w/s/ch11> ./hello
Hello, World!
```

我们现在使用相同的运行时来运行用 Rust 和 C 编译的未修改代码，并且相同的 WASI 风格的 WebAssembly 模块也可以在 Linux 或 Windows 上运行。 只要我们的 WASI 主机符合我们的期望，它就应该在 WebAssembly 运行的任何地方运行。 请注意，wasienv 甚至为我们生成了一个独立的本机应用程序。 您将在下一章中了解更多相关信息。

事实证明，Node.js 和 Deno 都支持 WASI。 甚至还有一个 JavaScript polyfill 可以让您支持 WASI 的应用程序在浏览器中运行！ [WASI polyfill](https://wasi.dev/polyfill/) 中的示例如图 11-1 所示。

![图 11-1. 在浏览器中运行 polyfill 中的 WASI 应用程序](../images/f11-1.png)

WebAssembly 使您的代码可移植。 WASI 通过使您的应用程序在您需要时满足其期望来努力实现可移植性。

## 基于能力的安全

在普适计算的背景下，WASI 的另一个方面对 WebAssembly 的未来至关重要。 我们不希望我们的软件被恶意程序窃取。 由于我们常常分不清谁是谁，我们可能会默认使用有限的沙箱环境。

从一开始，WASI 就被认为是一种对其分配给托管模块的行为实施基于能力的安全限制的方法 [^8]。

简而言之，这意味着就像 WebAssembly 不给任意代码直接访问内存一样，WASI 也不给它直接访问敏感资源，如文件句柄、网络套接字或子进程细节。 相反，这些资源将通过提供代码功能的不可伪造的、不透明的句柄公开。 由于这需要在 WebAssembly 模块之间传递特定语言或操作系统级别的结构，因此我们需要一种方法来进行外部引用。

在撰写本书时，如何以及为何这样做是一个复杂的目标。 我一直在纠结于要关注多少细节，大多数细节都会分散注意力。 部分原因是提案正在制定中。 这也是因为它在某些方面非常复杂，即使它的设计越来越优雅。 我将在[第 12 章](../extending-wasm-platform/) 中让您了解更多详细信息。 但现在，让我们专注于看到结果。

在例 11-4 中，我们有一个用 Rust 编写的简单程序，它将一个字符串写入文件并读回。 从编程的角度来看，这很简单。 当然，最大的问题是对文件系统的访问。 如果您还不是 Rust 大师，请不要担心这些细节； 程序的流程应该仍然有意义。

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

如您所见，我们可以构建并运行该程序。 该文件被创建并作为字符串读回，我们将其打印到控制台。 这是可能的，因为作为这台机器的主要用户和管理员，我有权执行这些操作。

但是，如果我只是从 Internet 下载一个程序并运行它呢？ 这可能不是一个好主意。 我得到的权限是通过我们称之为混淆代理问题 [^9] 的东西分配给随机代码的。 如果它是恶意的，它可能会删除文件、窃取我的比特币私钥 [^10]，或者加密我的硬盘以勒索赎金。

但是，让我们针对 WASI 重新编译应用程序并尝试在 Wasmtime 中运行它：

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

好吧，这行不通。 有很多噪音，但突出的是我们没有能力做我们想做的事，因为 WASI 主机无法访问不可伪造的句柄（在前面的示例中称为“预打开文件描述符”）形式给我们。

重新启动可执行文件，但调用允许目录访问的命令行参数，可以解决问题：

```bash
brian@tweezer ~/g/w/s/c/hello-fs> wasmtime --dir=. 
 target/wasm32-wasi/release/hello-fs.wasm
Read in from file: Hello, world!
```

Wasmer 的消息略有不同：

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
brian@tweezer ~/g/w/s/c/hello-fs> wasmer --dir=. target/wasm32-wasi/release/hello-fs.wasm
Read in from file: Hello, world!
```

向可执行实例添加命令行选项可能看起来不是最强大的安全机制，但它忽略了更大的问题。 您当然可以使用 Wasmer 或 Wasmtime 来启动您的应用程序，但这不是必须的。 在下一章中，您将学习如何编写自己的 WASI 感知代码，在这种情况下，您可以使用您想要启用或禁用行为的任何机制。

最后，让我们从更广阔的角度审视 WASI 来结束本章。

## 愿景

WebAssembly 的完整愿景比大多数人意识到的要广阔得多。 人们对 MVP 的能力有一定的认识，但对于大多数人来说，这就是它的终点。 鉴于语言和 JavaScript 运行时引擎的进步，能够使用 JavaScript 以外的语言将代码部署到浏览器的想法有点酷，但不一定如此。

对我来说，愿景中更重要的部分是我们将能够用我们想要的任何语言编写代码，并在我们想要的任何环境中使用它。 这使我们能够在新环境中利用现有软件而无需重写它。 此外，这使我们能够选择一种适合问题的语言，而无需新的运行时。 如果组织在生产中部署 Java 虚拟机 (JVM)，则迁移到 Ruby on Rails 或基于 Python 的解决方案可能需要安装它们各自的环境[^11]。

这绝不是一个全有或全无的前景。 有时出于性能原因我们希望运行本机代码，有时我们希望获得网络上零安装的好处。 有时我们想在沙箱中运行，有时我们不想。 考虑到实现这一愿景的所有变量，从头开始设计几乎是不可能的。

但是你希望在本章开始看到的是，由于 WebAssembly 的设计者一直在做出的深思熟虑的选择，这个愿景正在成为现实。 他们尽量避免设计过度或设计不足。 MVP 省略了一些并非每种语言都支持的语言特性，例如线程、垃圾回收和异常。 所有这些东西都有技术建议和工作示例，但在早期似乎太多了。

显然，该平台目前存在局限性。 有源源不断的提案正在宣布，何时何地扩展平台的功能是有意义的。 WASI 已成为一个焦点，允许这些建议独立出现并逐步被 Wasmtime、Wasmer 和 Wasm3 等平台采用。 诚然，这让跟踪添加的内容变得非常混乱，但通过编程机制，他们也开始解决这个问题。

为了促进对 WASI 的扩展，WASI 的设计者意识到有必要对模块的链接方式进行标准化。 我们需要一种解决方案，使我们能够在不暴露底层结构的情况下引用内存中不可伪造的句柄。 我们还需要一种方法来引用类型，例如字符串、列表和记录。 这成为对提案的设计和实施的依赖，这些提案将解锁一些额外的行为。 其中一些建议将在下一章中介绍，但 Wasmtime、Wasmer 和 Wasm3 已经开始实施其中的一些基本建议。

这个过程将继续，新的 WASI 模块将被设计出来。 虽然最初的行动集中在文件和控制台访问上，但已经提出了一系列功能的建议，包括加密功能、加密货币合约、2D 和 3D 图形、网络和神经网络系统。 不会有一个单一的 WASI 名称空间，而是源源不断的名称空间。 并非每个应用程序都需要每个模块。 并非每个环境都会提供这些模块的完整实现。 它们可以是上下文绑定的、虚拟化的，或者在具有相同依赖性的多个模块之间共享。 因此，WASI 可能永远不会“完成”。

在图 11-2 中，您可以看到愿景的基本轮廓以及它是如何实现的。 在[第 12 章](../extending-wasm-platform/) 和后续章节中，我将详细阐述其中的一些要点，但目前我认为这个愿景是一个合适的目标。

![图 11-2. WASI 的分层设想（来源：https://github.com/bytecodealliance/wasmtime/blob/main/docs/WASI-overview.md）](../images/f11-2.png)

在软件层之上是我们的应用程序。 这显然是我们编写的大部分内容，包括独立可执行文件、Web 应用程序、框架、库、微服务、无服务器函数等。 这些将代表我们创造的绝大部分商业价值。 当我们做出糟糕的技术选择时，这些商业价值就会被锁在孤岛中。 我们很难提取功能，因此我们唯一真正的选择往往是重新实现，这通常与增加业务价值背道而驰。 即使我们做出了很好的技术选择，我们的行业也不会闲着，重用的范围往往是有限的。

然而，在这个愿景中，我们可以想象出现一个通用框架来表达我们对软件运行环境的期望。 我们已经开始了解如何通过编写中间的、可移植的表示来获得 WebAssembly 的语言独立性。 这给我们留下了在我们希望扩展到的环境中经常无法满足的期望。 我们现在开始了解托管环境如何模块化、可虚拟化、可交换等，以提供满足我们界面期望的功能。 在浏览器中运行但期望访问文件系统的代码可以使用本地存储或其他东西进行满足需求的抽象。 您甚至可以想象这样的场景，其中“文件系统”抽象是一个用户文件系统，如 Fuse，由云存储提供商透明支持 [^12]。

关键是，我们的代码不一定要重写才能在这些环境之间移动，无论它们是完全特权的本机应用程序、虚拟化、托管、浏览器内还是嵌入式。 利用 LLVM 等模块化编译器架构，我们能够添加后端以灵活的方式表达我们的需求。 我们可以实施代码共享和动态链接策略，因为它很有意义。

反过来，我们周围的恶意软件、网络钓鱼攻击和勒索软件的安全地狱正在滚雪球。 如果我们能够在沙盒环境中以任何语言从任何地方运行代码，这将大大有助于加强我们的默认安全态势。

安全、便携和快速计算生态系统的愿景是如此强大，以至于 [字节码联盟](https://bytecodealliance.org/) 成立以推动其发展。 早期成员包括 Mozilla、Intel、Microsoft、Fastly 等。 他们在安全、保护环境和性能之间取得平衡。 他们不是在孤立的模块之间使用大型、重量级的通信过程，而是创建一个“纳米过程”机制来满足许多不同的需求。 他们正在为我们的行业设想一个更光明的未来，一个可以开发满足现代系统需求的高性能、安全代码，同时比我们现在更长时间地获取商业价值的未来。对这一点，我们深信不疑。

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
