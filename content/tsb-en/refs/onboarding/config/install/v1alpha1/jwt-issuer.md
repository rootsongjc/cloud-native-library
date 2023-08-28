---
title: JWT Issuer
description: Configuration associated with a JWT issuer.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

JwtIssuer specifies configuration associated with a JWT issuer.

For example,

```yaml
issuer: "https://mycompany.corp"
jwksUri: "https://mycompany.corp/jwks.json"
shortName: "mycorp"
tokenFields:
  attributes:
    jsonPath: .custom_attributes
```





## JwtIssuer {#tetrateio-api-onboarding-config-install-v1alpha1-jwtissuer}

JwtIssuer specifies configuration associated with a JWT issuer.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> JWT `Issuer` identifier.

The value must be a case sensitive URL using the https scheme that contains
scheme, host, and optionally, port number and path components and no query
or fragment components.

E.g., `https://mycompany.corp`, `https://accounts.google.com`,
`https://sts.windows.net/9edbd6c9-0e5b-4cfd-afec-fdde27cdd928/`, etc.

See https://openid.net/specs/openid-connect-core-1_0.html#IDToken

</td>

<td>

string = {<br/>&nbsp;&nbsp;prefix: `https://`<br/>&nbsp;&nbsp;uri: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


jwksUri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> jwks_source</sup>_ <br/> URL of the JSON Web Key Set document.

Source of public keys the `Workload Onboarding Plane` should use
to validate the signature of an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).

E.g., `https://mycompany.corp/jwks.json`.

When unspecified, URL the JSON Web Key Set document will be resolved using
[OpenID Connect Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html)
protocol.

</td>

<td>

string = {<br/>&nbsp;&nbsp;prefix: `https://`<br/>&nbsp;&nbsp;uri: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


jwks

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> jwks_source</sup>_ <br/> Inlined JSON Web Key Set document.

Specifies public keys the `Workload Onboarding Plane` should use
to validate the signature of an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


shortName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Unique short name associated with the issuer.

The value must consist of lower case alphanumeric characters and hyphen (`-`).

Since this value will be included into the auto-generated name of the
`WorkloadAutoRegistration` resource, keep it as short as possible.

E.g., `my-corp`, `prod`, `test`, etc.

</td>

<td>

string = {<br/>&nbsp;&nbsp;pattern: `^[0-9a-z]+(-[0-9a-z]+)*$`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


tokenFields

</td>

<td>

[tetrateio.api.onboarding.config.install.v1alpha1.JwtTokenFields](../../../../onboarding/config/install/v1alpha1/jwt_issuer#tetrateio-api-onboarding-config-install-v1alpha1-jwttokenfields) <br/> Description of the custom fields included in the
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).

By default, `Workload Onboarding Plane` interprets only one field that is always present
in a valid [OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
- `sub` (subject).

If you want `Workload Onboarding Plane` to interpret custom fields included in the
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken),
you have to provide an explicit configuration.

E.g., you can instruct the `Workload Onboarding Plane` to treat a certain field
as a map of fine-grained attributes associated with the subject. It will allow you
to define `OnboardingPolicy`(s) that match those attributes.

Notice that this description instructs how to interpret custom fields if they are present
in an [OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).
A token in which custom fields are not present is still valid. An `OnboardingPolicy` that
does not put constraints on attributes extracted from custom fields can still match a
workload with that token.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## JwtTokenField {#tetrateio-api-onboarding-config-install-v1alpha1-jwttokenfield}

JwtTokenField specifies a custom field included into the
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).



  
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


jsonPath

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Simple JSON Path which is evaluated against custom claims of the
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
to produce the value of the field.

E.g., `.custom_attributes`, `.google.compute_engine`, etc.

JSON Path must start either from `.` or from `$`. Use of `$` is mandatory
when followed by the array notation.

E.g., `$['custom_attributes']`, `$['google'].compute_engine`, etc.

Special symbols (such as `.` or ` `) in property names must be escaped.

E.g., `.custom\.attributes`, `$['custom\.attributes']`, etc.

See https://goessner.net/articles/JsonPath/

</td>

<td>

string = {<br/>&nbsp;&nbsp;pattern: `^[.$].+$`<br/>}<br/>

</td>
</tr>
    
</table>
  


## JwtTokenFields {#tetrateio-api-onboarding-config-install-v1alpha1-jwttokenfields}

JwtTokenFields specifies custom fields included into the
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).



  
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


attributes

</td>

<td>

[tetrateio.api.onboarding.config.install.v1alpha1.JwtTokenField](../../../../onboarding/config/install/v1alpha1/jwt_issuer#tetrateio-api-onboarding-config-install-v1alpha1-jwttokenfield) <br/> Field that carries a map of fine-grained attributes associated with
the subject of the [OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).

If specified, `Workload Onboarding Plane` will treat the name/value pairs extracted
from this field as attributes associated with the workload. It will allow you
to define `OnboardingPolicy`(s) that match those attributes.

E.g., if an [OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
includes the following fields:

```yaml
{
  "iss": "https://mycompany.corp",
  "aud": "ef67c7b9-10da-4542-ad3b-b95acc1e05ba",
  "sub": "us-east-datacenter1-vm007",
  "azp": "us-east-datacenter1-vm007",
  "iat": 1613404941,
  "exp": 1613408541,
  "custom_attributes": {
    "region": "us-east",
    "datacenter": "datacenter1",
    "instance_name": "vm007",
    "instance_hostname": "vm007.internal.corp",
    "instance_role": "app-ratings"
  }
}
```

then, you can indicate to the `Workload Onboarding Plane` to treat the contents of field
`custom_attributes` as fine-grained attributes associated with the workload.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## OnboardingPlaneComponentSet {#tetrateio-api-onboarding-config-install-v1alpha1-onboardingplanecomponentset}

The set of components that make up the control plane. Use this to override application settings
or Kubernetes settings for each individual component.



  
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


instance

</td>

<td>

[tetrateio.api.onboarding.config.install.v1alpha1.OnboardingPlaneInstance](../../../../onboarding/config/install/v1alpha1/jwt_issuer#tetrateio-api-onboarding-config-install-v1alpha1-onboardingplaneinstance) <br/> `Workload Onboarding Plane Instance` component.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## OnboardingPlaneInstance {#tetrateio-api-onboarding-config-install-v1alpha1-onboardingplaneinstance}

Kubernetes settings for the `Workload Onboarding Plane Instance` component.



  
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


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


logLevels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> The log level configuration by scopes.
Supported log level: "none", "error", "warn", "info", "debug".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



