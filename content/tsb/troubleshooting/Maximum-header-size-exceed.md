---
title: 请求头大小超限
weight: 6
---

本文将介绍在从 Istio 入口网关或边车转发到应用程序时，TSB 和 Istio 代理如何处理标头。

在开始之前，请确保你已经：
- 熟悉[TSB 概念](../../concepts/)
- 安装了 TSB 环境。你可以使用[TSB 演示](../../setup/self-managed/demo-installation)进行快速安装
- 完成了[TSB 使用快速入门](../quickstart)。
- 安装了示例应用程序[httpbin](../../reference/samples/httpbin)。

## Envoy（istio-proxy）中的请求标头大小

[Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto)或 istio-proxy 可以处理相当大的标头。传入连接的默认最大请求标头大小为 60 KiB。

在这种情况下，对于大多数应用程序来说，这不会成为问题，并且传入连接的请求标头将通过 istio-proxy 代理。但是，根据每个 Web 服务器的标头大小配置，你的应用程序可能会有限制。

例如：
在[Spring Boot 2](https://www.baeldung.com/spring-boot-max-http-header-size)和[Gunicorn](https://docs.gunicorn.org/en/stable/settings.html#limit-request-field-size)中，默认的最大标头大小为 8 KiB。如果需要，你可以覆盖默认设置。

## 调试请求标头大小

对于此实验，你需要在集群中部署[httpbin](../../reference/samples/httpbin)示例应用程序。你将执行两个请求，一个请求的标头大小低于最大值，另一个请求的标头大小超出应用程序容器的限制。

### 低于最大值的标头

你的标头可以是任何内容，只需确保低于 8 KiB，你可以将其导出为变量并执行请求：

```bash
curl -k  https://httpbin.example.io/response-headers -X POST -H "X-MyHeader: $SMALL" -sI
HTTP/2 200 
server: istio-envoy
date: Wed, 19 Oct 2022 20:13:49 GMT
content-type: application/json
content-length: 68
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 5
```

### 超出最大值的标头

现在，使用可以超出 8 KiB 的标头执行请求：

```bash
curl -k  https://httpbin.example.io/response-headers -X POST -H "X-MyHeader: $LONG" -sI
HTTP/2 400 
content-type: text/html
content-length: 189
x-envoy-upstream-service-time: 6
date: Wed, 19 Oct 2022 20:17:37 GMT
server: istio-envoy
```

如果请求标头超过最大标头大小，你将收到一个 HTTP 400 错误，表示坏请求。

## 修改 istio-proxy 中的标头大小

正如你在上面学到的，你可以在各种 Web 服务器中限制标头大小。你可以在 istio-proxy 中进行相同的修改。

默认的标头大小应该足够，或者你可能希望减小默认大小。
### 在 istio-proxy 中减小默认标头大小

为了减小默认请求标头的大小，你需要创建一个[Envoyfilter](https://istio.io/latest/docs/reference/config/networking/envoy-filter/)，允许你修改 istio-proxy 的配置。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: max-request-headers
  namespace: istio-system
spec:
  configPatches:
  - applyTo: NETWORK_FILTER # http connection manager is a filter in Envoy
    match:
      context: ANY
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
    patch:
      operation: MERGE
      value:
        typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager"
          max_request_headers_kb: 10
```

将此应用于你的集群后，请再次尝试请求，一个标头较小，另一个标头较大。

### 在 istio-proxy 中低于最大值的标头

```bash
curl -k  https://httpbin.example.io/response-headers -X POST -H "X-MyHeader: $SMALL" -sI
HTTP/2 200 
server: istio-envoy
date: Wed, 19 Oct 2022 20:36:43 GMT
content-type: application/json
content-length: 68
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 5
```

由于标头低于 10 KiB 的最大值，你可以看到请求成功。

### 在 istio-proxy 中超出最大值的标头

```bash
curl -k  https://httpbin.example.io/response-headers -X POST -H "X-MyHeader: $LONG" -sI
```

你可以从 curl 中删除-s 标志并查看输出。

```bash
curl -k  https://httpbin.example.io/response-headers -X POST -H "X-MyHeader: $LONG" -I
curl: (92) HTTP/2 stream 0 was not closed cleanly: INTERNAL_ERROR (err 2)
```

请求没有返回任何内容，只有一个错误。你可以在日志中查看发生了什么。

```bash
kubectl logs $GWPOD -n tier1

[2022-10-19T20:39:58.081Z] "- - HTTP/2" 0 - http2.too_many_headers - "-" 0 0 0 - "-" "-" "-" "-" "-" - - 10.211.129.34:

8443 10.240.0.38:63077 httpbin.example.io -
```