---
title: Access Bindings
description: Configuration for assigning access roles to users of any resource in TSB.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`AccessBindings` is an assignment of roles to a set of users or teams
to access resources. The user or team information is obtained from
an user directory (such an LDAP server or an external OIDC server)
that should have been configured as part of Service Bridge installation.
Note that an `AccessBinding` can be created or modified only by users
who have `SET_POLICY` permission on the target resource.

The following example assigns the `workspace-admin` role to users
`alice`, `bob`, and members of the `t1` team for the workspace `w1`
owned by the tenant `mycompany`.

Use fully-qualified name (fqn) when specifying the target resource,
as well as for the users and teams.

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: AccessBindings
metadata:
  fqn: organizations/myorg/tenants/mycompany/workspaces/w1
spec:
  allow:
  - role: rbac/workspace-admin
    subjects:
    - user: organizations/myorg/users/alice
    - user: organizations/myorg/users/bob
    - team: organizations/myorg/teams/t1
```





## AccessBindings {#tetrateio-api-tsb-rbac-v2-accessbindings}

`AccessBindings` assigns permissions to users of any TSB resource.



  
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
are allowed on the target resource.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



