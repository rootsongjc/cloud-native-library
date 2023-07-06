---
linktitle: 第 12 章：扩展 WebAssembly 平台
summary: "这篇文章是《WebAssembly 权威指南》一书的第十二章，介绍了如何扩展 WebAssembly 平台的能力，使其能够访问宿主环境的资源和服务。文章讲解了 WebAssembly 的模块化设计和接口类型的概念，以及如何使用 WebAssembly Interface Types（WIT）和 WebAssembly System Interface（WASI）来实现跨语言和跨平台的互操作。文章还展示了如何使用 WasmEdge 和 Rust 来编写一个简单的 WebAssembly 应用。"
weight: 13
icon: book-reader
icon_pack: fas
draft: false
title: 扩展 WebAssembly 平台
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

> 译者注：这是《WebAssembly 权威指南》一书的第十二章，介绍了如何扩展 WebAssembly 平台的能力，使其能够访问宿主环境的资源和服务。文章讲解了 WebAssembly 的模块化设计和接口类型的概念，以及如何使用 WebAssembly Interface Types（WIT）和 WebAssembly System Interface（WASI）来实现跨语言和跨平台的互操作。文章还展示了如何使用 WasmEdge 和 Rust 来编写一个简单的 WebAssembly 应用。

WebAssembly 的 [MVP](https://github.com/WebAssembly/design) 定义奠定了基础，但从未打算作为一个全面的解决方案。它主要侧重于不需要复杂线程、垃圾收集和异常处理的语言特性和运行时。还有一些其他的限制，我们在书中也看到了。虽然人们已经找到解决这些缺点的方法，但 MVP 并不是结束，而只是开始。

WebAssembly 平台的设计者对他们的决定采取了外科手术的方法。虽然从外面看起来可能很混乱，但内部有一个一致性，考虑到一些更大的和长期的目标。这些决定的许多动机都与规范本身一起记录在案。设计师没有将所有遗漏问题的解决方案塞进下一个大版本中，而是创建了一系列独立跟踪的后续提案。其中一些提案是相互依存的，因此它们的提交和通过是有顺序的。

由于后 MVP 世界已经以这种方式发展，跟踪哪些功能在哪个版本中可用变得有点棘手。我希望有工具和库来解决这个问题，尽量减少开发人员的负担。设计中的一些复杂性并没有多大用处，所以我不想在上面花很多时间，但它在某种程度上具有指导意义，可以了解多值和引用类型等建议如何帮助更重的接口类型提案。

我们将这些扩展视为尚未完全支持但代表 WebAssembly 平台前进方向的后续功能的集合。我不会全面介绍这些建议，因为其中许多建议深奥或不成熟。需要注意的是，有多种尝试来改善以 WebAssembly 为目标的体验，使我们的代码更广泛可用、更安全、更快速和可移植。

## WASI 运行时

在[第 11 章](../wasi/)中，我们介绍了 WASI 的主要思想。它已成为向平台添加新功能的主要工具之一。有一个引入提案的扩展的过程（译者注：该过程已不再存在），然后在采用和标准化过程中经历一系列阶段。正如我们在上一章中指出的那样，并非每个运行时都会支持每个提案。即使在某些情况下支持某项提案，出于安全原因，在其他情况下也可能不支持。我们看到了 Wasmer 和 Wasmtime 引擎的一些基本命令行用法，但更有趣的是你将能够使用基于 WASI 的机制从你自己的应用程序执行任意功能。

这将使你能够安全地构建和部署插件机制、无服务器函数、热插拔替换、数据过滤器、零售促销、Kubernetes 节点、区块链引擎和可以用任何语言编写的扩展点。语言自由、性能和沙箱隔离的结合已经推动了许多项目和公司这样做。

Fastly 和 Cloudflare 等边缘计算公司允许客户在地理上分布微服务和无服务器函数，以在多租户环境中实现低延迟访问。Istio 和 Envoy 允许其用户通过基于 WebAssembly 的机制创建过滤器并支持新协议。SecondState 的 WasmEdge 环境，以及其他用途，针对区块链和软件定义的车辆。WasmCloud 正在提供基于参与者模型的分布式系统基础设施。甚至 [Microsoft Flight Simulator](https://docs.flightsimulator.com/html/Programming_Tools/WASM/WebAssembly.htm) 也从基于 DLL 的 WebAssembly 模块获取插件。我们将在[第 15 章](../applied-wasm-cloud-and-edge/) 中讨论其他一些项目。

现在，我将通过一些简单的模块向你展示使用 WebAssembly 和 WASI 的基础知识。在你适应了事件的概念和顺序后，我们将介绍一些由基于 WASI 的框架支持的新提案，并了解该平台如何发展以填补 MVP 的一些遗漏。

首先，创建一个 Rust 二进制项目：

```bash
brian@tweezer ~/g/w/s/ch12> cargo new --bin hello-wasi
	Created binary (application) `hello-wasi` package
brian@tweezer ~/g/w/s/ch12> cd hello-wasi
```

我们需要添加对 Wasmtime crate 的依赖，以便我们可以访问允许我们实例化模块和执行代码的运行时结构。编辑 `hello-wasi` 目录下的 `Cargo.toml` 文件，其内容如例 12-1 所示。请记住，在你阅读本文时版本号可能已经更改，但它应该仍然有效。

例 12-1. Cargo.toml 文件

```toml
[package]
name = "hello-wasi"
version = "0.1.0"
edition = "2018"
[dependencies]
wasmtime = "0.28.0"
```

我们将使用库的 Rust 版本，但对于 C 和 Python 等其他语言也有类似的结构。我们将在后续章节中查看 .NET 和 AssemblyScript 版本。甚至可以将命令行版本的 Wasmtime 与 bash 一起使用，如示例 12-3 所示。

例 12-2. 从 bash 中调用我们的函数

```bash
#!/bin/sh

function how_old() {
    local x=$(($1))
    local y=$(($2))
    local result=$(wasmtime hello.wat --invoke how_old $x $y 2>/dev/null)
    echo "$result"
}

for num in "2021 2000" "2021 1980" "2021 1960"; do
    set -- $num
    echo "how_old($1, $2) = $(how_old "$1" "$2")"
done
```

```bash
brian@tweezer-2 ~/g/w/s/c/hello-wasi> chmod ogu+rx hello.sh
brian@tweezer-2 ~/g/w/s/c/hello-wasi> ./hello.sh
how_old(2021, 2000) = 21
how_old(2021, 1980) = 41
how_old(2021, 1960) = 61
```

当我们使用来自支持的开发语言的库、类和结构时，我们可以更好地控制生命周期。首先，我们将调用[第 2 章](../hello-world/)中的年龄计算模块。

例 12-3. 年龄计算的 Wasm 模块

```c
(module
    (func $how_old (param $year_now i32) (param $year_born i32) (result i32)
        get_local $year_now
        get_local $year_born
        i32.sub)

    (export "how_old" (func $how_old))
)
```

现在我们将创建一个独立的 Rust 应用程序，它通过 Wasmtime 库调用行为。请记住，Wasmer、Wasm3 和其他环境也将有自己的策略，我们将在本书的其余部分演示其中的一些策略。我将带你了解详细信息，但请看一下示例 12-4。

例 12-4. Rust 中的最小 Wasmtime WASI 集成

```rust
use std::error::Error;
use wasmtime::*;

fn main() -> Result<(), Box<dyn Error>> {
    let engine = Engine::default();
    let mut store = Store::new(&engine, ());
    let module = Module::from_file(&engine, "hello.wat")?;
    let instance = Instance::new(&mut store, &module, &[])?;

    let how_old = instance.get_typed_func::<(i32,i32), (i32), _>(&mut store, "how_old")?;
    let age : i32 = how_old.call(&mut store, (2021i32, 2000i32))?;

    println!("You are {}", age);

    Ok(())
}
```

在为我们正在使用的各种函数导入前奏定义后，我们开始使用 Wasmtime 的 Rust 库定义的结构。有关这些类型的说明，请参见表 12-1。

表 12-1. Wasmtime 结构

| 名称     | 描述                                              |
| -------- | ------------------------------------------------- |
| Engine   | 用于配置值的全局环境，旨在跨线程共享。            |
| Store    | WebAssembly 对象的集合，包括实例、全局、内存和表。 |
| Module   | WebAssembly 模块的编译形式。                       |
| Instance | 编译后的模块的一个实例。                          |

引擎包含任何特殊的配置细节。与例 12-4 一样，我们只使用了默认配置。这用于创建 Store。这为 WebAssembly 函数提供了上下文，因此是一个隔离单元。在 Store 中创建的不同 WebAssembly 结构不能从其他 Store 实例共享或访问。在 Wasmtime API 的 Rust 版本中，对 Store 实例的可变引用被传递到函数中，这阻止了跨线程共享它们。

引擎然后用于初始化和编译模块实例。有多种机制可以检索底层字节，但出于我们的目的，我们只是从文件系统中读取 `.wat` 文件。请记住，我们在这里构建的是原生 Rust 应用程序，而不是 WASI 应用程序，因此它将被允许访问文件系统。

一旦模块被编译，我们就可以为它创建一个新的实例。在这种情况下，我们不提供任何导入对象，但稍后我们将看到一个从 Rust 宿主环境到模块共享函数的示例。从 Instance 中，我们能够检索对导出函数包装器的引用，以便可以像调用普通 Rust 函数一样调用它。我们使用类型安全的 `get_typed_func`，它在这里接受两个 i32 参数并返回一个 i32 结果。

最后，我们用值 `2021i32` 和 `2000i32` 调用我们的函数，它们代表数字 2021 和 2000 的 Rust 32 位整数类型字。结果存储在 Rust i32 变量中，然后打印到控制台。

我已经删除了下面不相关的构建输出，但我想证明它只是一个普通的 Rust cargo 构建命令，使用本机操作系统的后端来生成一个调用 WebAssembly 行为的应用程序。

```bash
brian@tweezer ~/g/w/s/c/hello-wasi> cargo build --release
	Finished release [optimized] target(s) in 3m 22s
brian@tweezer ~/g/w/s/c/hello-wasi> cargo run --release 
	Finished release [optimized] target(s) in 0.38s
		Running `target/release/hello-wasi`
You are 21
```

现在你已经了解了基础知识，我们再看看 Wasmtime 作为运行时支持的一些新提案。当你阅读本书时，可能会添加更多支持。在你的 WebAssembly 职业生涯的这个阶段，我认为你不需要了解提案本身的细节，尽管我会在相关的地方链接到它们。相反，我认为更重要的是让你看到 WebAssembly 平台如何发展的实际示例。因此，我将只关注 WASI 环境中可用的内容，但会在我们结束本章时介绍其他内容。

## 多值返回

MVP 为调用函数建立了一些相当基本的语义。尽管它们可以接受任意数量的参数，但函数只能产生一个结果。这在很多情况下显然都很好，但这将是一个过度限制。

考虑我们之前涉及字符串的一些示例。由于我们正在使用线性 Memory 实例分配字符串，因此我们需要引用字符串的基地址和字符串的长度。没有简单的方法来做到这一点，就像我们首先写字符串的长度然后写字符序列一样。

那些支持原语的语言呢，比如 Python 或 Rust？这允许开发人员轻松地将多个值打包到一个结构中以从函数返回，但来自另一种语言的客户端可能希望将它们解包或解构为不同的表示形式，以便更符合该语言的习惯。

即使像交换一对值或对数组排序这样简单的事情也会出现问题。它必须在线性内存块中就地完成。如果考虑模运算、进位等，一些算术函数也可以返回多个值。

除了函数返回值，MVP 的另一个限制是条件块和循环等指令序列不能消费值或返回多个结果。此外，交换值、进行溢出运算或在其中包含多值元组响应也会很有趣。

如果你还记得[第 2 章](../hello-world/)，WebAssembly 函数的结果位于堆栈的顶部。栈顶的几个元素当然也可以理解为多个返回值。因此，多值返回类型的扩展是重要的下一步，既可以改进平台，也可以促进其他扩展[^1]。至此，它已被合并到主要规范中，并在许多 WebAssembly 环境中实现。

该提案引入了新的指令，例如上述算术函数。这包括“i32.divmod”，它接受分子和除数，并返回商和余数。它还允许多个值保留在堆栈中，而不必复制到线性内存实例中。这既更快又更节省内存。
因为 Wasmtime 已经支持多值建议，所以我们可以很容易地证明它是多么有用。在例 12-5 中，你可以看到一个提供我们将使用的结构的 Wat 文件。第一行从 Rust 环境中导入一个函数，该函数接受两个参数并返回两个参数。如你所见，在语法上扩展结果以支持多个值并不是什么大问题。实现起来显然更复杂，但正如我提到的，结果来自堆栈的顶部。我们将调用我们的新函数 swap 因为这是我们将要传递的函数的作用。

例 12-5. 演示多值返回类型的简单 Wat 文件

```c
(module
   (func $swap (import "" "swap") (param i32 i32) (result i32 i32))

   (func $myfunc (export "myfunc") (param i32 i32) (result i32 i32)
      (call $swap (local.get 0) (local.get 1))
   )
)
```

它定义了一个名为 myfunc 的导出函数，它调用我们的交换函数。我们调用指令将这些值压入栈中，然后直接调用我们导入的函数。在我们的函数定义中，除了指明我们返回两个 i32 值作为结果外，我们不需要做任何特殊的事情。一旦交换返回，这些值应该位于堆栈的顶部。这些幕后细节是 Wasmtime 团队必须实现的，但对 Wat 语法的影响相当小。

在例 12-6 中，你可以看到将调用我们的 Wat 函数的主例程。该程序的大部分内容与你在例 12-4 中看到的非常相似。

例 12-6. 使用 Wasmtime Rust 库练习多值返回类型

```rust
use std::error::Error;
use wasmtime::*;

fn main() -> Result<(), Box<dyn Error>> {
    let engine = Engine::default();
    let mut store = Store::new(&engine, ());
    let module = Module::from_file(&engine, "mvr.wat")?;

    let callback_func = Func::wrap(&mut store, |a: i32, b: i32| -> (i32, i32) {
        (b, a)
    });

    let instance = Instance::new(&mut store, &module, &[callback_func.into()])?;

    let myfunc = instance.get_typed_func::<(i32,i32), (i32, i32), _>(&mut store, "myfunc")?;
    let (a, b) = myfunc.call(&mut store, (13, 43))?;

    println!("Swapping {} {} produces {} {}", 13, 43, a, b);

    Ok(())
}
```

我们通过调用 `Func::wrap` 来定义回调函数。这需要一个对我们的 Store 实例的可变引用和一个带有两个 i32 参数并返回两个 i32 参数的元组的 Rust 闭包。我们使用惯用的 Rust 来表达这个功能，这个闭包的实现非常微妙。我们只是返回一个元组，其中参数的顺序相反。

现在我们有了回调，注意我们在创建模块实例时将它传递给了导入上下文。在此之后，我们从 WebAssembly 模块导出的 myfunc 函数中获取一个包装器，并使用元组值调用它。这也是 Rust 的习惯用法，是传递两个参数的自然方式。这些参数将在幕后分解为我们的函数期望的两个参数。调用导出函数的结果被捕获为一个元组，然后我们对其进行解构并打印出结果。

```bash
brian@tweezer ~/g/w/s/c/hello-mvr> cargo build --release 
	Compiling hello-mvr v0.1.0
		(/Users/brian/git-personal/wasm_tdg/src/ch12/hello-mvr)
	Finished release [optimized] target(s) in 3.17s
brian@tweezer ~/g/w/s/c/hello-mvr> cargo run --release
	Finished release [optimized] target(s) in 0.22s
		Running `target/release/hello-mvr`
Swapping 13 and 43 produces 43 and 13.
```

## 引用类型

能够指定多个返回值是一些附加建议的先决条件。另一个有利的建议是能够指定对不透明句柄的引用。这对于增加垃圾收集、拥有类型化引用、使用异常处理等至关重要，但它也是让主机环境能够传递不透明的引用的关键，这些引用指的是我们不希望 WebAssembly 模块有原始访问权的资源。记住，我们正在谈论能够在任何操作系统上以任何语言传递对任意结构的引用。兼顾灵活性和性能并非易事。

我们过去可以进行引用，但仅限于函数，并且仅在表的实例中，一旦它们被创建我们就无法对其进行操作。这在一定程度上是为了不允许模块操纵内存中的敏感细节，或者无法更改哪个功能进入哪个槽位。请记住我们必须对函数引用进行间接调用，而不是更常见的对其他函数的直接调用。

这个新提案使我们能够操作 Table 成员，增加 Table 实例大小，并在 WebAssembly 模块及其宿主环境之间来回传递 externref 引用 [^2]。

Wasmtime 支持创建 externref 引用的能力，我们使用此 API 创建另一个示例应用程序。需要明确的是，任何 WASI 环境都必须支持这些基本提案，但我们的重点是 Wasmtime。

```bash
brian@tweezer ~/g/w/s/ch12> cargo new --bin hello-extref
	Created binary (application) `hello-extref` package
```

这是对我们的 Wat 文件语法的另一个相对简单的更改。快速查看示例 12-7 表明我们可以将 externref 元素存储在表中，或者将它们作为参数传递，或者将它们作为函数结果返回。以下是 Wasmtime 针对这些引用类型的示例的简化版本。我在这里不关注它们，但也可以对 externref 元素进行全局变量引用。

例 12-7. 带有 externref 参数、表元素和结果的 Wat 文件

```c
(module
  (table $table (export "table") 10 externref)

  (global $global (export "global") (mut externref) (ref.null extern))

  (func (export "func") (param externref) (result externref)
    local.get 0
  )
)
```

我们的模块导出一个包含 10 个引用空间的表。我们还有一个简单地返回其参数的函数。例 12-8 中的 Rust 代码比我们看到的其他示例复杂得多，因为我们包装了这些引用并根据需要提取包装的数据。尽管如此，我还是会引导你完成它，以便我们可以专注于新内容。

例 12-8. 使用 externref 元素的 Wasmtime Rust 应用程序

```rust
use std::error::Error;
use wasmtime::*;

fn main() -> Result<(), Box<dyn Error>> {
    let mut config = Config::new();
    config.wasm_reference_types(true);

    let engine = Engine::new(&config)?;
    let mut store = Store::new(&engine, ());
    let module = Module::from_file(&engine, "extref.wat")?;

    let instance = Instance::new(&mut store, &module, &[])?;

    let eref = ExternRef::new("secret key");
    let arr : [u8; 4] = [1, 2, 3, 4];

    let eref2 = ExternRef::new(arr);


    let table = instance.get_table(&mut store, "table").unwrap();
    table.set(&mut store, 3, Some(eref.clone()).into())?;
    table.set(&mut store, 4, Some(eref2.clone()).into())?;

    let ret = table.get(&mut store, 3)
        .unwrap()
        .unwrap_externref()
        .unwrap();

    let ret2 = table.get(&mut store, 4)
        .unwrap()
        .unwrap_externref()
        .unwrap();

    let str = *ret.data().downcast_ref::<&'static str>().unwrap();
    let arr2 = *ret2.data().downcast_ref::<[u8; 4]>().unwrap();

    println!("Retrieved external reference: {} from table slot {}", str, 3);
    println!("Retrieved external reference: {:?} from table slot {}", arr2, 4);

    let func = instance.get_typed_func::<Option<ExternRef>, Option<ExternRef>, _>
        (&mut store, "func")?;

    let ret = func.call(&mut store, Some(eref.clone()))?;

    let str2 = *(ret.unwrap()).data().downcast_ref::<&'static str>().unwrap();

    println!("Received {} back from calling extern-ref aware function.", str2);

    Ok(())
}
```

你看到的第一件事是导入一个配置实例。我们之前一直在为我们的引擎实例使用默认配置，但我们需要打开对外部引用的支持，然后相应地配置我们的引擎。从那时起，从设置的角度来看，你应该很熟悉。

为了展示我们在引用方面的灵活性，我们从 Wasmtime 的 API 创建了两个 ExternRef 结构的实例。一个是不可伪造的不记名令牌，或者当模块进行共享函数调用时可以传回的东西。出于我们的目的，我只有一段字符串，上面写着“secret key”。另一个是对字节数组的引用。由于 ExternRef 结构是参数化类型，它可以包装这两种数据类型。

创建引用后，我们从模块中检索导出的表，并将引用的副本存储在槽位 3 和槽位 4 中。我们使用 Some 包装器，以便更容易判断引用是否存在。如果什么都不存在，我们可能会得到一个 None 实例。这是通过 Rust 中称为 [Option](https://doc.rust-lang.org/stable/std/option/) 的构造完成的。由于 Table 存储 externref 元素，因此模块无法检查详细信息。但是，当我们检索它们时，它们仍然代表我们放入其中的结构。根据静态类型和内存管理的细节，其他编程语言对这个程序会有不同的机制，但看起来基本相同。

提取引用看起来有点奇怪，但第一个 `unwrap()` 函数可以确定我们是否在 Table 实例的范围内进行了索引引用。然后它提取 externref 并验证它是该类型的实例（而不是其他引用类型）。最后，`unwrap()` 确保它不会产生空引用，这是该建议给 WebAssembly 平台带来的另一个补充。

接下来的步骤可能更奇怪，但我们正在对引用进行重复数据删除，提取数据，并将它们转换为我们期望的类型，在本例中，一个具有静态生命周期的字符串片段也称为字符串文字和一个四元素 u8 阵列。

假设这些都成功了，我们打印出我们从模块实例中拉回的元素值。

我们的最后一步是获取对模块导出函数的引用，该函数接受一个 Option-wrapped ExternRef 并返回一个 Option-wrapped ExternRef。回顾一下示例 12-7，我们的函数只是简单地返回它的参数。我们使用 ExternRef 的克隆副本调用我们的函数，捕获返回值，并通过相同的向下转换提取值。

现在一切都解释清楚了，我们可以像往常一样执行这个例子了。

```bash
brian@tweezer ~/g/w/s/c/hello-extref> cargo run --release 
	Finished release [optimized] target(s) in 0.36s
  	Running `target/release/hello-extref`
Retrieved external reference: secret key from table slot 3
Retrieved external reference: [1, 2, 3, 4] from table slot 4
Received secret key back from calling extern-ref aware function.
```

我承认这不是最令人兴奋的例子，但这个提案，就像多返回值提案一样，更多的是关于它能实现的东西，而不是你会使用它本身的东西。

## 模块链接

本章提出的最后一个提案是模块连接 [^3]。这个提案的范围相当大，最终是关于允许模块本身通过各种机制和风格被导入。

考虑 WASI 标准库的基本原理。我们希望有一个依赖模块来提供这种行为，而不需要一个一个地导入各个方法。如果每个函数调用都必须通过 javascript 包装器或类似的东西，这种方法会很脆弱、烦人，最终性能会很差。然而，我们确实喜欢虚拟实现的想法，这样可以通过在浏览器中使用本地存储来实现文件系统访问，而其他 API 可能表现良好（例如通过 `fd_write` 打印到 JavaScript 控制台）。我们还希望获得共享非结构化的好处，例如我们之前讨论的 Unix 管道和过滤器策略，而不会造成性能损失。我们还希望能够共享广泛使用的模块实例以节省内存。我们需要的是描述模块类型并允许不同的实现来满足这些类型的能力。

由于复杂的要求，这是一个复杂的提案。为了便于理解，我们将展示一个简单的示例，但它会对我们的 WebAssembly 系统中大型复杂模块依赖树的弹性和便利性产生巨大影响。甚至还有一种新的文本格式来描述这些基于 Wat 的接口。但是，它只允许接口定义，所以它有一个扩展名 `.wit` 来区分类型。

在例 12-9 中，我们看到了在模块连接提案中定义的示例模块。

例 12-9. 示例模块的 Wat 文件

```c
(module
  (memory (import "a") 1 2)
  (func (import "b") (param i32))
  (table (export "c") 1 funcref)
  (func $notImportedOrExported (result i64)
		i64.const 0 
  )
  (func (export "d") (result f32)
    f32.const 0 )
 )
```

在例 12-10 中，我们看到了相应的接口文件 (.wit)，它没有实现细节，但仍然根据模块导入和导出的元素定义了模块的“类型”。这最终将使我们能够更干净、灵活和高效地连接模块。

例 12-10. 同一模块的 Wit 文件

```c
(module
  (memory (import "a") 1 2)
  (func (import "b") (param i32))
  (table (export "c") 1 funcref)
  (func (export "d") (result f32))
)
```

为了方便起见，我将只展示模块连接的示例，这些示例取自 [Wasmtime 示例](https://github.com/bytecodealliance/wasmtime/tree/main/examples)。我们有两个模块，一个依赖于另一个，一个使用 WASI 功能写入控制台。

例 12-11 中的 `Cargo.toml` 文件比我们目前看到的更多一些依赖。然而，最重要的是 `wasmime-wasi` 依赖。这是标准 WASI 函数的实现，我们在下面的示例中链接到它。

例 12-11. 为我们的模块链接示例编写的 Cargo.toml 文件

```toml
[package]
name = "hello-modlink"
version = "0.1.0"
edition = "2018"

[dependencies]
wasmtime = "0.28.0"
wasmtime-wasi = "0.28.0"
anyhow = "1.0.19"
```

在例 12-12 的第一个模块中，我们导入了一个名为 double 的函数，它接受一个 i32，将它加倍，然后返回一个 i32。我们还导入了一个名为 log 的函数，它将在内存中以给定的偏移量和给定的长度打印一个字符串。我们还将导入一个要使用的 Memory 实例和一个表示偏移量的全局变量，作为我们活动的位置。

我们导出的 run 函数将常量 2 加载到堆栈上，然后调用 double 函数。请记住，堆栈的顶部将包含参数，因此我们希望它产生值 4。我们没有对输出做任何事情，但它起作用了。关键是，我们对导入函数的调用确实有效。

将值加倍后，我们调用日志函数打印出“Hello, World!”请注意，我们将字符串和数据元素写入内存中由全局变量指定的位置。

例 12-12.  我们要链接的模块依赖于另一个模块

```c
(module
  (import "linking2" "double" (func $double (param i32) (result i32)))
  (import "linking2" "log" (func $log (param i32 i32)))
  (import "linking2" "memory" (memory 1))
  (import "linking2" "memory_offset" (global $offset i32))

  (func (export "run")
    ;; Call into the other module to double our number, and we could print it
    ;; here but for now we just drop it
    i32.const 2
    call $double
    drop

    ;; Our `data` segment initialized our imported memory, so let's print the
    ;; string there now.
    global.get $offset
    i32.const 14
    call $log
  )

  (data (global.get $offset) "Hello, world!\n")
)
```

第二个模块如例 12-13 所示。它为接受四个 i32 参数并返回 i32 的函数定义了一个类型。此类型将对应于我们将从 WASI 命名空间`wasi_snapshot_preview1` 导入的 `fd_write` 方法。正如我们在[第 11 章](../wasi/) 中看到的，这个方法接受文件描述的参数，字符串向量从哪里开始，有多少个，以及它应该写入单词的表示 Where to write 节号的返回值。

还有一个名为 double 的简单函数，它会将传入的 i32 参数加载到堆栈中，跟在常量 2 之后，然后调用 `i32.mul` 指令，从堆栈中弹出顶部的两个值，比较它们相乘，并将结果写回栈顶。

我们导出的日志记录函数在设置详细信息后调用导入的“fd_write”。请注意，许多模块可能会导入 fd_write 函数，但这里我们有一个隐藏了大部分细节的可重用函数。其他模块可以导入我们的函数定义并传入内存指针和长度来达到相同的结果。

最后，我们的模块输出一个 Memory 实例和一个全局变量，表示要写入值的当前偏移量。这是一种（可能很脆弱的）方法，它允许使用的内存由该模块管理，同时允许其他模块写入未使用的空间。

例 12-13. 第一个模块依赖的第二个模块

```c
(module
  (type $fd_write_ty (func (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (type $fd_write_ty)))

  (func (export "double") (param i32) (result i32)
    local.get 0
    i32.const 2
    i32.mul
  )

  (func (export "log") (param i32 i32)
    ;; store the pointer in the first iovec field
    i32.const 4
    local.get 0
    i32.store

    ;; store the length in the first iovec field
    i32.const 4
    local.get 1
    i32.store offset=4

    ;; call the `fd_write` import
    i32.const 1     ;; stdout fd
    i32.const 4     ;; iovs start
    i32.const 1     ;; number of iovs
    i32.const 0     ;; where to write nwritten bytes
    call $fd_write
    drop
  )

  (memory (export "memory") 2)
  (global (export "memory_offset") i32 (i32.const 65536))
)
```

例 12-14 中的 Rust 代码引入了 Wasmtime API 的一些附加功能。首先是链接器的概念。这是一种工具，可帮助根据模块的导入和导出配置将模块连接在一起。由于 WASI 的功能被广泛使用，它可以作为一个单独的依赖项使用，如例 12-11 所示。将此模块的详细信息添加到链接器，以便它们可以链接到依赖此行为的模块中。

之后，实例化我们的两个模块，配置 WASI 实例，并将详细信息添加到 Store，以便它们在运行时在上下文中可用。

我们在链接器实例中注册了第二个模块，因为我们想让它对我们的第一个模块可用。请记住，这里的整个想法是关于平衡重用、可交换性、性能、隔离和其他要求。

例 12-14. 我们要链接的模块依赖于另一个模块

```rust
use anyhow::Result;
use wasmtime::*;
use wasmtime_wasi::sync::WasiCtxBuilder;

fn main() -> Result<()> {
    let engine = Engine::default();

    // First set up our linker which is going to be linking modules together. We
    // want our linker to have wasi available, so we set that up here as well.
    let mut linker = Linker::new(&engine);
    wasmtime_wasi::add_to_linker(&mut linker, |s| s)?;

    // Load and compile our two modules
    let linking1 = Module::from_file(&engine, "linking1.wat")?;
    let linking2 = Module::from_file(&engine, "linking2.wat")?;

    // Configure WASI and insert it into a `Store`
    let wasi = WasiCtxBuilder::new()
        .inherit_stdio()
        .inherit_args()?
        .build();
    let mut store = Store::new(&engine, wasi);

    // Instantiate our first module which only uses WASI, then register that
    // instance with the linker since the next linking will use it.
    let linking2 = linker.instantiate(&mut store, &linking2)?;
    linker.instance(&mut store, "linking2", linking2)?;

    // And with that we can perform the final link and the execute the module.
    let linking1 = linker.instantiate(&mut store, &linking1)?;
    let run = linking1.get_typed_func::<(), (), _>(&mut store, "run")?;
    run.call(&mut store, ())?;
    Ok(())
}
```

最后，我们将第一个模块链接到第二个模块，获取运行函数，并调用它。

```bash
brian@tweezer ~/g/w/s/c/hello-modlink> cargo run --release
	Compiling hello-modlink v0.1.0
		(/Users/brian/git-personal/wasm_tdg/src/ch12/hello-modlink)
  Finished release [optimized] target(s) in 21.49s
  	Running `target/release/hello-modlink`
Hello, world!
```

## 功能测试

关于功能测试的提案有很多。建议使用来自 Google 的名为 [wasm-feature-detect](https://github.com/GoogleChromeLabs/wasm-feature-detect) 的库。这不仅仅是一个聪明的名字。这就是它的作用。

它相当简单，并且可以通过插件测试轻松扩展。他们征求开发人员的意见，他们希望为他们尚未测试的新提案功能添加检查。贡献涉及一个 .wat 文件，该文件提供了新提案的用法以查看其是否有效。该模块将由 wabt.js[^4] 编译。

在例 12-15 中，你可以看到针对多值返回提案的测试。

例 12-15. 一个支持多个返回值的 wasm-feature-detect 检测器

```c
;; Name: Multi-value
;; Proposal: https://github.com/WebAssembly/multi-value
;; Features: multi_value
(module
  (func (result i32 i32)
		i32.const 0
		i32.const 0 
  )
)
```

使用库来测试某些功能也很简单。在例 12-16 中，我有一个简单的测试，它遍历了大部分可用的测试，并指示它们是否被当前浏览器支持。

例 12-16. 一个测试文件，用于查看浏览器支持哪些新提案

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <script type="module">
      import {
	       bigInt,
	       bulkMemory,
	       exceptions,
//	       memory64,
	       multiValue,
	       mutableGlobals,
	       referenceTypes,
	       saturatedFloatToInt,
	       signExtensions,
	       simd,
	       tailCall
	     } from "https://unpkg.com/wasm-feature-detect?module";

      function test(test, promise) {
	  promise().then( supported => {
	      console.log("Test: " + test + " is " + supported);
	  });
      }

      test("BIGINT", bigInt);
      test("BULK MEMORY", bulkMemory);
      test("EXCEPTIONS", exceptions);
//      test("MEMORY64", memory64);
      test("MULTIVALUE", multiValue);
      test("MUTABLEGLOBALS", mutableGlobals);
      test("REFERENCETYPES", referenceTypes);
      test("NONTRAPPING F-to-I", saturatedFloatToInt);
      test("SIGN EXTENSIONS", signExtensions);
      test("SIMD",  simd);
      test("TAIL CALL", tailCall);
    </script>
  </head>
  <body>
  </body>
</html>
```

在图 12-1 中，你可以看到在 Safari 中加载此测试 HTML 的结果。在撰写本文时是 Safari 15.0，它最近发布了对 WebAssembly 的更多支持。值得注意的是，缺乏对 SIMD 提案的支持。

![图 12-1. 在 Safari 中测试 WebAssembly 功能](../images/f12-1.png)

在图 12-2 中，你可以看到在 Firefox 中加载此测试 HTML 的结果。Firefox 一直是对 WebAssembly 支持最强大的浏览器之一，因此覆盖率如此之高也就不足为奇了。

![图 12-2. 在 Firefox 中测试 WebAssembly 功能](../images/f12-2.png)

在图 12-3 中，你可以看到在 Chrome 中加载此测试 HTML 的结果。由于它也是一个具有强大 WebAssembly 支持的浏览器，我对缺乏对引用类型的支持感到惊讶，但我想这很快就会到来。

![图 12-3. 在 Chrome 中测试 WebAssembly 功能](../images/f12-3.png)

## 其他提案

关于 WebAssembly 平台还有许多其他[提案](https://github.com/WebAssembly/proposals)。新的提案也会层出不穷。这是 WebAssembly 平台设计者用来增量扩展平台的主要方法之一。

每个提案都根据其自身的优点及其对模块的文本和二进制格式、模块的解析和验证、对其他提案的依赖性或对其他提案的潜在影响的影响进行考虑。你所听到的有关制定法律和香肠的内容，对标准流程也是如此 [^5]。这些建议使用精确和正式的语言来描述细节，因此不会因实施者的不同解释而出现错误。

一些提案是基础性的，例如添加垃圾收集、更高级别的接口类型、线程、矢量数学等的能力。其他的比较隐蔽，或者实现其他的新特性，但是都得先设计实现。目前还没有很多对开发人员友好的描述，但我相信随着 Wasmtime、Wasmer、Wasm3 和其他环境逐渐增加支持，它们将是你了解它们的最佳场所。

如果整个过程看起来有点大杂烩，那么，这是一个公平的批评，这就是为什么有人提案向 WebAssembly 平台添加功能检测——从而更容易检测哪些功能已启用，哪些未启用。直接访问将是最佳选择，但也可能有机会使用垫片、polyfill 和其他应急措施，以防它们未启用。理想情况下，我们不希望进行太多的功能检查，因为这会使测试策略和可移植性复杂化，但不可避免地会有一些检查。

现在，这足以让我们一窥即将发生的事情以及 WebAssembly 将如何随着时间的推移而发展。是时候看看我们如何在 .NET 世界中使用这个平台了。

## 注释

[^1]: 由于它代表了对 WebAssembly 平台的根本改变，多值建议已被合并到 WebAssembly 标准本身。
[^2]: 你可以在 [GitHub](https://github.com/WebAssembly/reference-types) 上找到引用类型的提案。
[^3]: [模块连接提案](https://github.com/WebAssembly/module-linking)是一个相当复杂的问题，需要首先得到几个更基本的提案的支持。
[^4]: [wabt.js](https://github.com/AssemblyScript/wabt.js) 是我们在本书早期介绍的 WebAssembly Binary Toolkit（WABT）功能的一个移植。
[^5]: 虽然这句话经常被当成是俾斯麦说的，但有证据表明，是 John Godfrey Saxe 说的，法律就像香肠。如果你喜欢这两者，你就不应该看着它们被制造出来。
