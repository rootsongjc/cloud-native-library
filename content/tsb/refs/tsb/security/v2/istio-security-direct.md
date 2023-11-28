---
title: Istio Direct Mode Security Service
description: Service to manage security settings in Istio Direct mode.
---

<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage security settings in Istio Direct mode.


## IstioSecurity {#tetrateio-api-tsb-security-v2-istiosecurity}

The Istio Security service provides methods to manage security settings in Istio direct mode.

The methods in this service allow users to push Istio security configuration resources into TSB.
All properties of the TSB resource hierarchies apply as well to these resources: grouping, access
control policies in the management plane, etc.


### CreatePeerAuthentication

<PanelContent>
<PanelContentCode>

rpc CreatePeerAuthentication ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create a new Istio PeerAuthentication resource in the given group.

</PanelContent>

### GetPeerAuthentication

<PanelContent>
<PanelContentCode>

rpc GetPeerAuthentication ([tetrateio.api.tsb.types.v2.GetIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-getistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** READ

Get the details of the given Istio PeerAuthentication resource.

</PanelContent>

### UpdatePeerAuthentication

<PanelContent>
<PanelContentCode>

rpc UpdatePeerAuthentication ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** WRITE

Modify a Istio PeerAuthentication resource.

</PanelContent>

### ListPeerAuthentications

<PanelContent>
<PanelContentCode>

rpc ListPeerAuthentications ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio PeerAuthentication resources that have been attached to the security group.

</PanelContent>

### DeletePeerAuthentication

<PanelContent>
<PanelContentCode>

rpc DeletePeerAuthentication ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio PeerAuthentication resource.

</PanelContent>

### CreateAuthorizationPolicy

<PanelContent>
<PanelContentCode>

rpc CreateAuthorizationPolicy ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio AuthorizationPolicy in the given security group.

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

Modify an Istio AuthorizationPolicy.

</PanelContent>

### ListAuthorizationPolicies

<PanelContent>
<PanelContentCode>

rpc ListAuthorizationPolicies ([tetrateio.api.tsb.types.v2.ListIstioObjectsRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsrequest)) returns ([tetrateio.api.tsb.types.v2.ListIstioObjectsResponse](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-lististioobjectsresponse))

</PanelContentCode>



List all Istio AuthorizationPolies that have been attached to the security group.

</PanelContent>

### DeleteAuthorizationPolicy

<PanelContent>
<PanelContentCode>

rpc DeleteAuthorizationPolicy ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio AuthorizationPolicy.

</PanelContent>

### CreateRequestAuthentication

<PanelContent>
<PanelContentCode>

rpc CreateRequestAuthentication ([tetrateio.api.tsb.types.v2.CreateIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-createistioobjectrequest)) returns ([tetrateio.api.tsb.types.v2.IstioObject](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-istioobject))

</PanelContentCode>

**Requires** CREATE

Create an Istio RequestAuthentication in the security group.

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



List all Istio RequestAuthentications that have been attached to the security group.

</PanelContent>

### DeleteRequestAuthentication

<PanelContent>
<PanelContentCode>

rpc DeleteRequestAuthentication ([tetrateio.api.tsb.types.v2.DeleteIstioObjectRequest](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-deleteistioobjectrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Istio RequestAuthentication.

</PanelContent>







