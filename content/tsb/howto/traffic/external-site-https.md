---
title: Send traffic to an External Host using HTTPS
weight: 4
---

This article will cover how to send traffic to an external host using HTTPS retries and timeouts.

Before you get started, make sure you:<br />
✓ Familiarize yourself with [TSB concepts](../../concepts/toc) <br />
✓ Install the TSB environment. You can use [TSB demo](../../setup/self_managed/demo-installation) for quick install<br />
✓ Completed [TSB usage quickstart](../../quickstart).


## Understanding the problem

Considering an external application added to the mesh with a [ServiceEntry](https://istio.io/latest/docs/reference/config/networking/service-entry/). The application listens on HTTPS so the traffic you will be sending is expected to use simple TLS.

The application client within the mesh will initiate an HTTP request and it will be converted to HTTPS at the sidecar to the external application host, e.g. `www.tetrate.io`. This is achieved due to outbound traffic policy defined in the DestinationRule.

Here is what you need to set to achieve the communication between the client and the external host:

:::note Direct mode
This only works using TSB direct mode config.
:::

First, create a namespace for your istio objects:

```
kubectl create ns tetrate
```

Create a file `tetrate.yaml` with the following ServiceEntry, VirtualService and DestinationRule.

````
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
````

Apply with kubectl:

```
kubectl apply -f tetrate.yaml
```

It is important to pay attention on how the external host is added to the service registry.
On the yaml above, you can see that the single ServiceEntry has port 80 as the matching port but your external application listens on HTTPS which most of the time will be 443 (you may change this if your application listens on 8443 or other port).

In other words, the traffic is sent to the same port that matched, i.e. port 80, which is not right for the outgoing HTTPS connection. In order to forward to upstream 443 port, you would need to make the endpoints stanza in the ServiceEntry look like this:

```
endpoints:
   - address: www.tetrate.io
     ports:
       http: 443
```


## Testing

For testing you can perform a request from a client with a sidecar injected, in this case a [netshoot](https://github.com/nicolaka/netshoot) or [sleep](../../reference/samples/sleep_service) pod will be useful.

First, send a request using HTTPS:

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

You can see how the first curl command succeeds, as it goes through the pass-through proxy (TCP proxy). That means no rule is applied from DestinationRule or VirtualService.

Now, perform a request instead sending and HTTPS this will be a plain HTTP. Remember the sidecar will initiate and HTTPS request as we instructed in the DestinationRule.

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

This will return an obvious response since you have an aggressive timeout defined in the virtual service which it gets applied hence is working as expected.

## Cleaning

Destroy all the resources with the same yaml file as following:

```
kubectl delete -f tetrate.yaml
```

Finally delete the namespace.

```
kubectl delete ns tetrate
```
