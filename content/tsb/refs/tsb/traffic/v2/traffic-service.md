---
title: Traffic Service
description: Service to manage traffic settings.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage traffic settings.


## Traffic {#tetrateio-api-tsb-traffic-v2-traffic}

The Traffic service provides methods to manage traffic settings in TSB.

It provides methods to create and manage traffic groups within a workspace, allowing
to create fine-grained groupings to configure a subset of the workspace namespaces.
Access policies can be assigned at group level, providing a fine-grained access control
to the traffic configuration features.

The Traffic service also provides methods to configure the different traffic settings
that are allowed within each group.


### CreateGroup

<PanelContent>
<PanelContentCode>

rpc CreateGroup ([tetrateio.api.tsb.traffic.v2.CreateTrafficGroupRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-createtrafficgrouprequest)) returns ([tetrateio.api.tsb.traffic.v2.Group](../../../tsb/traffic/v2/traffic_group#tetrateio-api-tsb-traffic-v2-group))

</PanelContentCode>

**Requires** CREATE

Create a new traffic group in the given workspace.

Groups will by default configure all the namespaces owned by their workspace, unless
explicitly configured. If a specific set of namespaces is set for the group, it must be a
subset of the namespaces defined by its workspace.

</PanelContent>

### GetGroup

<PanelContent>
<PanelContentCode>

rpc GetGroup ([tetrateio.api.tsb.traffic.v2.GetTrafficGroupRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-gettrafficgrouprequest)) returns ([tetrateio.api.tsb.traffic.v2.Group](../../../tsb/traffic/v2/traffic_group#tetrateio-api-tsb-traffic-v2-group))

</PanelContentCode>

**Requires** READ

Get the details of the given traffic group.

</PanelContent>

### UpdateGroup

<PanelContent>
<PanelContentCode>

rpc UpdateGroup ([tetrateio.api.tsb.traffic.v2.Group](../../../tsb/traffic/v2/traffic_group#tetrateio-api-tsb-traffic-v2-group)) returns ([tetrateio.api.tsb.traffic.v2.Group](../../../tsb/traffic/v2/traffic_group#tetrateio-api-tsb-traffic-v2-group))

</PanelContentCode>

**Requires** WRITE

Modify the given traffic group.

</PanelContent>

### ListGroups

<PanelContent>
<PanelContentCode>

rpc ListGroups ([tetrateio.api.tsb.traffic.v2.ListTrafficGroupsRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-listtrafficgroupsrequest)) returns ([tetrateio.api.tsb.traffic.v2.ListTrafficGroupsResponse](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-listtrafficgroupsresponse))

</PanelContentCode>



List all traffic groups in the given workspace.

</PanelContent>

### DeleteGroup

<PanelContent>
<PanelContentCode>

rpc DeleteGroup ([tetrateio.api.tsb.traffic.v2.DeleteTrafficGroupRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-deletetrafficgrouprequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given traffic group.
Note that deleting resources in TSB is a recursive operation. Deleting a traffic group will
delete all configuration objects that exist in it.

</PanelContent>

### CreateSettings

<PanelContent>
<PanelContentCode>

rpc CreateSettings ([tetrateio.api.tsb.traffic.v2.CreateTrafficSettingsRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-createtrafficsettingsrequest)) returns ([tetrateio.api.tsb.traffic.v2.TrafficSetting](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-trafficsetting))

</PanelContentCode>

**Requires** CreateTrafficSetting

Create a settings object for the given traffic group.

</PanelContent>

### GetSettings

<PanelContent>
<PanelContentCode>

rpc GetSettings ([tetrateio.api.tsb.traffic.v2.GetTrafficSettingsRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-gettrafficsettingsrequest)) returns ([tetrateio.api.tsb.traffic.v2.TrafficSetting](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-trafficsetting))

</PanelContentCode>

**Requires** ReadTrafficSetting

Get the details for the given settings object.

</PanelContent>

### UpdateSettings

<PanelContent>
<PanelContentCode>

rpc UpdateSettings ([tetrateio.api.tsb.traffic.v2.TrafficSetting](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-trafficsetting)) returns ([tetrateio.api.tsb.traffic.v2.TrafficSetting](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-trafficsetting))

</PanelContentCode>

**Requires** WriteTrafficSetting

Modify the given settings in the given traffic group.

</PanelContent>

### ListSettings

<PanelContent>
<PanelContentCode>

rpc ListSettings ([tetrateio.api.tsb.traffic.v2.ListTrafficSettingsRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-listtrafficsettingsrequest)) returns ([tetrateio.api.tsb.traffic.v2.ListTrafficSettingsResponse](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-listtrafficsettingsresponse))

</PanelContentCode>



List all the settings objects that have been attached to the given traffic group.

</PanelContent>

### DeleteSettings

<PanelContent>
<PanelContentCode>

rpc DeleteSettings ([tetrateio.api.tsb.traffic.v2.DeleteTrafficSettingsRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-deletetrafficsettingsrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DeleteTrafficSetting

Delete the given settings object from the traffic group.

</PanelContent>

### CreateServiceRoute

<PanelContent>
<PanelContentCode>

rpc CreateServiceRoute ([tetrateio.api.tsb.traffic.v2.CreateServiceRouteRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-createservicerouterequest)) returns ([tetrateio.api.tsb.traffic.v2.ServiceRoute](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute))

</PanelContentCode>

**Requires** CREATE

Create a new service route in the given traffic group.

</PanelContent>

### GetServiceRoute

<PanelContent>
<PanelContentCode>

rpc GetServiceRoute ([tetrateio.api.tsb.traffic.v2.GetServiceRouteRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-getservicerouterequest)) returns ([tetrateio.api.tsb.traffic.v2.ServiceRoute](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute))

</PanelContentCode>

**Requires** READ

Get the details of the given service route.

</PanelContent>

### UpdateServiceRoute

<PanelContent>
<PanelContentCode>

rpc UpdateServiceRoute ([tetrateio.api.tsb.traffic.v2.ServiceRoute](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute)) returns ([tetrateio.api.tsb.traffic.v2.ServiceRoute](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute))

</PanelContentCode>

**Requires** WRITE

Modify a service route.

</PanelContent>

### ListServiceRoutes

<PanelContent>
<PanelContentCode>

rpc ListServiceRoutes ([tetrateio.api.tsb.traffic.v2.ListServiceRoutesRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-listserviceroutesrequest)) returns ([tetrateio.api.tsb.traffic.v2.ListServiceRoutesResponse](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-listserviceroutesresponse))

</PanelContentCode>



List all service routes that have been attached to the traffic group.

</PanelContent>

### DeleteServiceRoute

<PanelContent>
<PanelContentCode>

rpc DeleteServiceRoute ([tetrateio.api.tsb.traffic.v2.DeleteServiceRouteRequest](../../../tsb/traffic/v2/traffic_service#tetrateio-api-tsb-traffic-v2-deleteservicerouterequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given service route.

</PanelContent>






## CreateServiceRouteRequest {#tetrateio-api-tsb-traffic-v2-createservicerouterequest}

Request to create a ServiceRoute.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the ServiceRoute will be created.

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


serviceRoute

</td>

<td>

[tetrateio.api.tsb.traffic.v2.ServiceRoute](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute) <br/> _REQUIRED_ <br/> Details of the ServiceRoute to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateTrafficGroupRequest {#tetrateio-api-tsb-traffic-v2-createtrafficgrouprequest}

Request to create a Traffic Group.



  
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

[tetrateio.api.tsb.traffic.v2.Group](../../../tsb/traffic/v2/traffic_group#tetrateio-api-tsb-traffic-v2-group) <br/> _REQUIRED_ <br/> Details of the Group to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateTrafficSettingsRequest {#tetrateio-api-tsb-traffic-v2-createtrafficsettingsrequest}

Request to create a Traffic Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Traffic Settings will be created.

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


settings

</td>

<td>

[tetrateio.api.tsb.traffic.v2.TrafficSetting](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-trafficsetting) <br/> _REQUIRED_ <br/> Details of the Traffic Settings to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteServiceRouteRequest {#tetrateio-api-tsb-traffic-v2-deleteservicerouterequest}

Request to delete a ServiceRoute.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the ServiceRoute.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteTrafficGroupRequest {#tetrateio-api-tsb-traffic-v2-deletetrafficgrouprequest}

Request to delete a Traffic Group.



  
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
  


## DeleteTrafficSettingsRequest {#tetrateio-api-tsb-traffic-v2-deletetrafficsettingsrequest}

Request to delete a Traffic Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Traffic Settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetServiceRouteRequest {#tetrateio-api-tsb-traffic-v2-getservicerouterequest}

Request to retrieve a ServiceRoute.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the ServiceRoute.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetTrafficGroupRequest {#tetrateio-api-tsb-traffic-v2-gettrafficgrouprequest}

Request to retrieve a Traffic Group.



  
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
  


## GetTrafficSettingsRequest {#tetrateio-api-tsb-traffic-v2-gettrafficsettingsrequest}

Request to retrieve a Traffic Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Traffic Settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListServiceRoutesRequest {#tetrateio-api-tsb-traffic-v2-listserviceroutesrequest}

Request to list ServiceRoutes.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list ServiceRoutes from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListServiceRoutesResponse {#tetrateio-api-tsb-traffic-v2-listserviceroutesresponse}

List of all service routes defined in the traffic group.



  
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


serviceRoutes

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.ServiceRoute](../../../tsb/traffic/v2/service_route#tetrateio-api-tsb-traffic-v2-serviceroute) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListTrafficGroupsRequest {#tetrateio-api-tsb-traffic-v2-listtrafficgroupsrequest}

Request to list Traffic Groups.



  
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
  


## ListTrafficGroupsResponse {#tetrateio-api-tsb-traffic-v2-listtrafficgroupsresponse}

List of all existing traffic groups in the workspace.



  
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

List of [tetrateio.api.tsb.traffic.v2.Group](../../../tsb/traffic/v2/traffic_group#tetrateio-api-tsb-traffic-v2-group) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListTrafficSettingsRequest {#tetrateio-api-tsb-traffic-v2-listtrafficsettingsrequest}

Request to list Traffic Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Traffic Settings from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListTrafficSettingsResponse {#tetrateio-api-tsb-traffic-v2-listtrafficsettingsresponse}

List of all existing traffic settings objects in the traffic group.



  
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


settings

</td>

<td>

List of [tetrateio.api.tsb.traffic.v2.TrafficSetting](../../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-trafficsetting) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



