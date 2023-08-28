---
title: Egress Gateway
description: Configurations to build an egress gateway.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`EgressGateway` configures a workload to act as a gateway for
traffic exiting the mesh. The egress gateway is meant to be the destination
of unknown traffic within the mesh (traffic sent to non-mesh services). The
gateway allows authorization control of traffic sent to it to more finely tune
which services are allowed to send unknown traffic through the gateway. Only HTTP
is supported at this time.

The following example declares an egress gateway running on pods in istio-system
with the label app=istio-egressgateway. This gateway is setup to allow traffic
from anywhere in the cluster to access www.httpbin.org and from the bookinfo details app
specifically, you can access any external host. `EgressGateway`s need to be paired
with `TrafficSetting`s in order to be usable. You must set the `egress` field in the
`TrafficSetting`s to point to the egress gateway and send traffic to port 15443. Once
this is set up, mesh internal apps will send unknown traffic to the egress gateway over mTLS.
The gateway will then decide whether to forward the traffic or not, and use one-way TLS for
external calls.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: EgressGateway
metadata:
  name: my-egress
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1 
    labels:
      app: istio-egressgateway
  authorization:
    - from:
        mode: WORKSPACE
      to: ["www.httpbin.org"]
    - from:
        mode: CUSTOM
        serviceAccounts: ["default/bookinfo-details"]
      to: ["*"]
```
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
  reachability:
   mode: CUSTOM
   hosts:
   - "./*"
   - "istio-system/*"
  egress:
    host: istio-system/istio-egressgateway.istio-system.svc.cluster.local
```

The following example customizes the `Extensions` field to enable
the execution of the specified WasmExtensions list and details
custom properties for the execution of each extension.
```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: EgressGateway
metadata:
  name: my-egress
  group: g1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  workloadSelector:
    namespace: ns1
    labels:
      app: istio-egressgateway
  authorization:
    - from:
        mode: WORKSPACE
      to: ["www.httpbin.org"]
    - from:
        mode: CUSTOM
        serviceAccounts: ["default/bookinfo-details"]
      to: ["*"]
  extension:
  - fqn: hello-world # fqn of imported extensions in TSB
    config:
      foo: bar
```





## EgressAuthorization {#tetrateio-api-tsb-gateway-v2-egressauthorization}

EgressAuthorization is used to dictate which service accounts can access a set of external hosts



  
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


from

</td>

<td>

[tetrateio.api.tsb.security.v2.AuthorizationSettings](../../../tsb/security/v2/security_setting#tetrateio-api-tsb-security-v2-authorizationsettings) <br/> The workloads or service accounts this authorization rule applies to.
If not set, the rule applies to all workloads or service accounts.

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

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The external hostnames the workload(s) described in this rule can access.
Hosts cannot be specified more than once. Use "*" to allow access to any external host

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## EgressGateway {#tetrateio-api-tsb-gateway-v2-egressgateway}

`EgressGateway` configures a workload to act as an egress gateway in the mesh.


-->



  
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


workloadSelector

</td>

<td>

[tetrateio.api.tsb.types.v2.WorkloadSelector](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-workloadselector) <br/> _REQUIRED_ <br/> Specify the gateway workloads (pod labels and Kubernetes
namespace) under the gateway group that should be configured with
this gateway. There can be only one gateway for a workload selector in a namespace.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


authorization

</td>

<td>

List of [tetrateio.api.tsb.gateway.v2.EgressAuthorization](../../../tsb/gateway/v2/egress_gateway#tetrateio-api-tsb-gateway-v2-egressauthorization) <br/> The description of which service accounts can access which hosts.
If the list of authorization rules is empty, this egress gateway will deny all traffic.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


extension

</td>

<td>

List of [tetrateio.api.tsb.types.v2.WasmExtensionAttachment](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-wasmextensionattachment) <br/> Extensions specifies all the WasmExtensions assigned to this EgressGateway
with the specific configuration for each extension. This custom configuration
will override the one configured globally to the extension.
Each extension has a global configuration including enablement and priority
that will condition the execution of the assigned extensions.

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
  



