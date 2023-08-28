---
title: Ingress Gateway troubleshooting
Description: Troubleshooting ingress routes in TSB.
---

Whenever we use the TSB `IngressGateway` or the Istio `Gateway` and `VirtualService` resources to route external traffic to our services, we might face problems with the routes that we expose. In this document, we are going to show you some of the most common failure scenarios and how to troubleshoot them.

## Missing configuration

One of the first things to check is that the configuration that we created in TSB exists in the destination cluster. For instance, in this case:

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

We are getting a 404 HTTP response (not found) to an ingress route that had just been configured. The first thing to check is the [resource status](./configuration_status). Make sure that the status for your ingress resources is `ACCEPTED`.

:::note 404
Envoy 404 responses do not have any body as shown above. If you see a 404 along with some "not found" message, it usually points to a correct configuration in routing, but you are hitting a wrong URL. For instance:

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

The HTML code you can see there is sent back by the application itself, which means the routing works OK, but you are reaching the application on a wrong path.
:::

```
$ tctl experimental status workspace hello --tenant tetrate
NAME     STATUS    LAST EVENT    MESSAGE                                                                                                                  
hello    FAILED                  The following children resources have issues: organizations/tetrate/tenants/tetrate/workspaces/hello/gatewaygroups/hello   
```

For instance, the output above suggests that something in the workspace `hello` is not right, specifically in the gateway group named `hello`.

```
$ tctl experimental status gatewaygroup hello --workspace hello --tenant tetrate
NAME     STATUS    LAST EVENT    MESSAGE                                                                                                                                        
hello    FAILED                  The following children resources have issues: organizations/tetrate/tenants/tetrate/workspaces/hello/gatewaygroups/hello/virtualservices/hello    
```

And there seem to be a problem with the `VirtualService` that was deployed for this route.

```
$ tctl experimental status virtualservice hello --gatewaygroup hello --workspace hello --tenant tetrate
NAME     STATUS    LAST EVENT    MESSAGE                                                                                                                                                          
hello    FAILED    MPC_FAILED    no gateway object found for reference "helloworld/hellogw" in "organizations/tetrate/tenants/tetrate/workspaces/hello/gatewaygroups/hello/virtualservices/hello"
```

At this point we can identify the reason for the missing configuration is actually a problem with the configuration itself, so it can be fixed so it gets deployed, fixing the 404 error we were seeing. The error message in the status object will guide you to find where error is.

## Envoy access logs

:::note X-REQUEST-ID HEADER
You can sent `X-REQUEST-ID` header to correlate the requests within the logs. You can use any random string as request ID. Envoy proxies will include that ID in every log statement that it creates. Following the example given below, this would be `curl -vk -H  'X-REQUEST-ID:4e3e3e04-6509-43d4-9a97-52b7b2cea0e8'`
:::

TSB configures Istio so that Envoy prints access logs in `stdout` and only errors for certain modules. If the configuration received from `istiod` is not valid, you will see a message, but for requests failing, you will pretty much see a response `503` with some flags, specified in the [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage) (see the `%RESPONSE_FLAGS%` section). Let's check the following example.

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

If we look at the access log for this request, we see:

```
[2022-04-27T15:02:20.472Z] "GET /foobar HTTP/2" 503 UH no_healthy_upstream - "-" 0 19 0 - "X.X.X.X" "curl/7.81.0" "55fef75a-70e5-449f-ad01-cd34960f465c" "httpbin.tetrate.io" "-" outbound|8000||httpbin.httpbin.svc.cluster.local - 10.16.0.20:8443 X.X.X.X:36009 httpbin.tetrate.io httpbin
```

Right, so we see the timestamp of the log, some HTTP information for the request (method, path, protocol), and then we can see the response code, `503`, followed by the flag `UH`, which matches the message we got in the response, stating that there is no healthy upstream. The `VirtualService` for this ingress route is currently:

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

If we check the destination service `httpbin` endpoints:

```
kubectl get ep
NAME              ENDPOINTS                                          AGE
httpbin           <none>                                             48m
httpbin-gateway   10.16.0.20:8080,10.16.0.20:8443,10.16.0.20:15443   48m
```

We have no valid endpoints, which is causing the problem. The next step here would be to check why we have no endpoints for the service (wrong selectors, compute problem, etc.).

## Debug or trace logs

There are other cases where you might need to end up raising the verbosity of Envoy logs to find out what is going on. Let's say we have created an application that does:

```
$ curl localhost:8090/
super funny stuff...
```

And we deploy that to our service mesh. Once all the configuration is in place, we found out it is not quite working...

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

The HTTP status code `502` stands for `bad gateway`, so the problem should not be in our app.

Inspecting the logs for the gateway shows:

```
[2022-04-28T10:58:59.087Z] "GET / HTTP/1.1" 502 - via_upstream - "-" 0 87 3 3 "X.X.X.X" "curl/7.81.0" "3d1f5c5c-e788-4f55-ba0f-00f15b749767" "fun.tetrate.io" "10.16.0.40:8090" outbound|8090||faulty-http.faulty-http.svc.cluster.local 10.16.2.34:50440 10.16.2.34:8080 X.X.X.X:20985 - faulty-http
```

And the sidecar shows:

```
[2022-04-28T10:58:59.089Z] "GET / HTTP/1.1" 502 UPE upstream_reset_before_response_started{protocol_error} - "-" 0 87 1 - "X.X.X.X" "curl/7.81.0" "3d1f5c5c-e788-4f55-ba0f-00f15b749767" "fun.tetrate.io" "10.16.0.40:8090" inbound|8090|| 127.0.0.6:36281 10.16.0.40:8090 X.X.X.X:0 outbound_.8090_._.faulty-http.faulty-http.svc.cluster.local default
```

OK, here we can see the HTTP status code `502` along with the flags `UPE`, which according to the Envoy docs means `The upstream response had an HTTP protocol error.`. Right, but that does not show us what is going on.

At this point we are going to raise the verbosity for the Envoy logs to see if we can see some message that can point us to the root cause of the problem. To that extent, we are going to use a combination of `tctl` commands to get the configuration matching our host URL and then raise the log for the related components. The first command we are going to run is `tctl get all` to get the configuration related to our URL `fun.tetrate.io`.

```
$ tctl get all --fqdn fun.tetrate.io > fun.tetrate.io.config.yaml
$ grep -i kind fun.tetrate.io.config.yaml
kind: VirtualService
kind: Gateway
```

In order to expose `fun.tetrate.io` we are using an Istio `Gateway` and a `VirtualService`. Now we can run a command that will turn the log levels of the pods related to these two objects to `trace` (we could use `debug`, but trace might provide some extra info in some cases), and we are going to instruct `tctl` to wait while we do the tests so it will collect the logs afterwards.

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

You can see how `tctl` identified 2 pods to change the log levels on:

- `faulty-http/faulty-http-75cd76d866-x9hqx` is a pod that matches the selector for the service that is the destination in the `VirtualService`.
- `faulty-http/faulty-http-gw-7fbd455c4c-q8lr8` is a pod that matches the `selector` in the Istio `Gateway` object.

For these two pods, `tctl` is going to turn the log level to the specified `trace` level, and then it will hang for the user to press `Ctrl+C` to stop waiting for logs. At this point we are going to fire up a different terminal and fire the `curl` request we used before a couple of times. After that, we will return to the terminal running the `tctl` command and press `Ctrl+C`.

```
Waiting for logs to populate. Press Ctrl+C to stop and dump logs to files...
^C
Dumping pod logs:
- faulty-http/faulty-http-75cd76d866-x9hqx... Done.
- faulty-http/faulty-http-gw-7fbd455c4c-q8lr8... Done.
```

As a result, we will have different files in the `/tmp/logs` folder:

```
$ ls -lrt /tmp/logs
-rw-r--r--   1 chirauki  staff       0 28 Apr 16:17 faulty-http-faulty-http-75cd76d866-x9hqx-faulty-http.log
-rw-r--r--   1 chirauki  staff  151797 28 Apr 16:17 faulty-http-faulty-http-75cd76d866-x9hqx-istio-proxy.log
-rw-r--r--   1 chirauki  staff  111970 28 Apr 16:17 faulty-http-faulty-http-gw-7fbd455c4c-q8lr8-istio-proxy.log
```

From top to bottom, these are the app container logs, app sidecar container logs and gateway logs. Let's check the sidecar container logs. If we search the host name in the URL, `fun.tetrate.io`, we will see the requests that come into the gateway:

```
2022-04-28T14:17:49.024048Z     debug   envoy filter    original_dst: new connection accepted
2022-04-28T14:17:49.024099Z     debug   envoy filter    tls inspector: new connection accepted
2022-04-28T14:17:49.024226Z     trace   envoy filter    tls inspector: recv: 2103
2022-04-28T14:17:49.024265Z     trace   envoy filter    tls:onALPN(), ALPN: istio-peer-exchange,istio
2022-04-28T14:17:49.024291Z     debug   envoy filter    tls:onServerName(), requestedServerName: outbound_.8090_._.faulty-http.faulty-http.svc.cluster.local
2022-04-28T14:17:49.024431Z     trace   envoy misc      enableTimer called on 0x557654f50480 for 3600000ms, min is 3600000ms
2022-04-28T14:17:49.024456Z     debug   envoy conn_handler      [C6169] new connection from 10.16.2.34:41344
```

Then we will be able to see the decoded headers of the incoming request:

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

And right after, we will see the outgoing request to the application. After some handshake messages, we will be able to see the headers of the incoming response from the application:

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

OK, hang on. We see how Envoy starts parsing the response headers, but eventually prints this line:

```
2022-04-28T14:17:49.028350Z     debug   envoy client    [C6170] Error dispatching received data: headers count exceeds limit
```

Somehow, there seem to be more headers in the response than Envoy would like. If we search the [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/protocol.proto#config-core-v3-httpprotocoloptions) (check specifically `max_headers_count`), we will see that, by default, Envoy allows up to 100 headers in an HTTP request or response, and we are going over that number. In this case, a problem in the application is causing an error in Envoy, so fixing the application would fix this issue.

At this point, we can use `tctl` again to revert the log levels to the defaults.

```
$ tctl experimental debug log-level -f fun.tetrate.io.config.yaml --level info -y
```

## Gateway Autoscaling and Deletion

When a gateway pod delete event occurs, TSB needs to propagate service information to other clusters so that cross-cluster traffic does not target the deleted pod's NodePort IP address. You can configure TSB control plane to enable a webhook that intercepts gateway pod delete events, holding the delete operation for a configurable time period. This allows for sufficient time for the configuration change to propagate across all clusters and for all mesh components to remove the soon-to-be-deleted IP address. In the unlikely event that the configuration does not completely propagate, you may observe `503` errors for HTTP traffic or `000` errors for passthrough cross cluster traffic.

See [gateway deletion hold webhook](../operations/features/gateway_deletion_webhook) to enable the webhook.
