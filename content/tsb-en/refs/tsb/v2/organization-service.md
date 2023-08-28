---
title: Organizations Service
description: Service to manage Organizations in TSB
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage Organizations in TSB


## Organizations {#tetrateio-api-tsb-v2-organizations}

The Organizations service exposes methods to manage the organizations that exist in TSB.
Organizations are the root of the Service Bridge object hierarchy. Each organization is
completely independent of the other with its own set of tenants, users, teams, clusters and 
workspaces.


### GetOrganization

<PanelContent>
<PanelContentCode>

rpc GetOrganization ([tetrateio.api.tsb.v2.GetOrganizationRequest](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-getorganizationrequest)) returns ([tetrateio.api.tsb.v2.Organization](../../tsb/v2/organization#tetrateio-api-tsb-v2-organization))

</PanelContentCode>

**Requires** READ

Get the details of an organization.

</PanelContent>

### SyncOrganization

<PanelContent>
<PanelContentCode>

rpc SyncOrganization ([tetrateio.api.tsb.v2.SyncOrganizationRequest](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-syncorganizationrequest)) returns ([tetrateio.api.tsb.v2.SyncOrganizationResponse](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-syncorganizationresponse))

</PanelContentCode>

**Requires** CreateUser, CreateTeam, DeleteUser, DeleteTeam, WriteTeam

SyncOrganization is used by processes that monitor the identity providers to synchronize
the users and teams with the ones in TSB.

This method will update the state of users and groups in the organization and will create, modify, and
delete groups according to the incoming request.
Sync requests are assumed to be a full-sync and to contain all existing users and groups. Existing TSB users and groups
that are not contained in a sync request will be deleted from the platform, as it will assume they have been removed
from the Identity Provider.

</PanelContent>

### CreateSettings

<PanelContent>
<PanelContentCode>

rpc CreateSettings ([tetrateio.api.tsb.v2.CreateOrganizationSettingsRequest](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-createorganizationsettingsrequest)) returns ([tetrateio.api.tsb.v2.OrganizationSetting](../../tsb/v2/organization_setting#tetrateio-api-tsb-v2-organizationsetting))

</PanelContentCode>

**Requires** CreateOrganizationSetting

Create a settings object for the given organization.

</PanelContent>

### GetSettings

<PanelContent>
<PanelContentCode>

rpc GetSettings ([tetrateio.api.tsb.v2.GetOrganizationSettingsRequest](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-getorganizationsettingsrequest)) returns ([tetrateio.api.tsb.v2.OrganizationSetting](../../tsb/v2/organization_setting#tetrateio-api-tsb-v2-organizationsetting))

</PanelContentCode>

**Requires** ReadOrganizationSetting

Get the details for the given settings object.

</PanelContent>

### UpdateSettings

<PanelContent>
<PanelContentCode>

rpc UpdateSettings ([tetrateio.api.tsb.v2.OrganizationSetting](../../tsb/v2/organization_setting#tetrateio-api-tsb-v2-organizationsetting)) returns ([tetrateio.api.tsb.v2.OrganizationSetting](../../tsb/v2/organization_setting#tetrateio-api-tsb-v2-organizationsetting))

</PanelContentCode>

**Requires** WriteOrganizationSetting

Modify the given settings in the given Organization.

</PanelContent>

### ListSettings

<PanelContent>
<PanelContentCode>

rpc ListSettings ([tetrateio.api.tsb.v2.ListOrganizationSettingsRequest](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-listorganizationsettingsrequest)) returns ([tetrateio.api.tsb.v2.ListOrganizationSettingsResponse](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-listorganizationsettingsresponse))

</PanelContentCode>



List all the settings objects that have been attached to the given Organization.

</PanelContent>

### DeleteSettings

<PanelContent>
<PanelContentCode>

rpc DeleteSettings ([tetrateio.api.tsb.v2.DeleteOrganizationSettingsRequest](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-deleteorganizationsettingsrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DeleteOrganizationSetting

Delete the given settings object from the Organization.

</PanelContent>






## CreateOrganizationSettingsRequest {#tetrateio-api-tsb-v2-createorganizationsettingsrequest}

Request to create a Organization Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Organization Settings will be created.

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

[tetrateio.api.tsb.v2.OrganizationSetting](../../tsb/v2/organization_setting#tetrateio-api-tsb-v2-organizationsetting) <br/> _REQUIRED_ <br/> Details of the Organization Settings to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteOrganizationSettingsRequest {#tetrateio-api-tsb-v2-deleteorganizationsettingsrequest}

Request to delete a Organization Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Organization Settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetOrganizationRequest {#tetrateio-api-tsb-v2-getorganizationrequest}

Request to retrieve a organization.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the organization.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetOrganizationSettingsRequest {#tetrateio-api-tsb-v2-getorganizationsettingsrequest}

Request to retrieve a Organization Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Organization Settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListOrganizationSettingsRequest {#tetrateio-api-tsb-v2-listorganizationsettingsrequest}

Request to list Organization Settings.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Organization Settings from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListOrganizationSettingsResponse {#tetrateio-api-tsb-v2-listorganizationsettingsresponse}

List of all existing Organization settings objects in the Organization group.



  
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

List of [tetrateio.api.tsb.v2.OrganizationSetting](../../tsb/v2/organization_setting#tetrateio-api-tsb-v2-organizationsetting) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## SyncOrganizationRequest {#tetrateio-api-tsb-v2-syncorganizationrequest}

Request to synchronize the users and teams in an organization from the configured identity provider.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Internal use only. Auto populated field.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


sourceType

</td>

<td>

[tetrateio.api.tsb.v2.SourceType](../../tsb/v2/team#tetrateio-api-tsb-v2-sourcetype) <br/> we cannot use the enum_only validation as protoc-gen-validate does not properly import
the enum package in the generated code, and it breaks :(

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


users

</td>

<td>

List of [tetrateio.api.tsb.v2.SyncOrganizationRequest.SyncUser](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-syncorganizationrequest-syncuser) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


teams

</td>

<td>

List of [tetrateio.api.tsb.v2.SyncOrganizationRequest.SyncTeam](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-syncorganizationrequest-syncteam) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### SyncTeam {#tetrateio-api-tsb-v2-syncorganizationrequest-syncteam}

Information of a team as synchronized from the team source. This differs slightly from a TSB
user since the fields here are raw info that does not have the context of the TSB hierarchy.



  
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


id

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Unique ID for the group.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


description

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Optional description for the group.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


memberUserIds

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of user ids for the users that belong to this group.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


memberGroupIds

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of group ids for the groups that are nested into this group.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


displayName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Friendly name to show the group in the different UIs.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### SyncUser {#tetrateio-api-tsb-v2-syncorganizationrequest-syncuser}

Information of a user as synchronized from the team source. This differs slightly from a TSB
user since the fields here are raw info that does not have the context of the TSB hierarchy.



  
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


id

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Unique ID for the user.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


description

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Optional description for the user.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


email

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> User's email

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


loginName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The login username for the user.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


displayName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Friendly name to show the user in the different UIs.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## SyncOrganizationResponse {#tetrateio-api-tsb-v2-syncorganizationresponse}

Result of the organization users and team synchronization.



  
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


failedUsers

</td>

<td>

[tetrateio.api.tsb.v2.SyncOrganizationResponse.FailedIds](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-syncorganizationresponse-failedids) <br/> List of users that were not synchronized

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


failedTeams

</td>

<td>

[tetrateio.api.tsb.v2.SyncOrganizationResponse.FailedIds](../../tsb/v2/organization_service#tetrateio-api-tsb-v2-syncorganizationresponse-failedids) <br/> List of groups that were not synchronized

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### FailedIds {#tetrateio-api-tsb-v2-syncorganizationresponse-failedids}





  
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


removal

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Users or groups that failed to be removed

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


addition

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Users or groups that failed to be created

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


update

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Users or groups that failed to be updated

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



