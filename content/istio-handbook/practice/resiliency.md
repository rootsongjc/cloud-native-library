---
weight: 60
title: 弹性
date: '2022-05-18T00:00:00+08:00'
type: book
---

为了演示弹性功能，我们将在产品目录服务部署中添加一个名为 `EXTRA_LATENCY` 的环境变量。这个变量会在每次调用服务时注入一个额外的休眠。

通过运行 `kubectl edit deploy productcatalogservice` 来编辑产品目录服务部署。这将打开一个编辑器。滚动到有环境变量的部分，添加 `EXTRA_LATENCY` 环境变量。

```yaml
...
    spec:
      containers:
      - env:
        - name: EXTRA_LATENCY
          value: 6s
...
```

保存并推出编辑器。

如果我们刷新页面，我们会发现页面需要 6 秒的时间来加载）——那是由于我们注入的延迟。

让我们给产品目录服务添加一个 2 秒的超时。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productcatalogservice
spec:
  hosts:
  - productcatalogservice
  http:
  - route:
    - destination:
        host: productcatalogservice
    timeout: 2s
```

将上述 YAML 保存为 `productcatalogservice-timeout.yaml`，并使用 `kubectl apply -f productcatalogservice-timeout.yaml` 创建 VirtualService。

如果我们刷新页面，我们会注意到一个错误信息的出现：

```
rpc error: code = Unavailable desc = upstream request timeout
could not retrieve products
```

该错误表明对产品目录服务的请求超时了。我们修改了服务，增加了 6 秒的延迟，并将超时设置为 2 秒。

让我们定义一个重试策略，有三次尝试，每次尝试的超时为 1 秒。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productcatalogservice
spec:
  hosts:
  - productcatalogservice
  http:
  - route:
    - destination:
        host: productcatalogservice
    retries:
      attempts: 3
      perTryTimeout: 1s
```

由于我们在产品目录服务部署中留下了额外的延迟，我们仍然会看到错误。让我们打开 Zipkin 中的追踪，看看重试策略的作用。

使用 `getmesh istioctl dash zipkin` 来打开 Zipkin 仪表盘。点击 + 按钮，选择 `serviceName` 和 `frontend.default`。为了只得到至少一秒钟的响应（这就是我们的 `perTryTimeout`），选择 `minDuration`，在文本框中输入 1s。点击搜索按钮，显示所有追踪。

点击 **Filter** 按钮，从下拉菜单中选择 `productCatalogService.default`。你应该看到花了 1 秒钟的 trace。这些 trace 对应于我们之前定义的 `perTryTimeout`。

![Zipkin 中的 trace](../../images/008i3skNly1gtedfgzf6kj32uy0t2wkx.jpg "Zipkin 中的 trace")

运行 `kubectl delete vs productcatalogservice` 删除 VirtualService。
