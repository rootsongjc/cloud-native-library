---
title: Organization Setting
description: Configuration for specifying global settings in an organization.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Organization Setting allows configuring global settings for the organization.
Settings such as network reachability or regional failover that apply globally
to the organization are configured in the Organizations Setting object.

This is a global object that uniquely configures the organization, and there can
be only one Organization Setting object defined for each organization.

The following example shows how these settings can be used to describe the organization's
network reachability settings and some regional failover configurations.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: OrganizationSetting
metadata:
  name: org-settings
  organization: myorg
spec:
  networkSettings:
    networkReachability:
      vpc01: vpc02,vpc03
  regionalFailover:
    - from: us-east1
      to: us-central1
```





## OrganizationSetting {#tetrateio-api-tsb-v2-organizationsetting}

Settings that apply globally to the entire organization.



  
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


networkSettings

</td>

<td>

[tetrateio.api.tsb.v2.OrganizationSetting.NetworkSettings](../../tsb/v2/organization_setting#tetrateio-api-tsb-v2-organizationsetting-networksettings) <br/> Reachability between clusters on various networks.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


regionalFailover

</td>

<td>

List of [tetrateio.api.tsb.types.v2.RegionalFailover](../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-regionalfailover) <br/> Default locality routing settings for all gateways.

Explicitly specify the region traffic will land on when endpoints in local region becomes unhealthy.
Should be used together with OutlierDetection to detect unhealthy endpoints.
Note: if no OutlierDetection specified, this will not take effect.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


defaultSecuritySetting

</td>

<td>

[tetrateio.api.tsb.security.v2.SecuritySetting](../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting) <br/> Security settings for all proxy workloads in this organization.
This can be overridden at TenantSettings, WorkspaceSettings, or security
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

[tetrateio.api.tsb.traffic.v2.TrafficSetting](../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-trafficsetting) <br/> Traffic settings for all proxy workloads in this organization.
This can be overridden at TenantSettings or WorkspaceSettings for specific cases.
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
  


### NetworkSettings {#tetrateio-api-tsb-v2-organizationsetting-networksettings}

Network related settings for clusters.



  
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


networkReachability

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Reachability between clusters on various networks. Each cluster
has a "network" field representing a network boundary like a VPC
on AWS/GCP/Azure. All clusters within the same network are
assumed to be reachable to each other for multi-cluster routing.
In addition, you can specify additional connectivity between
various networks in the mesh here. For example on AWS, each VPC
can be treated as a distinct network. VPCs that are reachable to
one another (through peering or transit gateways) can be listed
as reachable networks. The key is the network name and the value
is a comma separated list of networks whose clusters are
reachable from this network. For instance, vpc01: vpc02,vpc03 means
that the clusters in the network can reach those in vpc02 and vpc03.

Note that reachability is **not** bidirectional. That is, if `vpc01: vpc02`
is specified, then `vpc01` can reach `vpc02`, but not the other way around.
Hence, the workloads in clusters in `vpc01` can access the services
through the exposed gateway hostnames in clusters in `vpc02` . However,
the workloads in clusters in `vpc02` cannot access the services exposed
through the gateway hostnames in `vpc01`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



