---
title: "Rust 编译 WebAssembly 指南"
date: 2023-02-24T11:00:00+08:00
draft: false
authors: ["Surma"]
summary: "关于将 Rust 编译为 WebAssembly 的所有知识。"
tags: ["WebAssembly","Rust"]
categories: ["WebAssembly"]
links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://surma.dev/things/rust-to-webassembly/
---

下面是我所知道的关于将 Rust 编译为 WebAssembly 的所有知识。

前一段时间，我写了一篇[如何在没有 Emscripten 的情况下将 C 编译为 WebAssembly](https://surma.dev/things/c-to-webassembly) 的博客文章，即不默认工具来简化这个过程。 在 Rust 中，使 WebAssembly 变得简单的工具称为 [wasm-bindgen](https://rustwasm.github.io/wasm-bindgen/)，我们正在放弃它！ 同时，Rust 有点不同，因为 WebAssembly 长期以来一直是一流的目标，并且开箱即用地提供了标准库布局。

## Rust 编译 WebAssembly 入门

让我们看看如何让 Rust 以尽可能少的偏离标准 Rust 工作流程的方式编译成 WebAssembly。 如果你浏览互联网，许多文章和指南都会告诉你使用 `cargo init --lib` 创建一个 Rust 库项目，然后将 `crate-type = ["cdylib"]` 添加到你的 `cargo.toml`，如下所示：

```ini
[package]
name = "my_project"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]
   
[dependencies]
```

如果你不将 crate 类型设置为 `cdylib`，Rust 编译器将生成一个 `.rlib` 文件，这是 Rust 自己的库格式。 虽然 `cdylib` 这个名字暗示了一个与 C 兼容的动态库，但我怀疑它真的只是代表“使用可互操作的格式”或类似的东西。

{{<callout note "什么是 crate?">}}

在 Rust 编程中，Crate（中文意思是 "板条箱"）指的是 Rust 语言中的包（Package），是 Rust 代码的一个单元，用于组织、构建和共享 Rust 代码。一个 Crate 可以包含一个或多个模块（Module），并且可以被其他 Crate 引用和使用。

每个 Crate 都需要有一个 Cargo.toml 文件作为其配置文件。Cargo.toml 中包含了 Crate 的元信息，如名称、版本、作者、依赖等信息。同时，Cargo.toml 中还可以定义编译器选项、环境变量等配置信息，用于构建和发布 Crate。

在 Rust 社区中，有很多优秀的 Crate 可以供使用。通过引用这些 Crate，可以快速、简便地开发高质量的 Rust 应用程序。同时，Rust 社区也鼓励开发者贡献自己的 Crate，以便其他开发者使用和贡献。

cdylib 也可以被称为 "C-compatible Dynamic Library"。cdylib Crate 可以通过 Rust 语言编写动态链接库，并将其导出为 C ABI（Application Binary Interface）。这使得其他语言（如 C、C++、Python、Java 等）可以通过 C ABI 接口调用 Rust 动态链接库中的函数和变量。这对于 Rust 与其他语言的互操作性非常重要，特别是在需要与现有代码进行集成的情况下。

使用 cdylib Crate 可以方便地创建和发布 Rust 动态链接库，并将其与其他语言进行集成。同时，cdylib Crate 也提供了一些与动态链接库相关的工具和 API，如动态链接库版本管理、符号导出等。这些工具和 API 可以方便地将 Rust 动态链接库的开发和集成过程变得更加简单、可靠和高效。

{{</callout>}}

现在，我们将使用 Cargo 在创建新库时生成的默认/示例函数：

```rust
pub fn add(left: usize, right: usize) -> usize {
    left + right
}
```

一切就绪后，我们现在可以将这个库编译为 WebAssembly：

```bash
cargo build --target=wasm32-unknown-unknown --release
```

你会在 `target/wasm32-unknown-unknown/release/my_project.wasm` 找到它。 在整篇文章中，我将继续使用 `--release` 进行构建，因为它使 WebAssembly 模块在我们反汇编时更具可读性。

{{<callout note "什么是 Cargo？">}}

Cargo 是一个 Rust 项目管理工具，用于构建、测试、发布 Rust 应用程序和库。Cargo 提供了一个命令行界面和一组 Rust API，用于管理项目依赖、编译、测试和发布过程。

以下是 Cargo 提供的主要功能：

1. 依赖管理：Cargo 可以通过 Cargo.toml 文件管理 Rust 项目的依赖。当添加、更新或删除依赖时，Cargo 会自动处理依赖的版本控制、依赖解决和依赖编译等问题。
2. 构建和测试：Cargo 可以使用 rustc 编译器构建 Rust 项目，并自动解决依赖关系。同时，Cargo 还支持项目测试和文档生成等功能。
3. 发布和分发：Cargo 可以将 Rust 项目打包为 Crate 并发布到 crates.io 上，也可以将二进制文件打包为可执行文件并发布到其他平台上。

通过使用 Cargo，开发者可以方便地创建、构建、测试和发布 Rust 应用程序和库。同时，Cargo 还提供了一些有用的工具和命令行选项，如清理项目、查询依赖、查看构建日志等，用于提高 Rust 项目的开发效率和质量。

{{</callout>}}

### 可执行文件与库

你可以创建一个 Rust 可执行文件（通过 `cargo init --bin`），而不是创建一个库。 但是请注意，你要么必须让 `main()` 函数具有完善的签名，要么使用 `#![no_main]` 关闭编译器以让它知道缺少 `main()` 是故意的。

那个更好吗？ 这对我来说似乎是一个品味问题，因为这两种方法在功能上似乎是等同的并且生成相同的 WebAssembly 代码。 大多数时候，WebAssembly 模块似乎扮演了一个库的角色，而不是一个可执行文件（除了在 [WASI](https://wasi.dev/) 的上下文中，稍后会详细介绍！），所以在我看来，库方法在语义上似乎更可取。 除非另有说明，否则我将在本文的其余部分使用库设置。

### 导出

继续库样式的设置，让我们看看编译器生成的 WebAssembly 代码。 为此，我推荐 [WebAssembly Binary Toolkit](https://github.com/WebAssembly/wabt)（简称“wabt”），它提供了有用的工具，如 wasm2wat。 另外，请确保安装了 [Binarygen](https://github.com/WebAssembly/binaryen)，因为本文后面我们将需要 wasm-opt。 Binaryen 还提供了 `wasm-dis`，其工作方式与 wasm2wat 类似，但不产生 WebAssembly 文本格式 (WAT)。 它生成标准化程度较低的 WebAssembly S-Expression 文本格式 (WAST)。 最后，ByteCodeAlliance 的 [wasm-tools](https://github.com/bytecodealliance/wasm-tools) 提供了 `wasm-tools print`。

```bash
wasm2wat ./target/wasm32-unknown-unknown/release/my_project.wasm
```

此命令会将 WebAssembly 二进制文件转换为 WAT：

```c
(module
  (table (;0;) 1 1 funcref)
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2)))
```

令人发指的是，我们发现我们的 add 函数已从二进制文件中完全删除。 我们只剩下一个堆栈指针和两个全局变量，它们指定数据部分的结束位置和堆的开始位置。 事实证明，将函数声明为 `pub` 不足以让它出现在我们最终的 WebAssembly 模块中。 我其实希望这就足够了，但我怀疑 Rust 模块可见性是唯一的，而不是链接器级别的符号可见性。 

确保编译器不会删除我们关心的函数的最快方法是添加属性 `#[no_mangle]`，尽管我不喜欢这个命名。

```c
#[no_mangle]
pub fn add(left: usize, right: usize) -> usize {
    left + right
}
```

很少需要，但是你可以通过使用  `#[export_name = "..."]` 导出一个名称与其 Rust 内部名称不同的函数。

将我们的 `add` 函数标记为导出后，我们可以再次编译项目并检查生成的 WebAssembly 文件：

```c
(module
  (type (;0;) (func (param i32 i32) (result i32)))
  (func $add (type 0) (param i32 i32) (result i32)
    local.get 1
    local.get 0
    i32.add)
  (table (;0;) 1 1 funcref)
  (memory (;0;) 16)
  (global $__stack_pointer (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1048576))
  (global (;2;) i32 (i32.const 1048576))
  (export "memory" (memory 0))
  (export "add" (func $add))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2)))
```

这个模块可以用普通的 WebAssembly API 实例化：

```js
const importObj = {};

// Node
const data = require("fs").readFileSync("./my_project.wasm");
const {instance} = await WebAssembly.instantiate(data, importObj);

// Deno
const data = await Deno.readFile("./my_project.wasm");
const {instance} = await WebAssembly.instantiate(data, importObj);

// For Web, it’s advisable to use `instantiateStreaming` whenever possible:
const response = await fetch("./my_project.wasm");
const {instance} = 
  await WebAssembly.instantiateStreaming(response, importObj);

instance.exports.add(40, 2) // returns 42
```

突然之间，我们几乎可以使用 Rust 的所有功能来编写 WebAssembly。

需要特别注意模块边界处的函数（即你从 JavaScript 调用的函数）。至少就目前而言，最好坚持使用[能够清晰映射到 WebAssembly 的类型](https://webassembly.github.io/spec/core/syntax/types.html#number-types)（如`i32`或`f64`）。如果你使用更高级别的类型，如数组、切片，甚至 `String`，该函数最终可能会使用比它们在 Rust 中更多的参数，并且通常需要对内存布局和类似原则有更深入的了解。

### ABI

请注意：是的，我们正在成功地将 Rust 编译为 WebAssembly。然而，在 Rust 版本中，可能会生成一个具有完全不同函数签名的 WebAssembly 模块。函数参数从调用者传递到被调用者的方式（例如作为指向内存的指针或作为立即值）是应用程序二进制接口定义或简称“ABI”的一部分。`rustc` 默认使用 Rust 的 ABI，它不稳定，主要考虑 Rust 内部。

`rustc` 为了稳定这种情况，我们可以显式定义要为函数使用哪个 ABI 。这是通过使用 [`extern`](https://doc.rust-lang.org/reference/items/functions.html#extern-function-qualifier) 关键字来完成的。跨语言函数调用的一个长期选择是 [C ABI](https://github.com/WebAssembly/tool-conventions/blob/main/BasicCABI.md)，我们将在此处使用它。C ABI 不会改变，所以我们可以确定我们的 WebAssembly 模块接口也不会改变。

```rust
#[no_mangle]
pub fn add(left: usize, right: usize) -> usize {
pub extern "C" fn add(left: usize, right: usize) -> usize {
    left + right
}
```

我们甚至可以省略 `"C"` 而只使用 `extern`，因为 C ABI 是默认的替代 ABI。

### 导入

WebAssembly 的一个重要部分是它的沙箱。它确保在 WebAssembly VM 中运行的代码无法访问主机环境中的任何内容，除了通过 imports 对象显式传递到沙箱中的函数。

假设我们想在我们的 Rust 代码中生成随机数。我们可以引入 `rand` Rust 沙箱，但如果主机环境中已经有东西，为什么还要发布代码。作为第一步，我们需要声明我们的 WebAssembly 模块需要导入：

```rust
#[link(wasm_import_module = "Math")]
extern "C" {
    fn random() -> f64;
}

#[export_name = "add"]
pub fn add(left: f64, right: f64) -> f64 {
    left + right  
    left + right + unsafe { random() }
}
```

`extern "C"` 块（不要与上面的 `extern "C"` 函数混淆）声明编译器希望在链接时由“其他人”提供的函数。这通常是你在 Rust 中链接 C 库的方式，但该机制也适用于 WebAssembly。但是，外部函数总是隐式不安全的，因为编译器无法为非 Rust 函数提供任何安全保证。因此，除非我们将调用包装在 `unsafe { ... }` 块中，否则我们无法调用它们。

上面的代码可以编译，但不会运行。我们的 JavaScript 代码抛出错误，需要更新以满足我们指定的导入。导入对象是导入模块的字典，每个模块都是导入项的字典。在我们的 Rust 代码中，我们声明了一个导入模块"Math"，并期望一个被调用的函数"random"出现在该模块中。这些值当然是经过仔细选择的，这样我们就可以传入整个 Math 对象。

```javascript
  const importObj = {
    Math: {
      random: () => Math.random(),
    }
  };

  // or
  
  const importObj = { Math };
```

为了避免到处注入 `unsafe { ... }`，通常需要编写包装函数来恢复 Rust 的安全不变量。这是 Rust 内联模块的一个很好的用例：

```rust
mod math {
    mod math_js {
        #[link(wasm_import_module = "Math")]
        extern "C" {
            pub fn random() -> f64;
        }
    }

    pub fn random() -> f64 {
        unsafe { math_js::random() }
    }
}

#[export_name = "add"]
pub extern "C" fn add(left: f64, right: f64) -> f64 {
    left + right + math::random()
}
```

顺便说一句，如果我们没有指定 `#[link(wasm_import_module = ...)]`属性，则函数将在默认 `env` 模块上运行。此外，就像你可以使用 `#[export_name = "..."]` 更改导出的函数的名称一样，你可以使用 `#[link_name = "..."]` 更改导入的函数的名称。

### 高级类型

我之前说过，在模块边界处理函数的最有效方法是使用透明映射到 WebAssembly 支持的数据类型的值类型。 当然，编译器允许你使用更复杂的类型作为函数的参数和值。 在这些情况下，编译器生成 [C ABI](https://github.com/WebAssembly/tool-conventions/blob/main/BasicCABI.md) 中指定的代码（除了 rustc 目前不完全符合 C ABI 的[不足](https://github.com/rustwasm/team/issues/291)）。

无需赘述，类型大小（例如，struct、enum 等）就变成了一个简单的指针。 数组和元组是有大小的类型，如果它们使用少于 32 位，它们将被转换为立即值。 更复杂的情况是函数返回大于 32 位的数组类型的值：如果是这种情况，函数将不会收到返回值，而是会收到一个附加类型的参数 i32，该函数将利用指向此参数的指针来存储结果。 如果一个函数返回一个元组，无论元组的大小如何，它总是被认为是函数的参数。

`(?Sized)` 具有未指定类型的函数参数，例如 `str`、`[u8]` 或 `dyn MyTrait`，由两部分组成：第一部分是指向数据的指针，第二部分是指向元数据的指针。 如果是 str 的一个或一部分，则元数据是数据的长度。 在特征对象的实例中，它是一个虚拟表（或 vtable），它是指向各个特征函数实现的函数指针列表。 如果你想了解更多有关 Rust 中的 VTable 的信息，我可以推荐 Thomas Bächler 的[这篇文章](https://articles.bchlr.de/traits-dynamic-dispatch-upcasting)。

我在这里省略了重要的细节，因为建议你不要编写下一个 wasm-bindgen，除非你非要这样做。 我建议依靠现有工具而不是创建新工具。

## 模块大小

当 WebAssembly 部署在 web 上时，它的二进制文件的大小非常重要。 每一点都必须通过网络传输并通过浏览器的 WebAssembly 编译器，因此，较小的二进制大小意味着在 WebAssembly 开始运行之前用户等待的时间更少。 如果我们将默认项目构造为发布版本，我们将生成 1.7MB 的 WebAssembly。 这对于两个数字相加的功能似乎太大了。

> 数据部分：WebAssembly 模块的大部分由数据组成。 即数据在特定点保存在内存中，然后复制到线性内存。 这些部分的编译成本很低，因为编译器会跳过它们，在分析和减少模块的启动时间时请记住这一点。

检查 WebAssembly 模块内部结构的一种简单方法是 `llvm-objdump`，这应该可以在你的系统上访问。 或者，你可以使用 `wasm-objdump`，它是 wabt 的一部分，通常提供相同的接口。

```bash
$ llvm-objdump -h target/wasm32-unknown-unknown/release/my_project.wasm

target/wasm32-unknown-unknown/release/my_project.wasm: file format wasm

Sections:
Idx Name            Size     VMA      Type
  0 TYPE            00000007 00000000
  1 FUNCTION        00000002 00000000
  2 TABLE           00000005 00000000
  3 MEMORY          00000003 00000000
  4 GLOBAL          00000019 00000000
  5 EXPORT          0000002b 00000000
  6 CODE            00000009 00000000 TEXT
  7 .debug_info     00062c72 00000000
  8 .debug_pubtypes 00000144 00000000
  9 .debug_ranges   0002af80 00000000
 10 .debug_abbrev   00001055 00000000
 11 .debug_line     00045d24 00000000
 12 .debug_str      0009f40c 00000000
 13 .debug_pubnames 0003e3f2 00000000
 14 name            0000001c 00000000
 15 producers       00000043 00000000
```

`llvm-objdump` 过于笼统，为那些有使用其他语言汇编经验的人提供熟悉的命令行。 然而，专门用于调试二进制字符串的大小，它缺少简单的工具，如按大小排序部分或按功能分解部分。 幸运的是，有专门为此设计的 WebAssembly 专用工具 [Twiggy](https://rustwasm.github.io/twiggy/)：

```bash
$ twiggy top target/wasm32-unknown-unknown/release/my_project.wasm
 Shallow Bytes │ Shallow % │ Item
───────────────┼───────────┼─────────────────────────────────────────
        652300 ┊    36.67% ┊ custom section '.debug_str'
        404594 ┊    22.75% ┊ custom section '.debug_info'
        285988 ┊    16.08% ┊ custom section '.debug_line'
        254962 ┊    14.33% ┊ custom section '.debug_pubnames'
        176000 ┊     9.89% ┊ custom section '.debug_ranges'
          4181 ┊     0.24% ┊ custom section '.debug_abbrev'
           324 ┊     0.02% ┊ custom section '.debug_pubtypes'
            67 ┊     0.00% ┊ custom section 'producers'
            25 ┊     0.00% ┊ custom section 'name' headers
            20 ┊     0.00% ┊ custom section '.debug_pubnames' headers
            19 ┊     0.00% ┊ custom section '.debug_pubtypes' headers
            18 ┊     0.00% ┊ custom section '.debug_ranges' headers
            17 ┊     0.00% ┊ custom section '.debug_abbrev' headers
            16 ┊     0.00% ┊ custom section '.debug_info' headers
            16 ┊     0.00% ┊ custom section '.debug_line' headers
            15 ┊     0.00% ┊ custom section '.debug_str' headers
            14 ┊     0.00% ┊ export "__heap_base"
            13 ┊     0.00% ┊ export "__data_end"
            12 ┊     0.00% ┊ custom section 'producers' headers
             9 ┊     0.00% ┊ export "memory"
             9 ┊     0.00% ┊ add
...
```

现在很明显，模块大小的所有主要贡献者都是与模块用途无关的自定义组件。 它们的标题暗示它们包含用于故障排除的信息，因此这些部分是为构建和发布而发出的这一事实有些不合常规。 这似乎与我们代码的一个长期存在的问题有关，该问题导致它在编译时没有调试符号，但在我们的机器上预编译的标准库仍然有调试符号。

为了解决这个问题，我们在 `Cargo.toml` 中添加了：

```toml
[profile.release]
strip = true
```

这将导致 `rustc` 删除所有自定义部分，包括为函数分配名称的部分。 这可能不是我们想要的，因为 twiggy 的输出将只包含 `saycode[0]` 或类似的函数。 如果你想维护函数名称，我们可以使用特定的模式来删除信息：

```toml
[profile.release]
strip = true
strip = "debuginfo"
```

如果你想完全细粒度控制，你可以恢复并完全禁用 `rustc` 的 strip 方法，而是使用 `llvm-strip` 或 `wasm-strip`。 这使你能够决定应保留哪些自定义部件。

```bash
llvm-strip --keep-section=name target/wasm32-unknown-unknown/release/my_project.wasm
```

移除外层后，我们剩下一个与 116B 一样大或大于 116B 的块。 拆解它会发现该模块的唯一目的是调用 add 并执行 `(f64.add (local.get 0) (local.get 1))`，这意味着 Rust 编译器能够生成最佳代码。 当然，代码库的大小增加了，这使得掌握二进制大小变得更加困难。

### 自定义部分

> 有趣的事实：我们可以使用 Rust 将我们的自定义部分添加到 WebAssembly 模块中。 如果我们声明一个字节数组（不是切片！），我们可以添加一个 `#[link_section=...]` 属性来将这些字节打包到它自己的部分中。

```rust
const _: () = {
    #[link_section = "surmsection"]
    static SECTION_CONTENT: [u8; 11] = *b"hello world";
};
```

我们可以使用 [`WebAssembly.Module.customSection()` AP](https://developer.mozilla.org/en-US/docs/WebAssembly/JavaScript_interface/Module/customSections)I 或使用 `llvm-objdump` 提取这些数据：

```bash
$ llvm-objdump -s -j surmsection target/wasm32-unknown-unknown/release/my_project.wasm

target/wasm32-unknown-unknown/release/my_project.wasm: file format wasm
Contents of section surmsection:
 0000 68656c6c 6f20776f 726c64             hello world
```

### 偷偷摸摸的膨胀

我在网上看到一些关于 Rust 为看似很小的工作创建 WebAssembly 模块的抱怨。 根据我的经验，Rust 创建的 WebAssembly 二进制文件可能很大的原因有以下三个：

- 调试构建（即忘记将 `--release` 传递给 Cargo）
- 调试符号（即忘记运行 `llvm-strip`）
- 意外的字符串格式和恐慌

我们已经看到了前两个。 让我们仔细看看最后一个。 这个无害的程序编译成 18KB 的 WebAssembly：

```rust
static PRIMES: &[i32] = &[2, 3, 5, 7, 11, 13, 17, 19, 23];

#[no_mangle]
extern "C" fn nth_prime(n: usize) -> i32 {
    PRIMES[n]
}
```

好吧，也许它毕竟不是那么无害。 你可能已经知道我要干嘛了。

### 恐慌

快速浏览一下 twiggy 就会发现，影响 Wasm 模块大小的主要因素是与字符串格式化、恐慌和内存分配相关的函数。 这说得通！ 参数 n 未清理并用于索引数组。 Rust 别无选择，只能注入边界检查。 如果边界检查失败，Rust 会崩溃，这是创建格式正确的错误消息和堆栈跟踪所必需的。

解决这个问题的一种方法是自己进行边界检查。 Rust 的编译器非常擅长仅在需要时注入检查。

```rust
fn nth_prime(n: usize) -> i32 {
    if n < 0 || n >= PRIMES.len() { return -1; }
    PRIMES[n]
}
```

可以说更惯用的方法是依靠`Option<T>`API 来控制错误情况的处理方式：

```rust
fn nth_prime(n: usize) -> i32 {
    PRIMES[n]
    PRIMES.get(n).copied().unwrap_or(-1)
}
```

第三种方法是使用 `unchecked` Rust 明确提供的一些方法。 这些为未定义的行为打开了大门，因此是 `unsafe`，但如果你能够承担起安全的重担，性能（或文件大小）的提高将是显着的！

```rust
fn nth_prime(n: usize) -> i32 {
    PRIMES[n]
    unsafe { *PRIMES.get_unchecked(n) }
}
```

我们可以尝试处理恐慌可能发生的位置，并尝试手动处理这些路径。 然而，一旦我们开始依赖第三方 crate，成功的机会就会减少，因为我们无法轻易改变库内部处理错误的方式。

### LTO

我们可能不得不接受这样一个事实，即我们无法避免代码库中出现 panic 的代码路径。 虽然我们可以尝试减轻恐慌的影响（我们会的！），但有一个相当强大的优化通常可以节省一些重要的代码。 这个优化过程由 LLVM 提供，称为 [LTO（Link Time Optimization，链接时优化）](https://llvm.org/docs/LinkTimeOptimization.html)。 `rustc` 在将所有内容链接到最终二进制文件之前编译和优化每个 crate。 然而，一些优化只有在链接后才会变得明显。 例如，许多函数根据输入有不同的分支。 在编译期间，你只会看到来自同一个 crate 的函数调用。 在链接时，你知道对任何给定函数的所有可能调用，这意味着现在可以消除其中一些代码分支。

LTO 默认处于关闭状态，因为它是一项代价高昂的优化，会显着减慢编译时间，尤其是在较大的 crate 中。  你可以通过在 Cargo.toml 中配置 `rustc` 的许多代码生成选项启用。 具体来说，我们需要将这一行添加到我们的 `Cargo.toml` 中以在发布版本中启用 LTO：

```toml
[package]
name = "my_project"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[profile.release]
lto = true
```

启用 LTO 后，剥离的二进制文件减少到 2.3K，这令人印象深刻。 LTO 的唯一成本是更长的链接时间，但如果二进制大小是一个问题，LTO 将成为一项利器，因为它“仅”花费构建时间并且不需要更改代码。

### wasm-opt

另一个几乎应该成为构建管道一部分的工具是来自 [binaryen](https://github.com/WebAssembly/binaryen) 的 `wasm-opt`。 它是另一个优化过程的集合，完全在 WebAssembly VM 指令上工作，独立于生成它们的源语言。 像 Rust 这样的高级语言有更多的信息可以用来应用更复杂的优化，所以 `wasm-opt` 不能替代你的语言编译器的优化。 但是，它通常设法将模块大小减少几个额外的字节。

```bash
wasm-opt -O3 -o output.wasm target/wasm32-unknown-unknown/my_project.wasm
```

在我们的例子中，`wasm-opt` 进一步缩小了 Rust 的 2.3K WebAssembly 二进制文件，最后是 2.0K。 好的！ 但别担心，我不会就此打住。 这对于数组中的查找来说仍然太大了。

## 非标准

Rust 有一个[标准库](https://docs.rs/std)，其中包含你每天进行系统编程时所需的许多抽象和实用程序：访问文件、获取当前时间或打开网络套接字。 一切都在那里供你使用，无需去 [crates.io](https://crates.io/) 或类似网站上搜索。 然而，许多数据结构和函数对它们的使用环境做出了假设：它们假设硬件的细节被抽象成一个统一的 API，并且它们假设它们可以以某种方式分配（和释放）任意大小的内存块。 通常，这两项工作都是由操作系统完成的，我们大多数人每天都在操作系统上工作。

但是，当你通过原始 API 实例化 WebAssembly 模块时，情况就不同了：沙箱（WebAssembly 的定义安全功能之一）将 WebAssembly 代码与主机隔离开来，从而与操作系统隔离开来。 你的代码只能访问一大块线性内存，它甚至无法弄清楚哪些部分正在使用，哪些部分可以使用。

> WASI：这不是本文的一部分，但就像 WebAssembly 是对运行代码的处理器的抽象一样，[WASI](https://wasi.dev/)（WebAssembly 系统接口）旨在成为对运行代码的操作系统的抽象，并为你提供可以使用单一、统一的 API。 Rust 支持 WASI，尽管 WASI 本身仍在发展中。

这意味着 Rust 给了我们一种虚假的安全感！ 它为我们提供了一个没有操作系统支持的完整标准库。 事实上，许多 stdlib 模块只是别名或者失败了。 也就是说，它们在没有操作系统支持的情况下不能正常工作。在没有操作系统支持的情况下，许多返回 `Result <T>` 类型的函数可能会因为无法正常工作而始终返回 Err，这意味着无法得到正确的操作结果。同样，其他一些函数可能会因为无法正常工作而导致程序崩溃。

### 向无操作系统设备学习

只是一个线性内存块。 没有管理内存或外围设备的中央实体。 只是算术。 如果你曾经使用过嵌入式系统，这听起来可能很熟悉。 虽然现代嵌入式系统运行 Linux，但较小的微处理器没有资源来这样做。 [Rust 还针对那些超受限环境](https://www.rust-lang.org/what/embedded)，[Embedded Rust Book](https://docs.rust-embedded.org/book/) 和 [Embedomicon](https://docs.rust-embedded.org/embedonomicon/) 解释了如何为这些环境正确编写 Rust。

要进入裸机世界🤘，我们必须在代码中添加一行：`#![no_std]`。 这个 crate 宏告诉 Rust 不要链接到标准库。 相反，它只链接到 [core](https://docs.rs/core)。 Embedonomicon 非常简洁地[解释](https://docs.rust-embedded.org/embedonomicon/smallest-no-std.html#what-does-no_std-mean)了这意味着什么：

>`core` crate 是 `std` crate 的子集，它对程序将在其上运行的系统做出零假设。 因此，它为语言原语（如浮点数、字符串和切片）提供 API，以及公开处理器功能（如原子操作和 SIMD 指令）的 API。 但是，它缺少任何处理堆内存分配和 I/O 的 API。
>
>对于应用程序，std 不仅仅是提供一种访问操作系统抽象的方法。 std 还负责设置堆栈溢出保护、处理命令行参数以及在调用程序的主函数之前生成主线程。 `#![no_std]` 应用程序缺少所有标准运行时，因此如果需要它必须初始化自己的运行时。

这听起来有点可怕，但让我们一步一步来。 我们首先将上面的 panic-y 素数程序声明为 `no_std`：

```rust
#![no_std]
static PRIMES: &[i32] = &[2, 3, 5, 7, 11, 13, 17, 19, 23];

#[no_mangle]
extern "C" fn nth_prime(n: usize) -> i32 {
    PRIMES[n]
}
```

很遗憾，Embedonomicon 段落预示了这一点。因为我们没有提供核心依赖项的一些基础知识。 在列表的最顶部，我们需要定义在这种环境中发生恐慌时应该发生什么。 这是由恰当命名的恐慌处理程序完成的，Embedonomicon 给出了一个例子：

```rust
#[panic_handler]
fn panic(_panic: &core::panic::PanicInfo<'_>) -> ! {
    loop {}
}
```


这对于嵌入式系统来说是非常典型的，有效地阻止了处理器在崩溃发生后进行任何进一步的处理。 然而，这在 web 上不是好的行为，所以对于 WebAssembly，我通常选择手动发出无法访问的指令来阻止任何 Wasm VM 运行：

```rust
#[panic_handler]
fn panic(_panic: &core::panic::PanicInfo<'_>) -> ! {
    loop {}
    core::arch::wasm32::unreachable()
}
```

有了这个，我们的程序再次编译。 剥离和 `wasm-opt` 后，二进制文件大小为 168B。 极简主义再次获胜！

## 内存管理

当然，我们因非标准而放弃了很多。 没有堆分配，就没有 `Box`，没有 `Vec`，没有 `String` 和许多其他有用的东西。 幸运的是，我们可以在不放弃整个操作系统的情况下取回这些东西。

`std` 提供的很多东西实际上只是来自 `core` 的另一个称为 `alloc` 的东西。 `alloc` 包含有关内存分配和依赖于它的数据结构的所有内容。 通过导入它，我们可以重新获得我们信任的 `Vec`。

```rust
#![no_std]
// One of the few occastions where we have to use `extern crate`
// even in Rust Edition 2021.
extern crate alloc;
use alloc::vec::Vec;

#[no_mangle]
extern "C" fn nth_prime(n: usize) -> usize {
    // Please enjoy this horrible implementation of
    // The Sieve of Eratosthenes.
    let mut primes: Vec<usize> = Vec::new();
    let mut current = 2;
    while primes.len() < n {
        if !primes.iter().any(|prime| current % prime == 0) {
            primes.push(current);
        }
        current += 1;
    }
    primes.into_iter().last().unwrap_or(0)
}

#[panic_handler]
fn panic(_panic: &core::panic::PanicInfo<'_>) -> ! {
    core::arch::wasm32::unreachable()
}
```

当然，尝试编译它会失败——我们实际上并没有告诉 Rust 我们的内存管理是什么样的，Vec 需要知道它才能运行。

```bash
$ cargo build --target=wasm32-unknown-unknown --release
error: no global memory allocator found but one is required; 
  link to std or add `#[global_allocator]` to a static item that implements 
  the GlobalAlloc trait

error: `#[alloc_error_handler]` function required, but not found

note: use `#![feature(default_alloc_error_handler)]` for a default error handler
```

在撰写本文时，在 Rust 1.67 中，你需要提供一个在分配失败时调用的错误处理程序。 在下一个版本中，Rust 1.68 `default_alloc_error_handler` 已经稳定下来，这意味着每个非标准的 Rust 程序都将带有这个错误处理程序的默认实现。 如果你仍想提供自己的错误处理程序，你可以：

```rust
#[alloc_error_handler]
fn alloc_error(_: core::alloc::Layout) -> ! {
    core::arch::wasm32::unreachable()
}
```

有了这个复杂的错误处理程序，我们最终应该提供一种方法来进行实际的内存分配。 就像我在 [C 到 WebAssembly](https://surma.dev/things/c-to-webassembly) 的文章中一样，我的自定义分配器将是一个最小的 bump 分配器，它往往又快又小，但不会释放内存。 我们静态分配一个 arena 作为我们的堆，并跟踪“空闲区域”的开始位置。 由于我们不使用 Wasm 线程，因此我也会忽略线程安全。

```rust
use core::cell::UnsafeCell;

const ARENA_SIZE: usize = 128 * 1024;
#[repr(C, align(32))]
struct SimpleAllocator {
    arena: UnsafeCell<[u8; ARENA_SIZE]>,
    head: UnsafeCell<usize>,
}

impl SimpleAllocator {
    const fn new() -> Self {
        SimpleAllocator {
            arena: UnsafeCell::new([0; ARENA_SIZE]),
            head: UnsafeCell::new(0),
        }
    }
}

unsafe impl Sync for SimpleAllocator {}

#[global_allocator]
static ALLOCATOR: SimpleAllocator = SimpleAllocator::new();
```

将 `#[global_allocator]` 全局变量标记为管理堆的实体。 此变量的类型必须实现 GlobalAlloc 特性。 特性上的 GlobalAlloc 方法都使用 &self，所以如果你想修改数据类型中的任何值，你必须使用内部可变性。 我这里选择了UnsafeCell。 使用 UnsafeCell 使我们的结构隐式 !Sync，Rust 不允许全局静态变量。 这就是为什么我们还必须手动实现 Synctrait 来告诉 Rust 我们知道我们有责任使这种数据类型成为线程安全的（而我们完全忽略了这一点）。

该结构被标记为 `#[repr(C)]` 的原因很简单，以便我们可以手动指定对齐方式。 这样我们就可以确保即使是 arena 中的第一个字节（以及我们返回的第一个指针的扩展）也具有 32 位对齐，这应该可以满足大多数数据结构。

现在为特征的 GlobalAlloc 的实际实现：

```rust
unsafe impl GlobalAlloc for SimpleAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        let size = layout.size();
        let align = layout.align();

        // Find the next address that has the right alignment.
        let idx = (*self.head.get()).next_multiple_of(align);
        // Bump the head to the next free byte
        *self.head.get() = idx + size;
        let arena: &mut [u8; ARENA_SIZE] = &mut (*self.arena.get());
        // If we ran out of arena space, we return a null pointer, which
        // signals a failed allocation.
        match arena.get_mut(idx) {
            Some(item) => item as *mut u8,
            _ => core::ptr::null_mut(),
        }
    }

    unsafe fn dealloc(&self, _ptr: *mut u8, _layout: Layout) {
        /* lol */
    }
}
```

 `#[global_allocator]` 不仅仅是 `#[no_std]`！你还可以使用它来覆盖 Rust 的默认分配器并将其替换为你自己的分配器，因为 Rust 的默认分配器消耗大约 10K Wasm 空间。

### wee_alloc

当然，你不必自己实现分配器。 事实上，依靠经过良好测试的实施可能是明智的。 处理分配器中的错误和微妙的内存损坏并不好玩。

许多指南推荐 `wee_alloc`，这是一个非常小的 (<1KB) 分配器，由 Rust WebAssembly 团队编写，也可以释放内存。 可悲的是，它似乎没有得到维护，并且有一个[关于内存损坏和内存泄漏的未解决问题](https://github.com/rustwasm/wee_alloc/issues/105)。

在任何相当复杂的 WebAssembly 模块中，Rust 的默认分配器消耗的 10KB 只是整个模块大小的一小部分，所以我建议坚持使用它并知道分配器经过良好测试和性能。

## wasm-bindgen

现在我们已经完成了几乎所有困难的事情，我们已经看到了使用 [wasm-bindgen](https://rustwasm.github.io/wasm-bindgen/) 为 WebAssembly 编写 Rust 的便捷方法。

wasm-bindgen 的关键特性是 `#[wasm_bindgen]` 宏，我们可以将它放在我们想要导出的每个函数上。 这个宏添加了我们在本文前面手动添加的相同编译器指令，但它还做了一些更有用的事情。

例如，如果我们将上面的宏添加到我们的 `add` 函数中，它会发出另一个以[数字格式](https://github.com/rustwasm/wasm-bindgen/blob/main/crates/cli-support/src/descriptor.rs)返回我们的函数 `__wbindgen_describe_add` 的描述。 具体来说，我们函数的描述符如下所示：

```rust
Function(
    Function {
        arguments: [
            U32,
            U32,
        ],
        shim_idx: 0,
        ret: U32,
        inner_ret: Some(
            U32,
        ),
    },
)
```


这是一个非常简单的函数，但是 wasm-bindgen 中的描述符能够表示非常复杂的函数签名。

 > **展开:** 如果你想查看宏发出的代码 `#[wasm_bindgen]`，请使用 rust-analyzer 的“递归扩展宏”功能。 你可以通过命令面板在 VS Code 运行它。

这些描述符有什么用？ wasm-bindgen 不仅提供了一个宏，它还附带了一个 CLI，我们可以使用它来对我们的 Wasm 二进制文件进行后处理。  CLI 提取这些描述符并使用此信息生成自定义 JavaScript 绑定（然后删除所有不再需要的描述符函数）。 生成的 JavaScript 具有处理更高级别类型的所有例程，允许你无缝传递类型，例如字符串、`ArrayBuffer` 甚至闭包。

如果你想为 WebAssembly 编写 Rust，我推荐 wasm-bindgen。wasm-bindgen 不适用于 `#![no_std]`，但实际上这很少成为问题。

## wasm-pack

我还想提一下 [wasm-pack](https://rustwasm.github.io/wasm-pack/)，这是另一个用于 WebAssembly 的 Rust 工具。我们使用全套工具来编译和处理我们的 WebAssembly 以优化最终结果。`wasm-pack` 是一种对大多数这些过程进行编码的工具。它可以使用针对 WebAssembly 优化的所有设置引导一个新的 Rust 项目。它构建项目并使用所有正确的标志调用 `cargo`，然后它调用 `wasm-bindgen` CLI 来生成绑定，最后它运行 `wasm-opt` 以确保我们不会留下任何性能问题。`wasm-pack` 还能够准备你的 WebAssembly 模块以发布到 npm，但我个人从未使用过该功能。

## 总结

Rust 是一种用于 WebAssembly 的优秀语言。启用 LTO 后，你将获得非常小的模块。Rust 的 WebAssembly 工具非常出色，自从我第一次在 [Squoosh](https://squoosh.app/) 中使用它以来，它变得更好了。发出的胶水代码 `wasm-bindgen` 既现代又 tree-shaken。看到它在幕后是如何工作的，我从中获得了很多乐趣，它帮助我理解和欣赏所有工具为我所做的事情。我希望你也有同感。非常感谢 [Ingrid](https://twitter.com/opinionatedpie)、[Ingvar](https://twitter.com/rreverser) 和 [Saul](https://twitter.com/saulecabrera/) 审阅这篇文章。
