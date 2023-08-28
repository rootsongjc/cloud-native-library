---
title: Maximum Header Size Exceed
---

This article will cover how TSB and istio-proxy handle headers when forwarding from Istio ingress gateways or sidecars to applications.

Before you get started, make sure you:<br />
✓ Familiarize yourself with [TSB concepts](../concepts/toc) <br />
✓ Install the TSB environment. You can use [TSB demo](../setup/self_managed/demo-installation) for quick install<br />
✓ Completed [TSB usage quickstart](../quickstart).<br />
✓ Install sample application [httpbin](../reference/samples/httpbin).


## Request header size in Envoy (istio-proxy)

[Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto) or istio-proxy can handle headers that are considerably larger. The default maximum request headers size for incoming connections is 60 KiB

In this case, it will not be an issue for the majority of applications, and the request headers that incoming connections will be proxied through istio-proxy. However, your application might have restrictions based on the configuration of the header size for each web server.

For example:
In [Spring Boot 2](https://www.baeldung.com/spring-boot-max-http-header-size) and [Gunicorn](https://docs.gunicorn.org/en/stable/settings.html#limit-request-field-size) the default max header size is 8 KiB. You can override the default if needed.


## Debug request headers size

For this experiment, you will need the [httpbin](../reference/samples/httpbin) sample application deployed in your cluster. You will perform two requests, one with a header size below the maximum and another one that exceeds the limit by the app container.

### Header below the maximum

Your header can be anything just make sure is below 8 KiB you can export it as a variable and perform the request:

````
curl -k  https://httpbin.example.io/response-headers -X POST -H "X-MyHeader: $SMALL" -sI
HTTP/2 200 
server: istio-envoy
date: Wed, 19 Oct 2022 20:13:49 GMT
content-type: application/json
content-length: 68
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 5

````
### Header above the maximum

Now perform the request with a header that can exceed the maximum of 8 KiB

````
curl -k  https://httpbin.example.io/response-headers -X POST -H "X-MyHeader: $LONG" -sI
HTTP/2 400 
content-type: text/html
content-length: 189
x-envoy-upstream-service-time: 6
date: Wed, 19 Oct 2022 20:17:37 GMT
server: istio-envoy

````

If the request header exceed the maximum header size, you will receive a bad request following a 400 HTTP code.

## Modify header size in istio-proxy

As you learned above, you can limit the header size in a variety of web servers. You can do the same modifications in istio-proxy.

The default header size should be just enough, or you may want to decrease the default size. 
### Decreasing the default size of the header in istio-proxy

In order to decrease the size of the default request header you will need to create an [Envoyfilter](https://istio.io/latest/docs/reference/config/networking/envoy-filter/) that allows you to modify the istio-proxy configuration.

````
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

````

Once this is applied in your cluster, try again the request with an small header and a larger one.

### Header below the maximum in istio-proxy

````
curl -k  https://httpbin.example.io/response-headers -X POST -H "X-MyHeader: $SMALL" -sI
HTTP/2 200 
server: istio-envoy
date: Wed, 19 Oct 2022 20:36:43 GMT
content-type: application/json
content-length: 68
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 5

````

You can see the request was successfully as the header was below the maximum of 10 KiB.

### Header above the maximum in istio-proxy

````
curl -k  https://httpbin.example.io/response-headers -X POST -H "X-MyHeader: $LONG" -sI

````
You can remove the -s flag from curl and see the output.

````
curl -k  https://httpbin.example.io/response-headers -X POST -H "X-MyHeader: $LONG" -I
curl: (92) HTTP/2 stream 0 was not closed cleanly: INTERNAL_ERROR (err 2)
````

The request did not return anything but an error. You can see what happened in the logs.

````
kubectl logs $GWPOD -n tier1

[2022-10-19T20:39:58.081Z] "- - HTTP/2" 0 - http2.too_many_headers - "-" 0 0 0 - "-" "-" "-" "-" "-" - - 10.211.129.34:8443 10.240.0.38:63077 httpbin.example.io -

````
