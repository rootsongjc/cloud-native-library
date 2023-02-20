# WebAssembly 入门

学习 WebAssembly 的难点在于入门资料很多。作为一名 C/C++ 或 Rust 开发者，你都可以从这里开始，但也可以直接了解 WebAssembly 的机制，不需要考虑语言生成的问题。本章将从不考虑语言的角度介绍 WebAssembly，随着我们深入学习底层细节，在后面的章节中，我们将与高级语言建立联系。虽然这些细节最初看起来简单，但对于理解 WebAssembly 的基本机制却非常重要，它们不会是你的最终目的。

在 [第 1 章](../introduction/)，我曾经在讨论 asm.js 时介绍了大多数人编写新编程语言或技术的第一个程序。在例 2-1 中，我们再次展示了这个程序，它被称为 "Hello, World!"，以向 Brian Kernighan 和 Dennis Ritchie 的开创性著作《C 程序设计语言》致敬。很多优秀的编程书籍都从这个例子开始，因为它使读者了解了程序的基本概念，而不会深入细节。这是一种有趣，简洁的方法，也是确保读者正确设置工具的有效方法。

例 2-1. 典型的 "Hello, world!" 程序，用 C 语言编写

```c
#include <stdio.h>
int main () {printf ("Hello, World!\n");
  return 0;
}
```

不幸的是，WebAssembly 没有办法打印到控制台，所以我们不能以这种方式开始。

等等，什么？

我将给你一点时间来消化这句话，也许可以重读几遍，以确保你能理解。

是不是感觉很困惑？是的，可以说，WebAssembly 没有办法打印到控制台、读取文件或打开网络连接...... 除非有对应的 API 可以调用。

在检查例 2-1 时，你会发现问题所在。要使该程序正常运行，它需要 printf () 函数的工作副本，这个函数可以在标准库中找到。C 语言程序具有可移植性的原因之一是，这种标准库在各种平台上都存在。POSIX 库，把这些常见的功能扩展到了控制台以外，包括文件操作、信号处理、消息传递等。应用程序会写入诸如 POSIX 的 API，但可执行文件还需要一个静态或动态库，提供在目标平台上运行的调用方法的行为，这就是你打算使用的操作系统的本地可执行格式。

 因此，WebAssembly 使代码可移植，但我们仍然需要其他工具来帮助使应用程序可移植。我们会在书中重新探讨这个话题，但现在请记住，WebAssembly 没有直接的方法来写入控制台。 

在[第 5 章](../using-c-cpp-and-wasm/)，我们将向 Kernighan 和 Ritchie 致敬，并运行那个程序。但首先，我们需要学习 WebAssembly 的人类友好格式，以及如何让低级指令与堆栈机交互。然而，我仍然希望你在这里有一个 “Hello, world!” 的体验，所以我们将挑选其他内容来编写和运行，这不是太有挑战性，但仍然是合理的。这也算是一种 "Hello, world!" 吧！

## WebAssembly 文本格式（Wat）

WebAssembly 的二进制格式（Wasm）的设计目的是为了加速 WebAssembly 模块的传输、加载和验证。我们将在 [第 3 章](../wasm-modules/) 更深入地了解模块，但现在只需把它们理解为部署的单元，就像 Java 中的库或 Jar 文件。另外，还有一种描述模块行为的文本格式，方便人类阅读，这就是 Wat。虽然你可以手写文本格式的代码，但很少有人这样做。这种格式有时也被称为 "Wast"，但这是原名。很多工具都支持这两种写法，因此容易混淆。本书将使用 Wat 和它的后缀 .wat。

例 2-2 展示了一个完整的、有效的使用 Wat 表达的 Wasm 模块。它通过函数签名和堆栈机指令的集合来表示，类似于 Lisp 格式。WebAssembly 抽象机是一个虚拟堆栈机，在后面我们将对此进行详细解释。大多数编译后的软件都会被编译成特定硬件架构的可执行格式。例如，如果你的目标是 Intel x86 机器，那么代码将被编译为一系列的指令，可以在该芯片上运行。如果没有某种仿真器，它将无法在其他地方运行。平台如 Java 和.NET 有中间的字节码表示，这些字节码可以被解释并在各种平台的运行环境中执行。与此类似，WebAssembly 指令也具有类似的特征，但它通过对堆栈执行少量指令来实现目标。最后，当在 WebAssembly 主机中执行时，这些指令将被映射到特定芯片上的机器指令中。

例 2-2. 一个简单的 WebAssembly 文本文件

```c
(module
    (func $how_old (param $year_now i32) (param $year_born i32) (result i32) ①
        local.get $year_now 
        local.get $year_born
        i32.sub)

    (export "how_old" (func $how_old)) ②
)
```

1. 内部函数`$how_old`
1. 导出的函数`how_old`在这里，函数被称为`$how_old`，直到明确导出它，它在模块外是不可见的。请注意命名方式的不同。内部命名以`$` 开头，而导出版本则没有。如果有人从外部调用它，它仅执行内部函数。

本模块定义了一个接受两个整数参数并返回一个整数的函数。根据 MVP 的定义，WebAssembly 是一个 32 位环境。随着时间的推移，这种限制正在放松，在本书出版时，可能会有某种形式的 64 位 Wasm 环境（请参阅 [Memory64 Proposal for WebAssembly](https://github.com/WebAssembly/memory64)）。WebAssembly 支持 32 位和 64 位整数（分别称为 i32 和 i64）和 32 位和 64 位浮点数（分别称为 f32 和 f64）。

在 WebAssembly 层面上，没有我们熟悉的数据类型，例如字符串、对象、字典等。不用担心，在后面的章节中我们会讨论如何处理这些问题。这是我们不能编写典型的 "Hello, World!" 应用程序的原因之一。在我们开始介绍更多想法之前，我们仅处理数字，这样会更简单。因此，本书的风格是逐渐向你展示足够的知识，使你能够看到它的工作方式，而不会让你感到压抑。

这个内部函数用于计算一个人的年龄，根据他的出生年份和当前年份。WebAssembly 并不拥有日期概念，也无法请求当前时间，不过不用担心。它精通数学运算，如果给它当前年份和一个人的出生年份，它可以减去一个年份得出一个结果。我们把这些操作分开，是为了更清楚地知道系统的各部分功能。

堆栈是一种常用的数据结构，经常被比作一摞托盘，就像餐厅里的。工人会把干净的盘子放在其他盘子的顶部。客人可以从顶部取一个。

考虑一个空栈，如图 2-1 所示，我们说我们把某物品推到栈顶，然后从栈顶弹出。我们只对栈顶进行操作，所以如果需要遍历列表，堆栈并不是一个适合的数据结构。并且，只有一个位置可以找到我们感兴趣的东西，因此我们不需要指定位置、索引或键。这是一种快速且有效的操作结构。

![图 2-1. 一个空的堆栈](../images/f2-1.png)

回顾一下例 2-2 函数中的指令列表。第一条是 `get_local`。WebAssembly 主机环境将检索名为 `$year_now` 的参数值，然后把它推到堆栈。假设现在的年份是 2021 年，结果如图 2-2 所示。

![图 2-2. 一个有一个值的堆栈](../images/f2-2.png)

在这一点上，WebAssembly 主机环境将推进到第二个指令。这也是一条 `get_local` 指令，它将检索名为 `$year_born` 的参数值，并将其推到堆栈中。现在堆栈上有两个值，但堆栈的顶部指向推送的最新值。假设调用该函数的人是在 2000 年出生的，那么堆栈将看起来如图 2-3。

![图 2-3. 一个有两个值的堆栈](../images/f2-3.png)

执行环境将继续，因为还有一条指令。这条指令是 `i32.sub`，它表示一个 i32 值减去另一个 i32 值的算术运算。由于它需要两个值才有意义，它将通过弹出栈上的两个值来查询，结果是一个空栈，看起来如图 2-1。然后，它用第一个参数减去第二个参数，并将结果推回堆栈的顶部。其结果如图 2-4。

![图 2-4. 推回堆栈的减法结果](../images/f2-4.png)

在这一点上，没有更多的指令要执行，我们在堆栈的顶部只剩下一个值。在例 2-2 中，我们看到我们的函数定义了一个 i32 的返回值。无论堆栈顶部的是什么，都将作为调用函数的结果返回。

我们可能觉得为两个数相减做了太多工作，但实际上我们已经用平台中立的方式表达了一系列数学事件。当代码被转换成运行时主机的本地指令时，这些值会被加载到 CPU 寄存器中，一条指令就可以用 CPU 指令集的机械原理将它们相加。我们不用担心目标平台的细节或差异，因为转换过程会快速而简单，随时可以完成。但在此之前，我们需要将文本格式转换为它的二进制表示。

## 将 Wat 转换为 Wasm

任何长期担任程序员的人都会注意到我们实施的所有潜在问题。 我们没有处理有人颠倒参数，使函数返回负数的情况。为了使示例简单，我们忽略这些现实。虽然这不是一个非常令人兴奋的功能，但我们已经了解了通过 WebAssembly 的原生文本格式表达一些基本行为的机制。 下一步是将其转换为二进制可执行形式。我们有多种选择，但我们将重点介绍两种方法。

第一种方法不需要您安装任何东西。 事实上，您可以继续调用您的函数，看看它是如何工作的！ 如果您访问[在线 wat2wasm 演示](https://webassembly.github.io/wabt/demo/wat2wasm/index.html)，您将看到一个多面板网站。 左上角代表一个 `.wat` 文件。 右上角代表编译后的 `.wat` 文件注释的十六进制转储。 左下角代表使用 API 调用行为的 JavaScript 代码，稍后我们将更全面地介绍它。右下角代表执行这段代码的输出。

将示例2-2 中的代码复制并粘贴到左上角的 WAT 面板中。这会将文本格式转换为二进制格式。假设您没有任何拼写错误，您还可以通过单击同一面板上的下载按钮来下载二进制格式。

现在将示例2-3 中的代码复制到左下方的窗格中。这将在大多数现代浏览器（和Node.js）中调用 WebAssembly  JavaScript  API。我们稍后会讨论这个，但现在我们正在提取二进制模块的字节（可通过 `wasmModule`  变量在此处获得）并获取对 `how_old` 函数的引用，以便我们可以调用它。如您所见，可以像调用任何其他 JavaScript 函数一样调用此函数。结果将通过 `console.log()` 打印在右下角的面板上。

例 2-3. 使用 JavaScript 调用我们的函数

```javascript
const wasmInstance = new WebAssembly.Instance (wasmModule, {});
const {how_old} = wasmInstance.exports; 
console.log (how_old (2021, 2000));
```

如果一切顺利，您应该会看到类似于图 2-5 的内容。 尝试更改当前年份的日期和出生年份参数以确保您的计算正确。

![图 2-5. 将 WebAssembly 文本文件转换为二进制文件并执行它（译者注：图片比原著有更新）](../images/f2-5.png)

此时，您可以下载该文件的二进制版本。 默认情况下，它将被命名为 `test.wasm`，但您可以将其重命名为您喜欢的任何名称。 我们称之为 `hello.wasm`。

您还可以选择使用 WebAssembly Binary Toolkit（WABT）来生成这种二进制形式。有关安装 WABT 和我们将在本书中使用的其他工具的说明，请参阅[附录](../apendix/)。

此安装中包含一个名为 wat2wasm 的命令。 它的功能如其名，将文本文件转换为二进制格式：

```bash
> wat2wasm hello.wat
> ls -alF
total 16
drwxr-xr-x  4 brian  staff  128 Dec  7 07:59 ./
drwxr-xr-x  6 brian  staff  192 Dec  7 07:53 ../
-rw-r--r--  1 brian  staff   45 Dec  7 07:59 hello.wasm
-rw-r--r--  1 brian  staff  200 Dec  7 07:59 hello.wat
```

仔细观察。 你的眼睛没有骗你。 它的作用不大，但二进制格式只有 45 个字节长！ 之前写过很多 Java 程序，有些类名比这个还长。 现在我们需要一种方法来执行我们的功能，因为我们不在浏览器中。 使用 Node.js 中的 JavaScript API 很容易做到这一点，但我们将使用不同的方法来展示一系列选项。

## 在 Repl 中运行 Wasm

我在[附录](../appendix/)中向您展示了如何安装的另一个工具是 [wasm3](https://github.com/wasm3/wasm3)，它允许您在命令行上或通过通常称为 “repl”的交互模式运行 Wasm 模块和函数。

执行下面的命令后，你会收到 wasm3 提示符。 我将它指向我的 Wasm 文件，所以我只能调用一个函数，但如果模块中有其他导出函数，它们也可以工作。

```bash
> wasm3 --repl hello.wasm
wasm3> how_old 2021 2000
Result: 21
wasm3> how_old 2021 1980
Result: 41
wasm3> $how_old 2021 2000
Error: function lookup failed ('$how_old') wasm3> how_old 1980 2021
Result: 4294967255
wasm3>
```

请注意，我只能调用导出函数，不能调用内部函数。 另请注意，如果我们按预期颠倒参数的顺序，则会失败。当你用高级语言构建 Wasm 模块时，这些将使你更容易做正确的事情（尽管当然也可以在 `.wat` 文件中手动编写这种错误检查代码，但那太麻烦了）。 要退出 repl，您只需键入 Ctrl-C 或 Ctrl-D。

然而，让我们回顾一下我们刚刚做了什么。我们通过抽象机器的指令集来表达一些任意功能。我们在浏览器中运行它。 它应该适用于任何主要操作系统上的任何主要浏览器。好吧，JavaScript 也应该如此。 但我们也在 MacOS 机器上以交互模式运行的 C 可执行文件中运行它：

```bash
brian@tweezer ~/g/w/build> file wasm3
wasm3: Mach-O 64-bit executable x86_64
```

在这里，它在编译为 Linux 二进制文件的同一应用程序中运行： 

```bash
brian@bbfcfm:~/g/w/build> wasm3 --repl $HOME/hello.wasm wasm3> how_old 2021 2000
Result: 21
wasm3> ^C
brian@bbfcfm:~/g/w/build> file wasm3

wasm3: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV),
dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2,
BuildID [sha1]=b5e98161d08d2d180d0725f973b338c2a340d015, for GNU/Linux
3.2.0, not stripped
```

事实上，有几个独立的 WebAssembly 环境是用 Python、Rust、Scala、OCaml、Ruby 等编写的。我们的功能应该能够在任何一个环境中使用和工作。

## 在浏览器中运行 Wasm

对于我们的下一个演示，我将向您展示如何使用 JavaScript API 在浏览器中调用此行为。 我们不会介绍 API，但您会看到一个基本示例。有更复杂的模块编译和参数化方法，但首先我们学会爬行，然后才学会走路，最后是跑。

在示例 2-4 中，我们看到了一段用于实例化 WebAssembly 模块实例的可重用代码。 执行此操作的 JavaScript API 在任何支持 WebAssembly MVP 的环境中都可用，但还有其他不需要 JavaScript 的环境，例如我们刚刚使用的 wasm3 运行时。 但是，此代码将在任何支持 WebAssembly 的浏览器或 Node.js 中运行。请注意，我们使用了基于 Promise 的方法。 如果你的 JavaScript 环境支持 async/await，显然也可以使用它们。

{{<callout note 提示>}}

如果您的浏览器支持流式编译，则示例 2-4 中的代码不是实例化 WebAssembly 模块的首选方式。 我们现在将使用它，只是为了让您看到步骤，但我将在本书后面讨论首选方法。

{{</callout>}}

示例 2-4. 在 JavaScript 中实例化 Wasm 模块

```javascript
function fetchAndInstantiate (url, importObject) {return fetch (url).then (response =>
        response.arrayBuffer ()).then (bytes =>
        WebAssembly.instantiate (bytes, importObject)
    ).then (results =>
        results.instance
    );
}
```

一旦拥有此功能，在 HTML 中使用它就很简单了。在示例 2-5 中，您可以看到这个过程是如何工作的。

示例 2-5. 在网页上实例化 Wasm 组件

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
      fetchAndInstantiate ('hello.wasm').then (function (instance) {
        var ho = instance.exports.how_old (2021,2000);
        var ageEl = document.getElementById ('age');
        ageEl.innerText=ho;
      });
    </script>
  </body>
</html>
```

在这个例子中，我们建立了一个 ID 为 age 的 `<span>`。它目前是空的。我们将用调用 WebAssembly 函数的结果来填充它。我们的 HTML 文件的其余部分并不奇怪。我们在`<head>`元素中包括可重复使用的实例化代码。在这个文件的底部，我们看到一个嵌入的 `<script>` 元素，它调用 `fetchAndInstantiate ()` 函数。它传入了对 `hello.wasm` 文件的本地引用，所以我们也必须通过 HTTP 提供这个文件。

该函数返回一个 *Promise*。我们会收到实例化的 Wasm 模块实例的副本，并可以调用通过模块的导出部分公开的方法。 请注意，我们正在传递 JavaScript 的数字字符，但这些数字会被函数识别和接受。 调用过程请求数字 21，然后将其存储在<span>我们之前讨论的空 `</span>` 的 `innerText ` 中。

我们必须通过 HTTP 提供 HTML、JavaScript 和 Wasm 模块，以便在浏览器中运行。 您可以根据需要多次尝试此操作，但是使用 python3（或非 Mac 电脑上的 python），您可以启动服务器并指定一个端口来接受连接：

```bash
brian@tweezer ~/g/w/s/ch02> python3 -m http.server 10003
Serving HTTP on :: port 10003 (http://[::]:10003/) ...
```

如果打开浏览器并将其指向 <http://localhost:10003/index.html>，您应该会看到类似于图 2-6 的内容。随意更改嵌入的 `<script>` 元素中的参数，并验证它是否继续工作。

![图 2-6. 在网页的 JavaScript 中调用导出的 WebAssembly 模块函数](../images/f2-6.png)

显然我们还有很多东西要学，但你现在已经看到了类似于 “Hello, World!” 的示例。 希望您了解 WebAssembly 工作原理的基础知识。
