---
linktitle: 第 3 章：WebAssembly 模块
summary: WebAssembly 模块。
weight: 4
draft: false
icon: book-reader
icon_pack: fas
title: WebAssembly 模块
date: '2023-01-17T15:00:00+08:00'
type: book # Do not modify
---

> 物归原处，物归原主。
>
> —— 十七世纪的谚语

操作系统运行通常包含在编译形式中的程序 [^1]。每个操作系统都有自己的格式，定义从哪里开始，什么数据是必要的，以及不同的功能位的指令是什么。WebAssembly 也不例外。在这一章中，我们将看看这些行为是如何被打包的，以及主机是怎么知道如何处理它的。

软件工程师在他们的整个职业生涯中可能都忽略了程序是如何通过这个过程加载和执行的。他们的世界从 `int main (int argc, char **argv)` 或 `static void main (String [] args)` 开始，甚至到 `if __name == "__main__":` 就停止了。这些是众所周知的 C、Java 和 Python 程序的入口，因此这是程序员承担控制流责任的地方。然而，在程序启动之前和退出之后，操作系统或程序运行时需要建立和拆解可执行结构。装载程序需要知道指令从哪里开始，数据元素如何被初始化，还有哪些其他模块或库需要被加载等等。

这些细节通常由可执行文件的性质来定义。在 Linux 上，这是由 [可执行和可链接格式（ELF）](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format) 定义；在 Windows 上，它是由 [可移植格可执行格式（PE）](https://en.wikipedia.org/wiki/Portable_Executable) 来定义；而在 macOS 上，是由 [Mach-O 格式](https://en.wikipedia.org/wiki/Portable_Executable) 定义。这些显然是 ，是本地可执行文件的特定平台格式。像 Java 和.NET 这样更具可移植性的系统使用中间字节码表示，但仍有一个定义好的结构，它们的作用也类似。

WebAssembly MVP 的首要设计考虑之一是定义模块结构，以便 WebAssembly 主机知道寻找和验证什么，以及执行部署单元时从哪里开始。

在 [第 2 章](../hello-world/) 中，你已经看到了一个比我们在本章开始时更复杂的模块结构。我们将逐步介绍这些部分，然后向你展示一些工具，以探索 WebAssembly 模块的文本和视觉结构。在上一章中，我们已经简单地讨论了二进制结构。它结构紧凑，传输和加载速度快。你可能不会经常花很多时间去看二进制的细节，因为你的注意力会放在软件方面。熟悉模块的布局是很有用的，所以我们来看看。

## 模块结构

最基本的 WebAssembly 模块是空模块。没有一个部分是必须的，所以有可能有一个有效的模块，如例 3-1 所示。

例 3-1. 空模块，但是有效的 WebAssembly 模块。

```
(module)
```

 显然，它没有什么可看的，但它可以转换为二进制形式。你会注意到在下面的输出中，它至少没有占用很多空间，什么都不做。

```bash
brian@tweezer ~/g/w/s/ch03> wat2wasm empty.wat
brian@tweezer ~/g/w/s/ch03> ls -alF
total 16
drwxr-xr-x 4 brian staff 128 Dec 21 14:45 ./ 
drwxr-xr-x 4 brian staff 128 Dec 14 12:37 ../ 
-rw-r--r-- 1 brian staff 8   Dec 21 14:45 empty.wasm
-rw-r--r-- 1 brian staff 8   Dec 14 12:37 empty.wat
```

如果你是视觉导向的，你可能会喜欢使用 WebAssembly Code Explorer，可以从  [wasdk GitHub 仓库](https://github.com/wasdk/wasmcodeexplorer) 获取。你可以在浏览器中 [在线使用](https://wasdk.github.io/wasmcodeexplorer/) 或者从克隆的目录中下载运行一个 HTTP 服务器。在这种情况下，我将 ，像先前那样使用 Python 3 Web 服务器。

```bash
brian@tweezer ~/g/wasmcodeexplorer> python3 -m http.server 10003
Serving HTTP on :: port 10003 (http://[::]:10003/) ...
```

同样，对于一个空的模块来说，它看起来还不多，但一旦我们开始向它添加一些元素，这将是一个有用的总结。文件格式经常被操作系统从文件的前几个字节中 [^2] 识别出来。它们通常被称为 **神奇数字**。对于 WebAssembly 来说，这些字节被编码为`0x00 0x61 0x73 0x6D`，代表字符 **a**、**s** 和 **m** 的十六进制值，后面是版本号 1（由字节`0x01 0x00 0x00 0x00` 代表）。

在图 3-1 中你可以看到这些神奇的字节，以及表明这是 WebAssembly 文件格式的第 1 版，左边是一系列的数字，右边是空模块结构。

![图 3-1. 一个空模块在 WebAssembly 代码资源管理器中的可视化。](../images/f3-1.png)

对于模块的命令行检查，你有几个选择，但 Wabt 工具包中的 `wasm-objdump` 可执行文件相当有用。请参考 [附录](../appendix/) 以获得安装本书中讨论的各种工具的帮助。

如果你在运行命令时不加开关，就会抱怨。正如你将看到的那样，当你有更多的细节需要探索时，这些会产生更大的不同。

```bash
brian@tweezer ~/g/w/s/ch03> wasm-objdump empty.wasm At least one of the following switches must be given:
     -d/--disassemble
     -h/--headers
     -x/--details
     -s/--full-contents
```

现在，我们只需通过使用细节开关来验证我们的模块是无用的，但却是有效的。这也表明我们处理的是第 1 版的格式。

```bash
brian@tweezer ~/g/w/s/ch03> wasm-objdump -x empty.wasm 
empty.wasm: file format wasm 0x1
Section Details:
```

## 探索模块的各个部分

关于我们正在介绍的概念，有一个循环依赖的问题。模块格式必须包括对 WebAssembly 所包括的所有各种元素的支持，但我们将在以后的章节中才介绍其中的一些元素。我们将主要关注我们现在已经看到的部分，并承诺很快会重新审视其他部分的元素。

该模块的整体结构是基于一系列可选的编号部分，每个部分都涉及 WebAssembly 的一个特定功能。在表 3-1 中，我们可以看到这些部分的快速列表和描述。

| ID   | 名称       | 描述                                         |
| ---- | ---------- | -------------------------------------------- |
| 0    | Custom     | 调试或元数据信息供第三方使用                 |
| 1    | Type       | 模块中使用的类型定义                         |
| 2    | Import     | 一个模块所使用的导入元素                     |
| 3    | Function   | 与模块中的函数相关的类型签名                 |
| 4    | Table      | 定义模块所使用的间接的、不可改变的引用的表格 |
| 5    | Memory     | 一个模块所使用的线性内存结构                 |
| 6    | Global     | 全局变量                                     |
| 7    | Export     | 一个模块所提供的导出元素                     |
| 8    | Start      | 一个可选的启动函数，用于启动一个模块         |
| 9    | Element    | 由一个模块定义的元素                         |
| 10   | Code       | 一个模块所定义的函数的主体                   |
| 11   | Data       | 一个模块所定义的数据元素                     |
| 12   | Data Count | 模块所定义的数据元素的数量                   |

参考下面是来自 [第二章](../hello-world/) 的例子。

例 3-2. 一个简单的 WebAssembly 文本文件

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
2. 导出的函数`how_old`

我们用 wat2wasm 工具将其转换为二进制形式。如果我们试图审问由这种转换产生的结构，我们将看到以下内容：

```bash
> wasm-objdump -x hello.wasm

hello.wasm:	file format wasm 0x1

Section Details:

Type [1]:
 - type [0] (i32, i32) -> i32
Function [1]:
 - func [0] sig=0 <how_old>
Export [1]:
 - func [0] <how_old> -> "how_old"
Code [1]:
 - func [0] size=7 <how_old>
```

请注意，与我们的空模块相比，多填了很多部分。首先，我们有一个 Type 部分，定义了一个签名。它提出了一个需要两个 i32 并返回一个 i32 的类型。这对我们的`how_old` 方法来说是一个合适的签名。这个类型没有被赋予一个名字，但是它仍然可以被用来设置期望值，并在函数配置方面进行验证。

接下来我们有一个 Function 部分，将我们的类型（Type 部分的类型 0）链接到一个命名的函数。因为我们导出了我们的函数，以使它对我们的主机环境或其他模块可用，我们看到内部函数 `<how_old>` 通过名称 `how_old` 被导出。最后，我们有一个代码部分，包含了我们唯一的函数的实际指令。

图 3-2 显示了我们的模块在 WebAssembly Code Explorer [^3] 中的样子。

![图 3-2. 我们的 Hello, World! 模块在 WebAssembly 代码资源管理器中被可视化。](../images/f3-2.png)

红色表示部分的边界，但你也可以通过在浏览器中的各个部分上移动来获得更多的细节。例如，导出部分的紫色字节，如果你把鼠标放在其中一个字节上，应该会显示导出的函数 `how_old` 的名称。你可以通过在最后的代码部分的绿色和蓝色字节上看到实际的指令。

如果你仔细看一下例 3-2 的时候，你会注意到我们的变量名在默认情况下没有被带入。`wasm-objdump` 也强调了这个事实。为了达到调试的目的，你需要在 wat2wasm 命令中指定这样做：

```bash
> wat2wasm hello.wat -o hellodebug.wasm --debug-names
> wasm-objdump -x hellodebug.wasm

hellodebug.wasm:	file format wasm 0x1

Section Details:

Type [1]:
 - type [0] (i32, i32) -> i32
Function [1]:
 - func [0] sig=0 <how_old>
Export [1]:
 - func [0] <how_old> -> "how_old"
Code [1]:
 - func [0] size=7 <how_old>
Custom:
 - name: "name"
 - func [0] <how_old>
 - func [0] local [0] <year_now>
 - func [0] local [1] <year_born>
```

请注意，wat2wasm 使用自定义部分来保留函数和局部变量的细节。其他工具可能会出于自己的目的使用这一部分，但这是通常捕获调试信息的方式。在图 3-3 中，你可以看到由于这个自定义部分的存在，模块中有更多的字节。

![图 3-3. 我们的 Hello, World! 模块在 WebAssembly 代码浏览器中可视化地保留了调试细节。](../images/f3-3.png)

## 使用模块

一旦你理解了检查 WebAssembly 模块的静态、二进制结构的过程，你就会想继续以更动态的方式来处理它。我们已经在一些例子中看到了通过 JavaScript API 实例化模块的基本知识，例如在例 2-4 中，我们已经看到了通过 JavaScript API 实例化模块的基本原理，但还有其他的事情我们也可以做。

例 3-2 的代码中产生了一个导出部分，但正如我们在表 3-1 中看到的，还有一个潜在的导入部分，用于接收来自托管环境的元素。这最终可以包括 *Memory* 和 *Table* 实例，我们将在随后的章节中看到，但现在我们可以导入一个函数到模块中，使我们可以更直接地与 WebAssembly 的控制台窗口进行通信。请记住，我们仍在整理底层细节，你对这些技术的日常经验可能会在更高的层级上。

请看例 3-3，这是我们到目前为止的例子的一个新版本，它导出了第二个函数。更重要的是，它还导入了一个函数。

```c
(module
    (func $log (import "imports" "log_func") (param i32)) ①

    (func $how_old (param $year_now i32) (param $year_born i32) (result i32) ②
        local.get $year_now
        local.get $year_born
        i32.sub)

    (func $log_how_old (param $year_now i32) (param $year_born i32) ③
       	local.get $year_now
	local.get $year_born
	call $how_old
	call $log
    )

    (export "how_old" (func ow_old)) ④
    (export "log_how_old" (func $log_how_old)) ⑤
)
```

1. 从主机导入一个期望有一个 i32 参数的函数
2. 与之前的 `$how_old` 函数一样
3. 一个新的函数，需要两个参数，然后调用我们导入的函数 
4. 像以前一样导出我们的旧函数 `how_old`
5. 导出我们新的 log_how_old 函数

正如你所看到的，我们有一个新的函数可以在我们的模块中调用，但我们现在还不能调用它。我们以前的函数仍然可用，没有改变。我们的新函数调用旧函数来做数学运算，但希望有一个叫做 `log_func` 的函数可用来调用其结果。为了澄清一些差异，让我们生成 `.wasm` 输出，然后转储模块结构。

```bash
brian@tweezer ~/g/w/s/ch03> wat2wasm hellolog.wat brian@tweezer ~/g/w/s/ch03> wasm-objdump -x hellolog.wasm
    hellolog.wasm:  file format wasm 0x1
    Section Details:
    Type [3]:
     - type [0] (i32) -> nil
     - type [1] (i32, i32) -> i32
     - type [2] (i32, i32) -> nil
    Import [1]:
     - func [0] sig=0 <imports.log_func> <- imports.log_func
    Function [2]:
     - func [1] sig=1 <how_old>
     - func [2] sig=2 <log_how_old>
    Export [2]:
     - func [1] <how_old> -> "how_old"
     - func [2] <log_how_old> -> "log_how_old"
    Code [2]:
     - func [1] size=7 <how_old>
     - func [2] size=10 <log_how_old>
```

这是我们第一次有一个导入部分的条目。它被定义为有一个我们还没有见过的类型。如果你看一下类型部分，你会看到我们现在指定了三种类型：一种是需要一个 i32 但不返回任何东西的类型，两个 i32 参数和一个 i32 返回值的类型，以及另一个需要两个 i32 且不返回任何东西的新类型。

这些类型中的第一个被定义在我们的导入中。我们希望主机环境能给我们一个可以调用的函数，这个函数将接收一个 i32。这个函数的目的是以某种方式打印出参数，而不是返回任何东西，所以它不需要一个返回类型。我们希望能从我们之前在 JavaScript 方面忽略的 `importObject` 中找到这个函数。第二种类型和之前一样。第三种是采取参数来调用我们的 `$how_old` 函数，但随后将记录 ，所以它也不需要返回值。导入和函数部分向你展示了函数和签名之间的联系。

为了通过 `importObject` 提供元素，我们将需要一些 HTML 代码，如例 3-4 所示。

例 3-4. 一个 HTML 文件来实例化我们的模块，并通过一个方法来调用导入对象

```html
<!doctype html>

<html>
  <head>
      <meta charset="utf-8">
      <title>WASM Import test</title>
      <script src="utils.js"></script>
  </head>

  <body>
    <script>
      var importObject = {
        imports: {log_func: function (arg) {console.log ("You are this old:" + arg + "years.");
          },

          log_func_2: function (arg) {alert ("You are this old:" + arg + "years.");
          }
        }
      };

      fetchAndInstantiate ('hellolog.wasm', importObject).then (function (instance) {console.log (instance.exports.log_how_old (2021, 2000));
      });

    </script>
  </body>
</html>
```

比较例 3-3 中的导入语句和这个对象的结构。注意到有一个 import 命名空间，里面有一个叫做`log_func`的函数。这就是我们的导入语句所指定的结构。`$log_how_old`函数将其两个参数推到堆栈顶部，然后用调用`$how_old`指令调用我们之前的函数。请记住，该函数将一个参数减去另一个参数，然后将结果返回到堆栈顶部。在这一点上，我们不需要将该值重新推到堆栈中；我们可以简单地调用我们命名为`$log` 的导入函数。前一个函数的结果将是这个新调用的参数。花点时间来确保你理解参数、返回值和函数之间的关系。

如果你复制上一章的 `utils.js` 文件（它提供了 `fetchAnd Instantiate ()` 函数 [^4])，然后像我们之前所做的那样通过 HTTP 来提供这些东西，你可以在你的浏览器中加载新的 HTML 文件。最初你不会看到任何东西，因为我们的 `log_func` 只是把它的参数转储到 `console.log ()`。然而，如果你在浏览器的开发工具中查看控制台，你应该看到如图 3-4 所示内容。

![图 3-4. 用一个导入的 JavaScript 函数调用我们的新函数的结果](../images/f3-4.png)

如果你把 `importObject` 改成如例 3-5 的样子，然后在浏览器中重新加载 HTML 文件，你将不再看到控制台中的信息；你应该看到一个弹出的警报信息。显然，我们的 WebAssembly 代码没有任何变化 —— 我们只是从 JavaScript 方面传入了一个不同的函数，因此看到了一个不同的结果。随着我们对这个主题的深入研究，我们将看到更复杂的互动，但希望你开始看到 WebAssembly 和 JavaScript 代码如何通过导入和导出部分进行互动。

例 3-5. 同样的 WebAssembly 模块可以用不同的方法实例化来调用

```
javascript
var importObject = { 
  imports: {log_func: function (arg) {alert ("You are this old:" + arg + "years.");
    }
  }
};
```

实例化模块和调用它们的函数将是你通过 JavaScript API 与它们进行的主要互动，但还有一些额外的行为可以供你使用。如果你想知道一个模块导入或导出了什么方法，你可以使用 JavaScript API 来询问一个加载的模块。如果你不调用`utils.js`中的`fetchAndInstantiate ()` 方法，而是改变 HTML，使之具有如例 3-6 所示的代码，你会看到如图 3-5 所示的结果。

例 3-6. 我们可以用 JavaScript API 做更多的事情，包括流式编译

```javascript
WebAssembly.compileStreaming (fetch ('hellolog.wasm'))
  .then (function (mod) {var imports = WebAssembly.Module.imports (mod);
  console.log (imports [0]);
  var exports = WebAssembly.Module.exports (mod);
  console.log (exports);
  }
);
```

![图 3-5. 通过 JavaScript API 查询模块结构](../images/f3-5.png)

一旦我们学习了更多的概念，并开始进入更高级的语言来表达我们的行为，WebAssembly 的全部力量就会开始显现出来 [^5]。

到目前为止，我们一直在使用一个名为 `utils.js` 的文件中的代码块，看起来就像例 3-7 中那样。对于简单的模块，这很好，但是当你的模块变大时，有一些内置的延迟可以被消除。性能不仅仅是指运行时的性能，它也是指加载时的性能。

例 3-7. 我们一直在用简单的方式来实例化模块

```javascript
function fetchAndInstantiate (url, importObject) {return fetch (url).then (response =>
    response.arrayBuffer ()).then (bytes =>
    WebAssembly.instantiate (bytes, importObject)
  ).then (results =>
    results.instance
  );
}
```

这里的问题是，尽管我们使用 Promise 来避免阻塞主线程，但我们先将模块读入`ArrayBuffer`，然后再将其实例化。我们实质上是在等待，直到所有的网络传输都完成后再编译模块。后 MVP 的首批功能之一是在字节仍在网络上传输的情况下支持编译的能力。模块的格式结构适合这种优化，所以不使用它是很遗憾的。

虽然没有 "正确" 的方法来实例化你的模块（例如，在某些情况下，你可能希望实例化多个模块的实例），但在大多数情况下，例 3-8 中的代码是一种稍微有效的方法。

例 3-8. 大多数情况下，推荐的实例化模块的方式

```c
(async () => {const fetchPromise = fetch (url);
  const {instance} = await WebAssembly.instantiateStreaming (fetchPromise); // Use the module
  const result = instance.exports.method (param1, param2); 
  console.log (result);
})();
```

注意，我们不是在创建`ArrayBuffer`；我们是将`fetch ()`方法中的 Promise 传给 WebAssembly 对象的`instantiateStreaming ()` 方法。这允许基线编译器开始编译函数，因为它们是在网络上出现的。在大多数情况下，代码编译的速度会比网络传输的速度快，所以当你完成下载代码的时候，它应该已经被验证并可以使用。当 JavaScript 完成下载时，通常就是验证过程开始的时候，所以我们看到启动时间的改善。

目前还没有一个正式的方法来缓存 WebAssembly 模块，但这也将成为改善启动时间的一种不显眼的方法。缓存控制和其他网络工件处理将避免在不必要的情况下重新下载模块（例如，如果它们已经被更新）。

## 未来与 ES6 模块集成

虽然如我们所见，能够通过 JavaScript API 工作显然是有用的，但这样做是低级和重复的，这就是为什么我们把它放在一个可重复使用的实用脚本文件中。在未来，我们期望从 HTML 中使用 WebAssembly 模块将更加容易，因为它们将作为 ES6 模块可用。

这是一个有点棘手的问题，因为需要顶层的异步处理，以及模块的图是如何在三个阶段中加载构建、实例化和评估。二进制的 WebAssembly 和基于 JavaScript 的模块验证过程、编译发生的时间以及模块环境记录的遍历和链接方式都有细微差别。

有一项建议是在平台上增加支持，以消除这些差异。在撰写本书时，正处于提案过程的第二阶段 [^6]。Lin Clark [在 YouTube 上](https://www.youtube.com/watch?v=qR_b5gajwug&ab_channel=MozillaHacks) 对其复杂性做了一个很好的介绍。

我们的目标是引入一种声明式的形式，如例 3-9 所示。

例 3-9. 建议的加载 WebAssembly 模块的声明式形式

```javascript
import {something} from "./myModule.wasm";
something ();
```

这不仅有简化 WebAssembly 模块实例化的好处，这也将促进他们参与到 JavaScript 模块的依赖关系图中。如果不区分它们是如何作为依赖关系来管理的，那么开发者将更容易把用多种语言表达的行为混合起来作为完整的解决方案。

该提案有一个整洁的设计和良好的支持，但它涉及到 HTML 规范、ES6 模块规范、实现、JavaScript bundler 和更大的 Node.js 社区的仔细编排。我猜想，在我们看到这个提议的进展之前，不会有多长时间。

现在，我们已经看过了 WebAssembly 二进制文件的结构元素，你应该能自如地检查你自己的和第三方的模块，无论是人工 还是程序化。下一步是看看 WebAssembly 模块的更多动态元素。我们将首先关注 *Memory* 实例，以模拟更传统的编程运行时中连续的内存块的力量。

## 注释

[^1]: 在此，我忽略了脚本语言，但运行脚本的引擎仍将是某种编译的可执行文件。
[^2]: 许多常见的格式（包括 WebAssembly）请见维基百科上的 [这个列表](https://en.wikipedia.org/wiki/List_of_file_signatures)。
[^3]: 在印刷品的书籍中是黑白的，看不到彩色的。
[^4]: 请记住，我们仍然在使用不建议的方法来实例化模块。一次只做一件事！[^5]: 在那之前，如果你想进一步探索，请查看 [API 文档](https://webassembly.github.io/spec/js-api/)。
[^6]: 1 如果你对更底层的提案细节感兴趣，你可以在 [Github](https://webassembly.github.io/esm-integration/js-api/index.html#esm-integration) 上找到。
