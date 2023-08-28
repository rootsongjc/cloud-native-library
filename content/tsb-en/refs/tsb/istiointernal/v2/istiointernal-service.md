---
title: Istio Internal Direct Mode Service
description: Service to resources in Istio Direct mode.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`IstioInternal` service provides methods to manage istio internal TSB resources.


## IstioInternal {#tetrateio-api-tsb-istiointernal-v2-istiointernal}

`IstioInternal` service provides methods to manage istio internal TSB resources.

It provides methods to create and manage istio internal groups within a workspace, allowing
to create fine-grained groupings to configure a subset of the workspace namespaces.
Access policies can be assigned at group level, providing a fine-grained access control
to the istio internal configuration features.


### CreateGroup

<PanelContent>
<PanelContentCode>

rpc CreateGroup ([tetrateio.api.tsb.istiointernal.v2.CreateIstioInternalGroupRequest](../../../tsb/istiointernal/v2/istiointernal_service#tetrateio-api-tsb-istiointernal-v2-createistiointernalgrouprequest)) returns ([tetrateio.api.tsb.istiointernal.v2.Group](../../../tsb/istiointernal/v2/istio_internal_group#tetrateio-api-tsb-istiointernal-v2-group))

</PanelContentCode>

**Requires** CREATE

Create a new Istio internal group in the given workspace.

Groups will by default configure all the namespaces owned by their workspace, unless
explicitly configured. If a specific set of namespaces is set for the group, it must be a
subset of the namespaces defined by its workspace.

</PanelContent>

### GetGroup

<PanelContent>
<PanelContentCode>

rpc GetGroup ([tetrateio.api.tsb.istiointernal.v2.GetIstioInternalGroupRequest](../../../tsb/istiointernal/v2/istiointernal_service#tetrateio-api-tsb-istiointernal-v2-getistiointernalgrouprequest)) returns ([tetrateio.api.tsb.istiointernal.v2.Group](../../../tsb/istiointernal/v2/istio_internal_group#tetrateio-api-tsb-istiointernal-v2-group))

</PanelContentCode>

**Requires** READ

Get the details of the given Istio internal group.

</PanelContent>

### UpdateGroup

<PanelContent>
<PanelContentCode>

rpc UpdateGroup ([tetrateio.api.tsb.istiointernal.v2.Group](../../../tsb/istiointernal/v2/istio_internal_group#tetrateio-api-tsb-istiointernal-v2-group)) returns ([tetrateio.api.tsb.istiointernal.v2.Group](../../../tsb/istiointernal/v2/istio_internal_group#tetrateio-api-tsb-istiointernal-v2-group))

</PanelContentCode>

**Requires** WRITE

Modify a Istio internal group.

</PanelContent>

### ListGroups

<PanelContent>
<PanelContentCode>

rpc ListGroups ([tetrateio.api.tsb.istiointernal.v2.ListIstioInternalGroupsRequest](../../../tsb/istiointernal/v2/istiointernal_service#tetrateio-api-tsb-istiointernal-v2-lististiointernalgroupsrequest)) returns ([tetrateio.api.tsb.istiointernal.v2.ListIstioInternalGroupsResponse](../../../tsb/istiointernal/v2/istiointernal_service#tetrateio-api-tsb-istiointernal-v2-lististiointernalgroupsresponse))

</PanelContentCode>



List all Istio internal groups in the given workspace.

</PanelContent>

### DeleteGroup

<PanelContent>
<PanelContentCode>

rpc DeleteGroup ([tetrateio.api.tsb.istiointernal.v2.DeleteIstioInternalGroupRequest](../../../tsb/istiointernal/v2/istiointernal_service#tetrateio-api-tsb-istiointernal-v2-deleteistiointernalgrouprequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio internal group.
Note that deleting resources in TSB is a recursive operation. Deleting a Istio internal group will
delete all configuration objects that exist in it.

</PanelContent>






## CreateIstioInternalGroupRequest {#tetrateio-api-tsb-istiointernal-v2-createistiointernalgrouprequest}

Request to create an Istio internal group.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Group will be created.

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


group

</td>

<td>

[tetrateio.api.tsb.istiointernal.v2.Group](../../../tsb/istiointernal/v2/istio_internal_group#tetrateio-api-tsb-istiointernal-v2-group) <br/> _REQUIRED_ <br/> Details of the Group to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteIstioInternalGroupRequest {#tetrateio-api-tsb-istiointernal-v2-deleteistiointernalgrouprequest}

Request to delete a Istio internal Group.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Group.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


force

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Force the deletion of the object even if deletion protection is enabled.
If this is set, then the object and all its children will be deleted even if any of them
has the deletion protection enabled.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GetIstioInternalGroupRequest {#tetrateio-api-tsb-istiointernal-v2-getistiointernalgrouprequest}

Request to retrieve a Istio internal Group.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Group.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListIstioInternalGroupsRequest {#tetrateio-api-tsb-istiointernal-v2-lististiointernalgroupsrequest}

Request to list Istio internal Groups.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Groups from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListIstioInternalGroupsResponse {#tetrateio-api-tsb-istiointernal-v2-lististiointernalgroupsresponse}

List of all Istio internal in the workspace.



  
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


groups

</td>

<td>

List of [tetrateio.api.tsb.istiointernal.v2.Group](../../../tsb/istiointernal/v2/istio_internal_group#tetrateio-api-tsb-istiointernal-v2-group) <br/> The list of requested groups.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



