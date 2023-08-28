---
title: Teams and Users
description: Configuration for managing users and teams.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`User` represents a user that has been loaded from a configured
Identity Provider (IdP) that can log into the platform.
Currently, users are automatically synchronized by TSB from a
configured LDAP server.

The following example creates a user named `john` under the organization
`myorg`.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: User
metadata:
  name: john
  organization: myorg
spec:
  loginName: john
  firstName: John
  lastName: Doe
  displayName: John Doe
  email: john.doe@acme.com
```

`ServiceAccount` can be created to leverage machine authentication via JWT tokens.
Each service account has a key-pair that can be used to create signed JWT tokens that
can be used to authenticate to TSB.

The following example creates a service account named `my-sa` under the organization
`myorg`.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: ServiceAccount
metadata:
  name: my-sa
  organization: myorg
spec:
  displayName: My Service Account
  description: Service account used for service integrations
```

`Team` is a named collection of users, service accounts, and other
teams. Teams can be assigned access permissions on various
resources. All members of a team inherit the access permissions
assigned to the team.

The following example creates a team named `org` under the organization
`myorg` with all members of `product1` and `product2` teams, and
users `alice` and `bob`.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Team
metadata:
  name: org
  organization: myorg
spec:
  members:
  - organizations/myorg/users/alice
  - organizations/myorg/users/bob
  - organizations/myorg/teams/product1
  - organizations/myorg/teams/product2
```





## ServiceAccount {#tetrateio-api-tsb-v2-serviceaccount}

`ServiceAccount` represents a service account that can be used to access the TSB platform.
Service accounts have a set of associated public and private keys that can be used to generate
signed JWT tokens that are suitable to authenticate to TSB.
A default key-pair is generated on service account creation and the public key is stored in TSB.
Private keys are returned when service accounts are created, but TSB will not store them. It
is up to the client to store them securely.



  
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


description

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> A description of the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


keys

</td>

<td>

List of [tetrateio.api.tsb.v2.ServiceAccount.KeyPair](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount-keypair) <br/> _OUTPUT_ONLY_ <br/> Keys associated with the service account.
A default key-pair is automatically created when the Service Account is created. Note that
TSB does not store the private keys, so it is up to the client to store the returned private
keys securely, as they are only returned once after creation.
Additional keys can be added (and deleted) by using the corresponding key management APIs.
<!-- terraform code generation tags
+protoc-gen-terraform:computed
+protoc-gen-terraform:stateforunknown
-->

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### KeyPair {#tetrateio-api-tsb-v2-serviceaccount-keypair}

Represents key-pair associated to the service account.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> Unique identifier for this key-pair. This should be used as the `kid` (key id) when
generating JWT tokens that are signed with this key-pair.
<!-- terraform code generation tags
+protoc-gen-terraform:computed
-->

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


publicKey

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> The encoded public key associated with the service account.
The encoding format is determined by the `encoding` field.
<!-- terraform code generation tags
+protoc-gen-terraform:computed
-->

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


privateKey

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> The encoded private key associated with the service account.
TSB does not store the private key and it is up to the client to store it safely.
The encoding format is determined by the `encoding` field.
<!-- terraform code generation tags
+protoc-gen-terraform:sensitive
+protoc-gen-terraform:computed
-->

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


encoding

</td>

<td>

[tetrateio.api.tsb.v2.ServiceAccount.KeyPair.Encoding](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount-keypair-encoding) <br/> Format in which the public and private keys are encoded.
By default keys are returned in PEM format.
<!-- terraform code generation tags
+protoc-gen-terraform:computed
-->

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


defaultToken

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> A default access token that can be used to authenticate to TSB on behalf of the
service account. TSB does not store this token and it is only returned when a
service account key is created, similar to the private key. It is up to the client
to store the token for future use or to use the TSB CLI to generate new tokens as
explained in: https://docs.tetrate.io/service-bridge/latest/en-us/howto/service-accounts
<!-- terraform code generation tags
+protoc-gen-terraform:sensitive
+protoc-gen-terraform:computed
-->

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Team {#tetrateio-api-tsb-v2-team}

`Team` is a named collection of users under a tenant.



  
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


members

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of members under the team.
The elements of this list are the FQNs of the team members. Team members can be
users, service accounts or other teams.

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

[tetrateio.api.tsb.v2.SourceType](../../tsb/v2/team#tetrateio-api-tsb-v2-sourcetype) <br/> Where the team comes from. It can be a local team that exists only in TSB (type LOCAL)
or it can be a team that has been synchronized from the Identity Provider (for
example: type LDAP).
<!-- terraform code generation tags
+protoc-gen-terraform:computed
-->

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## User {#tetrateio-api-tsb-v2-user}

`User` represents a user from the Identity Provider that is allowed to log into
the platform.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The username used in the login credentials.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


firstName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The first name of the user.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Email for the user where alerts and other notifications will be sent.

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

[tetrateio.api.tsb.v2.SourceType](../../tsb/v2/team#tetrateio-api-tsb-v2-sourcetype) <br/> Where the user comes from. It can be a local user that exists only in TSB (type LOCAL)
or it can be a user that has been synchronized from the Identity Provider (for
example: type LDAP).
<!-- terraform code generation tags
+protoc-gen-terraform:computed
+protoc-gen-terraform:enumdefault:4
-->

</td>

<td>

enum = {<br/>&nbsp;&nbsp;defined_only: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  




#### Encoding {#tetrateio-api-tsb-v2-serviceaccount-keypair-encoding}

Format in which the keys in this keypair are encoded


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


PEM

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


JWK

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
</table>
  



## SourceType {#tetrateio-api-tsb-v2-sourcetype}

`SourceType` describes where teams come from.
Teams can be synchronized from the Identity Provider but can also be manually
created using the Team API to create convenient groupings of users and other
teams in order to configure fine-grained permissions in the Management Plane.


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


INVALID

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


LDAP

</td>

<td>

1

</td>

<td>

LDAP is used for users and teams that are automatically synchronized from LDAP.

</td>
</tr>
    
<tr>
<td>


LOCAL

</td>

<td>

2

</td>

<td>

LOCAL is used for local teams that are manually created using the TSB Team API and
do not exist in the Identity Provider.
Deprecated. This value is deprecated and will be removed in future releases. Use &#39;MANUAL&#39; instead.

</td>
</tr>
    
<tr>
<td>


AZURE

</td>

<td>

3

</td>

<td>

AZURE is used for users synchronized from an Azure Active Directory.

</td>
</tr>
    
<tr>
<td>


MANUAL

</td>

<td>

4

</td>

<td>

MANUAL is used for users and teams that exist in the Identity Provider that have been manually populated.
MANUAL users are deprecated and Service Accounts should be used instead. Support for MANUAL users will
be removed in future versions.

</td>
</tr>
    
</table>
  


