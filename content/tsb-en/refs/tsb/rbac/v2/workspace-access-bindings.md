---
title: Workspace Access Bindings
description: Configuration for assigning access roles to users of workspaces.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

DEPRECATED: use [Access Bindings](https://tetrate.io/docs/reference/config/rbac/v2/access-bindings.html) instead.

`WorkspaceAccessBindings` is an assignment of roles to a set of users or
teams to access resources under a Workspace.  The user or team
information is obtained from an LDAP server that should have been
configured as part of Service Bridge installation. Note that a
`WorkspaceAccessBinding` can be created or modified only by users who
have `SET_POLICY` permission on the Workspace.

The following example assigns the `workspace-admin` role to users
`alice`, `bob`, and members of the `t1` team for all workspace `w1`
owned by the tenant `mycompany`. Use fully-qualified name (fqn) when specifying user and team

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: WorkspaceAccessBindings
metadata:
  organization: myorg
  tenant: mycompany
  workspace: w1
spec:
  allow:
  - role: rbac/workspace-admin
    subjects:
    - user: organization/myorg/users/alice
    - user: organization/myorg/users/bob
    - team: organization/myorg/teams/t1
```





## WorkspaceAccessBindings {#tetrateio-api-tsb-rbac-v2-workspaceaccessbindings}

`WorkspaceAccessBindings` assigns permissions to users of workspaces.



  
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
  



