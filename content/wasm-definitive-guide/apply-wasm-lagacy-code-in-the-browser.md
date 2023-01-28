---
linktitle: 第 6 章：应用 WebAssembly——在浏览器中运行遗留代码
summary: 使用 C/C++ 和 WebAssembly。
weight: 7
icon: book-reader
icon_pack: fas
draft: true
title: 应用 WebAssembly——在浏览器中运行遗留代码
date: '2023-01-25T00:00:00+08:00'
type: book # Do not modify
---

> 无论你走到哪里，你都在那里。
>
> ——Buckaroo Banzai

现在是时候让我们更仔细地看看在浏览器中调用C/C++代码的过程了。这些语言中的大多数代码都不是为了在浏览器中以下载的形式运行。但是，正如香港骑士（译者注：The Hong Kong Cavaliers，电影《天生爱神》中的主角 Buckaroo Banzai 的乐队名称）的队长在本章开头的引文中告诉我们的那样，偶尔你会发现自己在某个意想不到的新地方，但那里仍然只有你[^1]。

我们对在浏览器中调用C/C++代码感兴趣，原因有很多。取代JavaScript并不是其中之一。至少对大多数人来说不是。相反，我们有大量的用C和C++等语言编写的遗留代码。其中有很多是非常有用的，如果能在我们的网络应用程序中使用这些代码，那就太好了。其中一些可能是将组织与遗留系统联系在一起的。能够通过浏览器分发这些代码将是一个很大的进步。

此外，有些问题根本不适合用JavaScript来写。可以选择用另一种语言来编写你的应用程序的那一部分，而不需要一个单独的运行时，这是非常引人注目的。而且，正如我们的最后一个用例所表明的那样，对于敏感和棘手的软件（如加密算法）来说，有来自可信来源的可信代码提供证明是真正有价值的。能够简单地重新编译来自你所认识的人的现有代码，他们知道自己在做什么，这也是一种有用的能力。

在上一章中，我们展示了使用常规的支持WebAssembly的C编译器（如clang）和一些头和库的依赖性管理来实现基本的集成是可能的。然而，必须提供我们自己的标准库版本，并手动将C代码连接到所提供的JavaScript上，这样做很快就会过时。

幸运的是，[Emscript 项目](https://emscripten.org/)奠定了基础，使之成为一个比其他方式更容易的过程。这并不奇怪，因为它的主要开发者Alon Zakai和Luke Wagner一直是这项工作的幕后推手，从asm.js开始，延伸到WebAssembly MVP，再到规范的进步 ，一直持续到今天。Emscripten[^2]工具链在这一过程中发挥了重要作用。

该项目是基于LLVM平台的。在前面的章节中，我指出它最初有一个自定义的后端，用来生成asm.js的可优化的JavaScript子集。一旦WebAssembly平台被定义，一个新的后端就能生成Wasm二进制文件。

不幸的是，这只是解决方案的一部分。还需要支持数据进出内存，链接模块，包装现有的库，等等。一个提供用户界面或监听网络请求的C语言程序经常在一个相当紧密的循环中响应输入活动。鉴于浏览器默认为单线程环境，这种主循环会出现操作上的不匹配。Emscripten工具链已被修改，以解决在试图将本地C/C++移植到我们的网络环境中运行时可能出现的许多类型的问题。与大多数主题一样，本书不可能全面介绍这个项目的所有内容，但我将尝试让你快速入门。

## 适当的 "Hello, World!"

所以，首先要承认：我们本可以在[第二章](../hello-world/)中就在浏览器中拥有一个有效的、未经修改的 "Hello, World!"的例子，早在2000年就有了。最后一次，我们将向你展示例 6-1 中的代码。

例6-1. 典型的 "Hello, World!"程序用C语言表达

```c
#include <stdio.h>
int main() {
  printf("Hello, World!\n"); return 0;
}
```

使用Emscripten C语言编译器（安装说明见[附件](../appendix/)），我们只需要告诉它编译C代码并生成一些JavaScript脚手架。之后，它就会在Node.js中未经修改地运行。

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

例 6-2 中的HTML文件并不是由这个过程生成的，它与我们之前看到的文件有明显的不同。有一个单一的`<script>`元素来加载我们生成的JavaScript。我们没有使用到目前为止使用过的utils.js文件。相反，我们有一个由前面的命令产生的更长的JavaScript文件。看看这个文件的清单！它超过了120KB。它超过了120千字节！这是超过2000行的代码。如果你看一看，你会发现自己很快就会迷失。这就是为什么我不想在前面的章节中从那里开始。

例6-2. 一个与我们所见过的HTML文件大不相同的文件

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

然而，如果我们通过HTTP提供这个目录，打开浏览器，并打开JavaScript控制台，你会看到非常类似图 6-1 的东西。

![图6-1. 你被告知的 "Hello, World!"是不可能的](../images/f6-1.png)

如果你对`hello.wasm`文件使用wasm-objdump命令，你会注意到有一个导出的`main()`函数。生成的代码很快就超出了我们显示整个文件的能力，所以我将只强调导出部分。

```
...
    Export[13]:
     - memory[0] -> "memory"
     - func[3] <__wasm_call_ctors> -> "__wasm_call_ctors"
     - func[5] <main> -> "main"
     - func[6] <__errno_location> -> "__errno_location"
     - func[50] <fflush> -> "fflush"
     - func[47] <stackSave> -> "stackSave"
     - func[48] <stackRestore> -> "stackRestore"
     - func[49] <stackAlloc> -> "stackAlloc"
     - func[44] <emscripten_stack_init> -> "emscripten_stack_init"
     - func[45] <emscripten_stack_get_free> -> "emscripten_stack_get_free"
     - func[46] <emscripten_stack_get_end> -> "emscripten_stack_get_end"
     - table[0] -> "__indirect_function_table"
     - func[53] <dynCall_jiji> -> "dynCall_jiji"
...
```

你看，有相当多的生成的脚手架来使这一切工作。这些细节相当复杂，但如果你想通过它来追踪你的方式，我建议用wasm2wat生成相应的Wat文件。从那里，追踪`main()`函数（在前面的代码样本中编号为5）。你将会看到如例 6-3 所示内容。

例6-3. Wat的main 方法

```
...
(func (;5;) (type 5) (param i32 i32) (result i32) (local i32)
call 4
local.set 2
local.get 2
return) 
...
```

最终，你会发现自己回到了生成的JavaScript文件。在那里有一个叫做`fd_write`的函数，如例 6-4 所示。这被添加到一个名为`wasi_snapshot_preview1`的命名空间 。顾名思义，这是一个我们将在后面的讨论中涉及的预览，但主要的一点是，Emscripten工具链正在生成代码，以解决我们在前面章节中看到的一些底层麻烦。我们将在第10章中发现与Rust生态系统类似的工具链。

例6-4. printf解决方案的一部分

```JavaScript
...
function _fd_write(fd, iov, iovcnt, pnum) {
  // hack to support printf in SYSCALLS_REQUIRE_FILESYSTEM=0
  varnum = 0;
  for (vari = 0; i < iovcnt; i++) {
    var ptr = HEAP32[(((iov) + (i * 8)) >> 2)];
    var len = HEAP32[(((iov) + (i * 8 + 4)) >> 2)];
    for (varj = 0; j < len; j++) {
      SYSCALLS.printChar(fd, HEAPU8[ptr + j]);
    }
    num += len;
  }
  HEAP32[((pnum) >> 2)] = num
  return 0;
}
...
```

当然，我们没有必要深入了解，看看这一切到底是如何进行的。重要的是你要明白，我们实际上不是在典型的标准库意义上调用 `printf()`，而是这个函数被改写成了调用生成的代码。在浏览器中，它将把字符路由到与开发者工具相关的JavaScript控制台。在Node.js环境中，它将被路由到底层系统控制台。在这个阶段，重要的是，我们的传统应用程序不必改变以在这个新环境中运行，但我们也没有被直接运行本地C和C++的可怕前景所困扰。我们在可移植性、安全性和性能之间取得了重要的平衡，这正是WebAssembly的意义所在。

生成的代码在JavaScript中有一个Module对象，它定义了我们的WebAssembly代码将占用的运行环境。在JavaScript文件的顶部有一些注释，描述了这个对象和它作为两个世界之间的接口的作用。然而，为了保持事情的可控性，我们将专注于其中更小的部分。

我们可以选择的方法之一是使用编译器指令来打开或压制某些生成行为。例如，我们可能不希望我们的C程序在加载JavaScript代码时立即运行。如果你尝试在没有`INVOKE_RUN=0`指令的情况下进行编译，你会看到典型的问候语，就像你在前面的例子中一样。在下面的片段中，注意到在Node.js中加载代码时，没有任何东西被打印到命令行。

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

在例6-5中，你可以看到我们调用 `main()` 函数来响应一个按钮的点击。

例6-5. 一个延迟的 `main()` 方法调用

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
var button = document.getElementById("press"); button.onclick = function() {
try { Module.callMain();
} catch(re) {
}; };
    </script>  
 </body>
</html>
```

在图6-2中，可以看到当按钮被按下时，友好的信息被打印到控制台。Firefox没有显示每条相同的信息，但它显示我已经在右边按了七次按钮。你的浏览器可能会在每次调用时显示一条打印信息。

![图6-2.按下按钮所触发的 "Hello, World！"。](../images/f6-2.png)

## 移植第三方代码

我们现在要深入研究将一些现有的代码引入浏览器。这段代码从未打算在web上运行，它所做的事情通常不会在浏览器中运行，例如向文件系统写入。不要担心，我们不会破坏浏览器的安全模型，但你会看到这段C++代码基本上可以不加修改地运行。

Emscripten有大量的选项用于将第三方代码移植到WebAssembly中。它可以有效地替代cc、make和configure，这通常使移植过程变得简单。在现实中，你很可能要通过自己的方式来解决你遇到的问题，但你可能会惊讶于这个过程是如此的简单。该[项目的网站](https://emscripten.org/docs/compiling/Building-Projects.html)有很好的文件来帮助你。然而，我最喜欢的主题介绍是Robert Aboukhalil的 [Level Up With WebAssembly材料](https://www.levelupwasm.com/)。他告诉你如何将几个不同的开源项目移植到WebAssembly，以便在浏览器上运行。这包括像俄罗斯方块、乒乓和吃豆人等游戏。与其尝试重新创造他已经完成的杰作，我将专注于一个相对简单和干净的项目。

我花了一些时间来寻找好的候选代码。我想找一些内容丰富但又不至于过于复杂的东西。最终，我在[Arash Partow的网站](https://www.partow.net/)上找到了他收集的优雅、干净、适当授权和有用的C++代码。 如果你去那里，你会发现相当多的有趣的材料。我原本打算使用计算几何库，但决定Bitmap库更适合于这本书。

首先，从 [Partow的网站](http://www.partow.net/programming/bitmap/index.html)下载代码。下载ZIP文件， 解压缩，你会看到三个文件。Makefile是一个老式的Unix构建文件，它有组装有关软件的指示。我们稍后将探讨这个过程 。`bitmap_image.hpp`文件是主库，`bitmap_test.cpp`是一个全面的测试集合，用于生成一堆有趣的Windows位图图像。这段代码不需要任何特定平台的库。

```bash
brian@tweezer ~/g/w/s/c/bitmap> ls -alF 
total 536
drwxr-xr-x@  5 brian  staff
drwxr-xr-x  11 brian  staff
-rw-r--r--@  1 brian  staff
-rw-r--r--@  1 brian  staff  247721 Dec 31  1999 bitmap_image.hpp
-rw-r--r--@  1 brian  staff   20479 Dec 31  1999 bitmap_test.cpp
```

我把一些注释和许可证的细节从例 6-6中删除了，为了节省空间。剩下的是构建测试程序的规则结构，即`bitmap_test`。Makefile的工作方式是建立一个目标，然后是建立目标的依赖关系和规则。作为一种惯例，通常有一个All规则，指定前面提到的目标文件名。它依赖于`.cpp`和`.hpp`文件。如果这两个文件中的任何一个被修改了，我们的可执行文件就需要被重新构建。要做到这一点，make工具将用OPTIONS 变量中的选项执行COMPILER变量中的文件。作为一个C/C++程序，它还需要与LINKER_OPT变量中指定的库链接。在这种情况下，我们要与标准的C++库和基本的数学函数集合进行链接。在库方面，这是最独立的了。clean目标只是删除了衍生的结果。

Makefile通常对空格和制表符比较敏感。确保使用制表符来开始缩进的规则行。本书仓库中的代码就是这样做的，但如果你以任何方式修改它，你要确保使用制表符。

例6-6. 我们的测试程序的Makefile

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

只要你安装了一个正常的C++环境，你就应该能够构建测试程序。

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

现在这个测试程序要求在当前目录下有一个`image.bmp`文件的例子。我只是在网上找了一个，然后用这个名字。运行该程序后，你将得到一大堆生成的图像，如图 6-3 所示。

![图6-3. 由bitmap_test可执行文件生成的图像](../images/f6-3.png)

好的，所以它可以工作。它是干净的代码。我不打算教你C++，也不打算带你看代码，但我会给你看一些工作实例，你可以在不完全理解发生了什么的情况下进行尝试。

首先要做的是。我们需要修改Makefile以使用Emscripten编译器，而不是你用来构建测试程序的东西。这就像更新COMPILER变量一样简单，如例6-7 所示。

例6-7. 为我们的测试程序更新Makefile，以便用Emscripten编译。

```
...
COMPILER      = -em++
...
```

Makefile的clean步骤并没有删除可执行文件。所以手动删除`bitmap_test`（或者更好的是修改Makefile！），现在重新运行make。你应该看到类似下面的东西。

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

呃，这很容易。不幸的是，我们还没有完全完成。虽然这确实是在编译，但由于各种原因，它是无法工作的。其中第一个原因是，该库希望能够写入文件系统。这一点应该不足为奇，因为这是不可能的。然而，有一个非常酷的文件系统抽象，它可以通过添加编译器指令来写入本地存储。现在，就像处理`printf() `的调用一样，Emscripten工具链将模拟一个文件系统。你可以通过在你的Makefile中添加指令`-s FORCE_FILESYSTEM=1`来解锁这一支持。我将在下面向你展示最终的形式。

第二个问题是，默认生成的Memory实例将不允许增长。如果我们期望这个库能在内存中生成一些相当大的图像，那么它就需要能够要求足够的内存。所以，我们可以使用另一个指令来允许这样做。这是我在[第4章](../wasm-memory/)中向你展示的如何手动操作的东西。这是Emscripten可以为我们处理的细节。为了对这个过程有更多的控制，我们将告诉Emscripten不要自动退出程序，并导出`main()`方法，这样我们就可以在需要时调用它。因为我们不是生成一个独立的二进制文件，我们还要告诉 Emscripten编译器生成一个叫做`bitmap_test.js`的JavaScript文件。`bitmap_test`规则的命令现在应该如例 6-8 所示。

{{<callout note 提示>}}

在下面的代码中，我用回车符（↵）表示行的延续，这样命令就适合在页面上进行。不要输入这些字符，只要在你的文件中保持行的连续性。

{{</callout>}}

例6-8. 修改后的Makefile带有我们所有的Emscripten选项

```bash
bitmap_test: bitmap_test.cpp bitmap_image.hpp
$(COMPILER) $(OPTIONS) bitmap_test.js bitmap_test.cpp $(LINKER_OPT) ↵
-s FORCE_FILESYSTEM=1 ↵
-s ALLOW_MEMORY_GROWTH=1 ↵
-s INVOKE_RUN=0 ↵
-s EXTRA_EXPORTED_RUNTIME_METHODS="['callMain']"
```

这就解决了会妨碍该例子工作的具体问题。然而，还有一个问题。这个测试运行了20个相对耗时的测试。由于JavaScript是一个单线程的环境，当WebAssembly模块在做它的事情时，浏览器很可能开始抓狂，因为事情花了太长时间。

我们最终会解决这个问题，但目前，我只是要删除对其余测试的调用 ，只调用我最喜欢的`test20()`。

`main()`方法现在如例 6-9 所示。

例6-9. 调用一个测试的 main 方法

```c
int main() {
	test20();
  return 0; 
}
```

如果你重新运行make命令，你应该看到生成的Wasm和JavaScript文件。我将生成一些基本的HTML脚手架供我们使用。在例 6-10中，你可以看到我有一个按钮和一个`<canvas>`元素，我们将用它来渲染位图。现在，把这个文件和你的Wasm和JavaScript文件保存在同一个目录中，并像我们在书中所做的那样，通过HTTP提供给它。

例6-10. 为我们的位图生成器提供HTML脚手架

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
var button = document.getElementById("load"); button.onclick = function() {
        Module.callMain();
        console.log("Done rendering.");
      };
    </script>  
 </body>
</html>
```


一旦你把HTML加载到你的浏览器，打开开发者控制台并按下按钮。这将生成各种文件，并将它们写到 "磁盘 "上。这将需要一点时间，我完全期待你的浏览器会抱怨这一点。只要告诉它在它要求的时候等待就可以了。一旦完成，你应该看到信息被打印到控制台。此时，在控制台中，你可以做一些可能让你吃惊的事情，如图所示 图 6-4.

图6-4.在浏览器中向 "文件系统 "写文件
我们的第三方代码使用标准C++库来向 "文件系统 "写入。Emscripten在浏览器的本地存储上提供了一个抽象层，使之成为可能。从C++中，我们可以很容易地把它读回来。在JavaScript中，这并不难，如图所示 例 6-11.

例6-11.使用文件系统抽象从 "磁盘 "中读取 "文件 "的 JavaScript

我们刚刚通过调用FS.readFile()函数得到了一个Uint8Array。这是 ，将使我们很容易处理来自文件的字节。只有一个问题。浏览器不支持显示Windows位图文件!
幸运的是，这是一种有记录的格式，有人为我们做了件好事，提供了这样做的代码。我们可以依靠一些现有的C或C++代码，但只是为了向你展示一些选择，我们将使用 JavaScript 代码 提供的.
幸运的是，在 第四章 你已经具备了理解例6-12中的大部分内容的能力。 例6-12.我们把从FS.read File()函数中返回的ArrayBuffer传递给一个叫做getMBP()的方法。这将在缓冲区周围创建一个DataView，并在把它们塞进一个更容易理解的JavaScript表示法之前拉出各种图像细节。

一旦读入位图文件，我们通过同一网站的convertToImageData()函数将JavaScript结构转换成ImageData 实例。之后 ，我们设置<canvas>的大小以匹配其高度和宽度，并使用其putImageData()方法来渲染像素。

例6-12.用JavaScript读回我们的位图文件，并在<canvas>中渲染它
元素

调用我们的C++应用程序，并在通过JavaScript读回结果后在画布上渲染，其结果可以在下面看到 图 6-5.

图6-5.在画布中渲染我们的位图文件的结果
我希望你至少有一点印象。要在浏览器中运行这段C++代码，我们只需要做很少的事情，这一点非常酷!在性能和线程方面仍有一些问题，但你已经从两个数字相加的过程中走了很长一段路。
我们可以做的一件事是在执行中添加一个命令行参数，以选择要运行的测试。目前，我们不打算担心在样本图像中读取的测试。3
为了接受命令行上的参数，我们需要将main()方法修改为你所看到的那样 例 6-13.

例6-13.修改了main()方法，以接受测试选择的参数

## 注释

[1]: [《天生爱神》（*The Adventures of Buckaroo Banzai Across the 8th Dimension*）](https://zh.wikipedia.org/wiki/%E5%8F%8D%E6%9A%B4%E6%88%B0%E5%A3%AB%E7%9B%9F)是有史以来最好的邪典电影之一。
