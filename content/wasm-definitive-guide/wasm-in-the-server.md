---
linktitle: 第 8 章：在服务器中运行 WebAssembly
summary: "这篇文章是《WebAssembly 权威指南》一书的第八章，介绍了在服务器中运行 WebAssembly 的动机、优势和挑战。它解释了 WebAssembly 是如何提高性能、兼容性和安全性的，以及如何利用不同的语言和工具来创建和部署 WebAssembly 模块。"
weight: 9
icon: book-reader
icon_pack: fas
draft: false
title: 在服务器中运行 WebAssembly
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

> 译者注：这篇文章是《WebAssembly 权威指南》一书的第八章，介绍了在服务器中运行 WebAssembly 的动机、优势和挑战。它解释了 WebAssembly 是如何提高性能、兼容性和安全性的，以及如何利用不同的语言和工具来创建和部署 WebAssembly 模块。

我的职业生涯是从用户界面领域开始的。我参与了一个控制 Network Matrix Switches 的 X/Motif 应用程序 [^1]。从那时起，我就进入了一个 Whole Earth 可视化环境，能够显示数兆字节的地形数据和高光谱图像。这不仅从三维可视化的角度来看很有趣，而且在 "四人帮" 设计模式书出现的前一年，我们受到了 Silicon Graphics 的 Doug Young 的启发，围绕着命令模式建立了整个应用程序 [^2]。

大多数时候，编写和使用软件是一种有趣且有益的体验。你真的可以让人们的生活更轻松，减轻压力，并在他们的工作任务中投入一些思考。尽管有这些优点，但也有缺点。虽然每个人都对 UI 有自己的看法，但其中只有一部分是有根据的意见。

后来，我的职业转变了，我开始专注于设计、架构、后端服务等。我走出了 UI 聚光灯，享受与后端服务器打交道的相对自由。它不像面向用户的活动那样引人注目，但这也很好。

WebAssembly 长期以来一直被定位为客户端技术。它主要被视为扩展浏览器的一种方式，浏览器是一种通用客户端，不再局限于仅通过 JavaScript 进行扩展。WebAssembly 的作用远不止是前端。它还将在浏览器之外的技术领域发挥极其重要的作用。其实 Node.js 一直支持 WebAssembly 模块。

为什么它在服务器上如此有意义可能并不明显，因为在服务器上性能如此关键并且你通常可以自由选择你的实现技术。然而，在硬件异构性和演进、开发人员生产力、商业价值、安全性，最小化基础设施和网络成本的架构选择方面，WebAssembly 有巨大的潜力。我们将在本书的其余部分讨论这一部分，但现在我们只关注在浏览器之外运行 WebAssembly 的基础知识。

## Node.js 的本地扩展

Node.js 的出现是对开发人员在浏览器客户端使用一种语言和一组框架，而在服务器端使用另一组框架这一事实的回应。以前为实现可重用代码所做的努力（通过 Java 本身和 Google Web Toolkit [GWT]）都试图朝另一个方向发展，从服务器到客户端。这是另一个方向的运动。软件开发世界中的许多激动人心的事情都发生在浏览器中，从 Ajax 到 jQuery 再到 Angular 的各种技术和框架。编写在浏览器中运行的代码，然后用不同的语言重写它以在服务器上运行是令人抓狂的。

Node.js 迅速流行起来并成为软件开发人员的宠儿，它现在具有更大的影响力和更高的可重用性。作为一个基于 JavaScript 的环境，在其上运行的应用程序具有天生的可移植性。Node.js 的核心是来自 Google 的高性能 V8 JavaScript 引擎、libuv（它的事件循环和低级功能抽象层的基础），以及建立在所有这些之上的一组 API。这是一个固有的可移植环境。

问题是，即使以强大的 V8 引擎为核心，也不是所有事情都适合用 JavaScript 实现。自然地，它允许使用 C 和 C++ 实现的本机库来扩展该机制。考虑到 JavaScript 对象生命周期和本机代码结构之间的复杂关系，这使得软件开发更加棘手。除此之外，你突然遇到了本机库管理问题。如果你安装带有本机库扩展的 Node.js 应用程序，则需要一个过程让它们在 Linux、Windows、macOS 等平台上进行编译。

许多 WebAssembly 教程展示了将两个数字相加。显然，这不是一个好的使用本地库的案例，除非你在谈论机器学习级别的数学。在[第 9 章](../applied-wasm-tensorflow-js/)中，我们将更深入地讨论这种情况。现在，我们只想强调将 Node.js 与本机库集成的相对复杂性，即使是对于这个简单的、不合理的示例也是如此。

主要问题是 C 和 C++ 代码可以直接访问内存，而 JavaScript 代码不能。在 Node.js 环境中，V8 引擎为在其中运行的 JavaScript 代码管理内存。这使得在 JavaScript 和引擎的本机部分之间传递字符串、结构、参数和其他占用内存空间的元素变得更加棘手。V8 的目的是在浏览器中隔离 JavaScript，使其不会干扰分配给不同页面上其他代码的内存。当它嵌入到 Node.js 环境中时，会保持这种隔离。

服务器端框架通常是可扩展的，因此我们可以添加额外的响应行为、过滤器、授权模型和数据处理工作流。在 Java 世界中，服务器开发人员可以通过多种方式来部署行为。有 servlet、Spring bean、反应式系统等等。这些扩展的结构通常由标准或公认的惯例定义。

在 Node.js 中，历史上有像 Express 这样的中间件，它们是用 C 和 C++ 编写的原生插件。这种环境中的大多数应用程序都没有原生插件，因为 JavaScript 引擎已经相当不错了，而且似乎有无穷无尽的开源库可以满足各种需求。但是，对于 JavaScript 性能不合适的情况，可以创建扩展并使其可从 JavaScript 端调用。

不幸的是，这不是一件简单的事情。首先，许多 JavaScript 开发人员并不是专业的 C 和 C++ 程序员。这两种语言和运行时之间存在很大差异，存在一条深深的鸿沟，将内存从 C 和 C++ 的不受限制的世界传递到 JavaScript 的孤立的、垃圾收集的世界。即使开发人员精通这些低级语言，使用本地库也会使构建过程复杂化。突然间，程序工件不再具有固有的可移植性，我们需要跟踪 Linux、macOS 和 Windows 版本的本机库。

让我们看一个简单的例子，到目前为止，我们已经在本书中看到过很多次了。Node.js 的插件文档中有一个很好的[例子](https://nodejs.org/api/addons.html#addons_addon_examples)，我们对比一下。首先，请参阅[附录](../appendix/) 以确保安装了 node 和 node-gyp 命令。然后看下例 8-1，你会看到一个将两个数字相加的函数。

例 8-1. 来自 Node 网站的 Node.js 插件

```cpp
//addon.cc
#include <node.h>

namespace demo {

using v8::Exception;
using v8::FunctionCallbackInfo;
using v8::Isolate;
using v8::Local;
using v8::Number;
using v8::Object;
using v8::String;
using v8::Value;

// This is the implementation of the "add" method
// Input arguments are passed using the
//const FunctionCallbackInfo<Value>& args struct
void Add (const FunctionCallbackInfo<Value>& args) {Isolate* isolate = args.GetIsolate ();

  // Check the number of arguments passed.
  if (args.Length () <2) {
    // Throw an Error that is passed back to JavaScript
    isolate->ThrowException (Exception::TypeError (
        String::NewFromUtf8 (isolate,
                            "Wrong number of arguments").ToLocalChecked ()));
    return;
  }

  // Check the argument types
  if (!args [0]->IsNumber () || !args [1]->IsNumber ()) {isolate->ThrowException (Exception::TypeError (
        String::NewFromUtf8 (isolate,
                            "Wrong arguments").ToLocalChecked ()));
    return;
  }

  // Perform the operation
  double value =
      args [0].As<Number>()->Value () + args [1].As<Number>()->Value ();
  Local<Number> num = Number::New (isolate, value);

  // Set the return value (using the passed in
  // FunctionCallbackInfo<Value>&)
  args.GetReturnValue ().Set (num);
}

void Init (Local<Object> exports) {NODE_SET_METHOD (exports, "add", Add);
}

NODE_MODULE (NODE_GYP_MODULE_NAME, Init)

}  //namespace demo
```

此方法称为 `Add()`，它接受一个 `FunctionCallbackInfo<Value>&` 引用类型。从这里，我们检索 Isolate 实例，它是 V8 为该实例维护的内存子系统的句柄。如果没有两个参数或者它们不是数字类型，则抛出异常。否则，我们将值作为数字检索，将它们相加，创建一个新位置来保存这些值，并将其设置为函数的返回类型。除了这些，我们还需要通过 `Init()` 方法向 Node.js 注册模块。

下一步是构建附加组件。在示例 8-2 中，你可以看到 `binding.gyp` 文件，它指示 node-gyp 命令如何构建。这可能是一个更详细的过程，但我们这里的需求相当简单。

例 8-2. 附加组件的构建说明

```json
{
  "targets": [
    {
      "target_name": "addon",
      "sources": ["addon.cc"]
    }
  ]
}
```

构建命令非常简单明了（我隐藏了一些细节）：

```bash
brian@tweezer ~/g/w/s/c/node-addon> node-gyp configure build 
gyp info it worked if it ends with ok
gyp info using node-gyp@8.0.0
gyp info using node@15.4.0 | darwin | x64
gyp info find Python using Python version 3.8.3 found at "/usr/local/bin/python3"
gyp http GET https://nodejs.org/download/release/v15.4.0/node-v15.4.0-hdrs.tar.gz
gyp http 200 https://nodejs.org/download/release/v15.4.0/node-v15.4.0-hdrs.tar.gz
gyp http GET https://nodejs.org/download/release/v15.4.0/SHASUMS256.txt
gyp http 200 https://nodejs.org/download/release/v15.4.0/SHASUMS256.txt
...
gyp info spawn args ['BUILDTYPE=Release', '-C', 'build']
CXX (target) Release/obj.target/addon/addon.o
SOLINK_MODULE (target) Release/addon.node
```

附加组件已经构建完成。我们可以用例 8-3 的代码来测试它。

例 8-3. 测试本地插件的 JavaScript 代码

```javascript
//test.js
const addon = require ('./build/Release/addon');
console.log ('This should be eight:', addon.add (3, 5));
```

从表面上看，使用这个附加组件感觉类似于调用 WebAssembly 模块，但显然实现起来比我们在其他地方调用的数学加法 C 代码要复杂得多。真正的问题是，本地库的复杂性很难管理。现在，有了 WebAssembly，这些都不再需要了，你可以理解为什么 Node.js 社区对 WebAssembly 版本的库感到兴奋。它们提供了良好的性能增益，完全可移植，并简化了它们的部署模型。

## WebAssembly 和 Node.js

虽然大多数人认为 WebAssembly 是一种客户端浏览器技术，但 Node.js 几乎与浏览器一样早就支持从 WebAssembly 模块调用函数。我不打算创建任何实际的“服务器”，因为我认为这可能会分散注意力，但你显然可以构建 REST API 或类似的东西，并且仍然使用我提到的功能。

让我们从一个简单的例子开始，例 8-4。

例 8-4. 两个数字相加的简单程序

```c
#include <emscripten.h>
#include <stdio.h>

EMSCRIPTEN_KEEPALIVE int add (int x, int y) {
  return x + y;
}

int main () {
  printf ("The sum of 2 and 3 is: % d\n", add (2,3));
  return 0;
}
```

使用 clang 编译和执行：

```bash
brian@tweezer ~/g/w/s/c/node> clang add.c 
brian@tweezer ~/g/w/s/c/node> ./a.out 
The sum of 2 and 3 is: 5
```

如果我们更新源代码，加入一些与 Emscripten 相关的宏，我们就可以很容易地在 Node.js 中运行它，就像我们之前看到的那样。我还删除了`main ()`方法，因此我们的模块将不再期望实现 `printf ()` 函数，因为我们将在服务器端的 JavaScript 世界中运行。更新后的代码见于例 8-5。

例 8-5. 一个用 Emscripten 宏进行两个数字相加的简单程序

```c
#include <emscripten.h> ①
EMSCRIPTEN_KEEPALIVE int add (int x, int y) { ②
  return x + y;
}
```

1. 包括宏定义的 Emscripten 头文件
2. 告诉 Emscripten 编译器保持 `add ()` 方法的存在。

现在我们可以用 emcc 重新编译，然后用 Node.js 运行它：

```bash
brian@tweezer ~/g/w/c/node> emcc add.c
brian@tweezer ~/g/w/c/node> ls -alF total 376
drwxr-xr-x	6 brian staff	   192 Apr 18 15:05 ./
drwxr-xr-x     10 brian staff	   320 Apr 18 13:08 .../
-rwxr-xr-x	1 brian staff	 49456 Apr 18 15:05 a.out.
-rw-r--r--	1 brian staff   121686 Apr 18 15:05 a.out.js
-rwxr-xr-x	1 brian staff	 11805 Apr 18 15:05 a.out.wasm
-rw-r--r--	1 brian staff	   141 Apr 18 15:05 add.c
brian@tweezer ~/g/w/c/node> node a.out.js
The sum of 2 and 3 is: 5
```

如果你研究一下 `a.out.js` 这个文件，你会看到 Emscripten 工具链为我们处理的所有设置。

有一个适当的基于 JavaScript 的 WebAssembly API 可以通过 Node.js 运行，就像我们在浏览器中看到的那样。这允许你加载和实例化模块，并在你认为合适的时候调用它们的行为。在幕后，这是 Emscripten 工具链为我们生成的。

然而，我们也有兴趣简化 WebAssembly 模块在服务器中的加载和实例化，就像在浏览器中一样。Node.js 还为加载 ES6 模块提供经验支持，如例 8-6 所示。

例 8-6. 将 WebAssembly 模块加载为 ES6 模块

```javascript
import * as Module from './a.out.wasm';
console.log ('The sum of 6 and 2 is: ' + Module.add (6,2));
```

根据你试图运行以下内容的时间，你可能需要实验特征标志，但注意到它比我们之前看到的要容易处理得多。该行为的表达方式也比我们在之前关于本地附加组件的讨论中看到的要简单得多。你可以看到为什么该社区对持续的 WebAssembly 支持随着时间的推移而增加感到兴奋。

```bash
brian@tweezer ~/g/w/s/c/node> node --experimental-modules --experimental-wasm-modules index.mjs
(node:74571) ExperimentalWarning: Importing Web Assembly modules is an
experimental feature. This feature could change at any time (Use `node
--trace-warnings ...` to show where the warning was created)
The sum of 6 and 2 is: 8
```

最后一个例子，我想引入一个更复杂的第三方库。出于我在本章末尾解释的原因，找到一个好的示例而不引起太多麻烦可能很困难。有些事情我们还没有涉及，但我们已经开始在本章中奠定基础。

## 供应链攻击

这给我们带来了另一个考虑。在安全软件系统的世界里，我们面临着一个非常严重的问题，称为供应链攻击。这不是一个新问题，但它越来越严重，越来越频繁。

没有单一的方法可以构建安全系统，当然也不能通过简单地打开加密或类似的安全功能来实现。这些可能是安全系统所必需的，但绝对不够。通常，通过结合纵深防御[^3]、最小特权原则[^4] 以及在组织上接受安全责任的深思熟虑的尝试，你可以开始朝着正确的方向前进。

对我们来说，问题是我们正在运行来自不受信任的第三方的代码，而这些第三方的权限我们通常会在生产中授予自己。开箱即用的 Node 不提供任何保护，这是一个严重的问题，为网络钓鱼、数据泄露和其他攻击开辟了新的攻击媒介。

Hayden Parker 撰写了一篇关于 [2018 年供应链攻击](https://medium.com/@hkparker/analysis-of-a-supply-chain-attack-2bd8fa8286ac) 的文章。基本思想是攻击者将编写一个有用的开源函数供开发人员使用。开发人员经常在不考虑来源的情况下添加依赖项，或者在不考虑依赖项的情况下添加源的水平集合。一旦代码在生态系统中获得足够的使用，精心控制的小更新就会开始以微妙且不可预测的方式暴露攻击。基本上，代码可能会开始寻找加密货币私钥或其他有用的敏感信息。

这个问题唯一真正的解决方案之一是一个活跃而专注的硬件和软件开发人员社区，他们手动检查每个依赖项的每个更新（及其相应的交叉依赖项综合列表），这几乎可以保证此类问题永远不会发生。另一种解决方案是在没有代码有权做任何想做的事情的场景中运行。Node.js 传统上允许这种模式，这就是为什么它的创建者 Ryan Dahl 创造了一些新的和更安全的东西。

## WebAssembly 和 Deno

对于 JavaScript 和 Typescript，Deno 可能比 Node.js [^5] 更安全。尽管两者最初都是由同一个人构建的，但在 Node.js 中并没有考虑到安全问题，因此事后很难修复。Deno 以安全作为默认位置开始。除非获得许可，否则在 Deno 运行时运行的代码无法访问文件系统或打开网络连接。

这显然不是一个新想法。几乎在 Java 存在的整个过程中，它的核心都有一个安全的许可模型。问题是，Java 的权限模型可能有点复杂，很难做到正确。如果有什么东西会扼杀安全性，那就是复杂性。正如你将在下面看到的，Deno 使用基于功能的方法 [^6] 可以更轻松地处理此问题。

除了安全性，Deno 还“本地运行 TypeScript”，通常首先将其转换为某种形式的 JavaScript。感觉更像是原生支持，因为 Deno 在幕后编译它并缓存编译后的形式。这提高了 JavaScript 开发的质量（这也有安全隐患），允许改进类型检查。由于 TypeScript 中强大的类型系统，通常在运行时出现的问题可以在编译时捕获。

从例 8-5 中的 WebAssembly 模块开始，它将两个数字相加。在示例 8-7 中，你可以看到我们首次尝试使用 Deno 的 WebAssembly 支持。超级简单！

例 8-7. 在 Deno 中加载 WebAssembly 模块

```javascript
const wasmCode = await Deno.readFile("./a.out.wasm"); 
const wasmModule = new WebAssembly.Module(wasmCode); 
const wasmInstance = new WebAssembly.Instance(wasmModule); 
const add = wasmInstance.exports.add as CallableFunction
console.log("2 + 3 =  " + add(2,3));
```

不要高兴的太早。我们试图从文件系统中读取，但没有权限。此时 Deno 的安全优势显露了出来。

```bash
brian@tweezer ~/g/w/s/c/deno> deno run main.ts
error: Uncaught (in promise) PermissionDenied: Requires read access to "./a.out.wasm", run again with the --allow-read flag

const wasmCode = await Deno.readFile ("./a.out.wasm");
                 ^
   at unwrapOpResult (deno:core/core.js:100:13)
   at async open (deno:runtime/js/40_files.js:46:17)
   at async Object.readFile (deno:runtime/js/40_read_file.js:19:18)
   at async file:///Users/brian/git-personal/wasm_tdg/src/ch08/deno/main.ts:1:18
```

如果我们用下面的命令重新运行就会愉快得多：

```bash
brian@tweezer ~/g/w/s/c/deno> deno run --allow-read main.ts
Check file:///Users/brian/git-personal/wasm_tdg/src/ch08/deno/main.ts 
2+3= 5
```

虽然我不想被运行 Node.js 和 Deno HTTP 服务器的细节分散注意力，但我承认在本章关于服务器的内容中我还没有运行服务器有点遗憾。所以，下面是一个简单的 HTTP 服务器。

在例 8-8 中，你看到了 Deno 如何允许通过 HTTP 拉取版本化模块以供使用。在此示例中，我们从 Deno 标准库中提取了一个基本的 HTTP 服务器。

例 8-8. 将 WebAssembly 与 Deno HTTP 服务器一起使用

```javascript
import {serve} from "https://deno.land/std@0.93.0/http/server.ts";

const wasmCode = await Deno.readFile ("./a.out.wasm");
const wasmModule = new WebAssembly.Module (wasmCode);
const wasmInstance = new WebAssembly.Instance (wasmModule);
const add = wasmInstance.exports.add as CallableFunction

const server = serve ({hostname: "0.0.0.0", port: 9000});
console.log (`HTTP webserver running.  Access it at:  http://localhost:9000/`);

for await (const request of server) {let bodyContent = "2 + 3 =" + add (2,3);
  request.respond ({status: 200, body: bodyContent});
}
```

准备好失败吧！就像我们没有权限从文件系统中读取的 TypeScript 代码一样，我们也不能在没有权限的情况下监听网络连接！

```bash
brian@tweezer ~/g/w/s/c/deno> deno run --allow-read main-serve.ts 
error: Uncaught (in promise) PermissionDenied: Requires net access to "0.0.0.0:9000", run again with the --allow-net flag
  const listener = Deno.listen (addr);
                        ^
    at unwrapOpResult (deno:core/core.js:100:13)
    at Object.opSync (deno:core/core.js:114:12)
    at opListen (deno:runtime/js/30_net.js:18:17)
    at Object.listen (deno:runtime/js/30_net.js:184:17)
    at serve (https://deno.land/std@0.93.0/http/server.ts:303:25)
    at file:///Users/brian/git-personal/wasm_tdg/src/ch08/deno/main-serve.ts:8:16
```

幸运的是，我们被告知该怎么做，而且这是个容易解决的问题。

```bash
brian@tweezer ~/g/w/s/c/deno> deno run --allow-read --allow-net main-serve.ts 
HTTP webserver running. Access it at: http://localhost:9000/
```

现在一个简单的 HTTP 客户端可以获取我们的结果：

```bash
brian@tweezer ~> http http://localhost:9000
http/1.1 200 ok
content-length: 9

2 + 3 = 5
```

接下来我们将看一下 Deno 和 WebAssembly 的最后一个例子。在我们有机会讨论 WebAssembly 系统接口（WASI）标准之前，我对展示第 11 章中的某些类型的功能一直有点犹豫不决。目前，我想展示 WebAssembly 与 Deno 的使用，不需要太多额外的细节。

Tilman Roeder [^7] 创建了一个内存 SQLite WebAssembly 模块，并将其封装以便在 JavaScript 和 TypeScript 中使用，你可以在 [GitHub](https://github.com/dyedgreen/deno-sqlite) 上获取。关于它的细节我们暂且不提，但使用它是非常简单的，如例 8-9 所示。

例 8-9. 在 Deno HTTP 服务器中使用 WebAssembly SQLite 包装器

```typescript
import {DB} from "https://deno.land/x/sqlite/mod.ts";
import {serve} from "https://deno.land/std@0.93.0/http/server.ts";

// Create the Database. This requires write access!

const db = new DB ("pl.db");
db.query ("DROP TABLE IF EXISTS languages",);

db.query ("CREATE TABLE languages (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)",
);

const names = ["C", "C++", "Rust", "TypeScript"]

// Populate the database

for (const name of names) {db.query ("INSERT INTO languages (name) VALUES (?)", [name]);
}

// Close out the connection

db.close ();

const server = serve ({hostname: "0.0.0.0", port: 9000});
console.log (`HTTP webserver running.  Access it at:  http://localhost:9000/`);

for await (const request of server) {
    // Re-open the Database

    const db = new DB ("pl.db");
    let bodyContent = "Programming Languages that work with WebAssembly:\n\n";

    for (const [name] of db.query ("SELECT name FROM languages")) {bodyContent += name + "\n";}

    bodyContent += "\n";
    request.respond ({status: 200, body: bodyContent});

    // Close the Database
    db.close ();}
```

我们从创建数据库文件开始，你应该察觉到这里还需要另一个运行时权限，而且确实如此。之后，我们将一些数据加载到数据库中并关闭连接。

一旦启动服务器，在收到适当的 HTTP 请求后，我们将再次打开数据库，运行查询，生成结果，然后关闭数据库。我并不是说这是高质量的生产代码，但这段代码在 Deno 中以及在 Deno 支持的各种平台上安全运行是非常了不起的。虽然我们正在处理一个包装的 C 语言库（即 SQLite3），但 WebAssembly 使代码可移植，同时仍然具有合理的性能。我希望使用安全、快速、可移植的 WebAssembly 代码扩展服务器基础设施的想法更有意义。

以下命令将以适当的权限启动服务器：

```bash
brian@tweezer ~/g/w/s/c/deno> deno run --allow-read --allow-write --allow-net db-serve.ts
HTTP webserver running.  Access it at:  http://localhost:9000/
```

来自 HTTP 客户端的请求会产生我们所期望的结果：

```bash
brian@tweezer ~> http http://localhost:9000 
HTTP/1.1 200 OK
content-length: 74
Programming Languages that work with WebAssembly:

C
C++
Rust
TypeScript
```

## 展望未来

本章所描述的与浏览器相关的巨大飞跃仅仅是个开始。虽然我们放弃了在受限环境中运行的安全限制（除了锁定的 Deno 实例之外），但我们也放弃了浏览器的丰富性。在任何现代浏览器平台上，JavaScript 环境中都有大量可用的功能。这包括 JavaScript 引擎、硬件加速的 2D/3D 图形和视频播放、声音、字体支持、发出网络请求能力等等。默认情况下，Node.js 和 Deno 都不提供浏览器的所有功能，尽管 Deno 试图支持其中的大部分功能。这使得编写可在浏览器内外运行的基于 WebAssembly 的应用程序变得更加困难。

为了让 WebAssembly 的代码可移植。我们需要另一种策略，通过为我们在现代计算平台上期望的功能提供一致的服务接口来使应用程序可移植。这就是为什么我对可以向你展示的示例类型持谨慎态度。这个问题的真正解决方案将在[第 11 章](../wasi/)中介绍。在那之前，请耐心等待，但我们还有很多问题需要讨论。

## 注释

[^1]: Motif 构建在 Xt Intrinsics 库和 X Window System 之上。
[^2]: 命令模式将执行代码的触发事件与实际代码分开，除此之外允许进行宏录制和回放。
[^3]: 一系列的 [重叠的安全控制](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) 组合可以帮助你防止意外的漏洞。
[^4]: [只分配给用户最低权限](https://en.wikipedia.org/wiki/Principle_of_least_privilege) 是这项技术的一部分。
[^5]: [Deno](https://deno.land/) 有很多优点。除了安全之外，还有很多值得喜欢的地方。
[^6]: [基于能力的安全系统](https://en.wikipedia.org/wiki/Capability-based_security) 一般要求行动者证明他们有一个不可磨灭的任务来进行一项行动。
