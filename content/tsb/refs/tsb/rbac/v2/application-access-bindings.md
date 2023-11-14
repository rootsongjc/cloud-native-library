---
title: Application Access Bindings
description: Configuration for assigning access roles to users of applications.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

DEPRECATED: use Access Bindings instead.

`ApplicationAccessBindings` is an assignment of roles to a set of users or
teams to access Application resources. The user or team
information is obtained from an LDAP server that should have been
configured as part of Service Bridge installation. Note that a
`ApplicationAccessBinding` can be created or modified only by users who
have `SET_POLICY` permission on the Application.

The following example assigns the `application-admin` role to users
`alice`, `bob`, and members of the `t1` team for the application `app`
owned by the tenant `mycompany`. Use fully-qualified name (fqn) when specifying user and team

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: ApplicationAccessBindings
metadata:
  organization: myorg
  tenant: mycompany
  application: app
spec:
  allow:
  - role: rbac/application-admin
    subjects:
    - user: organization/myorg/users/alice
    - user: organization/myorg/users/bob
    - team: organization/myorg/teams/t1
```





## ApplicationAccessBindings {#tetrateio-api-tsb-rbac-v2-applicationaccessbindings}

`ApplicationAccessBindings` assigns permissions to users of applications.



  
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
  



