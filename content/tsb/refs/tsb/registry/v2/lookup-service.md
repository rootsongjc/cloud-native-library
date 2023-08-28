---
title: Service Registry Lookup Service
description: Service to map registered services to configuration groups.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to map registered services to configuration groups.


## Lookup {#tetrateio-api-tsb-registry-v2-lookup}

The Lookup API allows resolving the groups that configure a particular service
in the registry. It allows lookups given a service, but also reverse lookups to
get all the services in the registry that are configured by a particular workspace
or group.


### Groups

<PanelContent>
<PanelContentCode>

rpc Groups ([tetrateio.api.tsb.registry.v2.GroupLookupRequest](../../../tsb/registry/v2/lookup_service#tetrateio-api-tsb-registry-v2-grouplookuprequest)) returns ([tetrateio.api.tsb.registry.v2.GroupLookupResponse](../../../tsb/registry/v2/lookup_service#tetrateio-api-tsb-registry-v2-grouplookupresponse))

</PanelContentCode>

**Requires** ReadTrafficGroup, ReadSecurityGroup, ReadGatewayGroup, ReadIstioInternalGroup

Get all the groups that configure the given service in the registry.

</PanelContent>

### Services

<PanelContent>
<PanelContentCode>

rpc Services ([tetrateio.api.tsb.registry.v2.ServiceLookupRequest](../../../tsb/registry/v2/lookup_service#tetrateio-api-tsb-registry-v2-servicelookuprequest)) returns ([tetrateio.api.tsb.registry.v2.ServiceLookupResponse](../../../tsb/registry/v2/lookup_service#tetrateio-api-tsb-registry-v2-servicelookupresponse))

</PanelContentCode>

**Requires** ReadRegisteredService

Get all the services in the registry that are part of the given selector.
This method can be used to resolve the registered services that are part of a workspace
or group.
This method can be also used to figure out how applying a selector could affect
the platform and have an understanding of which of the existing services would be
included in the selection.

</PanelContent>






## GroupLookupRequest {#tetrateio-api-tsb-registry-v2-grouplookuprequest}

Request to lookup the groups that configure a particular registered service.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The FQN of the registered service to lookup.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GroupLookupResponse {#tetrateio-api-tsb-registry-v2-grouplookupresponse}

List of groups that configure the requested service.



  
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


trafficGroups

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.Group](../../../tsb/traffic/v2/traffic_group#tetrateio-api-tsb-traffic-v2-group) <br/> The traffic groups that configure the given registered service.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


securityGroups

</td>

<td>

List of [tetrateio.api.tsb.security.v2.Group](../../../tsb/security/v2/security_group#tetrateio-api-tsb-security-v2-group) <br/> The security groups that configure the given registered service.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


gatewayGroups

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.Group](../../../tsb/gateway/v2/gateway_group#tetrateio-api-tsb-gateway-v2-group) <br/> The gateway groups that configure the given registered service.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


istioInternalGroups

</td>

<td>

List of [tetrateio.api.tsb.istiointernal.v2.Group](../../../tsb/istiointernal/v2/istio_internal_group#tetrateio-api-tsb-istiointernal-v2-group) <br/> The istio internal groups that configure the given registered service.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ServiceLookupRequest {#tetrateio-api-tsb-registry-v2-servicelookuprequest}

Request for all the services in the registry that are part of the given selector.



  
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


selector

</td>

<td>

[tetrateio.api.tsb.types.v2.NamespaceSelector](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-namespaceselector) <br/> _REQUIRED_ <br/> Selector used to filter services.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


parent

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The FQN of the parent object where services will be looked up

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ServiceLookupResponse {#tetrateio-api-tsb-registry-v2-servicelookupresponse}

List of services that are included in the provided namespace selector.



  
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


services

</td>

<td>

List of [tetrateio.api.tsb.registry.v2.Service](../../../tsb/registry/v2/service#tetrateio-api-tsb-registry-v2-service) <br/> The affected services

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



