---
title: Registered Service
description: Configuration for onboarding clusters.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Services in the registry represent logically a service that can be running in different compute
platforms and different locations. The same service could be running on different Kubernetes
clusters at the same time, on VMS, etc.
A service in the registry represents an aggregated and logical view for all those individual
services, and provides high-level features such as aggregated metrics.





## Port {#tetrateio-api-tsb-registry-v2-port}

Port exposed by a service.
Registration RPC will complete the instances field by assigning the physical services FQNs.



  
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


number

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> A valid non-negative integer port number.

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Name assigned to the port.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceDeployments

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> The list of FQNs of the instances that expose this port

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Service {#tetrateio-api-tsb-registry-v2-service}

A service in the registry that represents an aggregated and logical view for all those individual
services, and provides high-level features such as aggregated metrics.



  
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


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> Fully-qualified name of the resource. This field is read-only.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


displayName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> User friendly name for the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


etag

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The etag for the resource. This field is automatically computed and must be sent
on every update to the resource to prevent concurrent modifications.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


description

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> A description of the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


shortName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Short name for the service, used to uniquely identify it within the organization.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


hostnames

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The hostnames by which this service is accessed. Can correspond to the hostname of
an internal service or that ones of a virtual host on a gateway.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ports

</td>

<td>

List of [tetrateio.api.tsb.registry.v2.Port](../../../tsb/registry/v2/service#tetrateio-api-tsb-registry-v2-port) <br/> The set of ports on which this service is exposed.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


subsets

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> Deprecated. Use subset_deployments instead.
Subset denotes a specific version of a service. By default the 'version'
label is used to designate subsets of a workload.
Known subsets for the service.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceType

</td>

<td>

[tetrateio.api.tsb.registry.v2.ServiceType](../../../tsb/registry/v2/service#tetrateio-api-tsb-registry-v2-servicetype) <br/> _REQUIRED_ <br/> Internal/external/load balancer service.

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


externalAddresses

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> For kubernetes services of type load balancer, this field contains the list of lb hostnames or
IPs assigned to the service.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


state

</td>

<td>

[tetrateio.api.tsb.registry.v2.State](../../../tsb/registry/v2/service#tetrateio-api-tsb-registry-v2-state) <br/> _REQUIRED_ <br/> State of the service (registered/observed/controlled)

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


metrics

</td>

<td>

List of [tetrateio.api.tsb.registry.v2.Service.MetricConfig](../../../tsb/registry/v2/service#tetrateio-api-tsb-registry-v2-service-metricconfig) <br/> _OUTPUT_ONLY_ <br/> Services may expose different metrics.
For example, a regular service may expose the usual red metrics for incoming requests.
Services running in multiple clusters, may provide different aggregation levels, such as
aggregation by cluster, by subset, etc.
This list provides a complete list of all the aggregation keys that are available for this
particular service.
For example, a service that has instances in multiple clusters could provide the following
metrics:

  - global:        *|productpage|bookinfo|*|*
  - v1:            v1|productpage|bookinfo|*|*
  - v1 (cluster1): v1|productpage|bookinfo|cluster1|*

This is only available for Observed and Controlled services.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceDeployments

</td>

<td>

List of [tetrateio.api.tsb.registry.v2.Service.ServiceDeployment](../../../tsb/registry/v2/service#tetrateio-api-tsb-registry-v2-service-servicedeployment) <br/> _OUTPUT_ONLY_ <br/> List of the existing deployments for this service.
This is only available for internal and load balancer services and correspond to physical services
in the onboarded clusters.
This field is read-only.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


subsetDeployments

</td>

<td>

List of [tetrateio.api.tsb.registry.v2.Subset](../../../tsb/registry/v2/service#tetrateio-api-tsb-registry-v2-subset) <br/> _OUTPUT_ONLY_ <br/> Subset denotes a specific version of a service. By default the 'version'
label is used to designate subsets of a workload.
Known subsets for the service.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


canonicalName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The canonical name of the service defined by user

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


spiffeIds

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of SPIFFE identities used by the workloads of the service.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### MetricConfig {#tetrateio-api-tsb-registry-v2-service-metricconfig}

Configuration for metric aggregation



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> A user friendly name for this metric.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


description

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> A helpful description of what this metric represents.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


aggregationKey

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> An aggregation key that can be queried to get metrics for this service.

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

[tetrateio.api.tsb.registry.v2.Service.MetricConfig.MetricType](../../../tsb/registry/v2/service#tetrateio-api-tsb-registry-v2-service-metricconfig-metrictype) <br/> Type of the metric (single_instance/aggregated).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceDeployment

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The FQN of the service deployment related with this metric. Will be empty for group metrics.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


parentMetric

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The name of the metric config that aggregates this one in a higher level.
For example, for a subset in a cluster metric, this field has the name of the metric of the same subset
across the clusters

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### ServiceDeployment {#tetrateio-api-tsb-registry-v2-service-servicedeployment}

ServiceDeployment represents the physical service in a cluster.



  
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


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> Fully-qualified name of the instance. This field is read-only.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


source

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> Source of the instance. This field is read-only.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Subset {#tetrateio-api-tsb-registry-v2-subset}

Subset exposed by a service.
Registration RPC will complete the instances field by assigning the physical services FQNs.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> A valid subset name of a service.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceDeployments

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> The list of FQNs of the service deployments that expose this subset

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




#### MetricType {#tetrateio-api-tsb-registry-v2-service-metricconfig-metrictype}

MetricType denotes the relation of a metrics with a physical service instance.


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


SINGLE_INSTANCE

</td>

<td>

1

</td>

<td>

A single instance metric config belongs to an specific physical service instance.

</td>
</tr>
    
<tr>
<td>


SUBSET

</td>

<td>

2

</td>

<td>

A subset metric config represents subsets across clusters or hostnames across clusters.

</td>
</tr>
    
<tr>
<td>


GLOBAL

</td>

<td>

3

</td>

<td>

A global metric config represents all the physical services.

</td>
</tr>
    
<tr>
<td>


ENDPOINT

</td>

<td>

4

</td>

<td>

An endpoint metric config represents an endpoint across clusters.

</td>
</tr>
    
<tr>
<td>


ENDPOINT_INSTANCE

</td>

<td>

5

</td>

<td>

An endpoint instance metric config represents an endpoint in a specific cluster.

</td>
</tr>
    
</table>
  



## ServiceType {#tetrateio-api-tsb-registry-v2-servicetype}

ServiceType denotes the exposition of a service in the mesh.


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


INVALID_TYPE

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


INTERNAL

</td>

<td>

1

</td>

<td>

A regular service that is not directly exposed to the outside world.

</td>
</tr>
    
<tr>
<td>


LOADBALANCER

</td>

<td>

2

</td>

<td>

A load balancer service running only the proxy as the workload.

</td>
</tr>
    
<tr>
<td>


MESH_EXTERNAL

</td>

<td>

3

</td>

<td>

A mesh external service.

</td>
</tr>
    
</table>
  



## State {#tetrateio-api-tsb-registry-v2-state}

State denotes how deep is the knowledge of a service by the mesh. Meaning that if a service can be controlled,
observed or none of these.


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


INVALID_STATE

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


EXTERNAL

</td>

<td>

1

</td>

<td>

An external service is a service that is known, but that cannot be observed (we can&#39;t get metrics for it)
and cannot be controlled.

</td>
</tr>
    
<tr>
<td>


OBSERVED

</td>

<td>

2

</td>

<td>

An observed service is a known service that we can have metrics for. For example, a service running the
Skywalking agents.

</td>
</tr>
    
<tr>
<td>


CONTROLLED

</td>

<td>

3

</td>

<td>

A controlled service is a service that is part of the mesh and has a proxy we can configure.

</td>
</tr>
    
</table>
  


