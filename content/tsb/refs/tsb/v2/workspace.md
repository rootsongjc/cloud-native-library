---
title: Workspace
description: Configurations that group a set of related namespaces.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

A Workspace carves a chunk of the cluster resources owned by a
tenant into an isolated configuration domain.

The following example claims `ns1` and `ns2` namespaces across all
clusters owned by the tenant `mycompany`.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  name: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelector:
    names:
    - "*/ns1"
    - "*/ns2"
```

The following example claims `ns1` namespace only from the `c1`
cluster and claims all namespaces from the `c2` cluster.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  name: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelector:
    names:
    - "c1/ns1"
    - "c2/*"
```

Custom labels and annotations can be propagated to the final Istio translation that
will be applied at the clusters.
This could help with third-party integrations or to set custom identifier.
The following example configures the annotation `my.org.environment` to be applied to
all final Istio translations generated under this Workspace, for example Gateways or Virtual Services.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  name: w1
  tenant: mycompany
  organization: myorg
  annotations:
    my.org.environment: dev
spec:
  namespaceSelector:
    names:
    - "*/ns1"
```





## Workspace {#tetrateio-api-tsb-v2-workspace}

A Workspace is a collection of related namespaces in one or more clusters.



  
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


namespaceSelector

</td>

<td>

[tetrateio.api.tsb.types.v2.NamespaceSelector](../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-namespaceselector) <br/> _REQUIRED_ <br/> Set of namespaces owned exclusively by this workspace. A
workspace can own all namespaces of a cluster or a set of
namespaces across any cluster or a set of namespaces in a
specific cluster. Use `*/*` to claim all cluster resources under
the tenant.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


privileged

</td>

<td>

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> If set to true, allows Gateways in the workspace to route to
services in other workspaces. Set this to true for workspaces
owning cluster-wide gateways shared by multiple teams.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


isolationBoundary

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> Istio Isolation Boundary name to which this workspace belongs.
If not provided explicitly, the workspace looks for an isolation boundary with
name set as "global". 
Therefore, in order to move existing workspaces to isolation boundaries, and
be a part of revisioned control plane, it is recommended to configure an
isolation boundary with the name "global".

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


securityDomain

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Security domains can be used to group different resources under the same security domain.
Although security domain is not resource itself currently, it follows a fqn format
`organizations/myorg/securitydomains/mysecuritydomain`, and a child cannot override any ancestor's
security domain.
Once a security domain is assigned to a _Workspace_, all the children resources will belong to that
security domain in the same way a _Security group_ belongs to a _Workspace_, a _Security group_ will also belong
to the security domain assigned to the _Workspace_.
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
  



