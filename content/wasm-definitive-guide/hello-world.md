---
linktitle: 第 2 章：入门
summary: 从 Hello world 开始。
weight: 3
title: WebAssembly 入门
date: '2023-01-16T00:00:00+08:00'
type: book
---

> 它是如何，嗯，它是如何工作的？
>
> ——亚瑟王，《巨蟒与圣杯》（Monty Python and the Holy Grail）

教导人们了解WebAssembly的部分困难在于，有很多地方可以开始。如果他们是C/C++开发者，这可能是开始讨论的合理地点。如果他们是Rust开发者，那也是。但你也可以谈论WebAssembly的机制，而不考虑你用什么语言来生成它。在这一章中，我将采取这种方法。在接下来的几章中，我们将逐步学习底层细节，然后开始建立与高级语言的联系。这些细节最初看起来会很简单，令人困惑，但我们正在研究基本的机制，这不是你最终工作的地方。让我们首先考虑一下为什么我们不能从大多数编程书的方式开始。

在[第 1 章](../introduction/)中，我在讨论asm.js时介绍了大多数人用新的编程语言或技术编写的第一个程序。我们在例2-1中再次展示。我们把这个程序称为 "Hello, World!"，以表示对Brian Kernighan和Dennis Ritchie的开创性著作《C程序设计语言》（Pearson）中使用的第一个程序的敬意。许多高质量的编程书籍[^1]都是从这个例子开始的，因为它让读者了解了什么是怎么回事，而没有深入到细节中去。这很有趣，很有力量，也是确保读者正确设置工具的一个好方法。

例2-1. 典型的 "Hello, world!"程序，用C语言编写

```c
#include <stdio.h>
int main() {
  printf("Hello, World!\n");
  return 0;
}
```

不幸的是，WebAssembly没有办法打印到控制台，所以我们不能以这种方式开始。

等等，什么？

我将给你一点时间来消化这句话，也许可以重读几遍，以确保它说的是你认为的内容。

深信不疑？困惑吗？

是的，可以说，WebAssembly没有办法打印到控制台、读取文件或打开网络连接......除非你给它一个方法来这样做。

如果你检查例 2-1 的时候，你就会明白问题出在哪里。为了使该程序运行，它需要一个`printf()`函数的工作副本，该函数可以在标准库中找到。使得C语言程序具有可移植性的部分原因是，在各种平台上都有这样的标准库。所谓的POSIX库将这些常见的功能扩展到了打印到控制台之外，包括文件操作、信号处理、消息传递等等。一个应用程序将写入诸如POSIX的API，但可执行文件将需要一个静态或动态库，提供适合在目标平台上运行的调用方法的行为。这将是你计划使用的操作系统的本地可执行格式。

这就是为什么我说WebAssembly使代码可移植，但我们还需要其他东西来帮助我们使应用程序可移植。我们将在本书中重新讨论这个话题，但现在你只需知道WebAssembly没有直接的方法来写到控制台。

我向你保证，我们将向Kernighan和Ritchie致敬，在[第 5 章](../using-c-cpp-and-wasm/)运行那个确切的程序。然而，首先，我们要学习WebAssembly的人类友好格式，以及低级指令如何与堆栈机互动。然而，我仍然希望你在这里有一个 "Hello, world!" 的体验，所以我们将挑选一些其他的东西来编写和运行，这不是太有挑战性，但仍然是合理的。这也算是一种 "Hello, world!" 吧！

## WebAssembly文本格式（Wat）

我们已经提到，二进制格式（Wasm）的设计是为了使WebAssembly模块的传输、加载和验证更快。我们将在[第章](../wasm-modules/)更正式地介绍模块，但现在只需把它们看作是部署的单位，就像Java中的库或Jar文件。还有一种描述模块行为的文本格式，更便于人类阅读——Wat。虽然没有什么可以阻止你用手写文本格式的代码，但你不太可能这样做。这种格式有时在写作中也被称为 "Wast"，但这是原来的名字。许多工具都支持这两种写法，人们常常把这两者混淆。我们将坚持使用Wat和它的后缀`.wat`。

在例2-2中，我们看到一个完整的、有效的用 Wat 表达的Wasm模块。这种类似Lisp的格式，通过函数的签名和堆栈机指令的集合来表达。WebAssembly抽象机是一个虚拟堆栈机，这个概念我将在稍后进一步解释。大多数编译后的软件都变成了特定硬件架构的可执行格式。如果你的目标是英特尔x86机器，那么行为将从高级语言转化为一系列的指令，在该芯片上运行。如果没有某种仿真器，它将无法在其他地方运行。像Java和.NET这样的平台有一个中间的字节码表示，它将被移植到各种平台的运行环境所解释。WebAssembly指令更像这样，但涉及到通过一小部分指令对堆栈进行操作。最终，当它在WebAssembly主机中执行时，这些指令将被映射到特定芯片的指令中。

例 2-2. 一个简单的WebAssembly文本文件

```c
(module
    (func $how_old (param $year_now i32) (param $year_born i32) (result i32) ①
        local.get $year_now 
        local.get $year_born
        i32.sub)

    (export "how_old" (func $how_old)) ②
)
```

1. 内部函数 `$how_old`
2. 导出的函数 `how_old`

这里显示的函数被称为`$how_old`，在我们明确导出它之前，它在本模块之外是不可见的。注意名称的区别。内部名称以`$`开头，而导出的版本则没有。如果有人在外部调用它，它只是执行内部函数。

这个模块定义了一个函数，它接受两个整数参数并返回另一个整数。按照MVP的定义，WebAssembly是一个32位的环境[^2]。正如你将看到的，这种限制随着时间的推移正在放宽。到本书出版时，64位Wasm环境可能会以某种形式出现（译者注：参考 [Memory64 Proposal for WebAssembly](https://github.com/WebAssembly/memory64)）。WebAssembly支持32位和64位的整数（称为i32和i64）和32位和64位的浮点数（称为f32和f64）。

在这个层面上，没有字符串、对象、字典或其他你所期望的数据类型。请不要担心；我们将在后面讨论如何克服这些问题，但这是我们不做典型的 "Hello, World!"应用程序的原因之一。这里没有字符串！在我们引入一些更多的想法之前，只处理数字会更容易。因此，本着这种程序风格，我们将向你展示足够多的东西，让你看到它的工作，而不会让你感到压抑。

这个内部函数的目的是根据某人的出生年份和目前的年份来计算他的年龄。你可能不会感到惊讶，因为WebAssembly没有日期的概念，也没有默认请求当前时间的能力。我希望你想知道WebAssembly到底能做什么？令人高兴的是，它可以做数学运算。如果你给它当前的年份和某人出生的年份，它绝对可以从另一个年份中减去一个，并得出一个结果。请不要被吓倒，我们只是把事情分离出来，以便清楚地知道系统的哪一部分提供了什么。

正如你可能知道的那样，堆栈是软件中一个方便且广泛使用的数据结构。它经常被描述为像食堂里的一摞托盘。工作者会把干净的盘子放在任何其他盘子的上面。顾客会从上面拿一个。

考虑一个空栈，如图 2-1 我们说我们把某个东西推到堆栈的顶部，然后从堆栈的顶部弹出。我们只操作过这个位置，所以如果你需要遍历一个列表，这就不是一个合适的数据结构。同时，只有一个地方可以寻找我们感兴趣的东西，所以我们不需要指定位置、索引或键。这是一个快速而有效的操作结构。

![图 2-1. 一个空的堆栈](../images/f2-1.png)

回顾一下例 2-2 函数中的指令列表。第一条是`get_local`。WebAssembly主机环境将检索名为`$year_now`的参数值，然后把它推到堆栈。假设现在的年份是2021年，结果如图 2-2 所示。

![图 2-2. 一个有一个值的堆栈](../images/f2-2.png)

在这一点上，WebAssembly主机环境将推进到第二个指令。这也是一条`get_local`指令，它将检索名为`$year_born`的参数值，并将其推到堆栈中。现在堆栈上有两个值，但堆栈的顶部指向推送的最新值。假设调用该函数的人是在2000年出生的，那么堆栈将看起来如图 2-3。

![图2-3. 一个有两个值的堆栈](../images/f2-3.png)

执行环境将继续，因为还有一条指令。这条指令是`i32.sub`，它表示一个i32值减去另一个i32值的算术运算。由于它需要两个值才有意义，它将通过弹出栈上的两个值来查询，结果是一个空栈，看起来如图2-1。然后，它从第一个参数中提取第二个参数，并将结果推回堆栈的顶部。其结果如图 2-4。

![图 2-4. 推回堆栈的减法结果](../images/f2-4.png)

在这一点上，没有更多的指令要执行，我们在堆栈的顶部只剩下一个值。在例 2-2 中，我们看到我们的函数定义了一个i32的返回值。无论堆栈顶部的是什么，都将作为调用函数的结果返回。

这可能看起来像是为两个数字相减而做的大量工作，但考虑到我们已经以一种平台中立的方式表达了一个数学事件序列。当代码最终被转换为运行时主机中的本地指令时，这些值将被加载到CPU寄存器中，一条指令将使用CPU指令集的机械原理把它们加在一起。我们不必担心目标平台的细节或特异性，但转换过程将是快速和容易的，以时间到了就进行。然而，在这之前，我们需要将我们的文本格式转换为其二进制表示。

## 将Wat转换为Wasm

任何做了很长时间程序员的人都会注意到我们的实现中存在的所有潜在问题。我们没有处理有人颠倒参数，使函数返回一个负数的情况。为了保持例子的简单性，我们只是忽略了这些实际情况。虽然这不是一个超级令人兴奋的函数，但我们已经研究了通过WebAssembly的本地文本格式来表达一些基本行为的机制。下一步是把它变成二进制的可执行形式。你有几种选择，但我们将集中讨论两种方法。

第一个不需要你安装任何东西。事实上，你可以继续调用你的函数，看看它的工作情况！如果你去看[网上 wat2wasm 演示](https://webassembly.github.io/wabt/demo/wat2wasm/index.html)，你会看到一个多面板网站。左上角代表一个`.wat`文件。右上角代表编译后的`.wat`文件的注释的十六进制转储。左下角表示使用API调用行为的JavaScript代码，我们将在后面更全面地介绍。右下角表示执行该代码的输出。

复制并粘贴例2-2代码到左上角的WAT面板上。这将使文本格式转换为二进制格式。假设你没有任何错别字，你也可以通过按下同一面板上的下载按钮来下载二进制格式。先不要担心这样做。

现在，复制例 2-3 代码到左下角的面板上。这将调用大多数现代浏览器（和Node.js）中的WebAssembly JavaScript API。我们稍后会更多地讨论它，但现在我们正在检索二进制模块的字节（这里可以通过`wasmModule`变量获得），并获得`how_old`函数的引用，以便我们可以调用它。正如你所看到的，这个函数可以像其他的JavaScript函数一样被调用。这样做的结果将通过 `console.log()` 打印到右下角的面板上。

例 2-3. 调用我们的函数的JavaScript

```javascript
const wasmInstance = new WebAssembly.Instance(wasmModule, {});
const { how_old } = wasmInstance.exports; 
console.log(how_old(2021, 2000));
```

如果一切顺利，你应该看到类似于图 2-5 的东西。试着改变当前年份和出生年份参数的日期，确保你的计算是正确的。

![图 2-5. 将WebAssembly文本文件转换为二进制文件并执行它（译者注：图片比原著有更新）](../images/f2-5.png)

在这一点上，你可以下载该文件的二进制版本。默认情况下，它将被命名为 `test.wasm`，但你可以把它重命名为你喜欢的任何名字。我们将叫它`hello.wasm`。

你还有一个选择，就是使用WebAssembly Binary Toolkit（WABT）[^3]来生成这种二进制形式。请参考[附录](../apendix/)获取关于安装WABT和其他我们将在本书中使用的工具的说明。

在这个安装中包括一个叫做`wat2wasm`的命令。它如其名，将文本文件转换为二进制格式：

```bash
> wat2wasm hello.wat
> ls -alF
total 16
drwxr-xr-x  4 brian  staff  128 Dec  7 07:59 ./
drwxr-xr-x  6 brian  staff  192 Dec  7 07:53 ../
-rw-r--r--  1 brian  staff   45 Dec  7 07:59 hello.wasm
-rw-r--r--  1 brian  staff  200 Dec  7 07:59 hello.wat
```

仔细观察。你的眼睛没有欺骗你。它并没有做很多事情，但二进制格式只有45个字节长！我以前写了很多Java程序，有的类名比这个还要长。现在我们需要一种方法来执行我们的函数，因为我们不在浏览器中。这很容易做到，用Node.js中的JavaScript API，但我们将使用不同的方法来展示一系列的选择。

## 在Repl中运行Wasm

我向你展示的另一个工具是如何安装在[附录](../appendix/)中的是 [wasm3](https://github.com/wasm3/wasm3) 它允许你在命令行上运行Wasm模块和函数，或者通过通常称为 "repl"[^4]的交互式模式。

一旦我执行下面的命令，我就会得到一个wasm3 提示。我把它指向我的Wasm文件，所以只有一个函数我可以调用，但如果模块中还有其他导出的函数，它们也可以用。

```bash
> wasm3 --repl hello.wasm
wasm3> how_old 2021 2000
Result: 21
wasm3> how_old 2021 1980
Result: 41
wasm3> CTRL-D
>
```

请注意，我只能调用导出的函数，而不能调用内部函数。还注意到，如果我们像预期的那样颠倒参数的顺序，我们会失败。当你用高级语言构建Wasm模块时，这些将使你更容易做正确的事情（尽管当然也可以在`.wat`文件中手工编写这种错误检查，但生命对于那种无意义的事情来说太短暂）。要退出 repl，你可以简单地输入Ctrl-C或Ctrl-D。

不过，让我们回顾一下我们刚才所做的事情。我们通过一个针对抽象机器的指令集来表达一些任意的功能。我们在一个浏览器中运行它。它应该可以在任何主要操作系统上的任何主要浏览器中运行。嗯，JavaScript也应该如此。但我们也在MacOS机器上以交互模式运行的C语言可执行文件中运行了它：

```bash
brian@tweezer ~/g/w/build> file wasm3
wasm3: Mach-O 64-bit executable x86_64
```

在这里，它运行在被编译为Linux二进制的同一个应用程序中：

```bash
brian@bbfcfm:~/g/w/build> wasm3 --repl $HOME/hello.wasm wasm3> how_old 2021 2000
Result: 21
wasm3> ^C
brian@bbfcfm:~/g/w/build> file wasm3

wasm3: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV),
dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2,
BuildID[sha1]=b5e98161d08d2d180d0725f973b338c2a340d015, for GNU/Linux
3.2.0, not stripped
```

实际上，有几个独立的WebAssembly环境是用Python、Rust、Scala、OCaml、Ruby等编写的。我们的函数应该可以在其中任何一个环境中使用和工作。

## 在浏览器中运行Wasm

对于我们的下一个演示，我将向你展示如何使用JavaScript API在浏览器中调用该行为。我们现在还不会介绍API，但你会看到一个基本的例子。还有更复杂的编译模块和参数化模块的方法，但首先我们要学会爬，接着学会走，最后学会跑。

在例 2-4 中，我们看到了一段可重复使用的代码，用于实例化一个WebAssembly模块实例。这样做的JavaScript API在任何支持WebAssembly MVP的环境中都是可用的，但也有其他不需要JavaScript的环境，比如我们刚刚使用的wasm3运行时。然而，这段代码可以在任何支持WebAssembly的浏览器[^5]或Node.js中运行。请注意，我们使用了基于Promise的方法。如果你的JavaScript环境支持`async/await`，你显然也可以使用这些。

{{<callout note 提示>}}

如果你的浏览器支持流式编译功能，那么例 2-4 的代码不是实例化WebAssembly模块的首选方法。我们将暂时使用它，只是为了让你看到各个步骤，但我将在本书的后面讨论首选的方法。

{{</callout>}}

例2-4. 在JavaScript中实例化一个Wasm模块

```javascript
function fetchAndInstantiate(url, importObject) {
    return fetch(url).then(response =>
        response.arrayBuffer()
    ).then(bytes =>
        WebAssembly.instantiate(bytes, importObject)
    ).then(results =>
        results.instance
    );
}
```

一旦有了这个功能，从HTML中使用它就很容易了。在例 2-5 中，你可以看到这个过程是如何进行的。

例 2-5. 从一个网页实例化一个Wasm模块

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="bootstrap.min.css">
    <title>Hello, World! (Sort of)</title>
    <script src="utils.js"></script>
  </head>
  <body>
    <div class="container">
      <h1>Hello, World! (Sort of)</h1>
      I think you are <span id="age"></span> years old.
    </div>

    <script>
      fetchAndInstantiate('hello.wasm').then(function(instance) {
	  var ho = instance.exports.how_old(2021,2000);
	  var ageEl = document.getElementById('age');
	  ageEl.innerText=ho;
      });
    </script>
  </body>
</html>
```

在这个例子中，我们建立了一个ID为age的`<span>`。它目前是空的。我们将用调用WebAssembly函数的结果来填充它。我们的HTML文件的其余部分并不奇怪。我们在`<head>`元素中包括我们的可重复使用的实例化代码。在这个文件的底部，我们看到一个嵌入的`<script>`元素，它调用`fetchAndInstantiate()`函数。它传入了对`hello.wasm`文件的本地引用，所以我们也必须通过HTTP提供这个文件。

该函数返回一个*Promise*。当它解析时，我们收到一份实例化的Wasm模块实例的副本，并能够调用一个通过模块的出口部分暴露的方法。注意，我们传递的是普通的JavaScript数字字元，但这些数字可以很好地传递到函数中。数字21通过调用过程被返回，然后存储在我们前面提到的空`<span>`的`innerText`中。

我们需要通过HTTP提供HTML、JavaScript和Wasm模块，以便在浏览器中运行。你可以随心所欲地这样做，但用 python3（或者在非 Mac 上只用 python），你可以启动一个服务器，并指定要监听的端口。

```bash
brian@tweezer ~/g/w/s/ch02> python3 -m http.server 10003
Serving HTTP on :: port 10003 (http://[::]:10003/) ...
```

如果你打开你的浏览器并将其指向 <http://localhost:10003/index.html>，你应该看到类似于 图 2-6 中的内容。请随意改变嵌入的`<script>`元素中的参数，并验证它是否继续工作。

![图 2-6. 从网页中的JavaScript调用导出的WebAssembly模块函数](../images/f2-6.png)

我们显然还有很多东西要学，但你现在已经看到了相当于 "Hello, World!" 的例子，希望你能理解WebAssembly如何工作的基本原理。

## 注释

[^1]: 包括大部分 WebAssembly 教程！
[^2]: 计决定的细节和他们对基本WebAssembly功能的动机都记录在 [GitHub](https://github.com/WebAssembly/design/blob/main/MVP.md) 上。
[^3]: 读作wabbit，就像那个wascal，Bugs Bunny（兔八哥）。
[^4]: 如果你从未使用过这样的环境，你应该看看[维基百科上的这个页面](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)。
[^5]: 你可以看到哪些浏览器环境支持WebAssembly（或其他功能），请点击 "[Can I use...](https://caniuse.com/?search=WebAssembly)"
