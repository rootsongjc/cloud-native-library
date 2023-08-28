---
title: Info
description: Provide information about the Service bridge platform.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Provide information about the Service bridge platform.


## Info {#tetrateio-api-tsb-v2-info}

The Info service provides information about the service Bridge platform.


### GetVersion

<PanelContent>
<PanelContentCode>

rpc GetVersion ([tetrateio.api.tsb.v2.GetVersionRequest](../../tsb/v2/info#tetrateio-api-tsb-v2-getversionrequest)) returns ([tetrateio.api.tsb.v2.Version](../../tsb/v2/info#tetrateio-api-tsb-v2-version))

</PanelContentCode>



GetVersion returns the version of the TSB binary

</PanelContent>

### GetCurrentUser

<PanelContent>
<PanelContentCode>

rpc GetCurrentUser ([tetrateio.api.tsb.v2.GetCurrentUserRequest](../../tsb/v2/info#tetrateio-api-tsb-v2-getcurrentuserrequest)) returns ([tetrateio.api.tsb.v2.CurrentUser](../../tsb/v2/info#tetrateio-api-tsb-v2-currentuser))

</PanelContentCode>



GetCurrentUser returns the information of the user or service account that made the request.

</PanelContent>






## CurrentUser {#tetrateio-api-tsb-v2-currentuser}

CurrentUser contains the information of the user or service account that made the request.



  
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


loginName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> login_name is the name used in the login credentials.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


type

</td>

<td>

[tetrateio.api.tsb.v2.CurrentUser.Type](../../tsb/v2/info#tetrateio-api-tsb-v2-currentuser-type) <br/> The type of the current user, e.g. USER or SERVICE_ACCOUNT

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


sourceType

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Indicates the Identity Provider where the user has been 
synchronized from. It will be empty for service accounts.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The email for the user where alerts and other notifications will be sent.
It will be empty for service accounts.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The display name is the user friendly name for the resource.
It will be empty for service accounts.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


firstName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The first name is the first name of the user.
It will be empty for service accounts.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


lastName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The last name of the user, if any.
It will be empty for service accounts.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


organization

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The name of the organization the user belongs to

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Version {#tetrateio-api-tsb-v2-version}

The version of the Service Bridge platform.



  
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


version

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> version is the TSB binary version

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




### Type {#tetrateio-api-tsb-v2-currentuser-type}




<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


USER

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


SERVICE_ACCOUNT

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
<tr>
<td>


INTERNAL

</td>

<td>

2

</td>

<td>



</td>
</tr>
    
</table>
  


