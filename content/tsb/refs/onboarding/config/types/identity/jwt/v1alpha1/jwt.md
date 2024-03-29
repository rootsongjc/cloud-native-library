---
title: JWT Identity
description: JWT identity of a workload.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

JwtIdentity represents an [JWT identity](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
of a workload.

E.g.,

* [JWT identity](https://openid.net/specs/openid-connect-core-1_0.html#IDToken) of a workload:

  ```yaml
  issuer: https://mycompany.corp
  subject: us-east-datacenter1-vm007
  attributes:
    region: us-east
    datacenter: datacenter1
    instance_name: vm007
    instance_hostname: vm007.internal.corp
    instance_role: app-ratings
  ```





## JwtIdentity {#tetrateio-api-onboarding-config-types-identity-jwt-v1alpha1-jwtidentity}

JwtIdentity represents an [JWT identity](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
of a workload.



  
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


subject

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Workload identifier (JWT subject).

A locally unique identifier within the Issuer.

Preferably, the value should consist of lower case alphanumeric characters
and '-', should start and end with an alphanumeric character.

Otherwise, if the value includes ASCII characters other than lower case
alphanumeric characters and '-', it will be encoded in a special way and
will appear in that encoded form in metrics, in diagnostics, on UI.
It might become non-trivial to infer the original workload identifier from
the encoded form.

The value that includes non-ASCII characters is not valid.

E.g., `us-east-datacenter1-vm007`.

See https://openid.net/specs/openid-connect-core-1_0.html#IDToken

</td>

<td>

string = {<br/>&nbsp;&nbsp;pattern: `^[ -]+$`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


attributes

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Additional attributes associated with the workload.

The value is a map with free-form keys and values.

E.g.,

```yaml
region: us-east
datacenter: datacenter1
instance_name: vm007
instance_hostname: vm007.internal.corp
instance_role: app-ratings
```

</td>

<td>

map = {<br/>&nbsp;&nbsp;keys: `{string:{min_len:1}}`<br/>&nbsp;&nbsp;values: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
</table>
  



