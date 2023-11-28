---
title: Workspace Service
description: Service to manage TSB workspaces.
---

<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage TSB workspaces.


## Workspaces {#tetrateio-api-tsb-v2-workspaces}

The Workspaces service provides methods to manage the workspaces for a given tenant.

Workspaces are the main containers for the different configuration resources available in TSB,
and provide infrastructure isolation constraints.


### CreateWorkspace

<PanelContent>
<PanelContentCode>

rpc CreateWorkspace ([tetrateio.api.tsb.v2.CreateWorkspaceRequest](../../tsb/v2/workspace_service#tetrateio-api-tsb-v2-createworkspacerequest)) returns ([tetrateio.api.tsb.v2.Workspace](../../tsb/v2/workspace#tetrateio-api-tsb-v2-workspace))

</PanelContentCode>

**Requires** CREATE

Create a new workspace.
The workspace will own exclusively the namespaces configured in the namespaces
selector for the workspace.

</PanelContent>

### GetWorkspace

<PanelContent>
<PanelContentCode>

rpc GetWorkspace ([tetrateio.api.tsb.v2.GetWorkspaceRequest](../../tsb/v2/workspace_service#tetrateio-api-tsb-v2-getworkspacerequest)) returns ([tetrateio.api.tsb.v2.Workspace](../../tsb/v2/workspace#tetrateio-api-tsb-v2-workspace))

</PanelContentCode>

**Requires** READ

Get the details of an existing workspace

</PanelContent>

### UpdateWorkspace

<PanelContent>
<PanelContentCode>

rpc UpdateWorkspace ([tetrateio.api.tsb.v2.Workspace](../../tsb/v2/workspace#tetrateio-api-tsb-v2-workspace)) returns ([tetrateio.api.tsb.v2.Workspace](../../tsb/v2/workspace#tetrateio-api-tsb-v2-workspace))

</PanelContentCode>

**Requires** WRITE

Modify an existing workspace

</PanelContent>

### ListWorkspaces

<PanelContent>
<PanelContentCode>

rpc ListWorkspaces ([tetrateio.api.tsb.v2.ListWorkspacesRequest](../../tsb/v2/workspace_service#tetrateio-api-tsb-v2-listworkspacesrequest)) returns ([tetrateio.api.tsb.v2.ListWorkspacesResponse](../../tsb/v2/workspace_service#tetrateio-api-tsb-v2-listworkspacesresponse))

</PanelContentCode>



List all existing workspaces for the given tenant.

</PanelContent>

### DeleteWorkspace

<PanelContent>
<PanelContentCode>

rpc DeleteWorkspace ([tetrateio.api.tsb.v2.DeleteWorkspaceRequest](../../tsb/v2/workspace_service#tetrateio-api-tsb-v2-deleteworkspacerequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete an existing workspace.
Note that deleting resources in TSB is a recursive operation. Deleting a workspace will delete all
groups and configuration objects that exist in it.

</PanelContent>

### CreateSettings

<PanelContent>
<PanelContentCode>

rpc CreateSettings ([tetrateio.api.tsb.v2.CreateWorkspaceSettingsRequest](../../tsb/v2/workspace_service#tetrateio-api-tsb-v2-createworkspacesettingsrequest)) returns ([tetrateio.api.tsb.v2.WorkspaceSetting](../../tsb/v2/workspace_setting#tetrateio-api-tsb-v2-workspacesetting))

</PanelContentCode>

**Requires** CreateWorkspaceSetting

Create default settings for a workspace.
Default settings will apply to the services owned by the workspace, unless more
specific settings are provided at the group level.

</PanelContent>

### GetSettings

<PanelContent>
<PanelContentCode>

rpc GetSettings ([tetrateio.api.tsb.v2.GetWorkspaceSettingsRequest](../../tsb/v2/workspace_service#tetrateio-api-tsb-v2-getworkspacesettingsrequest)) returns ([tetrateio.api.tsb.v2.WorkspaceSetting](../../tsb/v2/workspace_setting#tetrateio-api-tsb-v2-workspacesetting))

</PanelContentCode>

**Requires** ReadWorkspaceSetting

Get the details of a settings object for the given workspace.

</PanelContent>

### UpdateSettings

<PanelContent>
<PanelContentCode>

rpc UpdateSettings ([tetrateio.api.tsb.v2.WorkspaceSetting](../../tsb/v2/workspace_setting#tetrateio-api-tsb-v2-workspacesetting)) returns ([tetrateio.api.tsb.v2.WorkspaceSetting](../../tsb/v2/workspace_setting#tetrateio-api-tsb-v2-workspacesetting))

</PanelContentCode>

**Requires** WriteWorkspaceSetting

Modify the given workspace settings.

</PanelContent>

### ListSettings

<PanelContent>
<PanelContentCode>

rpc ListSettings ([tetrateio.api.tsb.v2.ListWorkspaceSettingsRequest](../../tsb/v2/workspace_service#tetrateio-api-tsb-v2-listworkspacesettingsrequest)) returns ([tetrateio.api.tsb.v2.ListWorkspaceSettingsResponse](../../tsb/v2/workspace_service#tetrateio-api-tsb-v2-listworkspacesettingsresponse))

</PanelContentCode>



List all settings available for the given workspace.

</PanelContent>

### DeleteSettings

<PanelContent>
<PanelContentCode>

rpc DeleteSettings ([tetrateio.api.tsb.v2.DeleteWorkspaceSettingsRequest](../../tsb/v2/workspace_service#tetrateio-api-tsb-v2-deleteworkspacesettingsrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DeleteWorkspaceSetting

Delete the given workspace settings.

</PanelContent>






## CreateWorkspaceRequest {#tetrateio-api-tsb-v2-createworkspacerequest}

Request to create a Workspace.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Workspace will be created.

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


workspace

</td>

<td>

[tetrateio.api.tsb.v2.Workspace](../../tsb/v2/workspace#tetrateio-api-tsb-v2-workspace) <br/> _REQUIRED_ <br/> Details of the Workspace to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## CreateWorkspaceSettingsRequest {#tetrateio-api-tsb-v2-createworkspacesettingsrequest}

Request to create a Workspace Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Workspace Settings will be created.

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

[tetrateio.api.tsb.v2.WorkspaceSetting](../../tsb/v2/workspace_setting#tetrateio-api-tsb-v2-workspacesetting) <br/> _REQUIRED_ <br/> Details of the Workspace Settings to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteWorkspaceRequest {#tetrateio-api-tsb-v2-deleteworkspacerequest}

Request to delete a Workspace.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Workspace.

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
  


## DeleteWorkspaceSettingsRequest {#tetrateio-api-tsb-v2-deleteworkspacesettingsrequest}

Request to delete a Workspace Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Workspace Settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetWorkspaceRequest {#tetrateio-api-tsb-v2-getworkspacerequest}

Request to retrieve a Workspace.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Workspace.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetWorkspaceSettingsRequest {#tetrateio-api-tsb-v2-getworkspacesettingsrequest}

Request to retrieve a Workspace Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Workspace Settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListWorkspaceSettingsRequest {#tetrateio-api-tsb-v2-listworkspacesettingsrequest}

Request to list Workspace Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Workspace Settings from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListWorkspaceSettingsResponse {#tetrateio-api-tsb-v2-listworkspacesettingsresponse}

The existing settings objects for the given workspace.



  
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

List of [tetrateio.api.tsb.v2.WorkspaceSetting](../../tsb/v2/workspace_setting#tetrateio-api-tsb-v2-workspacesetting) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListWorkspacesRequest {#tetrateio-api-tsb-v2-listworkspacesrequest}

Request to list Workspaces.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Workspaces from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListWorkspacesResponse {#tetrateio-api-tsb-v2-listworkspacesresponse}

The existing workspaces for the given tenant.



  
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


workspaces

</td>

<td>

List of [tetrateio.api.tsb.v2.Workspace](../../tsb/v2/workspace#tetrateio-api-tsb-v2-workspace) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



