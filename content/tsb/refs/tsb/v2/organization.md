---
title: Organization
description: Configuration for creating an organization in Service Bridge.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`Organization` is a root of the Service Bridge object hierarchy. Each
organization is completely independent of the other with its own set of
tenants, users, teams, clusters and workspaces.

Organizations in TSB are tied to an Identity Provider (IdP). Users and teams,
representing the organizational structure, are periodically synchronized
from the IdP into TSB in order to make them available for access policy
configuration.

The following example creates an organization named `myorg`.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Organization
metadata:
  name: myorg
```





## Organization {#tetrateio-api-tsb-v2-organization}

`Organization` is the root of the Service Bridge object hierarchy.



  
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
  



