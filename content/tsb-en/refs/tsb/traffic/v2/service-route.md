---
title: Service Route
description: Configuration affecting routing for services in a traffic group.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service Routes can be used by service owners to configure traffic shifting
across different versions of a service in a Traffic Group. The traffic to
this service can originate from sidecars in the same or different traffic
groups, as well as gateways.

The following example yaml defines a Traffic Group `g1` in the namespaces
`ns1`, `ns2` and `ns3`, owned by its parent Workspace `w1`.
Then it defines a Service Route for the `reviews` service in the `ns1`
namespace with two subsets: `v1` and `v2`, where 80% of the traffic to the
reviews service is sent to `v1` while the remaining 20% is sent to `v2`.

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  name: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelectors:
  - name: "*/ns1"
  - name: "*/ns2"
  - name: "*/ns3"
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: reviews
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  service: ns1/reviews.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
    weight: 80
  - name: v2
    labels:
      version: v2
    weight: 20
```

Server side load balancing can be set through the combination of
`portLevelSettings` and `stickySession`.
The following ServiceRoute will generate two routes:
1. An HTTP route matching traffic on port 8080 and routing it 80:20 between
   v1:v2, targeting port 8080. The server side load balancing will be based
   on `header`.
2. A TCP route matching traffic on port 443, and routing it 80:20 between
   v1:v2, targeting port 443. The server side load balancing will be based
   on `source IP`.

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: reviews
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  service: ns1/reviews.svc.cluster.local
  portLevelSettings:
  - port: 8080
    trafficType: HTTP
    stickySession:
      header: x-session-hash
  - port: 443
    trafficType: TCP
    stickySession:
      useSourceIp: true
  subsets:
  - name: v1
    labels:
      version: v1
    weight: 80
  - name: v2
    labels:
      version: v2
    weight: 20
```

**Note**: For TCP routes, only source IP (`useSourceIp: true`) is a valid
load balancing hash key. Any other hash keys will be invalid.

You can also apply port settings just to a subset, such as in the following
example where for subset `v2` the source IP is used for sticky sessions.

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: reviews
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  service: ns1/reviews.svc.cluster.local
  portLevelSettings:
   - port: 8000
     trafficType: TCP
   - port: 443
     trafficType: HTTP
     stickySession:
       header: x-sticky-hash
 subsets:
   - name: v1
     labels:
       version: v1
     weight: 80
   - name: v2
     labels:
       version: v2
     weight: 20
     portLevelSettings:
       - port: 8000
         trafficType: TCP
         stickySession:
           useSourceIp: true
```

If the service exposes more than one port, then all such ports with
protocols need to be specified in top level `portLevelSettings`. Explicit
routes can be specified within `httpRoutes` or `tcpRoutes` sections. You can
also specify match conditions within each httpRoute to match the incoming
traffic and route the traffic accordingly.

The ServiceRoute below has two HTTP routes:
1. The first route matches traffic on
  `reviews.svc.cluster.local:8080/productpage` endpoint and `end-user: jason`
  header and routes 80% of traffic to subset "v1" and 20% to subset "v2".
2. The second route is the default HTTP route, which matches traffic on
   `reviews.ns1.svc.cluster.local:8080/productpage` endpoint, and routes 50% of
   traffic to subset "v1" and remaining 50% to subset "v2".

```yaml
apiVersion: traffic.xcp.tetrate.io/v2
kind: ServiceRoute
metadata:
  name: reviews
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  service: ns1/reviews.svc.cluster.local
  portLevelSettings:
    - port: 8080
      trafficType: HTTP
  subsets:
    - name: v1
      labels:
        version: v1
      weight: 80
    - name: v2
      labels:
        version: v2
      weight: 20
  httpRoutes:
    - name: http-route-match-productpage-endpoint
      match:
        - name: match-productpage-endpoint
          uri:
            prefix: /productpage
          headers:
            end-user:
              exact: jason
          port: 8080
      destination:
        - subset: v1
          weight: 80
          port: 8080
        - subset: v2
          weight: 20
          port: 8080
    - name: http-route-default
      match:
        - name: match-default
          uri:
            prefix: /productpage
          port: 8080
      destination:
        - subset: v1
          weight: 50
          port: 8080
        - subset: v2
          weight: 50
          port: 8080
```

**Note**: Default routes will be generated automatically **only** if a port
is specified in top level `portLevelSettings` but not used in any match
conditions of httpRoutes, tcpRoutes or tlsRoutes (or if no routes are
specified). In all other conditions, all routes have to defined
**explicitly**.

For example, the ServiceRoute below will generate a `default-http-route`
matching on port `8080` and will route traffic in the ratio 80:20 between
v1:v2.

```yaml
 apiVersion: traffic.xcp.tetrate.io/v2
 kind: ServiceRoute
metadata:
  name: reviews
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
 spec:
   service: ns1/reviews.ns1.svc.cluster.local
   portLevelSettings:
     - port: 8080
       trafficType: HTTP
   subsets:
     - name: v1
       labels:
         version: v1
       weight: 80
     - name: v2
       labels:
         version: v2
       weight: 20
```

Finally, a similar example but for TCP traffic where all the traffic for
port 666 will be sent to v1 subset.

```yaml
 apiVersion: traffic.tsb.tetrate.io/v2
 kind: ServiceRoute
 metadata:
   name: reviews
   group: t1
   workspace: w1
   tenant: mycompany
   organization: myorg
 spec:
   service: ns1/reviews.ns1.svc.cluster.local
   portLevelSettings:
     - port: 6666
       trafficType: TCP
   subsets:
     - name: v1
       labels:
         version: v1
       weight: 50
     - name: v2
       labels:
         version: v2
       weight: 50
   tcpRoutes:
     - name: tcp-route-match-port-6666-v1-100
       match:
         - name: match-condition-port-6666-v1-100
           port: 6666
       destination:
         - subset: v1
           weight: 100
           port: 6666
```





## HTTPMatchCondition {#tetrateio-api-tsb-traffic-v2-httpmatchcondition}

HTTPMatchCondition is the set of conditions to match incoming HTTP traffic
and route accordingly. We could have used HttpMatchCondition from
ingress_gateway.proto but it doesn't have a port field, so it's better to
create one natively.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the match condition

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


uri

</td>

<td>

[tetrateio.api.tsb.gateway.v2.StringMatch](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-stringmatch) <br/> Incoming URI to match in incoming traffic for routing forward

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


headers

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [tetrateio.api.tsb.gateway.v2.StringMatch](../../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-stringmatch)> <br/> Headers to match in incoming traffic for routing forward

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Port to match in incoming traffic

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## HTTPRoute {#tetrateio-api-tsb-traffic-v2-httproute}

HTTPRoute is used to set HTTP routes to service destinations on the basis of match conditions.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of HTTPRoute

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


match

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.HTTPMatchCondition](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-httpmatchcondition) <br/> Match conditions for incoming HTTP traffic

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


destination

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.ServiceDestination](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-servicedestination) <br/> Destination host:port and subset where HTTP traffic should be directed

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ServiceDestination {#tetrateio-api-tsb-traffic-v2-servicedestination}

ServiceDestination is the destination service, port and subset where traffic
should be routed



  
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


subset

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Subset is the version of the service where traffic should be routed to

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


weight

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Weight defines the amount of traffic that needs to be routed to this specific
version

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The port corresponding to the service host where traffic should be routed

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


destinationHost

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Service host where traffic should be routed to. This should either be a FQDN
or a short name for the k8s service. For example, "reviews" as destination_host will
be interpreted as "reviews.ns1.cluster.local"

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ServiceRoute {#tetrateio-api-tsb-traffic-v2-serviceroute}

A service route controls routing configurations for traffic to a
service in a traffic group.



  
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


service

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The service on which the configuration is being applied. Must be in namespace/FQDN format.

</td>

<td>

string = {<br/>&nbsp;&nbsp;pattern: `^[^/]+/[^/]+$`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


subsets

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.ServiceRoute.Subset](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute-subset) <br/> _REQUIRED_ <br/> The set of versions of a service and the percentage of traffic to
send to each version.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


stickySession

</td>

<td>

[tetrateio.api.tsb.traffic.v2.ServiceRoute.StickySession](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute-stickysession) <br/> StickySession specifies how to forward traffic from a client to the same backend

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


portLevelSettings

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.ServiceRoute.PortLevelTrafficSettings](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute-portleveltrafficsettings) <br/> In order to support multi-protocol routing, a list of all port/protocol combinations is needed.
These port settings are applied to all the subsets

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


httpRoutes

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.HTTPRoute](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-httproute) <br/> HTTPRoutes are used when HTTP traffic needs to be matched on uri, headers
and port and destination routes need to be set using subset-weight
combinations specified within the route.
**Note**: If a route is specified, then the global subset-weight
combinations (specified under subsets) will be ignored for the matched
port, as subsets within route will take effect.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tcpRoutes

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.TCPRoute](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-tcproute) <br/> TCPRoutes match TCP traffic based on port number. The subset-weight
configuration and priority have the same behaviour as HTTPRoutes.

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
  


### PortLevelTrafficSettings {#tetrateio-api-tsb-traffic-v2-serviceroute-portleveltrafficsettings}

PortLevelTrafficSettings explicitly defines the type of traffic for all of
the ports exposed by a service for which routing rules need to be set.
Depending on whether HTTPRoutes or TCTRoutes are specified or not, the main
subset weights are applied or not based on the following scenarios:
1. If HTTPRoutes or TCPRoutes are specified:
   a. Since Port is mandatory in MatchConditions, whenever a port is used
      in (HTTP/TCP) MatchCondition, it needs to be present in the global
      PortLevelTrafficSettings.
   b. When MatchConditions are present in the routes, then subset-weight
      combinations within routes will take effect instead of the global ones.
2. If the routes are not specified, then the traffic will be matched on
   ports specified in PortLevelTrafficSettings, and the routes will be set
   according to global subset-weight combinations.



  
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


port

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Port number to which traffic must be routed

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


trafficType

</td>

<td>

[tetrateio.api.tsb.traffic.v2.ServiceRoute.TrafficType](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute-traffictype) <br/> _REQUIRED_ <br/> Type of traffic for which a route has to be generated

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


stickySession

</td>

<td>

[tetrateio.api.tsb.traffic.v2.ServiceRoute.StickySession](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute-stickysession) <br/> Since we are supporting multiple types of protocols, so we expect to have separate sticky sessions
for each route (i.e. for a specific port/protocol combination)

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### StickySession {#tetrateio-api-tsb-traffic-v2-serviceroute-stickysession}

If set, all requests from a client will be forward to the same backend.



  
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


header

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> hash_key</sup>_ <br/> Hash based on a specific HTTP header.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


cookie

</td>

<td>

[tetrateio.api.tsb.traffic.v2.ServiceRoute.StickySession.HTTPCookie](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute-stickysession-httpcookie) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> hash_key</sup>_ <br/> Hash based on HTTP cookie.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


useSourceIp

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> hash_key</sup>_ <br/> Hash based on the source IP address.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### HTTPCookie {#tetrateio-api-tsb-traffic-v2-serviceroute-stickysession-httpcookie}

Describes a HTTP cookie that will be used for sticky sessions. If the cookie is not present, it
will be generated.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the cookie.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


path

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Path to set for the cookie.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


ttl

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> _REQUIRED_ <br/> Lifetime of the cookie.

</td>

<td>

timestamp = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


### Subset {#tetrateio-api-tsb-traffic-v2-serviceroute-subset}

Subset denotes a specific version of a service. The pods/VMs of a
subset should be uniquely identifiable using their labels.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name used to refer to the subset.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


labels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Labels apply a filter over the endpoints of a service in the service registry.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


weight

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Percentage of traffic to be sent to this subset. Weight if not
specified will be assumed to be 0 if there are multiple
subsets. If there is only one subset, the weight will be
assumed to be 1.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


portLevelSettings

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.ServiceRoute.PortLevelTrafficSettings](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute-portleveltrafficsettings) <br/> Port/Protocol/StickySession combination for which routes need to be generated specifically for
a subset. These settings are meant to override the global PortLevelTrafficSettings, i.e. first, 
global PortLevelTrafficSettings are used to generate routes and then we use non-conflicting subset level 
PortLevelTrafficSettings to modify existing routes. If provided, PortLevelTrafficSettings should be provided for 
all subsets for proper load balancing.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## TCPMatchCondition {#tetrateio-api-tsb-traffic-v2-tcpmatchcondition}

TCPMatchCondition is the set of conditions to match incoming TCP traffic
and route accordingly



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the match condition

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> TCP match conditions only have port in match conditions

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## TCPRoute {#tetrateio-api-tsb-traffic-v2-tcproute}

TCPRoute is used to set TCP routes to service destinations on the basis of match conditions.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of TCPRoute

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


match

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.TCPMatchCondition](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-tcpmatchcondition) <br/> Match conditions for incoming TCP traffic

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


destination

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.ServiceDestination](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-servicedestination) <br/> Destination host:port and subset where TCP traffic should be directed

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




### TrafficType {#tetrateio-api-tsb-traffic-v2-serviceroute-traffictype}

TrafficType is the list of allowed traffic types for generating routes


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


HTTP

</td>

<td>

0

</td>

<td>

If trafficType is HTTP, then a HTTP route is generated for that port

</td>
</tr>
    
<tr>
<td>


TCP

</td>

<td>

1

</td>

<td>

If trafficType is TCP, then a TCP route is generated for that port

</td>
</tr>
    
<tr>
<td>


TLS_PASSTHROUGH

</td>

<td>

2

</td>

<td>

This mode generates TLS routes for HTTPS traffic. TLS is not terminated at the gateway and is
passed through to the server

</td>
</tr>
    
</table>
  


