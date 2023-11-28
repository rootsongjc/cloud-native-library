---
title: Istio Direct Mode Gateway Service
description: Service to manage gateway settings in Istio Direct mode.
---

<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage gateway settings in Istio Direct mode.


## IstioGateway {#tetrateio-api-tsb-gateway-v2-istiogateway}

The Istio Gateway service provides methods to manage gateway settings in Istio direct mode.

The methods in this service allow users to push Istio gateway configuration resources into TSB.
All properties of the TSB resource hierarchies apply as well to these resources: grouping, access
control policies in the management plane, etc.


### CreateVirtualService

<PanelContent>
<PanelContentCode>

rpc CreateVirtualService ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create a new Istio VirtualService in the gateway group.
Note that the VirtualService must be in one of the namespaces owned by the group.

</PanelContent>

### GetVirtualService

<PanelContent>
<PanelContentCode>

rpc GetVirtualService ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

Get the details of the given Istio VirtualService.

</PanelContent>

### UpdateVirtualService

<PanelContent>
<PanelContentCode>

rpc UpdateVirtualService ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify the given Istio VirtualService.

</PanelContent>

### ListVirtualServices

<PanelContent>
<PanelContentCode>

rpc ListVirtualServices ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio VirtualServices that have been attached to the gateway group.

</PanelContent>

### DeleteVirtualService

<PanelContent>
<PanelContentCode>

rpc DeleteVirtualService ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the Istio VirtualService.

</PanelContent>

### CreateGateway

<PanelContent>
<PanelContentCode>

rpc CreateGateway ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio Gateway object in the gateway group.

</PanelContent>

### GetGateway

<PanelContent>
<PanelContentCode>

rpc GetGateway ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

Get the details of the given Istio Gateway object.

</PanelContent>

### UpdateGateway

<PanelContent>
<PanelContentCode>

rpc UpdateGateway ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify the given Istio Gateway object.

</PanelContent>

### ListGateways

<PanelContent>
<PanelContentCode>

rpc ListGateways ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all the Istio Gateway objects that have been attached to the gateway group.

</PanelContent>

### DeleteGateway

<PanelContent>
<PanelContentCode>

rpc DeleteGateway ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

delete the given Istio Gateway object.

</PanelContent>

### CreateRequestAuthentication

<PanelContent>
<PanelContentCode>

rpc CreateRequestAuthentication ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio RequestAuthentication in the gateway group.

</PanelContent>

### GetRequestAuthentication

<PanelContent>
<PanelContentCode>

rpc GetRequestAuthentication ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

Get the details for the given Istio RequestAuthentication.

</PanelContent>

### UpdateRequestAuthentication

<PanelContent>
<PanelContentCode>

rpc UpdateRequestAuthentication ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify the given Istio RequestAuthentication.

</PanelContent>

### ListRequestAuthentications

<PanelContent>
<PanelContentCode>

rpc ListRequestAuthentications ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio RequestAuthentications that have been attached to the gateway group.

</PanelContent>

### DeleteRequestAuthentication

<PanelContent>
<PanelContentCode>

rpc DeleteRequestAuthentication ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio RequestAuthentication.

</PanelContent>

### CreateAuthorizationPolicy

<PanelContent>
<PanelContentCode>

rpc CreateAuthorizationPolicy ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio AuthorizationPolicy in the gateway group.

</PanelContent>

### GetAuthorizationPolicy

<PanelContent>
<PanelContentCode>

rpc GetAuthorizationPolicy ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

Get the details of the given Istio AuthorizationPolicy.

</PanelContent>

### UpdateAuthorizationPolicy

<PanelContent>
<PanelContentCode>

rpc UpdateAuthorizationPolicy ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify the given Istio AuthorizationPolicy.

</PanelContent>

### ListAuthorizationPolicies

<PanelContent>
<PanelContentCode>

rpc ListAuthorizationPolicies ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio AuthorizationPolies that have been attached to the gateway group.

</PanelContent>

### DeleteAuthorizationPolicy

<PanelContent>
<PanelContentCode>

rpc DeleteAuthorizationPolicy ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio AuthorizationPolicy.

</PanelContent>







