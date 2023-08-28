---
title: Multiple Transfer Encoding Chunked
Description: How TSB handles the multiple Transfer-encoding chunked in both request and response header
---

This document describes how TSB will handle the request/response if the header has multiple `transfer-encoding:chunked`  and also helps you in identifying whether the problem is from the source or the destination.

What we recommend to resolve this issue is to make sure that there is only one `transfer-encoding:chunked` in both the request and the response header, otherwise Envoy will reject the request.

Before you get started, make sure you: <br />
✓ Familiarize yourself with [TSB concepts](../concepts/toc) <br />
✓ Install the [TSB demo](../setup/self_managed/demo-installation) environment <br />
✓ Deploy the [Istio Bookinfo](../quickstart/deploy_sample_app) sample app <br />

Note: For the response section, the application we used here deliberately generates multiple `transfer-encoding:chunked` headers and it’s used for only documentation purpose.

We have often seen that the header of the request/response contains multiple `transfer-encoding:chunked` and this is not a valid header as Envoy rejects such request. In the bookinfo application that we have installed we can take a deeper look at how envoy will reject with specific error code for a simple request.

## Request header with "Transfer-Encoding: chunked,chunked"

For our bookinfo app we will create a simple request using curl to send a multiple `transfer-encoding:chunked` and we will observe how the envoy gateway will respond.

```
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

At the same time the gateway envoy logs show the failure with the below snippet and the error code as `501 DPE (Downstream Protocol Error)`
```
kubectl logs ${GWPOD} -n bookinfo 
[2022-09-07T08:17:38.936Z] "- - HTTP/1.1" 501 DPE http1.invalid_transfer_encoding - "-" 0 15 0 - "-" "-" "-" "-" "-" - - 10.0.2.20:8080 10.128.0.74:23365 - -
```

## Response header with "Transfer-Encoding: chunked,chunked"

The response header can be manipulated within the application itself and could trigger the multiple chunks as well. In these cases the envoy sidecar of that application will reject the response.
To demonstrate the response we used a simple application which will generate multiple transfer-chunked as a default behavior,We will send a curl request from the [Debug-container](./debug-container) with default values as shown below.

```
$curl -v http://transfer:8080/test
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

When we look at the sidecar envoy log we can see the rejection with the error message `502 UPE (Upstream Protocol Error)`

```
kubectl logs transfer-58c6c67c56-d8wzk  -n test 
[2022-09-13T11:17:13.471Z] "GET /test HTTP/1.1" 502 UPE upstream_reset_before_response_started{protocol_error} - "-" 0 87 1 - "-" "curl/7.83.1" "fbcd5bff-1981-40a5-a2c8-fd6133161976" "transfer:8080" "10.0.2.7:8080" inbound|8080|| 127.0.0.6:53799 10.0.2.7:8080 10.0.0.21:59960 outbound_.8080_._.transfer.test.svc.cluster.local default
```

If we enable the debug log for sidecar of the application we can see the error in details as 
```
2022-09-13T12:46:48.497388Z     debug   envoy client    [C2912] Error dispatching received data: http/1.1 protocol error: unsupported transfer encoding
```
