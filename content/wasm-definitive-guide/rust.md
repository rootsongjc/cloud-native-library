---
linktitle: 第 10 章：Rust
summary: "这篇文章是《WebAssembly 权威指南》一书的第十章，介绍了如何使用 Rust 和 WebAssembly 来开发高性能的 Web 应用。Rust 是一种系统编程语言，具有安全、并发和零成本抽象的特点。WebAssembly 是一种二进制格式，可以在浏览器中运行，提供了接近原生的性能和可移植性。文章讲解了 Rust 和 WebAssembly 的基本概念和优势，以及如何使用 wasm-bindgen 库和工具来实现 Rust 和 JavaScript 之间的互操作。"
weight: 11
icon: book-reader
icon_pack: fas
draft: false
title: Rust
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

> 译者注：这是《WebAssembly 权威指南》一书的第十章，介绍了如何使用 Rust 和 WebAssembly 来开发高性能的 Web 应用。Rust 是一种系统编程语言，具有安全、并发和零成本抽象的特点。WebAssembly 是一种二进制格式，可以在浏览器中运行，提供了接近原生的性能和可移植性。文章讲解了 Rust 和 WebAssembly 的基本概念和优势，以及如何使用 wasm-bindgen 库和工具来实现 Rust 和 JavaScript 之间的互操作。
>

本章的目的是帮助读者了解结合使用 Rust 和 WebAssembly 的好处，以及如何快速开发高性能、跨平台的 Web 应用程序。

在我职业生涯的某个时刻，我不再关心新的编程语言。 似乎总是有新的语言出现。 大多数时候，我对它们根本不感兴趣。 现在，一种新的编程语言必须比以前的语言有足够的优势来吸引我们的注意力，并且值得付出努力，投资工具链等等。

大约在这个时候，我开始注意到 Go 和 Rust，并将它们放在同一个概念空间中：提供与 C 和 C++ 大致相似的速度的系统语言，但还包含使它们更安全的语言特性。 由于我一直是 Unix 用户，我对 Ken Thompson 和 Rob Pike 对 Go 的参与很感兴趣[^1]。 我也很高兴看到一些对 Plan 9 想法的支持。 所以我付出了一些努力来学习 Go，很高兴我做到了。 我觉得没必要同时学 Rust，因为我觉得它们是一回事。

然后，我对 WebAssembly 产生了兴趣。

当我听说 Rust 可以在后端生成 WebAssembly 时，我知道我需要更深入地挖掘。 那时我了解了 Rust 语言、它的社区、工具和文档，并且有点爱上了它。 不要误会我的意思，我也喜欢 Go 社区和这门语言，但是 Rust 和 WebAssembly 之间的关系引起了我的兴趣并延续至今。

到目前为止，在本书中，我们主要关注 C 和 C++ 与 WebAssembly 之间的关系。 这是迈向不同语言的重要的第一步。 Rust 是一种具有现代精神的语言。 它提供了良好的运行时性能和几乎不可能事后想到的安全规范。 鉴于 C 和 C++ 在我们每天面对的错误、错误和恶意软件攻击中仍然扮演着重要角色，拥有一种快速、安全的系统语言是一项重大改进。 在长期成为开源社区的宠儿之后，这些好处开始对商业开发人员变得显而易见，并且对 Rust 的兴趣持续增长。

C 和 C++ 显然在我们的行业中仍然扮演着重要的角色，但如果让我选择一个新项目，我会选择 Rust。 它真的成为了镇上的新生事物，所以在我们了解 Rust 和 WebAssembly 之间的相互作用之前，让我们先了解一下原因。

## Rust 简介

鉴于本书的篇幅，我无法在这本书中教你 Rust。 为此，我鼓励你查看 Steve Klabnik 和 Carol Nichols 的免费书籍 [The Rust Programming](https://doc.rust-lang.org/stable/book/) 或 Jim Blandy、Jason Orendorff 和 Leonora FS Tindall (O'Reilly) 的著作 [Programming Rust](https://www.oreilly.com/library/view/programming-rust-2nd/9781492052586/)。

Rust 最初是 Mozilla 的 Graydon Hoare 的一个副项目，但已经发展成为一种改变行业的语言，在谷歌、微软、苹果和其他领先的技术公司中获得了关注。 他们感兴趣的原因有很多，但采用的主要动力是它是一种快速、安全、现代的语言。 它最初是作为低级库和操作系统服务的系统编程语言，甚至开始在 Linux 内核扩展中找到自己的位置。

许多错误都是通过语言中的一系列基本设计来解决的。 在其他语言中表现为运行时错误的问题在 Rust 中变成了编译时错误。 不幸的是，该语言的学习曲线相当陡峭。 你可能会遇到莫名其妙的问题，从 Rust 编译器中抛出错误，一开始可能会非常沮丧。 我把这种经历比作青少年经历的成熟过程。

刚开始，十几岁的时候，对你的期望不高，慢慢地，对你的期望越来越高，直到你突然长大成人。 这个过渡过程可能是痛苦和令人沮丧的。 作为一名开发人员，Rust 编译器希望你能够清楚地沟通并表明你的意图，以便它可以做出相应的反应。 像 JavaScript 这样的语言对你没有这样的要求，所以根据你的背景，这可能有点令人反感。

然而，虽然你最初可能会对 Rust 编译器期望你达到的成人水平感到恼火，但它很快就会成为一种人们喜爱的语言。 它在过去几年赢得了多项最受喜爱的语言调查，因此攀登陡峭的学习曲线显然是一次有益的经历[^2]。 一旦青少年成为年轻人，即使有额外的期望，也很少有人渴望回到年轻时候的自己。

假定你已经按照 [附录](../appendix/) 中的详细信息安装了 Rust。 我们可以很容易地处理像“Hello World!”这样的程序。 如例10-1所示。

例 10-1. Rust "Hello, World!"

```rust
fn main () {println! ("Hello, World!");
}
```

这里我们有一个 `main()` 方法和将字符串打印到控制台的能力。 虽然它看起来像是一个强调的名称，但感叹号只是将其标记为一个宏，一种我们没有时间探索的语言功能 [^3]。 你可以将其视为 C 语言中的 `printf()` 或 Java 中的 `System.out.println()`。 编译和运行这个简单的程序就像编写以下命令一样简单。

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

我们将一个字符串分配给变量 s。 Rust 对类型非常挑剔，但并非不必要地挑剔。 当它可以使用类型推断来计算出变量应该是什么类型时，就不需要啰嗦了[^4]。 Rust 编译器可以看到这里分配了对字符串的引用。 然后我们改变主意，用另一个字符串引用覆盖该值，并打印出新值。 这在几乎任何其他编程语言中都是正确的。 但是在 Rust 中却不行。

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

此错误消息中发生了很多事情。 因为 Rust 团队意识到其陡峭的学习曲线，他们花了很多时间来确保错误消息是有用的 [^5]。

第一条错误消息只是说第一个赋值没有意义，因为你在读取它之前立即覆盖了该值。 这只是一个观察，表明存在潜在的代码味道 [^6]。 如果你不想看到这个警告，你可以禁止它，但它默认指出这些问题，这很好。

真正的问题是 Rust 变量默认是不可变的。 一旦你分配了一个值，你就不能改变它。 这似乎是一种奇怪的策略，但它会迫使你明确说明要更改的变量是可变的。 有一大类错误涉及无意覆盖变量。 在测试失败或出现运行时问题之前，你可能不会注意到你已经这样做了。

显然，我们需要 Rust 中的变量； 你只需要告诉编译器这是你想要的，如示例 10-3 所示。

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

一开始你可能会因为必须如此清晰地交流而感到恼火，但 Rust 编译器只是在教你如何做一个成年人，交流对于幸福和成功至关重要。

我们再看一个在编写 Rust 时可能绊倒你的例子。 在例 10-4 中，我们有一个简单的程序。 我们把一个字符串的字面意义赋值给了一个变量 s，然后再把它赋值给了一个变量 t，然后才把这两个词打印出来。

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
fn main () {
  let s = "Hello, world.".to_string ();
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

这看起来并不多，但是通过添加对 `to_string()` 方法的调用，我们违反了 Rust 的内存检查器。 这是因为我们将字符串文字转换为堆分配的字符串。 堆栈是分配与当前函数相关的短期变量的地方，以便在它们离开词法范围时（即在函数末尾）可以轻松清除它们。 堆分配的内存分配给它，直到不再需要它为止。 在 C 和 C++ 中，作为程序员，你通常必须自己管理这个过程。 在 Java 和 JavaScript 环境中，运行时的垃圾收集器会为你完成这项工作。

Rust 通过强制执行值的所有权来管理运行时垃圾收集器的缺失。 无论何时，只有一个变量可以拥有与堆分配值关联的内存。 在例 10-5 中，我们首先将字符串的所有权分配给变量 s，当我们将 s 分配给 t 时所有权发生了转移。 在这一点上，s 不再指向任何有效的东西，所以我们在 `println!` 宏中使用 s 的尝试被认为是违规的。

字面值和其他构造可以实现上面错误消息中提到的复制功能。 这是一种允许将相关位从一个变量复制到另一个变量而不会导致所有权转移的行为。 因为 Rust 字符串结构不实现此功能，所以所有权检查适用。 发生所有权转移的其他情况包括变量传入或传出函数、循环和其他词汇结构（如条件）。

好消息是，通过更明确地说明我们的意图，可以在不引入新风险的情况下规避这个问题。 我们试图避免的具体风险是初始化前使用、释放后使用以及 C 和 C++ 等语言中的其他常见错误。 我们可以使用引用而不是直接访问，这允许我们“借用”一个值。 我们也可以有可变引用，但一次只能有一个。 这些功能有点像 Java 等语言中的读/写锁。

一旦我们能够更好地传达我们的意图，Rust 编译器就可以帮助我们实现我们的目标，而不是一直与我们作对。 最终效果是 Rust 将一些运行时错误移到了编译时，在这里处理它们更恰当。 这消除了更广泛的错误，使我们能够生产更高质量的软件，包括在系统开发中有用的快速、高度并发的代码类型。

不过，使用 Rust 不仅仅是被编译器打扰。 一旦你通过了语言功能、工具和社区方面的学习曲线，它就会很有趣。 Rust 的速度、安全性以及它构建在 LLVM 之上的事实使其成为与 WebAssembly 配对的完美语言。

## Rust 和 WebAssembly

如果你按照 [附录](../appendix/) 中的说明安装了 Rust，那么你已经具备了使用 Rust 的 WebAssembly 的基础知识。 正如我之前提到的，最初激起我对 Rust 的好奇心的是 Rust 对 WebAssembly 的原生支持。

从图 5-1 中可以看到 LLVM 提供了一个三阶段架构。 由于 Rust 是一种基于 LLVM 的语言，它基本上只需要一个新的后端来支持 WebAssembly。 这不完全正确，但目前你可以这样理解。

你可以通过执行以下命令查看安装了哪些后端：

```bash
brian@tweezer ~/g/w/img> rustup target list | grep installed 
wasm32-unknown-unknown (installed)
x86_64-apple-darwin (installed)
```

Rust 后端被标记为三元组——指令集架构 (ISA)、供应商和操作系统。 我在 Intel Mac 上运行此命令，因此你可以看到相应的默认后端。 但你也可以注意到 WebAssembly 后端已经安装。 由于它生成的代码是针对 WebAssembly 堆栈机器的，因此我们不是在谈论 x86_64、arch64、arm7 或 riscv64。 因为这段代码是可移植的，所以它运行在哪台机器上都无关紧要，这就是为什么用 unknown-unknown 来填充三者之间的原因。

在例 10-6 中，你会看到添加两个数字的代码（Rust 中的 i32）和测试该行为的 `main()` 方法。

例 10-6. 将两个整数相加的 Rust 函数

```rust
pub extern "C" fn add (x: i32, y: i32) -> i32 {x + y}

fn main () {println!("2 + 3: {}", add (2,3));
}
```

使用默认的后端，查看这个代码的本地 Rust 版本的构建和运行结果：

```bash
brian@tweezer ~/g/w/s/ch10> rustc add.rs
brian@tweezer ~/g/w/s/ch10> ./add
2 + 3: 5
```

将相同的代码编译成 WebAssembly 模块就像选择 WebAssembly 后端并指示我们要生成 C 动态库一样简单。 你可以删除主函数或添加编译器指令来抑制死代码错误，如下所示。

```bash
brian@tweezer ~/g/w/s/ch10> rustc -A dead_code --target wasm32-unknown-unknown -O --crate-type=cdylib add.rs -o add.wasm
```

使用 wasm3 运行时执行我们的函数：

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

哇，与本地文件相比，这是一个相当大的文件。 这又是因为期望 Rust 编译器需要在 WebAssembly 的上下文中执行此代码。 本机构建可以依赖本机动态库来提供所需的功能。 你应该记得如何检查 Wasm 模块的内容：

```bash
brian@tweezer ~/g/w/s/ch10> wasm-objdump -x add.wasm
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

你可能已经猜到了，我们也可以通过典型的 HTML/JavaScript 组合来调用它，可以说是不费吹灰之力，如例 10-8 所示。

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

在图 10-1 中，你可以看到在浏览器中调用 JavaScript 函数的结果。 当然，不同之处在于它最初是用 Rust 编写的，而不是我们一直使用的 C 和 C++。

![图 10-1. 在 HTML 中调用 Rust](../images/f10-1.png)

如果我们要谈论的只是 Rust 和 WebAssembly，那就不会那么令人兴奋了。 幸运的是，多亏了 wasm-bindgen，事情很快变得有趣多了。

## wasm-bindgen

在后续章节中，我将向你介绍最小可行产品（MVP）将提供的几个功能。 这些特性包括引用更复杂的结构，例如字符串和列表、对线程的支持、多值返回类型等等。 在那之前，wasm-bindgen 在高层桥接 JavaScript 和 Rust 方面有很大帮助，这样你就可以跨越鸿沟传递数据，而不仅仅是数字。 这个工具并不打算只在 Rust 中使用，但到目前为止我们已经看到了它的好处。

如果你按照 [附录](../appendix/) 中的描述安装了 wasm-bingen 和 wasm-pack，你应该拥有本章剩余部分所需的一切。 后者不是必需的，但它使事情变得更容易，所以我们将从使用它的打包功能开始。

wasm-bindgen 的“Hello, World！” 是从 Rust 中调用 `alert()` JavaScript 方法，而不是直接在 WebAssembly 中导入该方法。 正如你很快就会看到的，浏览器的全部功能已在 Rust 中解锁并可用。 更神奇的是，它看起来像是全部用 Rust 编写的。 此外，你将能够与 JavaScript 共享 Rust 代码，并使其看起来像 JavaScript。 我使用过多种语言间桥接技术，这是我见过的最好的技术之一。

第一步是使用 cargo build 工具创建一个 Rust 库项目。 这将搭建基本项目：

```bash
brian@tweezer ~/src> cargo new --lib hello-wasm-bindgen 
Created library `hello-wasm-bindgen` package
```

你可以覆盖 `src/lib.rs` 文件中的默认代码，使之如例 10-9 所示。

例 10-9. 与 wasm-bindgen 一起使用我们的库

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern {pub fn alert (s: &str);
}

#[wasm_bindgen]
pub fn say_hello (name: &str, whom: &str) {alert (&format!("Hello, {} from {}!", name, whom));
}
```

它比我们目前在 Rust 中看到的要复杂一些，但还算不错。 第一行导入 `wasm_bindgen::prelude` 模块的内容，因此我们可以在 Rust 代码中使用它。 这包括一些将我们连接到 JavaScript 运行时的绑定代码。

下一行是 Rust 属性名称，`#[wasm_bindgen]`。 这表明我们计划调用一个名为 `alert()` 的外部函数。 这是我们使用前面提到的 use 语句从 prelude 导入的函数之一。 你可能会觉得很熟悉。 这将最终调用同名方法，你可能已经从 JavaScript 调用过多次。 不过请注意签名。 这不是 JavaScript 函数。 从我们的角度来看，我们只是从我们的 Rust 代码中调用一个 Rust 函数。 wasm-bindgen 提供的桥梁是如此无缝，以至于我们此时甚至不需要考虑其他语言。

“Hello, World！” 示例也以另一种方式工作。 我们想从 JavaScript 调用 Rust。 下一个 `#[wasm_bindgen]` 属性应用于我们库中定义的 Rust 函数，该函数接受两个字符串片段。 我们使用 Rust 的 `format!` 宏，相当于其他语言中的字符串格式化函数。 我们获得对返回字符串的引用，并将其传递给之前确定的 `alert()` 函数。 此属性将生成等效的 JavaScript 函数以从该端调用。 从它的角度来看，它将调用 JavaScript，而不是 Rust！ 相同的属性使我们在任一方向上保持同步，这非常了不起。

下一步是使用 wasm-pack 生成我们的支持代码。 为此，我们需要更新 `Cargo.toml` 以表明我们想要生成 C 语言动态库样式的输出，为此我们需要 wasm-bindgen 作为依赖项，如示例 10-10 所示。

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

现在我们可以使用 wasm-bindgen 生成一个 JavaScript 模块来包装我们的 Rust 代码。 我已经删除了一些关于缺少属性和 README 文件的警告，因为除了一些可爱的小表情符号，这些都不能很好地翻译。

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

我们使用了 `--target web` 标志来表示我们希望我们的包被加载到浏览器中。 其他选项包括使用 Webpack 捆绑所有内容，或者以 Node.js 或 Deno 为目标，我们很快就会看到。 在 pkg 目录中，你将看到生成的 JavaScript、我们的 Wasm 模块和一个 `package.json` 文件。 我们的代码还有一个 TypeScript 声明文件。 如果你使用 wasm-objdump 并查看我们模块的导出部分，你将看到以下内容。

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

如果像我们之前那样通过 HTTP 提供 HTML 文件，你应该看到如图 10-2 所示的内容。 这是通过 wasm-bindgen 生成的导出函数调用 Rust 的 JavaScript，它又通过浏览器中 wasm-bindgen 生成的 JavaScript 功能的 Rust 包装器调用 JavaScript。

尽管结果平平，但令人满意，因为由此产生的两种语言之间的桥梁从任何一方看起来都很自然。 在 Rust 中，考虑字符串片段要容易得多，而不是像以前那样将字节写入内存中的实例。

好了，现在我们已经介绍了基础知识，让我们尝试一些更有趣的事情。 我真的很喜欢 Rust 的模式匹配支持。 其他语言也有这个特性，但我非常喜欢 Rust 的做法。 请参见示例 10-12。 你将看到的第一个代码块上的 `#[wasm_bindgen]` 属性表示我们要从 JavaScript 调用一个名为 `log()` 的方法。 注意第二个内部属性，其 js_namespace 是控制台。 这表明我们可以直接从 Rust 调用 `console.log()`，这要感谢 wasm-bindgen。

例 10-12. Rust 模式匹配实践

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

在为我们提供 Rust 中的 log() 方法之后，我们定义了一个名为 `describe_location()` 的函数，它接受两个 f32 并将其与我们的大概位置进行比较。 为了简化比较并且不泄露太多位置细节，我只比较当前位置的整数部分（38N，-121W）。 为了适应这一点，我将传入的浮点数转换为整数，然后导入允许我比较整数的函数。 截断的“i_lat”值与我的纬度进行比较，“i_lon”值与我的经度进行比较。 结果被放入 Rust 元组中，它与 Python 元组一样，是一种将一个或多个值放入结构中的轻量级方法。

然后，当另一个位置与我的位置进行比较时，该元组中的值将与各种可能性进行匹配。 如果 `cmp()` 返回两个相等的值，那么位置就在我附近。 如果纬度相等但经度不同，那么另一个位置在我的东边或西边。 我们这里有一个非常紧凑但可读的方法，适用于九种不同的情况。 如果将其表示为一堆嵌套的 if-then 子句，则更难阅读。

一旦我们生成了相对位置的描述，我们就调用日志函数来打印结果。 由于这最终是 `console.log()` 函数，结果将打印在浏览器的开发人员控制台中。

下一步是构建我们的包，导入 HTML 和 JavaScript：

```bash
brian@tweezer ~/s/geo-example> wasm-pack build --target web [INFO]: Checking for the Wasm target...
[INFO]: Compiling to Wasm...
  Compiling geo-example v0.1.0 (/Users/brian/src/geo-example)
    Finished release [optimized] target (s) in 0.51s
[INFO]: Optimizing wasm binaries with `wasm-opt`...
[INFO]:  Done in 1.01s
[INFO]:  Your wasm pkg is ready to publish at /Users/brian/src/geo-example/pkg.
```

在示例 10-13 中，我们看到了 HTML 和 JavaScript 调用我们的行为。 我们导入这些函数，然后调用 JavaScript 函数来测试地理定位对象在浏览器上是否可用。 如果是这样，我们会询问当前位置，这会触发弹出窗口以供用户批准。 如果给出一个位置，结果将显示为占位符段落元素的 innerText，我们在 Rust 中调用 `describe_location()` 方法进行模式匹配。

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

## 构建可同时在浏览器内部和外部运行的程序

我想介绍的最后一部分是另一个 WebAssembly 用例，我认为它会越来越受欢迎。 我们已经研究过在浏览器中使用 JavaScript 以外的语言。 我们还讨论了在基于浏览器的运行时中重用现有代码的情况。 但是设计用于在浏览器内部和外部工作的代码呢？ 我认为，一旦越来越多对 WebAssembly 所提供的功能感到满意，这种情况就会越来越普遍。

自从我关注 WebAssembly 以来，我就一直期待着这种活动，但我对 Emil Ernerfeldt 的 [egui library](https://github.com/emilk/egui) 感到惊讶。 他将该项目描述为“一个易于使用的纯 Rust 即时模式 GUI”[^7]。 它是一个复杂的用户界面库，可在浏览器内部和外部运行。

我们在本章中多次提到，Rust 允许我们生成各种后端目标，从而从其 LLVM 继承中获益。 这就是 Emil 正在利用这个优势实现的作品。 但他做得很优雅，我认为他有很多值得学习的地方。 他如何做到这一点的全部细节超出了本章的范围，但我想提请你注意这个项目，以防重复工作。

首先，让我们看看将应用程序作为本机应用程序运行。 如果你使用的是 Linux，则必须安装 GitHub 站点上列出的更多软件包，但之后，你就可以运行了。

```bash
brian@tweezer ~/g/egui> cargo run --release -p egui_demo_app
```

结果如图 10-4 所示，这取决于你点击了哪些选项。如果你玩一玩这个演示，你会发现这是一个有吸引力的、功能丰富的用户界面库。Rust 社区非常期待有更多像这样的工具包来构建应用程序和游戏。

![图 10-4. egui 演示应用程序的本地执行](../images/f10-4.png)

当你运行 Emil 的演示时，所执行的代码（`src/main.rs`）如图例 10-14（我已经删除了一些配置代码以抑制警告）。注意 `main ()` 方法只在本地编译时使用。

例 10-14. egui 演示应用程序的 main 函数

```rust
// When compiling natively:
fn main () {let app = egui_demo_lib::WrapApp::default ();
  let options = eframe::NativeOptions {
    // Let's show off that we support transparent windows
    transparent: true, ..Default::default ()};
  eframe::run_native (Box::new (app), options);
}
```

对于本机执行，ecui 库有一个可插入的后端，它使用 ecui_glium 库来渲染组件。 这反过来又使用了一个名为 Glium [^8] 的 OpenGL Rust 包装器。 egui_glium 库是 egui GitHub 存储库的一部分。 `src/lib.rs` 文件显示了另一部分，如示例 10-15 所示（我还删除了此处的一些配置代码以抑制警告）。

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

注意 wasm_bindgen 注释的使用。 eframe 库也用作抽象来隐藏本机或在浏览器中运行的细节。 将例 10-14 中使用的函数与例 10-15 中使用的函数进行比较。

为了在 Web 环境中运行演示应用程序，ecui 使用了一个名为 egui_web 的库。 这依赖于 WebGL 通过 WebAssembly 在 HTML 5 画布中呈现组件。

如果查看 `target/release` 目录，你会看到该应用程序大约有 5.6MB。

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

如果你看一下 `docs` 目录，你会发现，该应用程序的 WebAssembly 版本也已经建立，而且只有 3.5MB。

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

还有一个 `index.html` 文件和一些 JavaScript 来引导该过程。 我省略了大部分 HTML，但例 10-16 突出显示了重要的部分。 演示程序给出`<canvas>` 在其中呈现自身的元素的 ID。

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

如果你在 `docs` 目录下启动一个 HTTP 服务器，并将你的浏览器指向你选择的端口，你可以看到的结果如图 10-5 所示。

```bash
brian@tweezer ~/g/e/docs> python -m http.server 10003 
Serving HTTP on :: port 10003 (http://[::]:10003/) ...
```

![图 10-5. 浏览器执行 egui 演示应用程序](../images/f10-5.png)

如果你对这一切的工作原理感兴趣，我鼓励你深入研究我提到的各种库。 那里面充满了有用的指导和文档，包括创建你自己的自定义小部件的技巧。

演示应用程序非常复杂，作为一种入门方式让人不知所措，但为了让你了解代码的概要，请参阅示例 10-17，摘自 GitHub 文档。

例 10-17. 用于构建简单应用程序的代码片段

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

我希望你会发现这个库及其相关的基础设施很有趣。 我宁愿说它代表了针对本机和基于浏览器的应用程序交付的软件的深思熟虑的设计。 我希望在不久的将来看到更多这样的方法。

[wasm-bindgen 食谱](https://rustwasm.github.io/wasm-bindgen/) 有更多令人兴奋的示例，说明如何从 Rust 中直接与浏览器功能交互，包括渲染到 `<canvas>` 元素，做 WebGL，直接操作 DOM。 还有[在 Deno 中从 TypeScript 的 Rust 调用 JavaScript 代码](https://github.com/rustwasm/wasm-bindgen/tree/main/examples/deno) 的示例。 我们将在第 12 章讨论如何使用 wasm-bindgen 来支持 Rust 中的线程。

如你所见，Rust 本身就是一种现代且令人兴奋的编程语言。 它可以生成 WebAssembly 代码也很酷，但是如果没有 wasm-bindgen 支持，它仍然很难构建任何重要的东西。 不过，借助这个有点神奇的工具，Rust 可以以令人惊讶和意想不到的方式驱动浏览器行为。

但现在，我们必须迈出一大步，采用更通用的策略，使 WebAssembly 应用程序更具可移植性。

## 注释

[^1]: Ken Thompson 是 B 编程语言的创造者，它是 C 语言的前身，他还发明并实现了大部分的 Unix 操作系统。Rob Pike 是一位作家和程序员，参与了 Unix 的开发和影响 Go 的后续项目，如 Plan 9。
[^2]: 有很多地方可以读到关于 Rust 的流行，但这篇来 [自 Nature 的文章](https://www.nature.com/articles/d41586-020-03382-2) 是一篇很酷的文章。
[^3]: 对于好奇的你，你可以在 [Rust 网站](https://doc.rust-lang.org/book/ch19-06-macros.html) 中找到更多关于宏的信息。
[^4]: [类型推导](https://en.wikipedia.org/wiki/Type_inference)是一种程序特征，它允许编译器或运行时推断出一个值的类型，而不告诉它是什么。

[^5]: 这些社区的东西非常重视开发者体验，它们将使你很快学会和热爱 Rust 编译器。
[^6]: Kent Beck 推广了一个令人回味的短语——[code smell](https://en.wikipedia.org/wiki/Code_smell)。意思是说，你可以在知道代码中有问题之前就感觉到它的存在，因为你会发现其中的暗示。当食物变坏时，你往往在意识到它之前就已经闻到了。代码也是如此。
[^7]: GitHub repo 解释了他为什么对即时模式的方法感兴趣。
[^8]: Glium 库目前没有人维护，所以 Emil 正计划在某个时候替换它。
