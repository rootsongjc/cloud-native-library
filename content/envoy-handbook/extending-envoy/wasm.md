---
weight: 30
title: WebAssembly（Wasm）
date: '2022-05-18T00:00:00+08:00'
type: book
---

Wasm 是一种可执行代码的可移植二进制格式，依赖于一个开放的标准。它允许开发人员用自己喜欢的编程语言编写，然后将代码编译成 **Wasm 模块**。

![代码编译成 wasm](../../images/008i3skNly1gz9m3g42z8j30j406eq31.jpg "代码编译成 wasm")

Wasm 模块与主机环境隔离，并在一个称为**虚拟机（VM）** 的内存安全沙盒中执行。Wasm 模块使用一个 API 与主机环境进行通信。

Wasm 的主要目标是在网页上实现高性能应用。例如，假设我们要用 Javascript 构建一个网页应用程序。我们可以用 Go（或其他语言）写一些，并将其编译成一个二进制文件，即 Wasm 模块。然后，我们可以在与 Javascript 网页应用程序相同的沙盒中运行已编译的 Wasm 模块。

最初，Wasm 被设计为在网络浏览器中运行。然而，我们可以将虚拟机嵌入到其他主机应用程序中，并执行它们。这就是 Envoy 的作用！

Envoy 嵌入了 V8 虚拟机的一个子集。V8 是一个用 C++ 编写的高性能 JavaScript 和 WebAssembly 引擎，它被用于 Chrome 和 Node.js 等。

我们在本课程的前面提到，Envoy 使用多线程模式运行。这意味着有一个主线程，负责处理配置更新和执行全局任务。

除了主线程之外，还有负责代理单个 HTTP 请求和 TCP 连接的 worker 线程。这些 worker 线程被设计为相互独立。例如，处理一个 HTTP 请求的 worker 线程不会受到其他处理其他请求的 worker 线程的影响。

![Envoy 线程](../../images/008i3skNly1gz9m3f9lmlj30sg0k0dgs.jpg "Envoy 线程")

每个线程拥有自己的资源副本，包括 Wasm 虚拟机。这样做的原因是为了避免任何昂贵的跨线程同步，即实现更高的内存使用率。

Envoy 在运行时将每个独特的 Wasm 模块（所有 *.wasm 文件）加载到一个独特的 Wasm VM。由于 Wasm VM 不是线程安全的（即，多个线程必须同步访问一个 Wasm VM），Envoy 为每个将执行扩展的线程创建一个单独的 Wasm VM 副本。因此，每个线程可能同时有多个 Wasm VM 在使用。

## Proxy-Wasm

我们将使用的 SDK 允许我们编写 Wasm 扩展，这些扩展是 HTTP 过滤器，网络过滤器，或称为 **Wasm 服务**的专用扩展类型。这些扩展在 Wasm 虚拟机内的 worker 线程（HTTP 过滤器，网络过滤器）或主线程（Wasm 服务）上执行。正如我们提到的，这些线程是独立的，它们本质上不知道其他线程上发生的请求处理。

HTTP 过滤器是处理 HTTP 协议的，它对 HTTP Header、body 等进行操作。同样，网络过滤器处理 TCP 协议，对数据帧和连接进行操作。我们也可以说，这两种插件类型是无状态的。

Envoy 还支持有状态的场景。例如，你可以编写一个扩展，将请求数据、日志或指标等统计信息在多个请求之间进行汇总——这意味着跨越了许多 worker 线程。对于这种情况，我们会使用 Wasm 服务类型。Wasm 服务类型运行在单个虚拟机上；这个虚拟机只有一个实例，它运行在 Envoy 主线程上。你可以用它来汇总无状态过滤器的指标或日志。

下图显示了 Wasm 服务扩展是如何在主线程上执行的，而不是 HTTP 或网络过滤器，后者是在 worker 线程上执行。

![API](../../images/008i3skNly1gz9m3gjke9j30sg0g5q3u.jpg "API")

事实上，Wasm 服务扩展是在主线程上执行的，并不影响请求延迟。另一方面，网络或 HTTP 过滤器会影响延迟。

图中显示了在主线程上运行的 Wasm 服务扩展，它使用消息队列 API 订阅队列并接收由运行在 worker 线程上的 HTTP 过滤器或网络过滤器发送的消息。然后，Wasm 服务扩展可以聚合从 worker 线程上收到的数据。

Wasm 服务扩展并不是持久化数据的唯一方法。你也可以调用 HTTP 或 gRPC API。此外，我们可以使用定时器 API 在请求之外执行行动。

我们提到的 API、消息队列、定时器和共享数据都是由 [Proxy-Wasm](https://github.com/proxy-wasm) 提供的。

Proxy-Wasm 是一个代理无关的 ABI（应用二进制接口）标准，它规定了代理（我们的主机）和 Wasm 模块如何互动。这些互动是以函数和回调的形式实现的。

Proxy-Wasm 中的 API 与代理无关，这意味着它们可以与 Envoy 代理以及任何其他代理（例如 [MOSN](https://github.com/mosn/mosn)）一起实现 Proxy-Wasm 标准。这使得你的 Wasm 过滤器可以在不同的代理之间移植，而且它们并不局限于 Envoy。


![Proxy-Wasm](../../images/008i3skNly1gz9m3eu5a4j30sg0gcdgs.jpg "Proxy-wasm")

当请求进入 Envoy 时，它们会经过不同的过滤器链，被过滤器处理，在链中的某个点，请求数据会流经本地 Proxy-Wasm 扩展。

这个扩展使用 Proxy-Wasm 接口与运行在虚拟机内的扩展通信。 过滤器处理完数据后，该链就会继续，或停止，这取决于从扩展返回的结果。

基于 Proxy-Wasm 规范，我们可以使用一些特定语言的 SDK 实现来编写扩展。

在其中一个实验中，我们将使用 [Go SDK for Proxy-Wasm](https://github.com/tetratelabs/proxy-wasm-go-sdk) 来编写 Go 中的 Proxy-Wasm 插件。

[TinyGo](https://tinygo.org/) 是一个用于嵌入式系统和 WebAssembly 的编译器。它不支持使用所有的标准 Go 包。例如，不支持一些标准包，如 `net` 和其他。

你还可以选择使用 Assembly Script、C++、Rust 或 Zig。

## 配置 Wasm 扩展

Envoy 中的通用 Wasm 扩展配置看起来像这样。

```yaml
- name: envoy.filters.http.wasm
  typed_config:
    "@type": type.googleapis.com/udpa.type.v1.TypedStruct
    type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
    value:
      config:
        vm_config:
          vm_id: "my_vm"
          runtime: "envoy.wasm.runtime.v8"
          configuration:
            "@type": type.googleapis.com/google.protobuf.StringValue
            value: '{"plugin-config": "some-value"}'
          code:
            local:
              filename: "my-plugin.wasm"
        configuration:
          "@type": type.googleapis.com/google.protobuf.StringValue
          value: '{"vm-wide-config": "some-value"}'
```

`vm_config` 字段用于指定 Wasm 虚拟机、运行时，以及我们要执行的`.wasm` 扩展的实际指针。

`vm_id` 字段在虚拟机之间进行通信时使用。然后这个 ID 可以用来通过共享数据 API 和队列在虚拟机之间共享数据。请注意，要在多个插件中重用虚拟机，你必须使用相同的 `vm_id`、运行时、配置和代码。

下一个项目是 `runtime`。这通常被设置为 `envoy.wasm.runtime.v8`。例如，如果我们用 Envoy 编译 Wasm 扩展，我们会在这里使用 `null` 运行时。其他选项是 Wasm micro runtime、Wasm VM 或 Wasmtime；不过，这些在官方 Envoy 构建中都没有启用。

`vm_config` 字段下的配置是用来配置虚拟机本身的。除了虚拟机 ID 和运行时外，另一个重要的部分是`code`字段。

`code` 字段是我们引用编译后的 Wasm 扩展的地方。这可以是一个指向本地文件的指针（例如，`/etc/envoy/my-plugin.wasm`）或一个远程位置（例如，`https://wasm.example.com/my-plugin.wasm`）。

`configuration` 文件，一个在 `vm_config` 下，另一个在 `config` 层，用于为虚拟机和插件提供配置。然后当虚拟机或插件启动时，可以从 Wasm 扩展代码中读取这些值。

要运行一个 Wasm 服务插件，我们必须在 `bootstrap_extensions` 字段中定义配置，并将 `singleton` 布尔字段的值设置为真。

```yaml
bootstrap_extensions:
- name: envoy.bootstrap.wasm
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.wasm.3.WasmService
    singleton: true
    config:
      vm_config:{ ...}
```

## 开发 Wasm 扩展 - Proxy-Wasm Go SDK API

在开发 Wasm 扩展时，我们将学习上下文、hostcall API 和入口点。

### 上下文

上下文是 Proxy-Wasm SDK 中的一个接口集合，并与我们前面解释的概念相匹配。

![上下文](../../images/008i3skNly1gz9m3fkp1xj30e806ndfx.jpg "上下文")

例如，每个虚拟机中都有一个 `VMContext`，可以有一个或多个 `PluginContexts`。这意味着我们可以在同一个虚拟机上下文中运行不同的插件（即使用同一个 `vm_id` 时）。每个 `PluginContext` 对应于一个插件实例。那就是 `TcpContext`（TCP 网络过滤器）或 `HttpContext`（HTTP 过滤器）。

`VMContext` 接口定义了两个函数：`OnVMStart` 函数和 `NewPluginContext` 函数。

```go
type VMContext interface {
  OnVMStart(vmConfigurationSize int) OnVMStartStatus
  NewPluginContext(contextID uint32) PluginContext
}
```

顾名思义，`OnVMStart` 在虚拟机创建后被调用。在这个函数中，我们可以使用 `GetVMConfiguration` hostcall 检索可选的虚拟机配置。这个函数的目的是执行任何虚拟机范围的初始化。

作为开发者，我们需要实现 `NewPluginContext` 函数，在该函数中我们创建一个 `PluginContext` 的实例。

`PluginContext` 接口定义了与 `VMContext` 类似的功能。下面是这个接口。

```go
type PluginContext interface {
  OnPluginStart(pluginConfigurationSize int) OnPluginStartStatus
  OnPluginDone() bool

  OnQueueReady(queueID uint32)
  OnTick()

  NewTcpContext(contextID uint32) TcpContext
  NewHttpContext(contextID uint32) HttpContext
}
```

`OnPluginStart` 函数与我们前面提到的 `OnVMStart` 函数类似。它在插件被创建时被调用。在这个函数中，我们也可以使用 `GetPluginConfiguration ` API 来检索插件的特定配置。我们还必须实现 `NewTcpContext` 或 `NewHttpContext`，在代理中响应 HTTP/TCP 流时被调用。这个上下文还包含一些其他的函数，用于设置队列（`OnQueueReady`）或在流处理的同时做异步任务（`OnTick`）。

> 参考 [Proxy Wasm Go SDK Github 仓库](https://github.com/tetratelabs/proxy-wasm-go-sdk/blob/main/proxywasm/types/context.go) 中的 `context.go` 文件，以获得最新的接口定义。 

### Hostcall API

[这里](https://github.com/tetratelabs/proxy-wasm-go-sdk/blob/main/proxywasm/hostcall.go)实现的 hostcall API ，为我们提供了与 Wasm 插件的 Envoy 代理互动的方法。

hostcall API 定义了读取配置的方法；设置共享队列并执行队列操作；调度 HTTP 调用，从请求和响应流中检索 Header、Trailer 和正文并操作这些值；配置指标；以及更多。

### 入口点

插件的入口点是 `main` 函数。Envoy 创建了虚拟机，在它试图创建 `VMContext` 之前，它调用了 `main` 函数。在典型的实现中，我们把 `SetVMContext` 方法称为 `main` 函数。

```go
func main() {
  proxywasm.SetVMContext(&myVMContext{})
}

type myVMContext struct { ....}

var _ types.VMContext = &myVMContext{}.
```

