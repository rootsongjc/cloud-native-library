---
title: 多重传输编码块处理
description: TSB 如何处理请求和响应标头中的多重“transfer-encoding:chunked”，以及如何确定问题是源自还是目的地。
weight: 7
---

本文描述了当标头中包含多个`transfer-encoding:chunked`时，TSB 将如何处理请求/响应，并帮助你确定问题是来自源还是目标。

我们建议解决此问题的方法是确保请求头和响应头中都只有一个`transfer-encoding:chunked`，否则 Envoy 将拒绝请求。

在开始之前，请确保你已经：
- 熟悉[TSB 概念](../../concepts/)
- 安装[TSB 演示](../../setup/self-managed/demo-installation)环境
- 部署[Istio Bookinfo](../../quickstart/deploy-sample-app)示例应用程序

注意：对于响应部分，我们在这里使用的应用程序特意生成了多个`transfer-encoding:chunked`标头，仅用于文档目的。

我们经常看到请求/响应的标头包含多个`transfer-encoding:chunked`，这不是有效的标头，因为 Envoy 会拒绝这种请求。在我们安装的 bookinfo 应用程序中，我们可以更深入地看一看当 Envoy 拒绝简单请求时，它将以特定的错误代码拒绝。

## 带有"Transfer-Encoding: chunked,chunked"的请求头

对于我们的 bookinfo 应用程序，我们将使用 curl 创建一个简单的请求，发送多个`transfer-encoding:chunked`，并观察 envoy 网关的响应。

```bash
$ curl  -kv "http://bookinfo.tetrate.com/productpage" -H "Transfer-Encoding: chunked" -H "Transfer-Encoding: chunked" 
[ ... ]
> GET /productpage HTTP/1.1
> Host: bookinfo.tetrate.com
> User-Agent: curl/7.79.1
> Accept: */*
> Transfer-Encoding: chunked
> Transfer-Encoding: chunked
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 501 Not Implemented
< content-length: 15
< content-type: text/plain
< date: Tue, 13 Sep 2022 11:08:56 GMT
< server: istio-envoy
< connection: close
< 
* Closing connection 0
Not Implemented%
```

同时，网关 envoy 日志显示以下片段以及错误代码为`501 DPE（下游协议错误）`的失败。

```
kubectl logs ${GWPOD} -n bookinfo 
[2022-09-07T08:17:38.936Z] "- - HTTP/1.1" 501 DPE http1.invalid_transfer_encoding - "-" 0 15 0 - "-" "-" "-" "-" "-" - - 10.0.2.20:8080 10.128.0.74:23365 - -
```

## 带有"Transfer-Encoding: chunked,chunked"的响应头

响应头可以在应用程序内部进行操作，并可能触发多个块。在这些情况下，该应用程序的 envoy sidecar 将拒绝响应。为了演示响应，我们使用了一个简单的应用程序，它将生成多个传输块作为默认行为，我们将从[Debug-container](../debug-container)发送 curl 请求，使用默认值如下所示。

```bash
$ curl -v http://transfer:8080/test
[ ... ]
> GET /test HTTP/1.1
> Host: transfer:8080
> User-Agent: curl/7.83.1
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 502 Bad Gateway
< content-length: 87
< content-type: text/plain
< date: Tue, 13 Sep 2022 11:17:13 GMT
< server: envoy
< x-envoy-upstream-service-time: 2
< 
* Connection #0 to host transfer left intact
upstream connect error or disconnect/reset before headers. reset reason: protocol error/ 
```

当我们查看 sidecar envoy 日志时，我们可以看到拒绝的详细信息，错误消息为`502 UPE（上游协议错误）`

```
kubectl logs transfer-58c6c67c56-d8wzk  -n test 
[2022-09-13T11:17:13.471Z] "GET /test HTTP/1.1" 502 UPE upstream_reset_before_response_started{protocol_error} - "-" 0 87 1

 - "-" "curl/7.83.1" "fbcd5bff-1981-40a5-a2c8-fd6133161976" "transfer:8080" "10.0.2.7:8080" inbound|8080|| 127.0.0.6:53799 10.0.2.7:8080 10.0.0.21:59960 outbound_.8080_._.transfer.test.svc.cluster.local default
```

如果我们为应用程序的 sidecar 启用调试日志，我们可以看到详细错误信息如下：

```
2022-09-13T12:46:48.497388Z     debug   envoy client    [C2912] Error dispatching received data: http/1.1 protocol error: unsupported transfer encoding
```
