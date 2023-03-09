---
linktitle: 第 17 章：WebAssembly 和其他语言
summary: "这篇文章是《WebAssembly 权威指南》一书的第十七章，介绍了其他语言对 WebAssembly 的支持。"
weight: 18
icon: book-reader
icon_pack: fas
draft: false
title: WebAssembly 和其他语言
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

> 译者注：这篇文章是《WebAssembly 权威指南》一书的第十七章，介绍了其他语言对 WebAssembly 的支持。

本书已经来到了尾声。我们已经看到了 WebAssembly 大放异彩的用例、语言和平台集成、托管环境等。在这个激动人心的新平台上高效工作，开发人员有很多选择。还有一些特定的原因可以解释为什么某些语言及其相关的运行时可以很好地与 WebAssembly 配合使用，而其他语言则不能。缺乏垃圾收集和良好的线程支持是 MVP 的早期障碍之一，但两者都在支持的路上。

正如我们在[第 12 章](../extending-wasm-platform/)中看到的，这些约束已经越来越多地用于各种主机和运行时环境中。随着对几乎得到所有语言的更广泛支持，WebAssembly 的未来是光明的。因此，如果你最喜欢的语言还不支持，请保持信心。我认为它会在不久的将来得到支持。

也就是说，在本章中，我们讨论了在许多其他流行的、甚至是新兴的、但仍然有些小众的语言对 WebAssembly 的支持。我并不是说这些语言可以替代支持更高的语言，而是说对它们的支持让我们看到多语言 WebAssembly 更光明的未来。

## TinyGo

正如我在[第 10 章](../rust/)中提到的，我最初被 Go 语言作为一种替代 C 和 C++ 的系统语言所吸引，是因为它简洁的语法、与 Unix 和 Plan 9 的联系以及 Rob Pike 和 Ken Thompson 的参与。当它在 WebAssembly 支持方面落后于 Rust 时，我的注意力就减弱了，但我一直期待有一天能缩小这一差距。它们的差距越来越小了，多亏了一个叫做 [TinyGo](https://tinygo.org/) 的新变种。该项目不是特定于 WebAssembly 的，但它基于一个新的 Go 编译器，该编译器基于 LLVM 基础设施实现器构建，它将 WebAssembly 公开为后端。

从 TinyGo 的 [FAQ](https://tinygo.org/docs/concepts/faq/) 中我们看到它是一个基于标准库的解析器（因此可移植并且得到各种 WebAssembly 工具如 Emscripten 和 wasi-sdk 的良好支持）和 LLVM 的可重用优化支持。除其他事项外，FAQ 指出它包括编译器内部函数（帮助优化的规则）、内存分配器、调度程序、重新实现的通用包以及对字符串操作的支持。

TinyGo 的 “Tiny” 部分旨在针对传统 Go 编译器不支持的微控制器。对于没有 LLVM 分层结构的许多开发人员来说，在后端添加此支持会很麻烦。LLVM 改变了努力的水平，从而开辟了各种新的可能性。普通 Go 工具链的另一个方面是它生成的大型二进制文件也不适合嵌入式系统和微控制器。解决这些问题的组合恰好很好地支持了 Go-to-WebAssembly 路径，这可能会继续取得成果并使 Go 能够以这种方式使用。

鉴于 Rust 和 Go 在许多人的心目中处于同一领域，并且 Rust 也对具有基于 LLVM 的工具链的嵌入式系统感兴趣，FAQ 继续介绍 Go 作为一个选择，因为它确实具有相对较平缓的学习曲线。它还通过 goroutines 和 channel 以及丰富的标准库提供线程无关的并发支持。在 Rust 中，其中一些功能由依赖的 Cargo 包支持。他们承认 Rust 有其长处和优势，但更重要的是，市场上有足够的需求来支持这两种语言，因此付出的努力是值得的。

在图 17-1 中，我们在浏览器中看到了 TinyGo Playground。既然你了解了 WASI 和其他与 WebAssembly 运行时共享行为的方法，希望这个运行时 importObject 的先睹为快能引起你的共鸣。

![图17-1. 浏览器中的TinyGo Playground](../images/f17-1.png)

如果你克隆了 TinyGo 存储库，则有一些突出显示交互的示例，即使你不了解 Go，现在也应该对它的结构感到熟悉。

如果你按照[附录](../appendix/)中的详细信息安装了编译器，你应该能够运行这些示例。在例 17-1 中，你可以在 `examples/wasm/main` 中看到 `main.go` 文件。

例17-1. 基本的 TinyGo 例子

```go
package main

func main() {
  println("Hello world!" )
}
```

要运行这个例子，你必须执行以下内容。它建立了命名的例子（如 main），然后将必要的文件复制到一个 html 目录中。为了提供该目录的内容，你可以运行 Go HTTP 服务器：

```bash
brian@tweezer ~/g/t/s/e/wasm> make main
rm -rf ./html
mkdir ./html
cp ../../../targets/wasm_exec.js ./html/
tinygo build -o ./html/wasm.wasm -target wasm -no-debug ./main/main.go
cp ./main/index.html ./html/
brian@tweezer ~/g/t/s/e/wasm> go run server.go
2021/08/14 13:49:42 Serving ./html on http://localhost:8080
```

图 17-2 展示了这个例子的输出。

![图17-2. 浏览器中的 TinyGo 示例](../images/f17-2.png)

我不打算在这里重现这个文件，但是考虑到你在本书其他地方读到的内容，看一下 `wasm_exec.js` 文件可能会有兴趣。TinyGo 的作者，他们创建了一个通用 API，用于在浏览器、Node.js、Electron 应用程序和 Parcel 中连续调用 Go。你可以在图 17-1 中看到该文件的一个片段。

在例 17-2 中可以找到一个更有趣的 Go 示例。我们不仅看到了 Go 语言的更多应用，还有他们构建的与 JavaScript 环境交互的机制。

例 17-2. 一个更有趣的 Go 示例

```go
package main
import( 
  "strings" 
  "syscall/js" 
)

func splitter( this js.Value, args[] js.Value ) interface{}{
  values: = strings.Split( args[0].String(), "," )
  
  result: = make([] interface {}, 0 )
  for _, each : = range values {
		result = append( result, each )
	}
	return js.ValueOf( result )
}

func main()
{
	wait : = make( chan struct {}, 0 )
  js.Global().Set( "splitter", js.FuncOf( splitter ) ) 
  < -wait
}
```

`main()` 方法基于前面示例中表达的 `splitter()` 函数创建了一个全局 JavaScript 函数。运行下面的程序将调用编译器并将 JavaScript 文件复制到 html 目录中，以便程序运行。

```bash
brian@tweezer ~/g/t/s/e/wasm> make slices
rm -rf ./html
mkdir ./html
cp ../../../targets/wasm_exec.js ./html/
tinygo build -o ./html/wasm.wasm -target wasm -no-debug ./slices/wasm.go
cp ./slices/wasm.js ./html/
cp ./slices/index.html ./html/
```

复制的文件包括 `wasm_exec.js` 中的可重用 API，和以前一样。`index.html` 大部分是不显眼的，但我在例 17-3 下方展示了它，因此你可以看到 input 和 div 元素。

例17-3. Go 切片的简单 HTML 文件示例

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8"/>
    <title>Go WebAssembly</title>
    <meta name="viewport" content="width=device-width, initial-scale=1"/> 
    <script src="wasm_exec.js" defer></script>
    <script src="wasm.js" defer></script>
  </head>
  <body>
    <h1>WebAssembly</h1>
    <p>type values separated by comma, using WebAssembly:</p>
    <input type="text" id="a" value=""/>==<div id="b"></div>
  </body>
</html>
```

正如我所说的，这个 HTML 文件除了加载我提到的普通 Go API 和 wasm.js 中的特定应用的 JavaScript 之外，并没有太多的内容。如例 17-4 所示。

例17-4. Go 切片示例的特定应用 JavaScript

```javascript
'use strict';
const WASM_URL = 'wasm.wasm';
var wasm;
function update() {
  const value = document.getElementById("a").value;
  document.getElementById("b").innerHTML = JSON.stringify(window.splitter(value));
}
function init() {
  document.querySelector('#a').oninput = update;
  const go = new Go();
  if ('instantiateStreaming' in WebAssembly) {
    WebAssembly.instantiateStreaming(fetch(WASM_URL), go.importObject).then(function(obj) {
      wasm = obj.instance;
      go.run(wasm);
    })
  } else {
    fetch(WASM_URL).then(resp = >resp.arrayBuffer()).then(bytes = >WebAssembly.instantiate(bytes, go.importObject).then(function(obj) {
      wasm = obj.instance;
      go.run(wasm);
    }))
  }
}
init();
```

除了根据环境提供的内容选择流式或非流式方法实例化 WebAssembly 模块外，这段代码还建立了一个 `update()` 函数，当输入字段发生变化时调用该函数。该值被送入窗口实例上的全局 JavaScript 函数 `splitter()`，该函数由 Go main 方法添加。该字符串将按逗号进行拆分，然后通过 JavaScript 发送回 HTML 进行显示，如图 17-3 所示。

![图 17-3. 在浏览器中运行的 Go 切片示例](../images/f17-3.png)

显然，在 Go 中编写 WebAssembly 模块只是为了像这样拆分字符串是很愚蠢的，但这个演示旨在向你展示交互的机制。我认为我们还没有看到 Go 对 WebAssembly 支持的最终形式，但我很高兴 TinyGo 将这门语言带到了它现在的位置。

## Artichoke

很长一段时间以来，我一直是 Ruby 语言的粉丝。它具有简洁的语法和强大的元编程功能。很难描述为什么一种语言会与另一种语言产生共鸣，但 Ruby 的美丽一直让我着迷。尽管我很欣赏它，但除了偶尔的 Rails 项目外，我从未真正用它做过任何事情。我记得当 Rails 第一次引起开发者社区的注意时，每个人都非常兴奋。由于各种原因，虽然 Rails 是一个非常有成效的项目并且深受喜爱，但性能问题和支持另一个运行时的需要阻止了它的流行。Charles Nutter 和 [JRuby](https://www.jruby.org/) 社区已经完成了让 Ruby 在 JVM 上运行的工作，但我们现在看到另一个选择出现在 [Artichoke 项目](https://www.artichokeruby.org/)中。

Artichoke 是一种基于 Rust 的 Ruby 运行时，旨在与 Matz 的 [Ruby 解释器（MRI）](https://en.wikipedia.org/wiki/Ruby_MRI) 配合使用。现在还处于早期阶段，所以我不想在这个项目上花太多时间，但它似乎进展很快，他们正在寻找贡献者，所以我想提一下，你也许会感兴趣。我很乐意看到这个项目将 Ruby 更全面地引入 WebAssembly 环境，因为它还支持在沙盒环境中运行不受信任的代码。

我在[附录](../appendix/)中详细介绍了一些安装 Artichoke 的方法。包括 Artichoke Ruby 解释器和一个 irb[^1]的替代品，称为 airb。目前，最简单的实验这个 Ruby-to-WebAssembly 工具链的方法可能是通过 [Playground](https://artichoke.run/)，如图 17-4 所示。

![图17-4. 在浏览器中运行的 Artichoke Ruby](../images/f17-4.png)

与 TinyGo 一样，我不认为这是 Ruby 和 WebAssembly 的终点，但这足以让 Ruby 爱好者相信在不久的将来，他们将能够更充分地参与 WebAssembly 生态系统。

## Swfit

Swift 编程语言不断扩大的影响力让我感到惊讶。在 macOS 和 iOS 编程的世界中，它最初看起来像是 Objective-C 的替代品，现在已经开源，可用于服务器端开发，并且是 TensorFlow 机器学习的强大支持语言。将 Swift 归类为正式支持 WebAssembly 是不合适的，但是，正如你所看到的，它离我们不远了，我认为会很快在主要工具链中看到它。

它自然地过渡到 WebAssembly，部分原因是 Swift 基于 LLVM，如 Rust、clang、TinyGo 和我们讨论过的许多其他项目一样。除此之外，还有一个充满活力的社区有兴趣看到这两种技术变得更加直接兼容。

按照惯例，开始尝试 Swift 和 WebAssembly 交叉点的最简单方法是在浏览器中。浏览器 [SwiftWasm 网页](https://swiftwasm.org/)提供了这样的机会，如图 17-5 所示。

![图 17-5. 在浏览器中运行的 SwiftWasm](../images/f17-5.png)

不仅可以在浏览器中执行常规的 Swift 代码，通过 [Tokamak](https://github.com/TokamakUI/Tokamak) 等项目，也有越来越多的 SwiftUI 程序可以在浏览器中运行。图 17-6 显示了一个这样的例子。

![图 17-6. 在浏览器中运行的 SwiftUI 应用程序](../images/f17-6.png)

还有许多其他项目涉及 Swift 和 WebAssembly，但我还想重点介绍 Swift、Wasm 和 Algorithms 项目，请参见图 17-7。这代表了 Apple 在 [Swift Algorithms repo](https://github.com/apple/swift-algorithms) 中添加算法支持的交互式版本。这个开源算法包专注于从集合类生成序列、组合、交换等。

图 17-7 中显示的页面允许用户交互式地试验这些算法的输入和配置，这是了解它们如何工作的好方法。通过能够直接使用 Swift 代码，开发人员可以准确地看到它在不同情况下的行为，这比通过用 JavaScript 重写它们来近似地使用库更有用。

![图 17-7. Swift、Wasm 和算法作为交互式文档](../images/f17-7.png)

虽然基于浏览器的演示很有趣且易于展示，但我们更感兴趣的是尝试更传统的编程。如果你按照[附录](../appendix/)中的描述安装了 SwiftWasm 工具链，你应该能够在 macOS 或 Linux 上运行以下命令以验证你是否安装了支持 WebAssembly 的 Swift 编译器版本：

```bash
brian@tweezer ~> swift --version
SwiftWasm Swift version 5.3 (swiftlang-5.3.1) 
Target: x86_64-apple-darwin20.6.0
```

例17-5. Swift 的 "Hello, world!"

```bash
print("Hello, world!")
```

我们可以生成程序的 WASI 目标版本，如下所示，显然可以在 Wasmer 和 Wasmtime 中运行它，这突出表明支持已经很好。

```bash
brian@tweezer ~/s/swift> swiftc -target wasm32-unknown-wasi hello.swift -o hello.wasm
brian@tweezer ~/s/swift> wasmer hello.wasm 
Hello, world!
brian@tweezer ~/s/swift> wasmtime hello.wasm 
Hello, world!
```

目前，这种整合的可能性是有限的。由于 WebAssembly 的标准线程支持仍在发展中，因此 Swift 标准库所依赖的许多功能尚不可用。希望如你所见，我们正在努力为浏览器内部和外部的 WebAssembly 提供适当的 Swift 支持。

## Java

Java 会出现在这份不受支持的语言和运行时列表中，这似乎是不可思议的，但唉，这是事实。Java 对垃圾回收和线程的依赖是造成这种情况的最大原因之一。随着这些建议的推进，事情显然会发生变化，但现在我们只有有限的选择。

第一个选项允许我们使用 Wasmer 在 Java 中嵌入 WebAssembly，就像我们在其他语言中看到的那样。这显然与编译 Java 以在 WebAssembly 平台上运行无关，但这是一个开始。它依赖于 Wasmer 库和  Java 本机接口（JNI）的加载，但通常足够简单。其基本结构如例 17-6 所示。

例 17-6. 我们的 howOld 函数是通过 Wasmer 从 Java 调用的

```java
import org.wasmer.Instance;

import java.io.IOException; 
import java.nio.file.Files;
import java.nio.file.Paths;

class HowOldExample {
  public static void main(String[] args) throws IOException {
    byte[] bytes = Files.readAllBytes(Paths.get("howold.wasm")); 
    Instance instance = new Instance(bytes);
    Function howOld = instance.exports.getFunction("howOld");
    Integer result = (Integer) howOld.apply(2021, 2000) [0];
    
    System.out.println("Result: " + result);
    instance.close();
  }
}
```

到目前为止，就 Wasmer API 而言，与我们所看到的没有实质性差异。我们实例化 WebAssembly 模块的一个实例，检索一个 Function 实例，并使用我们的参数调用它。在 [wasmer-java/examples](https://github.com/wasmerio/wasmer-java) 目录中，有更多关于如何与导出的 Memory 实例进行交互的演示。

字节码联盟目前不维护用于与 Wasmtime 运行时交互的 Java API，但是 [Yuto Kawamura](https://github.com/kawamuray/wasmtime-java) 和 [Benjamin Fry](https://github.com/bluejekyll/wasmtime-java) 在 GitHub 上提供了社区支持的版本。它们的行为很像我们在前几章中看到的 Rust 和 .NET 中的 Wasmtime API。

另一个类似的选择是使用 GraalVM，这是一个高性能的 JDK 发行版，它为 Java 世界带来了对多语言开发和近乎本机性能的支持。通过额外的支持，可以通过 LLVM JIT 引擎运行 Python、Ruby、R、JavaScript、WebAssembly 和基于 LLVM 的语言。你不仅可以编写这些语言的代码，还可以使它们互操作。GraalVM 社区有一个类似的 API，用于实例化 WebAssembly 模块并从 Java 调用它们，这在本质上与我们刚才所做的相同。我承认这是朝着更全面地支持 Java 和 WebAssembly 迈出的一步，但鉴于多语言互操作性，这仍然不是一个完整的解决方案。在 WebAssembly 生态系统中有适当的、标准化的垃圾收集和线程支持之前，以这种方式运行 Java 并不容易。

虽然 Java 还不是一个完全支持 WebAssembly 的语言，但这并不意味着没有采用策略。Leaning Technologies 有一个名为 [CheerpJ](https://leaningtech.com/cheerpj/) 的商业产品，它取得了一些令人瞩目的成果。该解决方案结合了提前编译、WebAssembly 和 JavaScript 运行时，以及动态编译的能力。我将让你自己研究产品，但是你可以看到在浏览器中运行 SwingSet3 演示，请参见图 17-8。这不会代表 Java 和 WebAssembly 的最终集成策略，但如果你需要在浏览器中支持遗留系统，这可能是一个选择。

![图 17-8. 通过 CheerpJ 在浏览器中运行的 SwingSet3 演示](../images/f17-8.png)

## Kotlin

作为一种语言和运行时，Kotlin 可以做的事情太多了，感觉它同时属于多个类别。可用于 JVM 上的目标应用程序，可转换为 JavaScript 在浏览器中运行，具有脚本身份，可通过 LLVM 编译器在 iOS 和 Android 上生成原生应用程序。

不用说，它很受欢迎。不同的组织出于不同的目的使用它，但它结合了许多不同的语言特性来创建一种简洁安全的工业级面向对象编程语言。它已被采纳为开发 Android 应用程序的首选语言，并且是 Spring 和 Gradle 等超级明星开源项目中完全支持的语言。

在此过程中，其开发人员尝试通过 LLVM 编译器生成 WebAssembly。截至目前，他们正在放弃这种方法以获得更全面的支持，直接处理 Kotlin-to-WebAssembly 后端。这绝对是一项正在进行的工作，因为他们正在组建一个新团队来管理这个问题，并试图在 2021 年 5 月为其配备人员。

如果需要，你仍然可以尝试使用 kotlinc-native wasm32 后端，但这不是一个长期策略。因此，虽然这些语言之间的配对程序有很大的好处，但我们现在必须采取观望态度。

## Zig

如果你说自己从来没听说过 Zig，我也不会感到惊讶。我最喜欢的轶事是 Jakub Konka，一位在软件和算法以及编译器理论方面备受尊敬的研究人员，在等待 Rust 编译时学习了 Zig[^3]。这是一个有趣的故事，在取笑 Rust 编译器运行缓慢的同时，也让你了解 Zig 带来的好处 [^4]。

首先，就像上面的故事所示，Zig 是一种简单的语言。该[站点](https://ziglang.org/)建议你花时间调试应用程序，而不是学习编程语言。复杂的编程语言很难学习和有效使用，除非你经过多年的练习才能掌握。Zig 没有隐藏的控制流，没有隐藏的内存分配，没有预处理器和宏系统。其完整的语法体现在一个 500 行的解析表达式语法文件中。

功能设计美学反映在主文档网页上。正是这样：一个页面。这是一个很长的、易于搜索的文件，还具有强大的离线功能。

Zig 是一种快速、可移植的语言，支持多平台交叉编译，具有广泛的安全和优化选项，直接支持 SIMD 向量，等等。

我希望在这里强调的不是你需要学习 Zig，尽管它在我需要掌握的新语言列表中名列前茅。相反，我希望你更多地考虑这样一个事实，即语言带来某些价值，而运行时带来其他种类的价值。我们想象了书中的各种用例，从重用遗留库到编写安全的现代代码，通过将它们转化为编译时错误来消除一些运行时错误。在选择一种语言来表达我们的应用程序和系统功能时，我们有多种选择。并且，我们不必担心我们的小众语言会因为缺乏良好支持的运行时平台而永远不会被使用。正如我之前指出的，我认为是 Ruby 运行时给开发人员对 Ruby 生产力的热爱蒙上了一层阴影。这些类型的选项似乎不像以前那样令人生畏。

通过各种 API 风格，我们可以将用一种语言编写的客户端连接到用另一种语言编写的服务。通过在响应中采用松散耦合（例如超媒体、JSON-LD 等），我们可以自由选择，而在许多情况下不会影响任何一个。像微服务这样的架构方法允许在技术选择上进行更分散的管理，只要它不会给我们的操作运行时和部署策略带来负担。随着 WebAssembly 模块在不久的将来作为 ES6 模块正式可用，人们对软件工件使用的语言的关注就会减少。

我认为重要的是要强调 WebAssembly 有助于管理其中的许多权衡，将它们转变为非权衡。当你可以自由选择自己喜欢的语言，将其与问题相匹配，利用现有的开发培训和经验，或者允许长期的业务价值捕获和重用时，那么我们过去面临的许多重大问题都将成为将来消失。

这并不是说支持多个语言环境没有问题。你希望对技术选择进行一定程度的监督，以避免错误的开发人员将他们奇怪的偏好强加给他们的同行然后退出。但是，如果他们这样做，你可以自由地继续使用他们的代码，只要它们有效，直到你有机会换掉它。

无论是避免遗留技术的锁定、重用不足，还是现代化的障碍，WebAssembly 都准备好在技术基础设施中广泛而深入地增加商业价值。如果这意味着使用 C# 和 .NET 开发业务应用程序，或者使用 Zig 等语言编写复杂的现代算法，那么所有这些用例都摆在桌面上。这一点值得不止一次强调，因为它是本书的核心。

虽然我们当然不会在我们老生常谈的示例中激发 Zig 的优势，但它至少会强调在你使用 Zig 遇到问题时自己进行实验的机制。你可以在以下文件中找到我们的 `howOld()` 函数的 Zig 版本。

例 17-7 看起来和我们之前看到的没有什么不同，但是用一个整数减去另一个整数到底有多难？

例17-7. 我们用 Zig 编写的 howOld 函数

```c
export fn howOld(now: i32, then: i32) i32 {
  return now - then;
}
```

把我们的例子构建成一个独立的 WebAssembly模块（相对于，比如说，一个以 WASI 为目标的模块），看起来如下。不要眨眼，否则你可能会错过编译的步骤。

```bash
brian@tweezer ~/g/w/c/zig> zig build-lib howOld.zig -target wasm32-freestanding -dynamic
```

我们可以用多种方式调用我们的新模块，让我们使用 Node.js 的代码，如例 17-8 所示。

例17-8. 从 Node.js 调用我们的 Zig 模块

```javascript
const fs = require('fs');
const source = fs.readFileSync("./howOld.wasm");
const typedArray = new Uint8Array(source);

WebAssembly.instantiate（typedArray）.then（result => {
  const howOld = result.instance.exports.howOld;
  let age = howOld(2021, 2000);
  console.log('You are: ' + age);
});
```

运行这个程序可以得到以下结果：

```bash
brian@tweezer ~/g/w/c/zig> node main.js
You are: 21
```

来自 Zig 网站的例 17-9 更有趣，其中突出显示了其对 WASI 的支持。在此示例中，为了演示基于功能的安全性和对命令行和文件系统的受控访问，我们通过打印出代码可以在运行时作为预打开列表访问的目录来实现。

例 17-9. 以 WASI 为目标的 Zig 应用程序，使用控制台和潜在的文件系统访问

```rust
const std = @import("std");
const PreopenList = std.fs.wasi.PreopenList;
pub fn main() !void {
  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  const gpa = &general_purpose_allocator.allocator;
  var preopens = PreopenList.init(gpa);
  defer preopens.deinit();
  try preopens.populate();
  for (preopens.asSlice()) |preopen, i| {
    std.debug.print("{}: {}\n", .{ i, preopen });
  }
}
```

我不打算深入探讨 Zig 的细节，但基本上我们只是打印出我们在托管环境允许的情况下具有预打开权限的目录。构建此应用程序需要不同的后端目标。我们将生成一个基于 WASI 的模块，而不是“独立的” WebAssembly 模块。

下一个示例中的第一行显然构建了 WASI 模块。第二行在 Wasmtime 中执行它而不给它任何目录访问权限。因此，没有输出。第三行重新执行 Wasmtime，赋予它对当前目录的权限，应用程序现在可以确认这些权限。

```bash
brian@tweezer ~/g/w/c/zig> zig build-exe preopens.zig -target wasm32-wasi
brian@tweezer ~/g/w/c/zig> wasmtime preopens.wasm brian@tweezer ~/g/w/c/zig> wasmtime --dir=. preopens.wasm 
0: Preopen{ .fd = 3, .type = PreopenType{ .Dir = '@".}}
```

我不是想给你推销 Zig[^5]。相反，我试图强调这本书的一个主题。WebAssembly 是一项非常有价值的技术。能够选择一种语言是因为它是遗留的因此可重用，或者因为它是新的和令人兴奋的并增加了新的好处，同时能够针对我们讨论过的所有运行时是相当大的成就。

如果你想从 Zig 中获得更多乐趣，请查[俄罗斯方块](https://raulgrell.github.io/tetris/)的实现，用 Zig 编写，并使用 WebGL。

## Grain

我将介绍的最后一种语言不是最后一种能够生成 WebAssembly 的语言。还有很多其他的语言我们还没有机会去了解。相反，我选择了一种与我们讨论过的其他语言不同的语言，因为它旨在生成 WebAssembly，同时也为了普及令人兴奋和奇特的新学术语言功能。

[Grain 语言](https://grain-lang.org/)是一种年轻但很有前途的语言，它结合了功能性、强类型和语言可访问性的优点。许多函数式编程语言非常强大，但它们也可能看起来很神秘，不适合一般的开发人员。很高兴看到这些功能出现在对开发人员友好的语言中，例如 Java（在 JDK 8 之后）、Rust 和现在的 Grain。尽管它具有函数式风格，但它很纯粹，并且支持可变变量。平衡的类型推断和丰富的复合结构标准库、对 WebAssembly 原语的直接支持以及 Rust 的模式匹配功能是它的主要吸引力。

它的网站上有关于使用 Grain 扩展设置 VS Code 以获得全面积极的开发体验的文档。我在这里的目的不是教你 Grain。这要交给在线资源和 Grain 社区。相反，我只想说，语言创新不是凭空发生的。其他新的编程语言完全有可能在设计时就考虑到了 WebAssembly。有了一条易于采用的持续创新之路，这再次提醒我们，我们不是在处理过去的技术选择。

我们可以构建一个未来，语言和运行时的选择、硬件平台和 API 风格、数据模型和存储系统的选择可以统一为技术和商业价值的综合愿景。

但是，我的朋友们，这可能是我的下一本书。

## 然后呢？

在本书中，我们涵盖了大量内容，从 MVP 的基础知识及其底层细节，到从浏览器到基于 WASI 的环境的转换。我们已经看到编译为 WebAssembly 的非常大、复杂的软件项目，有时使用 shim 和快捷方式来处理平台限制。我们还看到了新提议的积极步伐，这些提议试图将 WebAssembly 扩展到我们复杂、异构、不断变化的现代软件世界的每个角落。

现在我们已经完成了对 WebAssembly 支持的快速了解，并把它添加到我们最喜欢的编程语言中。它也被令人兴奋的新语言所采用和驱动。似乎所有这些语言都想编译出 WebAssembly 的输出，以便在未来占据一席之地，这似乎已经成为一种期望。

到目前为止，已经意识到了一些惰性，但现在越来越多的人认为 WebAssembly 将对使我们的软件安全、快速和便携产生深远影响。如果有限制和遗漏的地方，我们一般会通过扩展平台和开发一个工具链来使我们免受烦人的细节问题苦恼，可以快速克服和解决这些问题。

2017 年初，我开始在 [No Fluff Just Stuff 巡讲](https://nofluffjuststuff.com/)上从专业的角度开始讲 WebAssembly，就在 MVP 敲定之后，浏览器支持变得无处不在。这显然是在大多数人准备好利用这个新兴平台之前，但我想开始规划即将发生的事情，以便软件开发人员做好准备。

我对这个平台为我们准备的东西感到非常兴奋； 我的兴趣只增不减。当你评估我们在本书中介绍的各种工具、技术和用例时，我希望你至少已经抓住了一些兴奋点。事情每周都会变化，但我希望我写的大部分内容都是稳定的，值得你花时间。

感谢你的兴趣，我迫不及待地想看看你用所学知识做了些什么。

## 注释

[^1]: [irb](https://github.com/ruby/irb) 是一个交互式的 Ruby REPL 环境。
[^2]: NBC 正在保护该视频，但你可以在 [YouTube](https://www.youtube.com/watch?v=wPO8PqHGWFU&ab_channel=TheNotReadyForPrimeTimePlayers-Topic) 上收听该短剧。

[^3]: [Jakub 的手稿](http://www.jakubkonka.com/)已经遍布了 WASI、witx、Wasmtime 等。
[^4]:虽然公平地说，这是因为 Rust 做了很多事情，而且随着时间的推移，已经变得更好了。
[^5]: 尽管如果我已经激起了你的兴趣。
