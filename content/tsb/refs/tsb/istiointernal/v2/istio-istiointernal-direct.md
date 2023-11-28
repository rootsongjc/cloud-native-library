---
title: Istio Internal Direct Mode Service
description: Service to resources in Istio Direct mode.
---

<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`IstioInternalDirect` service provides methods to manage resources in Istio direct mode.


## IstioInternalDirect {#tetrateio-api-tsb-istiointernal-v2-istiointernaldirect}

`IstioInternalDirect` service provides methods to manage resources in Istio direct mode.

The methods in this service allow users to push resources like Istio Envoy filters or service entries, into TSB.
All properties of the TSB resource hierarchies apply as well to these resources: grouping, access
control policies in the management plane, etc.


### CreateEnvoyFilter

<PanelContent>
<PanelContentCode>

rpc CreateEnvoyFilter ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio EnvoyFilter in the given istio internal group.
Note that the EnvoyFilter must be in one of the namespaces owned by the group.

</PanelContent>

### GetEnvoyFilter

<PanelContent>
<PanelContentCode>

rpc GetEnvoyFilter ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

Get the details of the given Istio EnvoyFilter.

</PanelContent>

### UpdateEnvoyFilter

<PanelContent>
<PanelContentCode>

rpc UpdateEnvoyFilter ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify an existing Istio EnvoyFilter.

</PanelContent>

### ListEnvoyFilters

<PanelContent>
<PanelContentCode>

rpc ListEnvoyFilters ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio EnvoyFilter that are attached to the given Istio internal group.

</PanelContent>

### DeleteEnvoyFilter

<PanelContent>
<PanelContentCode>

rpc DeleteEnvoyFilter ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio EnvoyFilter.

</PanelContent>

### CreateServiceEntry

<PanelContent>
<PanelContentCode>

rpc CreateServiceEntry ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio ServiceEntry resource in the given Istio internal group.

</PanelContent>

### GetServiceEntry

<PanelContent>
<PanelContentCode>

rpc GetServiceEntry ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

Get the details of the given Istio ServiceEntry resource.

</PanelContent>

### UpdateServiceEntry

<PanelContent>
<PanelContentCode>

rpc UpdateServiceEntry ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify the given Istio ServiceEntry resource.

</PanelContent>

### ListServiceEntries

<PanelContent>
<PanelContentCode>

rpc ListServiceEntries ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio ServiceEntry resources that have been attached to the given Istio internal group.

</PanelContent>

### DeleteServiceEntry

<PanelContent>
<PanelContentCode>

rpc DeleteServiceEntry ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio ServiceEntry resource.

</PanelContent>

### CreateWasmPlugin

<PanelContent>
<PanelContentCode>

rpc CreateWasmPlugin ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio WasmPlugin resource in the given Istio internal group.

</PanelContent>

### GetWasmPlugin

<PanelContent>
<PanelContentCode>

rpc GetWasmPlugin ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

Get the details of the given Istio WasmPlugin resource.

</PanelContent>

### UpdateWasmPlugin

<PanelContent>
<PanelContentCode>

rpc UpdateWasmPlugin ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify the given Istio WasmPlugin resource.

</PanelContent>

### ListWasmPlugins

<PanelContent>
<PanelContentCode>

rpc ListWasmPlugins ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio WasmPlugin resources that have been attached to the given Istio internal group.

</PanelContent>

### DeleteWasmPlugin

<PanelContent>
<PanelContentCode>

rpc DeleteWasmPlugin ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio WasmPlugin resource.

</PanelContent>







