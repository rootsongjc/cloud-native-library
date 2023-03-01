---
linktitle: 第 10 章：Rust
summary: Rust。
weight: 11
icon: book-reader
icon_pack: fas
draft: false
title: Rust
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

在我职业生涯的一个时期，我不再关心新的编程语言。似乎总是新的语言出现。大多数时候，我对它们丝毫不感兴趣。现在，一种新的编程语言必须比以前的语言有足够的优势，才能吸引我们的注意力，值得我们努力学习，投资于工具链等等。

大约在这个时候，我开始注意到 Go 和 Rust，我把它们放在同一个概念空间里：系统语言提供了与 C 和 C++ 大致相似的速度，但也包含了使它们更安全的语言特性。由于我一直是一个 Unix 用户，我被 Ken Thompson 和 Rob Pike 对 Go 的参与所吸引 [^1]。我也很高兴看到 Plan 9 的一些想法得到了一些支持。因此，我付出了一些努力来学习 Go，很高兴我做到了。我不认为有必要同时学习 Rust，因为我认为它是相同的东西。

然后，我对 WebAssembly 产生了兴趣。

当我听说 Rust 可以在后端发出 WebAssembly 时，我知道我需要更深入地研究。这时我了解了 Rust 语言、它的社区、工具和文档，并有点爱上了它。不要误会我的意思，我喜欢 Go 社区和语言也是如此，但 Rust 和 WebAssembly 之间的关系使我的兴趣大为转移，而且我一直没有回头。

到目前为止，在本书中，我们主要关注的是 C 和 C++ 与 WebAssembly 之间的关系。这是迈向不同语言的第一个重要步骤。Rust 是一种具有现代精神的现代语言。它提供了良好的运行时性能和一个安全规范，这几乎是不可能作为一个事后的想法而产生的。鉴于 C 和 C++ 在我们每天面临的错误、缺陷和恶意软件的利用方面仍然发挥着重要作用，拥有一种快速、安全的系统语言是一种实质性的改进。在长期作为开源社区的宠儿之后，这些好处已经开始对商业开发者变得明显，而且对 Rust 的兴趣也在不断增长。

C 和 C++ 显然在我们的行业中仍然扮演着重要的角色，但是，如果让我选择新的项目，我反而会选择 Rust。它确实已经成为镇上人人都在谈论的新孩子，所以在我们看 Rust 和 WebAssembly 之间的相互作用之前，让我们了解一下原因。

## Rust 简介

鉴于本书的内容已经很庞大，我无法在本书中教你 Rust。为此，我鼓励你去看看 Steve Klabnik 和 Carol Nichols 的免费书 [The Rust Programming](https://doc.rust-lang.org/stable/book/) 或 Jim Blandy, Jason Orendorff, and Leonora F.S. Tindall (O'Reilly) 的作品 [Programming Rust](https://www.oreilly.com/library/view/programming-rust-2nd/9781492052586/)。

Rust 最初是 Graydon Hoare 在 Mozilla 时的一个副业项目，但现在已经演变成了一种改变行业的语言，在谷歌、微软、苹果和其他领先的技术公司中获得了关注。他们感兴趣的原因有很多，但采用的主要动力是它是一种快速、安全、现代的语言。它最初是作为一种用于低级库和操作系统服务的系统编程语言，它甚至已经开始在 Linux 内核扩展中找到自己的方式。

很多 bug 是通过语言中一系列基本的设计来解决的。在其他语言中表现为运行时错误的问题在 Rust 中变成了编译时错误。不幸的是，这门语言有一个相当陡峭的学习曲线。你很可能会遇到莫名其妙的问题，让 Rust 编译器报错，而且一开始可能会感到相当沮丧。我把这种经历比作青少年经历的成熟过程。

起初，作为一个青少年，人们对你的期望不多，但慢慢地，人们对你的期望越来越多，直到你突然成为一个成年人。这个过渡过程可能是痛苦的，令人沮丧的。作为一个开发者，Rust 编译器希望你能清楚地沟通并表明你的意图，以便它能做出相应的反应。像 JavaScript 这样的语言对你没有这样的要求，所以根据你的背景，可能会有点反感。

然而，尽管你最初可能会对 Rust 编译器期望你达到的成人化水平感到厌烦，但它很快就会成为一种人们热衷的语言。在过去的几年里，它赢得了几次最受欢迎的语言调查，所以很明显，越过陡峭的学习曲线是一种有益的经验 [^2]。一旦青少年成为年轻的成年人，即使有额外的期望，也很少有人会渴望回到年轻时的自己。

假设你已经按照 [附录](../appendix/) 中的详细说明安装了 Rust。我们可以很容易地处理 "Hello World!" 这样的程序。如例 10-1 所示。

例 10-1. Rust "Hello, World!"

```rust
fn main () {println! ("Hello, World!");
}
```

在这里，我们有一个`main ()`方法和向控制台打印字符串的能力。虽然它看起来像是一个强调性的名字，但感叹号只是标志着这是一个宏，一个我们没有时间去探索的语言特性 [^3]。为了我们的目的，就把它看作是 C 语言中的`printf ()`或 Java 中的`System.out.println ()`。编译和运行这个简单的程序就像编写下列命令一样简单。

```bash
brian@tweezer ~/g/w/s/ch10> rustc helloworld.rs 
brian@tweezer ~/g/w/s/ch10> ./helloworld
Hello, World!
```

到目前为止，没有什么大问题，但不需要很长时间就会遇到与 Rust 的区别。请看例 10-2。

例 10-2. Rust 不可变的变量

```rust
fn main () {
  let s = "cool"; 
  s = "safe";
  
  println!("Rust is {}", s);
}
```

我们给变量 s 分配一个字符串。Rust 对类型非常挑剔，但也不是不必要地挑剔。当它可以使用类型推导来计算出一个变量应该是什么类型时就没有必要再啰嗦了 [^4]。Rust 编译器可以看出这里正在分配一个对字符串的引用。然后我们改变主意，用另一个字符串引用覆盖这个值，然后打印出新的值。在几乎任何其他编程语言中，这都是完全可以。在 Rust 中...

```bash
 --> immutable.rs:2:13
  |
2 |     let mut s = "cool";
  |             ^
  |
  = help: maybe it is overwritten before being read?
  = note: `#[warn (unused_assignments)]` on by default

warning: 1 warning emitte
```

在这个错误信息中发生了很多事情。因为 Rust 团队意识到其学习曲线很陡峭，所以他们花了大量的时间来确保错误信息是有帮助的 [^5]。

第一个错误信息只是说，第一个 赋值没有什么意义，因为你在读取之前就立即覆盖了这个值。这只是一个观察结果，表明一个潜在的代码气味 [^6]。如果你不想看到这个警告，你可以抑制它，但它默认指出了这些问题，这很好。

真正的问题是，Rust 变量默认是不可变的。一旦你分配了一个值，你就不能改变它。这似乎是一个奇怪的策略，但它迫使你明确你想改变的变量是可变的。有一大类 bug 涉及到变量的无意覆盖。你可能不会注意到你已经这样做了，直到测试失败或出现运行时问题。

很明显，我们需要 Rust 中的可变量；你只需要告诉编译器这就是你想要的，如例 10-3 所示。

例 10-3. 可变的 Rust 变量

```rust
fn main () {
  let mut s = "cool";
  s = "safe";
  println!("Rust is {}", s);
}
```

现在，通过重新编译（并抑制了未使用的赋值警告），编译成功：

```bash
brian@tweezer ~/g/w/s/ch10> rustc -A unused_assignments immutable.rs
brian@tweezer ~/g/w/s/ch10> ./immutable
Rust is safe
```

一开始你可能会因为必须这样清楚地沟通而感到恼火，但是 Rust 编译器只是在教你如何成为一个成年人，而沟通对于幸福和成功是至关重要的。

让我们来看看另一个例子，当你开始写 Rust 时，可能会绊倒你的东西。在例 10-4 中，我们有一个简单的程序。我们把一个字符串的字面意思赋给了一个变量 s，然后在打印出这两个字之前把它重新赋给了一个变量 t。

例 10-4. 使用 Rust 变量

```rust
fn main () {
  let s = "Hello, world." 
  let t = s;
  println! ("s: {}", s);
  println! ("t: {}", t);
}
```

这是一件非常合理的事情，我们看到 Rust 编译器没有报错：

```bash
brian@tweezer ~/g/w/s/ch10> rustc memcheck.rs 
brian@tweezer ~/g/w/s/ch10> ./memcheck
s: Hello, world.
t: Hello, world.
```

然而，只要稍作改动，就会出错，如例 10-5 所示。

例 10-5. Rust 内存检查器报错

```rust
fn main () {let s = "Hello, world.".to_string ();
  let t = s; 
  println! ("s: {}", s);
  println! ("t: {}", t);
}
```

这个问题在 Rust 编译器的错误信息中得到了很好的强调：

```bash
brian@tweezer ~/g/w/s/ch10> rustc memcheck.rs
error [E0382]: borrow of moved value: `s`
 --> memcheck.rs:4:23
  |
2 |     let s = "Hello, world.".to_string ();
  |         - move occurs because `s` has type `String`, which does not implement the `Copy` trait
3 |     let t = s;
  |             - value moved here
4 |     println!("s: {}", s);
  |                       ^ value borrowed here after move
  |
  = note: this error originates in the macro `$crate::format_args_nl` which comes from the expansion of the macro `println` (in Nightly builds, run with -Z macro-backtrace for more info)
help: consider cloning the value if the performance cost is acceptable
  |
3 |     let t = s.clone ();
  |              ++++++++

error: aborting due to previous error

For more information about this error, try `rustc --explain E0382`.
```

这看起来并不多，但通过添加`to_string ()` 方法的调用，我们已经违反了 Rust 的内存检查器。这是因为我们把一个字符串字面意思变成了一个堆分配的字符串。堆栈是分配与当前函数相关的短期变量的地方，这样当它们超出词汇范围时（即在函数结束时），它们可以很容易地被清理掉。堆分配的内存一直分配到它 ，直到不再需要。在 C 和 C++ 中，作为一个程序员，你通常必须自己管理这个过程。在 Java 和 JavaScript 环境中，运行时的垃圾收集器为你做这个。

Rust 通过强制执行值的所有权来管理缺乏运行时垃圾收集器的问题。在任何时候，只有一个变量可以拥有与一个堆分配的值相关的内存。在 例 10-5 中，我们首先将字符串的所有权分配给了变量 s，当我们将 s 分配给 t 时，所有权就转移了。在这一点上，s 不再指向任何有效的东西，所以我们试图在 `println!` 宏中使用 s 的做法被认为是违规的。

字面值和其他结构可以实现上面错误信息中提到的复制特性。这是一种允许相关位从变量复制到变量而不引起所有权转移的行为。因为 Rust 字符串结构没有实现这个特性，所以所有权检查适用。其他发生所有权转移的情况包括当变量被传递进或者出函数时，在循环中，以及在其他词汇结构（如条件句）中，都可以使用。

好消息是，通过更明确地说明我们的意图，可以绕过这个问题而不引入新的风险。我们试图避免的具体风险是初始化前的使用、自由使用后的使用，以及其他诸如 C 和 C++ 语言中的常见错误。我们可以使用引用而不是直接访问，这样我们就可以 "借用" 一个值。我们也可以有可变的引用，但一次只能有一个。这些功能有点像 Java 等语言中的 reader/writer 锁。

一旦我们能更好地沟通我们的意图，Rust 编译器就能协助我们实现目标，而不是一直和我们作对。最终的效果是，Rust 将一些运行时的错误转移到了编译时，这是一个更好的处理它们的地方。这就消除了更多类别的错误，使我们能够产生更高质量的软件，包括在系统开发中有用的快速、高并发的代码类型。

不过，使用 Rust 不仅仅是被编译器所困扰。在语言特性、工具和社区方面，一旦你度过了学习曲线，就会体会到其中的乐趣。Rust 的速度、安全性，以及它建立在 LLVM 之上的特点，使它成为与 WebAssembly 配对的最佳语言。

## Rust 和 WebAssembly

如果你按照 [附录](../appendix/) 中的指示来安装 Rust，那么你已经有了用 Rust 进行 WebAssembly 的基础知识了。正如我前面提到的，正是 Rust 对 WebAssembly 的原生支持，最初激起了我对 Rust 的好奇心。

在图 5-1 中，你看到 LLVM 提供了一个三阶段的架构。由于 Rust 是一种基于 LLVM 的语言，为了支持 WebAssembly，它基本上只需要一个新的后端。这并不完全正确，但现在它是一个合适的虚构。

你可以通过执行以下命令查看哪些后端已经安装：

```bash
brian@tweezer ~/g/w/img> rustup target list | grep installed 
wasm32-unknown-unknown (installed)
x86_64-apple-darwin (installed)
```

Rust 后端被标记为三要素，表示指令集架构（ISA）、供应商和操作系统。我在 Intel Mac 上运行该命令，所以你可以看到相应的默认后端。但你也可以注意到，WebAssembly 后端已经安装。由于它产生的代码是针对 WebAssembly 堆栈机的，我们不是在谈论 x86_64、arch64、arm7 或 riscv64。因为这段代码是可移植的，所以在哪台机器上运行并不重要，这就是为什么三者之间用 unknown-unknown 来填写。

如果你看一下例 10-6，你会看到将两个数字相加的代码（Rust 中的 i32）和测试该行为的 `main ()` 方法。

例 10-6. Rust 函数为两个整数相加

```rust
pub extern "C" fn add (x: i32, y: i32) -> i32 {x + y}

fn main () {println!("2 + 3: {}", add (2,3));
}
```

使用默认的后台，你可以查看这个代码的本地 Rust 版本的构建和运行结果：

```bash
brian@tweezer ~/g/w/s/ch10> rustc add.rs
brian@tweezer ~/g/w/s/ch10> ./add
2 + 3: 5
```

将同样的代码编译成 WebAssembly 模块，就像选择 WebAssembly 后端并表明我们要生成一个 C 动态库一样简单。你可以删除 main 函数或添加编译器指令来抑制报错，如下所示。

```bash
brian@tweezer ~/g/w/s/ch10> rustc -A dead_code --target wasm32-unknown-unknown ↵
  -O --crate-type=cdylib add.rs -o add.wasm
```

我们可以在命令上使用 wasm3 运行时执行我们的函数：

```bash
brian@tweezer ~/g/w/s/ch10> wasm3 --func add add.wasm 2 3 
Error: [Fatal] repl_call: function lookup failed
Error: function lookup failed ('add')
```

你将看到：

```bash
brian@tweezer-2 ~/g/w/s/ch10> ls -laF add*
-rwxr-xr-x 1 brian staff 334920 May 4 11:54 add*
-rw-r--r-- 1 brian staff 111 May 4 12:07 add.rs 
-rwxr-xr-x 1 brian staff 1501227 May 4 12:16 add.wasm*
```

哇，与本地文件相比，这是个相当大的文件。这又是因为 Rust 编译器对在 WebAssembly 环境下执行这段代码所需的期望。本地版本可以依靠本地动态库来提供所需的功能。在本书的这一点上，你应该记得如何检查 Wasm 模块的内容：

```bash
add.wasm:	file format wasm 0x1

Section Details:

Type [1]:
 - type [0] (i32, i32) -> i32
Function [1]:
 - func [0] sig=0 <add>
Table [1]:
 - table [0] type=funcref initial=1 max=1
Memory [1]:
 - memory [0] pages: initial=16
Global [3]:
 - global [0] i32 mutable=1 <__stack_pointer> - init i32=1048576
 - global [1] i32 mutable=0 <__data_end> - init i32=1048576
 - global [2] i32 mutable=0 <__heap_base> - init i32=1048576
Export [4]:
 - memory [0] -> "memory"
 - func [0] <add> -> "add"
 - global [1] -> "__data_end"
 - global [2] -> "__heap_base"
Code [1]:
 - func [0] size=7 <add>
Custom:
 - name: ".debug_info"
Custom:
 - name: ".debug_pubtypes"
Custom:
 - name: ".debug_ranges"
Custom:
 - name: ".debug_abbrev"
Custom:
 - name: ".debug_line"
Custom:
 - name: ".debug_str"
Custom:
 - name: ".debug_pubnames"
Custom:
 - name: "name"
 - func [0] <add>
 - global [0] <__stack_pointer>
Custom:
 - name: "producers"
```

好了，我们有了一堆调试信息和导出的内存什么的，但是没有导出 add 函数。我们可以在方法定义中添加一个编译器指令来解决这个导出问题，如例 10-7 所示。

例 10-7. 正确导出两个整数相加的 Rust 函数

```rust
#[no_mangle]
pub extern "C" fn add (x: i32, y: i32) -> i32 {x+y}
```

现在，重建并检查结果。你应该看到 Export 中的 add 方法。而且我们可以在命令行上调用它：

```bash
brian@tweezer ~/g/w/s/ch10> wasm3 --func add add.wasm 2 3 
Result: 5
```

你可能已经猜到了，我们也可以通过典型的 HTML/JavaScript 组合来调用我们的行为，可以说是不费吹灰之力，如例 10-8 所示。

例 10-8. 从 HTML 中调用 Rust 函数

```html
<!doctype html>
<html lang="en">
  <!-- Latest compiled and minified CSS -->
  <link rel="stylesheet" href="bootstrap.min.css">
  <head>
      <meta charset="utf-8">
      <script src="utils.js"></script>
  </head>
  <body>
    <title>Rust and WebAssembly</title>
    <div class="container">
      <h1>Rust and WebAssembly</h1>
      2 + 3 = <span id="sum"></span>.
    </div>

    <script>
      fetchAndInstantiate ('add.wasm').then (function (instance) {var add = instance.exports.add (2,3);
	  var sumEl = document.getElementById ('sum');
	  sumEl.innerText=add;
      });
    </script>
  </body>
</html>
```

在图 10-1 中，你可以看到现在熟悉的在浏览器中调用 JavaScript 函数的结果。当然，不同的是，它最初是用 Rust 编写的，而不是我们一直使用的 C 和 C++。

![图 10-1. 在 HTML 中调用 Rust](../images/f10-1.png)

如果这就是我们要谈论的 Rust 和 WebAssembly 的全部内容，那也不会有多么兴奋。幸运的是，多亏了 wasm-bindgen，事情很快就变得有趣多了。

## wasm-bindgen

在随后的章节中，我将向你介绍几个功能，这些功能将由最小可行产品（MVP）提供。这些功能包括引用更复杂的结构，如字符串和列表，支持线程，多值返回类型等。在那之前，wasm-bindgen 在高层次上连接了 JavaScript 和 Rust 上有很大帮助，这样你就可以跨越鸿沟传递数据，而不仅仅是数字。这个工具并不打算只用于 Rust，但到目前为止，我们已经看到了好处。

如果你按照 [附录](../appendix/) 中所描述的那样安装了 wasm-bingen 和 wasm-pack，你就应该拥有本章剩余部分所需的一切。后者不是必须的，但它使事情变得更容易，所以我们将从使用它的打包功能开始。

wasm-bindgen 的 "Hello, World!" 是从 Rust 中调用 `alert ()` JavaScript 方法，而不需要在 WebAssembly 中直接导入方法。正如你将很快看到的那样，浏览器的全部功能都将从 Rust 中被解锁并使用。更令人惊奇的是，这样做看起来好像都是用 Rust 写的。此外，你将能够与 JavaScript 共享 Rust 代码，并让它看起来像 JavaScript。我曾经使用过几种语言间桥接技术，这是我见过的最好的技术之一。

第一步是使用 cargo build 工具创建一个 Rust 库项目。这将为基本项目建立脚手架：

```bash
brian@tweezer ~/src> cargo new --lib hello-wasm-bindgen 
Created library `hello-wasm-bindgen` package
```

你可以覆盖`src/lib.rs` 文件中的默认代码，使之如例 10-9 所示。

例 10-9. 我们的库与 wasm-bindgen 一起使用

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern {pub fn alert (s: &str);
}

#[wasm_bindgen]
pub fn say_hello (name: &str, whom: &str) {alert (&format!("Hello, {} from {}!", name, whom));
}
```

这比我们目前看到的 Rust 稍微棘手一些，但也不算太糟。第一行导入`wasm_bindgen::prelude` 模块的内容，以便我们可以在 Rust 代码中使用它。这包括一些绑定代码，它将把我们连接到 JavaScript 运行环境。

下一行是一个 Rust 属性名称，`#[wasm_bindgen]`。这表明我们计划 调用一个名为 `alert ()` 的外部函数。这是我们用前面提到的使用声明从前奏中导入的功能之一。如果你认为这个方法听起来很熟悉，那么你会是对的。这最终将调用同名的方法，你可能已经从 JavaScript 中调用过很多次了。不过请注意这个签名。这不是一个 JavaScript 函数。从我们的角度看，我们只是从我们的 Rust 代码中调用一个 Rust 函数。wasm-bindgen 提供的桥梁是如此无缝，以至于我们在这一点上甚至不需要考虑其他语言。

这个 "Hello, World!" 的例子也要用另一种方式运行。从 JavaScript，我们要调用到 Rust。下一个 `#[wasm_bindgen]` 属性被应用于我们库中定义的一个 Rust 函数，该函数接收两个字符串片断。我们使用 Rust 的 `format!` 宏，这相当于其他语言中的字符串格式化函数。我们获取一个对返回字符串的引用，并将其传递给之前确定的 `alert ()` 函数。这个属性将生成一个等效的 JavaScript 函数，以便从那一边调用。从它的角度来看，它将调用 JavaScript，而不是 Rust！同一个属性让我们在任何一个方向都保持同步，这相当了不起。

下一步是使用 wasm-pack 来生成我们的支持代码。为了做到这一点，我们需要更新 `Cargo.toml`，以表明我们要生成一个 C 语言动态库风格的输出，为此我们需要 wasm-bindgen 作为一个依赖项，如例 10-10 所示。

例 10-10. Cargo.toml 文件

```toml
[package]
name = "hello-wasm-bindgen"
version = "0.1.0"
edition = "2018"

[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2.73"
```

现在我们可以使用 wasm-bindgen 来生成一个包裹我们 Rust 代码的 JavaScript 模块。我已经消除了一些关于缺失属性和 README 文件的警告，因为 ，以及一些可爱的小表情符号，这些都不能很好地翻译。

```bash
brian@tweezer ~/s/hello-wasm-bindgen> wasm-pack build --target web [INFO]: Checking for the Wasm target...
[INFO]: Compiling to Wasm...
Compiling hello-wasm-bindgen v0.1.0 (/Users/brian/src/hello-wasm-bindgen)
Finished release [optimized] target (s) in 0.26s
[INFO]: Optimizing wasm binaries with `wasm-opt`...
[INFO]:   Done in 0.73s
[INFO]:   Your wasm pkg is ready to publish at
[INFO]:   /Users/brian/src/hello-wasm-bindgen/pkg.
brian@tweezer ~/s/hello-wasm-bindgen> ls -laF pkg total 72
drwxr-xr-x	8 brian	staff	256 May 10 17:20 ./
drwxr-xr-x	9 brian	staff	288 May 10 17:20 ../
-rw-r--r--	1 brian	staff	1 May 10 17:20 .gitignore
-rw-r--r--	1 brian	staff	861 May 10 17:20 hello_wasm_bindgen.d.ts
-rw-r--r--	1 brian	staff	4026 May 10 17:20 hello_wasm_bindgen.js
-rw-r--r--	1 brian	staff	15786 May 10 17:20 hello_wasm_bindgen_bg.wasm
-rw-r--r--	1 brian	staff	291 May 10 17:20 hello_wasm_bindgen_bg.wasm.d.ts
-rw-r--r--	1 brian	staff	266 May 10 17:20 package.json
```

我们使用了`--target web`标志，表示我们希望我们的包可以在浏览器中加载。其他的选择包括使用 Webpack 来打包所有东西，或者以 Node.js 或 Deno 为目标，我们很快就会看到。在 pkg 目录中，你将看到生成的 JavaScript，我们的 Wasm 模块，以及 package.json 文件。还有我们的代码的 TypeScript 声明文件。如果你使用 wasm-objdump 并查看我们模块的 Export 部分，你会看到以下内容。

```
Export [4]:
  - memory [0] -> "memory"
  - func [19] <say_hello> -> "say_hello"
  - func [34] <__wbindgen_malloc> -> "__wbindgen_malloc"
  - func [38] <__wbindgen_realloc> -> "__wbindgen_realloc"
```

这包括一个 Memory 实例，我们导出的方法，以及一些内存分配函数。

最后一步是在 HTML 和 JavaScript 中调用 ES6 模块，如例 10-11 所示。

例 10-11. 从 JavaScript 中调用 Rust

```html
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<title>hello-wasm-bindgen Example</title>
	</head>
	<body>
	<script type="module">
		import init, {say_hello} from 		"./pkg/hello_wasm_bindgen.js"; 
    init ()
      .then (() => {say_hello ("Rust", "JavaScript");
    });
    </script>
  </body>
</html>
```

如果你像我们之前做的那样通过 HTTP 提供 HTML 文件，你应该看到如图 10-2 所示的结果。这是 JavaScript 通过 wasm-bindgen 生成的导出函数调用 Rust，而 Rust 又通过浏览器中由 wasm-bindgen 生成的围绕 JavaScript 功能的 Rust 包装器调用 JavaScript。

![图 10-2. 从 Rust 中调用 JavaScript](../images/f10-2.png)

尽管结果很平庸，但这是一个令人满意的结果，因为这两种语言之间产生的桥梁从任何一方看起来都很自然。在 Rust 中思考字符串片断，而不是像以前那样将字节写入内存实例，这要容易得多。

好了，现在我们已经掌握了基本知识，让我们来试试更有趣的东西。我非常喜欢 Rust 的模式匹配支持。其他语言也有这个功能，但我非常喜欢 Rust 的做法。请看 例 10-12。你将看到的第一个代码块上的 `#[wasm_bindgen]` 属性，表明我们想从 JavaScript 调用一个叫 `log ()` 的方法。注意第二个内部属性，其 js_namespace 为 console。这表明我们可以从 Rust 中直接调用 `console.log ()`，这要感谢 wasm-bindgen。

例 10-12. 实践中的 Rust 模式匹配

```rust
use wasm_bindgen::prelude::*;
#[wasm_bindgen]
extern "C" {#[wasm_bindgen (js_namespace = console)] 
  fn log (s: &str);
}

#[wasm_bindgen]
pub fn describe_location (lat : f32, lon : f32) { 
  let i_lat = lat as i32;
  let i_lon = lon as i32;
  use std::cmp::Ordering::*;
  
  let relative_position = match (i_lat.cmp (&38), i_lon.cmp (&-121)) {(Equal, Equal) => "very close!",
    (Equal, Greater) => "east of me",
    (Equal, Less) => "west of me",
    (Less, Equal) => "south of me",
    (Less, Greater) => "southeast of me",
    (Less, Less) => "southwest of me",
    (Greater, Equal) => "north of me",
    (Greater, Greater) => "northeast of me",
    (Greater, Less) => "northwest of me"
  };
  
  log (&format!("You are {}!", relative_position));
}
```

在 Rust 中为我们提供了`log ()`方法之后，我们定义了一个名为`describe_location ()`的函数，该函数接收两个 f32，将它与我们的大致位置进行比较。为了简化比较，不泄露太多关于我在哪里的细节，我只比较我当前位置的整数部分（38N, -121W）。为了适应这种情况，我把传入的浮点数化成整数，然后导入允许我比较整数的功能 。截断的`i_lat`值与我的纬度比较，`i_lon` 值与我的经度比较。结果被放入一个 Rust 元组，它就像 Python 元组一样，是将一个或多个值放入一个结构的轻量级方式。

然后，当另一个地点与我的地点进行比较时，该元组中的值与各种可能性进行匹配。如果 `cmp ()` 返回两个相等的值，那么这个位置就在我附近。如果纬度相等但经度不相等，那么另一个位置就在我的东面或西面。我们在这里有一个非常紧凑但可读的方法来处理九个独立的情况。如果这被表达为一堆嵌套的 if-then 子句，那就更难阅读了。

一旦我们生成了相对位置的描述，我们就调用 log 函数来打印出结果。由于这最终是 `console.log ()` 函数，结果将在你的浏览器的开发者控制台中打印出来。

下一步是建立我们的包，在 HTML 和 JavaScript 中导入：

```bash
brian@tweezer ~/s/geo-example> wasm-pack build --target web [INFO]: Checking for the Wasm target...
[INFO]: Compiling to Wasm...
  Compiling geo-example v0.1.0 (/Users/brian/src/geo-example)
    Finished release [optimized] target (s) in 0.51s
[INFO]: Optimizing wasm binaries with `wasm-opt`...
[INFO]:  Done in 1.01s
[INFO]:  Your wasm pkg is ready to publish at /Users/brian/src/geo-example/pkg.
```

在例 10-13 中，我们看到了调用我们行为的 HTML 和 JavaScript。我们导入了这些函数，然后调用一个 JavaScript 函数来测试浏览器上的地理位置对象是否可用。如果有，我们就要求提供当前的位置，这就会触发一个弹出窗口让用户批准。如果给出了位置，结果将显示为占位符段落元素的内部文本，我们在 Rust 中调用`describe_location ()` 方法来进行模式匹配。

例 10-13. 从 HTML 中调用 Rust 模式匹配

```html
<!DOCTYPE html>
<html>
    <head>
    <meta charset="utf-8">
    <title>geo-example</title>
    <link rel="icon" href="data:;base64,=">
  </head>

<body>
  <script type="module">
    import init, {describe_location} from "./pkg/geo_example.js";
    init ()
       .then (() => {getLocation ();
       });

    var output = document.getElementById ("output");

    function getLocation () {if (navigator.geolocation) {navigator.geolocation.getCurrentPosition (showPosition);
       } else {output.innerHTML = "This browser doesn't support Geolocation.";}
    }

    function showPosition (position) {output.innerHTML = "Your position:<br>Latitude:" + position.coords.latitude.toFixed (2) +
	    "<br>Longitude:" + position.coords.longitude.toFixed (2);

	describe_location (position.coords.latitude, position.coords.longitude);
    }
  </script>

  <p>Open up your JavaScript console and allow the browser to see your current location</p>
  <p id="output"></p>
</body>
</html>
```

执行这段代码的结果如图 10-3 所示。

![图 10-3. 在 Rust 中从 JavaScript 中进行模式匹配的地理定位](../images/f10-3.png)

## 设计浏览器内外的代码

我想介绍的最后一节是另一个 WebAssembly 用例，我认为它将会越来越受欢迎。我们已经研究了针对浏览器使用 JavaScript 以外的语言。我们还讨论了在基于浏览器的运行时中重复使用现有代码的情况。但是，那些被设计为在浏览器内部和外部都能正常运行的代码呢？我认为，一旦越来越多的人对 WebAssembly 提供的东西感到满意，这将是一个越来越普遍的情况。

我一直在期待这种活动，因为我一直在关注 WebAssembly，但我惊讶于 Emil Ernerfeldt 的 [egui 库](https://github.com/emilk/egui)。他把这个项目描述为 "一个易于使用的纯 Rust 的即时模式 GUI"[^7]。它是一个复杂的用户界面库，在浏览器内部和外部都能工作。

我们在本章中多次提到，Rust 得益于其 LLVM 遗产，允许我们生成各种后端目标。这也是 Emil 在利用这个优势来实现工作的。但他做得很优雅，我认为有很多东西可以从他那里学到。他是如何做到这一点的全部细节超出了本章的范围，但我想请你留意这个项目，以防重复劳动。

首先，让我们看看将应用程序作为本地应用程序的运行情况。如果你是在 Linux 上，你必须再安装一些 GitHub 网站上列出的软件包，但之后，你只需运行即可。

```bash
brian@tweezer ~/g/egui> cargo run --release -p egui_demo_app
```

结果类似如图 10-4，这取决于你点击了哪些选项。如果你玩一玩这个演示，你会发现这是一个有吸引力的、功能丰富的用户界面库。Rust 社区非常期待有更多像这样的工具包来构建应用程序和游戏。

![图 10-4. egui 演示应用程序的本地执行](../images/f10-4.png)

当你运行 Emil 的演示时，所执行的代码（`src/main.rs`）如图例 10-14（我已经删除了一些配置代码以抑制警告）。注意 `main ()` 方法只在本地编译时使用。

例 10-14. egui 演示应用程序的 main 程序

```rust
// When compiling natively:
fn main () {let app = egui_demo_lib::WrapApp::default ();
  let options = eframe::NativeOptions {
    // Let's show off that we support transparent windows
    transparent: true, ..Default::default ()};
  eframe::run_native (Box::new (app), options);
}
```

对于本地执行，ecui 库有一个可插拔的后端，使用 ecui_glium 库渲染组件。这反过来又使用了一个围绕 OpenGL 的 Rust 包装器 ，称为 Glium [^8]。egui_glium 库是 egui GitHub repo 的一部分。`src/lib.rs` 文件显示了故事的另一部分，如例 10-15 所示（我在这里也删除了一些配置代码以抑制警告）。

例 10-15. egui 演示应用程序的 WebAssembly 入口点

```rust
#[cfg (target_arch = "wasm32")]
use eframe::wasm_bindgen::{self, prelude::*};
/// This is the entry-point for all the web-assembly.
/// This is called once from the HTML.
/// It loads the app, installs some callbacks, then returns.
/// You can add more callbacks like this if you want to call in to your code.
#[cfg (target_arch = "wasm32")]
#[wasm_bindgen]
pub fn start (canvas_id: &str) -> Result<(), wasm_bindgen::JsValue> {let app = egui_demo_lib::WrapApp::default ();
  eframe::start_web (canvas_id, Box::new (app))
}
```

注意到 wasm_bindgen 注释的使用。eframe 库也被用作一种抽象，以隐藏原生或在浏览器中运行的细节。比较一下例子 10-14 中使用的函数和例 10-15 中使用的函数。

为了在网络环境中运行演示应用程序，ecui 使用了一个名为 egui_web 的库。这依赖于 WebGL，通过 WebAssembly 在 HTML 5 画布中渲染组件。

如果你查看 `target/release` 目录，你会看到该应用程序大约有 5.6MB。

```bash
brian@tweezer ~/g/egui> ls -lah target/release
total 11736
drwxr-xr-x	13 brian staff	416B Sep 29 15:56 .
drwxr-xr-x@	5 brian staff	160B Aug 16 11:54 ..
drwxr-xr-x	57 brian staff	1.8K Sep 29 15:55 build
drwxr-xr-x 394 brian staff	12K Sep 29 15:56 deps
-rwxr-xr-x	2 brian staff	5.6M Sep 29 15:56 egui_demo_app
-rw-r--r--	1 brian staff	8.5K Sep 29 15:56 egui_demo_app.d
drwxr-xr-x	2 brian	staff	64B Aug 16 11:53 examples
drwxr-xr-x	2 brian	staff	64B Aug 16 11:53 incremental
-rw-r--r--	1 brian	staff	8.5K Sep 29 15:56 libegui_demo_app.d
-rwxr-xr-x	2 brian	staff	49K Sep 29 15:56 libegui_demo_app.dylib
-rw-r--r--	2 brian	staff	2.0K Sep 29 15:56 libegui_demo_app.rlib
```

如果你看一下文档目录，你会发现，该应用程序的 WebAssembly 版本也已经建立，而且只有 3.5MB。

```bash
brian@tweezer ~/g/egui> ls -lah docs
total 7288
drwxr-xr-x	6 brian	staff	192B Sep 29 15:51 .
drwxr-xr-x	28 brian	staff	896B Sep 29 15:51 ..
-rw-r--r--	1 brian	staff	60K Sep 29 15:51 egui_demo_app.js
-rw-r--r--	1 brian	staff	3.5M Sep 29 15:51 egui_demo_app_bg.wasm
-rw-r--r--	1 brian	staff	222B Aug 16 11:51 example.html
-rw-r--r--	1 brian	staff	2.9K Aug 16 11:51 index.html
```

还有一个`index.html`文件和一些 JavaScript 来引导整个过程。我把大部分的 HTML 留了出来，但是例 10-16 突出了重要的部分。演示程序被赋予了`<canvas>` 元素的 ID，以便将自己呈现在其中。

例 10-16. egui 演示应用程序的 HTML 脚手架

```html
<!-- this is the JS generated by the `wasm-bindgen` CLI tool -->
<script src="egui_demo_app.js"></script>

<script>
// We'll defer our execution until the wasm is ready to go.
// Here we tell bindgen the path to the wasm file so it can start 
//initialization and return to us a promise when it's done. 
  wasm_bindgen ("./egui_demo_app_bg.wasm")
    .then (on_wasm_loaded) 
    .catch (console.error);
  function on_wasm_loaded () {
    // This call installs a bunch of callbacks and then returns. 
    console.log ("loaded wasm, starting egui app"); wasm_bindgen.start ("the_canvas_id");
  }
</script>
```

如果你在 docs 目录下启动一个 HTTP 服务器，并将你的浏览器指向你选择的端口，你可以看到的结果如图 10-5 所示。

```bash
brian@tweezer ~/g/e/docs> python -m http.server 10003 
Serving HTTP on :: port 10003 (http://[::]:10003/) ...
```

![图 10-5. 浏览器执行 egui 演示应用程序](../images/f10-5.png)

如果你对这一切是如何运作的感兴趣，我鼓励你去钻研我提到的各种库。这里到处都是有用的指针和文件，包括创建你自己的自定义小工具的技巧。

该演示应用程序相当复杂，作为一种入门手段，让人不知所措，但为了让你了解一下代码的样子，请看例 10-17，这是从 GitHub 文档中摘录的。

例 10-17. 构建一个简单应用程序的代码片断

```rust
ui.heading ("My egui Application");
ui.horizontal (|ui| {ui.label ("Your name:");
  ui.text_edit_singleline (&mut name); 
});
ui.add (egui::Slider::new (&mut age, 0..=120).text ("age")); 
if ui.button ("Click each year").clicked () {age += 1;}
ui.label (format!("Hello '{}', age {}", name, age));
```

这个代码样本的结果如图 10-6 所示。

![图 10-6. 示例代码的渲染形式](../images/f10-6.png)

如果你对使用 egui 构建自己的应用程序感兴趣，可以在本地或浏览器中运行，Emil 提供了一个 [项目模板](https://github.com/emilk/eframe_template)。只要 fork 这个项目库（或使用 GitHub 模板来创建你自己的项目库），并按照说明进行操作就可以了。

我希望你会觉得这个库和它的相关基础结构很有趣。我更想说的是，它代表了对软件的有意设计，以便同时针对本地和基于浏览器的应用交付。我希望在不久之后能看到更多这样的方法。

[wasm-bindgen 指导手册](https://rustwasm.github.io/wasm-bindgen/) 有更多令人兴奋的例子，你可以从 Rust 中直接与浏览器功能进行交互，包括渲染到一个 `<canvas>` 元素，做 WebGL，以及直接操作 DOM。也有一些例子用于 [在 Deno 中从 TypeScript 的 Rust 中调用 JavaScript 代码](https://github.com/rustwasm/wasm-bindgen/tree/main/examples/deno)。我们将在第 12 章中讨论如何使用 wasm-bindgen 来支持 Rust 中的线程。

正如你所看到的，Rust 本身就是一种现代的、令人兴奋的编程语言。它可以生成 WebAssembly 代码也非常酷，但如果没有 wasm-bindgen 的支持，要建立起任何重要的东西仍然相当困难。不过，有了这个有点神奇的工具，Rust 可以以令人惊讶和意外的方式驱动浏览器的行为。

但现在，我们必须大跃进，进入一个更普遍的策略，使 WebAssembly 应用程序更加可移植。

## 注释

[^1]: Ken Thompson 是 B 编程语言的创造者，它是 C 语言的前身，他还发明并实现了大部分的 Unix 操作系统。Rob Pike 是一位作家和程序员，参与了 Unix 的开发和影响 Go 的后续项目，如 Plan 9。
[^2]: 有很多地方可以读到关于 Rust 的流行，但这篇来 [自 Nature 的文章](https://www.nature.com/articles/d41586-020-03382-2) 是一篇很酷的文章。
[^3]: 对于好奇的你，你可以在 [Rust 网站](https://doc.rust-lang.org/book/ch19-06-macros.html) 中找到更多关于宏的信息。
[^4]: [类型推导](https://en.wikipedia.org/wiki/Type_inference)是一种程序特征，它允许编译器或运行时推断出一个值的类型，而不告诉它是什么。

[^5]: 这些社区的东西非常重视开发者体验，它们将使你很快学会和热爱 Rust 编译器。
[^6]: Kent Beck 推广了一个令人回味的短语——[code smell](https://en.wikipedia.org/wiki/Code_smell)。意思是说，你可以在知道代码中有问题之前就感觉到它的存在，因为你会发现其中的暗示。当食物变坏时，你往往在意识到它之前就已经闻到了。代码也是如此。
[^7]: GitHub repo 解释了他为什么对即时模式的方法感兴趣。
[^8]: Glium 库目前没有人维护，所以 Emil 正计划在某个时候替换它。
