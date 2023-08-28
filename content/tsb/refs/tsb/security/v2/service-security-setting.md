---
title: Service Security Setting
description: Service specific security settings for proxy workloads in a security group.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`ServiceSecuritySetting` allows configuring security related properties
such as TLS authentication and access control for traffic arriving
at a particular service in a security group. These settings will replace
the security group wide settings for this service.

The following example defines a security setting that applies to the service
`foo` in namespace `ns1` that only allows mutual TLS authenticated traffic
from other proxy workloads in the same group.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: ServiceSecuritySetting
metadata:
  name: foo-auth
  group: sg1
  workspace: w1
  tenant: mycompany
  org: myorg
spec:
  service: ns1/foo.ns1.svc.cluster.local
  settings:
    authentication: REQUIRED
    authorization:
      mode: GROUP
```

The following example customizes the `Extensions` to enable
the execution of the WasmExtensions list specified, detailing
custom properties for the execution of each extension.

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: ServiceSecuritySetting
metadata:
  name: foo-wasm-plugin
  group: sg1
  workspace: w1
  tenant: mycompany
  org: myorg
spec:
  service: ns1/foo.ns1.svc.cluster.local
  settings:
    extension:
    - fqn: hello-world # fqn of imported extensions in TSB
      config:
        foo: bar
```





## ServiceSecuritySetting {#tetrateio-api-tsb-security-v2-servicesecuritysetting}

A service security setting applies configuration to a service in a
security group. Missing fields will inherit values from the
workspace-wide setting if any.



  
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


service

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The service on which the configuration is being applied. Must be in namespace/FQDN format.

</td>

<td>

string = {<br/>&nbsp;&nbsp;pattern: `^[^/]+/[^/]+$`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


settings

</td>

<td>

[tetrateio.api.tsb.security.v2.SecuritySetting](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting) <br/> Security settings to apply to this service.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


subsets

</td>

<td>

List of [tetrateio.api.tsb.security.v2.ServiceSecuritySetting.Subset](../../../tsb/security/v2/service_security_setting#tetrateio-api-tsb-security-v2-servicesecuritysetting-subset) <br/> Subset specific settings that will replace the service wide settings for the specified service
subsets.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


configGenerationMetadata

</td>

<td>

[tetrateio.api.tsb.types.v2.ConfigGenerationMetadata](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-configgenerationmetadata) <br/> Metadata values that will be add into the Istio generated configurations.
When using YAML APIs like`tctl` or `gitops`, put them into the `metadata.labels` or
`metadata.annotations` instead.
This field is only necessary when using gRPC APIs directly.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Subset {#tetrateio-api-tsb-security-v2-servicesecuritysetting-subset}

Subset allows replacing the settings for a specific version of a service.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name used to refer to the subset.
This must match a subset defined in the ServiceRoute for this service, else it will be omitted.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


settings

</td>

<td>

[tetrateio.api.tsb.security.v2.SecuritySetting](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting) <br/> _REQUIRED_ <br/> Security settings to apply to this service subset.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  



