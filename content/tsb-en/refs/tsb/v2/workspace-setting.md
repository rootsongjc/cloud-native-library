---
title: Workspace Setting
description: Configuration for specifying default traffic and security settings in a workspace.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Workspace Setting allows configuring the default traffic, security and
east-west gateway settings for all the workloads in the namespaces owned by
the workspace. Any namespace in the workspace that is not part of a
traffic or security group with specific settings will use these default
settings.

The following example sets the default security policy to accept
either mutual TLS or plaintext traffic, and only accept connections
at a proxy workload from services within the same namespace. The default
traffic policy allows unknown traffic from a proxy workload to be
forwarded via an egress gateway `tsb-egress` in the `perimeter`
namespace in the same cluster.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  name: w1-settings
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  defaultSecuritySetting:
    authenticationSettings:
      trafficMode: REQUIRED
  defaultTrafficSetting:
    egress:
      host: bookinfo-perimeter/tsb-egress
```

This other example sets the defaults for east-west traffic configuring gateways
for two different app groups.
The first setting configures the gateway from the namespace `platinum` to manage the traffic
for all those workloads with the labels `tier: platinum` and `critical: true`.
The second one configures the gateway from the namespace `internal` to manage the traffic
for all those workloads with the labels `app: eshop` or `internal-critical: true`.
Setting up multiple east-west gateways allows isolating also the cross-cluster traffic.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  name: w1-settings
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  defaultEastWestGatewaySettings:
  - workloadSelector:
      namespace: platinum
      labels:
        app: eastwest-gw
    exposedServices:
    - serviceLabels:
        tier: platinum
        critical: "true"
  - workloadSelector:
      namespace: internal
      labels:
        app: eastwest-gw
    exposedServices:
    - serviceLabels:
        app: eshop
    - serviceLabels:
        internal-critical: "true"
```
```

This example configures the workspace settings for different workspaces
with a list of gateway hosts that they can reach.
The first setting configures the hostname `echo-1.tetrate.io`
which is reachable from workspace w1.
The second setting configures the hostnames `echo-1.tetrate.io` and
`echo-2.tetrate.io` which are reachable from workspace w2.
The thrid setting configures nothing.
The fourth setting configures an empty hostname list.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  name: w1-settings
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  hostsReachability:
    hostnames:
    - echo-1.tetrate.io
```

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  name: w2-settings
  workspace: w2
  tenant: mycompany
  organization: myorg
spec:
  hostsReachability:
    hostnames:
    - echo-1.tetrate.io
    - echo-2.tetrate.io
```

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  name: w3-settings
  workspace: w3
  tenant: mycompany
  organization: myorg
spec:
```

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  name: w4-settings
  workspace: w4
  tenant: mycompany
  organization: myorg
spec:
  hostsReachability:
    hostnames: []
```
From the above settings, here's a summary of the host reachability:
`echo-1.tetrate.io` host is reachable from namespaces configured in w1, w2 and w3.
`echo-2.tetrate.io` host is reachable from namespaces configured in w2 and w3.
All hosts are reachable from namespaces configured in workspace w3.
Workspace w4 has no access to any hosts.





## WorkspaceSetting {#tetrateio-api-tsb-v2-workspacesetting}

Default security and traffic settings for all proxy workloads in the workspace.



  
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

[tetrateio.api.tsb.security.v2.SecuritySetting](../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-securitysetting) <br/> Security settings for all proxy workloads in this workspace.
This can be overridden at security group's SecuritySetting for specific cases.
The override strategy used will be driven by the SecuritySetting propagation strategy.
The default propagation strategy is `REPLACE`, in which a lower level SecuritySetting in the configuration
hierarchy replaces a higher level SecuritySetting defined in the configuration hierarchy.
Proxy workloads without a specific security group will inherit these settings. If
omitted, the following semantics apply:

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

[tetrateio.api.tsb.traffic.v2.TrafficSetting](../../tsb/traffic/v2/traffic_setting#tetrateio-api-tsb-traffic-v2-trafficsetting) <br/> Traffic settings for all proxy workloads in this workspace. Proxy workloads
without a specific traffic group will inherit these settings. If
omitted, the following semantics apply:

1. Sidecars will be able to reach any service in the
cluster, i.e. reachability mode defaults to `CLUSTER`.

2. Traffic to unknown destinations will be directly routed from
the sidecar to the destination.

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

List of [tetrateio.api.tsb.types.v2.RegionalFailover](../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-regionalfailover) <br/> Locality routing settings for all gateways in the workspace. Overrides any global settings.

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


defaultEastWestGatewaySettings

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.EastWestGateway](../../tsb/gateway/v2/eastwest_gateway#tetrateio-api-tsb-gateway-v2-eastwestgateway) <br/> Default east west gateway settings specifies workspace-wide east-west gateway configuration.
This is used to configure east-west routing (required for fail-over) for the services that
are not exposed on the gateways. All the services matching the specified criteria is picked
up for exposing on the east-west gateway workload selected by the workload selector. In case,
a service matches selectors in multiple items, the one which comes first is picked up.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hostsReachability

</td>

<td>

[tetrateio.api.tsb.gateway.v2.HostsReachability](../../tsb/gateway/v2/gateway_common#tetrateio-api-tsb-gateway-v2-hostsreachability) <br/> Hosts reachability defines the list of hostnames that this workspace can reach.
In multicluster deployments, hostnames are reachable to all namespaces(`*`) by default.
However, this may not always be necessary, as clients may only be present in a few namespaces.
By configuring this, a list of namespaces can be limited to the namespaces configured in the workspace.
A hostname can be reachable from multiple workspaces.
If more than one workspace is configured for the same hostname,
the hostname is exported to the union of all namespaces configured in each workspace.
Workspaces with no hosts reachability configuration are considered to have reachable to all hosts.
Workspaces with explicitly empty hostnames are considered to not want to see any hosts.
Namespaces that are not part of any workspaces are also considered to have reachable to all hosts.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



