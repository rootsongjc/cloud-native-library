---
title: Gateway
description: Configurations to build a gateway for traffic entering into the mesh.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

The `Gateway` configuration combines the functionalities of both the existing `Tier1Gateway` and `IngressGateway`,
providing a unified approach for configuring a workload as a gateway in the mesh.
Each server within the `Gateway` is configured to route requests to either destination clusters or services,
but configuring one server to route requests to a destination cluster and another server to route requests to a service
is not supported.
To ensure consistency and compatibility, the `Gateway` configuration requires that all servers within the gateway
either forward traffic to other clusters, similar to a `Tier1Gateway`, or route traffic to specific services, similar
to an `IngressGateway`.

The following example declares a gateway running on pods
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
Here, the `gateway` is configured in a manner similar to an
existing `IngressGateway` with HTTP server.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
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
          serviceDestination:
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

The following example declares a gateway running on pods with
`app: gateway` labels in the `ns1` namespace. The gateway exposes
host `movieinfo.com` on ports 8080, 8443 and `kafka.internal` on port 9000.
Traffic for these hosts at the ports 8443 and 9000 are TLS terminated and
forwarded over Istio mutual TLS to the ingress gateways hosting
`movieinfo.com` host on clusters `c3` for matching prefix `v1` and `c4` for matching `v2`,
and the internal `kafka.internal` service in cluster `c3` respectively. The server at
port 8080 is configured to receive plaintext HTTP traffic and redirect
to port 8443 with "Permanently Moved" (HTTP 301) status code.
Here, the `gateway` is configured in a manner similar to an
existing `Tier1Gateway` with external servers.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: tier1
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
  - name: movieinfo-plain
    hostname: movieinfo.com # Plaintext and HTTPS redirect
    port: 8080
    routing:
      rules:
        - redirect:
            authority: movieinfo.com
            port: 8443
            redirectCode: 301
            scheme: https
            uri: "/"
  - name: movieinfo
    hostname: movieinfo.com # TLS termination and Istio mTLS to upstream
    port: 8443
    tls:
      mode: SIMPLE
      secretName: movieinfo-secrets
    routing:
      rules:
         - match:
             - uri:
                 prefix: "/v1"
           route:
             clusterDestination:
               clusters:
                 - name: c3 # the target gateway IPs will be automatically determined
                   weight: 100
         - match:
             - uri:
                 prefix: "/v2"
           route:
             clusterDestination:
               clusters:
                 - name: c4 # the target gateway IPs will be automatically determined
                   weight: 100
    authentication:
      rules:
        jwt:
        - issuer: "auth.mycompany.com"
          jwksUri: https://auth.mycompany.com/oauth2/jwks
        - issuer: "auth.othercompany.com"
          jwksUri: https://auth.othercompany.com/oauth2/jwks
    authorization:
      external:
        uri: "https://auth.company.com"
        includeRequestHeaders:
          - authorization
  tcp:
  - name: kafka
    hostname: kafka.internal
    port: 9000
    tls:
      mode: SIMPLE
      secretName: kafka-cred
    route:
      clusterDestination:
        clusters:
          - name: c3
            weight: 100
```

This example used to forward mesh internal traffic
for Gateway hosts from one cluster to another. This form of
forwarding will work only if the two clusters cannot reach each
other directly (e.g., they are on different VPCs that are not
peered). The following example declares a gateway running on
pods with `app: gateway` labels in the `ns1` namespace. The gateway
exposes hosts `movieinfo.com`, `bookinfo.com`, and a non-HTTP server
called `kafka.org-internal` within the mesh. Traffic to `movieinfo.com`
is load balanced across all clusters on `vpc-02`, while traffic to
`bookinfo.com` and `kafka.org-internal` is load balanced across ingress
gateways exposing `bookinfo.com` on any cluster. Traffic from the source
(sidecars) is expected to arrive on the tier1 gateway over Istio mTLS.
Here, the `gateway` is configured in a manner similar to an
existing `Tier1Gateway` with internal servers.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: tier1
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  http: # forwarding gateway (HTTP traffic only)
  - name: movieinfo
    transit: true # server marked as internal
    hostname: movieinfo.com
    routing:
      rules:
      - route:
          clusterDestination:
            clusters:
            - labels:
                network: vpc-02 # the target gateway IPs will be automatically determined
    authentication:
      rules:
        jwt:
        - issuer: "auth.mycompany.com"
          jwksUri: https://auth.company.com/oauth2/jwks
        - issuer: "auth.othercompany.com"
          jwksUri: https://auth.othercompany.com/oauth2/jwks
    authorization:
      meshInternalAuthz:
        external:
          uri: "https://auth.company.com"
          includeRequestHeaders:
            - authorization
  - name: bookinfo
    transit: true # server marked as internal
    hostname: bookinfo.com # route to any ingress gateway exposing bookinfo.com
    routing:
      rules:
      - route:
          clusterDestination:
            clusters:
  tcp: # forwarding non-HTTP traffic within the mesh
  - name: kafka
    transit: true # server marked as internal
    hostname: kafka.org-internal
    route:
      clusterDestination:
        clusters:
```

The following example illustrates defining non-HTTP server (based
on TCP) with TLS termination. Here, kafka.myorg.internal uses non-HTTP
protocol and listens on port 9000. The clients have to connect with TLS
with the SNI `kafka.myorg.internal`. The TLS is terminated at the gateway
and the traffic is routed to `kafka.infra.svc.cluster.local:8000`.

If subsets are defined in the `ServiceRoute` referencing
`kafka.infra.svc.cluster.local` service, then it is also considered
while routing.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
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
      serviceDestination:
        host: kafka.infra.svc.cluster.local
        port: 8000
```

This is an example of configuring a gateway for TLS.
The gateway will forward the passthrough server traffic to clusters `c1` and `c2`.
It is essential to configure TLS on the same hostname at `c1` and `c2` as well.
Here, the `gateway` is configured similarly to an existing `Tier1Gateway` with passthrough servers.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  name: tier1-tls-gw
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  tls:
  - name: nginx
    port: 8443
    hostname: nginx.example.com
    route:
      clusterDestination:
         clusters:
           - name: c1 # the target gateway IPs will be automatically determined
             weight: 90
           - name: c2
             weight: 10
```





## Gateway {#tetrateio-api-tsb-gateway-v2-gateway}

The `Gateway` configuration combines the functionalities of both the existing `Tier1Gateway` and `IngressGateway`,
providing a unified approach for configuring a workload as a gateway in the mesh.

Each server within the `Gateway` is configured to route requests to either destination clusters or services,
but configuring one server to route requests to a destination cluster and another server to route requests to a service
is not supported.

To ensure consistency and compatibility, the `Gateway` configuration requires that all servers within the gateway
either forward traffic to other clusters, similar to a `Tier1Gateway`, or route traffic to specific services, similar
to an `IngressGateway`.



  
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

List of [tetrateio.api.tsb.gateway.v2.HTTP](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-http) <br/> One or more HTTP or HTTPS servers exposed by the gateway. The
server exposes configuration for TLS termination, request
authentication/authorization, HTTP routing, rate limiting, etc.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tls

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.TLS](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-tls) <br/> One or more TLS servers exposed by the gateway. The server
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

List of [tetrateio.api.tsb.gateway.v2.TCP](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-tcp) <br/> One or more non-HTTP and non-passthrough servers which use TCP
based protocols. This server also exposes configuration for terminating TLS.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


wasmPlugins

</td>

<td>

List of [tetrateio.api.tsb.types.v2.WasmExtensionAttachment](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-wasmextensionattachment) <br/> WasmPlugins specifies all the WasmExtensionAttachment assigned to this Gateway
with the specific configuration for each plugin. This custom configuration
will override the one configured globally to the plugin.
Each plugin has a global configuration including priority
that will condition the execution of the assigned plugins.

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
  


## HTTP {#tetrateio-api-tsb-gateway-v2-http}

`HTTP` describes the properties of a HTTP server exposed on gateway.



  
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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The port where the server is exposed at the gateway workload(pod).
If the k8s service, which is fronting the workload pod, has TargetPort as 8443 for the Port 443,
this could be configured as 8443 or 443.

Two servers with different protocols (HTTP and HTTPS) should not
share the same port. Note that port 15443 is reserved for internal use.

If the `transit` flag is set to true, populating the `port` will lead to an error,
as the server is considered internal to the mesh. TSB will automatically 
configure mTLS port(15443) for east-west multicluster traffic.

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;not_in: `15443`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


hostname

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Hostname with which the service can be expected to be accessed by clients.

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
If the `transit` flag is set to true, populating the `tls` will lead to an error,
as the server is considered internal to the mesh.
Gateway uses Istio mutual TLS to secure the connection for forwarding the traffic.

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

[tetrateio.api.tsb.auth.v2.Authentication](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authentication) <br/> Authentication is used to configure the authentication of end-user
credentials like JWT. It is highly recommended to configure this with TLS

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

[tetrateio.api.tsb.auth.v2.Authorization](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authorization) <br/> Authorization is used to configure authorization of end users. It
is highly recommended to configure this with TLS

If external authorization is configured, authorization is evaluated for each HTTP path by default.
Users can exclude authorization on specific paths by setting the flag
`disableExternalAuthorization` on individual HTTP route rules.

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

[tetrateio.api.tsb.gateway.v2.HttpRoutingConfig](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-httproutingconfig) <br/> _REQUIRED_ <br/> Routing rules associated with HTTP traffic to this server.

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

[tetrateio.api.tsb.gateway.v2.RateLimiting](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimiting) <br/> Configuration for rate limiting requests. This configuration is namespaced to a particular HttpServer.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


transit

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If set to true, the server is configured to be exposed within the mesh.
This configuration enables forwarding traffic between two clusters that are not directly reachable.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## HttpRouteRule {#tetrateio-api-tsb-gateway-v2-httprouterule}

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

[tetrateio.api.tsb.gateway.v2.RouteTo](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-routeto) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> route_or_redirect</sup>_ <br/> Forward the request to the specified destination(s). One of route or redirect must be specified.

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
    
<tr>
<td>


disableExternalAuthorization

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If set to true, external authorization is disabled on this route
when the hostname is configured with external authorization.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## HttpRoutingConfig {#tetrateio-api-tsb-gateway-v2-httproutingconfig}

`HttpRoutingConfig` defines a list of HTTP route rules that determine how incoming requests are routed.



  
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

List of [tetrateio.api.tsb.gateway.v2.HttpRouteRule](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-httprouterule) <br/> _REQUIRED_ <br/> HTTP routes.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## RouteTo {#tetrateio-api-tsb-gateway-v2-routeto}

RouteTo defines the how the traffic has been forwarded for the given request.
One of `ClusterDestination` or `ServiceDestination` must be specified.



  
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


clusterDestination

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RouteToClusters](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-routetoclusters) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> destination</sup>_ <br/> RouteToClusters represents the clusters where the request
needs to be routed to from the gateway.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceDestination

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RouteToService](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-routetoservice) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> destination</sup>_ <br/> RouteToService represents the service running in clusters.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## RouteToClusters {#tetrateio-api-tsb-gateway-v2-routetoclusters}

RouteToClusters represents the clusters where the request
needs to be routed to from the gateway.



  
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


clusters

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.ClusterDestination](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-clusterdestination) <br/> The destination clusters that contain ingress gateways exposing the hostname.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## RouteToService {#tetrateio-api-tsb-gateway-v2-routetoservice}

RouteToService represents the service running in clusters.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The destination service in `<namespace>/<fqdn>`.

</td>

<td>

string = {<br/>&nbsp;&nbsp;pattern: `^[^/]+/[^/]+$`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The port on the service to forward the request to. Omit only if
the destination service has only one port.

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;not_in: `15443`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


tls

</td>

<td>

[tetrateio.api.tsb.auth.v2.ClientTLSSettings](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-clienttlssettings) <br/> The `ClientTLSSettings` specifies how the `gateway` workload should establish connections
to external services. This setting is intended for external services specifically.
For normal mesh services, this should not be used, and the settings should be applied to the
corresponding traffic/security groups instead.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## TCP {#tetrateio-api-tsb-gateway-v2-tcp}

A TCP server exposed in a gateway. A TCP server may be used for any TCP based protocol.
This is also used for the special case of a non-HTTP protocol requiring TLS termination at the gateway.



  
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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The port where the server is exposed. Note that the port 15443 is reserved. Also
beware of the conflict among the services using different protocols on the same port.
The conflict occurs in the following scenarios
1. Using plaintext and TLS (passthrough/termination)
2. Mixing multiple protocols without TLS (HTTP and non-HTTP protocols like Kafka, Zookeeper etc)
3. Multiple non-HTTP protocols without TLS

Valid scenarios (for same port, multiple services)
1. Multiple protocols (HTTP, non-HTTP) with TLS passthrough/termination
2. Multiple HTTP services
3. Single non-HTTP service without TLS

If the `transit` flag is set to true, populating the `port` will lead to an error,
as the server is considered internal to the mesh. TSB will automatically 
configure mTLS port(15443) for east-west multicluster traffic.

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;not_in: `15443`<br/>}<br/>

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

[tetrateio.api.tsb.gateway.v2.ServerTLSSettings](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-servertlssettings) <br/> TLS certificate info to terminate the TLS connection.
If the `transit` flag is set to true, populating the `tls` will lead to an error,
as the server is considered internal to the mesh.
Gateway uses Istio mutual TLS to secure the connection for forwarding the traffic.

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

[tetrateio.api.tsb.gateway.v2.RouteTo](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-routeto) <br/> _REQUIRED_ <br/> Forward the connection to the specified destination.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


transit

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If set to true, the server is configured to be exposed within the mesh.
This configuration enables forwarding traffic between two clusters that are not directly reachable.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## TLS {#tetrateio-api-tsb-gateway-v2-tls}

A TLS server exposed in a gateway. For TLS servers, the gateways do not terminate
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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The port where the server is exposed. Two servers with different protocols (HTTP and HTTPS) should not
share the same port. Note that port 15443 is reserved for internal use.

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;not_in: `0,15443`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


hostname

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Hostname with which the service can be expected to be accessed by clients.
Routing will be done based on SNI matches for this hostname.
**NOTE:** The "hostname:port" must be unique across all gateways in the cluster in order for
multicluster routing to work.

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

[tetrateio.api.tsb.gateway.v2.RouteTo](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-routeto) <br/> _REQUIRED_ <br/> Forward the connection to the specified destination.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  



