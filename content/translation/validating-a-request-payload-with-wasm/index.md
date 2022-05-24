---
title: "使用 WebAssembly 验证请求负载"
summary: "本文是一个使用 Go 语言开发 Wasm 插件验证请求负载，并将其部署到 Istio 或 Envoy 上的教程。"
authors: ["Liam Byrne"]
categories: ["Service Mesh"]
tags: ["wasm","istio","envoy"]
# Date published
date: '2022-05-13T13:00:00+08:00'

# Date updated
lastmod: '2022-05-13T21:12:00+08:00'

# Is this an unpublished draft?
draft: false

# Show this page in the Featured widget?
featured: false

image:
  caption: '© [**jimmysong.io**](https://jimmysong.io)'
  focal_point: 'right'
  placement: 2
  preview_only: false

links:
  - icon: globe
    icon_pack: fa
    name: 原文
    url: https://www.tetrate.io/blog/validating-a-request-payload-with-wasm/
---

### 什么是 Wasm 插件？

你可以使用 Wasm 插件在数据路径上添加自定义代码，轻松地扩展服务网格的功能。可以用你选择的语言编写插件。目前，有 AssemblyScript（TypeScript-ish）、C++、Rust、Zig 和 Go 语言的 Proxy-Wasm SDK。

在这篇博文中，我们描述了如何使用 Wasm 插件来验证一个请求的有效载荷。这是 Wasm 与 Istio 的一个重要用例，也是你可以使用 Wasm 扩展 Istio 的许多方法的一个例子。您可能有兴趣阅读我们关于[在 Istio 中使用 Wasm 的博文](https://www.tetrate.io/blog/category/wasm/)，并观看我们关于在 Istio 和 Envoy 中使用 Wasm 的免费研讨会的录音。

### 何时使用 Wasm 插件？

当你需要添加 Envoy 或 Istio 不支持的自定义功能时，你应该使用 Wasm 插件。使用 Wasm 插件来添加自定义验证、认证、日志或管理配额。

在这个例子中，我们将构建和运行一个 Wasm 插件，验证请求 body 是 JSON，并包含两个必要的键 ——`id` 和 `token`。

### 编写 Wasm 插件

这个示例使用 [tinygo](https://tinygo.org/) 来编译成 Wasm。确保你已经安装了 [tinygo 编译器](https://tinygo.org/getting-started/install/)。

#### 配置 Wasm 上下文

首先配置 Wasm 上下文，这样 tinygo 文件才能操作 HTTP 请求：

```go
package main

import (
	"github.com/tetratelabs/proxy-wasm-go-sdk/proxywasm"
	"github.com/tetratelabs/proxy-wasm-go-sdk/proxywasm/types"
	"github.com/tidwall/gjson"
)

func main() {
	// SetVMContext 是配置整个 Wasm VM 的入口。请确保该入口在 main 函数中调用，否则 VM 将启动失败。
	proxywasm.SetVMContext(&vmContext{})
}

// vmContext 实现 proxy-wasm-go SDK 的 types.VMContext 接口。
type vmContext struct {
	// 在这里嵌入默认的虚拟机环境，我们不需要实现所有方法。
	types.DefaultVMContext
}

// 复写 types.DefaultVMContext
func (*vmContext) NewPluginContext(contextID uint32) types.PluginContext {
	return &pluginContext{}
}

// pluginContext 实现 proxy-wasm-go SDK 的 types.PluginContext 接口
type pluginContext struct {
	// 在这里侵入默认的插件上下文，我们不需要实现所有方法。
	types.DefaultPluginContext
}

// 复写 types.DefaultPluginContext
func (ctx *pluginContext) NewHttpContext(contextID uint32) types.HttpContext {
	return &payloadValidationContext{}
}

// payloadValidationContext 实现 proxy-wasm-go SDK 的 types.HttpContext 接口
type payloadValidationContext struct {
	// 在这里嵌入默认的根 http 上下文，我们不需要实现所有方法。
	types.DefaultHttpContext
	totalRequestBodySize int
}
```

#### 验证负载

内容类型头是通过实现 `OnHttpRequestHeaders` 来验证的，一旦从客户端收到请求头，就会调用该头。

`proxywasm.SendHttpResponse` 用于响应 403 forbidden 的错误代码和信息，如果内容类型丢失的话。

```go
func (ctx *payloadValidationContext) OnHttpRequestHeaders(numHeaders int, endOfStream bool) types.Action {
	contentType, err := proxywasm.GetHttpRequestHeader("content-type")
	if err != nil || contentType != "application/json" {
		// 如果 header 没有期望的 content type，返回 403 响应
		if err := proxywasm.SendHttpResponse(403, nil, []byte("content-type must be provided"), -1); err != nil {
			proxywasm.LogErrorf("failed to send the 403 response: %v", err)
		}
		// 终止 ActionPause 对流量的进一步处理
		return types.ActionPause
	}

	// ActionContinue 让主机继续处理 body
	return types.ActionContinue
}
```

请求主体是通过实现 `OnHttpRequestBody` 来验证的，每次从客户端接收到请求的一个块时，都会调用该请求。这是通过等待直到 `endOfStream` 为真并记录所有收到的块的总大小来完成的。一旦收到整个主体，就会使用 `proxywasm.GetHttpRequestBody` 读取，然后可以使用 golang 进行验证。

这个例子使用 `gjson`，因为 tinygo 不支持 golang 的默认 JSON 库。它检查有效载荷是否是有效的 JSON，以及键 `id` 和 `token` 是否存在。

```go
func (ctx *payloadValidationContext) OnHttpRequestBody(bodySize int, endOfStream bool) types.Action {
	ctx.totalRequestBodySize += bodySize
	if !endOfStream {
		// OnHttpRequestBody 等待收到到 body 的全部才开始处理。
		return types.ActionPause
	}

	body, err := proxywasm.GetHttpRequestBody(0, ctx.totalRequestBodySize)
	if err != nil {
		proxywasm.LogErrorf("failed to get request body: %v", err)
		return types.ActionContinue
	}

	if !validatePayload(body) {
		// 如果验证失败，发送 403 响应。
		if err := proxywasm.SendHttpResponse(403, nil, []byte("invalid payload"), -1); err != nil {
			proxywasm.LogErrorf("failed to send the 403 response: %v", err)
		}
		// 终止流量
		return types.ActionPause
	}

	return types.ActionContinue
}

// validatePayload 验证给定的 json 负载
// 注意该函数使用 gjson 解析 json，因为 TinyGo 不支持 encoding/json
func validatePayload(body []byte) bool {
	if !gjson.ValidBytes(body) {
		proxywasm.LogErrorf("body is not a valid json: %v", body)
		return false
	}
	jsonData := gjson.ParseBytes(body)

	// 验证 json。检查示例中是否存在必须的键
	for _, requiredKey := range []string{"id", "token"} {
		if !jsonData.Get(requiredKey).Exists() {
			proxywasm.LogErrorf("required key (%v) is missing: %v", requiredKey, jsonData)
			return false
		}
	}

	return true
}
```

#### 编译成 Wasm

使用 tinygo 编译器编译成 Wasm：

```bash
tinygo build -o main.wasm -scheduler=none -target=wasi main.go
```

### 部署 Wasm 插件

#### 打包到 Docker 中部署到 Envoy

对于开发，这个插件可以在 Docker 中部署到 Envoy。下面的 Envoy 配置文件将设置 Envoy 监听 `localhost:18000`，运行所提供的 Wasm 插件，并在成功后响应 HTTP 200 和文本 `hello from server`。突出显示的部分是配置 Wasm 插件。

```yaml
static_resources:
  listeners:
    - name: main
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 18000
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
                          route:
                            cluster: web_service
 
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
                                filename: "./main.wasm"
                  - name: envoy.filters.http.router

    - name: staticreply
      address:
        socket_address:
          address: 127.0.0.1
          port_value: 8099
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
                              inline_string: "hello from the server\n"
                http_filters:
                  - name: envoy.filters.http.router
                    typed_config: {}

  clusters:
    - name: web_service
      connect_timeout: 0.25s
      type: STATIC
      lb_policy: ROUND_ROBIN
      load_assignment:
        cluster_name: mock_service
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: 127.0.0.1
                      port_value: 8099

admin:
  access_log_path: "/dev/null"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 8001
```

运行 Docker 容器：

```bash
docker run --rm -p 18000:18000 \
  -v $PWD/envoy.yaml:/envoy.yaml \
  -v $PWD/main.wasm:/main.wasm \
  --entrypoint envoy containers.istio.tetratelabs.com/proxyv2:1.9.7-tetrate-v0 \
  -l debug \
  -c /envoy.yaml
```

通过 curl 测试。首先，没有设置内容类型，将返回 403：

```bash
% curl -i -X POST localhost:18000
HTTP/1.1 403 Forbidden
content-length: 29
content-type: text/plain
date: Sun, 13 Mar 2022 22:13:37 GMT
server: envoy

content-type must be provided
```

然后，请求 body 不是 JSON，同样返回 403。

```bash
% curl -i -X POST localhost:18000 -H 'Content-Type: application/json' --data 'not JSON'
HTTP/1.1 403 Forbidden
content-length: 15
content-type: text/plain
date: Sun, 13 Mar 2022 22:15:53 GMT
server: envoy

invalid payload
```

JSON 负载中没有 `token` 字段，还是返回 403。

```bash
% curl -i -X POST localhost:18000 -H 'Content-Type: application/json' --data '{"id": "xxx"}'
HTTP/1.1 403 Forbidden
content-length: 15
content-type: text/plain
date: Sun, 13 Mar 2022 22:17:18 GMT
server: envoy

invalid payload
```

当 id 和 token 字段都被提供时，将返回一个成功的响应。

```bash
% curl -i -X POST localhost:18000 -H 'Content-Type: application/json' --data '{"id": "xxx", "token": "xxx", "anotherField": "yyy"}'
HTTP/1.1 200 OK
content-length: 22
content-type: text/plain
date: Sun, 13 Mar 2022 22:18:37 GMT
server: envoy
x-envoy-upstream-service-time: 1

hello from the server
```

### 部署到 Istio

#### 部署 Istio 和 httpbin 示例应用

我们使用 [kind](https://kind.sigs.k8s.io/) 来创建测试集群，对于其他方式创建的 Kubernetes 集群同样适用。

```bash
kind create cluster
```

集群创建完毕后，安装 Istio，我们使用的是 Istio 1.12.3，安装 [Istio httpbin 示例应用](https://github.com/istio/istio/tree/master/samples/httpbin)。

```bash
istioctl install --set profile=demo
kubectl label namespace default istio-injection=enabled
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.12/samples/httpbin/httpbin.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.12/samples/httpbin/httpbin-gateway.yaml
```

在另一个终端中，将 Ingress 网关的 80 端口转发到你本地机器的 8080 端口上。

```bash
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
```

发送 curl 请求，检查服务是否正常启动，你应该应该看到成功的响应。

```bash
curl -X POST -i http://localhost:8080/post
```

有两种方式在 Istio 中安装 Wasm 模块：

1. 对于 Istio 1.12 和更新版本的 Istio，支持 [WasmPlugin](https://istio.io/latest/docs/reference/config/proxy_extensions/wasm-plugin/) 资源
2. 对于老版本的 Istio，可以使用 [EnvoyFilter](https://istio.io/latest/docs/reference/config/networking/envoy-filter/)

#### 使用 WasmPlugin 安装

WasmPlugin 资源从镜像仓库中提取 wasm 模块。因此，让我们首先为我们的 wasm 模块构建并推送一个 Docker 镜像。下面的 Docker 文件允许从你的 wasm 模块建立一个 Docker 镜像。

```Docker
FROM scratch

COPY main.wasm ./
```

构建镜像，推送到镜像仓库。

```bash
export HUB=your_registry # e.g. docker.io/tetrate
docker build . -t $HUB/json-validation:v1
docker push $HUB/json-validation:v1
```

现在我们创建 [WasmPlugin](https://istio.io/latest/docs/reference/config/proxy_extensions/wasm-plugin/) 资源。这将适用于所有通过 Istio Ingress 网关暴露的路由，并对其应用我们的验证。确保你把 `{your_registry}` 替换为你上传 wasm 镜像的镜像仓库。

```yaml
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: json-validation
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  url: oci://{your_registry}/json-validation:v3
  imagePullPolicy: IfNotPresent
  phase: AUTHN
```

#### 使用 EnvoyFilter 安装

为了使用 EnvoyFilter，我们创建一个包含已编译的 Wasm 插件的 ConfigMap，将 ConfigMap 挂载到网关 pod 中，然后通过 EnvoyFilter 配置 Envoy，从本地文件加载 Wasm 插件。这种方法的限制是，更大和更复杂的 Wasm 模块可能超出 ConfigMap 1MB 的大小限制。

首先，创建一个包含编译好的 Wasm 模块的 ConfigMap：

```bash
kubectl -n istio-system create configmap wasm-plugins --from-file=main.wasm
```

然后在 Istio Ingress 网关部署中打补丁，挂载这个 ConfigMap。

```bash
kubectl -n istio-system patch deployment istio-ingressgateway --patch='
spec:
  template:
    spec:
      containers:
        - name: istio-proxy
          volumeMounts:
            - name: wasm-plugins
              mountPath: /var/local/lib/wasm-plugins
              readOnly: true
      volumes:
        - name: wasm-plugins
          configMap:
            name: wasm-plugins'
```

现在 Wasm 模块就挂载到了网关 Pod 中，应用这个 EnvoyFilter。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: json-validation
  namespace: istio-system
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: GATEWAY
    patch:
      operation: INSERT_BEFORE
      value:
        name: json-validation
        typed_config:
          '@type': type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
          config:
            vm_config:
              code:
                local:
                  filename: /var/local/lib/wasm-plugins/main.wasm
              runtime: envoy.wasm.runtime.v8
              vm_id: json-validation
```

#### 测试 Wasm 插件

重复之前的 curl 请求。

```bash
% curl -X POST -i http://localhost:8080/post
HTTP/1.1 403 Forbidden
content-length: 29
content-type: text/plain
date: Tue, 15 Mar 2022 22:04:35 GMT
server: istio-envoy

content-type must be provided
```

如果提供了内容类型和 json 负载的话，请求将会成功。

```bash
curl -i http://localhost:8080/post  -H 'Content-Type: application/json' --data '{"id": "xxx", "token": "xxx"}'
```

### 让必填字段可配置

与其在编译的 golang 代码中硬编码所需的 JSON 字段，不如允许通过 Envoy 配置来配置这些字段。

当在 Docker 中运行 Envoy 时，可以通过向之前创建的 Wasm `http_filter` 添加配置来实现。

```yaml
  http_filters:
                  - name: envoy.filters.http.wasm
                    typed_config:
                      "@type": type.googleapis.com/udpa.type.v1.TypedStruct
                      type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
                      value:
                        config:
                          configuration:
                            "@type": type.googleapis.com/google.protobuf.StringValue
                            value: |
                                                            { "requiredKeys": ["id", "token"] }
                          vm_config:
                            runtime: "envoy.wasm.runtime.v8"
                            code:
                              local:
                                filename: "./main.wasm"
```

当使用 WasmPlugin，在 `pluginConfig` 字段中配置。

```yaml
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: json-validation
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  url: oci://{your_registry}/json-validation:v3
  imagePullPolicy: IfNotPresent
  phase: AUTHN
  pluginConfig:
    requiredKeys: ["id", "token"]
```

最后，当使用 EnvoyFilter 时，将它添加到 filter 配置中。

```yaml
   value:
        name: json-validation
        typed_config:
          '@type': type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
          config:
            configuration:
              "@type": type.googleapis.com/google.protobuf.StringValue
              value: |
                                { "requiredKeys": ["id", "token"] }
            vm_config:
              code:
                local:
                  filename: /var/local/lib/wasm-plugins/main.wasm
              runtime: envoy.wasm.runtime.v8
              vm_id: json-validation
```

在代码中，实现 `OnPluginStart`，使用 `proxywasm.GetPluginConfiguration` 加载。

```go
// pluginContext 实现 proxy-wasm-go SDK 中的 types.PluginContext 接口
type pluginContext struct {
	// 在这里嵌入默认的 plugin 上下文，这样就不用实现所有方法
	types.DefaultPluginContext
	configuration *pluginConfiguration
}

// pluginConfiguration 代表这个 wasm 插件中的示例配置
type pluginConfiguration struct {
	// 示例配置字段，插件将验证 json 负载中是否存在这些字段。
	requiredKeys []string
}

// 复写 types.DefaultPluginContext
func (ctx *pluginContext) OnPluginStart(pluginConfigurationSize int) types.OnPluginStartStatus {
	data, err := proxywasm.GetPluginConfiguration()
	if err != nil {
		proxywasm.LogCriticalf("error reading plugin configuration: %v", err)
		return types.OnPluginStartStatusFailed
	}
	config, err := parsePluginConfiguration(data)
	if err != nil {
		proxywasm.LogCriticalf("error parsing plugin configuration: %v", err)
		return types.OnPluginStartStatusFailed
	}
	ctx.configuration = config
	return types.OnPluginStartStatusOK
}

// parsePluginConfiguration 解析 json 插件配置并返回 pluginConfiguration
// 注意使用 gjson 解析 json，因为 TinyGo 不支持 encoding/json
// 你也可以使用 https://github.com/mailru/easyjson，支持解析为结构体
func parsePluginConfiguration(data []byte) (*pluginConfiguration, error) {
	config := &pluginConfiguration{}
	if !gjson.ValidBytes(data) {
		return nil, fmt.Errorf("the plugin configuration is not a valid json: %v", data)
	}

	jsonData := gjson.ParseBytes(data)
	requiredKeys := jsonData.Get("requiredKeys").Array()
	for _, requiredKey := range requiredKeys {
		config.requiredKeys = append(config.requiredKeys, requiredKey.Str)
	}

	return config, nil
}
```

现在它们被包含在 `pluginConfiguration` 结构中，它们可以像其他字段一样在验证过程中被使用。

```go
// validatePayload 验证给定的 json 负载
// 注意该函数使用 gjson 解析 json，因为 TinyGo 不支持 encoding/json
func (ctx *payloadValidationContext) validatePayload(body []byte) bool {
	if !gjson.ValidBytes(body) {
		proxywasm.LogErrorf("body is not a valid json: %v", body)
		return false
	}
	jsonData := gjson.ParseBytes(body)

	// 验证 json。检查示例中是否包含必须的键。
	// 必须的键通过插件配置。
	for _, requiredKey := range ctx.requiredKeys {
		if !jsonData.Get(requiredKey).Exists() {
			proxywasm.LogErrorf("required key (%v) is missing: %v", requiredKey, jsonData)
			return false
		}
	}

	return true
}
```

然后可以使用与之前相同的命令对其进行编译和测试。

### 总结

总而言之，要在 Istio 1.12 和更新的版本上使用 Wasm 插件，需要三个步骤：

1. 在你选择的语言中实现插件的功能。我在本教程中使用 Golang。
2. 编译 Wasm 插件并推送到镜像仓库。
3. 配置 Istio 以加载和使用镜像仓库中的插件。

该教程还详细介绍了如何使用 Docker 在 Envoy 容器中运行 Wasm 插件，以加快开发速度，以及如何将其部署到旧的 Istio 版本。
