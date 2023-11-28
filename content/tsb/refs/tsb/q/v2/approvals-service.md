---
title: Approvals Service
description: Service to manage centralized approval policies.
---

<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage centralized approval policies.


## Approvals {#tetrateio-api-tsb-q-v2-approvals}

The Approvals service exposes methods for working with approval policies.
$hide_from_yaml


### SetPolicy

<PanelContent>
<PanelContentCode>

rpc SetPolicy ([tetrateio.api.tsb.q.v2.ApprovalPolicy](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-approvalpolicy)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** CreateApprovalPolicy, WriteApprovalPolicy

SetPolicy enables authorization policy checks for the given resource and applies any provided
request or approval settings. If the resource has existing policies settings, they will be replaced.
Once the policy is set, authorization checks will be performed for the given resource.

</PanelContent>

### GetPolicy

<PanelContent>
<PanelContentCode>

rpc GetPolicy ([tetrateio.api.tsb.q.v2.GetPolicyRequest](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-getpolicyrequest)) returns ([tetrateio.api.tsb.q.v2.ApprovalPolicy](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-approvalpolicy))

</PanelContentCode>

**Requires** ReadApprovalPolicy

GetPolicy returns the approval policy for the given resource.

</PanelContent>

### QueryPolicies

<PanelContent>
<PanelContentCode>

rpc QueryPolicies ([tetrateio.api.tsb.q.v2.QueryPoliciesRequest](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-querypoliciesrequest)) returns ([tetrateio.api.tsb.q.v2.QueryPoliciesResponse](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-querypoliciesresponse))

</PanelContentCode>





</PanelContent>

### DeletePolicy

<PanelContent>
<PanelContentCode>

rpc DeletePolicy ([tetrateio.api.tsb.q.v2.DeletePolicyRequest](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-deletepolicyrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DeleteApprovalPolicy

DeletePolicy deletes the approval policy configuration for the given resource. When deleted, authorization
checks will no longer be performed, the resource will no longer accept approval requests and all existing approvals
will be revoked.

</PanelContent>

### AddAccessRequest

<PanelContent>
<PanelContentCode>

rpc AddAccessRequest ([tetrateio.api.tsb.q.v2.AccessRequest](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-accessrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** CreateApprovalPolicyAccessRequest, WriteApprovalPolicyAccessRequest

AddAccessRequest adds a new access request entry in the access request list for the given resource.
If the policy approval mode is "ALLOW_REQUESTED", access is allowed immediately. If the policy approval
mode is "REQUIRE_APPROVAL" access will be pending until the request is approved.

</PanelContent>

### DeleteAccessRequest

<PanelContent>
<PanelContentCode>

rpc DeleteAccessRequest ([tetrateio.api.tsb.q.v2.ResourceAndSubject](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-resourceandsubject)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DeleteApprovalPolicyAccessRequest

DeleteAccessRequest removes an existing entry from the access request list for the given resource.
If the request is already approved, the request no longer exists and this operation will return NotFound.
Deleting an approved request should be done using the DeleteApproved operation.

</PanelContent>

### ApproveAccessRequest

<PanelContent>
<PanelContentCode>

rpc ApproveAccessRequest ([tetrateio.api.tsb.q.v2.AccessRequest](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-accessrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** WriteApprovalPolicyApproveAccess

ApproveAccessRequest approves an existing access request for the given resource.
Once approved, the request will be removed from the requested list and added to the approved list.
If any of the permissions are changed, the requested permissions will be discarded and only the approved
permissions will be added to the approved list.

</PanelContent>

### AddApprovedAccess

<PanelContent>
<PanelContentCode>

rpc AddApprovedAccess ([tetrateio.api.tsb.q.v2.AccessRequest](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-accessrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** CreateApprovalPolicyApprovedAccess, WriteApprovalPolicyApprovedAccess

AddApprovedAccess adds a new entry in the approved access list for the given resource.

</PanelContent>

### DeleteApprovedAccess

<PanelContent>
<PanelContentCode>

rpc DeleteApprovedAccess ([tetrateio.api.tsb.q.v2.ResourceAndSubject](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-resourceandsubject)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DeleteApprovalPolicyApprovedAccess

DeleteApprovedAccess deletes an entry from the approved list for the given resource.

</PanelContent>






## Access {#tetrateio-api-tsb-q-v2-access}

Access is an access request for a subject with a set of permission.

Example:
Access {
  Subject: "organizations/demo/tenants/demo/applications/caller",
  Permissions: []string{"GET"}
}



  
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


subject

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Subject is the subject that is requested to access the resource.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


permissions

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Permissions is a list of permissions that the subject is allowed to use.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


metadata

</td>

<td>

[tetrateio.api.tsb.q.v2.Metadata](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-metadata) <br/> Metadata is additional information about this Access entity.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## AccessRequest {#tetrateio-api-tsb-q-v2-accessrequest}

AccessRequest is a request used for requesting or approving access to a resource.

Example:
AccessRequest {
  Resource: "organizations/demo/tenants/demo/applications/target",
  Access: []Access{{
    Subject: "organizations/demo/tenants/demo/applications/calling-app",
    Permissions: []string{"GET", "POST"}
  }}
}



  
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


resource

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Resource for which the access request is made.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


access

</td>

<td>

[tetrateio.api.tsb.q.v2.Access](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-access) <br/> _REQUIRED_ <br/> Access is the subject and permissions for the access request.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ApprovalPolicy {#tetrateio-api-tsb-q-v2-approvalpolicy}

ApprovalPolicy is a set of authorization rules that define access to a resource.
When applied to a resource, the rules enforce access to the resource based on the permission set.

Example:
ApprovalPolicy {
  Mode: ApprovalPolicy_REQUIRE_APPROVAL,
  Resource: "organizations/demo/tenants/demo/applications/target-app",
  Approved: []Access {{
    Subject: "organizations/demo/tenants/demo/applications/calling-app",
    Permissions: []string{"GET", "POST"}
  }}
}



  
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

[tetrateio.api.tsb.q.v2.ApprovalPolicy.Mode](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-approvalpolicy-mode) <br/> _REQUIRED_ <br/> Mode indicates how access to the resource is configured.

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


resource

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Resource is a fully qualified name of the resource that the policy applies to.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


requested

</td>

<td>

List of [tetrateio.api.tsb.q.v2.Access](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-access) <br/> Requested is a list of subjects that are requested to access the resource but that have not yet been
explicitly approved.
The access mode of the policy will determine if the subjects in this list are given immediate access to the
resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


approved

</td>

<td>

List of [tetrateio.api.tsb.q.v2.Access](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-access) <br/> Approved is a list of subjects that are approved to access the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


metadata

</td>

<td>

[tetrateio.api.tsb.q.v2.Metadata](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-metadata) <br/> Metadata is additional information about this Policy and the resource it applies to.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## DeletePolicyRequest {#tetrateio-api-tsb-q-v2-deletepolicyrequest}

DeletePolicyRequest is the request message for DeletePolicy.

Example:
DeletePolicyRequest {
  Resource: "organizations/demo/tenants/demo/applications/target-app"
}



  
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


resource

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Resource is the fully qualified name of the policy delete being requested.

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

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Force the deletion of internal resources even if they are protected against deletion.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GetPolicyRequest {#tetrateio-api-tsb-q-v2-getpolicyrequest}

GetPolicyRequest is the request message for GetPolicy.

Example:
GetPolicyRequest {
  Resource: "organizations/demo/tenants/demo/applications/example"
}



  
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


resource

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Resource is the fully qualified name of the policy being requested.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## Metadata {#tetrateio-api-tsb-q-v2-metadata}

Metadata includes additional information about an ApprovalPolicy or Access entity and
their respective resources that they apply to.



  
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


details

</td>

<td>

[tetrateio.api.tsb.q.v2.Metadata.Details](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-metadata-details) <br/> Details includes details about the resource or subject.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rules

</td>

<td>

List of [tetrateio.api.tsb.rbac.v2.Role.Rule](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role-rule) <br/> Permissions includes permissions for which an authenticated user is allowed to perform.
This applies to ApprovalPolicy or Access entities respectively.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Details {#tetrateio-api-tsb-q-v2-metadata-details}

Details is additional information about a resource.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Name is the resources name.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Description is the resources description.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## QueryPoliciesRequest {#tetrateio-api-tsb-q-v2-querypoliciesrequest}

QueryPoliciesRequest is the request message for QueryPolicies.

Example:
QueryPoliciesRequest {
  Parent: "organizations/demo/tenants/demo",
  Types: []string{"applications"},
  IncludeDetails: true,
  IncludePermissions: true,
}



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent is the resource where the query will collect ApprovalPolicy for the children that match the specified types.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


types

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Type is the type of the resources to query for policies.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


includeDetails

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> IncludeDetails indicates whether to include the details of the resources that are part of the policy.
When set to true, the name and description of the resource are included in the response.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


includePermissions

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> IncludePermissions indicates whether to include the user level permissions on resources that are part of the policy.
When set to true, the user level permissions are included in the response.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## QueryPoliciesResponse {#tetrateio-api-tsb-q-v2-querypoliciesresponse}

QueryPoliciesResponse is the response message for QueryPolicies.



  
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


policies

</td>

<td>

List of [tetrateio.api.tsb.q.v2.ApprovalPolicy](../../../tsb/q/v2/approvals_service#tetrateio-api-tsb-q-v2-approvalpolicy) <br/> Policies is a list of policies that match the query.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ResourceAndSubject {#tetrateio-api-tsb-q-v2-resourceandsubject}

ResourceAndSubject is a resource and subject pair used for approval and deletion operations.

Example:
ResourceAndSubject {
  Resource: "organizations/demo/tenants/demo/applications/target",
  Subject: "organizations/demo/tenants/demo/applications/caller"
}



  
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


resource

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Resource for which the access request is made.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


subject

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Subject for which the access request is made.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  




### Mode {#tetrateio-api-tsb-q-v2-approvalpolicy-mode}




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


UNRESTRICTED

</td>

<td>

0

</td>

<td>

Allows all subjects in the same policy class to access the resource.

</td>
</tr>
    
<tr>
<td>


ALLOW_REQUESTED

</td>

<td>

1

</td>

<td>

Allows only the subjects in the request and approved list to access the resource.

</td>
</tr>
    
<tr>
<td>


REQUIRE_APPROVAL

</td>

<td>

2

</td>

<td>

Allows only the subjects in the approved list to access the resource.

</td>
</tr>
    
</table>
  


