---
linktitle: 第 6 章：应用 WebAssembly—— 在浏览器中运行遗留代码
summary: 使用 C/C++ 和 WebAssembly。
weight: 7
icon: book-reader
icon_pack: fas
draft: false
title: "应用 WebAssembly：在浏览器中运行遗留代码"
date: '2023-01-25T00:00:00+08:00'
type: book # Do not modify
---

> 无论你走到哪里，你都在那里。
>
> ——Buckaroo Banzai

现在是时候让我们更仔细地看看在浏览器中调用 C/C++ 代码的过程了。这些语言中的大多数代码都不是为了在浏览器中以下载的形式运行。但是，正如香港骑士（译者注：The Hong Kong Cavaliers，电影《天生爱神》中的主角 Buckaroo Banzai 的乐队名称）的队长在本章开头的引文中告诉我们的那样，偶尔你会发现自己在某个意想不到的新地方，但那里仍然只有你 [^1]。

我们对在浏览器中调用 C/C++ 代码感兴趣，原因有很多。取代 JavaScript 并不是其中之一。至少对大多数人来说不是。相反，我们有大量的用 C 和 C++ 等语言编写的遗留代码。其中有很多是非常有用的，如果能在我们的网络应用程序中使用这些代码，那就太好了。其中一些可能是将组织与遗留系统联系在一起的。能够通过浏览器分发这些代码将是一个很大的进步。

此外，有些问题根本不适合用 JavaScript 来写。可以选择用另一种语言来编写你的应用程序的那一部分，而不需要一个单独的运行时，这是非常引人注目的。而且，正如我们的最后一个用例所表明的那样，对于敏感和棘手的软件（如加密算法）来说，有来自可信来源的可信代码提供证明是真正有价值的。能够简单地重新编译来自你所认识的人的现有代码，他们知道自己在做什么，这也是一种有用的能力。

在上一章中，我们展示了使用常规的支持 WebAssembly 的 C 编译器（如 clang）和一些头和库的依赖性管理来实现基本的集成是可能的。然而，必须提供我们自己的标准库版本，并手动将 C 代码连接到所提供的 JavaScript 上，这样做很快就会过时。

幸运的是，[Emscript 项目](https://emscripten.org/) 奠定了基础，使之成为一个比其他方式更容易的过程。这并不奇怪，因为它的主要开发者 Alon Zakai 和 Luke Wagner 一直是这项工作的幕后推手，从 asm.js 开始，延伸到 WebAssembly MVP，再到规范的进步 ，一直持续到今天。Emscripten [^2] 工具链在这一过程中发挥了重要作用。

该项目是基于 LLVM 平台的。在前面的章节中，我指出它最初有一个自定义的后端，用来生成 asm.js 的可优化的 JavaScript 子集。一旦 WebAssembly 平台被定义，一个新的后端就能生成 Wasm 二进制文件。

不幸的是，这只是解决方案的一部分。还需要支持数据进出内存，链接模块，包装现有的库，等等。一个提供用户界面或监听网络请求的 C 语言程序经常在一个相当紧密的循环中响应输入活动。鉴于浏览器默认为单线程环境，这种主循环会出现操作上的不匹配。Emscripten 工具链已被修改，以解决在试图将本地 C/C++ 移植到我们的网络环境中运行时可能出现的许多类型的问题。与大多数主题一样，本书不可能全面介绍这个项目的所有内容，但我将尝试让你快速入门。

## 适当的 "Hello, World!"

所以，首先要承认：我们本可以在 [第二章](../hello-world/) 中就在浏览器中拥有一个有效的、未经修改的 "Hello, World!" 的例子，早在 2000 年就有了。最后一次，我们将向你展示例 6-1 中的代码。

例 6-1. 典型的 "Hello, World!" 程序用 C 语言表达

```c
#include <stdio.h>
int main () {printf ("Hello, World!\n"); return 0;
}
```

使用 Emscripten C 语言编译器（安装说明见 [附件](../appendix/)），我们只需要告诉它编译 C 代码并生成一些 JavaScript 脚手架。之后，它就会在 Node.js 中未经修改地运行。

```bash
brian@tweezer ~/g/w/s/ch06> emcc hello.c -o hello.js brian@tweezer ~/g/w/s/ch06> ls -laF
total 520
drwxr-xr-x 7 brian staff 224 Mar 1 14:45 ./
drwxr-xr-x 7 brian staff 224 Mar 1 13:02 ../
-rw-r--r-- 1 brian staff 121457 Mar 1 13:05 bootstrap.min.css 
-rw-r--r-- 1 brian staff 76 Mar 1 13:02 hello.c 
-rw-r--r-- 1 brian staff 388 Mar 1 13:07 hello.html 
-rw-r--r-- 1 brian staff 121686 Mar 1 14:45 hello.js
-rwxr-xr-x 1 brian staff 11711 Mar 1 14:45 hello.wasm* 
brian@tweezer ~/g/w/s/ch06> node hello.js
Hello, World!
```

例 6-2 中的 HTML 文件并不是由这个过程生成的，它与我们之前看到的文件有明显的不同。有一个单一的`<script>` 元素来加载我们生成的 JavaScript。我们没有使用到目前为止使用过的 utils.js 文件。相反，我们有一个由前面的命令产生的更长的 JavaScript 文件。看看这个文件的清单！它超过了 120KB。它超过了 120 千字节！这是超过 2000 行的代码。如果你看一看，你会发现自己很快就会迷失。这就是为什么我不想在前面的章节中从那里开始。

例 6-2. 一个与我们所见过的 HTML 文件大不相同的文件

```html
<!DOCTYPE html>
<html lang="en">
 <head> 
  <meta charset="utf-8" /> 
  <link rel="stylesheet" href="bootstrap.min.css" /> 
  <title>Hello, World!</title> 
 </head> 
 <body> 
  <div class="container"> 
   <h1>Hello, World!</h1> 
  </div> 
  <script src="hello.js"></script>  
 </body>
</html>
```

然而，如果我们通过 HTTP 提供这个目录，打开浏览器，并打开 JavaScript 控制台，你会看到非常类似图 6-1 的东西。

![图 6-1. 你被告知的 "Hello, World!" 是不可能的](../images/f6-1.png)

如果你对 `hello.wasm` 文件使用 wasm-objdump 命令，你会注意到有一个导出的 `main ()` 函数。生成的代码很快就超出了我们显示整个文件的能力，所以我将只强调导出部分。

```
...
    Export [13]:
     - memory [0] -> "memory"
     - func [3] <__wasm_call_ctors> -> "__wasm_call_ctors"
     - func [5] <main> -> "main"
     - func [6] <__errno_location> -> "__errno_location"
     - func [50] <fflush> -> "fflush"
     - func [47] <stackSave> -> "stackSave"
     - func [48] <stackRestore> -> "stackRestore"
     - func [49] <stackAlloc> -> "stackAlloc"
     - func [44] <emscripten_stack_init> -> "emscripten_stack_init"
     - func [45] <emscripten_stack_get_free> -> "emscripten_stack_get_free"
     - func [46] <emscripten_stack_get_end> -> "emscripten_stack_get_end"
     - table [0] -> "__indirect_function_table"
     - func [53] <dynCall_jiji> -> "dynCall_jiji"
...
```

你看，有相当多的生成的脚手架来使这一切工作。这些细节相当复杂，但如果你想通过它来追踪你的方式，我建议用 wasm2wat 生成相应的 Wat 文件。从那里，追踪`main ()` 函数（在前面的代码样本中编号为 5）。你将会看到如例 6-3 所示内容。

例 6-3. Wat 的 main 方法

```
...
(func (;5;) (type 5) (param i32 i32) (result i32) (local i32)
call 4
local.set 2
local.get 2
return) 
...
```

最终，你会发现自己回到了生成的 JavaScript 文件。在那里有一个叫做`fd_write`的函数，如例 6-4 所示。这被添加到一个名为`wasi_snapshot_preview1` 的命名空间 。顾名思义，这是一个我们将在后面的讨论中涉及的预览，但主要的一点是，Emscripten 工具链正在生成代码，以解决我们在前面章节中看到的一些底层麻烦。我们将在第 10 章中发现与 Rust 生态系统类似的工具链。

例 6-4. printf 解决方案的一部分

```JavaScript
...
function _fd_write (fd, iov, iovcnt, pnum) {
  //hack to support printf in SYSCALLS_REQUIRE_FILESYSTEM=0
  varnum = 0;
  for (vari = 0; i < iovcnt; i++) {var ptr = HEAP32 [(((iov) + (i * 8)) >> 2)];
    var len = HEAP32 [(((iov) + (i * 8 + 4)) >> 2)];
    for (varj = 0; j < len; j++) {SYSCALLS.printChar (fd, HEAPU8 [ptr + j]);
    }
    num += len;
  }
  HEAP32 [((pnum) >> 2)] = num
  return 0;
}
...
```

当然，我们没有必要深入了解，看看这一切到底是如何进行的。重要的是你要明白，我们实际上不是在典型的标准库意义上调用`printf ()`，而是这个函数被改写成了调用生成的代码。在浏览器中，它将把字符路由到与开发者工具相关的 JavaScript 控制台。在 Node.js 环境中，它将被路由到底层系统控制台。在这个阶段，重要的是，我们的传统应用程序不必改变以在这个新环境中运行，但我们也没有被直接运行本地 C 和 C++ 的可怕前景所困扰。我们在可移植性、安全性和性能之间取得了重要的平衡，这正是 WebAssembly 的意义所在。

生成的代码在 JavaScript 中有一个 Module 对象，它定义了我们的 WebAssembly 代码将占用的运行环境。在 JavaScript 文件的顶部有一些注释，描述了这个对象和它作为两个世界之间的接口的作用。然而，为了保持事情的可控性，我们将专注于其中更小的部分。

我们可以选择的方法之一是使用编译器指令来打开或压制某些生成行为。例如，我们可能不希望我们的 C 程序在加载 JavaScript 代码时立即运行。如果你尝试在没有 `INVOKE_RUN=0` 指令的情况下进行编译，你会看到典型的问候语，就像你在前面的例子中一样。在下面的片段中，注意到在 Node.js 中加载代码时，没有任何东西被打印到命令行。

```bash
brian@tweezer ~/g/w/s/ch06> emcc hello.c -o hello.js -s INVOKE_RUN=0 
brian@tweezer ~/g/w/s/ch06> node hello.js
brian@tweezer ~/g/w/s/ch06>
```

很明显，如果你抑制了自动执行，你将希望能够指示应用程序何时可执行。这可以通过另一个指令来实现：

```bash
brian@tweezer ~/g/w/s/ch06> emcc hello.c -o hello.js ↵
-s INVOKE_RUN=0 -s EXTRA_EXPORTED_RUNTIME_METHODS="['callMain']"
```

在例 6-5 中，你可以看到我们调用`main ()` 函数来响应一个按钮的点击。

例 6-5. 一个延迟的 `main ()` 方法调用

```html
<!DOCTYPE html>
<html lang="en">
 <head> 
  <meta charset="utf-8" /> 
  <link rel="stylesheet" href="bootstrap.min.css" /> 
  <title>Hello, World!</title> 
 </head> 
 <body> 
  <div class="container"> 
   <h1>Hello, World!</h1> 
   <button id="press">Press Me</button> 
  </div> 
  <script src="hello.js"></script> 
  <script>
var button = document.getElementById ("press"); button.onclick = function () {try { Module.callMain ();
} catch (re) {};};
    </script>  
 </body>
</html>
```

在图 6-2 中，可以看到当按钮被按下时，友好的信息被打印到控制台。Firefox 没有显示每条相同的信息，但它显示我已经在右边按了七次按钮。你的浏览器可能会在每次调用时显示一条打印信息。

![图 6-2. 按下按钮所触发的 Hello, World！](../images/f6-2.png)

## 移植第三方代码

我们现在要深入研究将一些现有的代码引入浏览器。这段代码从未打算在 web 上运行，它所做的事情通常不会在浏览器中运行，例如向文件系统写入。不要担心，我们不会破坏浏览器的安全模型，但你会看到这段 C++ 代码基本上可以不加修改地运行。

Emscripten 有大量的选项用于将第三方代码移植到 WebAssembly 中。它可以有效地替代 cc、make 和 configure，这通常使移植过程变得简单。在现实中，你很可能要通过自己的方式来解决你遇到的问题，但你可能会惊讶于这个过程是如此的简单。该 [项目的网站](https://emscripten.org/docs/compiling/Building-Projects.html) 有很好的文件来帮助你。然而，我最喜欢的主题介绍是 Robert Aboukhalil 的 [Level Up With WebAssembly 材料](https://www.levelupwasm.com/)。他告诉你如何将几个不同的开源项目移植到 WebAssembly，以便在浏览器上运行。这包括像俄罗斯方块、乒乓和吃豆人等游戏。与其尝试重新创造他已经完成的杰作，我将专注于一个相对简单和干净的项目。

我花了一些时间来寻找好的候选代码。我想找一些内容丰富但又不至于过于复杂的东西。最终，我在 [Arash Partow 的网站](https://www.partow.net/) 上找到了他收集的优雅、干净、适当授权和有用的 C++ 代码。 如果你去那里，你会发现相当多的有趣的材料。我原本打算使用计算几何库，但决定 Bitmap 库更适合于这本书。

首先，从 [Partow 的网站](http://www.partow.net/programming/bitmap/index.html) 下载代码。下载 ZIP 文件， 解压缩，你会看到三个文件。Makefile 是一个老式的 Unix 构建文件，它有组装有关软件的指示。我们稍后将探讨这个过程 。`bitmap_image.hpp` 文件是主库，`bitmap_test.cpp` 是一个全面的测试集合，用于生成一堆有趣的 Windows 位图图像。这段代码不需要任何特定平台的库。

```bash
brian@tweezer ~/g/w/s/c/bitmap> ls -alF 
total 536
drwxr-xr-x@  5 brian  staff
drwxr-xr-x  11 brian  staff
-rw-r--r--@  1 brian  staff
-rw-r--r--@  1 brian  staff  247721 Dec 31  1999 bitmap_image.hpp
-rw-r--r--@  1 brian  staff   20479 Dec 31  1999 bitmap_test.cpp
```

我把一些注释和许可证的细节从例 6-6 中删除了，为了节省空间。剩下的是构建测试程序的规则结构，即`bitmap_test`。Makefile 的工作方式是建立一个目标，然后是建立目标的依赖关系和规则。作为一种惯例，通常有一个 All 规则，指定前面提到的目标文件名。它依赖于`.cpp`和`.hpp` 文件。如果这两个文件中的任何一个被修改了，我们的可执行文件就需要被重新构建。要做到这一点，make 工具将用 OPTIONS 变量中的选项执行 COMPILER 变量中的文件。作为一个 C/C++ 程序，它还需要与 LINKER_OPT 变量中指定的库链接。在这种情况下，我们要与标准的 C++ 库和基本的数学函数集合进行链接。在库方面，这是最独立的了。clean 目标只是删除了衍生的结果。

Makefile 通常对空格和制表符比较敏感。确保使用制表符来开始缩进的规则行。本书仓库中的代码就是这样做的，但如果你以任何方式修改它，你要确保使用制表符。

例 6-6. 我们的测试程序的 Makefile

```makefile
COMPILER
OPTIONS
LINKER_OPT
= -c++
= -ansi -pedantic-errors -Wall -Wall -Werror -Wextra -o
= -L/usr/lib -lstdc++ -lm
all: bitmap_test
bitmap_test: bitmap_test.cpp bitmap_image.hpp
	$(COMPILER) $(OPTIONS) bitmap_test bitmap_test.cpp $(LINKER_OPT)
clean: rm -f core *.o *.bak *stackdump *~
```

只要你安装了一个正常的 C++ 环境，你就应该能够构建测试程序。

```bash
brian@tweezer ~/g/w/s/c/bitmap> make
c++ -ansi -pedantic-errors -Wall -Wall -Werror -Wextra -o bitmap_test ↵
bitmap_test.cpp -L/usr/lib -lstdc++ -lm brian@tweezer ~/g/w/s/c/bitmap> ls -alF 
total 944
drwxr-xr-x@  6 brian  staff     192 Mar  6 14:35 ./
drwxr-xr-x@ 11 brian  staff     352 Mar  6 13:56 ../
-rw-r--r--@  1 brian  staff     770 Dec 31  1999 Makefile
-rw-r--r--@  1 brian  staff  247721 Dec 31  1999 bitmap_image.hpp
-rwxr-xr-x   1 brian  staff  205032 Mar  6 14:35 bitmap_test*
-rw-r--r--@  1 brian  staff   20479 Dec 31  1999 bitmap_test.cpp
```

现在这个测试程序要求在当前目录下有一个`image.bmp` 文件的例子。我只是在网上找了一个，然后用这个名字。运行该程序后，你将得到一大堆生成的图像，如图 6-3 所示。

![图 6-3. 由 bitmap_test 可执行文件生成的图像](../images/f6-3.png)

好的，所以它可以工作。它是干净的代码。我不打算教你 C++，也不打算带你看代码，但我会给你看一些工作实例，你可以在不完全理解发生了什么的情况下进行尝试。

首先要做的是。我们需要修改 Makefile 以使用 Emscripten 编译器，而不是你用来构建测试程序的东西。这就像更新 COMPILER 变量一样简单，如例 6-7 所示。

例 6-7. 为我们的测试程序更新 Makefile，以便用 Emscripten 编译。

```
...
COMPILER      = -em++
...
```

Makefile 的 clean 步骤并没有删除可执行文件。所以手动删除`bitmap_test`（或者更好的是修改 Makefile！），现在重新运行 make。你应该看到类似下面的东西。

```bash
brian@tweezer ~/g/w/c/bitmap> make
em++ -ansi -pedantic-errors -Wall -Wall -Werror -Wextra -o bitmap_test ↵ bitmap_test.cpp -L/usr/lib -lstdc++ -lm
brian@tweezer ~/g/w/c/bitmap> ls -alF
total 1848
drwxr-xr-x@ 8 brian staff	   256    Mar  6 15:21 ./
drwxr-xr-x 12 brian staff    384    Mar  6 14:47 .../
-rw-r-r--@  1 brian staff	   771    Mar  6 15:20 Makefile
-rw-r-r--@  1 brian staff 247721    Dec 31 1999 bitmap_image.hpp
-rw-r--r--	1 brian staff 248314    Mar  6 15:21 bitmap_test
-rw-r-r--@  1 brian staff	 20479    Dec  31 1999 bitmap_test.cpp
-rwxr-xr-x	1 brian staff 296743    Mar  6 15:21 bitmap_test.wasm*.
-rw-r-r--@  1 brian staff 120054    Mar  6 14:39 image.bmp
```

呃，这很容易。不幸的是，我们还没有完全完成。虽然这确实是在编译，但由于各种原因，它是无法工作的。其中第一个原因是，该库希望能够写入文件系统。这一点应该不足为奇，因为这是不可能的。然而，有一个非常酷的文件系统抽象，它可以通过添加编译器指令来写入本地存储。现在，就像处理`printf () `的调用一样，Emscripten 工具链将模拟一个文件系统。你可以通过在你的 Makefile 中添加指令`-s FORCE_FILESYSTEM=1` 来解锁这一支持。我将在下面向你展示最终的形式。

第二个问题是，默认生成的 Memory 实例将不允许增长。如果我们期望这个库能在内存中生成一些相当大的图像，那么它就需要能够要求足够的内存。所以，我们可以使用另一个指令来允许这样做。这是我在 [第 4 章](../wasm-memory/) 中向你展示的如何手动操作的东西。这是 Emscripten 可以为我们处理的细节。为了对这个过程有更多的控制，我们将告诉 Emscripten 不要自动退出程序，并导出 `main ()` 方法，这样我们就可以在需要时调用它。因为我们不是生成一个独立的二进制文件，我们还要告诉 Emscripten 编译器生成一个叫做 `bitmap_test.js` 的 JavaScript 文件。`bitmap_test` 规则的命令现在应该如例 6-8 所示。

{{<callout note 提示>}}

在下面的代码中，我用回车符（↵）表示行的延续，这样命令就适合在页面上进行。不要输入这些字符，只要在你的文件中保持行的连续性。

{{</callout>}}

例 6-8. 修改后的 Makefile 带有我们所有的 Emscripten 选项

```bash
bitmap_test: bitmap_test.cpp bitmap_image.hpp
$(COMPILER) $(OPTIONS) bitmap_test.js bitmap_test.cpp $(LINKER_OPT) ↵
-s FORCE_FILESYSTEM=1 ↵
-s ALLOW_MEMORY_GROWTH=1 ↵
-s INVOKE_RUN=0 ↵
-s EXTRA_EXPORTED_RUNTIME_METHODS="['callMain']"
```

这就解决了会妨碍该例子工作的具体问题。然而，还有一个问题。这个测试运行了 20 个相对耗时的测试。由于 JavaScript 是一个单线程的环境，当 WebAssembly 模块在做它的事情时，浏览器很可能开始抓狂，因为事情花了太长时间。

我们最终会解决这个问题，但目前，我只是要删除对其余测试的调用 ，只调用我最喜欢的 `test20 ()`。

`main ()` 方法现在如例 6-9 所示。

例 6-9. 调用一个测试的 main 方法

```c
int main () {test20 ();
  return 0; 
}
```

如果你重新运行 make 命令，你应该看到生成的 Wasm 和 JavaScript 文件。我将生成一些基本的 HTML 脚手架供我们使用。在例 6-10 中，你可以看到我有一个按钮和一个`<canvas>` 元素，我们将用它来渲染位图。现在，把这个文件和你的 Wasm 和 JavaScript 文件保存在同一个目录中，并像我们在书中所做的那样，通过 HTTP 提供给它。

例 6-10. 为我们的位图生成器提供 HTML 脚手架

```html
<!DOCTYPE html>
<html lang="en">
 <head> 
  <meta charset="utf-8" /> 
  <title>C++-rendered Image in the Browser</title> 
 </head> 
 <body> 
  <div class="container"> 
   <h1>C++-rendered Image in the Browser</h1> 
  </div> 
  <button id="load">Load</button> 
  <canvas id="output"></canvas> 
  <script src="bitmap_test.js"></script> 
  <script>
var button = document.getElementById ("load"); button.onclick = function () {Module.callMain ();
        console.log ("Done rendering.");
      };
    </script>  
 </body>
</html>
```

一旦你把 HTML 加载到你的浏览器，打开开发者控制台并按下按钮。这将生成各种文件，并将它们写到" 磁盘 " 上。这将需要一点时间，我料想你的浏览器会抱怨这一点。只要告诉它在它要求的时候等待就可以了。一旦完成，你应该看到信息被打印到控制台。此时，在控制台中，你可以做一些可能让你吃惊的事情，如图 6-4 所示。

![图 6-4. 在浏览器中向文件系统写文件](../images/f6-4.png)

我们的第三方代码使用标准 C++ 库来向 "文件系统" 写入。Emscripten 在浏览器的本地存储上提供了一个抽象层，使之成为可能。从 C++ 中，我们可以很容易地把它读回来。在 JavaScript 中，这并不难，如例 6-11。

例 6-11. 使用文件系统抽象从 "磁盘" 中读取 "文件" 的 JavaScript

```>> var image = FS.readFile ("./test20_julia_set_vga.bmp");
<- undefined>> image
<- Uint8Array (2880054) [66, 77, 54, 242, 43, 0, 0, 0, 0, 0, ...]
```

我们刚刚通过调用`FS.readFile ()` 函数得到了一个 Uint8Array。这将使我们很容易处理来自文件的字节。只有一个问题。浏览器不支持显示 Windows 位图文件！幸运的是，这是一种有记录的格式，有人为我们做了件好事，提供了这样做的代码。我们可以依靠一些现有的 C 或 C++ 代码，但只是为了向你展示一些选择，我们将 [使用 JavaScript 代码](https://www.i-programmer.info/projects/36-web/6234-reading-a-bmp-file-in-javascript.html)。

幸运的是，在 [第 4 章](../wasm-memory/) 你已经具备了理解例 6-12 中的大部分内容的能力。我们把从 `FS.readFile ()` 函数中返回的 ArrayBuffer 传递给一个叫做 `getMBP ()` 的方法。这将在缓冲区周围创建一个 DataView，并在把它们塞进一个更容易理解的 JavaScript 表示法之前拉出各种图像细节。

一旦读入位图文件，我们通过同一网站的 `convertToImageData ()` 函数将 JavaScript 结构转换成 ImageData 实例。之后 ，我们设置 `<canvas>` 的大小以匹配其高度和宽度，并使用其 `putImageData ()` 方法来渲染像素。

例 6-12. 用 JavaScript 读回我们的位图文件，并在 `<canvas>` 中渲染它

```html
 <script>
   // Code taken from https://tinyurl.com/bitmap-in-javascript 
   // Written by Ian Elliott
  function getBMP (buffer) {var datav = new DataView (buffer);
	  var bitmap = {};
	  bitmap.fileheader = {};
	  bitmap.fileheader.bfType = datav.getUint16 (0, true);
	  bitmap.fileheader.bfSize = datav.getUint32 (2, true);
	  bitmap.fileheader.bfReserved1 = datav.getUint16 (6, true);
	  bitmap.fileheader.bfReserved2 = datav.getUint16 (8, true);
	  bitmap.fileheader.bfOffBits = datav.getUint32 (10, true);
	  bitmap.infoheader = {};
	  bitmap.infoheader.biSize = datav.getUint32 (14, true);
	  bitmap.infoheader.biWidth = datav.getUint32 (18, true);
	  bitmap.infoheader.biHeight = datav.getUint32 (22, true);


	  bitmap.infoheader.biPlanes = datav.getUint16 (26, true);
	  bitmap.infoheader.biBitCount = datav.getUint16 (28, true);
	  bitmap.infoheader.biCompression = datav.getUint32 (30, true);
	  bitmap.infoheader.biSizeImage = datav.getUint32 (34, true);
	  bitmap.infoheader.biXPelsPerMeter = datav.getUint32 (38, true);
	  bitmap.infoheader.biYPelsPerMeter = datav.getUint32 (42, true);
	  bitmap.infoheader.biClrUsed = datav.getUint32 (46, true);
	  bitmap.infoheader.biClrImportant = datav.getUint32 (50, true);
	  var start = bitmap.fileheader.bfOffBits;
	  bitmap.stride = Math.floor ((bitmap.infoheader.biBitCount  *bitmap.infoheader.biWidth + 31) / 32) * 4;
	  bitmap.pixels = new Uint8Array (buffer, start);
	  return bitmap;
      }

   // Code taken from https://tinyurl.com/bitmap-in-javascript 
   // Written by Ian Elliott
  function convertToImageData (bitmap) {var canvas = document.createElement ("canvas");
	  var ctx = canvas.getContext ("2d");
	  var width = bitmap.infoheader.biWidth;
	  var height = bitmap.infoheader.biHeight;
	  var imageData = ctx.createImageData (width, height);

	  var data = imageData.data;
	  var bmpdata = bitmap.pixels;
	  var stride = bitmap.stride;

	   for (var y = 0; y < height; ++y) {for (var x = 0; x < width; ++x) {var index1 = (x+width*(height-y))*4;
		  var index2 = x * 3 + stride * y;
		  data [index1] = bmpdata [index2 + 2];
		  data [index1 + 1] = bmpdata [index2 + 1];
		  data [index1 + 2] = bmpdata [index2];
		  data [index1 + 3] = 255;
	      }
	   }

	  return imageData;
      }

      var button = document.getElementById ("load");
      button.onclick = function () {Module.callMain ();
	  var canvas = document.getElementById ("output");
	  var context = canvas.getContext ('2d');

	  var image = FS.readFile ("./test20_julia_set_vga.bmp");
	  var bmp = getBMP (image.buffer);
	  var imageData = convertToImageData (bmp);

	  canvas.width = bmp.infoheader.biWidth;
	  canvas.height = bmp.infoheader.biHeight;

	  context.putImageData (imageData, 0, 0);

	  console.log (image);
      };

    </script>
  </body>
</html>
```

调用我们的 C++ 应用程序，并在通过 JavaScript 读回结果后在画布上渲染，其结果如图 6-5 所示。

![图 6-5. 在画布中渲染位图文件的结果](../images/f6-5.png)

我希望你至少有一点印象。要在浏览器中运行这段 C++ 代码，我们只需要做很少的事情，这一点非常酷！在性能和线程方面仍有一些问题，但你已经从两个数字相加的过程一路走来，走了很长一段路。

我们可以做的一件事是在执行中添加一个命令行参数，以选择要运行的测试。目前，我们不担心在样本图像中读取的测试 [^3]。

为了接受命令行上的参数，我们需要将 `main ()` 方法修改为如例 6-13 所示。

例 6-13. 修改了 `main ()` 方法，以接受测试选择的参数

```cpp
int main (int argc, char **argv)
{
  int which = 20;

  if (argc> 1) {
    std::string::size_type sz;
    which = std::stoi (argv [1], &sz);
  }

  switch (which) {
  case 0:
  case 1:
  case 2:
  case 3:
  case 4:
  case 5:
  case 6:
  case 7:
  case 8:
  case 10:
  case 11:
  case 12:
  case 13:
  case 16:
    printf ("Sorry, % s requires reading in a file which we are not supporting yet.\n", argv [1]);
    break;
  case 9:
    test09 ();
    break;
  case 14:
    test14 ();
    break;
  case 15:
    test15 ();
    break;
  case 17:
    test17 ();
    break;
  case 18:
    test18 ();
    break;
  case 19:
    test19 ();
    break;
  case 20:
    test20 ();
    break;
  default:
    printf ("Sorry, % s is an unknown test number.\n", argv [1]);
  }

  return 0;
}
```

你将注意到的第一件事是，`main ()` 的签名已经被修改为接受一个代表命令行参数数量的整数，实际上是一个字符串数组。请记住，在 C/C++ 中，这是作为一个指针指向一堆指针，这就是为什么有两个星号的原因。我们可以像对数组那样对它们进行索引。

默认情况下，第一个参数将是可执行文件的名称。由于我们从 0 开始计数，第一个传入的参数将在 1 的位置。我们设置一个默认的测试数字为 20，因为我已经表示这是我最喜欢的测试。然而，如果你传入一个代表数字的字符串，它将被转换为一个整数。一旦我们确定了是否使用默认值，我们就在这个值上切换。如前所述，我们跳过需要输入图像的测试。还有其他几个你可以运行的。

{{<callout note 提示>}}

如果你要在本地代码和 WebAssembly 之间来回转移，你可能想在这时维护两个不同的 Makefile。当你更舒服时，你可以创建灵活的 Makefiles，支持两个目标。你可以用 `-f <file>` 参数来指定使用哪个文件，如下面的例子所示。

{{</callout>}}

如果你愿意，可以重新编译本地可执行文件并尝试新的参数处理：

```bash
brian@tweezer ~/g/w/s/c/bitmap> make -f Makefile.orig
c++ -ansi -pedantic-errors -Wall -Wall -Werror -Wextra -o bitmap_test ↵
bitmap_test.cpp -L/usr/lib -lstdc++ -lm
brian@tweezer ~/g/w/s/c/bitmap> ./bitmap_test 1
1 requires reading in a file which we don't support yet.
brian@tweezer ~/g/w/s/c/bitmap> ./bitmap_test 9
brian@tweezer ~/g/w/s/c/bitmap> ls -laF
total 7608
drwxr-xr-x@ 14 brian staff     448 Mar  7 22:55 ./
drwxr-xr-x  12 brian staff     384 Mar  6 14:45 ../
-rw-r--r--@  1 brian staff     893 Mar  7 17:43 Makefile
-rw-r--r--@  1 brian staff     776 Mar  7 20:10 Makefile.orig
-rw-r--r--@  1 brian staff  247721 Dec 31  1999 bitmap_image.hpp
-rwxr-xr-x   1 brian staff 205264  Mar  7 22:55 bitmap_test*
-rw-r--r--@  1 brian staff   20954 Mar  7 20:16 bitmap_test.cpp
-rw-r--r--   1 brian staff  249546 Mar  7 20:16 bitmap_test.js 
-rw-r--r--@  1 brian staff  120054 Mar  6 14:39 image.bmp
-rw-r--r--   1 brian staff    3127 Mar  7 17:26 index.html
-rw-r--r--   1 brian staff 3000054 Mar  7 22:55 test09_color_map_image.bmp
```

好消息是，我们不需要对我们的 JavaScript 代码做太多的改动！因为签名已经改变了。因为签名已经改变了，我们现在可以将字符串传入我们的方法，以调用`main ()` 方法。与其在 HTML 中输出只有适度差异的 JavaScript，在图 6-6 你可以从开发者控制台看到带参数的可执行程序的调用结果。

![图 6-6. 在浏览器中用命令行参数调用我们的位图生成器](../images/f6-6.png)

除了根据命令行参数选择测试外，你可能还想把测试当作函数来运行。然而，这需要更多的讨论。

我们将首先在我们的测试文件中添加一个名为 `run_test ()` 的方法，它将接受一个参数。在这一点上没有必要重复实际的代码，所以我们将只是打印出一个字符串，表明请求运行的是哪个测试。如例 6-14，你可以看到这个函数的定义。

```cpp
void run_test (int i) {printf ("Running test % d!\n", i);
}
```

默认情况下，只有`main ()`方法被导出，因为那是我们需要启动程序的唯一函数。我们需要添加一个 * EXPORTED_FUNCTIONS * 指令，如下所示 。函数名的定义有一个前导下划线字符。如果你想让`main ()` 仍然可以被调用，你需要把它也包括进来，但在例 6-15 中我们没有这样做。

例 6-15. 修改后的 Makefile 导出更多方法

```makefile
bitmap_test: bitmap_test.cpp bitmap_image.hpp
        $(COMPILER) $(OPTIONS) bitmap_test.js bitmap_test.cpp $(LINKER_OPT) ↵
             -s FORCE_FILESYSTEM=1 ↵
             -s ALLOW_MEMORY_GROWTH=1 ↵
             -s INVOKE_RUN=0 ↵
             -s EXPORTED_FUNCTIONS="['_main', '_run_test']" ↵
             -s EXTRA_EXPORTED_RUNTIME_METHODS="['callMain']"
```

不幸的是，这样做是行不通的，因为我们使用的是 C++。生成的函数名会被编译器进一步篡改，其原因不值得在此赘述 [^4]。为了避免这个问题，我们需要告诉编译器抑制这种行为并使用 C 语言连接。要使用这种行为，我们需要修改我们的函数定义，使之看起来如例 6-16 所示。

例 6-16. 导出一个函数以便从 JavaScript 中调用，并使用 C 语言链接

```c
extern "C"
void run_test (int i) {printf ("Running test % d!\n", i);
}
```

这应该可以解决这个问题，但我还要做一个改动，向你展示 ，你还有一个选择。Emscripten 工具链中有一个便捷的方法叫 cwrap，它可以为调用一个特定的 C 函数生成一个 JavaScript 函数。我们把它添加到例 6-17 的 *EXTRA_EXPORTED_RUNTIME_METHODS * 指令中。 

例 6-17 更新了 Makefile 以使用 cwrap

```makefile
bitmap_test: bitmap_test.cpp bitmap_image.hpp
        $(COMPILER) $(OPTIONS) bitmap_test.js bitmap_test.cpp $(LINKER_OPT) ↵
             -s FORCE_FILESYSTEM=1 ↵
             -s ALLOW_MEMORY_GROWTH=1 ↵
             -s INVOKE_RUN=0 ↵
             -s EXPORTED_FUNCTIONS="['_main', '_run_test']" ↵
             -s EXTRA_EXPORTED_RUNTIME_METHODS="['callMain', 'cwrap']"
```

如果你重建并重新加载你的 HTML，你将能够从 JavaScript 开发者控制台调用这个函数。请看这样做的结果，如 图 6-7.

![图 6-7. 从 JavaScript 中直接和通过 cwrap () 调用我们的函数](../images/f6-7.png)

请注意，`cwrap ()` 的调用返回一个适当的 JavaScript 函数，我们可以像往常一样使用。你可以把 switch 语句移到这个方法中，并有同样的能力来调用任意的测试。
对于一些额外的练习，尝试添加一个方法，写出一个名为 `image.bmp` 的位图文件。从你的 C++ 代码中导出这个方法并从浏览器中调用它。这可以让你在需要它的测试中读回该文件。你可以修改 switch 语句以允许这些方法被调用。

最后，想象一些其他的用户界面元素，允许你挑选要运行的测试。一旦运行，设想在 `<canvas>` 元素中显示一个文件列表。你几乎拥有做这件事所需要的所有部件，所以请试一试吧！

## libsodium

在结束本章之前，我想提请你注意一个叫做 libsodium 的项目。我们不打算直接用它做任何事情，但它展示了通过 WebAssembly 将 C 和 C++ 等语言与浏览器混合的额外动力。

这是基于另一个叫做网络和加密库（NaCl）[^5] 的库，它是一个高性能的现代加密库，由深谙此道的人编写。这个 NaCl 的许多功能还不一定能用于 JavaScript 运行系统。新的密码套件，包括带有附加数据的认证加密（AEAD），可能会在它们被移植到 JavaScript 或通过操作系统提供给浏览器之前很久就出现在这里 [^6]。

第二个动机是，NaCl 库的作者知道他们在做什么。用一个糟糕的实现来破坏一个加密库的功效是非常容易的。即使是比较两个哈希值是否相同这样微妙的事情，如果实施不当也会泄露细节。令人沮丧的是，这种比较的正确实现将与开发人员通常比较两个哈希值的方式相悖。我的观点是，NaCl 代码库是有出处的。如果一个没有背景了解这些细节的 JavaScript 开发人员试图实现这些功能，那么它很有可能存在这些漏洞。当你拥有一个可信赖的代码库时，能够重新编译并直接使用它是考虑本章主题的另一个原因。

所以，libsodium 旨在通过 WebAssembly 将 NaCl 库导出到 JavaScript 环境中，而不需要重写或在性能上妥协。它被设计为作为一个 WebAssembly 项目来维护。我认为，一旦人们对以这种方式使用 WebAssembly 有了更好的认识，我们就会开始看到更多的项目可以作为本地库或 WebAssembly 模块使用，这取决于你的配置需求。这将是代码重用的一个好机会。我们将在第 10 章看到这种方法的另一个例子。

在那之前，还有更多关于 WebAssembly 的知识需要学习。 

## 注释

[^1]:  [《天生爱神》（*The Adventures of Buckaroo Banzai Across the 8th Dimension*）](https://zh.wikipedia.org/zh-my/%E5%8F%8D%E6%9A%B4%E6%88%B0%E5%A3%AB%E7%9B%9F) 是有史以来最好的邪典电影之一。
[^2]: 这个名字是 JavaScript 和 "embiggen" 一词的语言混搭，《辛普森一家》使之流行。
[^3]: 这是留给你的作业。
[^4]: 如果你想了解更多关于 C++ 名称混用的信息，请查阅[维基百科](https://en.wikipedia.org/wiki/Name_mangling)。

[^5]: 请注意这与我们在[第一章](../hello-world/)中提到的本地客户端（NaCl）没有关系。你可以在[网上](http://nacl.cr.yp.to/) 找到更多关于这个的细节。

[^6]: 密码套件是一个密码基元的集合，为加密引擎提供一系列的能力。
