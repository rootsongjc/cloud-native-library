---
title: 将流量发送到使用 HTTPS 的外部主机
weight: 4
---

本文将介绍如何使用 HTTPS 重试和超时将流量发送到外部主机。

在开始之前，请确保你已经：

- 熟悉[TSB 概念](../../../concepts/)
- 安装了 TSB 环境。你可以使用[TSB 演示](../../../setup/self-managed/demo-installation)进行快速安装
- 完成了[TSB 使用快速入门](../../../quickstart)。

## 理解问题

考虑一个通过[ServiceEntry](https://istio.io/latest/docs/reference/config/networking/service-entry/)添加到网格中的外部应用程序。该应用程序监听 HTTPS，因此你将发送的流量预期使用简单的 TLS。

网格内的应用程序客户端将发起 HTTP 请求，并在侧车到外部应用程序主机的过程中将其转换为 HTTPS，例如`www.tetrate.io`。这是由于在 DestinationRule 中定义的出站流量策略实现的。

以下是你需要设置的内容，以实现客户端与外部主机之间的通信：

{{<callout note 直接模式>}}
这仅在使用 TSB 直接模式配置时有效。
{{</callout>}}

首先，为你的 Istio 对象创建一个命名空间：

```
kubectl create ns tetrate
```

创建一个名为`tetrate.yaml`的文件，其中包含以下 ServiceEntry、VirtualService 和 DestinationRule。

```yaml
kind: ServiceEntry
apiVersion: networking.istio.io/v1alpha3
metadata:
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: tetrate
    tsb.tetrate.io/workspace: w1
  name: tetrate
  namespace: tetrate
spec:
  endpoints:
    - address: www.tetrate.io
      ports:
        http: 443
  hosts:
    - www.tetrate.io
  ports:
    - name: http
      number: 80
      protocol: http
  location: MESH_EXTERNAL
  resolution: DNS
---
kind: VirtualService
apiVersion: networking.istio.io/v1alpha3
metadata:
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: tetrate
    tsb.tetrate.io/workspace: w1
    tsb.tetrate.io/trafficGroup: t1
  name: tetrate
  namespace: tetrate
spec:
  hosts:
    - www.tetrate.io
  http:
    - retries:
        attempts: 3
        perTryTimeout: 0.001s
        retryOn: "gateway-error,5xx"
      route:
        - destination:
            host: www.tetrate.io
          weight: 100
      timeout: 0.001s
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: tetrate
    tsb.tetrate.io/workspace: w1
    tsb.tetrate.io/trafficGroup: t1
  name: tetrate
  namespace: tetrate
spec:
  exportTo:
    - "."
  host: www.tetrate.io
  trafficPolicy:
    tls:
      mode: SIMPLE
      sni: tetrate.io
```

使用 kubectl 应用：

```
kubectl apply -f tetrate.yaml
```

重要的是要注意如何将外部主机添加到服务注册表。在上面的 YAML 中，你可以看到单个 ServiceEntry 具有端口 80 作为匹配端口，但你的外部应用程序监听 HTTPS，大多数情况下将是 443（如果你的应用程序监听 8443 或其他端口，你可以更改此端口）。

换句话说，流量被发送到匹配的相同端口，即端口 80，这对于出站 HTTPS 连接是不正确的。为了转发到上游的 443 端口，你需要使 ServiceEntry 中的 endpoints 部分如下所示：

```yaml
endpoints:
   - address: www.tetrate.io
     ports:
       http: 443
```

## 测试

用于测试的客户端可以执行来自具有注入了侧车的客户端的请求，此处将使用[netshoot](https://github.com/nicolaka/netshoot)或[sleep](../../../reference/samples/sleep-service) pod。

首先，发送一个使用 HTTPS 的请求：

```
curl -I https://www.tetrate.io
```

```
HTTP/2 200 
date: Tue, 13 Sep 2022 16:21:37 GMT
content-type: text/html; charset=UTF-8
content-length: 148878
server: Apache
link: <https://www.tetrate.io/wp-json/>; rel="https://api.w.org/", <https://www.tetrate.io/wp-json/wp/v2/pages/29256>; rel="alternate"; type="application/json", <https://www.tetrate.io/>; rel=shortlink
content-security-policy: upgrade-insecure-requests;
x-frame-options: SAMEORIGIN
strict-transport-security: max-age=31536000;includeSubDomains;


x-xss-protection: 1; mode=block
x-content-type-options: nosniff
referrer-policy: no-referrer
x-cacheable: YES:Forced
cache-control: must-revalidate, public, max-age=300, stale-while-revalidate=360, stale-if-error=43200
vary: Accept-Encoding
x-varnish: 107840197 105743030
age: 1441
via: 1.1 varnish (Varnish/6.5)
x-cache: HIT
x-powered-by: DreamPress
accept-ranges: bytes
strict-transport-security: max-age=31536000
```

你可以看到第一个 curl 命令成功了，因为它通过了直通代理（TCP 代理）。这意味着没有从 DestinationRule 或 VirtualService 应用规则。

现在，执行一个请求，而不是发送 HTTPS，这将是一个普通的 HTTP 请求。请记住，侧车将按照我们在 DestinationRule 中指示的方式发起 HTTPS 请求。

```
curl -I http://www.tetrate.io
```

```
HTTP/1.1 504 Gateway Timeout
content-length: 24
content-type: text/plain
date: Tue, 13 Sep 2022 16:24:32 GMT
server: envoy
```

由于在虚拟服务中定义了一个激进的超时，这将返回一个明显的响应，因此它按预期工作。

## 清理

使用相同的 yaml 文件销毁所有资源：

```
kubectl delete -f tetrate.yaml
```

最后，删除命名空间。

```
kubectl delete ns tetrate
```
