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

我的职业生涯是从用户界面领域开始的。我第一次参与了一个控制 Network Matrix Switches 的 X/Motif 应用程序 [^1]。从那时起，我就进入了一个 Whole Earth 可视化环境，能够显示数兆字节的地形数据和高光谱图像。这不仅从三维可视化的角度来看很有趣，而且在 "四人帮" 设计模式书出现的前一年，我们受到了 Silicon Graphics 的 Doug Young 的启发，围绕着命令模式建立了整个应用程序 [^2]。

在大多数时候，编写和使用的软件是一种有趣和有意义的经历。你可以真正地让人们的生活更轻松，减少压力，在他们的工作任务中投入一些心思。尽管有这些积极因素，但也有其缺点。虽然每个人都对用户界面有意见，但其中只有一些是知情的意见。

我想在某种程度上，这就是 Brian Eno 在上面的引文中所指的。值得注意的是，他是 Roxy Music 的共同创始人之一，是各地音乐发烧友的宠儿。但是，尽管他穿着华丽，但他并不真正享受在聚光灯下，在与 Bryan Ferry 经常发生冲突后，他走自己的路，更注重作曲和制作，而不是成为摇滚明星。

我的职业生涯发生了转变，我开始专注于设计、架构、后端服务等方面。我从用户界面的聚光灯下走出来，享受后端服务器工作的相对自由。它不像面向用户的活动那样引人注意，但这也有好处。

WebAssembly 长期以来都被定位为客户端技术。它主要被看作是一种扩展和扩大浏览器可能性的方式，一个通用的客户端不再局限于只通过 JavaScript 进行扩展。WebAssembly 的作用要大得多，而不仅仅是作为前端的宠儿。它也将在浏览器之外的技术领域发挥极其重要的作用。事实上，它一直被定位在这个位置，Node.js 一直支持 WebAssembly 模块。

这可能并不明显，为什么在服务器上会有这么大的意义，因为在服务器上性能是如此关键，而且你通常可以自由选择你的实施技术。然而，在硬件的异质性和进化、开发人员的生产力、商业价值、安全性以及架构作为设计选择的能力，以最大限度地减少基础设施和网络成本上，存在着一个闪亮的机会，WebAssembly 正在迅速扩展以填补这一空白。在本书的其余部分，我们将填补这一部分，但现在我们只关注在浏览器之外运行 WebAssembly 的基本知识。

## Node.js 的本地扩展

Node.js 的出现是对以下事实的回应：开发人员在浏览器的客户端使用一种语言和一套框架，而在服务器上使用另一套框架。之前为获得可重复使用的代码所做的努力（通过 Java 本身和 Google Web Toolkit [GWT]）试图朝另一个方向前进，即从服务器到客户端。这是在另一个方向的运动。软件开发领域的大部分兴奋点都发生在浏览器上，以及从 Ajax 到 jQuery 到 Angular 等技术和框架的探索中。要写出在浏览器中运行的代码，然后用不同的语言重写在服务器上运行，这让人抓狂。

Node.js 迅速流行起来，成为软件开发者的宠儿，他们现在有了更大的影响力和更大的重用性。作为一个基于 JavaScript 的环境，在其上运行的应用程序具有内在的可移植性。Node.js 的核心是来自 Google 的高性能 V8 JavaScript 引擎、libuv（其事件循环和低级功能的抽象层的基础），以及建立在所有这些之上的一套 API。这是一个固有的可移植环境。

问题是，即使有强大的 V8 引擎作为核心，也不是所有东西都适合用 JavaScript 来实现。自然地，它允许用 C 和 C++ 实现的本地库来扩展机制。鉴于 JavaScript 对象生命周期和本地代码结构之间的复杂关系，这使得软件开发变得更加棘手。除此之外，你突然有了一个本地库的管理问题。如果你安装了一个带有本地库扩展的 Node.js 应用程序，需要有一个过程来让它们在 Linux、Windows、macOS 等系统上编译。

许多 WebAssembly 教程展示了两个数字相加。显然，这不是一个使用本地库的好案例，除非你在谈论机器学习水平的数学。在第 9 章中，我们将更深入地讨论这种情况。现在，我们只想强调一下将 Node.js 与本地库整合在一起的相对复杂性，即使是对于这个简单的、理由不充分的例子。

问题主要在于，C 和 C++ 代码可以直接访问内存，但 JavaScript 代码却不能。在 Node.js 环境中，V8 引擎为运行在其中的 JavaScript 代码管理内存。这使得字符串、结构、参数和其他占用内存空间的元素在引擎的 JavaScript 和本地部分之间的传递更加棘手。V8 的目的是隔离浏览器中的 JavaScript，使其不会干扰分配给不同页面上其他代码的内存。当它被嵌入到 Node.js 环境中时，这种隔离得以保持。

服务器端框架通常是可扩展的，因此我们可以添加额外的响应行为、过滤器、授权模型和数据处理工作流程。在 Java 世界里，有一系列服务器开发者可以部署行为的方式。有 servlets、Spring beans、反应式系统等等。这些扩展的结构通常由标准或完善的惯例来定义。

在 Node.js 中，历来都有像 Express 这样的中间件，然后是用 C 和 C++ 编写的本地插件。这个环境中的大多数应用程序都没有原生的插件，因为 JavaScript 引擎已经变得相当出色，而且似乎有无限的开源库来解决各种需求。然而，对于 JavaScript 性能不合适的情况，可以创建一个扩展，并使其可以从 JavaScript 方面调用。

不幸的是，这并不是一件简单的事情。首先，许多 JavaScript 开发者都不是专业的 C 和 C++ 程序员。这两种语言和运行时之间有很大的区别，把内存从不受限制的 C 和 C++ 世界传递到孤立的、有垃圾收集的 JavaScript 世界，有一条很深的鸿沟。即使开发人员很精通这些低级别语言，采用本地库也会使构建过程复杂化。突然间，程序工件不再具有内在的可移植性，我们需要跟踪 Linux、macOS 和 Windows 版本的本地库。

让我们看看一个简单的例子，到目前为止，我们在本书中已经看到过多次。在关于附加组件的 Node.js 文档中有一个很好的 [例子](https://nodejs.org/api/addons.html#addons_addon_examples)，让我们对比一下。首先，参考 [附录](../appendix/)，确保 node 和 node-gyp 命令已经安装。然后看一下例 8-1，在这里你会看到一个将两个数字相加的单一函数。

例 8-1. 一个来自 Node 网站的 Node.js 插件

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

这个方法叫做`Add ()`，它接受一个`FunctionCallbackInfo<Value>& refer- ence`。从这里，我们检索 Isolate 实例，这是我们对 V8 为这个实例维护的内存子系统的句柄。如果没有两个参数或者它们不是数字类型，我们就抛出一个异常。否则，我们会以数字的形式检索这些值并将它们相加，然后创建一个新的位置来保存这些值，然后将其设置为函数的返回类型。除了这些，我们需要通过`Init ()` 方法向 Node.js 注册该模块。

下一步是建立附加组件。在 例 8-2 中，你可以看到 `binding.gyp` 文件，它指示 node-gyp 命令如何进行构建。这可能是一个更详细的过程，但我们在这里的需求相当简单。

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
brian@tweezer ~/g/w/s/c/node-addon> node-gyp configure build gyp info it worked if it ends with ok
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

在这一点上，附加组件已经构建完成。我们可以用例 8-3 的代码来测试它。

例 8-3. 测试本地插件的 JavaScript 代码

```javascript
//test.js
const addon = require ('./build/Release/addon');
console.log ('This should be eight:', addon.add (3, 5));
```

从表面上看，使用该附加组件感觉与调用 WebAssembly 模块类似，但显然这个实现要比我们在其他地方调用的两个数字相加的 C 代码复杂得多。真正的问题是，本地库的复杂性在管理上是一种痛苦。现在，有了 WebAssembly，就不再需要这些了，你可以理解为什么 Node.js 社区对 WebAssembly 版本的库感到兴奋。它们提供了良好的性能收益，且完全可移植，并简化了其部署模型。

## WebAssembly 和 Node.js

虽然大多数人认为 WebAssembly 是一种客户端的浏览器技术，但 Node.js 几乎和浏览器一样早就支持从 WebAssembly 模块调用函数。我不打算创建任何实际的 "服务器"，因为我认为这可能会分散我想表达的观点，但你显然可以建立一个 REST API 或类似的东西，并仍然使用我提到的功能。

让我们从例 8-4 这个简单的例子开始。

例 8-4. 一个简单的程序，将两个数字相加

```c
#include <emscripten.h>
#include <stdio.h>

EMSCRIPTEN_KEEPALIVE int add (int x, int y) {return x + y;}

int main () {printf ("The sum of 2 and 3 is: % d\n", add (2,3));
  return 0;
}
```

有了 clang，这是很简单的编译和执行：

```bash
brian@tweezer ~/g/w/s/c/node> clang add.c 
brian@tweezer ~/g/w/s/c/node> ./a.out 
The sum of 2 and 3 is: 5
```

如果我们更新源代码，加入一些与 Emscripten 相关的宏，我们就可以很容易地在 Node.js 中运行它，就像我们之前看到的那样。我还删除了`main ()`方法，因此我们的模块将不再期望实现`printf ()` 函数，因为我们将在服务器端的 JavaScript 世界中运行。更新后的代码见于例 8-5。

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
drwxr-xr-x 10 brian staff	   320 Apr 18 13:08 .../
-rwxr-xr-x	1 brian staff	 49456 Apr 18 15:05 a.out.
-rw-r--r--	1 brian staff 121686 Apr 18 15:05 a.out.js
-rwxr-xr-x	1 brian staff	 11805 Apr 18 15:05 a.out.wasm.
-rw-r--r--	1 brian staff	   141 Apr 18 15:05 add.c brian@tweezer ~/g/w/c/node> node a.out.js
The sum of 2 and 3 is: 5
```

如果你研究一下 a.out.js 这个文件，你会看到 Emscripten 工具链为我们处理的所有设置。

有一个适当的基于 JavaScript 的 WebAssembly API 可以通过 Node.js 运行 ，如我们在浏览器中看到的。这允许你加载和实例化模块，并在你认为合适的时候调用它们的行为。在幕后，这就是 Emscripten 工具链为我们生成的东西。

然而，我们也对简化 WebAssembly 模块在服务器中的加载和实例化感兴趣，就像在浏览器中一样。Node.js 也提供了对加载 ES6 模块的经验支持，如例 8-6 所示。

例 8-6. 将 WebAssembly 模块作为 ES6 模块加载

```javascript
import * as Module from './a.out.wasm';
console.log ('The sum of 6 and 2 is: ' + Module.add (6,2));
```

根据你试图运行以下内容的时间，你可能需要实验特征标志，但注意到它比我们之前看到的要容易处理得多。该行为的表达方式也比我们在之前关于本地附加组件的讨论中看到的要简单得多。你可以看到为什么该社区对持续的 WebAssembly 支持随着时间的推移而增加感到兴奋。

```bash
brian@tweezer ~/g/w/s/c/node> node --experimental-modules ↵ --experimental-wasm-modules index.mjs
(node:74571) ExperimentalWarning: Importing Web Assembly modules is an
experimental feature. This feature could change at any time (Use `node
--trace-warnings ...` to show where the warning was created)
The sum of 6 and 2 is: 8
```

作为最后一个例子，我想把一个更复杂的第三方库拉进来。由于我将在本章末尾解释的原因，找到一个好的例子而又不至于引起太多的麻烦是很困难的。有些东西我们还没有介绍，但在本章中已经开始打基础了。

## 供应链攻击

这给我们带来了另一个考虑。在安全软件系统的世界里，我们正面临着一个非常严重的问题，叫做供应链攻击。这不是一个新问题 ，但正变得越来越糟糕，越来越频繁。

没有单一的方法来建立一个安全的系统，当然不是简单地打开加密或类似的安全功能。这些对于一个安全的系统可能是必要的，但绝对是不够的。通常是通过深度防御的组合 [^3]，最少特权原则 [^4]，以及在组织上接受安全责任的深思熟虑的尝试，你可以开始朝着正确的方向前进。

对我们来说，问题是我们正在运行来自不受信任的第三方代码，而我们通常在生产中给予自己的权限。开箱后，Node 没有提供任何保护，这是一个严重的问题，它为网络钓鱼、数据外流和其他攻击提供了新的攻击载体。

Hayden Parker 写了一篇关于 [2018 年的供应链攻击](https://medium.com/@hkparker/analysis-of-a-supply-chain-attack-2bd8fa8286ac) 的文章。其基本思想是，攻击者将编写一个有用的开源功能供开发者使用。开发人员经常在不考虑其来源的情况下增加依赖性，或者不考虑依赖性的来源的横向集合。一旦代码在生态系统中获得足够的使用，在精心控制的情况下进行的小规模更新就会开始以微妙和难以预测的方式暴露攻击。基本上，代码可能开始寻找加密货币私钥或其他有用的敏感信息。
这个问题的唯一真正的解决方案之一是涉及到一个积极和细心的软硬件开发人员社区，他们手工检查每一个依赖关系的每一个更新（以及其相应的全面的交叉依赖关系列表），这几乎可以保证永远不会发生。另一个解决方案是在一个场景中运行，在这个场景中，任何代码都不会被赋予为所欲为的特权。Node.js 传统上允许这种模式，这是其创建者 Ryan Dahl 创建新的和更安全的东西的原因。

## WebAssembly 和 Deno

Deno 是一个可能比 Node.js 更安全的 JavaScript 和 Typescript 的运行时 [^5]。尽管两者最初都是由同一个人建立的，但安全问题在 Node.js 中并没有那么多的考虑，因此很难在事后再去解决。Deno 一开始就把安全作为一个默认位置。在 Deno 运行时运行的代码不能访问文件系统或打开网络连接，除非得到许可。

这显然不是一个新的想法。几乎在 Java 出现的整个过程中，它的核心都有一个安全的许可模型。问题是，Java 的权限模型可能有些拜占庭式的，而且很难做到正确。如果说有什么东西会扼杀安全，那么复杂性是最重要的。正如你将在下面看到的，Deno 有一个更简单的方法，使用基于能力的方法来处理这个问题 [^6]。

除了安全性之外，Deno 还在原生地 "运行 TypeScript"，而它通常会先被转译成某种形式的 JavaScript。当 Deno 在幕后编译它并缓存编译后的形式时，它感觉更像是原生支持。这改善了 JavaScript 开发的质量（这也有安全方面的影响），允许改进类型检查。由于 TypeScript 中强大的类型系统，通常在运行时出现的问题可以在编译时被发现。

从例 8-5 中的 WebAssembly 模块开始，它将两个数字加在一起。在例 8-7 中，你可以看到我们第一次尝试使用 Deno 的 WebAssembly 支持。超级简单！例 8-7. 在 Deno 中加载 WebAssembly 模块

```javascript
const wasmCode = await Deno.readFile ("./a.out.wasm")。
const wasmModule = new WebAssembly.Module (wasmCode);
const wasmInstance = new WebAssembly.Instance（wasmModule）。
const add = wasmInstance.exports.add as CallableFunction 

console.log ("2 + 3 =" + add (2,3))。
```

不幸的是，我们的兴奋是短暂的。至少问题是清楚的。我们试图从文件系统中读取，但没有权限。我们立即看到 Deno 的安全优势。

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

虽然我不想在运行 Node.js 和 Deno HTTP 服务器的细节上分心，但我承认，在关于服务器的这一章中，我还没有运行过服务器，这实在是有点可悲。所以，这里是一个简单的 HTTP 服务器。要想变得更复杂，就需要我们进入 Deno 中间件。

在例 8-8 中，你看到了 Deno 是如何允许你通过 HTTP 拉取版本模块以供使用。在这个例子中，我们从 Deno 标准库中拉出一个基本的 HTTP 服务器。

例 8-8. 在 Deno HTTP 服务器中使用 WebAssembly

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

准备好迎接快速的失望吧！就像我们没有权限从文件系统中读取的 TypeScript 代码一样，我们也不能在没有权限的情况下监听网络连接！

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

Tilman Roeder [^7] 创建了一个内存 SQLite WebAssembly 模块，并将其封装以便在 JavaScript 和 TypeScript 中使用，你可以在 [GitHub](https://github.com/dyedgreen/deno-sqlite) 上获取。关于它如何工作的细节还需要等待，但使用它是非常简单的，如例 8-9 所示。

例 8-9. 在 Deno HTTP 服务器中使用一个 WebAssembly SQLite 包装器

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

我们从创建数据库文件开始。我希望你的直觉告诉你，这需要另一个运行时权限，确实如此。之后，我们向数据库加载一些数据，并关闭连接。

一旦我们启动服务器，在收到一个合适的 HTTP 请求后，我们将再次打开数据库，运行一个查询，生成一个结果，然后关闭数据库。我并不是说这是高质量的生产代码，但是这段代码能在 Deno 中安全地运行，并且能在 Deno 支持的各种平台上运行，这是相当了不起的。尽管我们面对的是一个包装好的 C 库（即 SQLite3），但 WebAssembly 使代码可以移植，同时仍然具有相当高的性能。我希望用安全、快速、可移植的 WebAssembly 代码扩展服务器基础设施的想法更有意义。

下面的命令将以适当的权限启动服务器：

```bash
brian@tweezer ~/g/w/s/c/deno> deno run --allow-read --allow-write ↵
  --allow-net db-serve.ts
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

这一章所代表的脱离浏览器的巨大飞跃，仅仅是个开始。虽然我们放弃了在那种受限制的环境中运行的安全限制（除了类似于锁定的 Deno 实例），我们也放弃了浏览器的丰富功能。在任何一个现代的浏览器平台上，都有大量的功能可用于 JavaScript 环境。这包括 Java 脚本引擎、硬件加速的 2D/3D 图形和视频播放、声音、字体支持、提出网络请求的能力，等等。默认情况下，Node.js 和 Deno 都不提供浏览器的所有功能，尽管 Deno 正试图支持其中的大部分。这使得编写基于 WebAssembly 的应用程序在浏览器内部和外部都能工作变得更加困难。

WebAssembly 使代码可移植。我们需要另一种策略，通过为我们在现代计算平台上期望的功能提供一致的服务接口，使应用程序可移植。这就是为什么我对可以给你看的例子的种类有点谨慎。这个问题的真正解决方案将在第 11 章介绍。 在那之前，请耐心等待，但我们还有一堆问题要讨论的。

## 注释

[^1]: Motif 构建在 Xt Intrinsics 库和 X Window System 之上。
[^2]: 命令模式将执行代码的触发事件与实际代码分开，除此之外允许进行宏录制和回放。
[^3]: 一系列的 [重叠的安全控制](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) 组合可以帮助你防止意外的漏洞。
[^4]: [只分配给用户最低权限](https://en.wikipedia.org/wiki/Principle_of_least_privilege) 是这项技术的一部分。
[^5]: [Deno](https://deno.land/) 有很多优点。除了安全之外，还有很多值得喜欢的地方。
[^6]: [基于能力的安全系统](https://en.wikipedia.org/wiki/Capability-based_security) 一般要求行动者证明他们有一个不可磨灭的任务来进行一项行动。
