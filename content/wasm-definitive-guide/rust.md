---
linktitle: 第 10 章：Rust
summary: Rust。
weight: 11
icon: book-reader
icon_pack: fas
draft: true
title: Rust
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

> 街上有议论，那是为了提醒你
> 你站在哪一边并不重要
> 你走了，他们在你身后说话
> 他们永远不会忘记你，直到有新的人出现
> ——老鹰乐队，"New Kid in Town"

在我职业生涯的一个时期，我不再关心新的编程语言。似乎总是新的语言出现。大多数时候，我对它们丝毫不感兴趣。现在，一种新的编程语言必须比以前的语言有足够的优势，才能吸引我们的注意力，值得我们努力学习，投资于工具链等等。

大约在这个时候，我开始注意到Go和Rust，我把它们放在同一个概念空间里：系统语言提供了与C和C++大致相似的速度，但也包含了使它们更安全的语言特性。由于我一直是一个Unix用户，我被Ken Thompson和Rob Pike对Go的参与所吸引[^1]。我也很高兴看到Plan 9的一些想法得到了一些支持。因此，我付出了一些努力来学习Go，很高兴我做到了。我不认为有必要同时学习Rust，因为我认为它是相同的东西。

然后，我对WebAssembly产生了兴趣。

当我听说Rust可以在后端发出WebAssembly时，我知道我需要更深入地研究。这时我了解了Rust语言、它的社区、工具和文档，并有点爱上了它。不要误会我的意思，我喜欢Go社区和语言也是如此，但Rust和WebAssembly之间的关系使我的兴趣大为转移，而且我一直没有回头。

到目前为止，在本书中，我们主要关注的是C和C++与WebAssembly之间的关系。这是迈向不同语言的第一个重要步骤。Rust是一种具有现代精神的现代语言。它提供了良好的运行时性能和一个安全规范，这几乎是不可能作为一个事后的想法而产生的。鉴于C和C++在我们每天面临的错误、缺陷和恶意软件的利用方面仍然发挥着重要作用，拥有一种快速、安全的系统语言是一种实质性的改进。在长期作为开源社区的宠儿之后，这些好处已经开始对商业开发者变得明显，而且对Rust的兴趣也在不断增长。

C和C++显然在我们的行业中仍然扮演着重要的角色，但是，如果让我选择新的项目，我反而会选择Rust。它确实已经成为镇上人人都在谈论的新孩子，所以在我们看Rust和WebAssembly之间的相互作用之前，让我们了解一下原因。

## Rust简介

鉴于本书的内容已经很庞大，我无法在本书中教你Rust。为此，我鼓励你去看看Steve Klabnik和Carol Nichols的免费书 [The Rust Programming](https://doc.rust-lang.org/stable/book/) 或 Jim Blandy, Jason Orendorff, and Leonora F.S. Tindall (O'Reilly)的作品 [Programming Rust](https://www.oreilly.com/library/view/programming-rust-2nd/9781492052586/)。

Rust 最初是Graydon Hoare在Mozilla时的一个副业项目，但现在已经演变成了一种改变行业的语言，在谷歌、微软、苹果和其他领先的技术公司中获得了关注。他们感兴趣的原因有很多，但采用的主要动力是它是一种快速、安全、现代的语言。它最初是作为一种用于低级库和操作系统服务的系统编程语言，它甚至已经开始在Linux内核扩展中找到自己的方式。

很多bug是通过语言中一系列基本的设计来解决的。在其他语言中表现为运行时错误的问题在Rust中变成了编译时错误。不幸的是，这门语言有一个相当陡峭的学习曲线。你很可能会遇到莫名其妙的问题，让Rust编译器报错，而且一开始可能会感到相当沮丧。我把这种经历比作青少年经历的成熟过程。

起初，作为一个青少年，人们对你的期望不多，但慢慢地，人们对你的期望越来越多，直到你突然成为一个成年人。这个过渡过程可能是痛苦的，令人沮丧的。作为一个开发者，Rust编译器希望你能清楚地沟通并表明你的意图，以便它能做出相应的反应。像JavaScript这样的语言对你没有这样的要求，所以根据你的背景，可能会有点反感。

然而，尽管你最初可能会对Rust编译器期望你达到的成人化水平感到厌烦，但它很快就会成为一种人们热衷的语言。在过去的几年里，它赢得了几次最受欢迎的语言调查，所以很明显，越过陡峭的学习曲线是一种有益的经验[^2]。一旦青少年成为年轻的成年人，即使有额外的期望，也很少有人会渴望回到年轻时的自己。

假设你已经按照[附录](../appendix/)中的详细说明安装了Rust。我们可以很容易地处理 "Hello World!"这样的程序。如例 10-1 所示。

例10-1. Rust "Hello, World!"

```rust
fn main() {
println! ("Hello, World!");
}
```

在这里，我们有一个`main()`方法和向控制台打印字符串的能力。虽然它看起来像是一个强调性的名字，但感叹号只是标志着这是一个宏，一个我们没有时间去探索的语言特性[^3]。为了我们的目的，就把它看作是C语言中的`printf()`或Java中的`System.out.println()`。编译和运行这个简单的程序就像编写下列命令一样简单。

```bash
brian@tweezer ~/g/w/s/ch10> rustc helloworld.rs 
brian@tweezer ~/g/w/s/ch10> ./helloworld
Hello, World!
```

到目前为止，没有什么大问题，但不需要很长时间就会遇到与Rust的区别。请看例 10-2。

例10-2. Rust不可变的变量

```rust
fn main() {
  let s = "cool"; 
  s = "safe";
  
  println!("Rust is {}", s);
}
```

我们给变量s分配一个字符串。Rust对类型非常挑剔，但也不是不必要地挑剔。当它可以使用类型推理来计算出一个变量应该是什么类型时就没有必要再啰嗦了[^4]。Rust编译器可以看出这里正在分配一个对字符串的引用。然后我们改变主意，用另一个字符串引用覆盖这个值，然后打印出新的值。在几乎任何其他编程语言中，这都是完全可以。在Rust中...

```bash
brian@tweezer ~/g/w/s/ch10> rustc immutable.rs warning: value assigned to `s` is never read
     --> immutable.rs:2:9
      |
2 | let s = "cool";
|^
|
= note: `#[warn(unused_assignments)]` on by default = help: maybe it is overwritten before being read?
    error[E0384]: cannot assign twice to immutable variable `s`
     --> immutable.rs:3:5
      |
2 |     let s = "cool";
|- ||
|
| 3 | |
    first assignment to `s`
    help: make this binding mutable: `mut s`
s = "safe";
^^^^^^^^^^ cannot assign twice to immutable variable
    error: aborting due to previous error; 1 warning emitted
    For more information about this error, try `rustc --explain E0384`.
```

在这个错误信息中发生了很多事情。因为Rust团队意识到 的学习曲线很陡峭，所以他们花了大量的时间来确保错误信息是有帮助的、有信息的[^5]。

第一个错误信息只是说，第一个 赋值没有什么意义，因为你在读取之前就立即覆盖了这个值。这只是一个观察结果，表明一个潜在的代码气味[^6]。如果你不想看到这个警告，你可以抑制它，但它默认指出了这些问题，这很好。
真正的问题是，Rust变量默认是不可变的。一旦你分配了一个值，你就不能改变它。这似乎是一个奇怪的政策，但它迫使你明确当你想改变一个变量的值时，当你不想改变时。有一大类bug涉及到变量的无意覆盖。你可能不会注意到你已经这样做了，直到测试失败或出现运行时问题。

很明显，我们需要Rust中的可变量；你只需要告诉编译器这就是你想要的，正如你在下面看到的那样 例 10-3.

例10-3. 可变的Rust变量
fn main() {
let mut s = "酷"；s = "安全"。

println! ("Rust is {}", s);
}
现在，通过重新编译（并抑制了未使用的赋值警告），我们最终进入了一个更快乐的地方。
brian@tweezer ~/g/w/s/ch10> rustc -A unused_assignments immutable.rs
brian@tweezer ~/g/w/s/ch10> ./immutable
锈是安全的
一开始你可能会因为必须这样清楚地沟通而感到恼火，但是Rust com- piler只是在教你如何成为一个成年人，而沟通对于幸福和成功是至关重要的。
让我们来看看另一个例子，当你开始做 Rust时，可能会绊倒你的东西。在 例10-4中，我们有一个简单的程序。我们把一个字符串的字面意思赋给了一个变量s，然后在打印出这两个字之前把它重新赋给了一个变量t。

例10-4.使用Rust变量
fn main() {
let s = "Hello, world." 。
let t = s; println! ("s: {}", s);
println! ("t: {}", t);
}

这是一件非常合理的事情，我们看到Rust编译器对它没有任何问题。
brian@tweezer ~/g/w/s/ch10> rustc memcheck.rs
brian@tweezer ~/g/w/s/ch10> ./memcheck
s:你好，世界。 T。你好，世界。
然而，只要稍作改动，我们就可以打破这种局面，如图所示 例 10-5.

例10-5.Rust内存检查器违规
fn main() {
let s = "Hello, world.".to_string();
let t = s; println! ("s: {}", s);
println! ("t: {}", t);
}

这个问题在Rust编译器的错误信息中得到了很好的强调。
brian@tweezer ~/g/w/s/ch10> rustc memcheck.rs
error[E0382]: 借用移动的值：`s`。
--> memcheck.rs:4:23
|
2|	let s = "Hello, world.".to_string();
|	- 出现这种情况是因为`s`的类型是`std::string::String`，这
|	没有实现 "复制 "特性。
3|	让t = s。
|		- 值移到这里 4 |	println! ("s: {}", s);
|	^ 移动后在此借用的价值

错误：由于之前的错误而中止

关于这个错误的更多信息，请尝试`rustc --explain E0382`。
这看起来并不多，但通过添加to_string()方法的调用，我们已经违反了Rust的内存检查器， 。这是因为我们把一个字符串字面意思变成了一个堆分配的字符串。堆栈是分配与当前函数相关的短期变量的地方，这样当它们超出lexi-cal范围时（即在函数结束时），它们可以很容易地被清理掉。堆分配的内存一直分配到它 ，不再需要。在C和C++中，作为一个程序员，你通常必须自己管理这个过程。在Java和JavaScript环境中，运行时的垃圾收集器为你做这个。
Rust通过强制执行值的所有权来管理缺乏运行时垃圾收集器的问题。在任何时候，只有一个变量可以拥有与一个堆分配的值相关的内存。在 例 10-5中，我们首先将字符串的所有权分配给了变量s，当我们将s分配给t时，所有权就转移了。在这一点上，s不再指向任何有效的东西，所以我们试图在println！宏中使用s的做法被认为是违规的。
字面值和其他结构可以实现上面错误信息中提到的复制特性。这是一种允许相关位从变量复制到变量而不引起所有权转移的行为。因为Rust字符串结构没有实现这个特性，所以所有权检查适用。其他发生所有权转移的情况包括当变量被传递到

在函数中，在循环中，以及在其他词汇结构（如条件句）中，都可以使用。
好消息是，通过更明确地说明我们的意图，我们可以绕过这个问题而不引入新的风险。我们试图避免的具体风险是初始化前的使用、自由使用后的使用，以及其他诸如C和C++语言中的错误， mon。我们可以使用引用而不是直接访问，这样我们就可以 "借用 "一个值。我们也可以有可变的引用，但一次只能有一个。这些功能有点像Java等语言中的读者/写者锁。
一旦我们能更好地沟通我们的意图，Rust编译器就能协助我们实现我们的目标，而不是一直在和我们作对。最终的效果是，Rust将一些运行时的错误转移到了编译时的错误，这是一个更好的处理它们的地方。这就消除了更多类别的错误，使我们能够产生更高质量的软件，包括在系统开发中有用的快速、高并发的代码类型。
不过，使用Rust的经验不仅仅是被编译器所困扰。有很多语言特性、工具和社区方面，一旦你度过了学习曲线，就会使它成为一种乐趣。Rust的速度、安全性，以及它建立在LLVM之上的特点，使它成为与WebAssembly配对的最佳语言。
Rust和WebAssembly
如果你按照附录中的指示来安装Rust 附录的说明，那么你已经有了用Rust进行WebAssembly的基础知识了。正如我前面提到的，正是Rust对WebAssembly的原生支持，最初激起了我对Rust的好奇心。
你会记得，在 图 5-1中，你看到LLVM提供了一个三阶段的架构， ture。由于Rust是一种基于LLVM的语言，为了支持WebAssembly，它基本上只需要一个新的后台。这并不完全正确，但现在它是一个合适的虚构。
你可以通过发出以下命令查看哪些后端已经安装。
brian@tweezer ~/g/w/img> rustup target list | grep installed
wasm32-unknown-unknown (已安装) x86_64-apple-darwin (已安装)
Rust后端被标记为三要素，表示指令集架构（ISA）、供应商和操作系统。我在Intel Mac上运行该命令，所以你可以看到相应的默认后端。但你也可以注意到，WebAssem- bly后端已经安装。由于它产生的代码是针对WebAssembly堆栈机的，我们不是在谈论x86_64、arch64、arm7或riscv64。因为这段代码是可移植的，所以你打算在哪台机器上运行它并不重要，这就是为什么三者之间用unknown-unknown来填写。

如果你看一下 例 10-6，你会看到将两个数字相加的代码（Rust中的i32）和测试该行为的main()方法。

例10-6.Rust函数为两个整数相加
pub extern "C" fn add(x: i32, y: i32) -> i32 { x + y
}

fn main() {
println! ("2 + 3: {}", add(2,3))。
}

使用默认的后台，你可以查看这个代码的本地Rust版本的构建和运行结果。
brian@tweezer ~/g/w/s/ch10> rustc add.rs
brian@tweezer ~/g/w/s/ch10> ./add
2 + 3: 5
将同样的代码编译成WebAssembly模块，就像选择WebAssembly后端并表明我们要生成一个C动态库一样简单。你可以删除main函数或添加编译器指令来抑制死代码的投诉，如下所示。
brian@tweezer ~/g/w/s/ch10> rustc -A dead_code --target wasm32-unknown-unknown ↵
-O --cate-type=cdylib add.rs -o add.wasm
我们可以使用wasm3运行时在命令上执行我们的函数。
brian@tweezer ~/g/w/s/ch10> wasm3 --func add add.wasm 2 3
错误。[Fatal] repl_call: function lookup failed Error: function lookup failed ('add')
呃......或者不是。
brian@tweezer-2 ~/g/w/s/ch10> ls -laF add*
-rwxr-xr-x	1 brian	工作人员	334920年5月	4 11:54 加*
-rw-r--r--	1 brian	工作人员	5月111日	4 12:07 add.rs
-rwxr-xr-x	1 brian	工作人员	1501227年5月	4 12:16 add.wasm*
哇，与本地文件相比，这是个相当大的文件。这又是因为Rust编译器对在WebAssembly环境下执行这段代码所需的期望。本地版本可以依靠本地动态库来提供所需的功能。在本书的这一点上，你应该记得如何调查Wasm模块的内容。
brian@tweezer ~/g/w/s/ch10> wasm-objdump -x add.wasm
add.wasm:	文件格式wasm 0x1 部分详细信息。

表[1]:
-table[0] type=funcref initial=1 max=1 Memory[1]:
-内存[0]页：初始=16 全局[3]。
-global[0] i32 mutable=1 - init i32=1048576
-global[1] i32 mutable=0 < data_end> - init i32=1048576
-global[2] i32 mutable=0 < heap_base> - init i32=1048576 Export[3]:
-内存[0] -> "内存"
-global[1] -> " data_end"
-global[2] -> " heap_base" Custom:
-name: ".debug_info" Custom:
-name: ".debug_pubtypes" Custom:
-name: ".debug_ranges" Custom:
-name: ".debug_aranges" Custom:
-name: ".debug_abbrev" Custom:
-name: ".debug_line" Custom:
-名称：".debug_str"自定义。
-name: ".debug_pubnames" Custom:
-名称："生产商"
好了，我们有了一堆调试信息和导出的内存什么的，但是没有导出添加函数。我们可以在方法定义中添加一个编译器指令来解决这个导出问题，如下面所示 例 10-7.

例10-7.正确导出两个整数相加的Rust函数
#[no_mangle]
pub extern "C" fn add(x: i32, y: i32) -> i32 { x + y
}

现在，重建并检查结果。你应该看到出口中的添加方法
节。而且我们可以在命令行上调用它。
brian@tweezer ~/g/w/s/ch10> wasm3 --func add add.wasm 2 3
结果：5
你可能已经猜到了，我们也可以通过典型的HTML/JavaScript组合来调用我们的行为，几乎不费吹灰之力，正如我们在 例 10-8.

例10-8.从HTML中调用Rust函数
<！doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<link rel="styleheet" href="bootstrap.min.css">。
<title>Rust和WebAssembly</title>。
<script src="utils.js">/script>
</head>
<body>
<div class="container">
<h1>Rust和WebAssembly</h1>。
2 + 3 = <span id="sum"></span>。
</div>
<script>
fetchAndInstantiate('add.wasm').then(function(instance) {
var add = instance.exports.add(2,3);
var sumEl = document.getElementById('sum'); sumEl.innerText=add。
});
</脚本>
</body>
</html>

在 图10-1中，你可以看到现在熟悉的在浏览器中调用JavaScript函数的结果。当然，不同的是，它最初是用Rust编写的，而不是我们一直使用的C和C++。

图10-1.从HTML中调用Rust
如果这就是我们要谈论的Rust和WebAssembly的全部内容，那就不会有 ，也不会有那么多的兴奋。幸运的是，多亏了wasm-bindgen，事情很快就变得有趣多了。
滨根
在随后的章节中，我将向你介绍几个功能，这些功能将由起草的最小可行产品（MVP）后的提案来解锁。这些功能包括能够引用更复杂的结构，如字符串和列表，支持线程，多值返回类型，以及更多。在那之前，wasm-bindgen在以下方面会有很大帮助

在高水平上连接了JavaScript和Rust，这样你就可以跨越鸿沟传递数据，而不仅仅是数字。这个工具并不打算只用于Rust，但到目前为止，这已经是看到了大部分好处的地方。
如果你已经安装了wasm-bindgen和wasm-pack，如附录中所述。 附录中所描述的那样安装了wasm-bingen和wasm-pack，你就应该拥有本章剩余部分所需的一切。，你应该拥有本章剩余部分所需的一切。后者不是必须的，但它使事情变得更容易，所以我们将从使用它的打包功能开始。
wasm-bindgen的 "Hello, World!"是从Rust中调用alert()JavaScript方法，而不需要在WebAssembly中直接导入方法。正如你将很快看到的那样，浏览器的全部功能都将从Rust中被解锁并使用。更令人惊奇的是，从 ，它将这样做，看起来好像都是用Rust写的。此外，你将能够与JavaScript共享Rust代码，并让它看起来像JavaScript。我曾经使用过几种语言间桥接技术，这是我见过的最好的技术之一。
第一步是使用cargo build工具创建一个Rust库项目。这将为基本项目建立脚手架。
brian@tweezer ~/src> cargo new --lib hello-wasm-bindgen
创建了图书馆`hello-wasm-bindgen`包
你可以覆盖src/lib.rs文件中的默认代码，使之成为如下所示的内容 例 10-9.

例10-9.我们的库与wasm-bindgen一起使用
use wasm_bindgen::prelude::*; #[wasm_bindgen]
外部{
pub fn alert(s: &str);
}

#[wasm_bindgen]
pub fn say_hello(name: &str, whom: &str) { alert(&format! ("Hello, {} from {}!", name, whom);
}

这比我们目前看到的Rust稍微棘手一些，但也不算太糟。第一行导入wasm_bindgen::prelude模块的内容，以便我们可以在Rust代码中使用它。这包括一些绑定代码，它将把我们连接到JavaScript运行环境。
下一行是一个Rust属性名称，#[wasm_bindgen]。这表明我们计划 ，调用一个名为alert（）的外部函数。这是我们用前面提到的使用声明从前奏中导入的功能之一。如果你认为

这个方法听起来很熟悉，你会是对的。这最终将调用同名的方法，你可能已经从JavaScript中调用过很多次了。不过请注意这个签名。这不是一个JavaScript函数。从我们的角度看，我们只是从我们的Rust代码中调用一个Rust函数。wasm-bindgen提供的桥梁是如此无缝，以至于我们在这一点上甚至不需要考虑其他语言。
这个 "Hello, World!"的例子也要走另一条路。从JavaScript，我们要调用到Rust。下一个#[wasm_bindgen]属性被应用于我们库中定义的一个Rust函数，该函数接收两个字符串片断。我们使用Rust的format！宏，它相当于其他语言中的字符串格式化函数。我们获取一个对返回字符串的引用，并将其传递给之前确定的alert()函数。这个属性将生成一个等效的JavaScript函数，以便从世界的那一边调用。从它的角度来看，它将调用Java-脚本，而不是Rust!同一个属性让我们在任何一个方向都保持同步，这相当了不起。
下一步是使用wasm-pack来生成我们的支持代码。为了做到这一点，我们需要更新我们的Cargo.toml，以表明我们要生成一个C语言动态库风格的输出，为此我们需要wasm-bindgen作为一个依赖项，如图所示 例 10-10.

例10-10.Cargo.toml文件
[包装]
name = "hello-wasm-bindgen" version = "0.1.0"
版本="2018"

[lib]
crate-type = ["cdylib"]

[依赖性]
wasm-bindgen = "0.2.73"

现在我们可以使用wasm-bindgen来生成一个包裹我们Rust代码的JavaScript模块。我已经消除了一些关于缺失属性和README文件的警告，因为 ，以及一些可爱的小表情符号，这些都不能很好地翻译。
brian@tweezer ~/s/hello-wasm-bindgen> wasm-pack build --target web
[INFO]:检查Wasm的目标......INFO:编译到Wasm...
编译 hello-wasm-bindgen v0.1.0 (/Users/brian/src/hello-wasm-bindgen)
在0.26秒内完成发布[优化]目标[INFO]。用`wasm-opt`优化wasm二进制文件...[INFO]:在0.73秒内完成
[INFO]:你的wasm pkg已经准备好发布在[INFO]。/Users/brian/src/hello-wasm-bindgen/pkg。

brian@tweezer ~/s/hello-wasm-indgen> ls -laF pkg
共计72
drwxr-xr-x	8 brian	工作人员	256 五月 10 17:20 ./
drwxr-xr-x	9 brian	工作人员	288 五月 10 17:20 .../
-rw-r--r--	1 brian	工作人员	1 五月 10 17:20 .gitignore
-rw-r--r--	1 brian	工作人员	861 五月 10 17:20 hello_wasm_bindgen.d.ts
-rw-r--r--	1 brian	工作人员	4026 May 10 17:20 hello_wasm_bindgen.js
-rw-r--r--	1 brian	工作人员	15786 May 10 17:20 hello_wasm_bindgen_bg.wasm
-rw-r--r--	1 brian	工作人员	291 May 10 17:20 hello_wasm_bindgen_bg.wasm.d.ts
-rw-r--r--	1 brian	工作人员	266 五月 10 17:20 package.json
我们使用了--target web标志，表示我们希望我们的包可以在浏览器中加载。其他的选择包括使用Webpack来捆绑所有东西，或者以Node.js或Deno为目标，我们很快就会看到。在pkg目录中，你将 ，看到生成的JavaScript，我们的Wasm模块，以及package.json文件。还有我们的代码的TypeScript声明文件。如果你使用wasm-objdump并查看我们模块的导出部分，你会看到以下内容。
出口[4]。
-内存[0] -> "内存"
-func[19] <say_hello> -> "say_hello"
-func[34] < wbindgen_malloc> -> " wbindgen_malloc"
-func[38] < wbindgen_realloc> -> " wbindgen_realloc"
这包括一个Memory实例，我们导出的方法，以及一些内存分配函数。
最后一步是在HTML和JavaScript中调用ES6模块，如图所示 例 10-11.

例10-11.从JavaScript中调用Rust
<！DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>hello-wasm-bindgen 示例</title>。
</head>
<body>
<script type="module">
从"./pkg/hello_wasm_bindgen.js "导入init、{say_hello}；init()
.then(() => {
say_hello("Rust", "JavaScript")。
});
</脚本>
</body>
</html>

如果你像我们之前做的那样通过HTTP提供HTML文件，你应该看到如图所示的结果。 图10-2.这是JavaScript通过wasm-bindgen生成的导出函数调用Rust，而Rust又通过浏览器中由wasm-bindgen生成的围绕JavaScript功能的Rust包装器调用Java-Script。

图10-2.从Rust中调用JavaScript
尽管结果很平庸，但这是一个令人满意的结果，因为这两种语言之间产生的桥梁从任何一方看起来都很自然。在Rust中思考字符串片断，而不是像以前那样将字节写入内存实例，这要容易得多。
好了，现在我们已经掌握了基本知识，让我们来试试更有趣的东西。我非常喜欢Rust的一个特点是它的模式匹配支持。其他语言也有这个功能，但我非常喜欢Rust的做法。请看 例10-12.你将看到的第一个 ，是一个代码块上的#[wasm_bindgen]属性，表明我们 ，想从JavaScript调用一个叫log()的方法。注意第二个内部属性，其js_namespace为console。这表明我们可以从Rust中直接调用console.log()，这要感谢wasm-bindgen。

例10-12.实践中的Rust模式匹配
use wasm_bindgen::prelude::*; #[wasm_bindgen]
外部 "C" {
#[wasm_bindgen(js_namespace = console)]
fn log(s: &str);
}

#[wasm_bindgen]
pub fn describe_location( lat : f32, lon : f32 ) {
let i_lat = lat as i32; let i_lon = lon as i32;

使用std::cmp::Ordering::*。

let relative_position = match(i_lat.cmp(&38), i_lon.cmp(&-121)) { (Equal, Equal) => "非常接近！",
(等、大）=>"我的东边"，（等、小）=>"我的西边"，（小、等）=>"我的南边"。
(少，大)=>"我的东南"，(少，小)=>"我的西南"，(大，等)=>"我的北"，(大，大)=>"我的东北"，(大，小)=>"我的西北"
};

log(&format! ("You are {}!", relative_position))。
}
在Rust中为我们提供了log()方法之后，我们定义了一个名为describe_location()的函数，该函数接收两个f32，我们将把它们与我在家里的大致位置进行比较。为了简化比较，不泄露太多关于我在哪里的细节，我只比较我当前位置的整数部分（38N, -121W）。为了适应这种情况，我把传入的浮点数铸成整数，然后导入允许我比较整数的功能 。截断的i_lat值与我的纬度比较，i_lon值与我的经度比较。结果被放入一个Rust元组，它就像Python元组一样，是将一个或多个值放入一个结构的轻量级方式。
然后，当另一个地点与我的地点进行比较时，该元组中的值与各种可能性进行匹配。如果cmp()返回两个相等的值，那么这个位置就在我附近。如果纬度相等但经度不相等，那么另一个位置就在我的东面或西面。我们在这里有一个非常紧凑但可读的方法来处理九个独立的情况。如果这被表达为一堆嵌套的if-then子句，那就更难阅读了。
一旦我们生成了相对位置的描述，我们就调用log函数来打印出结果。由于这最终是console.log()函数，结果将在你的浏览器的开发者控制台中打印出来。
下一步是建立我们的包，在HTML和JavaScript中导入。
brian@tweezer ~/s/geo-example> wasm-pack build --target web
[INFO]:检查Wasm的目标......INFO:编译到Wasm...
编译geo-example v0.1.0 (/Users/brian/src/geo-example)
在0.51秒内完成发布[优化]目标[INFO]。用`wasm-opt`优化wasm二进制文件...[INFO]:在1.01秒内完成
[INFO]:你的wasm pkg已经准备好在/Users/brian/src/geo-example/pkg发布。

在 例10-13中，我们看到了调用我们行为的HTML和JavaScript。我们导入了这些函数，然后调用一个JavaScript函数来测试浏览器上的地理位置对象是否可用。如果有，我们就要求提供当前的位置，这就会触发一个弹出窗口让用户批准。如果给出了位置，结果将显示为占位符段落元素的内部文本，我们在Rust中调用describe_location()方法来进行模式匹配。

例10-13.从HTML中调用Rust模式匹配
<！DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>解析-示例</title>。
</head>
<body>
<script type="module">
从"./pkg/parsing_example.js "导入init、{describe_location}；init()
.then(() => { getLocation();
});

var output = document.getElementById("output");

函数 getLocation() {
如果（navigator.geolocation）{ navigator.geolocation.getCurrentPosition(showPosition);
} else {
output.innerHTML = "该浏览器不支持地理定位"。
}
}

函数 showPosition(position) { output.innerHTML = "你的位置："+
"<br>纬度。" + position.coords.latitude + "<br>Longitude:"+ position.coords.longitude;

describe_location(position.coords.latitude, position.coords.longitude)。
}
</脚本>

<p>打开你的JavaScript控制台，让浏览器看到你的位置</p>。
<p id="output"></p>
</body>
</html>

执行这段代码的结果显示在 图 10-3.


图10-3.在Rust中从JavaScript中进行模式匹配的地理定位
设计浏览器内外的代码
我想介绍的最后一节是另一个WebAssembly用例，我认为它将会越来越受欢迎。我们已经研究了使用Java-Script以外的语言来针对浏览器。我们还讨论了在基于浏览器的运行时中重复使用现有代码的情况。但是，那些被设计为在浏览器内部和外部都能正常运行的代码呢？我认为，一旦越来越多的人对WebAssembly提供的东西感到满意，这将是一个越来越普遍的情况。
我一直在期待这种活动，因为我一直在关注WebAssembly， ，但我惊讶于Emil Ernerfeldt在他的 egui库.他把这个项目描述为 "一个易于使用的纯Rust的即时模式GUI"。7基本上，它是一个复杂的用户界面库，在浏览器内部和外部都能工作。
我们在本章中多次提到，Rust得益于其LLVM遗产，允许我们发射各种后端目标。这也是Emil在利用这个优势来实现工作的。但他做得很优雅，我认为有很多东西可以从他那里学到。他是如何做到这一点的全部细节超出了本章的范围，但我想提请注意这个项目，以防你对做类似的事情感兴趣。
首先，让我们看看他的应用程序作为一个本地应用程序的运行情况。如果你是在Linux上，你必须再安装一些GitHub网站上列出的软件包，但之后，你只需运行即可。
brian@tweezer ~/g/egui> cargo run --release -p egui_demo_app



7GitHub repo解释了他为什么对即时模式的方法感兴趣。

结果应该与你在图10-4中看到的一样。 图10-4的样子，这取决于你点击了哪些选项。如果你玩一玩这个演示，你会发现这是一个有吸引力的、功能丰富的用户界面库。Rust社区非常期待有更多像这样的工具包来构建应用程序和游戏。

图10-4.egui演示应用程序的本地执行
当你运行Emil的演示时，所执行的代码（src/main.rs）如图所示 例10-14(我已经删除了一些配置代码以抑制警告）。注意main()方法只在本地编译时使用。

例10-14。egui演示应用程序的主程序
// 在本地编译时。
fn main() {
let app = egui_demo_lib::WrapApp::default()。
let options = eframe::NativeOptions {
// 让我们炫耀一下，我们支持透明窗口。
透明的：真。
.Default::default()
};

eframe::run_native(Box::new(app), options)。
}
对于本地执行，ecui库有一个可插拔的后端，使用ecui_glium库渲染组件。这反过来又使用了一个围绕OpenGL的Rust包装器 ，称为Glium。8egui_glium库是egui GitHub repo的一部分。
src/lib.rs文件显示了故事的另一部分，在 例10-15 (我在这里也删除了一些配置代码以抑制警告）。

例10-15。egui演示应用程序的WebAssembly入口点
#[cfg(target_arch = "wasm32")]
使用 eframe::wasm_bindgen::{self, prelude::*}。

/// 这是所有网络装配的入口。
/// 这是从HTML中调用一次。
///它加载应用程序，安装一些回调，然后返回。
/// 如果你想在你的代码中调用，你可以添加更多这样的回调。
#[cfg(target_arch = "wasm32")] #[wasm_bindgen]
pub fn start(canvas_id: &str) -> Result<(), wasm_bindgen::JsValue> { let app = egui_demo_lib::WrapApp::default(); eframe::start_web(canvas_id, Box::new(app) )
}

注意到wasm_bindgen注释的使用。eframe库也被用作一种抽象，以隐藏原生或在浏览器中运行的细节。比较一下例子10-14中使用的函数 例 10-14 中使用的函数和 例 10-15.
为了在网络环境中运行演示应用程序，ecui使用了一个名为egui_web的库。这依赖于WebGL，通过WebAssembly在HTML 5画布中渲染组件。
如果你查看目标/发布目录，你会看到该应用程序大约有5.6兆字节。
brian@tweezer ~/g/egui> ls -lah target/release
共计11736
drwxr-xr-x	13 brian staff	416B Sep 29 15:56 .
drwxr-xr-x@	5 brian staff	160B Aug 16 11:54 ...
drwxr-xr-x	57 brian staff	1.8K Sep 29 15:55 build
drwxr-xr-x 394 brian staff	12K Sep 29 15:56 deps
-rwxr-xr-x	2 brian staff	5.6M Sep 29 15:56 egui_demo_app
-rw-r--r--	1 brian staff	8.5K Sep 29 15:56 egui_demo_app.d


8Glium库目前没有得到维护，所以Emil正计划在某个时候替换它。

drwxr-xr-x	2 brian	工作人员	64B Aug 16 11:53 examples
drwxr-xr-x	2 brian	工作人员	64B Aug 16 11:53 增量
-rw-r--r--	1 brian	工作人员	8.5K Sep 29 15:56 libegui_demo_app.d
-rwxr-xr-x	2 brian	工作人员	49K Sep 29 15:56 libegui_demo_app.dylib
-rw-r--r--	2 brian	工作人员	2.0K Sep 29 15:56 libegui_demo_app.rlib
如果你看一下文档目录，你会发现，该应用程序的WebAssembly版本也已经建立，而且只有3.5兆字节。
brian@tweezer ~/g/egui> ls -lah docs
共计7288
drwxr-xr-x	6 brian	工作人员	192B Sep 29 15:51 .
drwxr-xr-x	28 brian	工作人员	896B Sep 29 15:51 ...。
-rw-r--r--	1 brian	工作人员	60K Sep 29 15:51 egui_demo_app.js
-rw-r--r--	1 brian	工作人员	3.5M Sep 29 15:51 egui_demo_app_bg.wasm
-rw-r--r--	1 brian	工作人员	222B Aug 16 11:51 example.html
-rw-r--r--	1 brian	工作人员	2.9K Aug 16 11:51 index.html
还有一个index.html文件和一些JavaScript来引导整个过程。我把大部分的HTML留了出来，但是 例10-16 突出了重要的部分。演示程序被赋予了<canvas>元素的ID，以便将自己呈现在其中。

例10-16。egui演示应用程序的HTML脚手架
<！--这是由`wasm-bindgen`CLI工具生成的JS-->。
<script src="egui_demo_app.js"></script></script>

<script>
// 我们将推迟执行，直到wasm准备好了。
// 这里我们告诉bindgen到wasm文件的路径，以便它能够启动
//初始化，完成后返回给我们一个承诺。
wasm_bindgen("./egui_demo_app_bg.wasm")
.then(on_wasm_loaded)
.catch(console.error)。

函数 on_wasm_loaded() {
// console.log("loaded wasm, starting egui app"); wasm_bindgen.start("the_canvas_id").this call install a bunch of callbacks and then returns;
}
</脚本>

如果你在docs目录下启动一个HTTP服务器，并将你的浏览器指向你选择的端口，你可以看到以下结果 图 10-5.
brian@tweezer ~/g/e/docs> python -m http.server 10003
在:: 10003端口提供HTTP服务 (http://[:]:10003/) ...


图10-5.浏览器执行egui演示应用程序
如果你对这一切是如何运作的感兴趣，我鼓励你去钻研我提到的各种库。这里到处都是有用的指针和文件，包括创建你自己的自定义小工具的技巧。
该演示应用程序相当复杂，作为一种入门手段，让人不知所措，但为了让你了解一下代码的样子，请看 例 10-17，这是从GitHub文档中摘录的。

例10-17.构建一个简单应用程序的代码片断
ui.heading("My egui Application"); ui.horizontal(|ui| {)
ui.label("你的名字："); ui.text_edit_singleline(&mut name)。
});
ui.add(egui::Slider::new(&mut age, 0..=120).text("age"))。
if ui.button("Click each year").clicked() { age += 1;
}
ui.label(format! ("Hello '{}', age {}", name, age))。

这个代码样本的结果显示在 图 10-6.

图10-6.示例代码的渲染形式
如果你对使用egui构建自己的应用程序感兴趣，可以在本地或浏览器中运行，Emil提供了一个 工作 项目 模板.只要叉开这个项目库（或使用GitHub模板来创建你自己的项目库），并按照说明进行操作就可以了。
我希望你在玩这个很酷的库和它的相关基础结构时有乐趣。我更想说的是，它代表了对软件的有意设计，以便同时针对本地和基于浏览器的应用交付。我希望在不久之后能看到更多这样的方法。
指南 wasm-bindgen 手册 指导有更多令人兴奋的例子，说明你可以从Rust中直接与浏览器功能进行交互，包括渲染到一个<canvas>元素，做WebGL，以及直接操作DOM。也有一些例子用于 在Deno中从TypeScript的Rust中调用JavaScript代码。.我们将在第二章中讨论如何使用wasm-bindgen来支持Rust中的线程。 章-第 12章.
正如你所看到的，Rust本身就是一种现代的、令人兴奋的编程语言。它可以生成WebAssembly代码的事实也非常酷，但如果没有wasm-bindgen的支持，要建立起任何重要的东西仍然相当困难。不过，有了这个有点神奇的工具，Rust可以以令人惊讶和意外的方式驱动浏览器的行为。
但现在，我们必须大跃进，进入一个更普遍的战略，使WebAssembly应用程序更加便携。

## 注释

[^1]: Ken Thompson是B编程语言的创造者，它是C语言的前身，他还发明并实现了大部分的Unix操作系统。Rob Pike 是一位作家和程序员，参与了Unix的开发和影响Go的后续项目，如Plan 9。
[^2]: 有很多地方可以读到关于Rust的流行，但这篇来[自 Nature 的文章](https://www.nature.com/articles/d41586-020-03382-2)是一篇很酷的文章。
[^3]: 对于好奇的你，你可以在[Rust网站](https://doc.rust-lang.org/book/ch19-06-macros.html)中找到更多关于宏的信息。
[^4]: 类型 inference推理 是一种程序的质量，它允许编译器或运行时推断出一个值的类型，而不告诉它是什么。
[^5]: 这将很快成为你学会热爱Rust编译器和非常重视开发者经验的社区的东西。
[^6]: 肯特-贝克推广了一个令人回味的短语 代码 smell嗅觉 意思是说，你可以在知道代码中有问题之前就感觉到它的存在，因为你会发现其中的暗示。当食物变坏时，你往往在意识到它之前就已经闻到了。代码也是如此。