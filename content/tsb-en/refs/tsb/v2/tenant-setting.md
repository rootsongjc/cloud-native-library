---
title: Tenant Setting
description: Configuration for specifying global settings in a tenant.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Tenant Setting allows configuring default settings for the tenant.

Traffic and Security settings can be defined as default for a tenant, meaning that they
will be applied to all the workspaces of the tenant.
These defaults settings can be overridden by creating proper WorkspaceSetting, TrafficSetting or SecuritySetting
into the desired workspace or group.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: TenantSetting
metadata:
  name: tenant-settings
  organization: myorg
  tenant: mytenant
spec:
  defaultTrafficSetting:
    reachability:
      mode: WORKSPACE
    egress: 
      host: bookinfo-perimeter/tsb-egress
  defaultSecuritySetting:
    authenticationSettings:
      trafficMode: REQUIRED
    authorization:
      mode: GROUP
```





## TenantSetting {#tetrateio-api-tsb-v2-tenantsetting}

Default settings that apply to all workspaces under a tenant.



  
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


defaultSecuritySetting

</td>

<td>

[tetrateio.api.tsb.security.v2.SecuritySetting](../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting) <br/> Security settings for all proxy workloads in this tenant.
This can be overridden at WorkspaceSettings or security
group's SecuritySetting for specific cases.
The override strategy used will be driven by the SecuritySetting propagation strategy.
The default propagation strategy is `REPLACE`, in which a lower level SecuritySetting in the configuration
hierarchy replaces a higher level SecuritySetting defined in the configuration hierarchy.
For instance, a WorkspaceSettings defined SecuritySetting will replace any tenant or
organization defined SecuritySetting.
Proxy workloads without a specific security group will inherit these settings.
If omitted, the following semantics apply:

1. Sidecars will accept connections from clients using Istio
Mutual TLS as well as legacy clients using plaintext (i.e. any
traffic not using Istio Mutual TLS authentication),
i.e. authentication mode defaults to `OPTIONAL`.

2. No authorization will be performed, i.e., authorization mode defaults to `DISABLED`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


defaultTrafficSetting

</td>

<td>

[tetrateio.api.tsb.traffic.v2.TrafficSetting](../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-trafficsetting) <br/> Traffic settings for all proxy workloads in this tenant.
This can be overridden at WorkspaceSetting or TrafficSetting for specific cases.
Proxy workloads without a specific traffic group will inherit these settings.
If omitted, the following semantics apply:

1. Sidecars will be able to reach any service in the
cluster, i.e. reachability mode defaults to `CLUSTER`.

2. Traffic to unknown destinations will be directly routed from
the sidecar to the destination.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



