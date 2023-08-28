---
title: WasmExtension Service
description: Service to manage WASM extensions.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage WASM extensions.


## WasmExtensions {#tetrateio-api-tsb-extension-v2-wasmextensions}

The WasmExtension service provides methods to manage the extensions inside an Organization.
WasmExtensions are created inside TSB and assigned later to SecuritySettings and IngressGateways.


### GetWasmExtension

<PanelContent>
<PanelContentCode>

rpc GetWasmExtension ([tetrateio.api.tsb.extension.v2.GetWasmExtensionRequest](../../../tsb/extension/v2/wasm_service#tetrateio-api-tsb-extension-v2-getwasmextensionrequest)) returns ([tetrateio.api.tsb.extension.v2.WasmExtension](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-wasmextension))

</PanelContentCode>

**Requires** READ

Get a WASM extension

</PanelContent>

### ListWasmExtension

<PanelContent>
<PanelContentCode>

rpc ListWasmExtension ([tetrateio.api.tsb.extension.v2.ListWasmExtensionRequest](../../../tsb/extension/v2/wasm_service#tetrateio-api-tsb-extension-v2-listwasmextensionrequest)) returns ([tetrateio.api.tsb.extension.v2.ListWasmExtensionResponse](../../../tsb/extension/v2/wasm_service#tetrateio-api-tsb-extension-v2-listwasmextensionresponse))

</PanelContentCode>



List the WASM extensions that are defined for the Organization.

</PanelContent>

### CreateWasmExtension

<PanelContent>
<PanelContentCode>

rpc CreateWasmExtension ([tetrateio.api.tsb.extension.v2.CreateWasmExtensionRequest](../../../tsb/extension/v2/wasm_service#tetrateio-api-tsb-extension-v2-createwasmextensionrequest)) returns ([tetrateio.api.tsb.extension.v2.WasmExtension](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-wasmextension))

</PanelContentCode>

**Requires** CREATE

Creates a new WasmExtension object in TSB. This is needed to let the extensions run.
Once a WasmExtension has been created, it can be assigned to IngressGateway and SecuritySetting.
This method returns the created extension.

</PanelContent>

### UpdateWasmExtension

<PanelContent>
<PanelContentCode>

rpc UpdateWasmExtension ([tetrateio.api.tsb.extension.v2.WasmExtension](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-wasmextension)) returns ([tetrateio.api.tsb.extension.v2.WasmExtension](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-wasmextension))

</PanelContentCode>

**Requires** WRITE

Modify an existing WasmExtension.
When modifying the details of an extension in use, such as the image property, enabled flag, phase,
or default configuration, a redeploy or reconfiguration of the extension may be triggered, affecting live
traffic in all those places that reference the extension.
Similarly, changes to the allowed_in property may trigger the removal of the extension from all places where
the extension was in use that are not allowed to use it anymore, affecting live traffic on the
relevant namespaces as well.

</PanelContent>

### DeleteWasmExtension

<PanelContent>
<PanelContentCode>

rpc DeleteWasmExtension ([tetrateio.api.tsb.extension.v2.DeleteWasmExtensionRequest](../../../tsb/extension/v2/wasm_service#tetrateio-api-tsb-extension-v2-deletewasmextensionrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete a WasmExtension.
Note that deleting a WasmExtension will delete the extension itself, and also its assignments to IngressGateway and SecuritySetting.

</PanelContent>






## CreateWasmExtensionRequest {#tetrateio-api-tsb-extension-v2-createwasmextensionrequest}

Request to create a WasmExtension and make it available to be assigned to IngressGateway and SecuritySetting.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the extension will be created. This is the FQN of the organization.

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


wasmExtension

</td>

<td>

[tetrateio.api.tsb.extension.v2.WasmExtension](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-wasmextension) <br/> _REQUIRED_ <br/> Details of the extension to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteWasmExtensionRequest {#tetrateio-api-tsb-extension-v2-deletewasmextensionrequest}

Request to delete a WasmExtension.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the WasmExtension.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetWasmExtensionRequest {#tetrateio-api-tsb-extension-v2-getwasmextensionrequest}

Request to retrieve a WASM extension.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the extension.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListWasmExtensionRequest {#tetrateio-api-tsb-extension-v2-listwasmextensionrequest}

Request to retrieve the list of WASM extensions for a given Organization.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the WasmExtension will be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListWasmExtensionResponse {#tetrateio-api-tsb-extension-v2-listwasmextensionresponse}

List of WASM Extensions.



  
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

List of [tetrateio.api.tsb.extension.v2.WasmExtension](../../../tsb/extension/v2/wasm_extension#tetrateio-api-tsb-extension-v2-wasmextension) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



