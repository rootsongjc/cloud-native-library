---
title: Servive Registry Registration Service
description: Service to manage registration of services in the TSB Service Registry.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage registration of services in the TSB Service Registry.


## Registration {#tetrateio-api-tsb-registry-v2-registration}

The service registration API allows to manage the services that exist in the catalog.
It exposes methods to register and unregister individual services as well as methods
to keep all the services in a given cluster in sync.


### ListServices

<PanelContent>
<PanelContentCode>

rpc ListServices ([tetrateio.api.tsb.registry.v2.ListServicesRequest](../../../tsb/registry/v2/registration_service#tetrateio-api-tsb-registry-v2-listservicesrequest)) returns ([tetrateio.api.tsb.registry.v2.ListServicesResponse](../../../tsb/registry/v2/registration_service#tetrateio-api-tsb-registry-v2-listservicesresponse))

</PanelContentCode>



List the services that have been registered in an organization

</PanelContent>

### GetService

<PanelContent>
<PanelContentCode>

rpc GetService ([tetrateio.api.tsb.registry.v2.GetServiceRequest](../../../tsb/registry/v2/registration_service#tetrateio-api-tsb-registry-v2-getservicerequest)) returns ([tetrateio.api.tsb.registry.v2.Service](../../../tsb/registry/v2/service#tetrateio-api-tsb-registry-v2-service))

</PanelContentCode>

**Requires** ReadRegisteredService

Get the details of a registered service

</PanelContent>






## GetServiceRequest {#tetrateio-api-tsb-registry-v2-getservicerequest}

Request to retrieve a registered service.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the registered service.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListServicesRequest {#tetrateio-api-tsb-registry-v2-listservicesrequest}

Request to list registered services.



  
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


parent

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list registered services from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListServicesResponse {#tetrateio-api-tsb-registry-v2-listservicesresponse}

Response with a list of registered services



  
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


services

</td>

<td>

List of [tetrateio.api.tsb.registry.v2.Service](../../../tsb/registry/v2/service#tetrateio-api-tsb-registry-v2-service) <br/> The requested registered services

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## RegisterServiceRequest {#tetrateio-api-tsb-registry-v2-registerservicerequest}

Request to register a service in a given parent (organization).



  
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


parent

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Organization where the service will be registered

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


cluster

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the cluster where the service belongs to.
This will be used to load the deduplication settings that have been configured for the cluster
where the service belongs.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

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


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Namespace associated with the service. It will be used in deduplication logic.

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

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Subset denotes a specific version of a service. By default the 'version'
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


source

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Source of the service: Kubernetes, Istio, Consul, etc.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


canonicalName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> optional canonical name that identify this service.

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
  


## UnregisterServiceRequest {#tetrateio-api-tsb-registry-v2-unregisterservicerequest}

Request to unregister a service from the registry



  
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


parent

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Organization from where the service will be unregistered

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


shortName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name attribute of the service

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


cluster

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the cluster of the service.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Namespace of the service.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  



