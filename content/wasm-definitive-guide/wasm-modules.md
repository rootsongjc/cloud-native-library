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

操作系统通常运行编译后的程序[^1]。每个操作系统都有自己的格式，定义了从哪里开始运行，需要什么数据，不同功能位的指令是什么。WebAssembly 也不例外。在本章中，我们将了解程序是如何编译打包的，以及主机怎样处理编译后的程序。

软件工程师可能会在整个职业生涯中都忽略了程序是如何编译、加载和执行的。他们的世界从 `int main (int argc, char **argv)` 或 `static void main (String [] args)` 开始，仅仅到 `if __name == "__main__":` 就结束了。这些是 C、Java 和 Python 程序的众所周知的入口点，因此这是程序员承担控制流责任的地方。但是，操作系统或程序运行时需要在程序启动之前和退出之后构建和拆除可执行结构。加载器需要知道指令从哪里开始、数据元素是如何初始化的、需要加载哪些其他模块或库等。

这些细节通常由可执行文件的性质定义。在 Linux 上，这是由[可执行和可链接格式 (ELF)](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format) 定义的；在 Windows 上，它由[可移植可执行格式 (PE)](https://en.wikipedia.org/wiki/Portable_Executable) 定义； 在 macOS 上，它由 [Mach-O 格式](https://en.wikipedia.org/wiki/Portable_Executable)定义。显然，这些是本机可执行文件的特定于平台的格式。Java 和 .NET 等更多可移植系统使用中间字节码表示，但仍具有定义良好的结构，并且它们的工作方式相似。

WebAssembly MVP 的首要设计考虑之一是定义模块结构，以便 WebAssembly 主机知道要查找和验证什么，以及在执行部署单元时从哪里开始。

在[第 2 章](../hello-world/)中，你看到了比本章开始时更复杂的模块结构。我们将逐步介绍这些部分，然后向你展示一些用于探索 WebAssembly 模块的文本和视觉结构的工具。在上一章中，我们简要讨论了二进制结构。它结构紧凑，转移和装载速度快。你可能不会经常花很多时间查看二进制细节，因为你关注的是软件方面。熟悉模块的布局很有用，让我们来看看。

## 模块结构

空模块是 WebAssembly 最基本的模块。空模块中不需要任何内容，就是一个有效的模块，如例 3-1 所示。

例 3-1. 空模块，但是有效的 WebAssembly 模块。

```
(module)
```

显然，这没有什么可看的，但它可以转换为二进制形式。你会注意到在下面的输出中，它没有占用多少空间，而且它什么都不做。

```bash
brian@tweezer ~/g/w/s/ch03> wat2wasm empty.wat
brian@tweezer ~/g/w/s/ch03> ls -alF
total 16
drwxr-xr-x 4 brian staff 128 Dec 21 14:45 ./ 
drwxr-xr-x 4 brian staff 128 Dec 14 12:37 ../ 
-rw-r--r-- 1 brian staff 8   Dec 21 14:45 empty.wasm
-rw-r--r-- 1 brian staff 8   Dec 14 12:37 empty.wat
```

如果你以视觉为导向，你可能会喜欢使用 WebAssembly Code Explorer，可从 [wasdk GitHub 存储库](https://github.com/wasdk/wasmcodeexplorer)获得。你可以在浏览器中[在线使用](https://wasdk.github.io/wasmcodeexplorer/)它或从克隆它以运行 HTTP 服务器。我将像以前一样使用 Python 3 Web 服务器。

```bash
brian@tweezer ~/g/wasmcodeexplorer> python3 -m http.server 10003
Serving HTTP on :: port 10003 (http://[::]:10003/) ...
```

同样，对于一个空模块来说，它看起来并不多，但一旦我们开始向其中添加一些元素，它将是一个有用的总结。操作系统通常从文件[^2]的前几个字节识别文件格式。它们通常被称为**幻数**。对于WebAssembly，这些字节被编码为 `0x00 0x61 0x73 0x6D`，分别代表字符 a、s、m 的十六进制值，后面是版本号 1（用字节 `0x01 0x00 0x00 0x00` 表示）。

在图 3-1 中，你可以看到魔法字节，这是 WebAssembly 文件格式的版本 1，左侧是一系列数字，右侧是一个空模块结构。

![图 3-1. 空模块在 WebAssembly 代码资源管理器中的可视化表示。](../images/f3-1.png)

使用命令行来检查模块你有很多选择。Wabt 工具包中的 `wasm-objdump` 可执行文件非常有用。请参阅[附录](../appendix/)以帮助安装本书中讨论的各种工具。

如果你在没有指定标志位的情况下运行命令，它会提示错误信息。正如你将看到的，当你有更多细节需要探索时，这些会产生更大的不同。

```bash
brian@tweezer ~/g/w/s/ch03> wasm-objdump empty.wasm
At least one of the following switches must be given:
     -d/--disassemble
     -h/--headers
     -x/--details
     -s/--full-contents
```

现在，我们只需通过使用 `-x` 标志来验证我们的模块虽然无用但却是有效的。这也表明我们处理的是第 1 版的格式。

```bash
brian@tweezer ~/g/w/s/ch03> wasm-objdump -x empty.wasm 
empty.wasm: file format wasm 0x1
Section Details:
```

## 探索模块的各个部分

关于我们引入的概念，有一个循环依赖的问题。模块格式必须支持 WebAssembly 包含的所有元素，其中一些我们将在后面的章节中介绍。我们将主要关注到目前为止所看到的内容，很快会介绍其他部分的元素。

该模块的整体结构基于一系列可选的编号部分，每个部分都涉及 WebAssembly 的一个特定功能。在表 3-1 中，我们可以看到这些部分的列表和描述。

表 3-1. WebAssembly 模块列表

| ID   | 名称       | 描述                                         |
| ---- | ---------- | -------------------------------------------- |
| 0    | Custom     | 调试或元数据信息供第三方使用                 |
| 1    | Type       | 模块中使用的类型定义                         |
| 2    | Import     | 模块中使用的导入元素                         |
| 3    | Function   | 与模块中的函数相关的类型签名                 |
| 4    | Table      | 定义模块所使用的间接的、不可改变的引用的表格 |
| 5    | Memory     | 模块使用的线性内存结构                       |
| 6    | Global     | 全局变量                                     |
| 7    | Export     | 模块提供的导出元素                           |
| 8    | Start      | 可选的启动函数，用于启动模块                 |
| 9    | Element    | 模块定义的元素                               |
| 10   | Code       | 模块定义的函数的主体                         |
| 11   | Data       | 模块定义的数据元素                           |
| 12   | Data Count | 模块定义的数据元素的数量                     |

参考下面来自[第 2 章](../hello-world/)中的例子。

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

1. 内部函数 `$how_old`
2. 导出的函数 `how_old`

我们使用 wat2wasm 工具将其转换为二进制形式。如果我们尝试询问这种转换产生的结构，我们会看到以下内容：

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

请注意，与空模块相比，还有更多的部分。首先，我们有一个类型部分，它定义了一个签名。它提出了一个接受两个 i32 并返回一个 i32 的类型。这是我们的 `how_old` 方法的签名。该类型没有给出名称，但它仍然可以用于设置期望并在函数配置方面进行验证。

接下来我们有一个 Function 部分，它将我们的类型（Type 部分中的 `type [0]`）链接到命名函数。因为我们导出了我们的函数以使其可用于我们的主机环境或其他模块，所以我们看到了内部函数 `<how_old>` 以名称 `how_old` 导出。最后，我们有一个 Code 部分，其中包含我们唯一函数的实际说明。

图 3-2 显示了我们的模块在 WebAssembly Code Explorer[^3] 中的样子。

![图 3-2. 我们的 Hello, World! 模块在 WebAssembly 代码资源管理器中被可视化。](../images/f3-2.png)

红色表示部分边界，但你也可以通过在浏览器中移动部分来获得更多详细信息。例如，导出部分中的紫色字节，如果将鼠标悬停在其中一个字节上，它应该显示导出函数的名称 `how_old`。你可以在最后的代码部分中通过绿色和蓝色字节查看实际指令。

如果仔细查看例 3-2，你会注意到默认情况下我们的变量名没有被引入。`wasm-objdump` 也强调了这一事实。出于调试目的，你需要在 wat2wasm 命令中指定：

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

请注意，wat2wasm 使用自定义部分来保留函数和局部变量的详细信息。其他工具可能会出于自己的目的使用此部分，但这通常是捕获调试信息的方式。在图 3-3 中，你可以看到由于这个自定义部分，模块中有更多的字节。

![图 3-3. 我们的 Hello, World! 模块在 WebAssembly 代码浏览器中可视化地保留了调试细节。](../images/f3-3.png)

## 使用模块

理解了 WebAssembly 模块的静态二进制结构后，你可能希望以更动态的方式处理它。我们已经在一些例中看到了通过 JavaScript API 实例化模块的基础知识，例如在例 2-4 中，但是我们还可以做其他事情。

例 3-2 中的代码生成一个导出部分，但正如我们在表 3-1 中看到的，还有一个潜在的导入部分，它从主机环境接收元素。这最终可以包括 Memory 和 Table 实例，正如我们将在后续章节中看到的那样，但现在我们可以将一个函数导入到模块中，使我们能够更直接地与 WebAssembly 的控制台窗口通信。请记住，我们仍在整理底层细节，你对这些技术的日常体验可能会处于更高层次。

看一下例 3-3，这是例 3-2 的新版本，它导出了第二个函数。更重要的是，它还导入了一个函数。

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

    (export "how_old" (func how_old)) ④
    (export "log_how_old" (func $log_how_old)) ⑤
)
```

1. 从主机导入一个期望有一个 i32 参数的函数
2. 与之前的 `$how_old` 函数一样
3. 一个新的函数，需要两个参数，然后调用我们导入的函数 
4. 像以前一样导出我们的旧函数 `how_old`
5. 导出我们新的 `log_how_old` 函数

如你所见，我们有一个可以在模块中调用的新函数，但我们还不能调用它。我们以前的函数仍然可用，没有变化。我们的新函数调用旧函数来做数学运算，但需要一个名为 `log_func` 的函数来调用它的结果。为了澄清一些差异，让我们生成 `.wasm` 输出，然后转储模块结构。

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

这是我们第一次有导入部分的条目。这是我们尚未见过的类型。如果你查看类型部分，你会看到我们现在指定了三种类型：一种接收一个 i32 但不返回任何内容，一种接收两个 i32 参数和一个 i32 返回值，另一种接收两个 i32，不返回任何内容。

这些类型中的第一个在我们的导入中定义。我们希望主机环境给我们一个函数，我们可以调用它来接收 i32。这个函数的目的是以某种方式打印出参数，而不返回任何东西，所以它不需要返回类型。我们希望从我们之前在 JavaScript 端忽略的 importObject 中找到这个函数。第二种和前面一样。第三个是带参数调用 `$how_old` 函数，但随后会记录，因此它也不需要返回值。Imports 和 Functions 部分显示了函数和签名之间的链接。

要通过 `importObject` 提供元素，我们需要一些 HTML 代码，如例 3-4 所示。

例 3-4. 一个 HTML 文件来实例化我们的模块，并通过方法来调用导入对象。

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

将例 3-3 中的 import 语句与该对象的结构进行比较。请注意，有一个 import 名称空间，其中包含一个名为 `log_func` 的函数。这是我们的 import 语句指定的结构。`$log_how_old` 函数将它的两个参数压入栈顶，然后调用 `$how_old` 指令调用我们之前的函数。请记住，此函数从一个参数中减去另一个参数并将结果返回到堆栈顶部。此时，我们不需要将该值压回堆栈； 我们可以简单地调用我们命名为 `$log` 的导入函数。前一个函数的结果将是这个新调用的参数。花点时间确保你了解参数、返回值和函数之间的关系。

如果你复制上一章的 `utils.js` 文件（它提供了 `fetchAnd Instantiate()` 函数[^4]），然后像我们之前所做的那样通过 HTTP 提供这些东西，你就可以加载新的 HTML 文件。最初你不会看到任何东西，因为我们的 `log_func` 只是将它的参数转储到 `console.log()`。但是，如果你在浏览器的开发人员工具中查看控制台，你应该会看到类似图 3-4 的内容。

![图 3-4. 用一个导入的 JavaScript 函数调用我们的新函数的结果](../images/f3-4.png)

如果将 `importObject` 更改为类似于例 3-5 的样子，然后在浏览器中重新加载 HTML 文件，你将不会再看到控制台消息；你应该会看到一条弹出式警报消息。显然，我们的 WebAssembly 代码没有任何变化——我们只是从 JavaScript 端传入了一个不同的函数，因此看到了不同的结果。当我们深入研究这个主题时，我们将看到更复杂的交互，但希望你开始了解 WebAssembly 和 JavaScript 代码如何通过导入和导出进行交互。

例 3-5.  同一个 WebAssembly 模块可以用不同的方式实例化和调用

```javascript
var importObject = { 
  imports: {log_func: function (arg) {alert ("You are this old:" + arg + "years.");
    }
  }
};
```

实例化模块和调用它们的函数将是你通过 JavaScript API 与它们进行交互的主要方式，但你还可以添加一些额外的行为。如果你想知道模块导入或导出了哪些方法，可以使用 JavaScript API 询问已加载的模块。如果你不调用 `utils.js` 中的 `fetchAndInstantiate()` 方法，而是将 HTML 更改为具有例 3-6 中所示的代码，你将看到如图 3-5 所示的结果。

例 3-6. 我们可以使用 JavaScript API 做更多的事情，包括流式编译。

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

当你了解更多概念，学会使用更高级别的语言来表述后，WebAssembly 的全部功能就会开始显现[^5]。

到目前为止，我们一直在使用名为 utils.js 的文件中的代码块，该文件类似于例 3-7。对于简单的模块，这很好，但是当你的模块变大时，可以消除一些内置延迟。性能不仅指运行时性能，还指加载时性能。

例 3-7.  我们一直在以简单的方式实例化模块

```javascript
function fetchAndInstantiate (url, importObject) {return fetch (url).then (response =>
    response.arrayBuffer ()).then (bytes =>
    WebAssembly.instantiate (bytes, importObject)
  ).then (results =>
    results.instance
  );
}
```

这里的问题是，虽然我们使用 Promises 来避免阻塞主线程，但我们需要在实例化之前将模块读入 ArrayBuffer 中。在编译模块之前，我们实际上是在等待所有网络传输完成。MVP 后续的首批功能之一是能够在字节仍在网络上传输时支持编译。模块的格式结构适合这种优化，所以你理应使用它。

虽然没有“正确”的方法来实例化你的模块（例如，在某些情况下你可能希望实例化一个模块的多个实例），但在大多数情况下，例 3-8 中的代码是一种稍微更有效的方法。

例 3-8. 大多数情况下实例化模块的推荐方式。

```c
(async () => {const fetchPromise = fetch (url);
  const {instance} = await WebAssembly.instantiateStreaming (fetchPromise); // Use the module
  const result = instance.exports.method (param1, param2); 
  console.log (result);
})();
```

请注意，我们不是在创建 `ArrayBuffer`； 我们将 Promise 从 `fetch()` 方法传递给 WebAssembly 对象的 `instantiateStreaming()` 方法。这允许基线编译器在它们出现在网络上时开始编译函数。在大多数情况下，代码的编译速度快于它通过网络传输的速度，因此在你下载完代码时，它应该已经过验证并可以使用了。当 JavaScript 完成下载时，通常是验证过程开始的时候，因此我们看到启动时间有所改善。

目前没有官方的方法来缓存 WebAssembly 模块，但这也是一种改善启动时间的不显眼的方法。缓存控制和其他网络工件处理可避免不必要地重新下载模块（例如，如果它们已更新）。

## 未来与 ES6 模块集成

正如我们所见，虽然通过 JavaScript API 工作很有用，但这样做是低级和重复的，这就是我们将其放在可重用实用程序脚本文件中的原因。将来，我们希望在 HTML 中使用 WebAssembly 模块会更容易，因为它们将作为 ES6 模块提供。

这有点棘手，因为顶层需要异步处理，以及模块的图形是如何在构建、实例化和评估的三个阶段加载的。二进制 WebAssembly 和基于 JavaScript 的模块的验证过程、编译发生的时间以及模块环境记录的遍历和链接方式存在细微差别。

有人提议增加对该平台的支持，以消除这些差异。在撰写本书时，我们正处于提案过程的第二阶段[^6]。Link Clark [在 YouTube 上](https://www.youtube.com/watch?v=qR_b5gajwug&ab_channel=MozillaHacks)很好地介绍了它的复杂性。

我们的目标是引入一种声明形式，如例 3-9 所示。

例 3-9. 用于加载 WebAssembly 模块的建议声明形式

```javascript
import {something} from "./myModule.wasm";
something ();
```

这不仅有利于简化 WebAssembly 模块的实例化，还有助于它们参与 JavaScript 模块的依赖关系图。如果不区分它们作为依赖项的管理方式，开发人员可以更容易将以多种语言表达的行为混合为一个完整的解决方案。

该提案设计简洁，支持良好，但涉及 HTML 规范、ES6 模块规范、实现、JavaScript 捆绑器和 Node.js 社区的通力合作。我猜用不了多久我们就会看到该提案的进展。

现在我们已经了解了 WebAssembly 二进制文件的结构元素，你应该可以轻松地手动和以编程方式检查你自己的和第三方的模块。下一步是查看 WebAssembly 模块的更多动态元素。我们将首先关注 Memory 实例，以模拟更传统的编程运行时中连续内存块的功能。

## 注释

[^1]: 在此，我忽略了脚本语言，但运行脚本的引擎仍将是某种编译的可执行文件。
[^2]: 许多常见的格式（包括 WebAssembly）请见维基百科上的[这个列表](https://en.wikipedia.org/wiki/List_of_file_signatures)。
[^3]: 在印刷品的书籍中是黑白的，看不到彩色。
[^4]: 请记住，我们仍然在使用不建议的方法来实例化模块。一次只做一件事！
[^5]: [GitHub](https://webassembly.github.io/spec/js-api/) 上有该 API 的文档。
[^6]:  [Github](https://webassembly.github.io/esm-integration/js-api/index.html#esm-integration) 上有该提案的更多细节。
