---
weight: 50
title: 实验17：使用 Wasm 和 Go 扩展 Envoy
date: '2022-05-18T00:00:00+08:00'
type: book
---

在这个实验中，我们将使用 [TinyGo](https://tinygo.org/)、[proxy-wasm-go-sdk](https://github.com/tetratelabs/proxy-wasm-go-sdk) 和 [func-e CLI](https://func-e.io/) 来构建和测试一个 Envoy Wasm 扩展。

我们将写一个简单的 Wasm 模块，为响应头添加一个头。稍后，我们将展示如何读取配置和添加自定义指标。我们将使用 Golang 并使用 TinyGo 编译器进行编译。

## 安装 TinyGo

让我们下载并安装 TinyGo。

```sh
wget https://github.com/tinygo-org/tinygo/releases/download/v0.21.0/tinygo_0.21.0_amd64.deb
sudo dpkg -i tinygo_0.21.0_amd64.deb
```

你可以运行 `tinygo version` 来检查安装是否成功。

```sh
$ tinygo version
tinygo version 0.21.0 linux/amd64 (using go version go1.17.2 and LLVM version 11.0.0)
```

## 为 Wasm 模块搭建脚手架

我们将首先为我们的扩展创建一个新的文件夹，初始化 Go 模块，并下载 SDK 依赖。

```go
$ mkdir header-filter && cd header-filter
$ go mod init header-filter
$ go mod edit -require=github.com/tetratelabs/proxy-wasm-go-sdk@main
$ go mod download github.com/tetratelabs/proxy-wasm-go-sdk
```

接下来，让我们创建 `main.go` 文件，其中有我们 WASM 扩展的代码。

```go
package main

import (
  "github.com/tetratelabs/proxy-wasm-go-sdk/proxywasm"
  "github.com/tetratelabs/proxy-wasm-go-sdk/proxywasm/types"
)

func main() {
  proxywasm.SetVMContext(&vmContext{})
}

type vmContext struct {
  // Embed the default VM context here,
  // so that we don't need to reimplement all the methods.
  types.DefaultVMContext
}

// Override types.DefaultVMContext.
func (*vmContext) NewPluginContext(contextID uint32) types.PluginContext {
  return &pluginContext{}
}

type pluginContext struct {
  // Embed the default plugin context here,
  // so that we don't need to reimplement all the methods.
  types.DefaultPluginContext
}

// Override types.DefaultPluginContext.
func (*pluginContext) NewHttpContext(contextID uint32) types.HttpContext {
  return &httpHeaders{contextID: contextID}
}

type httpHeaders struct {
  // Embed the default http context here,
  // so that we don't need to reimplement all the methods.
  types.DefaultHttpContext
  contextID uint32
}

func (ctx *httpHeaders) OnHttpRequestHeaders(numHeaders int, endOfStream bool) types.Action {
  proxywasm.LogInfo("OnHttpRequestHeaders")
  return types.ActionContinue
}

func (ctx *httpHeaders) OnHttpResponseHeaders(numHeaders int, endOfStream bool) types.Action {
  proxywasm.LogInfo("OnHttpResponseHeaders")
  return types.ActionContinue
}

func (ctx *httpHeaders) OnHttpStreamDone() {
  proxywasm.LogInfof("%d finished", ctx.contextID)
}
```

将上述内容保存在一个名为 `main.go的`文件中。

让我们建立过滤器，检查是否一切正常。

```sh
tinygo build -o main.wasm -scheduler=none -target=wasi main.go
```

构建命令应该成功运行并生成一个名为 `main.wasm的`文件。

我们将使用 `func-e` 来运行一个本地 Envoy 实例来测试我们构建的扩展。

首先，我们需要一个 Envoy 配置，它将配置扩展。

```yaml
static_resources:
  listeners:
    - name: main
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 10000
      filter_chains:
        - filters:
            - name: envoy.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: ingress_http
                codec_type: auto
                route_config:
                  name: local_route
                  virtual_hosts:
                    - name: local_service
                      domains:
                        - "*"
                      routes:
                        - match:
                            prefix: "/"
                          direct_response:
                            status: 200
                            body:
                              inline_string: "hello world\n"
                http_filters:
                  - name: envoy.filters.http.wasm
                    typed_config:
                      "@type": type.googleapis.com/udpa.type.v1.TypedStruct
                      type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
                      value:
                        config:
                          vm_config:
                            runtime: "envoy.wasm.runtime.v8"
                            code:
                              local:
                                filename: "main.wasm"
                  - name: envoy.filters.http.router
admin:
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 9901
```

将上述内容保存到 `8-lab-2-wasm-config.yaml` 文件。

Envoy 的配置在 10000 端口设置了一个监听器，返回一个直接响应（HTTP 200），正文是 `hello world`。在 `http_filters` 部分，我们配置了 `envoy.filters.http.wasm` 过滤器，并引用了我们之前建立的本地 WASM 文件（`main.wasm`）。

让我们在后台用这个配置运行 Envoy。

```sh
func-e run -c 8-Lab-2-wasm-config.yaml &
```

Envoy 实例的启动应该没有任何问题。一旦启动，我们就可以向 Envoy 监听的端口（`10000`）发送一个请求。

```sh
$ curl -v localhost:10000
...
< HTTP/1.1 200 OK
< content-length: 13
< content-type: text/plain
< my-new-header: some-value-here
< date: Mon, 22 Jun 2021 17:02:31 GMT
< server: envoy
<
hello world
```

输出显示了两个日志条目：一个来自 `OnHttpRequestHeaders` 处理器，第二个来自 `OnHttpResponseHeaders` 处理器。最后一行是过滤器中的直接响应配置所返回的响应示例。

你可以通过用 `fg` 把进程带到前台，然后按 CTRL+C 停止代理。

## 在 HTTP 响应上设置附加头信息

让我们打开 `main.go` 文件，在响应头信息中添加一个头信息。我们将更新 `OnHttpResponseHeaders` 函数来做到这一点。

我们将调用 `AddHttpResponseHeader` 函数来添加一个新的头。更新 `OnHttpResponseHeaders` 函数，使其看起来像这样。

```go
func (ctx *httpHeaders) OnHttpResponseHeaders(numHeaders int, endOfStream bool) types.action {
  proxywasm.LogInfo("OnHttpResponseHeaders")
  err := proxywasm.AddHttpResponseHeader("my-new-header", "some-value-here")
  if err != nil {
    proxywasm.LogCriticalf(" failed to add response header: %v", err)
  }
  return types.ActionContinue
}
```

让我们重新建立扩展。

```sh
tinygo build -o main.wasm -scheduler=none -target=wasi main.go
```

现在我们可以用更新后的扩展来重新运行 Envoy 代理。

```sh
func-e run -c 8-Lab-2-wasm-config.yaml &
```

现在，如果我们再次发送一个请求（确保添加 `-v` 标志），我们将看到被添加到响应中的头。

```sh
$ curl -v localhost:10000
...
< HTTP/1.1 200 OK
< content-length: 13
< content-type: text/plain
< my-new-header: some-value-here
< date: Mon, 22 Jun 2021 17:02:31 GMT
< server: envoy
<
hello world
```

## 从配置中读取数值

在代码中硬编码这样的值从来不是一个好主意。让我们看看我们如何读取额外的头文件。

**1.** 将 `additionalHeaders` 和 `contextID` 添加到 `pluginContext` 结构体中：

```go
type pluginContext struct {
// 在这里嵌入默认的插件上下文。
// 这样我们就不需要重新实现所有的方法了。
    types.DefaultPluginContext
    additionalHeaders map[string]string
    contextID uint32
}
```

**2.** 更新 `NewPluginContext` 函数以初始化数值。

```go
func (*vmContext) NewPluginContext(contextID uint32) types.PluginContext {
  return &pluginContext{contextID: contextID, additionalHeaders: map[string]string{}}
}
```

**3.** 在 `OnPluginStart` 函数中，我们现在可以从 Envoy 配置中读入值，并将键 / 值对存储在 `extrapperHeaders` 映射中。

```go
  func (ctx *pluginContext) OnPluginStart(pluginConfigurationSize int) types.OnPluginStartStatus {
    // Get the plugin configuration
    config, err := proxywasm.GetPluginConfiguration()
    if err != nil && err != types.ErrorStatusNotFound {
      proxywasm.LogCriticalf("failed to load config: %v", err)
      return types.OnPluginStartStatusFailed
    }

    // Read the config
    scanner := bufio.NewScanner(bytes.NewReader(config))
    for scanner.Scan() {
      line := scanner.Text()
      if strings.HasPrefix(line, "#") {
        continue
      }
      // Each line in the config is in the "key=value" format
      if tokens := strings.Split(scanner.Text(), "="); len(tokens) == 2 {
        ctx.additionalHeaders[tokens[0]] = tokens[1]
      }
    }
    return types.OnPluginStartStatusOK
  }
```

为了访问我们设置的配置值，我们需要在初始化 HTTP 上下文时将该地图添加到 HTTP 上下文中。要做到这一点，我们需要先更新 `httpheaders` 结构。

```go
type httpHeaders struct {
  // 在这里嵌入默认的http上下文。
  // 这样我们就不需要重新实现所有的方法了。
  types.DefaultHttpContext
  contextID uint32
  additionalHeaders map[string]string
}
```

然后，在 `NewHttpContext` 函数中，我们可以用来自插件上下文的附加 Header map 来实例化 httpHeaders。

```go
func (ctx *pluginContext) NewHttpContext(contextID uint32) types.HttpContext {
  return &httpHeaders{contextID: contextID, additionalHeaders: ctx.additionalHeaders}
}
```

最后，为了设置 Header，我们修改了 `OnHttpResponseHeaders` 函数，遍历 `extraHeaders` 映射，并为每个项目调用 `AddHttpResponseHeader`。

```go
func (ctx *httpHeaders) OnHttpResponseHeaders(numHeaders int, endOfStream bool) types.Action {
  proxywasm.LogInfo("OnHttpResponseHeaders")

  for key, value := range ctx.additionalHeaders {
    if err := proxywasm.AddHttpResponseHeader(key, value); err != nil {
        proxywasm.LogCriticalf("failed to add header: %v", err)
        return types.ActionPause
    }
    proxywasm.LogInfof("header set: %s=%s", key, value)
  }

  return types.ActionContinue
}
```

让我们再次重建这个扩展。

```sh
tinygo build -o main.wasm -scheduler=none -target=wasi main.go
```

另外，让我们更新配置文件，在过滤器配置（`configuration` 字段）中包括额外的头信息。

```yaml
- name: envoy.filters.http.wasm
  typed_config:
    "@type": type.googleapis.com/udpa.type.v1.TypedStruct
    type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
    value:
      config:
        vm_config:
          runtime: "envoy.wasm.runtime.v8"
          code:
            local:
              filename: "main.wasm"
        # ADD THESE LINES
        configuration:
          "@type": type.googleapis.com/google.protobuf.StringValue
          value: |
            header_1=somevalue
            header_2=secondvalue
```

随着过滤器的更新，我们可以重新运行代理。当你发送一个请求时，你会注意到我们在过滤器配置中设置的头信息被添加为响应头信息。

```sh
$ curl -v localhost:10000
...
< HTTP/1.1 200 OK
< content-length: 13
< content-type: text/plain
< header_1: somevalue
< header_2: secondvalue
< date: Mon, 22 Jun 2021 17:54:53 GMT
< server: envoy
...
```

## 添加一个指标

让我们添加另一个功能 —— 计数器，每次有一个叫 `hello的`请求头被设置时都会增加。

首先，让我们更新 `pluginContext` 以包括 `helloHeaderCounter`。

```go
type pluginContext struct {
  // 在这里嵌入默认的插件上下文。
  // 这样我们就不需要重新实现所有的方法了。
  types.DefaultPluginContext
  additionalHeaders map[string]string
  contextID uint32
  // 添加这一行
  helloHeaderCounter proxywasm.MetricCounter 
}
```

有了结构中的计数器指标，我们现在可以在 `NewPluginContext` 函数中创建它。我们将调用头信息 `hello_header_counter`。

```go
func (*vmContext) NewPluginContext(contextID uint32) types.PluginContext {
  return &pluginContext{contextID: contextID, additionalHeaders: map[string]string{}, helloHeaderCounter: proxywasm.DefineCounterMetric("hello_header_counter") }
}
```

由于我们要检查传入的请求头以决定是否增加计数器，我们需要将 `helloHeaderCounter也`添加到 `httpHeaders` 结构中。

```go
type httpHeaders struct {
  // 在这里嵌入默认的http上下文。
  // 这样我们就不需要重新实现所有的方法了。
  types.DefaultHttpContext
  contextID uint32
  additionalHeaders map[string]string
  // 添加这一行
  helloHeaderCounter proxywasm.MetricCounter
}
```

另外，我们需要从 `pluginContext` 中获取计数器，并在创建新的 HTTP 上下文时设置它。

```go
// 覆盖 types.DefaultPluginContext
func (ctx *pluginContext) NewHttpContext(contextID uint32) types.HttpContext {
  return &httpHeaders{contextID: contextID, additionalHeaders: ctx.additionalHeaders, helloHeaderCounter: ctx.helloHeaderCounter}
}
```

现在，我们已经将 `helloHeaderCounter` 一直输送到 `httpHeaders中`，我们可以在 `OnHttpRequestHeaders` 函数中使用它。

```go
func (ctx *httpHeaders) OnHttpRequestHeaders(numHeaders int, endOfStream bool) types.action {
  proxywasm.LogInfo("OnHttpRequestHeaders")

  _, err := proxywasm.GetHttpRequestHeader("hello")
  if err != nil {
    // 如果头没有被设置，则忽略
    return types.ActionContinue
  }

  ctx.helloHeaderCounter.Increment(1)
  proxywasm.LogInfo("hello_header_counter incremented")
  返回 types.ActionContinue
}
```

在这里，我们要检查 \"hello" 请求头是否被定义（注意，我们并不关心头的值），如果它被定义，我们就在计数器实例上调用 `Increment` 函数。否则，我们将忽略它，如果我们从 `GetHttpRequestHeader` 调用中得到一个错误，则返回 `ActionContinue。`

让我们再次重建这个扩展。

```sh
tinygo build -o main.wasm -scheduler=none -target=wasi main.go
```

然后重新运行 Envoy 代理。像这样发出几个请求。

```sh
curl -H "hello: something" localhost:10000
```

你会注意到像这样的日志 Envoy 日志条目。

```
wasm log: hello_header_counter incremented
```

你也可以使用 9901 端口的管理地址来检查指标是否被跟踪。

```sh
$ curl localhost:9901/stats/prometheus | grep hello
# TYPE envoy_hello_header_counter counter
envoy_hello_header_counter{} 1
```
