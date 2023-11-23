---
title: Wasm 扩展示例
description: 展示了创建 WASM 扩展并将其分配到层次结构的命令和脚本示例。
weight: 3
---

## 让我们开始

在开始之前，请确保你已经做到了以下几点：
- 熟悉 [TSB 概念](../../../concepts/)
- 安装了 TSB 环境。你可以使用 [TSB 演示](../../../setup/self-managed/demo-installation)进行快速安装。
- 完成了 TSB 的[快速入门](../../../quickstart)。本文假定你已经创建了租户并熟悉工作区和配置组，并且需要将 tctl 配置到你的 TSB 环境。

在这个示例中，将使用`httpbin`作为工作负载。通过 wasm 扩展执行，发送到 Ingress GW 的请求将在 HTTP 响应中添加一个头部。

### 部署`httpbin`服务

请按照[此文档中的所有说明](../../../reference/samples/httpbin)创建`httpbin`服务。

接下来的命令将假定你已经有一个组织=`tetrate`，租户=`tetrate`，工作区=`httpbin`，网关组=`httpbin-gateway`

### 构建和部署 WASM 扩展

让我们使用一个已经存在的 WASM 扩展[代码](https://github.com/tetratelabs/proxy-wasm-go-sdk/tree/main/examples/http_headers)，该扩展将在 HTTP 响应中添加头部。
为了构建 WASM 扩展，下载存储库并按照[这些](https://github.com/tetratelabs/proxy-wasm-go-sdk)说明进行操作：

```bash
make build.example name=http_headers
```

然后需要将其打包为 OCI 镜像：

```bash
docker build . -t docker.io/<your repo>/demo-wasm:0.1 -f examples/wasm-image.Dockerfile --build-arg WASM_BINARY_PATH=examples/http_headers/main.wasm
```

之后，使用适当的命令将镜像推送到你的镜像仓库：

```bash
docker push docker.io/<your repo>/demo-wasm:0.1
```

### 创建 Wasm 扩展

第一步是填写 WASM 扩展目录，添加可用于 TSB 资源的扩展。

必须指定包含扩展的 OCI 镜像（需要使用前缀`oci://`）。

还有其他可选字段，如指向扩展源代码的`source`字段，`priority`字段将定义 WASM 扩展的执行顺序，`allowedIn`用于限制此 WASM 扩展仅分配给特定租户的资源。

最后，字段`config`将设置 WASM 扩展的默认可选配置。每个 WASM 扩展都可以定义此 JSON 格式配置的特定分类。在将 WASM 扩展附加到 TSB 资源时，可以重新定义 config 字段，以设置与默认值不同的值。

要创建扩展，可以使用`UI`、`tctl`命令行或`kubernetes`资源（如果启用了[GitOps](../../gitops/gitops)）。

#### 使用`tctl`

创建一个名为`wasm-extension.yaml`的 yaml 文件，其中包含 WasmExtension 的定义：

```yaml
apiVersion: extension.tsb.tetrate.io/v2
kind: WasmExtension
metadata:
  name: wasm-add-header
  organization: tetrate
spec:
  description: Extension to modify the headers
  image: oci://docker.io/<your repo>/demo-wasm:0.1
  source: https://github.com/tetratelabs/proxy-wasm-go-sdk/tree/main/examples/http_headers
  priority: 1
  config:
    header: x-wasm-header
    value: tsb-header
```

在 TSB 上应用定义：
```bash
tctl apply -f wasm-extension.yaml
```

#### 使用 UI

单击“Wasm 扩展”菜单以打开 WasmExtension 目录，然后单击右上角的“创建”按钮。填写扩展字段，然后单击底部的“创建”按钮。注意，配置必须采用 JSON 格式。

![WasmExtension 目录 UI](../../../assets/howto/wasm/wasm-ui-create.png)

可以有多个扩展，每个扩展都有不同的名称，并且可以分配给多个资源。

下一步是将此 WASM 扩展分配给资源，以便影响所需的工作负载。在我们的示例中，选择 IngressGateway 作为资源，以便在网关接收到的每个请求上执行 WASM 扩展。

### 在 IngressGateway 上创建附件

#### 使用`tctl`

创建一个名为`ingress-gateway.yaml`的文件，其中包含将包含[WASM 附件](../../../refs/tsb/types/v2/types#wasmextensionattachment)的[IngressGateway](../../../refs/tsb/gateway/v2/ingress-gateway)的定义：

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: ingress-gw
  group: httpbin-gateway
  workspace: httpbin
  tenant: tetrate
  organization: tetrate
spec:
  workloadSelector:
    namespace: httpbin
    labels:
      app: httpbin-ingress-gateway
  http:
    - name: httpbin
      port: 443
      hostname: "httpbin.tetrate.io"
      routing:
        rules:
          - route:
              host: "httpbin/httpbin.httpbin.svc.cluster.local"
  extension:
    - fqn: "organizations/tetrate/extensions/wasm-add-header"
      config:
        header: x-wasm-header
        value: igw-tsb
```

在 TSB 上应用它：
```
tctl apply -f ingress-gateway.yaml
```

#### 使用 UI

{{<callout note "WasmExtension 的权限">}}
你需要授予团队或用户具有`READ` `WasmExtension`权限的角色，以便他们可以使用 TSB UI 来附加 Wasm 扩展。
{{</callout>}}

你可以使用 UI 将 WASM 扩展附加到 IngressGateway。转到 IngressGateway 配置 UI，然后单击“添加新的 WASM 扩展”。选择要使用的扩展

并指定配置。注意，配置必须采用 JSON 格式。

![在 Ingress Gateway 中附加扩展](../../../assets/howto/wasm/wasm-ui-attach.png)

### 测试

```bash
export GATEWAY_IP=$(kubectl -n httpbin get service httpbin-ingress-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://httpbin.tetrate.io:443 -kv --connect-to httpbin.tetrate.io:443:$GATEWAY_IP:443
```

你应该会看到类似于以下输出：

```
* Connecting to hostname: 35.230.60.29
* Connecting to port: 443
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0*   Trying 35.230.60.29:443...
* Connected to 35.230.60.29 (35.230.60.29) port 443 (#0)
> GET / HTTP/1.1
> Host: httpbin.tetrate.io:443
> User-Agent: curl/7.79.1
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< server: istio-envoy
< date: Wed, 09 Nov 2022 14:35:13 GMT
< content-type: text/html; charset=utf-8
< content-length: 9593
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 54
< x-proxy-wasm-go-sdk-example: http_headers
< x-wasm-header: igw-tsb
<
{ [9593 bytes data]
100  9593  100  9593    0     0  22866      0 --:--:-- --:--:-- --:--:-- 23171
* Connection #0 to host 35.230.60.29 left intact
```

在响应中，你可以看到`x-wasm-header`已根据 WASM 扩展的配置添加。这是通过执行 WASM 扩展的连接到网关工作负载来完成的。

## 它在 Istio / Envoy 中是如何结束的？

这些 WASM 分配将影响由 TSB 组件处理的工作负载，并最终转化为[Istio WasmPlugins](https://istio.io/latest/docs/reference/config/proxy_extensions/wasm-plugin/)，这些插件由 Istio 处理并转化为 Envoy 过滤器配置在 envoy 代理中执行，其执行顺序取决于插件的阶段和优先级。
一旦配置到达 Envoy 代理，WASM 扩展将成为过滤器链的一部分，它们的位置将取决于它们的阶段，而优先级将确定它们在同一阶段中与其他 WASM 扩展的位置。