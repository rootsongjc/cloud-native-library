---
title: Tenant Service
description: Service to manage TSB tenants.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage TSB tenants.


## Tenants {#tetrateio-api-tsb-v2-tenants}

The Tenant service can be used to manage the tenants in TSB.
Tenants can be seen as organization units and line of business that have a set of
resources. Every resource in TSB belongs to a tenant, and users can be assigned to
tenants to get access to those resources (such as workspaces, traffic settings, etc).
This service provides methods to manage the tenants that are available in the platform.


### CreateTenant

<PanelContent>
<PanelContentCode>

rpc CreateTenant ([tetrateio.api.tsb.v2.CreateTenantRequest](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-createtenantrequest)) returns ([tetrateio.api.tsb.v2.Tenant](../../tsb/v2/tenant#tetrateio-api-tsb-v2-tenant))

</PanelContentCode>

**Requires** CREATE

Create a new tenant in the platform that will be the home for a set of resources.

</PanelContent>

### GetTenant

<PanelContent>
<PanelContentCode>

rpc GetTenant ([tetrateio.api.tsb.v2.GetTenantRequest](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-gettenantrequest)) returns ([tetrateio.api.tsb.v2.Tenant](../../tsb/v2/tenant#tetrateio-api-tsb-v2-tenant))

</PanelContentCode>

**Requires** READ

Get the details of an existing tenant.

</PanelContent>

### UpdateTenant

<PanelContent>
<PanelContentCode>

rpc UpdateTenant ([tetrateio.api.tsb.v2.Tenant](../../tsb/v2/tenant#tetrateio-api-tsb-v2-tenant)) returns ([tetrateio.api.tsb.v2.Tenant](../../tsb/v2/tenant#tetrateio-api-tsb-v2-tenant))

</PanelContentCode>

**Requires** WRITE

Modify the details of the given tenant.

</PanelContent>

### ListTenants

<PanelContent>
<PanelContentCode>

rpc ListTenants ([tetrateio.api.tsb.v2.ListTenantsRequest](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-listtenantsrequest)) returns ([tetrateio.api.tsb.v2.ListTenantsResponse](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-listtenantsresponse))

</PanelContentCode>



List all tenants that are available.

</PanelContent>

### DeleteTenant

<PanelContent>
<PanelContentCode>

rpc DeleteTenant ([tetrateio.api.tsb.v2.DeleteTenantRequest](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-deletetenantrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete a tenant from the platform.
Deleting a tenant will recursively delete all resources attached to the tenant, so use with
caution.
It will delete all workspaces and all settings that have been created in that tenant, so this
operation should be done carefully, when it's safe to do so.

</PanelContent>

### CreateSetting

<PanelContent>
<PanelContentCode>

rpc CreateSetting ([tetrateio.api.tsb.v2.CreateTenantSettingRequest](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-createtenantsettingrequest)) returns ([tetrateio.api.tsb.v2.TenantSetting](../../tsb/v2/tenant_setting#tetrateio-api-tsb-v2-tenantsetting))

</PanelContentCode>

**Requires** CreateTenantSetting

Create a settings object for the given tenant.

</PanelContent>

### GetSetting

<PanelContent>
<PanelContentCode>

rpc GetSetting ([tetrateio.api.tsb.v2.GetTenantSettingRequest](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-gettenantsettingrequest)) returns ([tetrateio.api.tsb.v2.TenantSetting](../../tsb/v2/tenant_setting#tetrateio-api-tsb-v2-tenantsetting))

</PanelContentCode>

**Requires** ReadTenantSetting

Get the details for the given settings object.

</PanelContent>

### UpdateSetting

<PanelContent>
<PanelContentCode>

rpc UpdateSetting ([tetrateio.api.tsb.v2.TenantSetting](../../tsb/v2/tenant_setting#tetrateio-api-tsb-v2-tenantsetting)) returns ([tetrateio.api.tsb.v2.TenantSetting](../../tsb/v2/tenant_setting#tetrateio-api-tsb-v2-tenantsetting))

</PanelContentCode>

**Requires** WriteTenantSetting

Modify the given settings in the given tenant.

</PanelContent>

### ListSettings

<PanelContent>
<PanelContentCode>

rpc ListSettings ([tetrateio.api.tsb.v2.ListTenantSettingsRequest](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-listtenantsettingsrequest)) returns ([tetrateio.api.tsb.v2.ListTenantSettingsResponse](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-listtenantsettingsresponse))

</PanelContentCode>



List all the settings objects that have made available to the given tenant.

</PanelContent>

### ListWasmExtensions

<PanelContent>
<PanelContentCode>

rpc ListWasmExtensions ([tetrateio.api.tsb.v2.ListTenantExtensionsRequest](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-listtenantextensionsrequest)) returns ([tetrateio.api.tsb.v2.ListTenantExtensionsResponse](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-listtenantextensionsresponse))

</PanelContentCode>

**Requires** ReadWasmExtension

List all the WASM extensions that have been attached to the given tenant.

</PanelContent>

### DeleteSetting

<PanelContent>
<PanelContentCode>

rpc DeleteSetting ([tetrateio.api.tsb.v2.DeleteTenantSettingRequest](../../tsb/v2/tenant_service#tetrateio-api-tsb-v2-deletetenantsettingrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DeleteTenantSetting

Delete the given settings object from the tenant.

</PanelContent>






## CreateTenantRequest {#tetrateio-api-tsb-v2-createtenantrequest}

Request to create a tenant.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Parent resource where the Tenant will be created.
$only_beta

</td>

<td>

&ndash;

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


tenant

</td>

<td>

[tetrateio.api.tsb.v2.Tenant](../../tsb/v2/tenant#tetrateio-api-tsb-v2-tenant) <br/> _REQUIRED_ <br/> Details of the tenant to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateTenantSettingRequest {#tetrateio-api-tsb-v2-createtenantsettingrequest}

Request to create a Tenant Setting.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Tenant Setting will be created.

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


setting

</td>

<td>

[tetrateio.api.tsb.v2.TenantSetting](../../tsb/v2/tenant_setting#tetrateio-api-tsb-v2-tenantsetting) <br/> _REQUIRED_ <br/> Details of the Tenant Setting to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteTenantRequest {#tetrateio-api-tsb-v2-deletetenantrequest}

Request to delete a tenant.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the tenant.

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
  


## DeleteTenantSettingRequest {#tetrateio-api-tsb-v2-deletetenantsettingrequest}

Request to delete a Tenant Setting.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Tenant Setting.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetTenantRequest {#tetrateio-api-tsb-v2-gettenantrequest}

Request to retrieve a tenant.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the tenant.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetTenantSettingRequest {#tetrateio-api-tsb-v2-gettenantsettingrequest}

Request to retrieve a Tenant Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Tenant Setting.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListTenantExtensionsRequest {#tetrateio-api-tsb-v2-listtenantextensionsrequest}

Request to list Tenant extensions.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Tenant Extensions from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListTenantExtensionsResponse {#tetrateio-api-tsb-v2-listtenantextensionsresponse}

List of all existing WasmExtensions objects assigned to the Tenant.



  
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


extensions

</td>

<td>

List of [tetrateio.api.tsb.extension.v2.WasmExtension](../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-wasmextension) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListTenantSettingsRequest {#tetrateio-api-tsb-v2-listtenantsettingsrequest}

Request to list Tenant Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Tenant Settings from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListTenantSettingsResponse {#tetrateio-api-tsb-v2-listtenantsettingsresponse}

List of all existing Tenant settings objects in the Tenant.



  
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

List of [tetrateio.api.tsb.v2.TenantSetting](../../tsb/v2/tenant_setting#tetrateio-api-tsb-v2-tenantsetting) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListTenantsRequest {#tetrateio-api-tsb-v2-listtenantsrequest}

Request to list tenants.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Parent resource to list Tenants from.
$only_beta

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListTenantsResponse {#tetrateio-api-tsb-v2-listtenantsresponse}

List of available tenants.



  
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


tenants

</td>

<td>

List of [tetrateio.api.tsb.v2.Tenant](../../tsb/v2/tenant#tetrateio-api-tsb-v2-tenant) <br/> The list of available tenants.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



