---
linktitle: 第 17 章：WebAssembly 和其他语言
summary: WebAssembly 和其他语言。
weight: 18
icon: book-reader
icon_pack: fas
draft: true
title: WebAssembly 和其他语言。
date: '2023-01-26T00:00:00+08:00'
type: book # Do not modify
---

> 如果你用一个人听得懂的语言和他说话，那就会进入他的大脑。如果你用他自己的语言与他交谈，那就会进入他的内心。
> -尼尔森-曼德拉

我们的故事就要结束了，至少现在是这样。我们已经看到了广泛的使用案例，语言和平台的整合，托管环境，以及更多WebAssembly已经闪耀的地方。为了在这个令人振奋的新平台上提高生产力和效率，开发人员需要做出相当多的选择。还有一些具体的原因是，一些语言和它们相关的运行时与WebAssembly配合得很好，而另一些则不然。缺乏垃圾收集和良好的线程支持是MVP早期就存在的障碍之一，但这两者都在解决的路上。
正如我们在 Chapter 第十二章我们看到，这些和其他的限制已经被很好地理解，并且在各种主机和运行时环境中越来越多地被使用。未来是光明的，可以更广泛地支持几乎所有开发者可能想要使用的语言。所以，如果你喜欢的语言还没有被支持，请保持你的信心。我认为在不久之后，它就会被支持。
也就是说，在本章中，我们将讨论许多其他流行的，甚至是新兴的，但仍然有点小众的语言的渐进式努力，部分解决方案，以及正在进行的工作。我并不是说这些语言可以取代那些支持率较高的语言，而是说它们的裂痕可以让我们看到更光明的多语言WebAssembly的未来。正如曼德拉在开篇所言，我们可以理解许多语言，但我们喜欢使用自己的语言。

小小棋
正如我在 第十章我最初被Go语言所吸引，将其作为取代C和C++的系统语言，因为它的语法简洁，与Unix和Plan 9的关系，以及Rob Pike和Ken Thompson的参与。当它在对WebA-sembly的支持上落后于Rust时，我的注意力就减弱了，但我一直期待着有一天能缩小这一差距。我们还没有到那一步，但我们正在逐渐接近，这要归功于一个新的变体，叫做 TinyGo.这个项目不是专门针对WebAssembly的，但它是基于 ，一个建立在LLVM基础架构上的新Go编译器，将WebAssembly作为后端开放。
从 TinyGo的常见问题我们看到，它是一个基于标准库的分析器（因此可以移植，并得到各种WebAssembly工具的良好支持，如Emscripten和wasi-sdk）和LLVM的可重用优化支持。除此之外，FAQ还指出，它还包括编译器的内在因素（协助优化的规则）、内存分配器、调度器、重新实现的通用包，以及对字符串操作的支持。
TinyGo的 "Tiny "部分是希望针对传统Go编译器不支持的微控制器。如果没有LLVM的分层结构，在后端添加这种支持对许多开发者来说是麻烦的。LLVM改变了努力的程度，因此开启了各种新的可能性。普通Go工具链的另一个方面是，它产生的大型二进制文件也不适合于嵌入式系统和微控制器。解决这些问题的组合恰好能很好地支持Go- to-WebAssembly的路径，这可能会继续取得成果，并使Go能以这种方式被使用。
鉴于Rust和Go在很多人的脑海中处于同一空间，而且Rust也对基于LLVM的工具链的嵌入式系统感兴趣，FAQ继续介绍了Go作为一种选择，因为它的学习曲线确实比较浅。它还通过gor-outines和channel提供了独立于线程实现的并发支持，以及丰富的标准库。在Rust中，其中一些功能是由依赖性的Cargo包支持的。他们承认Rust有自己的长处和优势，但更重要的一点是，在思想市场上有足够的需求来支持这两种语言，所以这种努力是值得的。
在 图 17-1中，我们看到浏览器中的 TinyGo Playground。希望对运行时importObject的偷窥能引起你的共鸣，现在你已经了解了WASI和其他与WebAssembly运行时共享行为的方法。


图17-1.浏览器中的TinyGo游乐场
如果你克隆了 TinyGo  repo中，有一些例子强调了交互，即使你不懂围棋，现在也应该对其结构感到熟悉。
如果你按照附录中的详细说明安装了编译器 附录中详细说明的那样安装了编译器，你就可以运行这些例子了。中所详述的，你就可以运行这些例子了。在 例 17-1中，你可以看到来自 examples/wasm/main 的 main.go 文件。

例17-1.基本的TinyGo例子
包主

func main() { println("Hello world!" )
}

要运行这个例子，你必须执行以下内容。它建立了命名的例子（如main），然后将必要的文件复制到一个html目录中。为了提供该目录的内容，你可以运行Go HTTP服务器。
brian@tweezer ~/g/t/s/e/wasm> make main
rm -rf ./html mkdir ./html
cp .../.../.../targets/wasm_exec.js ./html/。
tinygo build -o ./html/wasm.wasm -target wasm -no-debug ./main/main.go cp ./main/index.html ./html/
brian@tweezer ~/g/t/s/e/wasm> go run server.go
2021/08/14 13:49:42 服务于./html on http://localhost:8080

图 17-2 展示了这个例子中不令人惊讶的输出。

图17-2.浏览器中的TinyGo主要例子
我不打算在这里复制这个文件，但是考虑到你在本书其他地方看到的内容，浏览一下wasm_exec.js文件可能会让你感兴趣。TinyGo的作者 ，他们创建了一个通用的API，用于在浏览器、Node.js、Electron应用程序和Parcel中持续调用Go。你在图17-1中看到了这个文件的一个片段。 图 17-1.
一个更有趣的围棋例子可以在 例17-2.我们不仅看到了更多的Go语言的应用，还看到了他们所建立的与JavaScript环境交互的机制。

例17-2.更有趣的围棋例子
包主

输入 ( "strings" "syscall/js"
)

func splitter(this js.Value, args []js.Value) interface{} { values := strings.Split(args[0].String(), " ," )

结果 := make([]interface{}, 0)
for _, each := range values { result = append(result, each)
}

返回 js.ValueOf(result)
}

func main() {

wait := make(chan struct{}, 0) js.Global().Set("splitter", js.FuncOf(splitter))
<-等待
}
main()方法根据前面例子中表达的splitter()函数创建了一个全局的JavaScript函数。运行下面的程序会调用com- piler，并将JavaScript文件复制到html目录中，这样这个程序就会运行。
brian@tweezer ~/g/t/s/e/wasm> make slices
rm -rf ./html mkdir ./html
cp .../.../.../targets/wasm_exec.js ./html/。
tinygo build -o ./html/wasm.wasm -target wasm -no-debug ./slices/wasm.go cp ./slices/wasm.js ./html/
cp ./slices/index.html ./html/。
复制的文件包括wasm_exec.js中可重复使用的API，和以前一样。index.html大多不引人注目，但我在下面展示了它 例 17-3 以便你能看到输入和div元素。

例17-3.围棋片的简单HTML文件示例
<！DOCTYPE html>

<html>
<head>
<meta charset="utf-8"/>
<title>Go WebAssembly</title>。
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<script src="wasm_exec.js" defer></script>。
<script src="wasm.js" defer></script>。
</head>
<body>
<h1>WebAssembly</h1>。
<p>类型值由逗号分隔，使用WebAssembly：</p>。
<input type="text" id="a" value=""/>==<div id="b"></div>
</body>
</html>

正如我所说的，这个HTML文件除了加载我提到的普通Go API和wasm.js中的特定应用的JavaScript之外，并没有太多的内容。这个文件显示在 例 17-4.

例17-4.Go片断示例的特定应用JavaScript
'使用严格'。

const WASM_URL = 'wasm.wasm';

var wasm;

函数 update() {
const value = document.getElementById("a").value; document.getElementById("b").innerHTML
= JSON.stringify(window.splitter(value))。
}

function init() { document.querySelector('#a').oninput = update;

const go = new Go();
如果（'instantiateStreaming' in WebAssembly）{ WebAssembly.instantiateStreaming(fetch(WASM_URL),
go.importObject).then(function (obj) { wasm = obj.instance;
go.run(wasm)。
})
} else { fetch(WASM_URL).then(resports =>)
resp.arrayBuffer()
).then(bytes =>
WebAssembly.instantiate(bytes, go.importObject).then(function (obj) { wasm = obj.instance;
go.run(wasm)。
})
)
}
}

init()。

除了根据环境提供的情况选择实例化WebAs- sembly模块的流式或非流式方法外，这段代码还建立了一个update()函数，在输入字段称为a的变化时调用。该值被送入窗口实例上的全局JavaScript函数splitter()，该函数是由Go主方法添加的。这个字符串将在逗号分隔的边界上被分割，然后通过JavaScript送回HTML中显示，如图所示 图 17-3.


图17-3.在浏览器中运行的Go切片实例
显然，在Go中写一个WebAssembly模块只是为了像这样分割字符串是很愚蠢的，但这个演示是想向你展示互动的机制。我认为我们还没有看到Go对WebAssembly的最终支持形式，但我很高兴TinyGo能把这种语言带到现在。
洋蓟
长期以来，我一直是Ruby语言的粉丝。它有一个干净的语法和强大的元编程能力。很难描述为什么一种语言会与另一种语言产生共鸣，但Ruby的美感一直吸引着我。尽管有这种欣赏，但除了偶尔的Rails项目外，我从未真正用它做过什么。我记得当Rails第一次引起开发者社区的注意时，每个人都感到很兴奋。由于各种原因，尽管Rails是一个非常有成效的项目，而且深受人们的喜爱，但性能问题和支持另一个运行时的需要阻碍了它对世界的统治。Charles Nutter和 JRuby社区 已经完成了让Ruby在JVM上运行的工作，但我们现在看到另一种选择出现在了 Artichoke 项目.
Artichoke是一个基于Rust的Ruby运行环境，被设计为与Matz的 红宝石解释器（MRI）.现在是早期阶段，所以我不想在这个项目上花太多时间，但它似乎进展很快，而且他们正在寻找贡献者，所以我想提及它，以防你感兴趣。我很希望看到这个项目能发展成一个让Ruby更充分地进入WebAssembly环境的全速方式，因为它也支持在沙盒环境中运行不受信任的代码。
我已经在附录中详细介绍了一些安装Artichoke的方法。 附录.这包括Artichoke Ruby解释器和一个irb1的替代品，称为airb。目前，最简单的


1基金会 irbirb 是一个交互式的Ruby REPL环境。

洋蓟 | 287

实验这个Ruby-to-WebAssembly工具链的方法可能是通过 园地，可以看到 图 17-4.

图17-4.在浏览器中运行的Artichoke Ruby
和TinyGo一样，我不认为这是Ruby和WebAssembly的结局，但它足够真实，它应该给Ruby爱好者以信心，在不久的将来的某个时刻，他们将能够更充分地参与WebAssembly的生态系统。
迅捷
Swift编程语言不断给我带来惊喜，它的影响越来越广。最初在macOS和iOS编程领域，它似乎是Objective-C的一个很好的现代替代品，现在已经扩展到开源，可用于服务器端开发，并且是TensorFlow领域机器学习的一个很好的支持语言。把Swift归类为正式支持WebAssembly是不合适的，但是，正如你所看到的，它已经不远了，我认为我们不久就会在主要工具链中看到它。
它之所以能自然地过渡到WebAssembly，部分原因是Swift是基于LLVM的，就像我们讨论过的Rust、clang、TinyGo和许多其他项目。除此之外，还有一个充满活力的社区，他们有兴趣看到这两种技术变得更加直接兼容。

按照惯例，在Swift和WebAssembly的交汇处开始玩耍的最简单方法是在浏览器中。浏览器 SwiftWasm网页 就提供了这样一个机会，如 图  17-5.

图 17-5.在浏览器中运行的SwiftWasm
不仅可以在浏览器中执行常规的Swift代码，通过诸如 等项目，不仅可以在浏览器中执行常规的 Swift 代码。等项目，而且还可以在浏览器中运行越来越多的 SwiftUI 程序。这方面的一个例子显示在 图  17-6.


图 17-6.在浏览器中运行的 SwiftUI 应用程序
还有许多其他涉及Swift和WebAssembly的项目，但我还想强调的是Swift、Wasm和Algorithms项目，见 图17-7.这代表了苹果公司在Swift Algorithms repo中增加了对算法的支持的互动版本。 Swift Algorithms repo.这个开源的算法包专注于从集合类中生成序列、组合、互换等。
中所示的页面 图17-7允许用户交互式地试验这些算法的输入和配置，这是学习它们如何工作的一个好方法。通过能够直接使用Swift代码，开发者可以准确地看到它在不同情况下的表现，这比通过在JavaScript中重写库来近似地使用它们更有用。


图17-7.作为交互式文档的Swift、Wasm和Algorithms
虽然基于浏览器的演示很有趣，也很容易炫耀，但我们更有兴趣尝试一下更传统的编程。如果你安装了SwiftWasm 工具链，如附录中描述的 附录你应该能够在 macOS 或 Linux 上运行以下程序，以验证你是否安装了 WebAssembly-aware 版本的 Swift 编译器。
brian@tweezer ~> swift --version
SwiftWasm Swift 5.3版本（swiftlang-5.3.1） 目标：x86_64-apple-darwin20.6.0
在 例 17-5中，我们有一个用Swift表达的常规介绍性程序。

例17-5。"你好，世界！"在Swift中
print("Hello, world!")

我们可以生成一个WASI目标版本的程序，如下所示，并明显地在Wasmer和Wasmtime中运行它，这突出表明支持已经很好。
brian@tweezer ~/s/swift> swiftc -target wasm32-unknown-wasi hello.swift ↵
-o hello.wasm
brian@tweezer ~/s/swift> wasmer hello.wasm
你好，世界!
brian@tweezer ~/s/swift> wasmtime hello.wasm
你好，世界!
目前，这种整合的可能性是有限制的。由于WebAssembly的标准线程支持仍然是一个移动的目标，所以Swift标准库所依赖的许多功能还不能使用。希望- 你可以看到，我们正在努力为WebAssembly提供适当的Swift支持，无论是在浏览器内部还是外部。
爪哇
似乎难以想象Java会出现在这个不支持的语言和运行时间的名单上，但可惜的是，这是事实。Java对垃圾收集和线程的依赖是造成这种情况的最大原因之一。随着这些建议的推进，事情显然会发生变化，但现在我们只有有限的选择。
第一个选项允许我们用Wasmer将WebAssembly嵌入到Java中，就像我们看到的其他语言一样。这显然与编译Java以在WebAssembly平台上运行 ，但这是一个开始。它依赖于Wasmer库和Java本地接口（JNI）的加载，但总体上是足够直接的。其基本结构见于 例 17-6.

例17-6.我们的howOld函数正在通过Wasmer从Java中调用
输入org.wasmer.Instance。

import java.io.IOException; import java.nio.file.Files; import java.nio.file.Paths。

class HowOldExample {
public static void main(String[] args) throws IOException { byte[] bytes = Files.readAllBytes(Paths.get("howold.wasm")); Instance instance = new Instance(bytes);

Function howOld = instance.exports.getFunction("howOld"); Integer result = (Integer) howOld.apply(2021, 2000) [0];

System.out.println("Result: " + result); instance.close()。

}
}
到目前为止，在Wasmer API方面，与我们所看到的没有什么实质性的区别。我们实例化一个WebAssembly模块的实例，检索一个 Function实例，然后用我们的参数调用它。在 Wasmer-java/examples目录中中，有更多关于如何与导出的Memory实例交互的演示。
字节码联盟目前没有维护与Wasmtime运行时交互的Java API，但在Git-Hub上有社区支持的版本，可从以下网站获取 Yuto Kawamura 和 Benjamin Fry.它们的行为很像我们在前几章看到的Rust和.NET中的Wasmtime APIs。
另一个类似的选择是使用GraalVM，这是一个高性能的JDK发行版，为Java世界提供了对多语言开发和接近原生性能的支持。有了额外的支持，就可以通过LLVM JIT引擎运行Python、Ruby、R、JavaScript、WebAssembly和基于LLVM的语言。不仅可以编写这些语言，而且还可以让它们互操作。GraalVM社区有一个类似的API，用于实例化WebAssembly模块并从Java中调用它们，这与我们刚才所做的有本质上的等同。考虑到多语言的互操作性，我承认这是向更全面地支持Java和WebAssembly迈进了一步，但它仍然不是一个完整的解决方案。在WebAs- sembly生态系统中有适当的、标准化的垃圾收集和线程支持之前，以这种方式运行Java是不容易的。
一旦这种情况发生，并且我们看到WebAssembly运行时从性能和优化的角度有了更多的改进，那么我们将开始看到企业质疑在生产中使用JVM和WebAssembly引擎的必要性。Java本身不会消失，但我可以看到，在未来，人们对混合软件的单一运行时间没有意见，无论它是使用GraalVM还是WebAssembly引擎。
虽然Java还不是一种完全支持的语言，但这并不意味着没有一个走向采用的策略- egy。Leaning Technologies公司有一个商业产品，叫做 CheerpJ的商业产品，取得了一些令人印象深刻的成果。该解决方案结合了超前编译、WebAssembly和JavaScript运行时，以及在飞行中进行动态编译的能力。我将让你自己去调查它的产品，但你可以看到在浏览器中运行SwingSet3演示的显著成就，见 图17-8.这不会代表来自Java和WebAssembly的最终整合策略，但如果你现在有需要在 浏览器中支持遗留系统，这可能是一个选择。


图17-8.通过CheerpJ在浏览器中运行的SwingSet3演示
洛克特林 (Kotlin)
Kotlin让我想起了《周六夜现场》中Shimmer的老式广告模仿，Shimmer是地板蜡和甜点配料的组合。2   作为一种语言和一个运行时，它有很多东西可以做，感觉它同时属于多个类别。它可以用于在JVM上的目标应用程序，它可以转换为JavaScript在浏览器中运行，它有一个脚本方面的身份，并且它可以通过LLVM编译器在iOS和Android上生成本地应用程序。
毋庸置疑的是，它很受欢迎。不同的组织出于不同的目的使用它，但它结合了许多不同的语言特征，创造了一个简明和安全的语言。



2NBC正在保护该视频，但你可以在YouTube上收听该短剧 在 YouTube.

工业强度的面向对象编程语言。它已被采纳为开发Android应用程序的首选语言，也是Spring和Gradle等超级明星开源项目的完全支持语言。
在这一过程中，它的开发者尝试了通过LLVM编译器生成WebAssembly。截至目前，他们正在放弃这种方法，以获得更全面的支持，直接处理Kotlin到WebAssembly的后端。这绝对是一项正在进行的工作，因为他们正在组建一个新的团队来管理这个问题，并试图在2021年5月为其配备人员。
如果你愿意，你仍然可以使用kotlinc-native wasm32后端来进行实验，但这不会是一个长期的策略。因此，虽然这些语言之间的配对计划有很大的好处，但我们必须暂时采取观望的态度。
Zig
如果我听说你可能从未听说过Zig，或者即使你听说过，也只是顺便听说过，我不会感到惊讶。我最喜欢的关于它的轶事是，Jakub Konka，一位备受尊敬的 软件和算法及编译器理论的研究者，在等待Rust编译完成的时候学会了Zig。3这是一个有趣的故事，在嘲笑Rust编译器慢的同时，也给了你一个关于Zig带来什么的暗示性提示。4
首先，正如故事所表明的，Zig是一种简单的语言。该 网站 建议你把时间花在调试你的应用程序上，而不是花在编程语言的知识上。复杂的编程语言很难学习，也很难有效地使用，直到你多年来掌握了它们。Zig没有隐藏的控制流，没有隐藏的内存分配，也没有预处理程序和宏系统。它的全部语法都体现在一个500行的解析表达式语法文件中。
功能性的设计美学体现在主要的文档网页上。它恰恰是：一个单一的页面。它是一个长的、容易搜索的文件，也有很好的离线功能。
不要把Zig对flimflammery的避免与限制性功能集混为一谈。Zig是一种快速、可移植的语言，它支持针对多种平台的交叉编译，有广泛的安全和优化选项，直接支持SIMD向量，还有很多很多。



3雅库布的手已经遍布了 WASI,  witx,  Wasmtime,  以及 更多。.
4虽然公平地说，这是因为Rust做了很多事情，而且随着时间的推移，已经变得更好了。

我希望在这里强调的不是你需要学习Zig，尽管它在我需要掌握的新语言名单上名列前茅。相反，我希望你能更多地思考这样一个事实：语言带来了一定的价值，而运行时则带来了其他类型的价值。我们在书中想象了各种用例，这些用例涉及到从重用遗留库到编写安全的现代代码，通过把它们变成编译时的错误来消除一些运行时错误。在选择语言来表达我们的应用程序和系统功能方面，我们有一系列的选择。而且，我们越来越不需要担心我们的小众语言会因为缺乏一个支持良好的运行时平台而永远无法使用。我在前面指出，我认为是Ruby运行时给开发者对Ruby的生产力的热爱蒙上了一层阴影。这些类型的选择似乎不再像过去那样让人望而却步了。
通过各种API风格，我们可以将用一种语言编写的客户端连接到用另一种语言编写的服务。通过在响应中采用松散的耦合（例如hyperme- dia、JSON-LD等），我们可以自由地改变其中一种，而在许多情况下不会影响到任何一种。像微服务这样的架构方法允许在技术选择上进行更加分散的管理，只要它不对我们的操作运行时间和部署策略造成负担。由于WebAssembly模块在不久的将来可以正式作为ES6模块使用，人们对软件工件所使用的语言的关注会更少。
我认为有必要强调的是，WebAssembly帮助管理许多这样的权衡，把它们变成了非权衡的问题。当你可以自由地选择一种你喜欢的语言，与问题相匹配，利用现有的开发培训和经验，或者允许长期的商业价值捕获和重用，那么我们过去所面临的许多大问题就会在未来消失。
这并不是说，在支持多语言环境方面没有问题。你要对技术选择进行一定程度的监督，以避免错误的开发者将他们奇怪的偏好强加给他们的同行，然后退出。但是，如果他们这样做了，你有自由继续使用他们的代码，只要它能工作，直到你有机会把它换下来。
不管是避免被煅烧的遗留技术锁定、不充分的重用，还是走向现代化的路障，WebAssembly已经做好准备，在技术基础设施中广泛而深入地增加商业价值。如果这意味着用C#和.NET开发商业应用，或者用Zig这样的语言编写复杂的现代算法，所有这些用例都在桌面上。这一点值得不止一次地强调，因为它切中了本书的核心要点。
虽然我们当然不会在我们这个老掉牙的例子中激励Zig的优势，但它至少会强调如果你遇到Zig的问题，可以自己进行实验的机制。你可以在以下文件中找到我们howOld()函数的Zig版本

例 17-7.它看起来和我们之前看到的没有什么不同，但是用一个整数减去另一个整数到底有多难？

例17-7.我们用Zig编写的howOld函数
export fn howOld(now: i32, then: i32) i32 { return now - then;
}

把我们的例子建成一个 "独立的 "WebAssembly模块（相对于，比如说，一个以WASI为目标的模块），看起来如下。不要眨眼，否则你可能会错过编译的步骤。
brian@tweezer ~/g/w/c/zig> zig build-lib howOld.zig ↵
-target wasm32-freestanding -dynamic
我们可以用多种方式调用我们的新模块，但为了与众不同，让我们使用Node.js的代码，在 例 17-8.

例17-8.从Node.js调用我们的Zig模块
const fs = require('fs');
const source = fs.readFileSync("./howOld.wasm")。
const typedArray = new Uint8Array(source);

WebAssembly.instantiate（typedArray）.then（result => {
const howOld = result.instance.exports.howOld。
let age = howOld(2021, 2000); console.log('You are: ' + age);
});

运行这个程序可以得到以下结果。
brian@tweezer ~/g/w/c/zig> node main.js
你是21
一个更有趣的例子显示在 例17-9所示，该例来自Zig网站，强调了它的WASI支持。在这个例子中，我们展示了基于能力的安全和对命令行和文件系统的控制性访问，通过打印出我们的代码可以访问的目录作为运行时的预打开列表。

例17-9.一个以WASI为目标的Zig应用程序，使用控制台和潜在的文件系统访问权
const std = @import("std");
const PreopenList = std.fs.wasi.PreopenList; pub fn main() !void {

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){}; const gpa = &general_purpose_allocator.allocator。

var preopens = PreopenList.init(gpa); defer preopens.deinit();

尝试preopens.populate()。

for (preopens.asSlice() |preopen, i| { std.debug.print("{}: {}/n", .{ i, preopen })。
}
}
我不打算详述Zig的具体细节，但基本上我们只是根据我们的主机环境所允许的能力，打印出我们有预开放权限的目录。建立这个应用程序需要一个不同的后端目标。我们将产生一个基于WASI的模块，而不是 "独立的 "WebAssembly模块。
下一个例子中的第一行显然是建立了WASI-module。第二行是在Wasmtime中执行它，而不给它任何目录的访问权。因此，没有输出。第三行重新执行Wasmtime，并赋予其对当前目录的权限，应用程序现在可以确认。
brian@tweezer ~/g/w/c/zig> zig build-exe preopens.zig -target wasm32-wasi
brian@tweezer ~/g/w/c/zig> wasmtime preopens.wasm brian@tweezer ~/g/w/c/zig> wasmtime --dir=. preopens.wasm 0: Preopen{ .fd = 3, .type = PreopenType{ .Dir = '@".}}
我并不是想向你推销Zig。5相反，我是想加强本书的一个主要主题。WebAssembly是一种非常有价值的技术。能够选择一种语言，因为它是遗留的，因此可以重用，或者因为它是新的、令人兴奋的，并且增加了新的好处，同时能够针对我们讨论过的所有运行时，这是相当大的成就。
如果你想用Zig获得更多的乐趣，可以看看这个流行的视频游戏的实现。 俄罗斯方块的实现，它是 编写的 用 Zig ，并 使用了 WebGL.
谷物
我将要介绍的最后一种语言当然不是能够生成WebAssembly的最终语言。还有许多其他的语言，我们还没有机会去了解。相反，我选择了一种与我们讨论过的其他语言不同的语言，因为它被设计用来生成WebAssembly，同时也是普及令人兴奋和奇特的新学术语言特性的工具。


5尽管如果我已经激起了你的兴趣，"对不起，不是对不起"。

谷物语言 Grain语言 是一种年轻但有前途的语言，它融合了函数式的优点、强类型和语言的可及性。许多函数式编程语言都是非常强大的，但它们似乎也很神秘，不适合典型的开发者。很高兴看到这些功能出现在对开发者友好的语言中，如Java（JDK 8之后）、Rust，以及现在的Grain。尽管采用了函数式风格，但它并不是不必要的纯粹，而且还支持可变体。平衡类型推理与丰富的复合结构标准库，直接支持WebAssembly原语，以及Rust的模式匹配能力是其主要魅力所在。
该网站有关于设置VS Code与Grain扩展的很好的文档，以获得全方位的积极的开发经验。我在这里的目的不是要教你Grain。我将让在线资源和 Grain 社区来做这件事。相反，我只是想在最后说，语言创新不一定要在真空中发生。其他新的编程语言完全有可能在设计时考虑到WebAssembly。有了一条易于采用的持续创新的前进道路，又一次提醒我们，我们不是在处理过去的技术选择。
我们可以建立一个未来，在那里，语言和运行时间、硬件平台和API风格、数据模型和存储系统的选择可以统一到一个全面的 技术和商业价值的愿景。
但是，我的朋友们，这可能是我的下一本书。
然后呢？
你已经拥有了它。在本书中，我们已经涵盖了大量的内容，从MVP的基础知识及其低级细节，到从浏览器过渡到基于WASI的环境。我们看到了非常大的、复杂的软件项目被编译成WebAssembly，有时使用垫片和捷径来处理平台的限制。我们也看到了新提案的积极步伐，这些提案试图将WebAssembly扩展到我们复杂的、异质的、不断变化的现代软件世界的每个角落。
现在，我们已经结束了对WebAssembly支持的快速调查，它几乎以这样或那样的形式被添加到我们最喜欢的编程语言中。它也正在被令人兴奋的新语言所采用并推动其功能的发展。看来，所有这些语言都希望能发出WebAssembly的输出，以便在未来占据一席之地，这已成为一种期望。
到目前为止，有些惯性是意识到的，但现在越来越多的人认为WebAssembly在使我们的软件安全、快速和可移植方面将产生深远的影响。凡是有限制和遗漏的地方，一般都会被

通过扩展平台和开发保护我们不受恼人的细枝末节影响的工具链，可以迅速克服和关闭这些问题。
我开始从专业角度谈论WebAssembly。 谈论WebAssembly。 在2017年初，就在MVP被敲定和浏览器支持变得无处不在之后。这显然是在大多数人准备好利用这个新兴平台之前，但我想开始描绘即将到来的情况，以便软件开发人员能够做好准备。
我对这个平台为我们准备的东西从来没有不感到兴奋；我的兴趣只增不减。当你评估我们在本书中提到的各种工具、技术和用例时，我希望你至少抓住了其中的一些兴奋点。事情会继续每周发生变化，但我希望我所写的大部分内容是稳定的，值得你花时间。
我感谢你的关注，我迫不及待地想看到你用你所学的东西做什么。
