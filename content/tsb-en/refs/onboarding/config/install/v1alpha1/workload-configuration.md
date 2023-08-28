---
title: Workload Configuration
description: Configuration of the workload handling.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

WorkloadConfiguration specifies configuration of the workload handling.

For example,

```yaml
authentication:
  jwt:
    issuers:
    - issuer: "https://mycompany.corp"
      jwksUri: "https://mycompany.corp/jwks.json"
      shortName: "mycorp"
      tokenFields:
        attributes:
          jsonPath: .custom_attributes
deregistration:
  propagationDelay: 15s
```





## JwtAuthenticationConfiguration {#tetrateio-api-onboarding-config-install-v1alpha1-jwtauthenticationconfiguration}

JwtAuthenticationConfiguration specifies configuration of the workload
authentication by means of an [OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).



  
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


issuers

</td>

<td>

List of [tetrateio.api.onboarding.config.install.v1alpha1.JwtIssuer](../../../../onboarding/config/install/v1alpha1/jwt_issuer#tetrateio-api-onboarding-config-install-v1alpha1-jwtissuer) <br/> List of permitted JWT issuers.

If a workload authenticates itself by means of an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken),
the issuer of that token must be present in this list, otherwise
authentication attempt will be declined.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{message:{required:true}}`<br/>}<br/>

</td>
</tr>
    
</table>
  


## WorkloadAuthenticationConfiguration {#tetrateio-api-onboarding-config-install-v1alpha1-workloadauthenticationconfiguration}

WorkloadAuthenticationConfiguration specifies configuration of the workload
authentication.



  
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

[tetrateio.api.onboarding.config.install.v1alpha1.JwtAuthenticationConfiguration](../../../../onboarding/config/install/v1alpha1/workload_configuration#tetrateio-api-onboarding-config-install-v1alpha1-jwtauthenticationconfiguration) <br/> JWT authentication configuration.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## WorkloadConfiguration {#tetrateio-api-onboarding-config-install-v1alpha1-workloadconfiguration}

WorkloadConfiguration specifies configuration of the workload handling.



  
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


authentication

</td>

<td>

[tetrateio.api.onboarding.config.install.v1alpha1.WorkloadAuthenticationConfiguration](../../../../onboarding/config/install/v1alpha1/workload_configuration#tetrateio-api-onboarding-config-install-v1alpha1-workloadauthenticationconfiguration) <br/> Workload authentication configuration.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


deregistration

</td>

<td>

[tetrateio.api.onboarding.config.install.v1alpha1.WorkloadDeregistrationConfiguration](../../../../onboarding/config/install/v1alpha1/workload_configuration#tetrateio-api-onboarding-config-install-v1alpha1-workloadderegistrationconfiguration) <br/> Workload deregistration configuration.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## WorkloadDeregistrationConfiguration {#tetrateio-api-onboarding-config-install-v1alpha1-workloadderegistrationconfiguration}

WorkloadDeregistrationConfiguration specifies configuration of the workload
deregistration.



  
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


propagationDelay

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Estimated amount of time it takes to propagate the unregistration event
across all affected mesh nodes.

During this time interval affected proxies will continue making requests
to the deregistered workload until the respective configuration update
arrives.

To prevent traffic loss, `Workload Onboarding Agent` SHOULD delay shutdown
of the the workload's sidecar for that time period.

As a rule of thumb, this value should remain relatively small, e.g. under
15 seconds. The reason for this is that shutdown flow on the workload's side
is time-boxed. E.g., on VMs there is a stop timeout enforced by SystemD,
while on AWS ECS there is a stop timeout enforced by ECS Agent. If you pick
a delay value that is too big, `Workload Onboarding Agent` will delay
shutdown of the sidecar for too long; as a result sidecar risks to get
terminated abruptly instead of graceful connection draining.

Defaults to `10s`.

</td>

<td>

duration = {<br/>&nbsp;&nbsp;required: `true`<br/>&nbsp;&nbsp;gte: `{nanos:0}`<br/>}<br/>

</td>
</tr>
    
</table>
  



