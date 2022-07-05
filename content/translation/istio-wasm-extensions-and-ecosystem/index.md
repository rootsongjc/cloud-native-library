---
title: Istio 1.12 引入 Wasm 插件配置 API 用于扩展 Istio 生态
summary: Istio 1.12 中新的 WebAssembly 基础设施使其能够轻松地将额外的功能注入网格部署中。

# Link this post with a project
projects: [""]

# Date published
date: 2021-11-24T18:03:00+08:00

# Date updated
lastmod: 2021-11-24T18:03:00+08:00

# Is this an unpublished draft?
draft: false

# Show this page in the Featured widget?
featured: false

# Featured image
# Place an image named `featured.jpg/png` in this page's folder and customize its options here.
image:
  caption: '© [**jimmysong.io**](https://jimmysong.io)'
  focal_point: 'right'
  placement: 2
  preview_only: false

authors: ["胡渐飞"]
tags: ["Envoy","Wasm","Istio","Tetrate"]
categories: ["Istio"]
links:
  - icon: language
    icon_pack: fa
    name: 阅读英文版原文
    url: https://www.tetrate.io/blog/istio-wasm-extensions-and-ecosystem/
---

## 前言

Istio 1.12 中新的 WebAssembly 基础设施使其能够轻松地将额外的功能注入网格部署中。

经过三年的努力，Istio 现在有了一个强大的扩展机制，可以将自定义和第三方 Wasm 模块添加到网格中的 sidecar。Tetrate 工程师[米田武（Takeshi Yoneda）](https://github.com/mathetake)和[周礼赞（Lizan Zhou）](https://github.com/lizan)在实现这一目标方面发挥了重要作用。这篇文章将介绍 Istio 中 Wasm 的基础知识，以及为什么它很重要，然后是关于建立自己的 Wasm 插件并将其部署到网格的简短教程。

## 为什么 Istio 中的 Wasm 很重要

使用 Wasm，开发人员可以更容易的扩展网格和网关。在 Tetrate，我们相信这项技术正在迅速成熟，因此我们一直在投资上游的 Istio，使配置 API、分发机制和从 Go 开始的可扩展性体验更加容易。我们认为这将使 Istio 有一个全新的方向。

## 有何期待：新的插件配置 API，可靠的获取和安装机制

有一个新的顶级 API，叫做 [WasmPlugin](https://istio.io/latest/docs/reference/config/proxy_extensions/wasm-plugin/)，可以让你配置要安装哪些插件，从哪里获取它们（OCI 镜像、容器本地文件或远程 HTTP 资源），在哪里安装它们（通过 [Workload 选择器](https://istio.io/latest/docs/reference/config/type/workload-selector/#WorkloadSelector)），以及一个配置结构体来传递给插件实例。

istio-agent 中的镜像提取机制（在 Istio 1.9 中引入），从远程 HTTP 源可靠地检索 Wasm 二进制文件，已被扩展到支持从任何 OCI 注册处检索 Wasm OCI 镜像，包括 Docker Hub、Google Container Registry（GCR）、Amazon Elastic Container Registry（Amazon ECR）和其他地方。

这意味着你可以创建自己的 Wasm 插件，或者从任何注册处选择现成的插件，只需几行配置就可以扩展 Istio 的功能。Istio 会在幕后做所有的工作，为你获取、验证、安装和配置它们。

## Istio Wasm 扩展

Istio 的扩展机制使用 [Proxy-Wasm 应用二进制接口（ABI）](https://github.com/proxy-wasm/spec)规范，该规范由周礼赞和米田武带头制定，提供了一套代理无关的流媒体 API 和实用功能，可以用任何有合适 SDK 的语言来实现。截至目前，Proxy-Wasm 的 SDK 有 AssemblyScript（类似 TypeScript）、C++、Rust、Zig 和 Go（使用 TinyGo WebAssembly 系统接口「WASI」，米田武也是其主要贡献者）。

## 如何获取：Tetrate Istio Distro

获得 Istio 的最简单方法是使用 Tetrate 的开源 [`get-mesh` CLI 和 Tetrate Istio Distro](https://istio.tetratelabs.io/)，这是一个简单、安全的上游 Istio 的企业级发行版。

## Wasm 实战：构建你自己的速率限制 WebAssembly 插件

在我们之前关于 [Envoy 中的 Wasm 扩展](https://www.tetrate.io/blog/wasm-modules-and-envoy-extensibility-explained-part-1/)的博客中，我们展示了如何开发 WebAssembly 插件来增强服务网格的能力。新的 Wasm 扩展 API 让它变得更加简单。本教程将解释如何使用 Istio Wasm 扩展 API 来实现 Golang 中的速率限制。

### 先决条件

- 熟悉 [Istio 和 Envoy 中的 Wasm](https://www.tetrate.io/blog/wasm-modules-and-envoy-extensibility-explained-part-1/)。
- 安装 [TinyGo 0.21.0](https://tinygo.org/getting-started/install/) 并使用 Golang 构建 Wasm 扩展。

### 说明

在这个例子中，我们将在集群中部署两个应用程序（sleep 和 httpbin）。我们将从一个容器向另一个容器发送几个请求，而不部署任何 Wasm 扩展。

接下来，我们将在 Go 中创建一个 Wasm 模块，为响应添加一个自定义头，并拒绝任何请求率超过每秒两个的请求。

我们将把 Wasm 模块推送到 Docker 镜像仓库，并使用新的 WasmPlugin 资源，告诉 Istio 从哪里下载 Wasm 模块，以及将该模块应用于哪些工作负载。

### 第 1 步：安装 Istio 并部署应用程序

首先，我们将下载并安装 Istio 1.12，并标记 Kubernetes 的 default 命名空间，以便自动注入 sidecar。

```sh
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.12 sh
cd istio-1.12/
./bin/istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled --overwrite
```

接下来，我们将部署 httpbin 和 sleep 应用程序的示例。

```sh
kubectl apply -f samples/httpbin/httpbin.yaml
kubectl apply -f samples/sleep/sleep.yaml
```

应用程序部署并运行后，我们将每秒从 **sleep** 容器向 **httpbin** 容器发送 4 个请求。

```sh
$ SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})

$ kubectl exec ${SLEEP_POD} -c sleep -- sh -c 'for i in $(seq 1 3); do curl --head -s httpbin:8000/headers; sleep 0.25; done'


HTTP/1.1 200 OK
server: envoy
date: Tue, 16 Nov 2021 22:18:32 GMT
content-type: application/json
content-length: 523
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 2


HTTP/1.1 200 OK
server: envoy
date: Tue, 16 Nov 2021 22:18:32 GMT
content-type: application/json
content-length: 523
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 4


HTTP/1.1 200 OK
server: envoy
date: Tue, 16 Nov 2021 22:18:32 GMT
content-type: application/json
content-length: 523
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 1
```

你会发现所有的请求都成功了，并返回了 HTTP 200。

### 第 2 步：开发、编译和推送 Wasm 模块

我们将使用 Golang 和 Proxy Wasm Golang SDK 来开发 Wasm 模块。我们将使用 SDK 资源库中的一个现有例子，叫做 istio-rate-limiting。要开始，请先克隆 Github 仓库。

```sh
git clone https://github.com/tetratelabs/wasm-rate-limiting
cd wasm-rate-limiting/
```

我们来看看 `main.go` 中的代码。这就是我们使用 Proxy Wasm Golang SDK 实现速率限制逻辑的地方。Wasm 模块做了两件事。

- 在响应中添加一个自定义的头。
- 执行 2 个请求 / 秒的速率限制，拒绝超额的请求。

下面是 `main.go` 的片段，显示了功能是如何实现的。

```go
// Modify the header
func (ctx *httpHeaders) OnHttpResponseHeaders(numHeaders int, endOfStream bool) types.Action {
	for key, value := range additionalHeaders {
		proxywasm.AddHttpResponseHeader(key, value)
	}
	return types.ActionContinue
}


// Perform rate limiting
func (ctx *httpHeaders) OnHttpRequestHeaders(int, bool) types.Action {
	current := time.Now().UnixNano()
	// We use nanoseconds() rather than time.Second() because the proxy-wasm has the known limitation.
	// TODO(incfly): change to time.Second() once https://github.com/proxy-wasm/proxy-wasm-cpp-host/issues/199
	// is resolved and released.
	if current > ctx.pluginContext.lastRefillNanoSec+1e9 {
		ctx.pluginContext.remainToken = 2
		ctx.pluginContext.lastRefillNanoSec = current
	}
	proxywasm.LogCriticalf("Current time %v, last refill time %v, the remain token %v",
		current, ctx.pluginContext.lastRefillNanoSec, ctx.pluginContext.remainToken)
	if ctx.pluginContext.remainToken == 0 {
		if err := proxywasm.SendHttpResponse(403, [][2]string{
			{"powered-by", "proxy-wasm-go-sdk!!"},
		}, []byte("rate limited, wait and retry."), -1); err != nil {
			proxywasm.LogErrorf("failed to send local response: %v", err)
			proxywasm.ResumeHttpRequest()
		}
		return types.ActionPause
	}
	ctx.pluginContext.remainToken -= 1
	return types.ActionContinue
}
```

在 `OnHttpResponseHeaders` 函数中，我们正在迭代 `extraHeaders` 变量，并将头文件添加到响应中。

在 `OnHttpRequestHeaders` 函数中，我们得到当前的时间戳，将其与最后一次补给时间的时间戳进行比较（对于速率限制器），如果需要的话，就补给令牌。

如果没有剩余的令牌，我们就发送一个带有额外头的 403 响应（**由：proxy-wasm-go-sdk！！**）。

让我们用 tinygo 将 Golang 程序编译成 Wasm 模块，并将其打包成一个 Docker 镜像。

```sh
tinygo build -o main.wasm -scheduler=none -target=wasi main.go
```

我们构建一个 Docker 镜像，并将其推送到镜像仓库（用你自己的 Docker 镜像仓库和镜像名称替换 `${YOUR_DOCKER_REGISTRY_IMAGE}`）。在这之后，你的 Wasm 插件就可以在你的服务网格中使用了。

```sh
docker build -t ${YOUR_DOCKER_REGISTRY_IMAGE}:v1 .
docker push -t ${YOUR_DOCKER_REGISTRY_IMAGE}:v1 
```

另外，你也可以使用一个预构建的 Docker 镜像，它有相同的代码，位于 [ghcr.io/tetratelabs/wasm-rate-limiting:v1](http://ghcr.io/tetratelabs/wasm-rate-limiting:v1)。

### 第 3 步：配置 Istio Wasm 扩展 API

Istio Wasm Extension API 和新的 WasmPlugin 资源允许我们将我们推送到 Docker 镜像仓库的速率限制 Wasm 模块添加到 httpbin 工作负载中。下面是 WasmPlugin 资源的 YAML 配置。

```yaml
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: httpbin-rate-limiting
  namespace: default
spec:
  selector:
    matchLabels:
      app: httpbin
  url: oci://ghcr.io/tetratelabs/wasm-rate-limiting:v1
```

这个配置部署后，Istiod 就会把相应的配置推送到 Envoy sidecar（与我们在 `matchLabels` 字段中指定的标签相匹配的那些）。Sidecar 中的 Istio 代理将执行远程获取，下载我们刚刚推送的 Wasm 模块，然后将其加载到 Envoy 运行时的 Wasm 引擎中执行。

让我们把上述 YAML 保存为 wasm.yaml，并将其部署到集群中。

```sh
$ kubectl apply -f ./wasm.yaml
wasmplugin.extensions.istio.io/httpbin-rate-limiting created
```

### 第 4 步：验证速率限制的效果

在我们部署了 WasmPlugin 资源和 Istio 从注册表中获取了 Wasm 模块后，我们现在可以验证 Wasm 插件中实现的速率限制是如何工作的。

```sh
$ SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl exec ${SLEEP_POD} -c sleep -- sh -c 'for i in $(seq 1 3); do curl --head -s httpbin:8000/headers; sleep 0.25; done'
HTTP/1.1 200 OK
server: envoy
date: Tue, 16 Nov 2021 22:16:34 GMT
content-type: application/json
content-length: 523
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 2
who-am-i: wasm-extension
injected-by: istio-api!

HTTP/1.1 200 OK
server: envoy
date: Tue, 16 Nov 2021 22:16:35 GMT
content-type: application/json
content-length: 523
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 2
who-am-i: wasm-extension
injected-by: istio-api!

HTTP/1.1 403 Forbidden
powered-by: proxy-wasm-go-sdk!!
content-length: 29
content-type: text/plain
who-am-i: wasm-extension
injected-by: istio-api!
date: Tue, 16 Nov 2021 22:16:35 GMT
server: envoy
x-envoy-upstream-service-time: 0
```

就像以前一样，我们从 sleep 容器向 httpbin 容器发送 3 个请求。这一次，Wasm 插件代码被执行，我们可以注意到输出中的一些差异。首先，`who-am-i` 头被 Wasm 插件注入了。前两个请求以 HTTP 200 的响应代码成功，剩下的请求则以 HTTP 429 失败。此外，我们可以注意到一个名为 `powered-by` 的额外头，它也被 Wasm 插件注入了。

## 教程摘要

总而言之，本教程演示了如何轻松实现插件功能，以扩展 Istio 的功能，满足你的特定需求。这需要三个步骤：

1. 在 Golang 中实现你的插件功能。
2. 编译、构建，并将 Wasm 模块推送到符合 OCI 标准的 Docker 镜像仓库。
3. 使用 WasmPlugin 资源配置服务网格工作负载，以便从远程镜像仓库中拉取 Wasm 模块。

该教程实现了一个单一的 Wasm 插件来处理 HTTP 请求。除此之外，你可以有多个 Wasm 插件，每个单独的插件负责某一部分的功能。

例如，[AUTHN](https://github.com/istio/api/blob/master/extensions/v1alpha1/wasm.proto#L254) 阶段的一个插件获取或验证认证凭证；[AUTHZ](https://github.com/istio/api/blob/master/extensions/v1alpha1/wasm.proto#L257) 阶段的另一个插件实现你自己定制的授权逻辑，等等。

Istio Wasm 扩展还允许我们生成插件指标，或在多个 Wasm 插件中汇总。该插件提供了一个日志功能，允许我们将日志信息写到 Envoy sidecar。这对 Wasm 插件的调试和开发特别有帮助。

目前的 Istio Wasm API 处于 alpha 阶段，将在未来的 Istio 版本中得到增强和稳定。这包括通过验证签名来安全地验证 Wasm 插件本身，支持用存储为 Kubernetes Secret 的秘密来拉取 Wasm 插件等。

## 进一步阅读和补充资源

在 Tetrate，我们正在努力改善开发者的体验，[tetratelabs/proxy-wasm-golang-sdk](https://github.com/tetratelabs/proxy-wasm-go-sdk/tree/main/examples) 包含本教程使用的 Golang SDK 库。你可以找到更多的例子，如 http [头的操作](https://github.com/tetratelabs/proxy-wasm-go-sdk/blob/main/examples/http_routing/main.go#L70-L80)、样例[授权](https://github.com/tetratelabs/proxy-wasm-go-sdk/tree/main/examples/http_auth_random)、[改变路由](https://github.com/tetratelabs/proxy-wasm-go-sdk/tree/main/examples/http_routing)行为等。

[Tetrate Istio Distro](https://istio.tetratelabs.io/) 是安装、操作和升级 Istio 的最简单方法。

[报名参加 Tetrate 的 Istio Wasm 插件研讨会，向 Istio 中的 Wasm 插件的创造者学习](https://www.tetrate.io/istio-wasm-workshop/)。
