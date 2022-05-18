---
weight: 110
title: EnvoyFilter
date: '2022-05-18T00:00:00+08:00'
type: book
---

EnvoyFilter 资源允许你定制由 Istio Pilot 生成的 Envoy 配置。使用该资源，你可以更新数值，添加特定的过滤器，甚至添加新的监听器、集群等等。小心使用这个功能，因为不正确的定制可能会破坏整个网格的稳定性。

过滤器是叠加应用的，这意味着对于特定命名空间中的特定工作负载，可以有任何数量的过滤器。根命名空间（例如 `istio-system`）中的过滤器首先被应用，然后是工作负载命名空间中的所有匹配过滤器。

下面是一个 EnvoyFilter 的例子，它在请求中添加了一个名为 `api-version` 的头。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: api-header-filter
  namespace: default
spec:
  workloadSelector:
    labels:
      app: web-frontend
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        portNumber: 8080
        filterChain:
          filter:
            name: "envoy.http_connection_manager"
            subFilter:
              name: "envoy.router"
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.lua
        typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua"
          inlineCode: |
            function envoy_on_response(response_handle)
              response_handle:headers():add("api-version", "v1")
            end
```

如果你向 `$GATEWAY_URL` 发送一个请求，你可以注意到 `api-version` 头被添加了，如下所示：

```sh
$ curl -s -I -X HEAD  http://$GATEWAY_URL
HTTP/1.1 200 OK
x-powered-by: Express
content-type: text/html; charset=utf-8
content-length: 2471
etag: W/"9a7-hEXE7lJW5CDgD+e2FypGgChcgho"
date: Tue, 17 Nov 2020 00:40:16 GMT
x-envoy-upstream-service-time: 32
api-version: v1
server: istio-envoy
```

{{< cta cta_text="下一章" cta_link="../../config-networking/" >}}
