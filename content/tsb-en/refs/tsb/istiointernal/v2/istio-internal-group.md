---
title: Istio internal Group
description: Group of istio resources that are not directly related to traffic, security, and gateways.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Istio internal groups only allow grouping `DIRECT` mode mesh resources in a set of namespaces
owned by its parent workspace. This group is aimed for grouping resources not directly related
to traffic, security, or gateway like `EnvoyFilters` and `ServiceEntry` for instance.
Istio internal group is meant to group highly coupled and implementation-detailed oriented istio resources that
don't provide any `BRIDGE` mode guarantees or backward/forward compatibilities that other groups like
traffic, security of gateway can provide.
Especially, and mainly because resources like `EnvoyFilters`, are highly customizable and can interfere
in unpredictable ways, with any other routing, security, listeners, or filter chains among other configurations
that TSB may have setup. Therefore, this group is only meant to be used for users/administrators that are confident
with those advanced features, knowing that the defined resources under this group will not interfere
with the TSB provided mesh governance functionalities.

The following example creates an istio internal group for resources in
`ns1`, `ns2` and `ns3` namespaces owned by its parent workspace
`w1` under tenant `mycompany`.
```yaml
apiVersion: istiointernal.tsb.tetrate.io/v2
kind: Group
metadata:
  name: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelector:
    names:
    - "*/ns1"
    - "*/ns2"
    - "*/ns3"
```

It is possible to directly attach Istio APIs such as `EnvoyFilter`, and `ServiceEntry`
to the istio internal group. These configurations will then pushed to the
appropriate Istio control planes.

The following ServiceEntry example declares a few external APIs accessed by internal applications over HTTPS.
The sidecar inspects the SNI value in the ClientHello message to route to the appropriate external service.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-svc-https
  namespace: ns1
  annotations:
    tsb.tetrate.io/organization: myorg
    tsb.tetrate.io/tenant: mycompany
    tsb.tetrate.io/workspace: w1
    tsb.tetrate.io/istioInternalGroup: t1
spec:
  hosts:
  - api.dropboxapi.com
  - www.googleapis.com
  - api.facebook.com
  location: MESH_EXTERNAL
  ports:
  - number: 443
    name: https
    protocol: TLS
  resolution: DNS
```

The namespace where the Istio APIs are applied will need to be part
of the parent istio internal group. In addition, each API object will need
to have annotations to indicate the organization, tenant, workspace and the
istio internal group to which it belongs to.





## Group {#tetrateio-api-tsb-istiointernal-v2-group}

An Istio Internal Group only allows grouping `DIRECT` mode mesh resources in a set of namespaces
owned by its parent workspace. This group is aimed for grouping resources not directly related
to traffic, security, or gateway like `EnvoyFilters` and `ServiceEntry`.



  
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

[tetrateio.api.tsb.types.v2.NamespaceSelector](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-namespaceselector) <br/> _REQUIRED_ <br/> Set of namespaces owned exclusively by this group. If omitted,
applies to all resources owned by the workspace. Use `*/*` to
claim all cluster resources under the workspace.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

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

[tetrateio.api.tsb.types.v2.ConfigGenerationMetadata](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-configgenerationmetadata) <br/> Default metadata values that will be propagated to the children Istio generated configurations.
When using YAML APIs like`tctl` or `gitops`, put them into the `metadata.labels` or
`metadata.annotations` instead.
This field is only necessary when using gRPC APIs directly.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



