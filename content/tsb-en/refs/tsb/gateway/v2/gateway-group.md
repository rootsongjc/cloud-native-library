---
title: Gateway Group
description: Configurations to group a set of gateways in a workspace.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Gateway Groups allow grouping the gateways in a set of namespaces
owned by its parent workspace. Gateway related configurations can
then be applied on the group to control the behavior of these
gateways. The group can be in one of two modes: `BRIDGED` and
`DIRECT`. `BRIDGED` mode is a minimalistic mode that allows users to
quickly configure the most commonly used features in the service
mesh using Tetrate specific APIs, while the `DIRECT` mode provides
more flexibility for power users by allowing them to configure the
gateways's traffic and security properties using a restricted
subset of Istio Networking and Security APIs.

The following example creates a gateway group for the gateways in
`ns1`, `ns2` and `ns3` namespaces owned by its parent workspace
`w1` under tenant `mycompany`

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  name: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelector:
    names:
    - "*/ns1"
    - "*/ns2"
    - "*/ns3"
  configMode: BRIDGED
```

It is possible to create a gateway group for namespaces in a
specific cluster as long as the parent workspace owns those
namespaces in that cluster. For example,

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  name: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelector:
    names:
    - "c1/ns1" # pick ns1 namespace only from c1 cluster
    - "*/ns2"
    - "*/ns3"
  configMode: BRIDGED
```

In the `DIRECT` mode, it is possible to directly attach Istio
Networking v1beta1 APIs - `VirtualService`, and `Gateway`, and
Istio Security v1beta1 APIs - `RequestAuthentication`, and
`AuthorizationPolicy` to the gateway group. These configurations
will be validated for correctness and conflict free operations and
then pushed to the appropriate Istio control planes.

The following example declares a `Gateway` and a `VirtualService`
for a specific workload in the `ns1` namespace:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: ingress
  namespace: ns1
  annotations:
    tsb.tetrate.io/organization: myorg
    tsb.tetrate.io/tenant: mycompany
    tsb.tetrate.io/workspace: w1
    tsb.tetrate.io/gatewayGroup: g1
spec:
  selector:
      app: my-ingress-gateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - uk.bookinfo.com
    - eu.bookinfo.com
```

and the associated `VirtualService`

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ingress-rule
  namespace: ns1
  annotations:
    tsb.tetrate.io/organization: myorg
    tsb.tetrate.io/tenant: mycompany
    tsb.tetrate.io/workspace: w1
    tsb.tetrate.io/gatewayGroup: g1
spec:
  hosts:
  - uk.bookinfo.com
  - eu.bookinfo.com
  gateways:
  - ns1/ingress # Has to bind to the same gateway
  http:
  - route:
    - destination:
        port:
          number: 7777
        host: reviews.ns1.svc.cluster.local
```

The namespace where the Istio APIs are applied will need to be part
of the parent gateway group. In addition, each API object will need
to have annotations to indicate the organization, tenant, workspace and the
gateway group to which it belongs to.





## Group {#tetrateio-api-tsb-gateway-v2-group}

A gateway group manages the gateways in a group of namespaces owned
by the parent workspace.



  
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


configMode

</td>

<td>

[tetrateio.api.tsb.types.v2.ConfigMode](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-configmode) <br/> The Configuration types that will be added to this
group. `BRIDGED` mode indicates that configurations added to this
group will use Tetrate APIs such as `IngressGateway`. `DIRECT`
mode indicates that configurations added to this group will use
Istio Networking v1beta1 APIs such as `Gateway` and
`VirtualService`, Istio Security v1beta1 APIs such as
`RequestAuthentication` and `AuthorizationPolicy`. Defaults to
`BRIDGED` mode.

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
  



