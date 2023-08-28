---
title: API
description: Configuration for APIs exposed by an Application.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

API objects define a set of servers and endpoints that expose the business logic
for an Application. APIs are attached to existing Applications to configure how the
features exposed by the different services that are part of the Application can be accessed.

The format used to define APIs is based on the OpenAPI v3 spec. Users can attach OpenAPI
documents to the applications, and Service Bridge will generate all the configuration
that is needed to make the APIs available. Service Bridge also provides a set of custom
extensions to the OpenAPI spec that can be used to further customize the APIs in those
cases where the standard OpenAPI properties are not sufficient.

The following example shows how an API can be attached to an existing application:

```yaml
apiversion: application.tsb.tetrate.io/v2
kind: API
metadata:
  organization: my-org
  tenant: tetrate
  application: example-app
  name: ezample-app-api
spec:
  description: An example OpenAPI based API
  workloadSelector:
    namespace: exampleapp
    labels:
      app: exampleapp-gateway
  openapi: |
    openapi: 3.0.0
    info:
      title: Sample API
      description: An example API defined in an OpenAPI spec
      version: 0.1.9
      x-tsb-service: sample-app.sample-ns   # service exposing this api
    servers:
    - url: http://api.example.com/v1
      description: Optional server description, e.g. Main (production) server
    - url: http://staging-api.example.com
    paths:
      /users:
        get:
          summary: Returns a list of users.
          description: Optional extended description in CommonMark or HTML.
          responses:
            '200':    # status code
              description: A JSON array of user names
              content:
                application/json:
                  schema: 
                    type: array
                    items: 
                      type: string
```





## API {#tetrateio-api-tsb-application-v2-api}

An API configuring a set of servers and endpoints that expose the Application business logic.



  
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


openapi

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The raw OpenAPI spec for this API.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


workloadSelector

</td>

<td>

[tetrateio.api.tsb.types.v2.WorkloadSelector](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-workloadselector) <br/> Optional selector to specify the gateway workloads (pod labels and Kubernetes
namespace) under the application gateway group that should be configured with
this gateway. There can be only one gateway for a workload selector in a namespace.
If the selector is omitted, then the following default workload selector will be applied,
based on the name of the Application and the API objects.

```yaml
workloadSelector:
  namespace: exampleapp
  labels:
    app: application-name
    api: api-name
```

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


servers

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.HttpServer](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-httpserver) <br/> _OUTPUT_ONLY_ <br/> DEPRECATED: For new created APIs, the exposed servers will be available at httpServers.
For APIs created before version 1.7, will still be available in this field.

List of ingress gateways servers that expose the API.
Server hostnames must be unique in the system, and only one API can expose a specific hostname.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


endpoints

</td>

<td>

List of [tetrateio.api.tsb.application.v2.HTTPEndpoint](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-httpendpoint) <br/> _OUTPUT_ONLY_ <br/> List of endpoints exposed by this API.
This field is read-only and generated from the configured OpenAPI spec.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


httpServers

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.HTTP](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-http) <br/> _OUTPUT_ONLY_ <br/> List of gateways servers that expose the API.
Server hostnames must be unique in the system, and only one API can expose a specific hostname.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ExposedBy {#tetrateio-api-tsb-application-v2-exposedby}

The exposer of an HTTPEndpoint.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> exposer</sup>_ <br/> _OUTPUT_ONLY_ <br/> The FQN of the service in the service registry that is exposing a concrete endpoint.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


clusterGroup

</td>

<td>

[tetrateio.api.tsb.application.v2.ExposedByClusters](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-exposedbyclusters) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> exposer</sup>_ <br/> _OUTPUT_ONLY_ <br/> The clusters that are exposing a concrete endpoint.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ExposedByCluster {#tetrateio-api-tsb-application-v2-exposedbycluster}

ExposedByCluster is a cluster or set of clusters identified by the labels that are
exposing an endpoint.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The name of the cluster exposing the endpoint. Only one of name or labels
must be specified.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


labels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Labels associated with the cluster. Any cluster with matching
labels will be selected as an exposer. Only one of name or labels
must be specified.

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The weight for traffic to a cluster exposing the endpoint.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ExposedByClusters {#tetrateio-api-tsb-application-v2-exposedbyclusters}

ExposedByClusters represents the clusters that are exposing a concrete endpoint.



  
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

List of [tetrateio.api.tsb.application.v2.ExposedByCluster](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-exposedbycluster) <br/> The clusters that contain gateways exposing the HTTPEndpoint.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## HTTPEndpoint {#tetrateio-api-tsb-application-v2-httpendpoint}

An HTTP Endpoint represents an individual HTTP path exposed in the API.



  
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


path

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> The HTTP path of the endpoint, relative to the hostnames exposed by the API.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


methods

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> The list of HTTP methods this endpoint supports.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hostnames

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> The list of hostnames where this endpoint is exposed.
If omitted, the endpoint is assumed to be exposed in all hostnames defined for the API.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> DEPRECATED: For new created APIs, the exposed servers will be available at httpServers.
For APIs created before version 1.7, will still be available in this field.
The FQN of the service in the service registry that is exposing this endpoint.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


exposedBy

</td>

<td>

[tetrateio.api.tsb.application.v2.ExposedBy](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-exposedby) <br/> _OUTPUT_ONLY_ <br/> The exposer of this endpoint.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ConfigResource {#tetrateio-api-tsb-application-v2-configresource}

ConfigResource represents a configuration object (group, ingress gateway, etc)
that is related to an Application or API.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> The FQN of the resource this status is computed for.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


expectedEtag

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> The expected etag field is used to check the if the configuration resource contents have
changed. This might not be relevant for all configuration resources, so this field may
not be set. If it is not set, the status will only report the presence or absence of the
configuration resource, but not differences in its contents.

When this field is present, the status will also reflect changes in the contents of the
configuration resource, and report it as DIRTY if there are differences.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


exclusivelyOwned

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> The exclusively owned flag indicates if the referenced configuration resource is exclusively
owned by the object. Configuration resources that are exclusively owned by an object will
be deleted when the object is deleted.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ResourceStatus {#tetrateio-api-tsb-application-v2-resourcestatus}

The ResourceStatus object provides information about the status of the configuration
related to an Application or an API object.

Applications and APIs are translated into configuration objects (config groups, ingress
gateways, etc). This status object reflects the status of the Application and APIs with
regard to the generated configuration, and exposes any configuration mismatch.
This status only reflects the status of the configuration objects in Service Bridge. It
does not provide information about the status of the generated configuration in the final
clusters.



  
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


status

</td>

<td>

[tetrateio.api.tsb.application.v2.Status](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-status) <br/> _OUTPUT_ONLY_ <br/> The aggregated configuration status for the Application/API.
In the case of applications, the status will also reflect the aggregated status of
the APIs attached to the application; if any of the APIs is missing / dirty, the
application status will reflect that.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


resources

</td>

<td>

List of [tetrateio.api.tsb.application.v2.ResourceStatus.ConfigResourceStatus](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-resourcestatus-configresourcestatus) <br/> _OUTPUT_ONLY_ <br/> List of the individual configuration resource statuses.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### ConfigResourceStatus {#tetrateio-api-tsb-application-v2-resourcestatus-configresourcestatus}

Individual status for a configuration resource related to the Application/API.



  
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


status

</td>

<td>

[tetrateio.api.tsb.application.v2.Status](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-status) <br/> _OUTPUT_ONLY_ <br/> The configuration status for the individual configuration resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


resource

</td>

<td>

[tetrateio.api.tsb.application.v2.ConfigResource](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-configresource) <br/> _OUTPUT_ONLY_ <br/> The resource for which the status has been computed.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




## Status {#tetrateio-api-tsb-application-v2-status}

The computed configuration status for the Application or API.


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


UNKNOWN

</td>

<td>

0

</td>

<td>

Unknown indicates that the status has not been computed.

</td>
</tr>
    
<tr>
<td>


MISSING

</td>

<td>

1

</td>

<td>

The missing status indicates that the configuration resource for the Applications
or APIs do not exist.

</td>
</tr>
    
<tr>
<td>


DIRTY

</td>

<td>

2

</td>

<td>

Dirty Applications and APIs are those that have the corresponding configuration
objects (config groups, ingress gateways, etc), but those objects have been
directly modified or they current configuration does not match the one specified
in the corresponding Application/API.

</td>
</tr>
    
<tr>
<td>


CONFIGURED

</td>

<td>

3

</td>

<td>

Configured Applications and APIs are those that have the corresponding
configuration resources (config groups, ingress gateways, etc) and their
configurations match the ones defined in the Application/API objects.

</td>
</tr>
    
</table>
  


