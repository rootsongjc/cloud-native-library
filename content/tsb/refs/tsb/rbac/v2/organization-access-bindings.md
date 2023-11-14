---
title: Organization Access Bindings
description: Configuration for assigning access roles to users under an organization.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

DEPRECATED: use Access Bindings instead.

`OrganizationAccessBindings` is an assignment of roles to a set of users or
teams to access resources under an Organization. The user or team
information is obtained from an LDAP server that should have been
configured as part of Service Bridge installation. Note that a
`OrganizationAccessBinding` can be created or modified only by users who
have `SET_POLICY` permission on the Organization.

The following example assigns the `org-admin` role to users
`alice`, `bob`, and members of the `t1` team owned by the organization
`myorg`. Use fully-qualified name (fqn) when specifying user and team

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: OrganizationAccessBindings
metadata:
  organization: myorg
spec:
  allow:
  - role: rbac/org-admin
    subjects:
    - user: organization/myorg/users/alice
    - user: organization/myorg/users/bob
    - team: organization/myorg/teams/t1
```





## OrganizationAccessBindings {#tetrateio-api-tsb-rbac-v2-organizationaccessbindings}

`OrganizationAccessBindings` assigns permissions to users of organizations.



  
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
  



