---
title: JWT Identity Matcher
description: Specification of matching workloads with JWT identities.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

JwtIdentityMatcher specifies matching workloads with
[JWT identities](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).

For example, the following configuration will match only those workloads that
were authenticated by means of an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
issued by `https://mycompany.corp` for one of the subjects `us-east-datacenter1-vm007` or
`us-west-datacenter2-vm008`:

```yaml
issuer: "https://mycompany.corp"
subjects:
- "us-east-datacenter1-vm007"
- "us-west-datacenter2-vm008"
```

In those cases where an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
from a given issuer includes a map of fine-grained attributes associated with a workload,
it is possible to define rules that match those attributes.

E.g., the following configuration will match a set workloads that
were authenticated by means of an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
issued by `https://mycompany.corp` and include 1) attribute `region` with one of the values
`us-east` or `us-west` and 2) attribute `instance_role` with the value `app-ratings`:

```yaml
issuer: "https://mycompany.corp"
attributes:
- name: "region"
  values:
  - "us-east"
  - "us-west"
- name: "instance_role"
  values:
  - "app-ratings"
```





## AttributeMatcher {#tetrateio-api-onboarding-authorization-jwt-v1alpha1-attributematcher}

AttributeMatcher specifies a matching attribute.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> [OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
must include an attribute with the given name.

E.g., `region`, `instance_role`, etc.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


values

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> [OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
must include the attribute with one of the following values.

E.g., `us-east`, `app-ratings`, etc.

Empty list means match any value.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{min_len:1}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## JwtIdentityMatcher {#tetrateio-api-onboarding-authorization-jwt-v1alpha1-jwtidentitymatcher}

JwtIdentityMatcher specifies matching workloads with
[JWT identities](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Match workloads authenticated by means of an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
issued by a given issuer.

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


subjects

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Match workloads authenticated by means of an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
issued for one of the subjects in a given list.

The value must consist of ASCII characters.

E.g., `us-east-datacenter1-vm007`.

Empty list means match
[OIDC ID Tokens](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
with any subject.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{string:{pattern:^[\u0000-]+$}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


attributes

</td>

<td>

List of [tetrateio.api.onboarding.authorization.jwt.v1alpha1.AttributeMatcher](../../../../../onboarding/config/authorization/jwt/v1alpha1/jwt#tetrateio-api-onboarding-authorization-jwt-v1alpha1-attributematcher) <br/> _REQUIRED_ <br/> Match workloads authenticated by means of an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
that includes all of the following attributes.

Empty list means match
[OIDC ID Tokens](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
with any attributes.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{message:{required:true}}`<br/>}<br/>

</td>
</tr>
    
</table>
  



