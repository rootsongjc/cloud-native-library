---
title: IAM (OAuth)
description: IAM APIs for authentication.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

IAM APIs for authentication.


## OAuth {#tetrateio-api-iam-v2-oauth}




### Token

<PanelContent>
<PanelContentCode>

rpc Token ([tetrateio.api.iam.v2.GrantRequest](../../iam/v2/oauth_service#tetrateio-api-iam-v2-grantrequest)) returns ([tetrateio.api.iam.v2.GrantResponse](../../iam/v2/oauth_service#tetrateio-api-iam-v2-grantresponse))

</PanelContentCode>



Grants tokens for a given grant type.

This is used by clients to obtain an access token by presenting required parameters for the requested grant type.
Current only "urn:ietf:params:oauth:grant-type:device_code" is supported.
When an error occurs, this will return a 4xx status code with an Error and ErrorMessage in the response.

</PanelContent>

### DeviceCode

<PanelContent>
<PanelContentCode>

rpc DeviceCode ([tetrateio.api.iam.v2.DeviceCodeRequest](../../iam/v2/oauth_service#tetrateio-api-iam-v2-devicecoderequest)) returns ([tetrateio.api.iam.v2.DeviceCodeResponse](../../iam/v2/oauth_service#tetrateio-api-iam-v2-devicecoderesponse))

</PanelContentCode>



Requests device codes that can be used with a token grant with grant type "urn:ietf:params:oauth:grant-type:device_code".
For additional information please refer to the Device Authorization Grant RFC
https://datatracker.ietf.org/doc/html/rfc8628

</PanelContent>






## DeviceCodeResponse {#tetrateio-api-iam-v2-devicecoderesponse}

Response with device codes for use with the Device Authorization flow.
For additional information on the response parameters please refer to the Device Authorization Response section
of the RFC https://datatracker.ietf.org/doc/html/rfc8628#section-3.2



  
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


deviceCode

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Code that the device uses to poll for tokens

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


userCode

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Code the user enters in the verification URI

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


verificationUri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> URI where to enter the user code

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


interval

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Rate in which to poll the token endpoint with the device code

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


expiresIn

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Expiration time of the device code in seconds

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

[tetrateio.api.iam.v2.Error](../../iam/v2/oauth_service#tetrateio-api-iam-v2-error) <br/> Optional error code presented when an error or validation check failed.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


errorMessage

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Optional error message that contains more details about the error that occurred.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GrantRequest {#tetrateio-api-iam-v2-grantrequest}

Token grant request.



  
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


grantType

</td>

<td>

[tetrateio.api.iam.v2.GrantType](../../iam/v2/oauth_service#tetrateio-api-iam-v2-granttype) <br/> _REQUIRED_ <br/> Token grant type as specified in the OAuth2 specification.
Current supported grant types are "urn:ietf:params:oauth:grant-type:device_code" and "refresh_token"

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


deviceCode

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> Device code issued by the device authorization code endpoint when device code grant is used.
This field is required when using a device_code grant.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


refreshToken

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> Refresh token issued from a previous grant request.
This field is required when using a refresh_token grant.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


scope

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> List of requested scopes. This is a list that can include any of the scopes
that are allowed by the client configuration. For refresh_token grants, this list
may not include any scopes that were not part of the original token request.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


clientId

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> Client ID for which the token grant request is being made.
This is optional and when absent, TSB will use an appropriate client ID from configuration
for the grant type being request.
For a refresh grant type, this parameter may be required to ensure the appropriate client
configuration is used.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


resource

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> A URI that indicates the target service or resource where the client intends to use the requested token.
This is used with the token exchange grant and should be the URI of TSB.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


subjectToken

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> A token that represents the identity of the party on behalf of whom the request is being made.
This is used with the token exchange grant and should be either an ID Token or Access Token from the configured
offline token grant client.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


subjectTokenType

</td>

<td>

[tetrateio.api.iam.v2.TokenType](../../iam/v2/oauth_service#tetrateio-api-iam-v2-tokentype) <br/> _OPTIONAL_ <br/> An identifier that indicates the type of the security token in the "subject_token" parameter.
This is used with the token exchange grant.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GrantResponse {#tetrateio-api-iam-v2-grantresponse}

Token grant response.



  
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


accessToken

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Access token issued by the authorization server.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tokenType

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Access token type such as "bearer" or "mac".

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


expiresIn

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Expiration time of the access token in seconds.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


refreshToken

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Optional refresh token issued when the authorization server
and client are configured to use refresh tokens.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


clientId

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Optional client ID used during the grant process.
When present the client ID for subsequent refresh grant calls.
While not a standard field on an OAuth grant response, this helps remove ambiguity
when multiple OIDC configurations are present in TSB.

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

[tetrateio.api.iam.v2.Error](../../iam/v2/oauth_service#tetrateio-api-iam-v2-error) <br/> Optional error code presented when an error or validation check failed.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


errorMessage

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Optional error message that contains more details about the error that occurred.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




## Error {#tetrateio-api-iam-v2-error}

OAuth2 error codes


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


NO_ERROR

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


INVALID_REQUEST

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
<tr>
<td>


INVALID_CLIENT

</td>

<td>

2

</td>

<td>



</td>
</tr>
    
<tr>
<td>


INVALID_GRANT

</td>

<td>

3

</td>

<td>



</td>
</tr>
    
<tr>
<td>


UNAUTHORIZED_CLIENT

</td>

<td>

4

</td>

<td>



</td>
</tr>
    
<tr>
<td>


UNSUPPORTED_GRANT_TYPE

</td>

<td>

5

</td>

<td>



</td>
</tr>
    
<tr>
<td>


AUTHORIZATION_PENDING

</td>

<td>

6

</td>

<td>



</td>
</tr>
    
<tr>
<td>


SLOW_DOWN

</td>

<td>

7

</td>

<td>



</td>
</tr>
    
<tr>
<td>


ACCESS_DENIED

</td>

<td>

8

</td>

<td>



</td>
</tr>
    
<tr>
<td>


EXPIRED_TOKEN

</td>

<td>

9

</td>

<td>



</td>
</tr>
    
<tr>
<td>


SERVER_ERROR

</td>

<td>

10

</td>

<td>



</td>
</tr>
    
</table>
  



## GrantType {#tetrateio-api-iam-v2-granttype}

OAuth2 grant types that are currently supported.


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


UNSPECIFIED

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


REFRESH_TOKEN

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
<tr>
<td>


DEVICE_CODE_URN

</td>

<td>

2

</td>

<td>



</td>
</tr>
    
<tr>
<td>


CLIENT_CREDENTIALS

</td>

<td>

3

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TOKEN_EXCHANGE

</td>

<td>

4

</td>

<td>



</td>
</tr>
    
</table>
  



## TokenType {#tetrateio-api-iam-v2-tokentype}




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


TOKEN_TYPE_UNSPECIFIED

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TOKEN_TYPE_ACCESS_TOKEN

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TOKEN_TYPE_REFRESH_TOKEN

</td>

<td>

2

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TOKEN_TYPE_ID_TOKEN

</td>

<td>

3

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TOKEN_TYPE_JWT

</td>

<td>

4

</td>

<td>



</td>
</tr>
    
</table>
  


