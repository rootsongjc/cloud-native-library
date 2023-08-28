---
title: Traffic Setting
description: Traffic settings for proxy workloads in a traffic group.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Traffic Settings allow configuring the behavior of the proxy workloads in
a set of namespaces owned by a traffic group. Specifically, it
allows configuring the dependencies of proxy workloads on namespaces
outside the traffic group as well as reliability settings for
outbound calls made by the proxy workloads to other services.

The following example creates a traffic group for the proxy workloads in
`ns1`, `ns2` and `ns3` namespaces owned by its parent workspace
`w1` under tenant `mycompany`. It then defines a traffic setting
for the all workloads in these namespaces, adding a dependency on
all the services in the shared `db` namespace, and forwarding all
unknown traffic via the egress gateway in the `istio-system`
namespace.

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  name: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelector:
    names:
    - "*/ns1"
    - "*/ns2"
    - "*/ns3"
  configMode: BRIDGED
```

And the associated traffic settings for the proxy workloads:

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: TrafficSetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  reachability:
    mode: CUSTOM
    hosts:
    - "ns1/*"
    - "ns2/*"
    - "ns3/*"
    - "db/*"
  resilience:
    circuitBreakerSensitivity: MEDIUM
  egress:
    host: istio-system/istio-egressgateway
```

The following traffic setting confines the reachability of proxy workloads
in the traffic group `t1` to other namespaces inside the group. The
resilience and egress gateway settings will be inherited from the
workspace wide traffic setting.

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: TrafficSetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  reachability:
    mode: GROUP
```





## HTTPRetry {#tetrateio-api-tsb-traffic-v2-httpretry}

HTTPRetry defines the parameters for retrying API calls to a service.



  
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


attempts

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Number of retries for a given request. The interval between retries will be determined
automatically (25ms+).

Actual number of retries attempted depends on the httpReqTimeout.

</td>

<td>

int32 = {<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


perTryTimeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Timeout per retry attempt for a given request. format: 1h/1m/1s/1ms. MUST BE >=1ms.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


retryOn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Specifies the conditions under which retry takes place.
One or more policies can be specified using a ‘,’ delimited list.
See the [retry policies](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#x-envoy-retry-on)
and [gRPC retry policies](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#x-envoy-retry-grpc-on)
for more details.

</td>

<td>

string = {<br/>&nbsp;&nbsp;pattern: `^$|^(5xx|gateway-error|reset|connect-failure|envoy-ratelimited|retriable-4xx|refused-stream|retriable-status-codes|retriable-headers|cancelled|deadline-exceeded|internal|resource-exhausted|unavailable)(,(5xx|gateway-error|reset|connect-failure|envoy-ratelimited|retriable-4xx|refused-stream|retriable-status-codes|retriable-headers|cancelled|deadline-exceeded|internal|resource-exhausted|unavailable))*$`<br/>}<br/>

</td>
</tr>
    
</table>
  


## KeepAliveSettings {#tetrateio-api-tsb-traffic-v2-keepalivesettings}

Keep Alive Settings.



  
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


tcp

</td>

<td>

[tetrateio.api.tsb.traffic.v2.KeepAliveSettings.TcpKeepAliveSettings](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-keepalivesettings-tcpkeepalivesettings) <br/> TCP Keep Alive settings associated with the upstream and downstream TCP connections.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### TcpKeepAliveSettings {#tetrateio-api-tsb-traffic-v2-keepalivesettings-tcpkeepalivesettings}

TCP Keep Alive Settings.



  
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


downstream

</td>

<td>

[tetrateio.api.tsb.traffic.v2.KeepAliveSettings.TcpKeepAliveSettings.TcpKeepAlive](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-keepalivesettings-tcpkeepalivesettings-tcpkeepalive) <br/> TCP Keep Alive Settings associated with the downstream (client) connection.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


upstream

</td>

<td>

[tetrateio.api.tsb.traffic.v2.KeepAliveSettings.TcpKeepAliveSettings.TcpKeepAlive](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-keepalivesettings-tcpkeepalivesettings-tcpkeepalive) <br/> TCP Keep Alive Settings associated with the upstream (backend) connection.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### TcpKeepAlive {#tetrateio-api-tsb-traffic-v2-keepalivesettings-tcpkeepalivesettings-tcpkeepalive}





  
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


probes

</td>

<td>

[google.protobuf.UInt32Value](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.UInt32Value) <br/> The total number of unacknowledged probes to send before deciding
the connection is dead. Default is to use the OS level configuration,
Linux defaults to 9.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


idleTime

</td>

<td>

[google.protobuf.UInt32Value](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.UInt32Value) <br/> The number of seconds a connection needs to be idle before keep-alive probes
start being sent. Default is to use the OS level configuration,
Linux defaults to 7200s.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


interval

</td>

<td>

[google.protobuf.UInt32Value](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.UInt32Value) <br/> The number of seconds between keep-alive probes. Default is to use the OS
level configuration, Linux defaults to 75s.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ReachabilitySettings {#tetrateio-api-tsb-traffic-v2-reachabilitysettings}

`ReachabilitySettings` define the set of services and hosts
accessed by a workload (and hence its sidecar) in the
mesh. Defining the set of services accessed by a workload (i.e. its
dependencies) in advance reduces the memory and CPU consumption
both the Istio control plane and the individual Envoy proxy workloads in
the data plane.



  
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


mode

</td>

<td>

[tetrateio.api.tsb.traffic.v2.ReachabilitySettings.Mode](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-reachabilitysettings-mode) <br/> A short cut for specifying the set of services accessed by the workload.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hosts

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When the mode is `CUSTOM`, `hosts` specify the set of services
that the sidecar should be able to reach. Must be in the
`<namespace>/<fqdn>` format.

- `./*` indicates all services in the namespace where the sidecar resides.

- `ns1/*` indicates all services in the `ns1` namespace.

- `ns1/svc1.com` indicates `svc1.com` service in `ns1` namespace.

- `*/svc1.com` indicates `svc1.com` service in any namespace.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ResilienceSettings {#tetrateio-api-tsb-traffic-v2-resiliencesettings}

ResilienceSettings control the reliability knobs in Envoy when making
outbound connections from a gateway or proxy workload.



  
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


httpRequestTimeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Timeout for HTTP requests. Disabled if not set.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


httpRetries

</td>

<td>

[tetrateio.api.tsb.traffic.v2.HTTPRetry](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-httpretry) <br/> Retry policy for HTTP requests. Disabled if not set.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tcpKeepalive

</td>

<td>

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> Deprecated. This field will be removed in upcoming releases.
Please use the `keep_alive` field instead.
If enabled, sets SO_KEEPALIVE on the socket to enable TCP keepalive.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


keepAlive

</td>

<td>

[tetrateio.api.tsb.traffic.v2.KeepAliveSettings](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-keepalivesettings) <br/> Keep Alive Settings.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


circuitBreakerSensitivity

</td>

<td>

[tetrateio.api.tsb.traffic.v2.ResilienceSettings.Sensitivity](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-resiliencesettings-sensitivity) <br/> Circuit breakers in Envoy are applied per endpoint in a load
balancing pool. By default, circuit breakers are disabled. If
set, the sensitivity level determines the maximum number of
consecutive failures that Envoy will tolerate before ejecting an
endpoint from the load balancing pool.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## TrafficSetting {#tetrateio-api-tsb-traffic-v2-trafficsetting}

A traffic setting applies configuration to a set of proxy workloads in a
traffic group or a workspace. When applied to a traffic group,
missing fields will inherit values from the workspace-wide setting if any.



  
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


reachability

</td>

<td>

[tetrateio.api.tsb.traffic.v2.ReachabilitySettings](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-reachabilitysettings) <br/> The set of services and hosts accessed by a workload (and hence
its sidecar) in the mesh. Defining the set of services accessed
by a workload (i.e. its dependencies) in advance reduces the
memory and CPU consumption both the Istio control plane and the
individual Envoy proxy workloads in the data plane.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


resilience

</td>

<td>

[tetrateio.api.tsb.traffic.v2.ResilienceSettings](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-resiliencesettings) <br/> Resilience settings such as timeouts, retries, etc., affecting
outbound traffic from proxy workloads.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


egress

</td>

<td>

[tetrateio.api.tsb.traffic.v2.TrafficSetting.EgressGateway](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-trafficsetting-egressgateway) <br/> Specifies the details of the egress proxy to which unknown
traffic should be forwarded to from the proxy workload. If not
specified, the proxy workload will send the unknown traffic directly to
the IP requested by the application.

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

[tetrateio.api.tsb.gateway.v2.RateLimiting](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-ratelimiting) <br/> Configuration for rate limiting requests.
These settings are only applied to sidecar proxies in the traffic group.
Use the rateLimiting field in the Tier1Gateway and the Ingressgateway API
to configure ratelimiting at the ingressgateway proxies.

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
  


### EgressGateway {#tetrateio-api-tsb-traffic-v2-trafficsetting-egressgateway}

EgressGateway specifies the gateway where traffic external to the mesh will be redirected.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Specifies the egress gateway hostname. Must be in
`<namespace>/<fqdn>` format.

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

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Deprecated. This field is ignored and will be removed in upcoming releases.
Specifies the port on the host to connect to.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




### Mode {#tetrateio-api-tsb-traffic-v2-reachabilitysettings-mode}

A short cut for defining the common reachability patterns


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


UNSET

</td>

<td>

0

</td>

<td>

Inherit from parent if possible. Otherwise treated as `CLUSTER`.

</td>
</tr>
    
<tr>
<td>


NAMESPACE

</td>

<td>

1

</td>

<td>

The workload may talk to any service in its own namespace.

</td>
</tr>
    
<tr>
<td>


GROUP

</td>

<td>

2

</td>

<td>

The workload may talk to any service in the traffic group.

</td>
</tr>
    
<tr>
<td>


WORKSPACE

</td>

<td>

3

</td>

<td>

The workload may talk to any service in the workspace.

</td>
</tr>
    
<tr>
<td>


CLUSTER

</td>

<td>

4

</td>

<td>

The workload may talk to any service in the cluster.

</td>
</tr>
    
<tr>
<td>


CUSTOM

</td>

<td>

5

</td>

<td>

The workload may talk to services defined explicitly.

</td>
</tr>
    
</table>
  



### Sensitivity {#tetrateio-api-tsb-traffic-v2-resiliencesettings-sensitivity}

Available sensitivity levels for the circuit breaker.


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


UNSET

</td>

<td>

0

</td>

<td>

Default values will be used.

</td>
</tr>
    
<tr>
<td>


LOW

</td>

<td>

1

</td>

<td>

Tolerate up to 20 consecutive 5xx or connection failures from an
endpoint before ejecting it temporarily from the load balancing
pool.

</td>
</tr>
    
<tr>
<td>


MEDIUM

</td>

<td>

2

</td>

<td>

Tolerate up to 10 consecutive 5xx or connection failures from an
endpoint before ejecting it temporarily from the load balancing
pool.

</td>
</tr>
    
<tr>
<td>


HIGH

</td>

<td>

3

</td>

<td>

Tolerate up to 5 consecutive 5xx or connection failures from an
endpoint before ejecting it temporarily from the load balancing
pool.

</td>
</tr>
    
</table>
  


