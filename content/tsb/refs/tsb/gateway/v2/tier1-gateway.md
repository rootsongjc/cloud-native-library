---
title: Tier1 Gateway
description: Configurations to build a tier1 gateway.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

DEPRECATION: The functionality provided by the `Tier1Gateway` is now provided in `Gateway` object, and
using it is the recommended approach. The `Tier1Gateway` resource will be removed in future releases.

`Tier1Gateway` configures a workload to act as a gateway that
distributes traffic across one or more ingress gateways in other
clusters.

**NOTE:** Tier1 gateways cannot be used to route traffic to the
same cluster. A cluster with tier1 gateway cannot have any other
gateways or workloads.

The following example declares a tier1 gateway running on pods with
`app: gateway` labels in the `ns1` namespace. The gateway exposes
host `movieinfo.com` on ports 8080, 8443 and `kafka.internal` on port 9000.
Traffic for these hosts at the ports 8443 and 9000 are TLS terminated and
forwarded over Istio mutual TLS to the ingress gateways hosting
`movieinfo.com` host on clusters `c3` and `c4` and the internal
`kafka.internal` service in cluster `c3` respectively. The server at
port 8080 is configured to receive plaintext HTTP traffic and redirect
to port 8443 with "Permanently Moved" (HTTP 301) status code.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
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
  externalServers:
  - name: movieinfo-plain
    hostname: movieinfo.com # Plaintext and HTTPS redirect
    port: 8080
    redirect:
      authority: movieinfo.com
      uri: "/"
      redirectCode: 301
      port: 8443
      scheme: https
  - name: movieinfo
    hostname: movieinfo.com # TLS termination and Istio mTLS to upstream
    port: 8443
    tls:
      mode: SIMPLE
      secretName: movieinfo-secrets
    clusters:
    - name: c3 # the target gateway IPs will be automatically determined
      weight: 90
    - name: c4
      weight: 10
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
  tcpExternalServers:
  - name: kafka
    hostname: kafka.internal
    port: 9000
    tls:
      mode: SIMPLE
      secretName: kafka-cred
    clusters:
    - name: c3
      weight: 100
```

Tier1 gateways can also be used to forward mesh internal traffic
for Gateway hosts from one cluster to another. This form of
forwarding will work only if the two clusters cannot reach each
other directly (e.g., they are on different VPCs that are not
peered). The following example declares a tier1 gateway running on
pods with `app: gateway` labels in the `ns1` namespace. The gateway
exposes hosts `movieinfo.com`, `bookinfo.com`, and a non-HTTP server
called `kafka.org-internal` within the mesh. Traffic to `movieinfo.com`
is load balanced across all clusters on `vpc-02`, while traffic to
`bookinfo.com` and `kafka.org-internal` is load balanced across ingress
gateways exposing `bookinfo.com` on any cluster. Traffic from the source
(sidecars) is expected to arrive on the tier1 gateway over Istio mTLS.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
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
  internalServers: # forwarding gateway (HTTP traffic only)
  - name: movieinfo
    hostname: movieinfo.com
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
      external:
        uri: "https://auth.company.com"
        includeRequestHeaders:
        - authorization
  - name: bookinfo
    hostname: bookinfo.com # route to any ingress gateway exposing bookinfo.com
  tcpInternalServers: # forwarding non-HTTP traffic within the mesh
  - name: kafka
    hostname: kafka.org-internal
```

** NOTE:** If two clusters have direct connectivity, declaring
a tier1 internal server will have no effect.

Tier1 gateways can also be configured to expose hostnames in the
TLS passthrough mode. Tier1 gateway will forward the pasthrough server traffic to 
any tier2 pass through servers exposing the same hostname. In other words,
To be able to leverage passthrough at tier1, it is a MUST that passthrough is configured
at t2 IngressGateway as well.

** NOTE:** A hostname like `abc.com` can only be exposed either in passthrough mode OR
in terminating tls mode(External/Internal servers), not in both the modes.


```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
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
  passthroughServers:
  - name: nginx
    port: 8443
    hostname: nginx.example.com
```

The Tier1Gateway above will require the corresponding, at least one or more, IngressGateway(s), e.g.:

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: tls-gw
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  tlsPassthrough:
    - name: nginx
      port: 443
      hostname: nginx.example.com
      route:
        host: "ns1/my-nginx.default.svc.cluster.local"
        port: 443
```

The following example customizes the `Extensions` field to enable
the execution of the specified WasmExtensions list and details
custom properties for the execution of each extension.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
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
  externalServers:
  - name: movieinfo-plain
    hostname: movieinfo.com # Plaintext and HTTPS redirect
    port: 8080
    redirect:
      authority: movieinfo.com
      uri: "/"
      redirectCode: 301
      port: 8443
      scheme: https
  extension:
  - fqn: hello-world # fqn of imported extensions in TSB
    config:
      foo: bar
```

Whenever traffic is to be sent from one cluster to another, one or more of
the following would have to be true for it to succeed:
- Both clusters belong to the same network.
- Destination cluster network is not named.
- [Organization Setting](https://docs.tetrate.io/service-bridge/en-us/refs/tsb/v2/organization_setting#organizationsetting)
is set up to send traffic from source cluster to destination cluster.

`Tier1Gateway` also allows you to apply ModSecurity/Coraza compatible Web
Application Firewall rules to traffic passing through the gateway.

```yaml
apiVersion: gateway.xcp.tetrate.io/v2
kind: Tier1Gateway
metadata:
  name: tier1-waf-gw
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: gateway
  passthroughServers:
  - name: nginx
    port: 8443
    hostname: nginx.example.com
  waf:
    rules:
      - Include @owasp_crs/*.conf
```





## Tier1ExternalServer {#tetrateio-api-tsb-gateway-v2-tier1externalserver}

Tier1ExternalServer describes the properties of a server exposed
outside the mesh. Traffic arriving at a Tier1 external server is
usually TLS terminated and then forwarded over Istio mTLS to all
the lower tier2 clusters.



  
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
unique across all external servers in the gateway.

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The port where the server is exposed. Note that port 15443 is reserved.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Hostname with which the service can be expected to be accessed by
clients.

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

[tetrateio.api.tsb.gateway.v2.ServerTLSSettings](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-servertlssettings) <br/> TLS certificate info. The gateway will terminate the TLS
connection and forward it to the upstream ingress gateway using
Istio mutual TLS on port 15443.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


clusters

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.ClusterDestination](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-clusterdestination) <br/> The destination clusters that contain ingress gateways exposing
the hostname. If omitted, traffic will be automatically load
balanced across all tier2 clusters whose ingress gateways expose
the above hostname. If `redirect` is configured then this field
cannot be configured.
To do failover and locality based routing among clusters, either omit
the clusters field or omit the weights from all the cluster destinations.

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

[tetrateio.api.tsb.gateway.v2.Redirect](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-redirect) <br/> Redirect allows configuring HTTP redirect. When this is
configured, the `clusters` field cannot be configured.

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

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rateLimiting

</td>

<td>

[tetrateio.api.tsb.gateway.v2.RateLimiting](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimiting) <br/> Configuration for rate limiting requests. This configuration is namespaced to a Tier1ExternalServer

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Tier1Gateway {#tetrateio-api-tsb-gateway-v2-tier1gateway}

`Tier1Gateway` configures a workload to act as a tier1 gateway into the mesh.



  
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


externalServers

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.Tier1ExternalServer](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1externalserver) <br/> One or more servers exposed by the gateway externally.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


internalServers

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.Tier1InternalServer](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1internalserver) <br/> One or more servers exposed by the gateway internally for cross cluster forwarding.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


passthroughServers

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.Tier1PassthroughServer](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1passthroughserver) <br/> One or more tls passthrough servers exposed by the gateway externally.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tcpExternalServers

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.Tier1TCPExternalServer](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1tcpexternalserver) <br/> One or more tcp servers exposed by the gateway externally.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tcpInternalServers

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.Tier1TCPInternalServer](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1tcpinternalserver) <br/> One or more tcp servers exposed by the gateway for mesh internal traffic.

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

List of [tetrateio.api.tsb.types.v2.WasmExtensionAttachment](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-wasmextensionattachment) <br/> Extensions specifies all the WasmExtensions assigned to this Tier1Gateway
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

[tetrateio.api.tsb.security.v2.WAFSettings](../../../tsb/security/v2/waf_settings#tetrateio-api-tsb-security-v2-wafsettings) <br/> WAF settings to be enabled for traffic passing through this Tier1 gateway.

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
  


## Tier1InternalServer {#tetrateio-api-tsb-gateway-v2-tier1internalserver}

Tier1InternalServer describes the properties of a server exposed
within the mesh, for the purposes of forwarding traffic between two
clusters that cannot otherwise directly reach each other. Traffic
arriving at a Tier1 internal server should be over Istio
mTLS. After TLS termination and metrics extraction, it is forwarded
to tier2 clusters based on the selection criteria.



  
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
unique across all internal servers in the gateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


hostname

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Hostname with which the service can be expected to be accessed by
sidecars in the mesh.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


clusters

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.ClusterDestination](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-clusterdestination) <br/> The destination clusters that contain ingress gateways exposing
the hostname. If omitted, traffic will be automatically load
balanced across all tier2 clusters whose ingress gateways expose
the above hostname.

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
credentials like JWT.

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

[tetrateio.api.tsb.auth.v2.Authorization](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authorization) <br/> Authorization is used to configure authorization of end user and traffic.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Tier1PassthroughServer {#tetrateio-api-tsb-gateway-v2-tier1passthroughserver}

Tier1PassthroughServer describes the properties of a server exposed
to the external world. Traffic arriving at a Tier1 passthrough server is
not TLS terminated and rather forwarded over to all the lower tier2 clusters.



  
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
unique across all external servers in the gateway.

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The port where the server is exposed. Note that port 15443 is reserved.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Hostname with which the service can be expected to be accessed by
clients.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


clusters

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.ClusterDestination](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-clusterdestination) <br/> The destination clusters that contain ingress gateways exposing
the hostname on passthrough servers. If omitted, traffic will be automatically load
balanced across all tier2 clusters whose ingress gateways expose
the above hostname.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Tier1TCPExternalServer {#tetrateio-api-tsb-gateway-v2-tier1tcpexternalserver}

Tier1TCPExternalServer is used to describe the properties of a TCP server
(used for opaque TCP or non-HTTP protocols) exposed to the external world.
If the protocol is known to be HTTP, then please use `externalServers` as
it allows using HTTP-specific features.

Caveat - Currently, we don't support multicluster routing when Tier2 gateway
settings are specified in the direct mode for TCP services. So please use
the bridged mode.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> A name assigned to the server. This name is used in the generated metrics. The name
must be unique across all TCP servers in the gateway

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The port where the server is exposed. Note that the port 15443 is reserved. Also
beware of the conflict among the services using different protocols on the same port.
The conflict occurs in the following scenarios
1. Using plaintext and TLS (passthrough/termination)
2. Mixing multiple protocols without TLS (HTTP and non-HTTP protocols like Kafka, Zookeeper etc)
3. Multiple non-HTTP protocols without TLS

Valid scenarios (for same port, multiple services)
1. Multiple protocols (HTTP, non-HTTP) with TLS passthrough/termination
2. Multiple HTTP services
3. Single non-HTTP service without TLS

Note on service port - If a service is exposed on port 6789 in the tier1 gateway,
then it must be exposed on the same port with the same hostname (without wildcard)
in the tier2 gateway as well.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Although hostname or authority does not make sense in the non-HTTP context, this
is used to define the routing rules. Wildcard hostnames are not yet supported.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


clusters

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.ClusterDestination](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-clusterdestination) <br/> The destination clusters contain ingress gateways exposing the service.

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

[tetrateio.api.tsb.gateway.v2.ServerTLSSettings](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-servertlssettings) <br/> TLS certificate information to terminate TLS. If passthrough is required, then please
use `passthroughServers` to specify them.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Tier1TCPInternalServer {#tetrateio-api-tsb-gateway-v2-tier1tcpinternalserver}

Tier1TCPInternalServer is used to describe the properties of a TCP server
which is used exclusively within the mesh.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> A name assigned to the server. This name is used in the generated metrics. The name
must be unique across all TCP servers in the gateway.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hostname

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The name of the service used. Although hostname or authority does not make sense
in the non-HTTP context, this is used for the multicluster routing purposes. Consider
the case where there are two non-HTTP services listening on the same port 6000,
but are hosted on different workloads. Here, the service name is used to distinguish
between the two for routing to the correct workload. We do not support wildcard hostnames
yet. The ports are determined automatically by the cluster updates of the remote edge
clusters. Suppose there is a service called `foo.com` and the remote cluster says that
it exposes ports 8080 and 8443, then we can route east-west traffic for both the ports
through this server. The changes to the port or protocol settings are picked up automatically.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


clusters

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.ClusterDestination](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-clusterdestination) <br/> The destination clusters contain ingress gateways exposing the service.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



