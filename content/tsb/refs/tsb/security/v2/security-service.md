---
title: Security Service
description: Service to manage security settings.
---


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage security settings.


## Security {#tetrateio-api-tsb-security-v2-security}

The Security service provides methods to manage security settings in TSB.

It provides methods to create and manage security groups within a workspace, allowing
to create fine-grained groupings to configure a subset of the workspace namespaces.
Access policies can be assigned at group level, providing a fine-grained access control
to the security configuration features.

The Security service also provides methods to configure the different security settings
that are allowed within each group.


### CreateGroup

<PanelContent>
<PanelContentCode>

rpc CreateGroup ([tetrateio.api.tsb.security.v2.CreateSecurityGroupRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-createsecuritygrouprequest)) returns ([tetrateio.api.tsb.security.v2.Group](../../../tsb/security/v2/security_group#tetrateio-api-tsb-security-v2-group))

</PanelContentCode>

**Requires** CREATE

Create a new security group in the given workspace.

Groups will by default configure all the namespaces owned by their workspace, unless
explicitly configured. If a specific set of namespaces is set for the group, it must be a
subset of the namespaces defined by its workspace.

</PanelContent>

### GetGroup

<PanelContent>
<PanelContentCode>

rpc GetGroup ([tetrateio.api.tsb.security.v2.GetSecurityGroupRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-getsecuritygrouprequest)) returns ([tetrateio.api.tsb.security.v2.Group](../../../tsb/security/v2/security_group#tetrateio-api-tsb-security-v2-group))

</PanelContentCode>

**Requires** READ

Get the details of the given security group.

</PanelContent>

### UpdateGroup

<PanelContent>
<PanelContentCode>

rpc UpdateGroup ([tetrateio.api.tsb.security.v2.Group](../../../tsb/security/v2/security_group#tetrateio-api-tsb-security-v2-group)) returns ([tetrateio.api.tsb.security.v2.Group](../../../tsb/security/v2/security_group#tetrateio-api-tsb-security-v2-group))

</PanelContentCode>

**Requires** WRITE

Modify a security group.

</PanelContent>

### ListGroups

<PanelContent>
<PanelContentCode>

rpc ListGroups ([tetrateio.api.tsb.security.v2.ListSecurityGroupsRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-listsecuritygroupsrequest)) returns ([tetrateio.api.tsb.security.v2.ListSecurityGroupsResponse](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-listsecuritygroupsresponse))

</PanelContentCode>



List all security groups in the given workspace.

</PanelContent>

### DeleteGroup

<PanelContent>
<PanelContentCode>

rpc DeleteGroup ([tetrateio.api.tsb.security.v2.DeleteSecurityGroupRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-deletesecuritygrouprequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given security group.
Note that deleting resources in TSB is a recursive operation. Deleting a security group will
delete all configuration objects that exist in it.

</PanelContent>

### CreateSettings

<PanelContent>
<PanelContentCode>

rpc CreateSettings ([tetrateio.api.tsb.security.v2.CreateSecuritySettingsRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-createsecuritysettingsrequest)) returns ([tetrateio.api.tsb.security.v2.SecuritySetting](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting))

</PanelContentCode>

**Requires** CreateSecuritySetting

Create a security settings object in the security group.

</PanelContent>

### GetSettings

<PanelContent>
<PanelContentCode>

rpc GetSettings ([tetrateio.api.tsb.security.v2.GetSecuritySettingsRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-getsecuritysettingsrequest)) returns ([tetrateio.api.tsb.security.v2.SecuritySetting](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting))

</PanelContentCode>

**Requires** ReadSecuritySetting

Get the details of the given security settings object.

</PanelContent>

### UpdateSettings

<PanelContent>
<PanelContentCode>

rpc UpdateSettings ([tetrateio.api.tsb.security.v2.SecuritySetting](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting)) returns ([tetrateio.api.tsb.security.v2.SecuritySetting](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting))

</PanelContentCode>

**Requires** WriteSecuritySetting

Modify the given security settings object.

</PanelContent>

### ListSettings

<PanelContent>
<PanelContentCode>

rpc ListSettings ([tetrateio.api.tsb.security.v2.ListSecuritySettingsRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-listsecuritysettingsrequest)) returns ([tetrateio.api.tsb.security.v2.ListSecuritySettingsResponse](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-listsecuritysettingsresponse))

</PanelContentCode>



List all security settings objects that have been attached to the security group.

</PanelContent>

### DeleteSettings

<PanelContent>
<PanelContentCode>

rpc DeleteSettings ([tetrateio.api.tsb.security.v2.DeleteSecuritySettingsRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-deletesecuritysettingsrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DeleteSecuritySetting

Delete the given security settings from the group.

</PanelContent>

### CreateServiceSecuritySettings

<PanelContent>
<PanelContentCode>

rpc CreateServiceSecuritySettings ([tetrateio.api.tsb.security.v2.CreateServiceSecuritySettingsRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-createservicesecuritysettingsrequest)) returns ([tetrateio.api.tsb.security.v2.ServiceSecuritySetting](../../../tsb/security/v2/service_security_setting#tetrateio-api-tsb-security-v2-servicesecuritysetting))

</PanelContentCode>

**Requires** CREATE

Create a service security settings object in the security group.

</PanelContent>

### GetServiceSecuritySettings

<PanelContent>
<PanelContentCode>

rpc GetServiceSecuritySettings ([tetrateio.api.tsb.security.v2.GetServiceSecuritySettingsRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-getservicesecuritysettingsrequest)) returns ([tetrateio.api.tsb.security.v2.ServiceSecuritySetting](../../../tsb/security/v2/service_security_setting#tetrateio-api-tsb-security-v2-servicesecuritysetting))

</PanelContentCode>

**Requires** READ

Get the details of the given service security settings object.

</PanelContent>

### UpdateServiceSecuritySettings

<PanelContent>
<PanelContentCode>

rpc UpdateServiceSecuritySettings ([tetrateio.api.tsb.security.v2.ServiceSecuritySetting](../../../tsb/security/v2/service_security_setting#tetrateio-api-tsb-security-v2-servicesecuritysetting)) returns ([tetrateio.api.tsb.security.v2.ServiceSecuritySetting](../../../tsb/security/v2/service_security_setting#tetrateio-api-tsb-security-v2-servicesecuritysetting))

</PanelContentCode>

**Requires** WRITE

Modify the given service security settings object.

</PanelContent>

### ListServiceSecuritySettings

<PanelContent>
<PanelContentCode>

rpc ListServiceSecuritySettings ([tetrateio.api.tsb.security.v2.ListServiceSecuritySettingsRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-listservicesecuritysettingsrequest)) returns ([tetrateio.api.tsb.security.v2.ListServiceSecuritySettingsResponse](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-listservicesecuritysettingsresponse))

</PanelContentCode>



List all service security settings objects that have been attached to the security group.

</PanelContent>

### DeleteServiceSecuritySettings

<PanelContent>
<PanelContentCode>

rpc DeleteServiceSecuritySettings ([tetrateio.api.tsb.security.v2.DeleteServiceSecuritySettingsRequest](../../../tsb/security/v2/security_service#tetrateio-api-tsb-security-v2-deleteservicesecuritysettingsrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given service security settings from the group.

</PanelContent>






## CreateSecurityGroupRequest {#tetrateio-api-tsb-security-v2-createsecuritygrouprequest}

Request to create a Security Group.



  
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

[tetrateio.api.tsb.security.v2.Group](../../../tsb/security/v2/security_group#tetrateio-api-tsb-security-v2-group) <br/> _REQUIRED_ <br/> Details of the Group to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateSecuritySettingsRequest {#tetrateio-api-tsb-security-v2-createsecuritysettingsrequest}

Request to create a Security Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Security Settings will be created.

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

[tetrateio.api.tsb.security.v2.SecuritySetting](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting) <br/> _REQUIRED_ <br/> Details of the Security Settings to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateServiceSecuritySettingsRequest {#tetrateio-api-tsb-security-v2-createservicesecuritysettingsrequest}

Request to create a Service Security Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Service Security Settings will be created.

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

[tetrateio.api.tsb.security.v2.ServiceSecuritySetting](../../../tsb/security/v2/service_security_setting#tetrateio-api-tsb-security-v2-servicesecuritysetting) <br/> _REQUIRED_ <br/> Details of the Service Security Settings to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteSecurityGroupRequest {#tetrateio-api-tsb-security-v2-deletesecuritygrouprequest}

Request to delete a Security Group.



  
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
  


## DeleteSecuritySettingsRequest {#tetrateio-api-tsb-security-v2-deletesecuritysettingsrequest}

Request to delete a Security Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Security Settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteServiceSecuritySettingsRequest {#tetrateio-api-tsb-security-v2-deleteservicesecuritysettingsrequest}

Request to delete a Service Security Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Service Security Settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetSecurityGroupRequest {#tetrateio-api-tsb-security-v2-getsecuritygrouprequest}

Request to retrieve a Security Group.



  
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
  


## GetSecuritySettingsRequest {#tetrateio-api-tsb-security-v2-getsecuritysettingsrequest}

Request to retrieve a Security Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Security Settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetServiceSecuritySettingsRequest {#tetrateio-api-tsb-security-v2-getservicesecuritysettingsrequest}

Request to retrieve a Service Security Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Service Security Settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListSecurityGroupsRequest {#tetrateio-api-tsb-security-v2-listsecuritygroupsrequest}

Request to list Security Groups.



  
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
  


## ListSecurityGroupsResponse {#tetrateio-api-tsb-security-v2-listsecuritygroupsresponse}

List of all security groups in the workspace.



  
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

List of [tetrateio.api.tsb.security.v2.Group](../../../tsb/security/v2/security_group#tetrateio-api-tsb-security-v2-group) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListSecuritySettingsRequest {#tetrateio-api-tsb-security-v2-listsecuritysettingsrequest}

Request to list Security Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Security Settings from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListSecuritySettingsResponse {#tetrateio-api-tsb-security-v2-listsecuritysettingsresponse}

List of all security settings objects attached to the group.



  
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

List of [tetrateio.api.tsb.security.v2.SecuritySetting](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListServiceSecuritySettingsRequest {#tetrateio-api-tsb-security-v2-listservicesecuritysettingsrequest}

Request to list Service Security Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Service Security Settings from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListServiceSecuritySettingsResponse {#tetrateio-api-tsb-security-v2-listservicesecuritysettingsresponse}

List of all Service Security Settings objects attached to the group.



  
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

List of [tetrateio.api.tsb.security.v2.ServiceSecuritySetting](../../../tsb/security/v2/service_security_setting#tetrateio-api-tsb-security-v2-servicesecuritysetting) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



