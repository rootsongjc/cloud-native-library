---
title: IAM (OIDC)
description: IAM APIs for authentication.
---

<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

IAM APIs for authentication.


## OIDC {#tetrateio-api-iam-v2-oidc}

The IAM OIDC service is a service used with Open ID Connect provider integrations.


### Callback

<PanelContent>
<PanelContentCode>

rpc Callback ([tetrateio.api.iam.v2.CallbackRequest](../../iam/v2/oidc_service#tetrateio-api-iam-v2-callbackrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>



Callback endpoint for OAuth2 Authorization Code grant flows as part of the OIDC spec.

</PanelContent>

### Login

<PanelContent>
<PanelContentCode>

rpc Login ([tetrateio.api.iam.v2.LoginRequest](../../iam/v2/oidc_service#tetrateio-api-iam-v2-loginrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>



Login endpoint to start an OIDC Authentication flow.

</PanelContent>






## CallbackRequest {#tetrateio-api-iam-v2-callbackrequest}

Request with parameters for an OAuth2 Authorization Code grant redirect.



  
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


code

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> result</sup>_ <br/> OAuth2 Authorization Code.
When present this indicates the user authorized the request. TSB will use this code
to acquire a token from the OIDC token endpoint and complete the login flow.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


error

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> result</sup>_ <br/> OAuth2 Error Code.
When present this indicates that either the authorization request has an error, the OIDC
provider encountered an error or the user failed to log in. When set TSB will display information
to the user indicating what went wrong.

Standard error codes can be found found here.
https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2.1
https://openid.net/specs/openid-connect-core-1_0.html#AuthError

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


state

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The state parameter sent to the OIDC provider on the authorization request.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


errorDescription

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> Optional error description sent by the OIDC provider when an error occurs.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


errorUri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> Optional error URI of a web page that includes additional information about the error.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## LoginRequest {#tetrateio-api-iam-v2-loginrequest}

Request to initiate an OIDC Authentication flow.



  
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


redirectUri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> URl where the user will be redirected when the authentication flow completes.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  

