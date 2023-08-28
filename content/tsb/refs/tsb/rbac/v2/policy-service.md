---
title: Policy Service
description: Service to manage access control policies for TSB resources
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage access control policies for TSB resources


## Policy {#tetrateio-api-tsb-rbac-v2-policy}

The Policy service provides methods to configure the access control policies for TSB resources.

All TSB resources have one and exactly one policy document that configures access for it.
When resources are created, a default policy is attached to the resource, assigning administration
privileges on the resource to the user that created it.


### GetPolicy

<PanelContent>
<PanelContentCode>

rpc GetPolicy ([tetrateio.api.tsb.rbac.v2.GetPolicyRequest](../../../tsb/rbac/v2/policy_service#tetrateio-api-tsb-rbac-v2-getpolicyrequest)) returns ([tetrateio.api.tsb.rbac.v2.AccessPolicy](../../../tsb/rbac/v2/policy_service#tetrateio-api-tsb-rbac-v2-accesspolicy))

</PanelContentCode>



Get the access policy for the given resource.

</PanelContent>

### SetPolicy

<PanelContent>
<PanelContentCode>

rpc SetPolicy ([tetrateio.api.tsb.rbac.v2.AccessPolicy](../../../tsb/rbac/v2/policy_service#tetrateio-api-tsb-rbac-v2-accesspolicy)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>



Set the access policy for the given resource.

</PanelContent>

### GetRootPolicy

<PanelContent>
<PanelContentCode>

rpc GetRootPolicy ([tetrateio.api.tsb.rbac.v2.GetAdminPolicyRequest](../../../tsb/rbac/v2/policy_service#tetrateio-api-tsb-rbac-v2-getadminpolicyrequest)) returns ([tetrateio.api.tsb.rbac.v2.AccessPolicy](../../../tsb/rbac/v2/policy_service#tetrateio-api-tsb-rbac-v2-accesspolicy))

</PanelContentCode>

**Requires** SET_POLICY

Get the root access policy.
The root access policy configures global permissions for the platform. Subjects
assigned to a root policy will be granted the permissions described in the policy
to all objects ion TSB.

</PanelContent>

### SetRootPolicy

<PanelContent>
<PanelContentCode>

rpc SetRootPolicy ([tetrateio.api.tsb.rbac.v2.AccessPolicy](../../../tsb/rbac/v2/policy_service#tetrateio-api-tsb-rbac-v2-accesspolicy)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** SET_POLICY

Set the root access policy.
The root access policy configures global permissions for the platform. Subjects
assigned to a root policy will be granted the permissions described in the policy
to all objects ion TSB.

</PanelContent>

### GetRBACPolicy

<PanelContent>
<PanelContentCode>

rpc GetRBACPolicy ([tetrateio.api.tsb.rbac.v2.GetAdminPolicyRequest](../../../tsb/rbac/v2/policy_service#tetrateio-api-tsb-rbac-v2-getadminpolicyrequest)) returns ([tetrateio.api.tsb.rbac.v2.AccessPolicy](../../../tsb/rbac/v2/policy_service#tetrateio-api-tsb-rbac-v2-accesspolicy))

</PanelContentCode>

**Requires** SET_POLICY

Get the global RBAC access policy.
The global RBAC access policy configures who can manage the Role objects in TSB.

</PanelContent>

### SetRBACPolicy

<PanelContent>
<PanelContentCode>

rpc SetRBACPolicy ([tetrateio.api.tsb.rbac.v2.AccessPolicy](../../../tsb/rbac/v2/policy_service#tetrateio-api-tsb-rbac-v2-accesspolicy)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** SET_POLICY

Set the global RBAC access policy.
The global RBAC access policy configures who can manage the Role objects in TSB.

</PanelContent>






## AccessPolicy {#tetrateio-api-tsb-rbac-v2-accesspolicy}

Policy

A policy defines the set of subjects that can access a resource and under
which conditions that access is granted.



  
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


allow

</td>

<td>

List of [tetrateio.api.tsb.rbac.v2.Binding](../../../tsb/rbac/v2/binding#tetrateio-api-tsb-rbac-v2-binding) <br/> The list of allowed bindings configures the different access profiles that
are allowed on the resource configured by the policy.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GetPolicyRequest {#tetrateio-api-tsb-rbac-v2-getpolicyrequest}

Request to get the access policy for a resource.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the policy.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  



