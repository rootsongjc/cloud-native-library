---
title: Istio Direct Mode Traffic Service
description: Service to manage traffic settings in Istio Direct mode.
---

<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage traffic settings in Istio Direct mode.


## IstioTraffic {#tetrateio-api-tsb-traffic-v2-istiotraffic}

The Istio Traffic service provides methods to manage traffic settings in Istio direct mode.

The methods in this service allow users to push Istio traffic configuration resources into TSB.
All properties of the TSB resource hierarchies apply as well to these resources: grouping, access
control policies in the management plane, etc.


### CreateVirtualService

<PanelContent>
<PanelContentCode>

rpc CreateVirtualService ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio VirtualService in the given traffic group.
Note that the VirtualService must be in one of the namespaces owned by the group.

</PanelContent>

### GetVirtualService

<PanelContent>
<PanelContentCode>

rpc GetVirtualService ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

Get the details of the given Istio VirtualService

</PanelContent>

### UpdateVirtualService

<PanelContent>
<PanelContentCode>

rpc UpdateVirtualService ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify an existing Istio VirtualService

</PanelContent>

### ListVirtualServices

<PanelContent>
<PanelContentCode>

rpc ListVirtualServices ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio VirtualServices that are attached to the given traffic group.

</PanelContent>

### DeleteVirtualService

<PanelContent>
<PanelContentCode>

rpc DeleteVirtualService ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio VirtualService.

</PanelContent>

### CreateDestinationRule

<PanelContent>
<PanelContentCode>

rpc CreateDestinationRule ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio DestinationRule in the given traffic group.

</PanelContent>

### GetDestinationRule

<PanelContent>
<PanelContentCode>

rpc GetDestinationRule ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

get the details of the given Istio DestinationRule.

</PanelContent>

### UpdateDestinationRule

<PanelContent>
<PanelContentCode>

rpc UpdateDestinationRule ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify the given Istio DestinationRule.

</PanelContent>

### ListDestinationRules

<PanelContent>
<PanelContentCode>

rpc ListDestinationRules ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio DestinationRules that have been attached to the given traffic group.

</PanelContent>

### DeleteDestinationRule

<PanelContent>
<PanelContentCode>

rpc DeleteDestinationRule ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio DestinationRule.

</PanelContent>

### CreateSidecar

<PanelContent>
<PanelContentCode>

rpc CreateSidecar ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio Sidecar resource in the given traffic group.

</PanelContent>

### GetSidecar

<PanelContent>
<PanelContentCode>

rpc GetSidecar ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

Get the details of the given Istio Sidecar resource.

</PanelContent>

### UpdateSidecar

<PanelContent>
<PanelContentCode>

rpc UpdateSidecar ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify the given Istio Sidecar resource.

</PanelContent>

### ListSidecars

<PanelContent>
<PanelContentCode>

rpc ListSidecars ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio Sidecar resources that have been attached to the given traffic group.

</PanelContent>

### DeleteSidecar

<PanelContent>
<PanelContentCode>

rpc DeleteSidecar ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio Sidecar resource.

</PanelContent>







