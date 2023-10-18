---
title: Ingress Gateway故障排除
描述: 在TSB中排查入口路由问题。
weight: 2
---

无论我们是使用TSB的`IngressGateway`还是Istio的`Gateway`和`VirtualService`资源将外部流量路由到我们的服务，都可能会遇到我们暴露的路由问题。在本文档中，我们将展示一些最常见的故障场景以及如何进行故障排查。

## 缺少配置

首先要检查的一件事是我们在TSB中创建的配置是否存在于目标集群中。例如，在这种情况下：

```
$ curl -vk http://helloworld.tetrate.io/hello
[ ... ]
> GET /hello HTTP/1.1
> Host: helloworld.tetrate.io
> User-Agent: curl/7.81.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< date: Wed, 27 Apr 2022 14:46:41 GMT
< server: istio-envoy
< content-length: 0
<
```

我们得到了一个404的HTTP响应（未找到），对于刚刚配置的入口路由，这是一个问题。要检查的第一件事是[资源状态](./configuration_status)。确保您的入口资源的状态为`ACCEPTED`。

{{<callout note "注意 404">}}
Envoy返回的404响应不包含正文，如上所示。如果您看到404和一些“未找到”的消息，通常表示路由配置正确，但您正在访问错误的URL。例如：

```
$ curl -vk https://httpbin.tetrate.io/foobar
[ ... ]
< HTTP/2 404
< server: istio-envoy
< date: Wed, 27 Apr 2022 14:53:32 GMT
< content-type: text/html
< content-length: 233
< access-control-allow-origin: *
< access-control-allow-credentials: true
< x-envoy-upstream-service-time: 47
<
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server.  If you entered the URL manually please check your spelling and try again.</p>
```

您在那里看到的HTML代码是应用程序本身发送的，这意味着路由正常工作，但您正在访问错误的路径。
{{</callout>}}

```
$ tctl experimental status workspace hello --tenant tetrate
NAME     STATUS    LAST EVENT    MESSAGE                                                                                                                  
hello    FAILED                  The following children resources have issues: organizations/tetrate/tenants/tetrate/workspaces/hello/gatewaygroups/hello   
```

例如，上面的输出表明`hello`工作区中的某些内容有问题，具体来说是名为`hello`的网关组中。

```
$ tctl experimental status gatewaygroup hello --workspace hello --tenant tetrate
NAME     STATUS    LAST EVENT    MESSAGE                                                                                                                                        
hello    FAILED                  The following children resources have issues: organizations/tetrate/tenants/tetrate/workspaces/hello/gatewaygroups/hello/virtualservices/hello    
```

并且在为此路由部署的`VirtualService`中似乎存在问题。

```
$ tctl experimental status virtualservice hello --gatewaygroup hello --workspace hello --tenant tetrate
NAME     STATUS    LAST EVENT    MESSAGE                                                                                                                                                          
hello    FAILED    MPC_FAILED    no gateway object found for reference "helloworld/hellogw" in "organizations/tetrate/tenants/tetrate/workspaces/hello/gatewaygroups/hello/virtualservices/hello"
```

此时我们可以确定缺少配置的原因实际上是与配置本身有关的问题，因此可以进行修复以使其部署，从而修复我们之前看到的404错误。状态对象中的错误消息将引导您找到错误所在。

## Envoy访问日志

{{<callout note "X-REQUEST-ID HEADER">}}
您可以发送 `X-REQUEST-ID` 头以关联日志中的请求。您可以使用任意随机字符串作为请求ID。Envoy代理将在其创建的每个日志语句中包含该ID。以下是示例：

```bash
$ curl -vk -H "X-REQUEST-ID:4e3e3e04-6509-43d4-9a97-52b7b2cea0e8" http://helloworld.tetrate.io/hello
```

{{</callout>}}

TSB配置了Istio以便Envoy在`stdout`中打印访问日志，并仅对特定模块的错误进行记录。如果从`istiod`接收到的配置无效，您将会看到一条消息，但对于失败的请求，您将会看到一个带有一些标志的`503`响应，这些标志在[Envoy文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage)中有说明（请参阅`%RESPONSE_FLAGS%`部分）。让我们看看以下示例。

```
$ curl -vk https://httpbin.tetrate.io/foobar
[ ... ]
< HTTP/2 503
< content-length: 19
< content-type: text/plain
< date: Wed, 27 Apr 2022 15:02:19 GMT
< server: istio-envoy
<
no healthy upstream
```

如果我们查看这个请求的访问日志，我们可以看到：

```
[2022-04-27T15:02:20.472Z] "GET /foobar HTTP/2" 503 UH no_healthy_upstream - "-" 0 19 0 - "X.X.X.X" "curl/7.81.0" "55fef75a-70e5-449f-ad01-cd34960f465c" "httpbin.tetrate.io" "-" outbound|8000||httpbin.httpbin.svc.cluster.local - 10.16.0.20:8443 X.X.X.X:36009 httpbin.tetrate.io httpbin
```

好的，我们可以看到日志的时间戳，请求的一些HTTP信息（方法、路径、协议），然后可以看到响应代码`503`，后跟标志`UH`，与我们在响应中得到的消息相匹配，说明没有可用的上游服务。当前用于此入口路由的`VirtualService`是：

```yaml
kind: VirtualService
metadata:
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: tetrate
    xcp.tetrate.io/workspace: httpbin
    xcp.tetrate.io/gatewayGroup: httpbin
  name: httpbin
  namespace: httpbin
spec:
  gateways:
  - httpbin/httpbingw
  hosts:
  - httpbin.tetrate.io
  http:
  - name: httpbin
    route:
    - destination:
        host: httpbin.httpbin.svc.cluster.local
```

如果我们检查目标服务`httpbin`的端点：

```
kubectl get ep
NAME              ENDPOINTS                                          AGE
httpbin           <none>                                             48m
httpbin-gateway   10.16.0.20:8080,10.16.0.20:8443,10.16.0.20:15443   48m
```

我们没有有效的端点，这是导致问题的原因。接下来的步骤是检查为什么我们的服务没有端点（选择器错误、计算问题等）。

## 调试或跟踪日志

还有其他情况可能需要提高Envoy日志的详细程度，以找出问题所在。假设我们创建了一个应用程序，它执行：

```bash
$ curl localhost:8090/
super funny stuff...
```

然后我们将其部署到我们的服务网格。一旦所有配置就绪，我们发现它实际上无法正常工作...

```
$ curl -v http://fun.tetrate.io/
[ ... ]
> GET / HTTP/1.1
> Host: fun.tetrate.io
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 502 Bad Gateway
< content-length: 87
< content-type: text/plain
< date: Thu, 28 Apr 2022 11:03:48 GMT
< server: istio-envoy
< x-envoy-upstream-service-time: 3
< 
upstream connect error or disconnect/reset before headers. reset reason: protocol error
```

HTTP状态代码`502`表示“网关错误”，因此问题不应出现在我们的应用程序中。

检查网关的日志显示：

```
[2022-04-28T10:58:59.087Z] "GET / HTTP/1.1" 502 - via_upstream - "-" 0 87 3 3 "X.X.X.X" "curl/7.81.0" "3d1f5c5c-e788-4f55-ba0f-00f15b749767" "fun.tetrate.io" "10.16.0.40:8090" outbound|8090||faulty-http.faulty-http.svc.cluster.local 10.16.2.34:50440 10.16.2.34:8080 X.X.X.X:20985 - faulty-http
```

以及 Sidecar 显示：

```
[2022-04-28T10:58:59.089Z] "GET / HTTP/1.1" 502 UPE upstream_reset_before_response_started{protocol_error} - "-" 0 87 1 - "X.X.X.X" "curl/7.81.0" "3d1f5c5c-e788-4f55-ba0f-00f15b749767" "fun.tetrate.io" "10.16.0.40:8090" inbound|8090|| 127.0.0.6:36281 10.16.0.40:8090 X.X.X.X:0 outbound_.8090_._.faulty-http.faulty-http.svc.cluster.local default
```

好的，在这里我们可以看到HTTP状态代码`502`以及标志`UPE`，根据Envoy文档的说明，这表示“上游响应存在HTTP协议错误”。好的，但这并没有告诉我们到底发生了什么。

此时，我们将提高Envoy日志的详细程度，以查看到底发生了什么。我们将使用一些`tctl`命令的组合来获取与我们的主机URL匹配的配置，然后提高相关组件的日志级别。首先，我们要运行的命令是 `tctl get all`，以获取与我们的URL `fun.tetrate.io` 相关的配置。

```
$ tctl get all --fqdn fun.tetrate.io > fun.tetrate.io.config.yaml
$ grep -i kind fun.tetrate.io.config.yaml
kind: VirtualService
kind: Gateway
```

为了公开 `fun.tetrate.io`，我们正在使用一个Istio `Gateway` 和一个 `VirtualService`。现在我们可以运行一个命令，该命令将把与这两个对象相关的Pod的日志级别调整为 `trace`（我们可以使用 `debug`，但是在某些情况下 `trace` 可能会提供一些额外的信息），然后我们将指示 `tctl` 在我们进行测试时等待，因此它将在测试之后收集日志。

```
$ tctl experimental debug log-level -f fun.tetrate.io.config.yaml --level trace --wait -o /tmp/logs
The following pods were found matching the provided component/file:

 - faulty-http/faulty-http-75cd76d866-x9hqx
 - faulty-http/faulty-http-gw-7fbd455c4c-q8lr8

Do you want to proceed? [y/n]: y
Pod: faulty-http/faulty-http-75cd76d866-x9hqx
active loggers:
  admin: trace
  alternate_protocols_cache: trace
  aws: trace
  assert: trace
[ ... ]

Pod: faulty-http/faulty-http-gw-7fbd455c4c-q8lr8
active loggers:
  admin: trace
  alternate_protocols_cache: trace
  aws: trace
  assert: trace
[ ... ]

Waiting for logs to populate. Press Ctrl+C to stop and dump logs to files...
```

您可以看到 `tctl` 标识了两个要更改日志级别的Pod：

- `faulty-http/faulty-http-75cd76d866-x9hqx` 是匹配目标 `VirtualService` 中的服务的选择器的一个Pod。
- `faulty-http/faulty-http-gw-7fbd455c4c-q8lr8` 是匹配Istio `Gateway` 对象中的 `selector` 的一个Pod。

对于这两个Pod，`tctl` 将日志级别更改为指定的 `trace` 级别，然后它将挂起等待用户按下 `Ctrl+C` 以停止等待日志。此时，我们将在另一个终端中启动并发出我们之前使用过的 `curl` 请求几次。之后，我们将返回到运行 `tctl` 命令的终端并按下 `Ctrl+C`。

```
Waiting for logs to populate. Press Ctrl+C to stop and dump logs to files...
^C
Dumping pod logs:
- faulty-http/faulty-http-75cd76d866-x9hqx... Done.
- faulty-http/faulty-http-gw-7fbd455c4c-q8lr8... Done.
```

结果，我们将在 `/tmp/logs` 文件夹中有不同的文件：

```
$ ls -lrt /tmp/logs
-rw-r--r--   1 chirauki  staff       0 28 Apr 16:17 faulty-http-faulty-http-75cd76d866-x9hqx-faulty-http.log
-rw-r--r--   1 chirauki  staff  151797 28 Apr 16:17 faulty-http-faulty-http-75cd76d866-x9hqx-istio-proxy.log
-rw-r--r--   1 chirauki  staff  111970 28 Apr 16:17 faulty-http-faulty-http-gw-7fbd455c4c-q8lr8-istio-proxy.log
```

从上到下，这些是应用程序容器日志，应用程序sidecar容器日志和网关日志。让我们检查sidecar容器的日志。如果我们在URL中搜索主机名 `fun.tetrate.io`，我们将看到进入网关的请求：

```
2022-04-28T14:17:49.024048Z     debug   envoy filter    original_dst: new connection accepted
2022-04-28T14:17:49.024099Z     debug   envoy filter    tls inspector: new connection accepted
2022-04-28T14:17:49.024226Z     trace   envoy filter    tls inspector: recv: 2103
2022-04-28T14:17:49.024265Z     trace   envoy filter    tls:onALPN(), ALPN: istio-peer-exchange,istio
2022-04-28T14:17:49.024291Z     debug   envoy filter    tls:onServerName(), requestedServerName: outbound_.8090_._.faulty-http.faulty-http.svc.cluster.local
2022-04-28T14:17:49.024431Z     trace   envoy misc      enableTimer called on 0x557654f50480 for 3600000ms, min is 3600000ms
2022-04-28T14:17:49.024456Z     debug   envoy conn_handler      [C6169] new connection from 10.16.2.34:41344
```

接着我们将能够看到进入请求的头部：

```
2022-04-28T14:17:49.025487Z     trace   envoy http      [C6169] completed header: key=host value=fun.tetrate.io
2022-04-28T14:17:49.025503Z     trace   envoy http      [C6169] completed header: key=user-agent value=curl/7.81.0
2022-04-28T14:17:49.025510Z     trace   envoy http      [C6169] completed header: key=accept value=*/*
2022-04-28T14:17:49.025516Z     trace   envoy http      [C6169] completed header: key=x-forwarded-for value=10.132.0.30
2022-04-28T14:17:49.025525Z     trace   envoy http      [C6169] completed header: key=x-forwarded-proto value=http
2022-04-28T14:17:49.025531Z     trace   envoy http      [C6169] completed header: key=x-envoy-internal value=true
2022-04-28T14:17:49.025539Z     trace   envoy http      [C6169] completed header: key=x-request-id value=4e3e3e04-6509-43d4-9a97-52b7b2cea0e8
2022-04-28T14:17:49.025560Z     trace   envoy http      [C6169] completed header: key=x-envoy-decorator-operation value=faulty-http.faulty-http.svc.cluster.local:8090/*
2022-04-28T14:17:49.025577Z     trace   envoy http      [C6169] completed header: key=x-envoy-peer-metadata value=ChQKDkFQUF9DT05UQUlORVJTEgIaAAoUCgpDTFVTVEVSX0lEEgYaBGRlbW8KJAoNSVNUSU9fVkVSU0lPThITGhExLjEyLjQtZmZmMGE5MDg5Mwr0AgoGTEFCRUxTEukCKuYCChcKA2FwcBIQGg5mYXVsdHktaHR0cC1ndwo2CilpbnN0YWxsLm9wZXJhdG9yLmlzdGlvLmlvL293bmluZy1yZXNvdXJjZRIJGgd1bmtub3duChkKBWlzdGlvEhAaDmluZ3Jlc3NnYXRld2F5ChkKDGlzdGlvLmlvL3JldhIJGgdkZWZhdWx0CjAKG29wZXJhdG9yLmlzdGlvLmlvL2NvbXBvbmVudBIRGg9JbmdyZXNzR2F0ZXdheXMKIQoRcG9kLXRlbXBsYXRlLWhhc2gSDBoKN2ZiZDQ1NWM0YwozCh9zZXJ2aWNlLmlzdGlvLmlvL2Nhbm9uaWNhbC1uYW1lEhAaDmZhdWx0eS1odHRwLWd3Ci8KI3NlcnZpY2UuaXN0aW8uaW8vY2Fub25pY2FsLXJldmlzaW9uEggaBmxhdGVzdAoiChdzaWRlY2FyLmlzdGlvLmlvL2luamVjdBIHGgVmYWxzZQoaCgdNRVNIX0lEEg8aDWNsdXN0ZXIubG9jYWwKKQoETkFNRRIhGh9mYXVsdHktaHR0cC1ndy03ZmJkNDU1YzRjLXE4bHI4ChoKCU5BTUVTUEFDRRINGgtmYXVsdHktaHR0cApWCgVPV05FUhJNGktrdWJlcm5ldGVzOi8vYXBpcy9hcHBzL3YxL25hbWVzcGFjZXMvZmF1bHR5LWh0dHAvZGVwbG95bWVudHMvZmF1bHR5LWh0dHAtZ3cKqwUKEVBMQVRGT1JNX01FVEFEQVRBEpUFKpIFCkAKEGdjcF9nY2VfaW5zdGFuY2USLBoqZ2tlLXRlc3QtbWFzdGVyLWRlZmF1bHQtcG9vbC0zM2Y5ZDBhMi0wb2JkCosBChtnY3BfZ2NlX2luc3RhbmNlX2NyZWF0ZWRfYnkSbBpqcHJvamVjdHMvNzIyMTQ1MjIwNjg3L3pvbmVzL2V1cm9wZS13ZXN0MS1iL2luc3RhbmNlR3JvdXBNYW5hZ2Vycy9na2UtdGVzdC1tYXN0ZXItZGVmYXVsdC1wb29sLTMzZjlkMGEyLWdycAosChNnY3BfZ2NlX2luc3RhbmNlX2lkEhUaEzg2NzA2MDkxNDc3MzExODY3NTgKcwoZZ2NwX2djZV9pbnN0YW5jZV90ZW1wbGF0ZRJWGlRwcm9qZWN0cy83MjIxNDUyMjA2ODcvZ2xvYmFsL2luc3RhbmNlVGVtcGxhdGVzL2drZS10ZXN0LW1hc3Rlci1kZWZhdWx0LXBvb2wtMDA3NzZlYWIKJQoUZ2NwX2drZV9jbHVzdGVyX25hbWUSDRoLdGVzdC1tYXN0ZXIKhwEKE2djcF9na2VfY2x1c3Rlcl91cmwScBpuaHR0cHM6Ly9jb250YWluZXIuZ29vZ2xlYXBpcy5jb20vdjEvcHJvamVjdHMvbWFyYy10ZXN0aW5nLTI2MjQxNC9sb2NhdGlvbnMvZXVyb3BlLXdlc3QxLWIvY2x1c3RlcnMvdGVzdC1tYXN0ZXIKIAoMZ2NwX2xvY2F0aW9uEhAaDmV1cm9wZS13ZXN0MS1iCiQKC2djcF9wcm9qZWN0EhUaE21hcmMtdGVzdGluZy0yNjI0MTQKJAoSZ2NwX3Byb2plY3RfbnVtYmVyEg4aDDcyMjE0NTIyMDY4NwohCg1XT1JLTE9BRF9OQU1FEhAaDmZhdWx0eS1odHRwLWd3
2022-04-28T14:17:49.025590Z     trace   envoy http      [C6169] completed header: key=x-envoy-peer-metadata-id value=router~10.16.2.34~faulty-http-gw-7fbd455c4c-q8lr8.faulty-http~faulty-http.svc.cluster.local
2022-04-28T14:17:49.025594Z     trace   envoy http      [C6169] completed header: key=x-envoy-attempt-count value=1
2022-04-28T14:17:49.025602Z     trace   envoy http      [C6169] completed header: key=x-b3-traceid value=d5a4ba02141b15b1769bf40d0463c3b6
2022-04-28T14:17:49.025606Z     trace   envoy http      [C6169] completed header: key=x-b3-spanid value=769bf40d0463c3b6
2022-04-28T14:17:49.025611Z     trace   envoy http      [C6169] onHeadersCompleteBase
2022-04-28T14:17:49.025614Z     trace   envoy http      [C6169] completed header: key=x-b3-sampled value=0
2022-04-28T14:17:49.025622Z     trace   envoy http      [C6169] Server: onHeadersComplete size=14
2022-04-28T14:17:49.025636Z     trace   envoy http      [C6169] message complete
2022-04-28T14:17:49.025642Z     trace   envoy connection        [C6169] readDisable: disable=true disable_count=0 state=0 buffer_length=2374
2022-04-28T14:17:49.025679Z     debug   envoy http      [C6169][S9387494024320102295] request headers complete (end_stream=true):
':authority', 'fun.tetrate.io'
':path', '/'
':method', 'GET'
'user-agent', 'curl/7.81.0'
'accept', '*/*'
'x-forwarded-for', '10.132.0.30'
'x-forwarded-proto', 'http'
'x-envoy-internal', 'true'
'x-request-id', '4e3e3e04-6509-43d4-9a97-52b7b2cea0e8'
'x-envoy-decorator-operation', 'faulty-http.faulty-http.svc.cluster.local:8090/*'
'x-envoy-peer-metadata', 'ChQKDkFQUF9DT05UQUlORVJTEgIaAAoUCgpDTFVTVEVSX0lEEgYaBGRlbW8KJAoNSVNUSU9fVkVSU0lPThITGhExLjEyLjQtZmZmMGE5MDg5Mwr0AgoGTEFCRUxTEukCKuYCChcKA2FwcBIQGg5mYXVsdHktaHR0cC1ndwo2CilpbnN0YWxsLm9wZXJhdG9yLmlz
dGlvLmlvL293bmluZy1yZXNvdXJjZRIJGgd1bmtub3duChkKBWlzdGlvEhAaDmluZ3Jlc3NnYXRld2F5ChkKDGlzdGlvLmlvL3JldhIJGgdkZWZhdWx0CjAKG29wZXJhdG9yLmlzdGlvLmlvL2NvbXBvbmVudBIRGg9JbmdyZXNzR2F0ZXdheXMKIQoRcG9kLXRlbXBsYXRlLWhhc2gSDBoKN2ZiZD
Q1NWM0YwozCh9zZXJ2aWNlLmlzdGlvLmlvL2Nhbm9uaWNhbC1uYW1lEhAaDmZhdWx0eS1odHRwLWd3Ci8KI3NlcnZpY2UuaXN0aW8uaW8vY2Fub25pY2FsLXJldmlzaW9uEggaBmxhdGVzdAoiChdzaWRlY2FyLmlzdGlvLmlvL2luamVjdBIHGgVmYWxzZQoaCgdNRVNIX0lEEg8aDWNsdXN0ZXIu
bG9jYWwKKQoETkFNRRIhGh9mYXVsdHktaHR0cC1ndy03ZmJkNDU1YzRjLXE4bHI4ChoKCU5BTUVTUEFDRRINGgtmYXVsdHktaHR0cApWCgVPV05FUhJNGktrdWJlcm5ldGVzOi8vYXBpcy9hcHBzL3YxL25hbWVzcGFjZXMvZmF1bHR5LWh0dHAvZGVwbG95bWVudHMvZmF1bHR5LWh0dHAtZ3cKqw
UKEVBMQVRGT1JNX01FVEFEQVRBEpUFKpIFCkAKEGdjcF9nY2VfaW5zdGFuY2USLBoqZ2tlLXRlc3QtbWFzdGVyLWRlZmF1bHQtcG9vbC0zM2Y5ZDBhMi0wb2JkCosBChtnY3BfZ2NlX2luc3RhbmNlX2NyZWF0ZWRfYnkSbBpqcHJvamVjdHMvNzIyMTQ1MjIwNjg3L3pvbmVzL2V1cm9wZS13ZXN0
MS1iL2luc3RhbmNlR3JvdXBNYW5hZ2Vycy9na2UtdGVzdC1tYXN0ZXItZGVmYXVsdC1wb29sLTMzZjlkMGEyLWdycAosChNnY3BfZ2NlX2luc3RhbmNlX2lkEhUaEzg2NzA2MDkxNDc3MzExODY3NTgKcwoZZ2NwX2djZV9pbnN0YW5jZV90ZW1wbGF0ZRJWGlRwcm9qZWN0cy83MjIxNDUyMjA2OD
cvZ2xvYmFsL2luc3RhbmNlVGVtcGxhdGVzL2drZS10ZXN0LW1hc3Rlci1kZWZhdWx0LXBvb2wtMDA3NzZlYWIKJQoUZ2NwX2drZV9jbHVzdGVyX25hbWUSDRoLdGVzdC1tYXN0ZXIKhwEKE2djcF9na2VfY2x1c3Rlcl91cmwScBpuaHR0cHM6Ly9jb250YWluZXIuZ29vZ2xlYXBpcy5jb20vdjEv
cHJvamVjdHMvbWFyYy10ZXN0aW5nLTI2MjQxNC9sb2NhdGlvbnMvZXVyb3BlLXdlc3QxLWIvY2x1c3RlcnMvdGVzdC1tYXN0ZXIKIAoMZ2NwX2xvY2F0aW9uEhAaDmV1cm9wZS13ZXN0MS1iCiQKC2djcF9wcm9qZWN0EhUaE21hcmMtdGVzdGluZy0yNjI0MTQKJAoSZ2NwX3Byb2plY3RfbnVtYm
VyEg4aDDcyMjE0NTIyMDY4NwohCg1XT1JLTE9BRF9OQU1FEhAaDmZhdWx0eS1odHRwLWd3'
'x-envoy-peer-metadata-id', 'router~10.16.2.34~faulty-http-gw-7fbd455c4c-q8lr8.faulty-http~faulty-http.svc.cluster.local'
'x-envoy-attempt-count', '1'
'x-b3-traceid', 'd5a4ba02141b15b1769bf40d0463c3b6'
'x-b3-spanid', '769bf40d0463c3b6'
'x-b3-sampled', '0'
```

紧接着，我们将看到对应用程序的出站请求。在一些握手消息后，我们将能够看到来自应用程序的入站响应的头部：

```
2022-04-28T14:17:49.027763Z     trace   envoy http      [C6170] parsing 2548 bytes
2022-04-28T14:17:49.027768Z     trace   envoy http      [C6170] message begin
2022-04-28T14:17:49.027788Z     trace   envoy http      [C6170] completed header: key=X-Header-0 value=value
2022-04-28T14:17:49.027806Z     trace   envoy http      [C6170] completed header: key=X-Header-1 value=value
2022-04-28T14:17:49.027810Z     trace   envoy http      [C6170] completed header: key=X-Header-10 value=value
2022-04-28T14:17:49.027815Z     trace   envoy http      [C6170] completed header: key=X-Header-100 value=value
[ ... ]
2022-04-28T14:17:49.028329Z     trace   envoy http      [C6170] completed header: key=X-Header-8 value=value
2022-04-28T14:17:49.028335Z     trace   envoy http      [C6170] completed header: key=X-Header-80 value=value
2022-04-28T14:17:49.028340Z     trace   envoy http      [C6170] completed header: key=X-Header-81 value=value
2022-04-28T14:17:49.028350Z     debug   envoy client    [C6170] Error dispatching received data: headers count exceeds limit
2022-04-28T14:17:49.028366Z     debug   envoy connection        [C6170] closing data_to_write=0 type=1
2022-04-28T14:17:49.028370Z     debug   envoy connection        [C6170] closing socket: 1
2022-04-28T14:17:49.028450Z     trace   envoy connection        [C6170] raising connection event 1
2022-04-28T14:17:49.028466Z     debug   envoy client    [C6170] disconnect. resetting 1 pending requests
2022-04-28T14:17:49.028478Z     debug   envoy client    [C6170] request reset
2022-04-28T14:17:49.028484Z     trace   envoy main      item added to deferred deletion list (size=1)
2022-04-28T14:17:49.028497Z     debug   envoy router    [C6169][S9387494024320102295] upstream reset: reset reason: protocol error, transport failure reason:
2022-04-28T14:17:49.028555Z     debug   envoy http      [C6169][S9387494024320102295] Sending local reply with details upstream_reset_before_response_started{protocol error}
2022-04-28T14:17:49.028594Z     trace   envoy http      [C6169][S9387494024320102295] encode headers called: filter=0x557655798850 status=0
2022-04-28T14:17:49.028601Z     trace   envoy http      [C6169][S9387494024320102295] encode headers called: filter=0x55765503e2a0 status=0
2022-04-28T14:17:49.028606Z     trace   envoy http      [C6169][S9387494024320102295] encode headers called: filter=0x5576557993b0 status=0
2022-04-28T14:17:49.028628Z     trace   envoy http      [C6169][S9387494024320102295] encode headers called: filter=0x557654ed1420 status=0
2022-04-28T14:17:49.028660Z     debug   envoy http      [C6169][S9387494024320102295] encoding headers via codec (end_stream=false):
':status', '502'
'content-length', '87'
'content-type', 'text/plain'
'x-envoy-peer-metadata', 'Ch8KDkFQUF9DT05UQUlORVJTEg0aC2ZhdWx0eS1odHRwChQKCkNMVVNURVJfSUQSBhoEZGVtbwokCg1JU1RJT19WRVJTSU9OEhMaETEuMTIuNC1mZmYwYTkwODkzCtABCgZMQUJFTFMSxQEqwgEKFAoDYXBwEg0aC2ZhdWx0eS1odHRwCiEKEXBvZC10ZW1wbGF0
ZS1oYXNoEgwaCjc1Y2Q3NmQ4NjYKJAoZc2VjdXJpdHkuaXN0aW8uaW8vdGxzTW9kZRIHGgVpc3RpbwowCh9zZXJ2aWNlLmlzdGlvLmlvL2Nhbm9uaWNhbC1uYW1lEg0aC2ZhdWx0eS1odHRwCi8KI3NlcnZpY2UuaXN0aW8uaW8vY2Fub25pY2FsLXJldmlzaW9uEggaBmxhdGVzdAobCgdNRVNIX0
lEEhAaDmRlbW8udHNiLmxvY2FsCiYKBE5BTUUSHhocZmF1bHR5LWh0dHAtNzVjZDc2ZDg2Ni14OWhxeAoaCglOQU1FU1BBQ0USDRoLZmF1bHR5LWh0dHAKUwoFT1dORVISShpIa3ViZXJuZXRlczovL2FwaXMvYXBwcy92MS9uYW1lc3BhY2VzL2ZhdWx0eS1odHRwL2RlcGxveW1lbnRzL2ZhdWx0
eS1odHRwCqsFChFQTEFURk9STV9NRVRBREFUQRKVBSqSBQpAChBnY3BfZ2NlX2luc3RhbmNlEiwaKmdrZS10ZXN0LW1hc3Rlci1kZWZhdWx0LXBvb2wtMzNmOWQwYTItZnpobAqLAQobZ2NwX2djZV9pbnN0YW5jZV9jcmVhdGVkX2J5EmwaanByb2plY3RzLzcyMjE0NTIyMDY4Ny96b25lcy9ldX
JvcGUtd2VzdDEtYi9pbnN0YW5jZUdyb3VwTWFuYWdlcnMvZ2tlLXRlc3QtbWFzdGVyLWRlZmF1bHQtcG9vbC0zM2Y5ZDBhMi1ncnAKLAoTZ2NwX2djZV9pbnN0YW5jZV9pZBIVGhM0NjQ3OTQ3MDc3NTU5ODE3NTY5CnMKGWdjcF9nY2VfaW5zdGFuY2VfdGVtcGxhdGUSVhpUcHJvamVjdHMvNzIy
MTQ1MjIwNjg3L2dsb2JhbC9pbnN0YW5jZVRlbXBsYXRlcy9na2UtdGVzdC1tYXN0ZXItZGVmYXVsdC1wb29sLTAwNzc2ZWFiCiUKFGdjcF9na2VfY2x1c3Rlcl9uYW1lEg0aC3Rlc3QtbWFzdGVyCocBChNnY3BfZ2tlX2NsdXN0ZXJfdXJsEnAabmh0dHBzOi8vY29udGFpbmVyLmdvb2dsZWFwaX
MuY29tL3YxL3Byb2plY3RzL21hcmMtdGVzdGluZy0yNjI0MTQvbG9jYXRpb25zL2V1cm9wZS13ZXN0MS1iL2NsdXN0ZXJzL3Rlc3QtbWFzdGVyCiAKDGdjcF9sb2NhdGlvbhIQGg5ldXJvcGUtd2VzdDEtYgokCgtnY3BfcHJvamVjdBIVGhNtYXJjLXRlc3RpbmctMjYyNDE0CiQKEmdjcF9wcm9q
ZWN0X251bWJlchIOGgw3MjIxNDUyMjA2ODcKHgoNV09SS0xPQURfTkFNRRINGgtmYXVsdHktaHR0cA=='
'x-envoy-peer-metadata-id', 'sidecar~10.16.0.40~faulty-http-75cd76d866-x9hqx.faulty-http~faulty-http.svc.cluster.local'
'date', 'Thu, 28 Apr 2022 14:17:48 GMT'
'server', 'istio-envoy'
```

好的，等等。我们看到Envoy开始解析响应头部，但最终打印了这行：

```
2022-04-28T14:17:49.028350Z     debug   envoy client    [C6170] Error dispatching received data: headers count exceeds limit
```

以某种方式，响应中的头部似乎比Envoy希望的多。如果我们搜索[Envoy文档](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/protocol.proto#config-core-v3-httpprotocoloptions)（特别是检查 `max_headers_count`），我们会看到，默认情况下，Envoy允许一个HTTP请求或响应中的最多100个头部，而我们超过了这个数字。在这种情

况下，应用程序中的问题会导致Envoy出现错误，因此修复应用程序将解决此问题。

此时，我们可以再次使用 `tctl` 将日志级别恢复为默认值。

```
$ tctl experimental debug log-level -f fun.tetrate.io.config.yaml --level info -y
```

## Gateway自动缩放和删除

当发生网关Pod删除事件时，TSB需要将服务信息传播到其他集群，以便跨集群流量不会针对已删除的Pod的NodePort IP地址。您可以配置TSB控制平面以启用一个Webhook，拦截网关Pod删除事件，将删除操作保留一段可配置的时间。这样可以为配置更改在所有集群中传播并让所有网格组件删除即将删除的IP地址提供足够的时间。如果配置未完全传播，您可能会观察到HTTP流量的`503`错误或通过传递跨集群流量的`000`错误。

请参阅[网关删除保持Webhook](../../operations/features/gateway-deletion-webhook)以启用Webhook。
