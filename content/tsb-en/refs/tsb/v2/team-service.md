---
title: Teams Service
description: Service to manage Users and Teams in TSB
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage Users and Teams in TSB


## Teams {#tetrateio-api-tsb-v2-teams}

The Teams service provides methods to manage the Users and Teams that exist in an
Organization.

Users and Teams are periodically synchronized from the Identity Provider (IdP)
configured for the Organization, but TSB allows creating local teams to provide
extended flexibility in how Users and Teams are grouped, and to provide a comprehensive
way of creating more fine-grained access control policies.


### GetUser

<PanelContent>
<PanelContentCode>

rpc GetUser ([tetrateio.api.tsb.v2.GetUserRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-getuserrequest)) returns ([tetrateio.api.tsb.v2.User](../../tsb/v2/team#tetrateio-api-tsb-v2-user))

</PanelContentCode>

**Requires** READ

Get the details of an existing user.

</PanelContent>

### ListUsers

<PanelContent>
<PanelContentCode>

rpc ListUsers ([tetrateio.api.tsb.v2.ListUsersRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-listusersrequest)) returns ([tetrateio.api.tsb.v2.ListUsersResponse](../../tsb/v2/team_service#tetrateio-api-tsb-v2-listusersresponse))

</PanelContentCode>



List existing users.

</PanelContent>

### GenerateTokens

<PanelContent>
<PanelContentCode>

rpc GenerateTokens ([tetrateio.api.tsb.v2.GenerateTokensRequest](../../tsb/v2/cluster_service#tetrateio-api-tsb-v2-generatetokensrequest)) returns ([tetrateio.api.tsb.v2.TokenResponse](../../tsb/v2/team_service#tetrateio-api-tsb-v2-tokenresponse))

</PanelContentCode>

**Requires** CreateUser

Deprecated. This method will be removed in future versions of TSB. Use Service Accounts instead.

Generate the tokens for a local user account so it can authenticate against management plane.
This method will return an error if the user account is not of type MANUAL. Credentials for
normal platform users must be configured in the corresponding Identity Provider.

</PanelContent>

### CreateTeam

<PanelContent>
<PanelContentCode>

rpc CreateTeam ([tetrateio.api.tsb.v2.CreateTeamRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-createteamrequest)) returns ([tetrateio.api.tsb.v2.Team](../../tsb/v2/team#tetrateio-api-tsb-v2-team))

</PanelContentCode>

**Requires** CREATE

Create a new team.

</PanelContent>

### GetTeam

<PanelContent>
<PanelContentCode>

rpc GetTeam ([tetrateio.api.tsb.v2.GetTeamRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-getteamrequest)) returns ([tetrateio.api.tsb.v2.Team](../../tsb/v2/team#tetrateio-api-tsb-v2-team))

</PanelContentCode>

**Requires** READ

Get the details of an existing team.

</PanelContent>

### UpdateTeam

<PanelContent>
<PanelContentCode>

rpc UpdateTeam ([tetrateio.api.tsb.v2.Team](../../tsb/v2/team#tetrateio-api-tsb-v2-team)) returns ([tetrateio.api.tsb.v2.Team](../../tsb/v2/team#tetrateio-api-tsb-v2-team))

</PanelContentCode>

**Requires** WRITE

Modify an existing team.

</PanelContent>

### ListTeams

<PanelContent>
<PanelContentCode>

rpc ListTeams ([tetrateio.api.tsb.v2.ListTeamsRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-listteamsrequest)) returns ([tetrateio.api.tsb.v2.ListTeamsResponse](../../tsb/v2/team_service#tetrateio-api-tsb-v2-listteamsresponse))

</PanelContentCode>



List all existing teams.

</PanelContent>

### DeleteTeam

<PanelContent>
<PanelContentCode>

rpc DeleteTeam ([tetrateio.api.tsb.v2.DeleteTeamRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-deleteteamrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete a team.
Note that deleting a team only deletes the team itself, but not its members.

</PanelContent>

### CreateServiceAccount

<PanelContent>
<PanelContentCode>

rpc CreateServiceAccount ([tetrateio.api.tsb.v2.CreateServiceAccountRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-createserviceaccountrequest)) returns ([tetrateio.api.tsb.v2.ServiceAccount](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount))

</PanelContentCode>

**Requires** CREATE

Create Service Account in TSB.
Service Accounts are local to TSB and can be used to access the platform using
JWT tokens signed with the Service Account's private key for authentication.

</PanelContent>

### GetServiceAccount

<PanelContent>
<PanelContentCode>

rpc GetServiceAccount ([tetrateio.api.tsb.v2.GetServiceAccountRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-getserviceaccountrequest)) returns ([tetrateio.api.tsb.v2.ServiceAccount](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount))

</PanelContentCode>

**Requires** READ

Get the details of an existing Service Account.

</PanelContent>

### GetServiceAccountJWKS

<PanelContent>
<PanelContentCode>

rpc GetServiceAccountJWKS ([tetrateio.api.tsb.v2.GetServiceAccountJWKSRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-getserviceaccountjwksrequest)) returns ([tetrateio.api.tsb.v2.JWKS](../../tsb/v2/team_service#tetrateio-api-tsb-v2-jwks))

</PanelContentCode>



Get all the public keys available in the service account and return them in a JWKS document.
See: https://datatracker.ietf.org/doc/html/rfc7517
Requests to this endpoint require read permissions on the service account, or a token signed
with one of the service account keys.

</PanelContent>

### UpdateServiceAccount

<PanelContent>
<PanelContentCode>

rpc UpdateServiceAccount ([tetrateio.api.tsb.v2.ServiceAccount](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount)) returns ([tetrateio.api.tsb.v2.ServiceAccount](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount))

</PanelContentCode>

**Requires** WRITE

Update the details of a service account.
Updating the details of the service account does not regenerate its keys.

</PanelContent>

### ListServiceAccounts

<PanelContent>
<PanelContentCode>

rpc ListServiceAccounts ([tetrateio.api.tsb.v2.ListServiceAccountsRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-listserviceaccountsrequest)) returns ([tetrateio.api.tsb.v2.ListServiceAccountsResponse](../../tsb/v2/team_service#tetrateio-api-tsb-v2-listserviceaccountsresponse))

</PanelContentCode>



List existing Service Accounts.

</PanelContent>

### DeleteServiceAccount

<PanelContent>
<PanelContentCode>

rpc DeleteServiceAccount ([tetrateio.api.tsb.v2.DeleteServiceAccountRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-deleteserviceaccountrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Delete the given Service account.

</PanelContent>

### GenerateServiceAccountKey

<PanelContent>
<PanelContentCode>

rpc GenerateServiceAccountKey ([tetrateio.api.tsb.v2.GenerateServiceAccountKeyRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-generateserviceaccountkeyrequest)) returns ([tetrateio.api.tsb.v2.ServiceAccount](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount))

</PanelContentCode>

**Requires** WriteServiceAccount

Generate a new key-pair for the service account.
Note that TSB does not store the generated private key, so the client must read it and
store it securely.

</PanelContent>

### DeleteServiceAccountKey

<PanelContent>
<PanelContentCode>

rpc DeleteServiceAccountKey ([tetrateio.api.tsb.v2.DeleteServiceAccountKeyRequest](../../tsb/v2/team_service#tetrateio-api-tsb-v2-deleteserviceaccountkeyrequest)) returns ([tetrateio.api.tsb.v2.ServiceAccount](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount))

</PanelContentCode>

**Requires** WriteServiceAccount

Delete a key-pair associated the service account.

</PanelContent>






## CreateServiceAccountRequest {#tetrateio-api-tsb-v2-createserviceaccountrequest}

Request to create a ServiceAccount.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the User will be created.

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


serviceAccount

</td>

<td>

[tetrateio.api.tsb.v2.ServiceAccount](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount) <br/> _REQUIRED_ <br/> Details of the Service Account to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


keyEncoding

</td>

<td>

[tetrateio.api.tsb.v2.ServiceAccount.KeyPair.Encoding](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount-keypair-encoding) <br/> The format in which the generated key pairs will be returned.
If not set keys are returned in PEM format.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## CreateTeamRequest {#tetrateio-api-tsb-v2-createteamrequest}

Request to create a Team.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the Team will be created.

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


team

</td>

<td>

[tetrateio.api.tsb.v2.Team](../../tsb/v2/team#tetrateio-api-tsb-v2-team) <br/> _REQUIRED_ <br/> Details of the Team to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteServiceAccountKeyRequest {#tetrateio-api-tsb-v2-deleteserviceaccountkeyrequest}

Delete a key-pair associated with the Service Account.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Service Account.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


id

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> ID of the key-pair to delete.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteServiceAccountRequest {#tetrateio-api-tsb-v2-deleteserviceaccountrequest}

Request to delete a ServiceAccount.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Service Account.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteTeamRequest {#tetrateio-api-tsb-v2-deleteteamrequest}

Request to delete a Team.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Team.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GenerateServiceAccountKeyRequest {#tetrateio-api-tsb-v2-generateserviceaccountkeyrequest}

Request to generate a new key-pair for the Service Account.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Service Account.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


keyEncoding

</td>

<td>

[tetrateio.api.tsb.v2.ServiceAccount.KeyPair.Encoding](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount-keypair-encoding) <br/> The format in which the key pairs will be returned.
If not set keys are returned in PEM format.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GetServiceAccountJWKSRequest {#tetrateio-api-tsb-v2-getserviceaccountjwksrequest}

Request to retrieve all the public keys under a service account.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the service account.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetServiceAccountRequest {#tetrateio-api-tsb-v2-getserviceaccountrequest}

Request to retrieve a Service Account.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Service Account.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


keyEncoding

</td>

<td>

[tetrateio.api.tsb.v2.ServiceAccount.KeyPair.Encoding](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount-keypair-encoding) <br/> The format in which the key pairs will be returned.
If not set keys are returned in PEM format.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GetTeamRequest {#tetrateio-api-tsb-v2-getteamrequest}

Request to retrieve a Team.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Team.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetUserRequest {#tetrateio-api-tsb-v2-getuserrequest}

Request to retrieve a User.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the User.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## JWKS {#tetrateio-api-tsb-v2-jwks}

JSON Web Key Set. Refer to https://datatracker.ietf.org/doc/html/rfc7517



  
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


keys

</td>

<td>

List of [tetrateio.api.tsb.v2.JWKS.JWK](../../tsb/v2/team_service#tetrateio-api-tsb-v2-jwks-jwk) <br/> List of public JWKs

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### JWK {#tetrateio-api-tsb-v2-jwks-jwk}

JSON Web Key. Refer to https://datatracker.ietf.org/doc/html/rfc7517



  
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


alg

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The specific cryptographic algorithm used with the key.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kty

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The family of cryptographic algorithms used with the key.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


use

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> How the key was meant to be used; `sig` represents the signature.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


n

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The modulus for the RSA public key.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


e

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The exponent for the RSA public key.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kid

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The unique identifier for the key.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListServiceAccountsRequest {#tetrateio-api-tsb-v2-listserviceaccountsrequest}

Request to list Service Accounts.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Users from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


keyEncoding

</td>

<td>

[tetrateio.api.tsb.v2.ServiceAccount.KeyPair.Encoding](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount-keypair-encoding) <br/> The format in which the key pairs for each key will be returned.
If not set keys are returned in PEM format.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListServiceAccountsResponse {#tetrateio-api-tsb-v2-listserviceaccountsresponse}

List of existing Service Accounts.



  
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


serviceAccounts

</td>

<td>

List of [tetrateio.api.tsb.v2.ServiceAccount](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListTeamsRequest {#tetrateio-api-tsb-v2-listteamsrequest}

Request to list Teams.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Teams from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListTeamsResponse {#tetrateio-api-tsb-v2-listteamsresponse}

List of existing teams.



  
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


teams

</td>

<td>

List of [tetrateio.api.tsb.v2.Team](../../tsb/v2/team#tetrateio-api-tsb-v2-team) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListUsersRequest {#tetrateio-api-tsb-v2-listusersrequest}

Request to list Users.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list Users from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListUsersResponse {#tetrateio-api-tsb-v2-listusersresponse}

List of existing Users.



  
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


users

</td>

<td>

List of [tetrateio.api.tsb.v2.User](../../tsb/v2/team#tetrateio-api-tsb-v2-user) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## TokenResponse {#tetrateio-api-tsb-v2-tokenresponse}

Contains a pair of tokens for a user that can be used to authenticate against TSB.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Bearer access token that can be used to access TSB.
This token is usually short-lived. The refresh token, when present, can be used to
obtain a new access token when it expires.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Refresh token that can be used to obtain a new Bearer access token.
This token is usually long-lived and should be stored securely.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



