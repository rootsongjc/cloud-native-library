---
title: Common Object Types
description: Definition of objects shared by different APIs.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Definition of objects shared by different APIs.





## ConfigGenerationMetadata {#tetrateio-api-tsb-types-v2-configgenerationmetadata}

`ConfigGenerationMetadata` allows to setup extra metadata that will be added in the final Istio generated configurations.
Like new labels or annotations.
Defining the config generation metadata in tenancy resources (like organization, tenant, workspace or groups) works as default
values for those configs that belong to it.
Defining same config generation metadata in configuration resources (like ingress gateways, service routes, etc.) will replace the
ones defined in the tenancy resources.



  
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


labels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Set of key value paris that will be added into the `metadata.labels` field of the Istio generated configurations.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


annotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Set of key value paris that will be added into the `metadata.annotations` field of the Istio generated configurations.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## NamespaceSelector {#tetrateio-api-tsb-types-v2-namespaceselector}

`NamespaceSelector` selects a set of namespaces across one or more
clusters in a tenant. Namespace selectors can be used at Workspace
level to carve out a chunk of resources under a tenant into an
isolated configuration domain. They can be used in a Traffic,
Security, or a Gateway group to further scope the set of namespaces
that will belong to a specific configuration group.
Names in namespaces selector must be in the form `cluster/namespace`
where:
- cluster must be a cluster name or an `*` to mean all clusters
- namespace must be a namespace name, an `*` to mean all namespaces
  or a prefix like `ns-*` to mean all those namespaces starting
  by `ns-`



  
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


names

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Under the tenant/workspace/group:

- `*/ns1` implies `ns1` namespace in any cluster.

- `c1/ns1` implies `ns1` namespace from `c1` cluster.

- `c1/*` implies all namespaces in `c1` cluster.

- `*/*` implies all namespaces in all clusters.

- `c1/ns*` implies all namespaces prefixes by `ns` in `c1` cluster.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{string:{pattern:^(\\*|[^/*]+)/(\\*|[^/*]+\\*?)$}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## PortSelector {#tetrateio-api-tsb-types-v2-portselector}

PortSelector is the criteria for specifying if a policy can be applied to
a listener having a specific port.



  
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


number

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Port number

</td>

<td>

uint32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## RegionalFailover {#tetrateio-api-tsb-types-v2-regionalfailover}

Specify the traffic failover policy across regions. Since zone and sub-zone
failover is supported by default this only needs to be specified for
regions when the operator needs to constrain traffic failover so that
the default behavior of failing over to any endpoint globally does not
apply. This is useful when failing over traffic across regions would not
improve service health or may need to be restricted for other reasons
like regulatory controls.



  
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


from

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Originating region.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


to

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Destination region the traffic will fail over to when endpoints in
the 'from' region become unhealthy.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ServiceSelector {#tetrateio-api-tsb-types-v2-serviceselector}

ServiceSelector represents the match criteria to select services within a
particular scope (namespace, workspace, cluster etc)



  
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


serviceLabels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> _REQUIRED_ <br/> One or more labels that indicate a specific set of services within a particular scope

</td>

<td>

map = {<br/>&nbsp;&nbsp;min_pairs: `1`<br/>&nbsp;&nbsp;keys: `{string:{min_len:1}}`<br/>&nbsp;&nbsp;values: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## TrafficSelector {#tetrateio-api-tsb-types-v2-trafficselector}

TrafficSelector provides a mechanism to select a specific traffic flow
for which this Wasm Extension will be enabled.
When all the sub conditions in the TrafficSelector are satisfied, the
traffic will be selected.



  
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


mode

</td>

<td>

[tetrateio.api.tsb.types.v2.WorkloadMode](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-workloadmode) <br/> Criteria for selecting traffic by their direction.
Note that CLIENT and SERVER are analogous to OUTBOUND and INBOUND,
respectively.
For the gateway, the field should be CLIENT or CLIENT_AND_SERVER.
If not specified, the default value is CLIENT_AND_SERVER.

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


ports

</td>

<td>

List of [tetrateio.api.tsb.types.v2.PortSelector](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-portselector) <br/> Criteria for selecting traffic by their destination port.
More specifically, for the outbound traffic, the destination port would be
the port of the target service. On the other hand, for the inbound traffic,
the destination port is the port bound by the server process in the same Pod.

If one of the given `ports` is matched, this condition is evaluated to true.
If not specified, this condition is evaluated to true for any port.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## WasmExtensionAttachment {#tetrateio-api-tsb-types-v2-wasmextensionattachment}

WasmExtensionAttachment defines the WASM extension attached to this resource
including the name to identify the extension and also the specific configuration
that will override the global extension configuration.
Only those extensions globally enabled will be considered although they can be
associated to the target resources.
Match configuration allows you to specify which traffic is sent through the Wasm
extension. Users can select the traffic based on different workload modes and ports.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
metadata:
  name: ingress-bookinfo
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
  namespace: ns1
  labels:
    app: gateway
  extension:
  - fqn: hello-world # fqn of imported extensions in TSB
    config:
      foo: bar
    match:
    - ports:
      - number: 80
      mode: CLIENT_AND_SERVER
  http:
  - name: bookinfo
    port: 80
    hostname: bookinfo.com
    routing:
      rules:
      - route:
        host: ns1/productpage.ns1.svc.cluster.local
```



  
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


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fqn of the extension to be executed.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


config

</td>

<td>

[google.protobuf.Struct](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Struct) <br/> Configuration parameters sent to the WASM plugin execution.
This configuration will overwrite the one specified globally in the extension.
This config will be passed as-is to the extension. It is up to the extension to deserialize the config and use it.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


match

</td>

<td>

List of [tetrateio.api.tsb.types.v2.TrafficSelector](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-trafficselector) <br/> Specifies the criteria to determine which traffic is passed to WasmExtension.
If a traffic satisfies any of TrafficSelectors,
the traffic passes to the WasmExtension.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## WorkloadSelector {#tetrateio-api-tsb-types-v2-workloadselector}

`WorkloadSelector` selects one or more workloads in a
namespace. `WorkloadSelector` can be used in TrafficSetting,
SecuritySetting, and Gateway APIs in `BRIDGED` mode to scope the
configuration to a specific set of workloads.



  
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


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The namespace where the workload resides.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


labels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> _REQUIRED_ <br/> One or more labels that indicate a specific set of pods/VMs in
the namespace. If omitted, the TrafficSetting or SecuritySetting
configuration will apply to all workloads in the
namespace. Labels are required for Gateway API resources.

</td>

<td>

map = {<br/>&nbsp;&nbsp;min_pairs: `1`<br/>&nbsp;&nbsp;keys: `{string:{min_len:1}}`<br/>&nbsp;&nbsp;values: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## Object {#tetrateio-api-tsb-types-v2-object}

Format for all API objects in TSB as exposed in the CLI.



  
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


apiVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> api.tsb.tetrate.io/v2, traffic.tsb.tetrate.io/v2,
security.tsb.tetrate.io/v2, gateway.tsb.tetrate.io/v2,
networking.istio.io/v1beta1, security.istio.io/v1beta1, etc.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


kind

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Workspace, Cluster, Tenant, Team, User, WorkspaceSetting, Group
(under traffic.tsb.tetrate.io and security.tsb.tetrate.io),
TrafficSetting, SecuritySetting, etc.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


metadata

</td>

<td>

[tetrateio.api.tsb.types.v2.ObjectMeta](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-objectmeta) <br/> _REQUIRED_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


spec

</td>

<td>

[google.protobuf.Any](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Any) <br/> The API payload.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


status

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Contains errors, tokens (in case of cluster onboarding, and other information).

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ObjectMeta {#tetrateio-api-tsb-types-v2-objectmeta}

Metadata associated with each API Object.



  
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


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Name associated with the object. The object name must be unique
within the `kind` and the parent. For example, all workspaces
under a tenant should have a unique name. Traffic groups under a
workspace should have a unique name, while names are not required
to be unique across traffic groups in different workspaces.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Applicable when using Istio objects.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tenant

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The tenant to which the object belongs to.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


workspace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The workspace to which the object belongs to.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


group

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The traffic/security/gateway group to which the object belongs to.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


resourceVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Resource version is used internally to track propagation of resources to the data planes.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


labels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> User specified labels to attach to the objects.
This is only available for Istio resources when applying configuration in DIRECT mode. Labels
applied to TSB resources will be ignored.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


annotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Istio artifacts must contain 4 annotations:
tsb.tetrate.io/organization, tsb.tetrate.io/tenant, tsb.tetrate.io/workspace,
and one of tsb.tetrate.io/trafficGroup, tsb.tetrate.io/securityGroup,
tsb.tetrate.io/gatewayGroup or tsb.tetrate.io/istioInternalGroup
This is only available for Istio resources when applying configuration in DIRECT mode. Labels
applied to TSB resources will be ignored.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


displayName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> User friendly name for the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


description

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> A description of the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


organization

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The organization to which the object belongs to

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


application

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The application to which the resource belongs to

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


api

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The API to which the resource belongs to

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


service

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The service which the resource belongs to.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


telemetrySource

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The telemetry source the resource belongs to.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The fully-qualified name of a resource.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## IstioObjectSpec {#tetrateio-api-tsb-types-v2-istioobjectspec}

Contains the raw type of an Istio object.
This is used to generate the documentation examples when showing the
serialized form of Istio direct mode resources.



  
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


type

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## TypeInfo {#tetrateio-api-tsb-types-v2-typeinfo}

TypeInfo provides metadata describing a message type.



  
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


generatesConfig

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Indicates that the type has a configuration status and that it will
go through several stages after creation until it is fully ready.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


aggregatesStatus

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Indicates that the type has its status aggregated from the status
of its child resources.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


dependencies

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If not empty, it indicates on what resources it's dependent.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


lastEventXcpAccepted

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> By setting this to `true`, the last expected event for the resource will be XCP_ACCEPTED, and its status will be set to READY after
the event is received.
This should be set in resources that need to become READY when they are accepted by XCP Central
without waiting for the XCP Edges.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## CreateIstioObjectRequest {#tetrateio-api-tsb-types-v2-createistioobjectrequest}

Request to create an Istio Object



  
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


parent

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Istio Object will be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The short name for the Istio Object to be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


object

</td>

<td>

[tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject) <br/> _REQUIRED_ <br/> Details of the Istio Object to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteIstioObjectRequest {#tetrateio-api-tsb-types-v2-deleteistioobjectrequest}

Request to delete a Istio Object.



  
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


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the IstIo Object.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetIstioObjectRequest {#tetrateio-api-tsb-types-v2-getistioobjectrequest}

Request to retrieve a Istio Object.



  
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


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Istio Object.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## IstioObject {#tetrateio-api-tsb-types-v2-istioobject}

Wrapper for Istio direct mode objects with all the details needed to add it
to the TSB resource hierarchy.



  
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


metadata

</td>

<td>

[tetrateio.api.tsb.types.v2.IstioObject.ConfigMeta](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject-configmeta) <br/> Metadata for the Istio object

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


spec

</td>

<td>

[google.protobuf.Any](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Any) <br/> The Istio API object

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### ConfigMeta {#tetrateio-api-tsb-types-v2-istioobject-configmeta}





  
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


apiVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> networking.istio.io/v1beta1, security.istio.io/v1beta1, etc.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


kind

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> VirtualService, Gateway, DestinationRule, Sidecar, etc.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Short name associated with the object. The object name must be unique
within the `kind` and the parent. For example, all workspaces
under a tenant should have a unique name. Traffic groups under a
workspace should have a unique name, while names are not required
to be unique across traffic groups in different workspaces.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Namespace where the Istio object applies.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


labels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> User specified labels to attach to the object.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


annotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Istio artifacts must contain 4 annotations:
tsb.tetrate.io/organization, tsb.tetrate.io/tenant, tsb.tetrate.io/workspace,
and one of tsb.tetrate.io/trafficGroup, tsb.tetrate.io/securityGroup,
tsb.tetrate.io/gatewayGroup or tsb.tetrate.io/istioInternalGroup

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListIstioObjectsRequest {#tetrateio-api-tsb-types-v2-lististioobjectsrequest}

Request to list Istio Object.



  
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


parent

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Istio Objects from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListIstioObjectsResponse {#tetrateio-api-tsb-types-v2-lististioobjectsresponse}

List of Istio direct mode objects



  
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


objects

</td>

<td>

List of [tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




## ConfigMode {#tetrateio-api-tsb-types-v2-configmode}

The configuration mode used by a traffic, security or a gateway group.


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


BRIDGED

</td>

<td>

0

</td>

<td>

Indicates that the configurations to be added to the group will
use macro APIs that automatically generate Istio APIs under the
hood.

</td>
</tr>
    
<tr>
<td>


DIRECT

</td>

<td>

1

</td>

<td>

Indicates that the configurations to be added to the group will
directly use Istio APIs.

</td>
</tr>
    
</table>
  



## PropagationStrategy {#tetrateio-api-tsb-types-v2-propagationstrategy}

The PropagationStrategy is the key differentiating factor to decide how a security
policy should be propagated and applied at runtime across clusters.
The default propagation strategy is REPLACE, in which a lower level SecuritySetting
in the configuration hierarchy replaces a higher level SecuritySetting.
The STRICTER PropagationStrategy on the other hand makes sure the default
SecuritySettings configured at the parent level are always enforced and propagated
down the hierarchy unless additional SecuritySettings are defined and restricted
further in the configuration hierarchy.

* `REPLACE` should be used when resources in the hierarchy are allowed to override the default
settings configured at the higher levels.
* `STRICTER` should be used when the default settings must prevail, and the settings can only be
made more restrictive by child resources at lower levels of the hierarchy.

When a resource or property of it affected by the propagation strategy is propagated down the hierarchy, regardless
of the defined strategy (`REPLACE` or `STRICTER`), a parent defined resource or a property of the
resource will be used (propagated) in absence of a child resource or a property of it.

For example, the following policy configures optional mTLS for traffic within the workspace, but
it allows SecuritySettings to modify it. The example shows a workspace that configures
service-to-service access so that only services in the same workspace can talk to each other.
The `REPLACE` propagation policy allows individual settings to override it. In the example, the
SecuritySettings allows services within that group to be reachable from any
service in the cluster, regardless for the workspace they belong to, even though the Workspace
restricts service-to-service access to only services in the Workspace.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  name: w1-settings
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  defaultSecuritySetting:
    propagationStrategy: REPLACE
    authorization:
      mode: WORKSPACE
---
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  authorization:
    mode: CLUSTER
```

`STRICTER` propagation configures defaults that can be only be restricted down the hierarchy.
The following example configures the same WorkspaceSetting but with a `STRICTER` propagation mode.
The `defaults` SecuritySetting further narrows down that access to the `GROUP` scope, which is
allowed because GROUP is more strict than WORKSPACE. However, the `defaults-invalid` SecuritySetting
configures `CLUSTER` access, which would widen the scope defined at the Workspace. That settings will
not be allowed based on the `STRICTER` propagation policy.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  name: w1-settings
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  defaultSecuritySetting:
    propagationStrategy: STRICTER
    authorization:
      mode: WORKSPACE
---
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  authorization:
    mode: GROUP
---
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults-invalid
  group: t2
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  authorization:
    mode: CLUSTER
```

Further details of how security settings are resolved between in `STRICTER` mode between a parent and a
child resource can be found in the [SecuritySettings reference](../../security/v2/security_setting#securitysetting).


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


REPLACE

</td>

<td>

0

</td>

<td>

Is the default configuration propagation strategy.
A lower defined configuration in the hierarchy will replace a higher configuration in the hierarchy.
Otherwise, if a lower configuration is not defined, the configuration higher up in the hierarchy will
prevail.
For instance, a defined default propagation strategy for workspace default security settings
will replace tenant&#39;s defined default security settings.

</td>
</tr>
    
<tr>
<td>


STRICTER

</td>

<td>

1

</td>

<td>

STRICTER propagation strategy propagates the strictest configuration between a defined higher level and
a defined lower level configuration in the hierarchy. If a lower level configuration in the hierarchy
is not defined, the higher one will prevail.
Which configuration is stricter than the other is defined by each concrete configuration that allows specifying
a propagation strategy.

</td>
</tr>
    
</table>
  



## WorkloadMode {#tetrateio-api-tsb-types-v2-workloadmode}

WorkloadMode allows selection of the role of the underlying workload in
network traffic. A workload is considered as acting as a SERVER if it is
the destination of the traffic (that is, traffic direction, from the
perspective of the workload is *inbound*). If the workload is the source of
the network traffic, it is considered to be in CLIENT mode (traffic is
*outbound* from the workload).


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


UNDEFINED

</td>

<td>

0

</td>

<td>

Default value, which will be interpreted by its own usage.

</td>
</tr>
    
<tr>
<td>


CLIENT

</td>

<td>

1

</td>

<td>

Selects for scenarios when the workload is the
source of the network traffic. In addition,
if the workload is a gateway, selects this.

</td>
</tr>
    
<tr>
<td>


SERVER

</td>

<td>

2

</td>

<td>

Selects for scenarios when the workload is the
destination of the network traffic.

</td>
</tr>
    
<tr>
<td>


CLIENT_AND_SERVER

</td>

<td>

3

</td>

<td>

Selects for scenarios when the workload is either the
source or destination of the network traffic.

</td>
</tr>
    
</table>
  


