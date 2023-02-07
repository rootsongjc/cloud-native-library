---
linktitle: 第 12 章：扩展 WebAssembly 平台
summary: 扩展 WebAssembly 平台。
weight: 13
icon: book-reader
icon_pack: fas
draft: false
title: 扩展 WebAssembly 平台
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

> 吸收琐碎的信息，他善于适应
>
> 因为对于陌生人和安排者来说，只有不断适应变化
>
> ——Rush，"Digital Man"

WebAssembly的[MVP](https://github.com/WebAssembly/design)定义是在地上打了一个桩，但从来没有打算作为全面的解决方案。它主要关注的是语言特性和不需要复杂的线程、垃圾收集和异常处理的运行时。还有一些其他的限制，我们在书中也看到了。虽然人们已经找到了解决这些缺点的方法，令人印象深刻，但MVP不是终点，它只是个开始。

WebAssembly平台的设计者对其决策采取了一种外科手术式的方法。虽然从外面看可能很混乱，但内部有一种一致性，考虑到了一些较大的和长期的目标。这些决定的许多动机都与规范本身一起被记录下来。设计者没有把所有遗漏问题的解决方案塞进下一个大版本中，而是创建了一系列独立跟踪的后续建议。这些建议中有几个是相互依存的，所以它们被提交和采纳是有顺序的。

由于后MVP世界是这样发展的，要跟踪哪些功能在哪个发行版中可用变得有点棘手。我希望能有工具和库来解决这个问题，将开发者的负担最小化。设计中的复杂性有些并没有多大用处，所以我不想花很多时间在上面，但它在某种程度上是有启发性的，可以看到像多值和参考类型的提议如何帮助实现更重的接口类型提议。

我们将把这些扩展视为一个后续功能的集合，这些功能还没有得到完全的支持，但却代表了WebAssembly平台的发展方向。我不会全面介绍这些建议，因为许多建议比较深奥，或者还没有成熟。只是要注意，有几种尝试是为了改善以WebAssembly为目标的体验，使我们的代码更广泛地可用、安全、快速和便携。

## WASI运行时

在[第 11 章](../wasi/)中，我们介绍了WASI的主要思想。它已经成为向平台添加新功能的主要载体之一。有一个过程来介绍建议的扩展的过程（译者注：该流程已不存在），然后在采用和标准化的过程中经历一系列的阶段。正如我们在上一章所指出的，不是每个运行时都会支持每个提议。即使在某些情况下支持一项建议，出于安全原因，在其他情况下也可能不支持。我们看到一些基本的命令行使用Wasmer和Wasmtime引擎，但更有趣的现实是，你将能够使用基于WASI的机制从你自己的应用程序执行任意的功能。

这将使你能够安全地构建和部署插件机制、无服务器功能、热插拔替换、数据过滤器、零售促销、Kubernetes节点、区块链引擎以及可以用任意语言编写的扩展点。语言的自由度、性能和沙盒隔离的结合，推动了许多项目和公司已经开始这样做。

Fastly和Cloudflare等边缘计算公司正允许客户在地理上分布微服务和无服务器函数，以便在多租户环境中进行低延迟访问 。Istio和Envoy正允许他们的用户创建过滤器，并通过基于WebAssembly的机制支持新协议。SecondState的WasmEdge环境，除其他用途外，还针对区块链和软件定义的车辆。WasmCloud正在提供一个基于行为者模型的分布式系统基础设施。甚至[微软飞行模拟器](https://docs.flightsimulator.com/html/Programming_Tools/WASM/WebAssembly.htm)正在从基于动态链接库的WebAssembly模块的插件 。我们将在[第15章](../applied-wasm-cloud-and-edge/)中讨论一些其他项目。 

现在，我将用一些简单的模块向你展示使用WebAssembly和WASI的基础知识。一旦你适应了这些概念和事件的顺序，我们将介绍一些基于WASI的框架所支持的新建议，看看这个平台是如何发展以填补一些MVP的遗漏的。

首先，创建一个Rust二进制项目：

```bash
brian@tweezer ~/g/w/s/ch12> cargo new --bin hello-wasi
	Created binary (application) `hello-wasi` package
brian@tweezer ~/g/w/s/ch12> cd hello-wasi
```

我们需要添加对Wasmtime crate的依赖，这样我们就可以访问允许我们实例化模块和执行代码的运行时结构。编辑`hello-wasi`目录下的`Cargo.toml`文件，其内容如例12-1 所示。请记住，当你读到这里的时候，版本号可能已经不同了，但它应该仍然可以工作。

例 12-1. Cargo.toml 文件

```toml
[package]
name = "hello-wasi"
version = "0.1.0"
edition = "2018"
[dependencies]
wasmtime = "0.28.0"
```

我们将使用Rust版本的库，但也有类似的结构用于其他语言，如C和Python。我们将在随后的章节中看一下.NET和AssemblyScript版本。甚至可以用bash来使用Wasmtime的命令行版本，如例 12-3 所示。

例12-2. 从bash中调用我们的函数

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

当我们使用支持的开发语言中的库、类和结构时，我们对生命周期有更大的控制。首先，我们将调用[第 2 章](../hello-world/)中的年龄计算模块。你可以通过查看以下内容来更新你的记忆 例 12-3.

例12-3. 年龄计算的Wasm模块

```c
(module
    (func $how_old (param $year_now i32) (param $year_born i32) (result i32)
        get_local $year_now
        get_local $year_born
        i32.sub)

    (export "how_old" (func $how_old))
)
```

现在我们将创建一个独立的Rust应用程序，通过Wasmtime库调用行为。请记住，Wasmer、Wasm3和其他环境也会有自己的策略，我们将在本书的剩余部分演示其中的一些策略。我将带领你完成这些细节，但请看一下例 12-4。

例12-4. Rust中最小的Wasmtime WASI集成

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

在导入我们正在使用的各种功能的前奏定义后，我们开始使用Wasmtime的Rust库所定义的结构。查看表12-1 以了解这些类型的描述。

表12-1. Wasmtime结构

| 名称     | 描述                                              |
| -------- | ------------------------------------------------- |
| Engine   | 用于配置值的全局环境，旨在跨线程共享。            |
| Store    | WebAssembly对象的集合，包括实例、全局、内存和表。 |
| Module   | WebAssembly模块的编译形式。                       |
| Instance | 编译后的模块的一个实例。                          |

Engine包含任何特殊的配置细节。如例 12-4中，我们只是使用了一个默认的配置。这是用来创建Store的。这为WebAssembly功能提供了一个上下文，因此是一个隔离的单位。在Store中创建的不同的WebAssembly结构不能被共享或从其他Store实例中访问。在Rust版本的Wasmtime API中，对Store实例的可变引用被传递到函数中，这就排除了跨线程共享它们。

Engine 接下来被用来初始化和编译模块实例。有多种机制来检索底层字节，但对于我们的目的，我们只是从文件系统中读入`.wat`文件。请记住，我们在这里构建的是一个本地的Rust应用程序，而不是一个WASI应用程序，所以它将被允许访问文件系统。

一旦Module被编译，我们就可以为它创建一个新的Instance。在这种情况下，我们不提供任何导入对象，但稍后我们将看到从Rust主机环境到模块共享函数的例子。从Instance中，我们能够检索到一个导出的函数包装器的引用，这样它就可以被调用，就像它是一个普通的Rust函数一样。我们使用类型安全的`get_typed_func`，它在这里接收两个i32参数并返回一个i32结果。

最后，我们用`2021i32`和`2000i32`这两个值来调用我们的函数，这两个值代表了2021和2000这两个数字的Rust 32位整数类型字。结果被保存在一个Rust的i32变量中，然后打印到控制台。

我在下面删除了不相干的构建输出，但我想证明它只是一个普通的Rust cargo构建命令，使用本地操作系统的后端来生成调用WebAssembly行为的应用程序。

```bash
brian@tweezer ~/g/w/s/c/hello-wasi> cargo build --release
	Finished release [optimized] target(s) in 3m 22s
brian@tweezer ~/g/w/s/c/hello-wasi> cargo run --release 
	Finished release [optimized] target(s) in 0.38s
		Running `target/release/hello-wasi`
You are 21
```

现在你已经看到了基础知识，我们将研究Wasmtime作为一个运行时支持的一些新建议。当你读到这本书时，可能会有更多的支持加入。在你的WebAssembly职业生涯的这一阶段，我认为你不必纠缠于提案本身的细节，尽管我会在相关的地方链接到它们。相反，我认为更重要的是让你看到WebAssembly平台如何发展的实际例子。因此，我将只关注在WASI环境中可用的 ，但在我们总结这一章时，将暗示还有什么会出现。

## 多值返回

MVP为调用函数确定了一些相当基本的语义。虽然它们 ，可以接受任何数量的参数，但函数只能产生一个结果。在许多情况下，这显然是好的，但很容易想象到这将是一个过度限制的场景。

考虑一下我们之前的一些涉及字符串的例子。因为我们是用线性Memory实例来分配字符串的，我们需要对字符串的基址以及字符串的长度的引用。没有简单的方法可以做到这一点，就像我们所做的那样，我们先写出字符串的长度，然后再写出字符序列。

那么，支持图元的语言，如Python或Rust呢？这允许开发者轻松地将几个值打包成一个结构，以便从一个函数中返回，但来自另一种语言的客户可能希望将它们拆开或解构成不同的表示方式，以便对该语言更加习惯。

即使是像交换一对数值或对数组进行排序这样简单的事情也变得很有问题。它必须在线性内存块中就地完成。如果考虑到模块化操作、携带位等因素，一些算术函数也可以返回多个值。

除了函数返回值，MVP的另一个限制是，条件块和循环等指令序列无法消耗数值或返回一个以上的结果。同样，交换值、进行溢出算术或在那里有一个多值元组响应也是很有趣的。

如果你记得[第 2章](../hello-world/)中，WebAssembly函数的结果是在堆栈的顶部。堆栈顶部的几个元素当然也可以被解释为多个返回值。因此，无论是作为对平台的改进，还是为了方便其他的扩展，多值返回类型的扩展是一个重要的下一步[^1]。在这一点上，它已被合并到主要规范中，并在许多WebAssembly环境中实施。

该提案引入了新的指令，如上述的算术函数。这包括`i32.divmod`，它接受分子和除数，并返回商和余数。它还允许多个值保留在堆栈中，而不必复制到线性内存实例中。这既更快又更节省内存。
因为Wasmtime已经支持多值建议，我们可以很容易地证明它是多么有用。在例12-5中，你可以看到一个Wat文件，它提供了我们将要使用的结构。第一行从Rust环境中导入了一个接收两个参数并返回两个参数的函数。正如你所看到的，从语法上扩展结果以支持一个以上的值并不是什么大事。实现它显然更复杂，但正如我提到的，结果来自堆栈的顶部。我们称我们的新函数为swap，因为这就是我们将传入的函数所要做的。

例12-5. 一个演示多值返回类型的简单Wat文件

```c
(module
   (func $swap (import "" "swap") (param i32 i32) (result i32 i32))

   (func $myfunc (export "myfunc") (param i32 i32) (result i32 i32)
      (call $swap (local.get 0) (local.get 1))
   )
)
```

其中定义了一个名为`myfunc`的导出函数，调用我们的交换函数。我们调用指令将这些值推到堆栈，然后直接调用我们的导入函数。在我们的函数定义中，除了表明我们返回两个i32值作为我们的结果外，我们不需要做任何特别的事情。一旦交换返回，这些值应该在堆栈的顶部。这些幕后细节是Wasmtime团队必须实现的，但对Wat语法的影响相当小。

在例12-6中，你可以看到将调用我们的Wat函数的主程序。该程序的大部分内容与你在例12-4中看到的非常相似。

例12-6. 使用Wasmtime Rust库练习多值返回类型

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

我们通过调用`Func::wrap`来定义一个回调函数。这需要一个对我们的Store实例的可变引用和一个Rust闭包，它需要两个i32参数并返回两个i32参数的元组。我们正在使用习惯性的Rust来表达这个功能，这个闭包的实现非常微妙。我们只是返回一个参数顺序相反的元组。

现在我们有了回调，注意我们在创建模块Instance的时候把它传递给了导入上下文。在这之后，我们从WebAssembly模块导出的`myfunc`函数中获取一个包装器，并用一个元组值调用它。这也是Rust的习惯做法，是传递两个参数的自然方式。这些参数将在幕后被分解成我们函数所期望的两个参数。调用导出函数的结果 ，被捕获为一个元组，然后我们对其进行解构并打印出结果。

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

拥有指定多个返回值的能力是一些额外建议的必要前提。另一个有利的建议是能够指定对不透明句柄的引用。这对于增加垃圾收集、具有类型化的引用、使用异常处理等是至关重要的，但它也是让主机环境能够传递不透明的引用的关键，这些引用指的是我们不希望WebAssembly模块有原始访问权的资源。请记住，我们谈论的是能够在任意操作系统上用任意的语言传递任意结构的引用。要做到既灵活又有性能，不是一件容易的事。

我们以前也能进行引用，但只是对函数进行引用，而且只是在表的实例中，一旦它们被创建，我们就不能进行操作。这在一定程度上是为了不允许模块操作内存中的敏感细节，或者能够改变哪个函数在哪个槽中。记得从 第七章 我们必须对函数引用进行间接调用，而不是更常见的对其他函数的直接调用。

这个新建议使我们有能力操纵Table的成员，增加Table的实例大小，并在WebAssembly模块和它们的主机环境之间来回传递externref引用[^2]。

Wasmtime支持进行externref引用的能力，我们使用这个API创建另一个示例应用程序。要清楚，任何WASI环境都必须支持这些基本提议，但我们的重点是Wasmtime。

```bash
brian@tweezer ~/g/w/s/ch12> cargo new --bin hello-extref
	Created binary (application) `hello-extref` package
```

这是对我们Wat文件的语法的另一个相对简单的改变。快速检查一下 例 12-7 就会发现，我们可以把externref元素存储在一个Table中，或者把它们作为参数传入，或者作为函数结果返回。这是Wasmtime关于这些引用类型的例子的简化版本。我在这里不关注它们，但也可以对externref元素进行全局变量引用。

例12-7. 一个带有externref参数、表元素和结果的Wat文件

```c
(module
  (table $table (export "table") 10 externref)

  (global $global (export "global") (mut externref) (ref.null extern))

  (func (export "func") (param externref) (result externref)
    local.get 0
  )
)
```

我们的模块导出了一个Table，其中有10个引用的空间。我们还有一个函数，只是简单地返回其参数。例12-8 中的Rust代码比我们看过的其他例子要复杂得多，因为我们要对这些引用进行封装，并根据需要提取封装后的数据。不过，我还是会带着你浏览一遍，这样我们就可以把注意力放在新的东西上。

例12-8. 一个使用externref元素的Wasmtime Rust应用程序

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

你首先看到的是引入一个配置实例。我们之前一直在为我们的Engine实例使用默认配置，但是我们需要打开对外部引用的支持，然后相应地配置我们的Engine。从那时起，从设置的角度来看你应该很熟悉。

为了证明我们在引用方面的灵活性，我们从Wasmtime的API中创建了两个ExternRef结构的实例。一个可能是一个不可伪造的承载令牌，或者当模块进行共享函数调用时可以传递回来的东西。对于我们的目的，我只是有一个字符串切片，写着 "秘密密钥"。另一个引用是对一个字节数组的引用。由于ExternRef结构是一个参数化的类型，它能够包住这两种数据类型。

在我们创建了引用之后，我们从模块中检索导出的表，并在槽3和槽4中存储我们引用的克隆。我们使用Some包装器，这样就可以更容易地分辨出引用是否在那里。如果什么都不存在，我们可能会得到一个 None实例。这是通过 Rust 中一个叫做 [Option](https://doc.rust-lang.org/stable/std/option/) 的结构。由于Table存储的是externref元素，模块没有办法查看细节。然而，当我们把它们检索出来的时候，它们仍然代表着我们放在里面的结构。其他编程语言会根据静态类型和内存管理的细节，对这个程序有不同的机制，但它看起来基本上是一样的。

拉出引用看起来有点奇怪，但是第一个`unwrap()`函数可以确定我们是否在Table实例的边界内做了一个索引引用。然后，它提取externref并验证它是该类型的一个实例（而不是其他引用类型）。最后`unwrap()`确保它没有产生一个空的引用，这是这个建议给WebAssembly平台带来的另一个补充。

接下来的步骤也许更奇怪，但我们正在对我们的引用进行去重，提取数据，并将它们转换为我们期望的类型，在这种情况下，是一个具有静态寿命的字符串片断也称为字符串字面（string literal）和一个四元素的u8数组。

假设这些成功，我们就打印出我们从模块实例中拉回来的元素值。

我们的最后一步是获取对模块导出函数的引用，该函数接收一个Option包裹的ExternRef，并返回一个Option包裹的ExternRef。回顾一下例 12-7，我们的函数只是返回它的参数。我们用一个克隆的 ExternRef 的副本来调用我们的函数，捕获返回值，并通过同样的下转换来提取值。

现在一切都已经解释清楚了，我们可以像往常一样执行这个例子。

```bash
brian@tweezer ~/g/w/s/c/hello-extref> cargo run --release 
	Finished release [optimized] target(s) in 0.36s
  	Running `target/release/hello-extref`
Retrieved external reference: secret key from table slot 3
Retrieved external reference: [1, 2, 3, 4] from table slot 4
Received secret key back from calling extern-ref aware function.
```

我承认这不是世界上最激动人心的例子，但这个提议和多值提议一样，更多的是关于它所促成的事情，而不是你本身会使用的东西 。

## 模块链接

本章介绍的最后一项提案是模块连接[^3]。这个提案的范围相当大，它最终是关于允许模块本身通过各种机制和风格被导入。

考虑一下WASI标准库的基本原理。我们想有一个依赖性的模块，它将提供这种行为，而不需要逐个导入各个方法。如果每个函数的调用都要经过一个JavaScript包装器或类似的东西，这种方法将是脆弱的、令人讨厌的，而且最终会表现不佳。然而，我们确实喜欢虚拟实现的想法，这样文件系统的访问就可以通过在浏览器中使用本地存储来实现，而其他API可能会表现得很好（例如，通过`fd_write`打印到JavaScript控制台）。我们还希望能得到共享无结构的好处，比如我们之前讨论过的Unix管道和过滤器策略，而且不会有性能上的损失。我们还希望能够拥有广泛使用的模块的共享实例以节省内存。我们所需要的是描述模块类型的能力，并允许不同的实现来满足这些类型。

因为有复杂的要求，这是一个复杂的建议。为了便于理解，我们将展示一个简单的例子，但它将对我们的WebAssembly系统中大型、复杂的模块依赖树的弹性和便利性产生巨大影响。甚至还有一种新的文本格式来描述基于Wat的这些接口。然而，它只允许接口定义，所以它有一个扩展名`.wit`来区分类型。

在例 12-9中，我们看到了一个在模块连接建议中定义的样本模块。

例12-9. 一个样本模块的Wat文件

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

在例 12-10中，我们看到了相应的接口文件 (.wit)，它没有实现的细节，但仍然根据它导入和导出的元素定义了模块的 "类型"。这最终将使我们有能力更干净、更灵活、更高效地连接模块。

例12-10. 同一模块的一个Wit文件

```c
(module
  (memory (import "a") 1 2)
  (func (import "b") (param i32))
  (table (export "c") 1 funcref)
  (func (export "d") (result f32))
)
```

为了方便起见，我将只展示模块连接的例子，这些例子来自于 [Wasmtime 示例](https://github.com/bytecodealliance/wasmtime/tree/main/examples)的例子。我们有两个模块，一个依赖另一个，一个依赖有WASI能力的写到控制台。

例12-11 中的 `Cargo.toml` 文件比我们到目前为止看到的，多了一些依赖关系。然而，最重要的一个是`wasmime-wasi`的依赖。这是一个标准WASI功能的实现，我们将在下面的例子中与之链接。

例12-11. 为我们的模块链接例子编写的Cargo.toml文件

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

在例12-12 的第一个模块中，我们导入了一个名为double的函数，它将接收一个i32，将其加倍，并返回一个i32。我们还导入了一个名为log的函数，它将在Memory中打印一个给定偏移量和给定长度的字符串。我们还将导入一个要使用的Memory实例和一个代表偏移量的全局变量，以作为我们活动的位置。

我们导出的运行函数将常数2加载到堆栈，然后调用double函数。记住，堆栈的顶部将包含参数，所以我们希望这将产生4的值。我们没有对输出做任何处理，但它确实起作用了。重点是，我们对一个导入的函数的调用实际上是有效的。

在数值翻倍后，我们调用log函数打印出 "Hello, World！"注意，我们在全局变量指定的位置将我们的字符串与一个数据元素写入内存。

例12-12. 一个我们要链接的模块，它依赖于另一个模块

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

第二个模块显示在例12-13 中。它为一个接受四个i32参数并返回一个i32的函数定义了一个类型。这个类型将对应于我们将从WASI命名空间`wasi_snapshot_preview1`导入的`fd_write`方法。 这个方法，正如我们在[第 11 章](../wasi/)中看到的，这个方法需要文件描述的参数，字符串向量开始的位置，有多少个，以及它应该把代表写入字节数的返回值写到哪里。

还有一个名为double的简单函数，它将发送进来的i32参数加载到堆栈中，用常数2跟进，然后调用`i32.mul`指令，它将弹出堆栈顶部的两个值，将它们相乘，并将结果写回堆栈顶部。

我们导出的日志函数在设置好细节后调用了导入的`fd_write`。注意到许多模块可能会导入`fd_write`功能，但在这里我们有一个可重复使用的函数，隐藏了大部分细节。其他模块可以导入我们的函数定义，并传入一个内存指针和长度，以达到相同的结果。

最后，我们的模块输出了一个Memory实例和一个全局变量，表示当前的偏移量，以便将数值写入其中。这是一种（潜在的脆弱的）方法，允许使用的内存由这个模块管理，同时允许其他模块写入未使用的空间。

例12-13. 第一个模块所依赖的第二个模块

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

例12-14 中的 Rust 代码介绍了Wasmtime API的一些其他特性。第一个是链接器的概念。这是一个工具，它可以根据模块的导入和导出配置，帮助将模块连接在一起。因为WASI的功能被广泛使用，它可以作为我们在例12-11中看到的单独的依赖关系来使用。 把这个模块的细节添加到链接器中，这样它们就可以被链接到依赖于这个行为的模块中。

在这之后，实例化我们的两个模块，配置WASI实例，并将细节添加到Store 中，以便它们在运行时可以在上下文中使用。

我们在链接器实例中注册第二个模块，因为我们要让它对我们的第一个模块可用。请记住，这里的整个想法是关于平衡重用、交换性、性能、隔离和其他要求。

例12-14. 一个我们要链接的模块，它依赖于另一个模块

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

关于功能测试有很多天，推荐使用谷歌的一个库，叫做 [wasm-feature-detect](https://github.com/GoogleChromeLabs/wasm-feature-detect)。这不仅仅是一个聪明的名字。这就是它的作用。

它是相当直接的，并且很容易通过插件测试进行扩展。他们向那些希望为他们尚未测试的新提案功能添加检查的开发者征求意见。贡献涉及到一个`.wat`文件，它提供了一个新提案的使用，看它是否工作。该模块将由wabt.js编译[^4]。

在例 12-15中，你可以看到对多值返回提案的测试。

例12-15. 一个支持多值返回的wasm-feature-detect检测器

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

使用该库来测试某些功能也是很直接的。在例12-16中，我有一个简单的测试，它浏览了大部分可用的测试，并指出它们是否被当前的浏览器所支持。

例12-16. 看一个浏览器支持哪些新提案的测试文件

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

在图 12-1中，你可以看到在Safari中加载这个测试HTML的结果。在写这篇文章的时候，这是Safari 15.0，它最近发布了对WebAssembly的更多支持。值得注意的是，缺乏对SIMD建议的支持。

![图12-1. 在Safari中测试WebAssembly功能](../images/f12-1.png)

在图12-2中，你可以看到在Firefox中加载这个测试HTML的结果。Firefox 是一直对WebAssembly支持最强的浏览器之一，所以覆盖率如此之高也就不奇怪了。

![图12-2. 测试Firefox中的WebAssembly功能](../images/f12-2.png)

在 图12-3中，你可以看到在Chrome中加载这个测试HTML的结果。由于它也是一个具有强大WebAssembly支持的浏览器，我对缺乏对引用类型的支持感到惊讶，但我想这很快就会出现。

![图12-3. 在Chrome中测试WebAssembly的功能](../images/f12-3.png)

## 其他提案

关于WebAssembly平台还有很多其他[提案](https://github.com/WebAssembly/proposals)。新提案也会层出不穷。这是 WebAssembly平台设计者用来逐步扩展平台的主要方法之一。

每个提案都会根据其自身的优点以及对模块的文本和二进制格式、模块的解析和验证、对其他提案的依赖性或对其他提案的潜在影响来考虑。你所听到的关于制定法律和香肠的说法，对标准过程也是如此[^5]。这些建议使用精确和正式的语言来描述细节，因此不会因为实施者的不同解释而出现错误。

有些提案是根本性的，比如增加垃圾收集、更高级别的接口类型、线程、矢量数学等等的能力。其他的则比较微妙，或者是为了实现其他的新功能，但必须先设计和实现。现在还没有很多开发者友好的描述，但我相信Wasmtime、Wasmer、Wasm3和其他环境将是你了解它们的最好地方，因为它们会逐渐增加支持。

如果整个过程看起来有点大杂烩，那么，这是一个公平的批评，这就是为什么有一个提案要在WebAssembly平台上增加功能检测——这样就可以更容易地检测出哪些功能被启用，哪些没有。直接访问将是最好的选择，但也可能有机会使用shim、polyfills和其他应变计划，以防止它们不被启用。理想情况下，我们不需要过多的功能检测，因为那会使测试策略和可移植性复杂化，但不可避免的是，会有一些检测。

现在，这足以窥见即将到来的东西以及WebAssembly将如何随着时间的推移而发展。现在是时候了解一下我们如何从.NET世界中使用这个平台了。

## 注释

[^1]: 由于它代表了对WebAssembly平台的根本改变，多值建议已被合并到WebAssembly标准本身。
[^2]: 你可以在 [GitHub](https://github.com/WebAssembly/reference-types) 上找到引用类型的提案。
[^3]: [模块连接提案](https://github.com/WebAssembly/module-linking)是一个相当复杂的问题，需要首先得到几个更基本的提案的支持。
[^4]: [wabt.js](https://github.com/AssemblyScript/wabt.js) 是我们在本书早期介绍的WebAssembly Binary Toolkit（WABT）功能的一个移植。
[^5]: 虽然这句话经常被当成是俾斯麦说的，但有证据表明，是 John Godfrey Saxe 说的，法律就像香肠。如果你喜欢这两者，你就不应该看着它们被制造出来。