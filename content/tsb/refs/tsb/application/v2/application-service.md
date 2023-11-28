---
title: Application Service
description: Service to manage Applications and APis
---

<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage Applications and APis


## Applications {#tetrateio-api-tsb-application-v2-applications}

The Applications service exposes methods to manage Applications and API
definitions in Service Bridge.


### CreateApplication

<PanelContent>
<PanelContentCode>

rpc CreateApplication ([tetrateio.api.tsb.application.v2.CreateApplicationRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-createapplicationrequest)) returns ([tetrateio.api.tsb.application.v2.Application](../../../tsb/application/v2/application#tetrateio-api-tsb-application-v2-application))

</PanelContentCode>

**Requires** CREATE

Creates a new Application in TSB.

</PanelContent>

### GetApplication

<PanelContent>
<PanelContentCode>

rpc GetApplication ([tetrateio.api.tsb.application.v2.GetApplicationRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-getapplicationrequest)) returns ([tetrateio.api.tsb.application.v2.Application](../../../tsb/application/v2/application#tetrateio-api-tsb-application-v2-application))

</PanelContentCode>

**Requires** READ

Get the details of an existing application.

</PanelContent>

### UpdateApplication

<PanelContent>
<PanelContentCode>

rpc UpdateApplication ([tetrateio.api.tsb.application.v2.Application](../../../tsb/application/v2/application#tetrateio-api-tsb-application-v2-application)) returns ([tetrateio.api.tsb.application.v2.Application](../../../tsb/application/v2/application#tetrateio-api-tsb-application-v2-application))

</PanelContentCode>

**Requires** WRITE

Modify an existing application.

</PanelContent>

### ListApplications

<PanelContent>
<PanelContentCode>

rpc ListApplications ([tetrateio.api.tsb.application.v2.ListApplicationsRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-listapplicationsrequest)) returns ([tetrateio.api.tsb.application.v2.ListApplicationsResponse](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-listapplicationsresponse))

</PanelContentCode>



List all existing applications for the given tenant.

</PanelContent>

### DeleteApplication

<PanelContent>
<PanelContentCode>

rpc DeleteApplication ([tetrateio.api.tsb.application.v2.DeleteApplicationRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-deleteapplicationrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete an existing Application.
Note that deleting resources in TSB is a recursive operation. Deleting a application will delete all
API objects that exist in it.

</PanelContent>

### GetApplicationStatus

<PanelContent>
<PanelContentCode>

rpc GetApplicationStatus ([tetrateio.api.tsb.application.v2.GetStatusRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-getstatusrequest)) returns ([tetrateio.api.tsb.application.v2.ResourceStatus](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-resourcestatus))

</PanelContentCode>

**Requires** ReadApplication

Get the configuration status of an existing application.

</PanelContent>

### CreateAPI

<PanelContent>
<PanelContentCode>

rpc CreateAPI ([tetrateio.api.tsb.application.v2.CreateAPIRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-createapirequest)) returns ([tetrateio.api.tsb.application.v2.API](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-api))

</PanelContentCode>

**Requires** CREATE

Attach a new API to the given application.

</PanelContent>

### GetAPI

<PanelContent>
<PanelContentCode>

rpc GetAPI ([tetrateio.api.tsb.application.v2.GetAPIRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-getapirequest)) returns ([tetrateio.api.tsb.application.v2.API](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-api))

</PanelContentCode>

**Requires** READ

Get the details of an API.

</PanelContent>

### UpdateAPI

<PanelContent>
<PanelContentCode>

rpc UpdateAPI ([tetrateio.api.tsb.application.v2.API](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-api)) returns ([tetrateio.api.tsb.application.v2.API](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-api))

</PanelContentCode>

**Requires** WRITE

Deprecated. Use the `UpdateAPIWithParams ` method instead.
Modifies an existing API object if its status is not DIRTY.

</PanelContent>

### UpdateAPIWithParams

<PanelContent>
<PanelContentCode>

rpc UpdateAPIWithParams ([tetrateio.api.tsb.application.v2.UpdateAPIRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-updateapirequest)) returns ([tetrateio.api.tsb.application.v2.API](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-api))

</PanelContentCode>

**Requires** WriteAPI

Modify an existing API object.
By default, API objects that are in DIRTY state cannot be modified. This state is reached when the configurations
generated for the API object are not in sync with the contents of the API object itself, so updates are rejected to
prevent accidental changes.
In these situations, the `force` flag can be used to force the update and to overwrite any changes that have been
done to the generated config resources.
When using the HTTP APIs, the `force` flag must be set as a query parameter.

</PanelContent>

### ListAPIs

<PanelContent>
<PanelContentCode>

rpc ListAPIs ([tetrateio.api.tsb.application.v2.ListAPIsRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-listapisrequest)) returns ([tetrateio.api.tsb.application.v2.ListAPIsResponse](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-listapisresponse))

</PanelContentCode>



List all APIs attached to the given application.

</PanelContent>

### DeleteAPI

<PanelContent>
<PanelContentCode>

rpc DeleteAPI ([tetrateio.api.tsb.application.v2.DeleteAPIRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-deleteapirequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete an existing API.

</PanelContent>

### GetAPIStatus

<PanelContent>
<PanelContentCode>

rpc GetAPIStatus ([tetrateio.api.tsb.application.v2.GetStatusRequest](../../../tsb/application/v2/application_service#tetrateio-api-tsb-application-v2-getstatusrequest)) returns ([tetrateio.api.tsb.application.v2.ResourceStatus](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-resourcestatus))

</PanelContentCode>

**Requires** ReadAPI

Get the configuration status of an existing API.

</PanelContent>






## CreateAPIRequest {#tetrateio-api-tsb-application-v2-createapirequest}

Request to create an API and register it in the management plane so configuration can
be generated for it.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the API will be created. This is the FQN of the application where the API
belongs to.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The short name for the resource to be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


api

</td>

<td>

[tetrateio.api.tsb.application.v2.API](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-api) <br/> _REQUIRED_ <br/> Details of the API to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateApplicationRequest {#tetrateio-api-tsb-application-v2-createapplicationrequest}

Request to create an application and register it in the management plane so configuration can
be generated for it.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the application will be created. This is the FQN of the tenant where the application
belongs to.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The short name for the resource to be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


application

</td>

<td>

[tetrateio.api.tsb.application.v2.Application](../../../tsb/application/v2/application#tetrateio-api-tsb-application-v2-application) <br/> _REQUIRED_ <br/> Details of the application to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteAPIRequest {#tetrateio-api-tsb-application-v2-deleteapirequest}

Request to delete an API.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the API.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteApplicationRequest {#tetrateio-api-tsb-application-v2-deleteapplicationrequest}

Request to delete an application.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the application.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


forceDeleteProtectedGroups

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Force the deletion of internal groups even if they are protected against deletion.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GetAPIRequest {#tetrateio-api-tsb-application-v2-getapirequest}

Request to retrieve an API.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the API.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetApplicationRequest {#tetrateio-api-tsb-application-v2-getapplicationrequest}

Request to retrieve an application.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the application.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetStatusRequest {#tetrateio-api-tsb-application-v2-getstatusrequest}

Request to retrieve the configuration status of a given resource.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the resource to get the configuration status for.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListAPIsRequest {#tetrateio-api-tsb-application-v2-listapisrequest}

Request to list APIs.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list APIs from. This is the FQN of the application where the APIs belong to.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListAPIsResponse {#tetrateio-api-tsb-application-v2-listapisresponse}

List of APIs that have been attached to the given application.



  
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


apis

</td>

<td>

List of [tetrateio.api.tsb.application.v2.API](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-api) <br/> The list of APIs that are registered in the given application.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListApplicationsRequest {#tetrateio-api-tsb-application-v2-listapplicationsrequest}

Request to list applications.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list applications from. This is the FQN of the tenant where the applications belong to.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListApplicationsResponse {#tetrateio-api-tsb-application-v2-listapplicationsresponse}

List of applications in the given tenant.



  
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


applications

</td>

<td>

List of [tetrateio.api.tsb.application.v2.Application](../../../tsb/application/v2/application#tetrateio-api-tsb-application-v2-application) <br/> The list of applications that are registered in the given tenant.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## UpdateAPIRequest {#tetrateio-api-tsb-application-v2-updateapirequest}





  
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


api

</td>

<td>

[tetrateio.api.tsb.application.v2.API](../../../tsb/application/v2/api#tetrateio-api-tsb-application-v2-api) <br/> _REQUIRED_ <br/> Details of the API to be updated.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


force

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When the force parameter is set, changes will be applied regardless of the status of the API object.
This will overwrite the generated configuration objects even if they were manually modified or were out of sync
with the API object.
Defaults to `false`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



