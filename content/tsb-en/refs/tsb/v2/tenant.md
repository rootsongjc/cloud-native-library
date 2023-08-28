---
title: Tenant
description: Configuration for creating a tenant in Service Bridge.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`Tenant` is a self-contained entity within an organization in
the Service Bridge object hierarchy. Tenants can be business units,
organization units, or any logical grouping that matches a corporate
structure.

The following example creates a tenant named `mycompany` in an organization
named `myorg`.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: myorg
  name: mycompany
```





## Tenant {#tetrateio-api-tsb-v2-tenant}

`Tenant` is a self-contained entity within an organization in the Service Bridge hierarchy.



  
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


securityDomain

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Security domains can be used to group different resources under the same security domain.
Although security domain is not resource itself currently, it follows a fqn format
`organizations/myorg/securitydomains/mysecuritydomain`, and a child cannot override any ancestor's
security domain.
Once a security domain is assigned to a _Tenant_, all the children resources will belong to that
security domain in the same way a _Workspace_ belongs to a _Tenant_, a _Workspace_ will also belong
to the security domain assigned to the _Tenant_.
Security domains can also be used to define _Security settings Authorization rules_ in which you can allow
or deny request from or to a security domain.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


deletionProtectionEnabled

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When set, prevents the resource from being deleted. In order to delete the resource this
property needs to be set to `false` first.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


configGenerationMetadata

</td>

<td>

[tetrateio.api.tsb.types.v2.ConfigGenerationMetadata](../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-configgenerationmetadata) <br/> Default metadata values that will be propagated to the children Istio generated configurations.
When using YAML APIs like`tctl` or `gitops`, put them into the `metadata.labels` or
`metadata.annotations` instead.
This field is only necessary when using gRPC APIs directly.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



