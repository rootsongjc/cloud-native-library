---
title: Auth
description: Authentication and authorization configs at gateways, security group level
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Authentication and authorization configs at gateways, security group level





## Authentication {#tetrateio-api-tsb-auth-v2-authentication}





  
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


jwt

</td>

<td>

[tetrateio.api.tsb.auth.v2.Authentication.JWT](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authentication-jwt) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> authn</sup>_ <br/> Authenticate an HTTP request from a JWT Token attached to it.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rules

</td>

<td>

[tetrateio.api.tsb.auth.v2.Authentication.Rules](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authentication-rules) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> authn</sup>_ <br/> List of rules how to authenticate an HTTP request.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### JWT {#tetrateio-api-tsb-auth-v2-authentication-jwt}





  
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


issuer

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Identifies the issuer that issued the JWT. See
[issuer](https://tools.ietf.org/html/rfc7519#section-4.1.1)
A JWT with different `iss` claim will be rejected.

Example: https://foobar.auth0.com
Example: 1234567-compute@developer.gserviceaccount.com

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


audiences

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The list of JWT
[audiences](https://tools.ietf.org/html/rfc7519#section-4.1.3).
that are allowed to access. A JWT containing any of these
audiences will be accepted.

The service name will be accepted if audiences is empty.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


jwksUri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> keys</sup>_ <br/> URL of the provider's public key set to validate signature of
the JWT. See [OpenID
Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata).

Optional if the key set document can either (a) be retrieved
from [OpenID
Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html)
of the issuer or (b) inferred from the email domain of the
issuer (e.g. a Google service account).

Example: `https://www.googleapis.com/oauth2/v1/certs`

Note: Only one of jwks_uri and jwks should be used. jwks_uri
will be ignored if it does.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


jwks

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> keys</sup>_ <br/> JSON Web Key Set of public keys to validate signature of the JWT.
See https://auth0.com/docs/jwks.

Note: Only one of jwks_uri and jwks should be used. jwks_uri will be ignored if it does.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


outputPayloadToHeader

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> This field specifies the header name to output a successfully verified JWT payload to the
backend. The forwarded data is `base64_encoded(jwt_payload_in_JSON)`. If it is not specified,
the payload will not be emitted.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


outputClaimToHeaders

</td>

<td>

List of [tetrateio.api.tsb.auth.v2.Authentication.JWT.ClaimToHeader](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authentication-jwt-claimtoheader) <br/> This field specifies a list of operations to copy the claim to HTTP headers on a successfully verified token.
This differs from the `output_payload_to_header` by allowing outputting individual claims instead of the whole payload.
Only claims of type string, boolean, and integer are supported. Array type claims are not supported at this time.
The header specified in each operation in the list must be unique. Nested claims of type string/int/bool is supported as well.
```
  outputClaimToHeaders:
  - header: x-my-company-jwt-group
    claim: my-group
  - header: x-test-environment-flag
    claim: test-flag
  - header: x-jwt-claim-group
    claim: nested.key.group
```
[Experimental] This feature is a experimental feature.

[TODO:Update the status whenever this feature is promoted.]

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


fromHeaders

</td>

<td>

List of [tetrateio.api.tsb.auth.v2.Authentication.JWT.JWTHeader](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authentication-jwt-jwtheader) <br/> This field specifies the locations to extract JWT token.
If no explicit location is specified the following default
locations are tried in order:

    1) The Authorization header using the Bearer schema,
       e.g. Authorization: Bearer <token>. (see
       [Authorization Request Header
       Field](https://tools.ietf.org/html/rfc6750#section-2.1))

    2) The `access_token` query parameter (see
    [URI Query Parameter](https://tools.ietf.org/html/rfc6750#section-2.3))

List of header locations from which JWT is expected. For example, below is the location spec
if JWT is expected to be found in `x-jwt-assertion` header, and have `Bearer ` prefix:

```yaml
  fromHeaders:
  - name: x-jwt-assertion
    prefix: "Bearer "
```

Note: Multiple tokens present on the same request are not supported. 
The behaviour of authorization policies when there is more than one user identity is undefined

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### ClaimToHeader {#tetrateio-api-tsb-auth-v2-authentication-jwt-claimtoheader}

This message specifies the detail for copying claim to header.



  
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


header

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The name of the header to be created. The header will be overridden if it already exists in the request.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


claim

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The name of the claim to be copied from. Only claim of type string/int/bool is supported.
The header will not be there if the claim does not exist or the type of the claim is not supported.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


#### JWTHeader {#tetrateio-api-tsb-auth-v2-authentication-jwt-jwtheader}

This message specifies a header location to extract JWT token.



  
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


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The HTTP header name.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


prefix

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The prefix that should be stripped before decoding the token.
For example, for `Authorization: Bearer <token>`, prefix=`Bearer ` with a space at the end.
If the header doesn't have this exact prefix, it is considered invalid.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Rules {#tetrateio-api-tsb-auth-v2-authentication-rules}





  
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


jwt

</td>

<td>

List of [tetrateio.api.tsb.auth.v2.Authentication.JWT](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authentication-jwt) <br/> List of rules how to authenticate an HTTP request from a JWT Token attached to it.
A JWT Token, if present in the HTTP request, must satisfy one of the rules defined here.
The order in which rules are being checked at runtime might differ from the order
in which they are defined here.
If the JWT Token doesn't satisfy any of the rules, the request will be rejected.
If the JWT Token does satisfy one of the rules, the identity of the request
will be extracted from the JWT Token.

Notice that an HTTP request without a JWT Token attached to it will NOT be rejected
based on the rules defined here. Remember to define HTTP request authorization settings
to achieve that.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Authorization {#tetrateio-api-tsb-auth-v2-authorization}

Configuration for authorizing a HTTP request



  
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


external

</td>

<td>

[tetrateio.api.tsb.auth.v2.Authorization.ExternalAuthzBackend](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authorization-externalauthzbackend) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> authz</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


local

</td>

<td>

[tetrateio.api.tsb.auth.v2.Authorization.LocalAuthz](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-authorization-localauthz) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> authz</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### ExternalAuthzBackend {#tetrateio-api-tsb-auth-v2-authorization-externalauthzbackend}

Use an authorization server running at the specified URI. Support both HTTP and gRPC server.
It is recommended to enable TLS validation (SIMPLE or MUTUAL) to secure traffic 
between workload and external authorization server
If you use gRPC, do not set `includeRequestHeaders`



  
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


uri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


includeRequestHeaders

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tls

</td>

<td>

[tetrateio.api.tsb.auth.v2.ClientTLSSettings](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-clienttlssettings) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### LocalAuthz {#tetrateio-api-tsb-auth-v2-authorization-localauthz}

Authorize the request in Envoy based on the JWT claims.



  
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


rules

</td>

<td>

List of [tetrateio.api.tsb.auth.v2.LocalAuthzRule](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-localauthzrule) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ClientTLSSettings {#tetrateio-api-tsb-auth-v2-clienttlssettings}

Configure TLS parameters for the client



  
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


mode

</td>

<td>

[tetrateio.api.tsb.auth.v2.TLSMode](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-tlsmode) <br/> Set this to DISABLED to disable TLS (not recommended from the
security perspective), SIMPLE for one-way TLS and MUTUAL for
mutual TLS (where client is required to present its certificate as well)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


files

</td>

<td>

[tetrateio.api.tsb.auth.v2.TLSFileSource](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-tlsfilesource) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> tls_key_source</sup>_ <br/> TLS key source from files.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


secretName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> tls_key_source</sup>_ <br/> TLS key source from a Kubernetes Secret.
This is applicable for gateway workloads.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


subjectAltNames

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Subject alternative names is the list of names that are accepted
as service name as part of TLS handshake

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## LocalAuthzRule {#tetrateio-api-tsb-auth-v2-localauthzrule}

LocalAuthzRule

Bindings define the subjects that can access the resource a policy is attached to,
and the conditions that need to be met for that access to be granted.
A policy can have multiple bindings to configure different access controls for specific
subjects.



  
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


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> A friendly name to identify the binding.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


from

</td>

<td>

List of [tetrateio.api.tsb.auth.v2.Subject](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-subject) <br/> Subjects configure the actors (end users, other services)  that are allowed to access the
target resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


to

</td>

<td>

List of [tetrateio.api.tsb.auth.v2.LocalAuthzRule.HttpOperation](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-localauthzrule-httpoperation) <br/> A set of HTTP rules that need to be satisfied by the HTTP requests to get access to the
target resource.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### HttpOperation {#tetrateio-api-tsb-auth-v2-localauthzrule-httpoperation}





  
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


paths

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The request path where the request is made against. E.g. ["/accounts"].

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


methods

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The HTTP methods that are allowed by this rule. E.g. ["GET", "HEAD"].

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{in:[GET,HEAD,POST,PUT,PATCH,DELETE,OPTIONS]}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## Subject {#tetrateio-api-tsb-auth-v2-subject}

Subject

A subject designates an actor (user, service, etc) that attempts to access a target resource.
Subjects can be modeled with JWT tokens, service accounts, and decorated with attributes such as
HTTP request headers, JWT token claims, etc.
The fields that define a subject will be matched to incoming requests, to fully qualify where the
request comes from, and to decide if the given request is allowed or not for the target resource.
All the fields in a subject are evaluated as AND expressions.



  
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


jwt

</td>

<td>

[tetrateio.api.tsb.auth.v2.Subject.JWTClaims](../../../tsb/auth/v2/auth#tetrateio-api-tsb-auth-v2-subject-jwtclaims) <br/> JWT configuration to identity the subject.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### JWTClaims {#tetrateio-api-tsb-auth-v2-subject-jwtclaims}

JWT based subject

JWT based subjects qualify a subject by matching against a JWT token present in the request.
By default the token is expected to be present in the 'Authorization' HTTP header, with the
'Bearer" prefix.



  
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


iss

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


sub

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


other

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> A set of arbitrary claims that are required to qualify the subject.
E.g. "iss": "*@foo.com".

</td>

<td>

map = {<br/>&nbsp;&nbsp;keys: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## TLSFileSource {#tetrateio-api-tsb-auth-v2-tlsfilesource}

TLSFileSource is used to load the keys and certificates from
files accessible to the workload



  
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


clientCertificate

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Certificate file to authenticate the client. This
is mandatory for mutual TLS and must not be
specified for simple (one-way) TLS

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Private key file associated with the client certificate.
This is mandatory for mutual TLS and must not be
specified for simple TLS

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


caCertificates

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> File containing CA certificates to verify the certificates
presented by the server. This is mandatory for both simple and
mutual TLS.
Here are some common paths for the system CA bundle on Linux and can be
specified here if the server certificate is signed by a well known authority,
already part of the system CA bundle on the host - 
  /etc/ssl/certs/ca-certificates.crt (Debian/Ubuntu/Gentoo etc.)
  /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem (CentOS/RHEL 7)
  /etc/pki/tls/certs/ca-bundle.crt (Fedora/RHEL 6)

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




## TLSMode {#tetrateio-api-tsb-auth-v2-tlsmode}

Describes how authentication is performed
as part of establishing TLS connection


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


DISABLED

</td>

<td>

0

</td>

<td>

TLS is not used and communication is
in plaintext.

</td>
</tr>
    
<tr>
<td>


SIMPLE

</td>

<td>

1

</td>

<td>

Only the server is authenticated.

</td>
</tr>
    
<tr>
<td>


MUTUAL

</td>

<td>

2

</td>

<td>

Both the peers in the communication must
present their certificate for TLS authentication

</td>
</tr>
    
</table>
  


