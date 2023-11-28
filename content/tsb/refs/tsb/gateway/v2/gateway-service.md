---
title: Gateway Service
description: Service to manage the configuration for Gateways.
---

<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage the configuration for Gateways.


## Gateways {#tetrateio-api-tsb-gateway-v2-gateways}

The Gateway service provides methods to manage gateway settings in TSB.

It provides methods to create and manage gateway groups within a workspace, allowing
to create fine-grained groupings to configure a subset of the workspace namespaces.
Access policies can be assigned at group level, providing a fine-grained access control
to the gateway configuration features.

The Gateway service also provides methods to configure the different gateway settings
that are allowed within each group.


### CreateGroup

<PanelContent>
<PanelContentCode>

rpc CreateGroup ([tetrateio.api.tsb.gateway.v2.CreateGatewayGroupRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-creategatewaygrouprequest)) returns ([tetrateio.api.tsb.gateway.v2.Group](../../../tsb/gateway/v2/gateway_group#tetrateio-api-tsb-gateway-v2-group))

</PanelContentCode>

**Requires** CreateGatewayGroup

Create a new gateway group in the given workspace.

Groups will by default configure all the namespaces owned by their workspace, unless
explicitly configured. If a specific set of namespaces is set for the group, it must be a
subset of the namespaces defined by its workspace.

</PanelContent>

### GetGroup

<PanelContent>
<PanelContentCode>

rpc GetGroup ([tetrateio.api.tsb.gateway.v2.GetGatewayGroupRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-getgatewaygrouprequest)) returns ([tetrateio.api.tsb.gateway.v2.Group](../../../tsb/gateway/v2/gateway_group#tetrateio-api-tsb-gateway-v2-group))

</PanelContentCode>

**Requires** ReadGatewayGroup

Get the details of the given gateway group.

</PanelContent>

### UpdateGroup

<PanelContent>
<PanelContentCode>

rpc UpdateGroup ([tetrateio.api.tsb.gateway.v2.Group](../../../tsb/gateway/v2/gateway_group#tetrateio-api-tsb-gateway-v2-group)) returns ([tetrateio.api.tsb.gateway.v2.Group](../../../tsb/gateway/v2/gateway_group#tetrateio-api-tsb-gateway-v2-group))

</PanelContentCode>

**Requires** WriteGatewayGroup

update the given gateway group.

</PanelContent>

### ListGroups

<PanelContent>
<PanelContentCode>

rpc ListGroups ([tetrateio.api.tsb.gateway.v2.ListGatewayGroupsRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-listgatewaygroupsrequest)) returns ([tetrateio.api.tsb.gateway.v2.ListGatewayGroupsResponse](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-listgatewaygroupsresponse))

</PanelContentCode>



List all gateway groups that exist in the workspace.

</PanelContent>

### DeleteGroup

<PanelContent>
<PanelContentCode>

rpc DeleteGroup ([tetrateio.api.tsb.gateway.v2.DeleteGatewayGroupRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-deletegatewaygrouprequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DeleteGatewayGroup

Delete the given gateway group.
Note that deleting resources in TSB is a recursive operation. Deleting a gateway group will
delete all configuration objects that exist in it.

</PanelContent>

### CreateIngressGateway

<PanelContent>
<PanelContentCode>

rpc CreateIngressGateway ([tetrateio.api.tsb.gateway.v2.CreateIngressGatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-createingressgatewayrequest)) returns ([tetrateio.api.tsb.gateway.v2.IngressGateway](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-ingressgateway))

</PanelContentCode>

**Requires** CREATE

Create an Ingress Gateway object in the gateway group.

</PanelContent>

### GetIngressGateway

<PanelContent>
<PanelContentCode>

rpc GetIngressGateway ([tetrateio.api.tsb.gateway.v2.GetIngressGatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-getingressgatewayrequest)) returns ([tetrateio.api.tsb.gateway.v2.IngressGateway](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-ingressgateway))

</PanelContentCode>

**Requires** READ

Get the details of the given Ingress Gateway object.

</PanelContent>

### UpdateIngressGateway

<PanelContent>
<PanelContentCode>

rpc UpdateIngressGateway ([tetrateio.api.tsb.gateway.v2.IngressGateway](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-ingressgateway)) returns ([tetrateio.api.tsb.gateway.v2.IngressGateway](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-ingressgateway))

</PanelContentCode>

**Requires** WRITE

Modify the given Ingress Gateway object.

</PanelContent>

### ListIngressGateways

<PanelContent>
<PanelContentCode>

rpc ListIngressGateways ([tetrateio.api.tsb.gateway.v2.ListIngressGatewaysRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-listingressgatewaysrequest)) returns ([tetrateio.api.tsb.gateway.v2.ListIngressGatewaysResponse](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-listingressgatewaysresponse))

</PanelContentCode>



List all Ingress Gateway objects in the gateway group.

</PanelContent>

### DeleteIngressGateway

<PanelContent>
<PanelContentCode>

rpc DeleteIngressGateway ([tetrateio.api.tsb.gateway.v2.DeleteIngressGatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-deleteingressgatewayrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Ingress Gateway object.

</PanelContent>

### CreateEgressGateway

<PanelContent>
<PanelContentCode>

rpc CreateEgressGateway ([tetrateio.api.tsb.gateway.v2.CreateEgressGatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-createegressgatewayrequest)) returns ([tetrateio.api.tsb.gateway.v2.EgressGateway](../../../tsb/gateway/v2/egress_gateway#tetrateio-api-tsb-gateway-v2-egressgateway))

</PanelContentCode>

**Requires** CREATE

Create an Egress Gateway object in the gateway group.

</PanelContent>

### GetEgressGateway

<PanelContent>
<PanelContentCode>

rpc GetEgressGateway ([tetrateio.api.tsb.gateway.v2.GetEgressGatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-getegressgatewayrequest)) returns ([tetrateio.api.tsb.gateway.v2.EgressGateway](../../../tsb/gateway/v2/egress_gateway#tetrateio-api-tsb-gateway-v2-egressgateway))

</PanelContentCode>

**Requires** READ

Get the details of the given Egress Gateway object.

</PanelContent>

### UpdateEgressGateway

<PanelContent>
<PanelContentCode>

rpc UpdateEgressGateway ([tetrateio.api.tsb.gateway.v2.EgressGateway](../../../tsb/gateway/v2/egress_gateway#tetrateio-api-tsb-gateway-v2-egressgateway)) returns ([tetrateio.api.tsb.gateway.v2.EgressGateway](../../../tsb/gateway/v2/egress_gateway#tetrateio-api-tsb-gateway-v2-egressgateway))

</PanelContentCode>

**Requires** WRITE

Modify the given Egress Gateway object.

</PanelContent>

### ListEgressGateways

<PanelContent>
<PanelContentCode>

rpc ListEgressGateways ([tetrateio.api.tsb.gateway.v2.ListEgressGatewaysRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-listegressgatewaysrequest)) returns ([tetrateio.api.tsb.gateway.v2.ListEgressGatewaysResponse](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-listegressgatewaysresponse))

</PanelContentCode>



List all Egress Gateway objects in the gateway group.

</PanelContent>

### DeleteEgressGateway

<PanelContent>
<PanelContentCode>

rpc DeleteEgressGateway ([tetrateio.api.tsb.gateway.v2.DeleteEgressGatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-deleteegressgatewayrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Egress Gateway object.

</PanelContent>

### CreateTier1Gateway

<PanelContent>
<PanelContentCode>

rpc CreateTier1Gateway ([tetrateio.api.tsb.gateway.v2.CreateTier1GatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-createtier1gatewayrequest)) returns ([tetrateio.api.tsb.gateway.v2.Tier1Gateway](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1gateway))

</PanelContentCode>

**Requires** CREATE

Create a Tier1 Gateway object in the gateway group.

</PanelContent>

### GetTier1Gateway

<PanelContent>
<PanelContentCode>

rpc GetTier1Gateway ([tetrateio.api.tsb.gateway.v2.GetTier1GatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-gettier1gatewayrequest)) returns ([tetrateio.api.tsb.gateway.v2.Tier1Gateway](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1gateway))

</PanelContentCode>

**Requires** READ

get the details of the given Tier1 Gateway object.

</PanelContent>

### UpdateTier1Gateway

<PanelContent>
<PanelContentCode>

rpc UpdateTier1Gateway ([tetrateio.api.tsb.gateway.v2.Tier1Gateway](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1gateway)) returns ([tetrateio.api.tsb.gateway.v2.Tier1Gateway](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1gateway))

</PanelContentCode>

**Requires** WRITE



</PanelContent>

### ListTier1Gateways

<PanelContent>
<PanelContentCode>

rpc ListTier1Gateways ([tetrateio.api.tsb.gateway.v2.ListTier1GatewaysRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-listtier1gatewaysrequest)) returns ([tetrateio.api.tsb.gateway.v2.ListTier1GatewaysResponse](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-listtier1gatewaysresponse))

</PanelContentCode>



List all Tier1 Gateway objects that have been created in the gateway group.

</PanelContent>

### DeleteTier1Gateway

<PanelContent>
<PanelContentCode>

rpc DeleteTier1Gateway ([tetrateio.api.tsb.gateway.v2.DeleteTier1GatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-deletetier1gatewayrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Tier1 Gateway object.

</PanelContent>

### CreateGateway

<PanelContent>
<PanelContentCode>

rpc CreateGateway ([tetrateio.api.tsb.gateway.v2.CreateGatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-creategatewayrequest)) returns ([tetrateio.api.tsb.gateway.v2.Gateway](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-gateway))

</PanelContentCode>

**Requires** CREATE

Create a Gateway object in the gateway group.

</PanelContent>

### GetGateway

<PanelContent>
<PanelContentCode>

rpc GetGateway ([tetrateio.api.tsb.gateway.v2.GetGatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-getgatewayrequest)) returns ([tetrateio.api.tsb.gateway.v2.Gateway](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-gateway))

</PanelContentCode>

**Requires** READ

Get the details of the given Gateway object.

</PanelContent>

### UpdateGateway

<PanelContent>
<PanelContentCode>

rpc UpdateGateway ([tetrateio.api.tsb.gateway.v2.Gateway](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-gateway)) returns ([tetrateio.api.tsb.gateway.v2.Gateway](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-gateway))

</PanelContentCode>

**Requires** WRITE

Modify the given Gateway object.

</PanelContent>

### ListGateways

<PanelContent>
<PanelContentCode>

rpc ListGateways ([tetrateio.api.tsb.gateway.v2.ListGatewaysRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-listgatewaysrequest)) returns ([tetrateio.api.tsb.gateway.v2.ListGatewaysResponse](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-listgatewaysresponse))

</PanelContentCode>



List all Gateway objects in the gateway group.

</PanelContent>

### DeleteGateway

<PanelContent>
<PanelContentCode>

rpc DeleteGateway ([tetrateio.api.tsb.gateway.v2.DeleteGatewayRequest](../../../tsb/gateway/v2/gateway_service#tetrateio-api-tsb-gateway-v2-deletegatewayrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Gateway object.

</PanelContent>






## CreateEgressGatewayRequest {#tetrateio-api-tsb-gateway-v2-createegressgatewayrequest}

Request to create a EgressGateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the EgressGateway will be created.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The short name for the resource to be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


egressGateway

</td>

<td>

[tetrateio.api.tsb.gateway.v2.EgressGateway](../../../tsb/gateway/v2/egress_gateway#tetrateio-api-tsb-gateway-v2-egressgateway) <br/> _REQUIRED_ <br/> Details of the EgressGateway to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateGatewayGroupRequest {#tetrateio-api-tsb-gateway-v2-creategatewaygrouprequest}

Request to create a Gateway Group.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Group will be created.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The short name for the resource to be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


group

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Group](../../../tsb/gateway/v2/gateway_group#tetrateio-api-tsb-gateway-v2-group) <br/> _REQUIRED_ <br/> Details of the Group to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateGatewayRequest {#tetrateio-api-tsb-gateway-v2-creategatewayrequest}

Request to create a Gateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Gateway will be created.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The short name for the resource to be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


gateway

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Gateway](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-gateway) <br/> _REQUIRED_ <br/> Details of the Gateway to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateIngressGatewayRequest {#tetrateio-api-tsb-gateway-v2-createingressgatewayrequest}

Request to create a IngressGateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the IngressGateway will be created.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The short name for the resource to be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


ingressGateway

</td>

<td>

[tetrateio.api.tsb.gateway.v2.IngressGateway](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-ingressgateway) <br/> _REQUIRED_ <br/> Details of the IngressGateway to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateTier1GatewayRequest {#tetrateio-api-tsb-gateway-v2-createtier1gatewayrequest}

Request to create a Tier1Gateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Tier1Gateway will be created.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The short name for the resource to be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


tier1Gateway

</td>

<td>

[tetrateio.api.tsb.gateway.v2.Tier1Gateway](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1gateway) <br/> _REQUIRED_ <br/> Details of the Tier1Gateway to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteEgressGatewayRequest {#tetrateio-api-tsb-gateway-v2-deleteegressgatewayrequest}

Request to delete a EgressGateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the EgressGateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteGatewayGroupRequest {#tetrateio-api-tsb-gateway-v2-deletegatewaygrouprequest}

Request to delete a Gateway Group.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Group.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


force

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Force the deletion of the object even if deletion protection is enabled.
If this is set, then the object and all its children will be deleted even if any of them
has the deletion protection enabled.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## DeleteGatewayRequest {#tetrateio-api-tsb-gateway-v2-deletegatewayrequest}

Request to delete a Gateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Gateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteIngressGatewayRequest {#tetrateio-api-tsb-gateway-v2-deleteingressgatewayrequest}

Request to delete a IngressGateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the IngressGateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteTier1GatewayRequest {#tetrateio-api-tsb-gateway-v2-deletetier1gatewayrequest}

Request to delete a Tier1Gateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Tier1Gateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetEgressGatewayRequest {#tetrateio-api-tsb-gateway-v2-getegressgatewayrequest}

Request to retrieve a EgressGateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the EgressGateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetGatewayGroupRequest {#tetrateio-api-tsb-gateway-v2-getgatewaygrouprequest}

Request to retrieve a Gateway Group.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Group.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetGatewayRequest {#tetrateio-api-tsb-gateway-v2-getgatewayrequest}

Request to retrieve a Gateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Gateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetIngressGatewayRequest {#tetrateio-api-tsb-gateway-v2-getingressgatewayrequest}

Request to retrieve a IngressGateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the IngressGateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetTier1GatewayRequest {#tetrateio-api-tsb-gateway-v2-gettier1gatewayrequest}

Request to retrieve a Tier1Gateway.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Tier1Gateway.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListEgressGatewaysRequest {#tetrateio-api-tsb-gateway-v2-listegressgatewaysrequest}

Request to list EgressGateways.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list EgressGateways from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListEgressGatewaysResponse {#tetrateio-api-tsb-gateway-v2-listegressgatewaysresponse}

Lost of all Egress Gateway objects in the gateway group.



  
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


egressGateways

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.EgressGateway](../../../tsb/gateway/v2/egress_gateway#tetrateio-api-tsb-gateway-v2-egressgateway) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListGatewayGroupsRequest {#tetrateio-api-tsb-gateway-v2-listgatewaygroupsrequest}

Request to list Gateway Groups.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Groups from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListGatewayGroupsResponse {#tetrateio-api-tsb-gateway-v2-listgatewaygroupsresponse}

List of all gateway groups in the workspace.



  
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


groups

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.Group](../../../tsb/gateway/v2/gateway_group#tetrateio-api-tsb-gateway-v2-group) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListGatewaysRequest {#tetrateio-api-tsb-gateway-v2-listgatewaysrequest}

Request to list Gateways.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Gateways from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListGatewaysResponse {#tetrateio-api-tsb-gateway-v2-listgatewaysresponse}

List of all Gateway objects in the gateway group.



  
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


gateways

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.Gateway](../../../tsb/gateway/v2/gateway#tetrateio-api-tsb-gateway-v2-gateway) <br/> List of all Gateway objects.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListIngressGatewaysRequest {#tetrateio-api-tsb-gateway-v2-listingressgatewaysrequest}

Request to list IngressGateways.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list IngressGateways from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListIngressGatewaysResponse {#tetrateio-api-tsb-gateway-v2-listingressgatewaysresponse}

List of all Ingress Gateway objects in the gateway group.



  
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


ingressGateways

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.IngressGateway](../../../tsb/gateway/v2/ingress_gateway#tetrateio-api-tsb-gateway-v2-ingressgateway) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListTier1GatewaysRequest {#tetrateio-api-tsb-gateway-v2-listtier1gatewaysrequest}

Request to list Tier1Gateways.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Tier1Gateways from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListTier1GatewaysResponse {#tetrateio-api-tsb-gateway-v2-listtier1gatewaysresponse}

List of all Tier1 Gateway objects in the gateway group.



  
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


tier1Gateways

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.Tier1Gateway](../../../tsb/gateway/v2/tier1_gateway#tetrateio-api-tsb-gateway-v2-tier1gateway) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



