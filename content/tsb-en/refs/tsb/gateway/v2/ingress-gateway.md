---
title: Ingress Gateway
description: Configurations to build an ingress gateway.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

DEPRECATION: The functionality provided by the `IngressGateway` is now provided in `Gateway` object, and
using it is the recommended approach. The `IngressGateway` resource will be removed in future releases.

`IngressGateway` configures a workload to act as a gateway for
traffic entering the mesh. The ingress gateway also provides basic
API gateway functionalities such as JWT token validation 
and request authorization. Gateways in privileged
workspaces can route to services outside the workspace while those
in unprivileged workspaces can only route to services inside the
workspace.

The following example declares an ingress gateway running on pods
with `app: gateway` labels in the `ns1` namespace. The gateway
exposes a host `bookinfo.com` on https port 9443 and http port 9090.
The port 9090 is configured to receive plaintext traffic and send a
redirect to the https port 9443 (site-wide HTTP -> HTTPS redirection).
At port 9443, TLS is terminated using the certificates in the Kubernetes
secret `bookinfo-certs`. Clients are authenticated using JWT
tokens, whose keys are obtained from the OIDC provider `www.googleapis.com`.
The request is then authorized by an the user's authorization engine
hosted at `https://company.com/authz` before being forwarded to 
the `productpage` service in the backend.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: ingress-bookinfo
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  http:
  - name: bookinfo-plaintext
    port: 9090
    hostname: bookinfo.com
    routing:
      rules:
      - redirect:
          authority: bookinfo.com
          port: 9443
          redirectCode: 301
          scheme: https
  - name: bookinfo
    port: 9443
    hostname: bookinfo.com
    tls:
      mode: SIMPLE
      secretName: bookinfo-certs
    authentication:
      rules:
        jwt:
        - issuer: https://accounts.google.com
          jwksUri: https://www.googleapis.com/oauth2/v3/certs
        - issuer: "auth.mycompany.com"
          jwksUri: https://auth.mycompany.com/oauth2/jwks
    authorization:
      external:
        uri: https://company.com/authz
        includeRequestHeaders:
        - Authorization # forwards the header to the authorization service.
    routing:
      rules:
      - route:
          host: ns1/productpage.ns1.svc.cluster.local
    rateLimiting:
      settings:
        rules:
          # Ratelimit at 10 requests/hour for clients with a remote address of 1.2.3.4 
        - dimensions: 
          - remoteAddress:
              value: 1.2.3.4
          limit:
            requestsPerUnit: 10
            unit: HOUR
          # Ratelimit at 50 requests/minute for every unique value in the user-agent header
        - dimensions:
          - header:
              name: user-agent
          limit:
            requestsPerUnit: 50
            unit: MINUTE
          # Ratelimit at 100 requests/second for every unique client remote address
          # with the HTTP requests having a GET method and the path prefix of /productpage
        - dimensions:
          - remoteAddress:
              value: "*"
          - header:
              name: ":path"
              value:
                prefix: /productpage
          - header:
              name: ":method"
              value:
                exact: "GET"
          limit:
            requestsPerUnit: 100
            unit: SECOND
```

If the `productpage.ns1` service on Kubernetes has a `ServiceRoute`
with multiple subsets and weights, the traffic will be split across
the subsets accordingly.

The following example illustrates defining non-HTTP servers (based
on TCP) with TLS termination. Here, kafka.myorg.internal uses non-HTTP
protocol and listens on port 9000. The clients have to connect with TLS
with the SNI `kafka.myorg.internal`. The TLS is terminated at the gateway
and the traffic is routed to `kafka.infra.svc.cluster.local:8000`.

If subsets are defined in the `ServiceRoute` referencing
`kafka.infra.svc.cluster.local` service, then it is also considered
while routing.
```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: ingress-bookinfo
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  tcp:
  - name: kafka-gateway
    hostname: kafka.myorg.internal
    port: 9000
    tls:
      mode: SIMPLE
      secretName: kafka-cred
    route:
      host: kafka.infra.svc.cluster.local
      port: 8000
```

The following example customizes the `Extensions` to enable
the execution of the specified WasmExtensions list and details
custom properties for the execution of each extension.
```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: ingress-bookinfo
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
  namespace: ns1
  labels:
    app: gateway
  extension:
  - fqn: hello-world # fqn of imported extensions in TSB
    config:
      foo: bar
  http:
  - name: bookinfo
    port: 80
    hostname: bookinfo.com
    routing:
      rules:
      - route:
        host: ns1/productpage.ns1.svc.cluster.local

`IngressGateway` also allows you to apply ModSecurity/Coraza compatible Web
Application Firewall rules to traffic passing through the gateway.

```yaml
apiVersion: gateway.xcp.tetrate.io/v2
kind: IngressGateway
metadata:
  name: waf-gw
    namespace: ns1
    labels:
      app: waf-gateway
  http:
  - name: bookinfo
    port: 9443
    hostname: bookinfo.com
  waf:
    rules:
      - Include @recommended-conf
      - SecResponseBodyAccess Off
      - Include @owasp_crs/*.conf
```





## HttpRouting {#tetrateio-api-tsb-gateway-v2-httprouting}





  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


corsPolicy

</td>

<td>

[tetrateio.api.tsb.gateway.v2.CorsPolicy](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-corspolicy) <br/> Cross origin resource request policy settings for all routes.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rules

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.HttpRule](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-httprule) <br/> _REQUIRED_ <br/> HTTP routes.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## HttpRule {#tetrateio-api-tsb-gateway-v2-httprule}

A single HTTP rule.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


match

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.HttpMatchCondition](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-httpmatchcondition) <br/> One or more match conditions (OR-ed).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


modify

</td>

<td>

[tetrateio.api.tsb.gateway.v2.HttpModifyAction](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-httpmodifyaction) <br/> One or more mutations to be performed before forwarding. Includes typical modifications to be
done on a single request like URL rewrite, host rewrite, headers to add/remove/append.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


route

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Route](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-route) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> route_or_redirect</sup>_ <br/> Forward the request to the specified destination(s). One of route or redirect must be specified.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


redirect

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Redirect](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-redirect) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> route_or_redirect</sup>_ <br/> Redirect the request to a different host or URL or both. One of route or redirect must be specified.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## HttpServer {#tetrateio-api-tsb-gateway-v2-httpserver}

An HTTP server exposed in an ingress gateway.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> A name assigned to the server. The name will be visible in the generated metrics. The name must be
unique across all servers in a gateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The port where the server is exposed. Two servers with different protocols (HTTP and HTTPS) should not
share the same port. Note that port 15443 is reserved for internal use.

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;not_in: `0,15443`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


hostname

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Hostname with which the service can be expected to be accessed by clients.
**NOTE:** The hostname must be unique across all gateways in the cluster in order for multicluster routing to work.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


tls

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ServerTLSSettings](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-servertlssettings) <br/> TLS certificate info. If omitted, the gateway will expose a plain text HTTP server.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


authentication

</td>

<td>

[tetrateio.api.tsb.auth.v2.Authentication](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authentication) <br/> Configuration to authenticate clients.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


authorization

</td>

<td>

[tetrateio.api.tsb.auth.v2.Authorization](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authorization) <br/> Configuration to authorize a request.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


routing

</td>

<td>

[tetrateio.api.tsb.gateway.v2.HttpRouting](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-httprouting) <br/> _REQUIRED_ <br/> Routing rules associated with HTTP traffic to this service.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


rateLimiting

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RateLimiting](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimiting) <br/> Configuration for rate limiting requests. This configuration is namespaced to a particular HttpServer

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## IngressGateway {#tetrateio-api-tsb-gateway-v2-ingressgateway}

`IngressGateway` configures a workload to act as an ingress gateway into the mesh.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


workloadSelector

</td>

<td>

[tetrateio.api.tsb.types.v2.WorkloadSelector](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-workloadselector) <br/> _REQUIRED_ <br/> Specify the gateway workloads (pod labels and Kubernetes
namespace) under the gateway group that should be configured with
this gateway. There can be only one gateway for a workload selector in a namespace.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


http

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.HttpServer](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-httpserver) <br/> One or more HTTP or HTTPS servers exposed by the gateway. The
server exposes configuration for TLS termination, request
authentication/authorization, HTTP routing, etc.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tlsPassthrough

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.TLSPassthroughServer](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-tlspassthroughserver) <br/> One or more TLS servers exposed by the gateway. The server
does not terminate TLS and exposes config for SNI based routing.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tcp

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.TCPServer](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-tcpserver) <br/> One or more non-HTTP and non-passthrough servers which use TCP
based protocols. This server also exposes configuration for terminating TLS

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


extension

</td>

<td>

List of [tetrateio.api.tsb.types.v2.WasmExtensionAttachment](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-wasmextensionattachment) <br/> Extensions specifies all the WasmExtensions assigned to this IngressGateway
with the specific configuration for each extension. This custom configuration
will override the one configured globally to the extension.
Each extension has a global configuration including enablement and priority
that will condition the execution of the assigned extensions.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


waf

</td>

<td>

[tetrateio.api.tsb.security.v2.WAFSettings](../../../tsb/security/v2/waf_settings#tetrateio-api-tsb-security-v2-wafsettings) <br/> WAF settings to be enabled for traffic passing through the HttpServer.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


configGenerationMetadata

</td>

<td>

[tetrateio.api.tsb.types.v2.ConfigGenerationMetadata](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-configgenerationmetadata) <br/> Metadata values that will be add into the Istio generated configurations.
When using YAML APIs like`tctl` or `gitops`, put them into the `metadata.labels` or
`metadata.annotations` instead.
This field is only necessary when using gRPC APIs directly.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Route {#tetrateio-api-tsb-gateway-v2-route}

One or more destinations in a local/remote cluster for the given request.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


host

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The destination service in `<namespace>/<fqdn>` format for
`IngressGateway` resources. For `Tier1Gateway` resources, the
destination must be in `<clusterName>/<namespace>/<fqdn>` format,
where cluster name corresponds to a cluster name created in the
management plane. The `fqdn` must be the fully qualified name of
the destination service in a cluster.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The port on the service to forward the request to. Omit only if
the destination service has only one port. When used for routing
from Tier1 gateways, the port specified here will be used only if
the Tier1 gateway is doing TLS passthrough.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## TCPServer {#tetrateio-api-tsb-gateway-v2-tcpserver}

A TCP server exposed in an ingress gateway. A TCP server may be used for any TCP based protocol.
This is also used for the special case of a non-HTTP protocol requiring TLS termination at the gateway



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> A name assigned to the server. The name will be visible in the generated metrics. The name must be
unique across all HTTP, TLS passthrough and TCP servers in a gateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The port where the server is exposed. Two servers with different protocols can share the same port
only when both of them use TLS (either terminated at the gateway or pass-through)

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;not_in: `0,15443`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


hostname

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Hostname to identify the service. When TLS is configured, clients have to use this as
the Server Name Indication (SNI) for the TLS connection. When TLS is not configured (opaque TCP),
this is used to identify the service traffic for defining routing configs. Usually, this is
configured as the DNS name of the service. For instance, if clients access a zookeeper cluster
as `zk-1.myorg.internal` then the hostname could be specified as `zk-1.myorg.internal`. This
also helps easier identification in the configs.

This is also used in multicluster routing. In the previous example, clients within the mesh
can also use `zk-1.myorg.internal` to access this service (provided authorization policy allows it)

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


tls

</td>

<td>

[tetrateio.api.tsb.gateway.v2.ServerTLSSettings](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-servertlssettings) <br/> TLS certificate info to terminate the TLS connection

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


route

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Route](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-route) <br/> Forward the connection to the specified destination.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## TLSPassthroughServer {#tetrateio-api-tsb-gateway-v2-tlspassthroughserver}

A TLS server exposed in an ingress gateway. For TLS servers the gateways don't terminate
connections and use SNI based routing.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> A name assigned to the server. The name will be visible in the generated metrics. The name must be
unique across all HTTP, TCP and TLS servers in a gateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The port where the server is exposed. Two servers with different protocols (HTTP and HTTPS) should not
share the same port. Note that port 15443 is reserved for internal use.

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;not_in: `0,15443`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


hostname

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Hostname with which the service can be expected to be accessed by clients.
Routing will be done based on SNI matches for this hostname.
**NOTE:** The hostname must be unique across all gateways in the cluster in order for multicluster routing to work.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


route

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Route](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-route) <br/> _REQUIRED_ <br/> Forward the connection to the specified destination.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  



