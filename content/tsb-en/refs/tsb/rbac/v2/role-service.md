---
title: Role Service
description: Service to manage access roles in Service Bridge.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage access roles in Service Bridge.


## RBAC {#tetrateio-api-tsb-rbac-v2-rbac}

The RBAC service provides methods to manage the roles in the Service Bridge
platform.
It provides method to configure the roles that can be used in the management
plane access control policies and their permissions.


### CreateRole

<PanelContent>
<PanelContentCode>

rpc CreateRole ([tetrateio.api.tsb.rbac.v2.CreateRoleRequest](../../../tsb/rbac/v2/role_service#tetrateio-api-tsb-rbac-v2-createrolerequest)) returns ([tetrateio.api.tsb.rbac.v2.Role](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role))

</PanelContentCode>

**Requires** CREATE

Create a new role.

</PanelContent>

### ListRoles

<PanelContent>
<PanelContentCode>

rpc ListRoles ([tetrateio.api.tsb.rbac.v2.ListRolesRequest](../../../tsb/rbac/v2/role_service#tetrateio-api-tsb-rbac-v2-listrolesrequest)) returns ([tetrateio.api.tsb.rbac.v2.ListRolesResponse](../../../tsb/rbac/v2/role_service#tetrateio-api-tsb-rbac-v2-listrolesresponse))

</PanelContentCode>

**Requires** READ

List all existing roles.

</PanelContent>

### GetRole

<PanelContent>
<PanelContentCode>

rpc GetRole ([tetrateio.api.tsb.rbac.v2.GetRoleRequest](../../../tsb/rbac/v2/role_service#tetrateio-api-tsb-rbac-v2-getrolerequest)) returns ([tetrateio.api.tsb.rbac.v2.Role](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role))

</PanelContentCode>

**Requires** READ

Get the details of the given role.

</PanelContent>

### UpdateRole

<PanelContent>
<PanelContentCode>

rpc UpdateRole ([tetrateio.api.tsb.rbac.v2.Role](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role)) returns ([tetrateio.api.tsb.rbac.v2.Role](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role))

</PanelContentCode>

**Requires** WRITE

Modify a role.

</PanelContent>

### DeleteRole

<PanelContent>
<PanelContentCode>

rpc DeleteRole ([tetrateio.api.tsb.rbac.v2.DeleteRoleRequest](../../../tsb/rbac/v2/role_service#tetrateio-api-tsb-rbac-v2-deleterolerequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete a role.
NRoles that are in use by policies attached to existing resources
cannot be deleted.

</PanelContent>






## CreateRoleRequest {#tetrateio-api-tsb-rbac-v2-createrolerequest}

Request to create a Role.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The short name for the resource to be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


role

</td>

<td>

[tetrateio.api.tsb.rbac.v2.Role](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role) <br/> _REQUIRED_ <br/> Details of the Role to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteRoleRequest {#tetrateio-api-tsb-rbac-v2-deleterolerequest}

Request to delete a Role.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Role.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetRoleRequest {#tetrateio-api-tsb-rbac-v2-getrolerequest}

Request to retrieve a Role.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Role.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListRolesResponse {#tetrateio-api-tsb-rbac-v2-listrolesresponse}

List of all existing roles.



  
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


roles

</td>

<td>

List of [tetrateio.api.tsb.rbac.v2.Role](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



