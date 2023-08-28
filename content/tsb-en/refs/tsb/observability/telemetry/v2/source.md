---
title: Source
description: A group of metrics observing scoped resources.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`Source` describes a set of observed resources that have a group of metrics that emit measurements at runtime.
A source specifies **what** is being observed (which resource types: service, ingress hostnames,
relation, ...) and **how** it is being observed (with which scope of observation).

A telemetry source can observe different types of resources in a single or aggregated way depending on the defined
scope. A scope can be of type ServiceScope, IngressScope, or RelationScope, and they define the wingspan of the
telemetry source in the mesh. Each scope contains information to determine if it is a single standalone source or an
aggregation of standalone sources of the same type.

ServiceScope can be one of the following types which define the span of a service's telemetry source in the mesh as:
- INSTANCE: A single specific service instance (pod or VM) in a cluster.
- SERVICE: An aggregation of all instances of a specific service of a concrete version (subset) in a cluster.
- SUBSET: An aggregation of all instances of a specific service of a concrete version (subset) across clusters.
- GLOBAL: An aggregation of all instances from all the versions of a specific service across clusters.

IngressScope can be one the following types which define the span of Ingress hostname's telemetry source in the mesh as:
- HOSTNAME: A ingress's hostname in a concrete cluster.
- GLOBAL: A ingress's hostname across clusters.

A Telemetry source can also observe relation between resources. A relation is the physical connection between
resources when a call between them has been done. For instance, a relation exists when a gateway calls a service or
vice versa, or a service calls another service. That relation (call) can be seen (detected) from the server side,
client-side, or both.
For instance, when a gateway calls a service, and both resources are observed, the relation can be seen from both
sides, the client and the server. In this case, the gateway is the client-side of the relation observation and the
service is the server side of the observation. Each of the observation points (client or server) in the relation will
produce different measurements for the same metric. Which means that, if we take the duration metric of the relation,
we will have a concrete value (measurement) from the client point of view and another value from the server point
view, where the client-side observed duration will be greater than the server side duration, in which the difference
between durations is the network/transport introduced latency.

RelationScope can be one the following types which define the span of a relation telemetry source in the mesh as:
- SERVICE: A relation between logical services.

To understand a bit better **what** and **how** a telemetry source can observe, let's assume we have deployed the classic
Istio [bookinfo demo application](https://istio.io/latest/docs/examples/bookinfo/) in 2 clusters, `demo` and
`demo-disaster-recovery`.
If we take as an example the reviews service which has 3 different versions (subsets V1, V2, and V3) for **what** is
being observed, we will have different telemetry sources available which will tell us **how** (which scope) they are
being observed.

An INSTANCE scoped telemetry source for a concrete review service instance (pod) running on the demo cluster will be:
```yaml
apiVersion: observability.telemetry.tsb.tetrate.io/v2
kind: Source
metadata:
  organization: myorg
  service: reviews.bookinfo
  name: reviews-v1-545db77b95-vhtlj
spec:
  belongsTo: organizations/myorg/services/reviews.bookinfo
  metric_source_key: djF8cmV2aWV3c3xib29raW5mb3xkZW1vfC0=.1_cmV2aWV3cy12MS01NDVkYjc3Yjk1LXZodGxq
  service_scopes:
    - type: INSTANCE
      scope:
        instance: reviews-v1-545db77b95-vhtlj
        subset: v1
        service: reviews
        namespace: bookinfo
        cluster: demo
      deployment: organizations/myorg/clusters/demo/namespaces/bookinfo/services/reviews
```

A SUBSET scoped telemetry source for the reviews service of v1 subset running on the demo cluster will be:
```yaml
apiVersion: observability.telemetry.tsb.tetrate.io/v2
kind: Source
metadata:
  organization: myorg
  service: reviews.bookinfo
  name: reviews-v1-demo
spec:
  belongsTo: organizations/myorg/services/reviews.bookinfo
  metric_source_key: djF8cmV2aWV3c3xib29raW5mb3xkZW1vfC0=.1
  service_scopes:
    - type: SUBSET
      scope:
        subset: v1
        service: reviews
        namespace: bookinfo
        cluster: demo
      deployment: organizations/myorg/clusters/demo/namespaces/bookinfo/services/reviews
```

A GLOBAL_SUBSET scope telemetry source for the reviews services of version v1 running across clusters will be:
```yaml
apiVersion: observability.telemetry.tsb.tetrate.io/v2
kind: Source
metadata:
  organization: myorg
  service: reviews.bookinfo
  name: reviews-v1
spec:
  belongsTo: organizations/myorg/services/reviews.bookinfo
  metric_source_key: djF8cmV2aWV3c3xib29raW5mb3wqfCo=.1
  service_scopes:
    - type: GLOBAL_SUBSET
      scope:
        subset: v1
        service: reviews
        namespace: bookinfo
      deployment: organizations/myorg/clusters/demo/namespaces/bookinfo/services/reviews
```

A GLOBAL scoped telemetry source for the reviews service of all subsets(v1, v2, and v3) running across all clusters
will be:
```yaml
apiVersion: observability.telemetry.tsb.tetrate.io/v2
kind: Source
metadata:
  organization: myorg
  service: reviews.bookinfo
  name: reviews
spec:
  belongsTo: organizations/myorg/services/reviews.bookinfo
  metric_source_key: djF8cmV2aWV3c3xib29raW5mb3wqfCo=.1
  service_scopes:
    - type: GLOBAL
      scope:
        service: reviews
        namespace: bookinfo
      deployment: organizations/myorg/clusters/demo/namespaces/bookinfo/services/reviews
```





## Source {#tetrateio-api-tsb-observability-telemetry-v2-source}

Source identifies a set of observed resources that have a group of metrics that emit measurements at runtime.



  
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


belongsTo

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> Which concrete TSB resource in the configuration hierarchy this telemetry source belongs to.
For instance, a telemetry source can belong to a service,or a gateway, or a workspace, or any other resource in the
configuration hierarchy.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


metricSourceKey

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> A key to query metric measurements from the resources that the telemetry source is observing.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


type

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScopeType](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescopetype) <br/> The type of resource which the telemetry source is observing, a service, an ingress, or a relation.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


scope

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## SourceScope {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope}

Source scope defines the source's wingspan in the mesh. It defines how we are observing the resources.
For instance we can observer a resources at service, ingress, or relation level.



  
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


serviceScopes

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope.ServiceScopes](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-servicescopes) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> scope</sup>_ <br/> ServiceScopes defines one or many service's telemetry source wingspan in the mesh.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ingressScopes

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope.IngressScopes](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-ingressscopes) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> scope</sup>_ <br/> IngressScopes defines one or many Ingress's telemetry source wingspan in the mesh.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


relationScopes

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope.RelationScopes](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-relationscopes) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> scope</sup>_ <br/> RelationScopes defines one or many Relation's telemetry source wingspan in the mesh.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### IngressScopes {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-ingressscopes}

IngressScopes defines one or many Ingress's hostname telemetry source wingspan in the mesh.



  
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


scopes

</td>

<td>

List of [tetrateio.api.tsb.observability.telemetry.v2.SourceScope.IngressScopes.IngressScope](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-ingressscopes-ingressscope) <br/> Multiple IngressScope can be defined to group under a single telemetry source different ingresses.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### IngressScope {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-ingressscopes-ingressscope}

An ingress defines the telemetry source wingspan in the mesh of ingress's hostname.



  
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


type

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope.IngressScopes.IngressScope.ScopeType](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-ingressscopes-ingressscope-scopetype) <br/> Type of the scope.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


scope

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope.IngressScopes.IngressScope.Scope](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-ingressscopes-ingressscope-scope) <br/> The scope that this telemetry source spans over.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


deployment

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The FQN of the service deployment in a concrete cluster related with this telemetry source scope.
Will have a value for scope types HOSTNAME.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


##### Scope {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-ingressscopes-ingressscope-scope}

Each of the scope properties can have the following values:
- A non empty value.
- An empty value or absence of the property act as a wildcard, meaning any possible value.



  
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


hostname

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> hostname is always a concrete value

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ingressService

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> ingress_service is always a concrete value

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


cluster

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> cluster can be a concrete value or an empty value meaning any cluster.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### RelationScopes {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-relationscopes}

RelationScopes  represents the physical connection that exists between observable resources.
A relation can represent for instance the physical connection that exist when a call between services is done:
- Between a gateway and a service or vice versa.
- Between a service and another service.
This observation can produce client-side measurements, server side measurements or both.



  
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


scopes

</td>

<td>

List of [tetrateio.api.tsb.observability.telemetry.v2.SourceScope.RelationScopes.RelationScope](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-relationscopes-relationscope) <br/> Multiple RelationScope can be defined to group under a single telemetry source different relations.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### RelationScope {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-relationscopes-relationscope}





  
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


type

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope.RelationScopes.RelationScope.ScopeType](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-relationscopes-relationscope-scopetype) <br/> Type of the scope.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


scope

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope.RelationScopes.RelationScope.Scope](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-relationscopes-relationscope-scope) <br/> The scope that this telemetry source spans over.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


##### Scope {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-relationscopes-relationscope-scope}





  
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


serviceRelation

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope.RelationScopes.RelationScope.ServiceRelation](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-relationscopes-relationscope-servicerelation) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> relation_type</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


##### ServiceRelation {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-relationscopes-relationscope-servicerelation}

A relation between logical services.



  
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


source

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The source resource's fqn of the relation between two logical services.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


target

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The target resource's fqn of the relation between two logical services.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### ServiceScopes {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-servicescopes}

ServiceScopes defines one or many service's telemetry source wingspan in the mesh.



  
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


scopes

</td>

<td>

List of [tetrateio.api.tsb.observability.telemetry.v2.SourceScope.ServiceScopes.ServiceScope](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-servicescopes-servicescope) <br/> Multiple ServiceScope can be defined to group under a single telemetry source different services.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### ServiceScope {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-servicescopes-servicescope}

A service scope defines the telemetry source wingspan in the mesh of a service.



  
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


type

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope.ServiceScopes.ServiceScope.ScopeType](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-servicescopes-servicescope-scopetype) <br/> Type of the scope.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


scope

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.SourceScope.ServiceScopes.ServiceScope.Scope](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-servicescopes-servicescope-scope) <br/> The scope that this telemetry source spans over.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


deployment

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The FQN of the service deployment in a concrete cluster related with this telemetry source scope.
Will have a value for scope types INSTANCE or SERVICE.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


##### Scope {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-servicescopes-servicescope-scope}

Each of the scope properties can have the following values:
- A non empty value.
- An empty value or absence of the property act as a wildcard, meaning any possible value.



  
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


instance

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> instance is a concrete value or an empty value meaning any instance.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


subset

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> subset can be a concrete value or an empty value meaning any subset.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


service

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> service is always a concrete value.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> namespace is always a concrete value.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


cluster

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> cluster can be a concrete value or an empty value meaning any cluster.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




##### ScopeType {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-ingressscopes-ingressscope-scopetype}

ScopeType denotes the wingspan of a telemetry source for an ingress's hostname.


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


INVALID

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


HOSTNAME

</td>

<td>

1

</td>

<td>

A hostname telemetry source that belongs to a specific ingress instance in a cluster.

</td>
</tr>
    
<tr>
<td>


GLOBAL

</td>

<td>

2

</td>

<td>

A global telemetry source of a hostname from an ingress across clusters.

</td>
</tr>
    
</table>
  



##### ScopeType {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-relationscopes-relationscope-scopetype}

ScopeType denotes the wingspan of a telemetry source for relation between resources.


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


INVALID

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


SERVICE

</td>

<td>

1

</td>

<td>

A service telemetry source that belongs to a specific relation between logical services.

</td>
</tr>
    
</table>
  



##### ScopeType {#tetrateio-api-tsb-observability-telemetry-v2-sourcescope-servicescopes-servicescope-scopetype}

ScopeType denotes the wingspan of a telemetry source for a service.


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


INVALID

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


INSTANCE

</td>

<td>

1

</td>

<td>

A instance telemetry source belongs to a specific service instance (pod or VM) in a cluster.

</td>
</tr>
    
<tr>
<td>


SERVICE

</td>

<td>

2

</td>

<td>

A service telemetry source belongs to a specific service, without subsets, in a cluster.

</td>
</tr>
    
<tr>
<td>


SUBSET

</td>

<td>

3

</td>

<td>

A subset telemetry source belongs to a specific service of a concrete subset in a cluster.

</td>
</tr>
    
<tr>
<td>


GLOBAL_SUBSET

</td>

<td>

4

</td>

<td>

A global subset telemetry source represents a concrete subset from a service across cluster.
Subset scope type does not apply to ingress services.

</td>
</tr>
    
<tr>
<td>


GLOBAL

</td>

<td>

5

</td>

<td>

A global telemetry source represents all subsets from a service across clusters.

</td>
</tr>
    
</table>
  



## SourceScopeType {#tetrateio-api-tsb-observability-telemetry-v2-sourcescopetype}

The type of scopes which defines telemetry source's wingspan in the mesh.


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


INVALID

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


SERVICE

</td>

<td>

1

</td>

<td>

A telemetry source service based scope.

</td>
</tr>
    
<tr>
<td>


INGRESS

</td>

<td>

2

</td>

<td>

A telemetry source ingress&#39;s hostname based scope.

</td>
</tr>
    
<tr>
<td>


RELATION

</td>

<td>

3

</td>

<td>

A telemetry source relation based scope.

</td>
</tr>
    
</table>
  


