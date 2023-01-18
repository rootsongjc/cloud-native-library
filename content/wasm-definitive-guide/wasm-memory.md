---
linktitle: 第 4 章：WebAssembly 内存
summary: WebAssembly 模块。
weight: 5
icon: book-reader
icon_pack: fas
draft: false
title: WebAssembly 内存
date: '2023-01-16T00:00:00+08:00'
type: book # Do not modify
---

> 也许有一天，这也会成为令人愉快的回忆。
>
> ——Virgil

如果 WebAssembly 要表现得像一个普通的运行时环境，它需要一种方法来分配和释放内存，以便进行数据处理。在这一章中，我将向你介绍它是如何模拟这种行为以提高效率的，但又不会出现 C 和 C++ 等语言的典型内存操作问题的风险（即使那是我们正在运行它们）。由于我们有可能在互联网上下载任意代码，这是一个重要的安全考虑。

计算的整个概念通常涉及某种形式的数据处理。无论我们是在拼写检查文档、处理图像、进行机器学习、对蛋白质进行排序、玩视频游戏、看电影，还是简单地在电子表格中计算数字，我们通常都在与任意的数据块进行交互。在这些系统中，最关键的性能考虑之一是如何将数据送到它需要的地方，以便以某种方式询问或转换它。

中央处理单元（CPU）在寄存器或缓存中的数据可用时工作最快。显然，这些都是非常小的容器，所以大型数据集永远不会被完整地加载到 CPU 上。我们必须花费一些精力将数据移入和移出内存。等待数据被加载到这些位置之一的代价是 CPU 时钟时间。这就是它们变得如此复杂的原因之一。现代芯片有各种形式的多线程、预测性分支和指令重写，在我们从网络中读取主内存，从主内存中读取多级缓存，最后到需要使用的地方时，可以让芯片保持忙碌。

传统程序通常有堆栈内存来管理小的或固定大小的短期变量。他们使用基于堆的内存来管理长期的、任意大小的数据块。这些通常只是分配给程序的内存的不同区域，它们被区别对待。堆栈内存经常被执行过程中被调用的函数所覆盖。堆内存被使用，并在不再需要时被清理掉。如果一个程序耗尽了内存，它可以要求获得更多的内存，但它必须合理地判断如何使用它 [^2]。如今，虚拟分页系统和更便宜的内存使得一台典型的计算机完全可能拥有几十 GB 的内存。能够快速有效地访问潜在的大数据集的单个字节是软件运行时性能良好的一个关键。

WebAssembly 程序需要一种方法来模拟这些内存块，而不需要真正不受限制地访问我们计算机内存的隐私。幸运的是，这里有一个很好的故事，可以平衡方便、速度和安全。它从使 JavaScript 能够访问内存中的单个字节开始，但将扩展到 JavaScript 之外，成为主机环境和 WebAssembly 模块之间共享内存的通用方式。

## TypedArray

传统上，JavaScript 无法提供对内存中单个字节的方便访问。这就是为什么对时间敏感的底层功能通常由浏览器或某种插件提供。即使是 Node.js 应用程序也经常要用一种比 JavaScript 更能处理内存操作的语言来实现一些功能。这使情况变得复杂，因为 JavaScript 是一种解释型语言，你需要一种有效的机制，在解释型、可移植代码和快速编译代码之间来回切换控制流。这也使部署变得更加棘手，因为应用程序的一部分本身就是可移植的，而另一部分需要在不同的操作系统上获得本地库的支持。

在软件开发中通常有一个权衡：语言要么是快速的，要么是安全的。当你需要原始速度时，你可能会选择 C 或 C++，因为它们在使用和操作内存中的数据时提供很少的运行时检查。因此，它们是非常快的。当你需要安全时，你可以选择一种对数组引用进行运行时边界检查的语言。速度权衡的缺点是，事情要么很慢，要么内存管理的负担落到了程序员身上。不幸的是，忘记分配空间，重复使用已释放的内存，或者在完成后没有取消空间分配，都是极其容易出错的。这就是用这些快速语言编写的应用程序经常出现错误，容易崩溃，并成为许多安全漏洞 [^3] 的来源之一。

像 Java 和 JavaScript 这样的带有垃圾收集的语言使开发者摆脱了管理内存的负担，但作为一种交换，在运行时往往会产生性能损耗。运行时的一个部分必须不断地寻找未使用的内存并释放它。性能开销使得许多这样的应用程序无法预测，因此不适合嵌入式应用程序、金融系统或其他对时间敏感的用例。

只要创建的内存大小适合你想放的东西，分配内存就不是一个大问题。棘手的部分是知道何时进行清理。显然，在程序用完之前释放内存是不好的，但在不再需要的时候不这样做是低效的，你可能会耗尽内存。像 Rust 这样的语言在便利性和安全性之间取得了良好的平衡。编译器迫使你更清楚地表达你的意图，但当你这样做的时候，它可以更有效地为你清理。

如何在运行时管理这一切往往是一种语言及其运行时的决定性特征之一。因此，并不是每一种语言都需要同样水平的支持。这也是 WebAssembly 的设计者在 MVP 中没有过度指定垃圾收集等功能的原因之一。

JavaScript 是一种灵活的动态语言，但它在历史上并没有使处理大型数据集的单个字节变得容易或高效。这使得底层库的使用变得复杂，因为数据必须被复制到 JavaScript 原生的格式中，这是不高效的。阵列类存储 JavaScript 对象，这意味着必须准备好处理任意的类型。许多 Python 的灵活容器 ，也同样是灵活和臃肿的 [^4]。通过指针快速遍历和操作内存是连续块中数据类型统一性的产物。字节是最小的可寻址单位，特别是在处理图像、视频和声音文件时。

数值数据需要更多的努力。一个 16 位的整数需要占用两个字节。一个 32 位的整数，需要四个字节。字节数组中的位置 0 可能代表数据数组中的第一个这样的数字，但第二个数字将从位置 4 开始。

JavaScript 添加了 TypedArray 接口来解决这些问题，最初是为了改善 WebGL 的性能 。这些是内存的一部分，可以通过 ArrayBuffer 实例，可以被视为特定数据类型的同质块。可用的内存受制于 ArrayBuffer 实例，但它可以以方便传递给本地库的格式在内部存储。

在例 4-1 中，我们看到了创建一个 32 位无符号整数的类型化数组的基本功能。

例 4-1. 在 Uint32Array 中创建 10 个 32 位整数

```javascript
var u32arr = new Uint32Array (10);
u32arr [0] = 257;
console.log (u32arr);
console.log ("u32arr length:" + u32arr.length);
```

调用的输出应该是这样的：

```
Uint32Array (10) [257, 0, 0, 0, 0, 0, 0, 0, 0, 0]
u32arr length: 10
```

正如你所看到的，这和你所期望的整数数组一样工作。请记住，这些是 4 字节的整数（因此类型名称中的 32）。在例 4-2 中，我们从 Uint32Array 中获取了 ArrayBuffer 的底层，并将其打印出来。这表明它的长度是 40。接下来，我们用一个 Uint8Array 包裹缓冲区，代表一个无符号字节的数组，并打印出它的内容和长度。

例 4-2. 将 32 位整数作为一个 8 位字节的缓冲区来访问

```javascript
var u32buf = u32arr.buffer;
var u8arr = new Uint8Array (u32buf);
console.log (u8arr);
console.log ("u8arr length:" + u8arr.length);
```

该代码产生了以下输出：

```
ArrayBuffer {byteLength: 40}
Uint8Array (40) [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, ...]
u8arr length: 40
```

ArrayBuffer 表示原始的基础字节。TypedArray 是基于指定的类型大小的这些字节的一个相互预设的视图。因此，当我们初始化 Uint32Array 的长度为 10 时，这意味着 10 个 32 位的整数，这需要 40 个字节来表示。分离出来的缓冲区被设置成这么大，所以它可以容纳所有 10 个整数。由于 Uint8Array 的大小定义，它将每个字节视为一个独立的元素。

看一下图 4-1，你就会明白发生了什么事。Uint32Array 的第一个元素（位置 0）是简单的值 257。这是 ArrayBuffer 中底层字节的一个解释视图。Uint8Array 直接反映了缓冲区的基础字节。图中底部的比特模式反映了前两个字节的每个字节的比特。

![图 4-1. 代表值 257](../images/f4-1.png)

你可能会惊讶于前两个字节里有 1 的存在。这是由于当我们在内存中存储数字时，出现了一个令人困惑的概念，叫做 endianess [^5]。在这种情况下，小 endianess 系统会把最不重要的字节放在第一位（1）。大 endianess 系统会先存储 0。从总体上看，它们的存储方式并不重要，但不同的系统和协议会选择其中之一。你只需要跟踪你看到的是哪种格式。

如前所述，TypedArray 类最初是为 WebGL 引入的，但从那时起，它们已经被其他 API 采用，包括 Canvas2D、XMLHttpRe-quest2、File、Binary WebSockets 等等。请注意，这些都是较低级别的、面向性能的 I/O 和可视化 API，必须与本地库对接。底层的内存表示可以在这些层之间有效传递。正是由于这些原因，它们对 WebAssembly 内存实例也是有用的。

## WebAssembly 内存实例

WebAssembly 内存是一个与模块相关的底层 ArrayBuffer（或 SharedArrayBuffer，我们后面会看到）。目前，MVP 限制一个模块只能有一个实例，但这很可能在不久之后就会改变。一个模块可以创建自己的 Memory 实例，也可以从它的主机环境中得到一个。这些实例可以被导入或导出，就像我们到目前为止对函数所做的那样。在模块结构中也有一个相关的 Memory 部分，我们在 [第三章](../wasm-modules/) 中跳过了这个部分。 因为我们还没有涉及这个概念。现在我们将弥补这一遗漏。

在例 4-3 中，我们有一个 Wat 文件，它定义了一个 Memory 实例，并以 "memory" 的名字将其导出。这表示一个连续的内存块被限制在一个特定的 ArrayBuffer 实例中。这是我们模拟内存中类似 C/C++ 的同质字节数组的能力的开始。每个实例是由一个或多个 64KB 的内存页块组成的。在这个例子中，我们把它初始化为一个页面，但允许它增长到 10 个页面，总数为 640 千字节，这对任何人来说都应该是足够的 [^6]。你马上就会看到如何增加可用的内存。现在，我们只是要把字节 1、1、0 和 0 写到缓冲区的开头。`i32.const` 指令将一个常量值加载到堆栈中。我们想写到缓冲区的开头，所以我们使用 `0x0` 这个值。data 指令是对 Memory 实例的部分进行初始化的方便之举。

例 4-3. 在 WebAssembly 模块中创建并导出一个 Memory 实例

```c
(module
  (memory (export "memory") 1 10)
  (data (i32.const 0x0) "\01\01\00\00")
)
```

如果我们用 wat2wasm 将这个文件编译成二进制表示，然后调用`wasm-objdump`，我们看到了一些我们还没有遇到过的新细节。

```bash
brian@tweezer ~/g/w/s/ch04> wasm-objdump -x memory.wasm 
memory.wasm: file format wasm 0x1
Section Details:
    Memory [1]:
     - memory [0] pages: initial=1 max=10
    Export [1]:
     - memory [0] -> "memory"
    Data [1]:
     - segment [0] memory=0 size=4 - init i32=0
      - 0000000: 0101 0000
```

在 Memory 部分有一个配置好的 Memory 实例，反映了我们的初始规模为 1 页，最大规模为 10 页。我们看到它在 Export 部分被导出为"memory"。我们还看到，Data 部分已经用我们写进的四个字节初始化了我们的 Memory 实例。

现在我们可以通过在浏览器中的一些 JavaScript 中导入我们导出的内存来使用它。在这个例子中，我们将加载模块并获取 Memory 示例。然后，我们显示以字节为单位的缓冲区大小、页数，以及当前在内存缓冲区中的内容。

我们的 HTML 文件的基本结构如例 4-4 所示。我们有一系列的 `<span>` 元素，这些元素将通过一个名为 `show Details ()` 的函数来填充细节，该函数将获取对我们内存实例的引用。

例 4-4. 在浏览器中显示内存细节

```html
<!DOCTYPE html>
<html lang="en">
 <head> 
  <meta charset="utf-8" /> 
  <link rel="stylesheet" href="bootstrap.min.css" /> 
  <title>Memory</title> 
  <script src="utils.js"></script> 
 </head> 
 <body> 
  <div class="container"> 
   <h1>Memory</h1> 
   <div>Your memory instance is <span id="mem"></span> bytes.</div> 
   <div>It has this many pages: <span id="pages"></span>.</div> 
   <div>Uint32Buffer [0] = <span id="firstint"></span>.</div> 
   <div>Uint8Buffer [0-4] = <span id="firstbytes"></span>.</div> 
  </div> 
  <button id="expand">Expand</button> 
  <script>
<!-- Shown below --> </script>  
 </body>
</html>
```

在 例 4-5 中，我们看到了`<script>`元素的 JavaScript。首先看一下`fetchAndInstantiate ()`的调用。在加载模块方面，它的行为与我们之前看到的相同。在这里，我们通过出口部分获得对 Memory 实例的引用。我们为我们的按钮附加了一个`onClick ()` 函数，我们马上就会处理。

例 4-5. 我们的例子的 JavaScript 代码

```javascript
function showDetails (mem) {
  var buf = mem.buffer;
  var memEl = document.getElementById ('mem');
  var pagesEl = document.getElementById ('pages');
  var firstIntEl = document.getElementById ('firstint'); 
  var firstBytesEl = document.getElementById ('firstbytes');
  memEl.innerText=buf.byteLength;
pagesEl.innerText=buf.byteLength/ 65536;
var i32 = new Uint32Array (buf); var u8 = new Uint8Array (buf);
firstIntEl.innerText=i32 [0];
firstBytesEl.innerText= "[" + u8 [0] + "," + u8 [1] + "," +
u8 [2] + "," + u8 [3] + "]"; fetchAndInstantiate ('memory.wasm').then (function (instance) {
};
var mem = instance.exports.memory;
var button = document.getElementById ("expand"); button.onclick = function () {try { mem.grow (1);
showDetails (mem); } catch (re) {alert ("You cannot grow the Memory any more!");
    };
};
  showDetails (mem);
});
```

最后，我们调用`showDetails ()`函数并传入我们的 mem 变量。这个函数将检索底层的 ArrayBuffer 和对我们各种`<span>`元素的引用，以显示细节。缓冲区的长度被存储在我们第一个`<span>`的`innerText`字段中。页数是这个长度除以 64KB 来表示页数。然后，我们用 Uint32Array 包裹 ArrayBuffer，这使得我们能够以 4 字节的整数来获取内存值。它的第一个元素显示在下一个`<span>` 中。我们还用 Uint8Array 包裹我们的 ArrayBuffer，并显示前四个字节。经过我们前面的讨论，图 4-2 中显示的细节所示的细节应该不会让你感到惊讶。

![图 4-2. 显示 Memory 的细节](../images/f4-2.png)

`onClick ()` 函数在 Memory 实例上调用了一个方法，将分配的大小增加了一页的内存。这导致原来的 ArrayBuffer 从实例中分离出来，现有的数据被复制过来。如果我们成功了，我们重新调用 `showDetails ()` 函数并提取新 ArrayBuffer。如果按钮被按下一次，你应该看到这个实例现在代表了两页内存，代表了 128KB 的内存。开始时的数据应该没有变化。

如果你按下按钮太多次，分配的页数将超过最大指定量 10 页。这时，就不可能再扩展内存了，将抛出一个 RangeError。当这种情况发生时，我们的例子将弹出一个警告窗口。

## 使用 WebAssembly 内存 API

我们在前面的例子中使用的 `grow ()` 方法是 WebAssembly JavaScript API 的一部分，MVP 希望所有主机环境都能提供。我们可以扩大对这个 API 的使用，并向另一个方向发展。也就是说，我们可以在 JavaScript 中创建一个 Memory 实例，然后让它对一个模块可用。请记住，目前每个模块只有一个实例的限制。

在随后的章节中，我们将看到对内存的更精细的使用，但我们将希望使用比 Wat 更高级别的语言来做任何严肃的事情。现在，我们将把我们的例子保持在较简单的方面，但仍将尝试扩展到我们所看到的以外的地方。

我们将从 HTML 开始，以便你能看到整个工作流程，然后我们将深入研究新模块的细节。在例 4-6 中，你可以看到我们使用的 HTML 结构与到目前为止所使用的相似。有一个 ID 为 container 的 `<div>` 元素，我们将在其中放置一系列的斐波那契数。如果你不熟悉这些数字，它们在很多自然系统中都非常重要，我鼓励你自己去研究它们。前两个数字被定义为 0 和 1，随后的数字被设定为前两个数字之和。所以第三个数字将是 1（0+1）。第四个数字将是 "2"（1+1）。第五个数字将是 3（2+1），等等。

例 4-6. 在 JavaScript 中创建一个 Memory 并将其导入到模块中

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="bootstrap.min.css">
    <title>Fibonacci</title>
    <script src="utils.js"></script>
  </head>
  <body>
    <div id="container"></div>

    <script>
      var memory = new WebAssembly.Memory ({initial:10, maximum:100});

      var importObject = {js: { mem: memory}
      };

      fetchAndInstantiate ('memory2.wasm', importObject).then (function (instance) {
	  var fibNum = 20;
	  instance.exports.fibonacci (fibNum);
	  var i32 = new Uint32Array (memory.buffer);

	  var container = document.getElementById ('container');

	  for (var i = 0; i < fibNum; i++) {container.innerText += `Fib [${i}]: ${i32 [i]}\n`;
	  }
      });

    </script>
  </body>
</html>
```

实际的计算是用 Wat 写的，如例 4-7 所示，但是在我们到达那里之前，我们看到在`<script>`元素的第一行创建了 Memory 实例。我们使用的是 JavaScript API，但其意图与我们在`<script>`中使用的 (memory) 元素是一样的。在例 4-3 中我们创建一个初始大小为一页的内存，最大大小为 10 页。在这种情况下，我们永远不会需要超过一页的内存，但你现在看到了如何做到这一点。内存实例是通过`importObject` 提供给模块的。正如你即将看到的，Wasm 模块中的函数将接受一个参数，表明要向 Memory 缓冲区写入多少个斐波那契数。在这个例子中，我们将传入一个 20 的参数。

一旦我们的模块被实例化，我们就调用其导出的 `fibonacci ()` 函数。我们可以访问上面的内存变量，所以我们可以在函数调用完成后直接检索底层的 Array Buffer。因为斐波那契数是整数，我们将缓冲区包裹在一个 Uint32Array 实例中，这样我们就可以在各个元素上进行迭代。当我们检索这些数字时，我们不必担心它们是 4 字节的整数。在读取每个值时，我们用数字的字符串版本扩展我们容器元素的 `innerText`。

例 4-7 中的计算比我们到目前为止看到的任何 Wat 都要复杂得多，但是通过分块计算，你应该能够弄清楚。

例 4-7. 用 Wat 表示的斐波那契计算方法

```c
(module
 (memory (import "js" "mem") 1) ①
 (func (export "fibonacci") (param $n i32) ②
    (local $index i32) ③
    (local $ptr i32) ④

    (i32.store (i32.const 0) (i32.const 0)) ⑤
    (i32.store (i32.const 4) (i32.const 1))

    (local.set $index (i32.const 2)) ⑥
    (local.set $ptr (i32.const 8))

    (block $break ⑦
      (loop $top ⑧
            (br_if $break (i32.eq (local.get $n) (local.get $index))) ⑨
	    (i32.store ⑩
	       (local.get $ptr)
	       (i32.add
	         (i32.load (i32.sub (local.get $ptr) (i32.const 4)))
		 (i32.load (i32.sub (local.get $ptr) (i32.const 8)))
	       )
	    )

	    (local.set $ptr (i32.add (local.get $ptr) (i32.const 4))) #11
	    (local.set $index (i32.add (local.get $index) (i32.const 1)))
	    (br $top) #12
      )
    )
   )
 )
```

1. Memory 是从主机环境中导入的。
2. fibonacci 函数被定义并导出。
3. `$index` 是我们的数字计数器。
4. `$ptr` 是我们在 Memory 实例中的当前位置。
5. `i32.store` 函数将一个值写到缓冲区的指定位置。
6. `$index` 变量被提前为 2，$ptr 被设置为 8。
7. 定义一个命名的块，以便在我们的循环中返回。
8. 在块中定义一个命名的循环。
9. 当 `$index` 变量等于 `$n` 参数时，我们就脱离了循环。
10. 将前两个元素的总和写到 `$ptr` 的当前位置。
11. 将 `$ptr` 变量提前 4，`$index` 变量提前 1。
12. 离开循环到顶部。

希望附加到例 4-7 中的数字说明是有意义的，但是考虑到它的复杂性，有必要对它进行简单的讨论。这是一个基于堆栈的虚拟机，所以所有的指令都涉及对堆栈顶部的操作。在第一个调用中，我们导入了 JavaScript 中定义的内存。它代表了默认分配的页，对现在来说应该足够了。虽然这是一个正确的实现，但它并不是一个安全的实现。坏的输入可能会扰乱流程，但在我们引入更高级别的语言支持后，我们会更关心这个问题，因为在那里更容易处理这些细节。

输出的函数被定义为接受一个参数 `$n`，代表要计算的斐波那契数的数量 [^7]。我们使用了两个定义在第三和第四个调用的局部变量。第一个表示我们正在处理的数字，默认为 0。第二个将作为内存中的一个指针。它将作为索引进入内存缓冲区。请记住，i32 数据值代表 4 个字节，所以 `$index` 的每一次前进都会涉及到 `$ptr` 前进 4。 在交互的这一边，我们没有 TypedArrays 的好处，所以我们必须自己处理这些细节。同样，更高级别的语言将使我们免受这些细节的影响。

根据定义，前两个斐波那契数是 0 和 1，所以我们把这些写进缓冲区。`i32.store` 把一个整数值写到一个位置。它希望在堆栈顶部找到这些值，所以语句的下两部分调用了 `i32.const` 指令，将指定的值推到堆栈顶部。首先，偏移量为 0 表示我们要写到缓冲区的开头。第二行将数字 0 推到堆栈中，表示我们要写到 0 的位置。 下一行重复下一个斐波那契数字的过程。前一行的 i32 占用了 4 个字节，所以我们把值 1 写到了位置 4。

下一步是对剩余的数字进行迭代，每个数字都定义为前两个数字之和。这就是为什么我们需要从刚才的两个数字开始。我们将 `$index` 变量提前到 2，所以我们需要 `$n-2` 的循环迭代。我们已经写了两个 i32 的整数，所以我们把 `$ptr` 推进到 8。

Wat 引用了几个 WebAssembly 指令，在本书中会一一介绍。在这里你可以看到一些循环的结构。我们在第七个调用处定义了一个块，并给它一个 `$break` 标签。下一步将引入一个循环，其入口点为 `$top`。循环中的第一条指令检查 `$n` 和 `$index` 是否相等，表明我们已经处理了所有的数字。如果是，它将跳出循环。如果不是，则继续进行。

在第 10 个调用的 `i32.store` 指令写到 `$ptr` 位置。变量的值是用 `get_local` 推到堆栈顶部的。要写到那里的值是前面两个数字的值相加。`i32.add` 期望在栈顶也能找到它的两个加法。所以我们加载比 `$ptr` 少 4 的整数位置。这代表 `$n - 1`。然后我们加载存储在 `$ptr` 位置的整数减去 8，这代表 `$n - 2`。`i32.add` 将这些加数从堆栈顶部弹出，并将它们的总和写回顶部。现在堆栈顶部包含这个值和当前 `$ptr` 值的位置，这就是 `i32.store` 所期望的。

下一步是将 `$ptr` 推进 4，因为我们现在已经将另一个斐波那契数写入缓冲区。我们将 `$n` 前进一个，然后中断到循环的顶部，重复这个过程。一旦我们写了 `$n` 个数字到缓冲区，这个函数就会返回。它不需要返回任何东西，因为主机环境可以访问 Memory 缓冲区，并且可以用 TypedArrays 直接读出结果，正如我们前面看到的那样。

将我们的 HTML 加载到浏览器中并显示前 20 个斐波那契额数字的结果如图 4-3 所示。

![图 4-3. 从 Memory 实例中读取斐波那契额序列](../images/f4-3.png)

如果经常处理这种级别的细节是很烦人的，但幸运的是，你不必这样做。不过，了解事物在这一层次的工作原理是很重要的，我们可以模拟线性内存的连续块，以实现高效处理。

## 最后是字符串

在我们继续之前的最后一次讨论如何将操作字符串。在本书后面的章节中，还有很多工具会让事情变得更加简单，但我们可以利用 Wat 中的一些便利条件，将字符串写入 Memory 缓冲区，并在 JavaScript 端读出。

在例 4-8 中，你可以看到一个非常简单的模块，它导出了一个单页的 Memory 实例。然后它使用一条数据指令将一串字节写入模块内存的某个位置。它从位置 0 开始，将字节写入随后的字符串中。这是一种方便，不必将多字节的字符串转换为它们的组成字节，如果你愿意当然也可以。这个字符串有一个日语发音，然后是它的英语翻译 [^8]。

例 4-8. 在 Wat 中对字符串的一个简单使用

```c
(module
  (memory (export "memory") 1)
  (data (i32.const 0x0) "私は横浜に住んでいました。I used to live in Yokohama.")
)
```

一旦我们将 Wat 编译到 Wasm，我们就会发现我们的模块中有一个新的填充部分。你可以通过`wasm-objdump`命令看到这一点：

```bash
brian@tweezer ~/g/w/s/ch04> wasm-objdump -x strings.wasm 

strings.wasm: file format wasm 0x1

Section Details:

Memory [1]:
     - memory [0] pages: initial=1
    Export [1]:
     - memory [0] -> "memory"
    Data [1]:
     - segment [0] memory=0 size=66 - init i32=0
      - 0000000: e7a7 81e3 81af e6a8 aae6 b59c e381 abe4  ................
      - 0000010: bd8f e382 93e3 81a7 e381 84e3 81be e381  ................
      - 0000020: 97e3 819f e380 8249 2075 7365 6420 746f  .......I used to
      - 0000030: 206c 6976 6520 696e 2059 6f6b 6f68 616d   live in Yokoham
      - 0000040: 612e
```

Memory、Export 和 Data 部分填写了我们写入内存的字符串的细节。实例是这样初始化的，所以当主机环境从缓冲区读取时，这些字符串已经在那里了。

在例 4-9 中，你可以看到，我们有一个 `<span>` 用于日语句子，一个用于英语句子。为了提取各个字节，我们可以用 Uint8Array 包住我们从模块中导入的 Memory 实例缓冲区。注意，我们只包裹了前 39 个字节。这些字节通过 TextDecoder 实例被解码为 UTF-8 字符串，然后我们为日语句子设置指定的 `<span>` 的 innerText。然后，我们用一个单独的 Uint8Array 包住缓冲区中从第 39 位开始的部分，包括随后的 26 个字节。

例 4-9. 从一个导入的 Memory 实例中读取字符串

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="bootstrap.min.css">
    <title>Reading Strings From Memory</title>
    <script src="utils.js"></script>
  </head>
  <body>
    <div>
      <div>Japanese: <span id="japanese"></span></div>
      <div>English: <span id="english"></span></div>
    </div>
    <script>
      fetchAndInstantiate ('strings.wasm').then (function (instance) {
	  var mem = instance.exports.memory;

	  var bytes = new Uint8Array (mem.buffer, 0, 39);
          var string = new TextDecoder ('utf8').decode (bytes);
          var japanese = document.getElementById ('japanese');
	  japanese.innerText = string;

	  bytes = new Uint8Array (mem.buffer, 39, 26);
	  string = new TextDecoder ('utf8').decode (bytes);
          var english = document.getElementById ('english');
	  english.innerText = string;
      });

    </script>
  </body>
</html>
```

在图 4-4 中，我们看到从缓冲区中读出字节并将其渲染为 UTF-8 字符串的成功结果。

![图 4-4. 从 Memory 实例中读取字符串](../images/f4-4.png)

尽管这些结果很酷，但我们是如何知道要包多少字节，在哪个位置寻找字符串的？一个小小的侦探工作可以帮助我们。一个大写字母 "I" 在十六进制中表示为 49。`wasm-objdump` 的输出给了我们每个字节在数据段的偏移量。我们在以 `0000020:` 开始的一行中第一次看到了 49 这个值。49 代表第七个字节，所以第二句话从 27 的位置开始，也就是 `2×16+7` 的十进制，所以是 39。日语串代表 0 到 39 之间的字节。英文字符串从第 39 位开始。

但是，等一下！事实证明，我们在英语句子上算错了，我们偏离了一个。为了从 WebAssembly 模块中获得字符串，这似乎是一个麻烦的、容易出错的工作。即使在这么底层用困难的方法做事，也可以处理得更好。我们先把字符串的位置写出来，这样我们就不用自己去想了。

例 4-10 看起来更复杂。我们现在有两个数据段。第一个数据段写了第一个字符串的起始位置和长度，然后是第二个字符串的相同信息。因为我们使用相同的缓冲区来写索引和字符串，所以我们必须注意位置问题。

由于我们的字符串不是很长，我们可以使用单字节作为偏移量和长度。这在一般情况下可能不是一个好的策略，但它会显示出一些额外的灵活性。所以，我们写出值 4 和值 27。这代表了 4 个字节的偏移量和 39 的长度。偏移量是 4，因为我们在缓冲区的开头有这四个数字（作为单字节），需要跳过它们来获取字符串。正如你现在所知道的，27 是 39 的十六进制，是日语字符串的长度。英语句子将从索引 4+39=43 开始，在十六进制中是 2b（2×16+11），长度为 27 字节，在十六进制中是 1b（1×16+11）。

第二个数据段从位置 0x4 开始，因为我们需要跳过这些偏移量和长度。

例 4-10. 在 Wat 中对字符串的更复杂的使用

```c
(module
  (memory (export "memory") 1)
  (data (i32.const 0x0) "\04\27\2b\1b")
  (data (i32.const 0x4) "私は横浜に住んでいました。I used to live in Yokohama.")
)
```

在例 4-11 中，我们看到了读出字符串的另一面。现在当然更复杂了，但也更省力了，因为模块准确地告诉了我们该去哪里找。使用 TypedArrays 的另一个选择是 DataView，它允许你从 Memory 缓冲区中提取任意的数据类型。它们不需要像普通的 TypedArrays（例如 Uint32Array）那样是同质的。

例 4-11. 从 Memory 缓冲区读取我们的索引字符串

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <link rel="stylesheet" href="bootstrap.min.css">
    <title>Reading Strings From Memory</title>
    <script src="utils.js"></script>
  </head>
  <body>
    <div>
      <div>Japanese: <span id="japanese"></span></div>
      <div>English: <span id="english"></span></div>
    </div>
    <script>
      fetchAndInstantiate ('strings2.wasm').then (function (instance) {
	  var mem = instance.exports.memory;

	  var dv = new DataView (mem.buffer);
	  var start = dv.getUint8 (0);
	  var end = dv.getUint8 (1);

	  var bytes = new Uint8Array (mem.buffer, start, end);
	  var string = new TextDecoder ('utf8').decode (bytes);
          var japanese = document.getElementById ('japanese');
	  japanese.innerText = string;

	  start = dv.getUint8 (2);
	  end = dv.getUint8 (3);

	  bytes = new Uint8Array (mem.buffer, start, end);
	  string = new TextDecoder ('utf8').decode (bytes);
          var english = document.getElementById ('english');
	  english.innerText = string;
      });

    </script>
  </body>
</html>
```

因此，我们用一个 DataView 实例来包装导出的 Memory 缓冲区，并通过调用`getUint8 ()` 函数在位置 0 和位置 1 上读取前两个字节。这些代表了日语字符串在缓冲区中的位置和偏移。除了不再使用硬编码的数字之外，我们之前的代码的其余部分都是一样的。接下来我们读出位置 2 和 3 的两个字节，代表英语句子的位置和长度。这也被转换为 UTF-8 字符串，并且这次如图 4-5 所示，更新正确。

![图 4-5. 从 Memory 实例中读取索引和字符串](../images/f4-5.png)

你可以试着自己创建一个更加灵活的方法，告诉你有多少个字符串需要读取，它们的位置和长度是多少。读取它的 JavaScript 可以做成一个循环，整个过程应该更加灵活。

关于 Memory 实例还有更多的知识，你将在后面看到，但现在，我们已经涵盖了足够多的 WebAssembly 的基础知识，试图在 Wat 中用手做更复杂的事情将是太痛苦了。因此，是时候使用更高级的语言，如 C 语言了。

## 注释

[^1]: 寄存器是一个片上存储器的位置，通常向指令提供它需要执行的内容。
[^2]: 我的第一台电脑是 Atari 800，开始时只有 16 千字节的内存。有一天，我父亲带着一张 32KB 的扩展卡回家，这真是一件大好事！
[^3]: Ryan Levick 在他的
[^4]: NumPy 库通过重新实现 C 语言数组中的同质存储，并具有在这些结构上运行的数学函数的编译形式来帮助解决这个问题。
[^5]: 引用自 Jonathan Swift 的《格列佛游记》。
[^6]: 不错的尝试，不是，比尔・盖茨从来没说过这句话！
[^7]: 作为一个思考练习，在我们的 i32 数据类型溢出之前，`$n` 有可能被设置为什么？如何解决这个问题？
[^8]: 这是真的！
