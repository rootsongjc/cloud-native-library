---
title: Policy Bindings
description: Access Policy Bindings.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Access Policy Bindings.





## Binding {#tetrateio-api-tsb-rbac-v2-binding}

A binding associates a role with a set of subjects.

Bindings are used to configure policies, where different roles can be
assigned to different sets of subjects to configure a fine-grained access
control to the resource protected by the policy.



  
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


role

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The role that defines the permissions that will be granted to the target
resource.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


subjects

</td>

<td>

List of [tetrateio.api.tsb.rbac.v2.Subject](../../../tsb/rbac/v2/binding#tetrateio-api-tsb-rbac-v2-subject) <br/> The set of subjects that will be allowed to access the target resource
with the permissions defined by the role.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Subject {#tetrateio-api-tsb-rbac-v2-subject}

Subject identifies a user or a team under an organization. Roles are
assigned to subjects for specific resources in the system.



  
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


user

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> sub</sup>_ <br/> A user in TSB, created through LDAP sync or API.
Must use the fully-qualified name (fqn) of the user. 
E.g. organization/myorg/users/alice

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


team

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> sub</sup>_ <br/> A team in TSB, created through LDAP sync or API.
Must use the fully-qualified name (fqn) of the team. 
E.g. organization/myorg/teams/t1

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceAccount

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> sub</sup>_ <br/> A service account in TSB.
Must use the fully-qualified name (fqn) of the service account. 
E.g. organization/myorg/serviceaccounts/sa1

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## RequiredPermission {#tetrateio-api-tsb-rbac-v2-requiredpermission}

RequiredPermission

Configures the sets of permissions that are required to invoke the method where this option is
applied.



  
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


permissions

</td>

<td>

List of [tetrateio.api.tsb.rbac.v2.Permission](../../../tsb/rbac/v2/permissions#tetrateio-api-tsb-rbac-v2-permission) <br/> The required set of permissions. The full name of each permission (such as ReadApplication)
will be inferred from the name of the method where this option is applied.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rawPermissions

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Set of raw permission names values. Only use this if the method being protected does not follow
the common naming convention and the proper name of the permission cannot be inferred just by
using the Permission enum and the method name.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


deferPermissionCheckToApplication

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When this flag is set to true, the permission checks will not be made at the API surface.
This is usually needed when there is not an explicit set of permissions that can be
preconfigured for the API methods, so the access control checks will be implemented at runtime
by the application.
The default value is 'false' and will only be taken into account if the permission properties
are empty. If any permission is set, this flag will be ignored.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



