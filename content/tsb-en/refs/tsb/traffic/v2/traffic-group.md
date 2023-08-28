---
title: Traffic Group
description: Configurations to group a set of proxy workloads in a workspace for traffic management.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Traffic Groups allow grouping the proxy workloads in a set of namespaces
owned by its parent workspace. Networking and routing related
configurations can then be applied on the group to control the
behavior of these proxy workloads. The group can be in one of two modes:
`BRIDGED` and `DIRECT`. `BRIDGED` mode is a minimalistic mode that
allows users to quickly configure the most commonly used features
in the service mesh using Tetrate specific APIs, while the `DIRECT`
mode provides more flexibility for power users by allowing them to
configure the proxy workload behavior using a restricted subset of Istio
Networking APIs.

The following example creates a traffic group for the proxy workloads in
`ns1`, `ns2` and `ns3` namespaces owned by its parent workspace
`w1` under tenant `mycompany` and sets up a `TrafficSetting`
defining the resilience properties for proxy workloads in these
namespaces.

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  name: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelector:
    names:
    - "*/ns1"
    - "*/ns2"
    - "*/ns3"
  configMode: BRIDGED
```

And the associated traffic settings for the proxy workloads in the group

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: TrafficSetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  resilience:
    circuitBreakerSensitivity: MEDIUM
```

Under the hood, Service Bridge translates these minimalistic
settings into Istio APIs such as `Sidecar`, `DestinationRule`,
etc. for the namespaces managed by the traffic group. These APIs
are then pushed to the Istio control planes of clusters where the
workspace is applicable.

It is possible to create a traffic group for namespaces in a
specific cluster as long as the parent workspace owns those
namespaces in that cluster. For example,

```yaml
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
metadata:
  name: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  namespaceSelector:
    names:
    - "c1/ns1" # pick ns1 namespace only from c1 cluster
    - "*/ns2"
    - "*/ns3"
  configMode: BRIDGED
```

In the `DIRECT` mode, it is possible to directly attach Istio APIs
such as `VirtualService`, `DestinationRule`, and `Sidecar` to the
traffic group. These configurations will be validated for
correctness and conflict free operations and then pushed to the
appropriate Istio control planes.

The following example declares a `DestinationRule` with two
subsets, for the `ratings` service in the `ns1` namespace:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: ratings-subsets
  namespace: ns1
  annotations:
    tsb.tetrate.io/organization: myorg
    tsb.tetrate.io/tenant: mycompany
    tsb.tetrate.io/workspace: w1
    tsb.tetrate.io/trafficGroup: t1
spec:
  host: ratings.ns1.svc.cluster.local
  subsets:
  - name: stableversion
    labels:
      app: ratings
      env: prod
  - name: testversion
    labels:
      app: ratings
      env: uat
```

The namespace where the Istio APIs are applied will need to be part
of the parent traffic group. In addition, each API object will need
to have annotations to indicate the organization, tenant, workspace and the
traffic group to which it belongs to.





## Group {#tetrateio-api-tsb-traffic-v2-group}

A traffic group manages the routing properties of proxy workloads in a
group of namespaces owned by the parent workspace.



  
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


namespaceSelector

</td>

<td>

[tetrateio.api.tsb.types.v2.NamespaceSelector](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-namespaceselector) <br/> _REQUIRED_ <br/> Set of namespaces owned exclusively by this group. If omitted,
applies to all resources owned by the workspace. Use `*/*` to
claim all cluster resources under the workspace.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


configMode

</td>

<td>

[tetrateio.api.tsb.types.v2.ConfigMode](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-configmode) <br/> The Configuration types that will be added to this
group. `BRIDGED` mode indicates that configurations added to this
group will use Tetrate APIs such as `TrafficSetting` and
`ServiceRoute`. `DIRECT` mode indicates that configurations added
to this group will use Istio Networking APIs such as
`VirtualService`, `DestinationRule`, and `Sidecar`. Defaults to
`BRIDGED` mode.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


deletionProtectionEnabled

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When set, prevents the resource from being deleted. In order to delete the resource this
property needs to be set to `false` first.

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

[tetrateio.api.tsb.types.v2.ConfigGenerationMetadata](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-configgenerationmetadata) <br/> Default metadata values that will be propagated to the children Istio generated configurations.
When using YAML APIs like`tctl` or `gitops`, put them into the `metadata.labels` or
`metadata.annotations` instead.
This field is only necessary when using gRPC APIs directly.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



