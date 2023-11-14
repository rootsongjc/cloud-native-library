---
title: Istio Internal Access Bindings
description: Configuration for assigning access roles to users of istio internal groups.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

DEPRECATED: use Access Bindings instead.

`IstioInternalAccessBindings` is an assignment of roles to a set of users or
teams to access resources under a Istio internal group.  The user or team
information is obtained from an LDAP server that should have been
configured as part of Service Bridge installation. Note that a
`IstioInternalAccessBinding` can be created or modified only by users who
have `SET_POLICY` permission on the Istio internal group.

The following example assigns the `istiointernal-admin` role to users
`alice`, `bob`, and members of the `istiointernal-ops` team for
istio internal group `g1` under workspace `w1` owned by the tenant
`mycompany`. Use fully-qualified name (fqn) when specifying user and team

```yaml
apiVersion: rbac.tsb.tetrate.io/v2
kind: IstioInternalAccessBindings
metadata:
  organization: myorg
  tenant: mycompany
  workspace: w1
  group: g1
spec:
  allow:
  - role: rbac/istiointernal-admin
    subjects:
    - user: organization/myorg/users/alice
    - user: organization/myorg/users/bob
    - team: organization/myorg/teams/istiointernal-ops
```





## IstioInternalAccessBindings {#tetrateio-api-tsb-rbac-v2-istiointernalaccessbindings}

`IstioInternalAccessBindings` assigns permissions to users of istio internal groups.



  
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
  



