---
title: Role
description: Configuration for creating various access roles.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`Role` is a named collection of permissions that can be assigned to
any user or team in the system. The set of actions that can be
performed by a user, such as the ability to create, delete, or
update configuration will depend on the permissions associated with
the user's role. Roles are global resources that are defined
once. `AccessBindings` in each configuration group will bind a user
to a specific role defined apriori.

TSB comes with the following predefined roles:

| Role | Permissions | Description |    
| -----| ----------- | ----------- |
| rbac/admin | `*` | Grants full access to the target resource and its child objects |
| rbac/editor | `Read` `Write` `Create` | Grants read/write access to a resource and allows creating child resources |
| rbac/creator | `Read` `Create` | Useful to delegate access to a resource without giving write access to the object itself. Users with this role will be able to manage sub-resources but not the resource itself |
| rbac/writer | `Read` `Write` | Grants Read and Write access permissions |
| rbac/reader | `Read` | Grants read-only permissions to a resource |

The following example declares a custom `workspace-admin` role with
the ability to create, delete configurations and the ability to set
RBAC policies on the groups within the workspace.

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: Role
metadata:
  name: role1
spec:
  rules:
  - types:
    - apiGroup: api.tsb.tetrate.io/v2
      kinds:
      - WorkspaceSetting
    permissions:
    - CREATE
    - READ
    - DELETE
    - WRITE
    - SET_POLICY
```





## Role {#tetrateio-api-tsb-rbac-v2-role}

`Role` is a named collection of permissions that can be assigned to
any user or team in the system.



  
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


rules

</td>

<td>

List of [tetrateio.api.tsb.rbac.v2.Role.Rule](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role-rule) <br/> A set of rules that define the permissions associated with each API group.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


### ResourceType {#tetrateio-api-tsb-rbac-v2-role-resourcetype}

The type of API resource for which the role is being created.



  
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


apiGroup

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> A specific API group such as traffic.tsb.tetrate.io/v2.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


kinds

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Specific kinds of APIs under the API group. If omitted, the
role will apply to all kinds under the group.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Rule {#tetrateio-api-tsb-rbac-v2-role-rule}

A rule defines the set of api groups



  
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


types

</td>

<td>

List of [tetrateio.api.tsb.rbac.v2.Role.ResourceType](../../../tsb/rbac/v2/role#tetrateio-api-tsb-rbac-v2-role-resourcetype) <br/> The set of API groups and the api Kinds within the group on which this rule is applicable.
If omitted, the permissions will globally apply to all resource types.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


permissions

</td>

<td>

List of [tetrateio.api.tsb.rbac.v2.Permission](../../../tsb/rbac/v2/permissions#tetrateio-api-tsb-rbac-v2-permission) <br/> _REQUIRED_ <br/> The set of actions allowed for these APIs.
The current version supports requires the kind, but this constraint will be relaxed in
upcoming releases so that rules can apply globally to an entire API group.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  



