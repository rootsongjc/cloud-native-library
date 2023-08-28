---
title: Security Group
description: Configurations to group a set of proxy workloads in a workspace for security.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Security Groups allow grouping the proxy workloads in a set of namespaces
owned by its parent workspace. Security related configurations can
then be applied on the group to control the behavior of these
proxy workloads. The group can be in one of two modes: `BRIDGED` and
`DIRECT`. `BRIDGED` mode is a minimalistic mode that allows users to
quickly configure the most commonly used features in the service
mesh using Tetrate specific APIs, while the `DIRECT` mode provides
more flexibility for power users by allowing them to configure the
proxy workload's security properties using a restricted subset of Istio
Security APIs.

The following example creates a security group for the proxy workloads in
`ns1`, `ns2` and `ns3` namespaces owned by its parent workspace
`w1` under tenant `mycompany`

```yaml
apiVersion: security.tsb.tetrate.io/v2
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

And the associated security settings for the proxy workloads in the group

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: SecuritySetting
metadata:
  name: defaults
  group: t1
  workspace: w1
  tenant: mycompany
  organization: myorg
spec:
  authentication: REQUIRED
```

Under the hood, Service Bridge translates these minimalistic
settings into Istio APIs such as `PeerAuthentication`,
`AuthorizationPolicy`, etc. for the namespaces managed by the
security group. These APIs are then pushed to the Istio control
planes of clusters where the workspace is applicable.

It is possible to create a security group for namespaces in a
specific cluster as long as the parent workspace owns those
namespaces in that cluster. For example,

```yaml
apiVersion: security.tsb.tetrate.io/v2
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

In the `DIRECT` mode, it is possible to directly attach Istio
Security v1beta1 APIs - `PeerAuthentication`, and
`AuthorizationPolicy` to the security group. These configurations
will be validated for correctness and conflict free operations and
then pushed to the appropriate Istio control planes.

The following example declares a `PeerAuthentication` policy for a
specific workload in the `ns1` namespace:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: workload-mtls-disable
  namespace: ns1
  annotations:
    tsb.tetrate.io/organization: myorg
    tsb.tetrate.io/tenant: mycompany
    tsb.tetrate.io/workspace: w1
    tsb.tetrate.io/securityGroup: t1
spec:
  selector:
    matchLabels:
      app: reviews
  mtls:
    mode: DISABLE
```

The namespace where the Istio APIs are applied will need to be part
of the parent security group. In addition, each API object will need
to have annotations to indicate the organization, tenant, workspace and the
security group to which it belongs to.





## Group {#tetrateio-api-tsb-security-v2-group}

A security group manages the security properties of proxy workloads in a
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
group will use Tetrate APIs such as `SecuritySetting`. `DIRECT`
mode indicates that configurations added to this group will use
Istio Security v2beta1 APIs such as `PeerAuthentication`, and
`AuthorizationPolicy`. Defaults to `BRIDGED` mode.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


securityDomain

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Security domains can be used to group different resources under the same security domain.
Although security domain is not resource itself currently, it follows a fqn format
`organizations/myorg/securitydomains/mysecuritydomain`, and a child cannot override any ancestor's
security domain.
Once a security domain is assigned to a _Security group_, all the children resources will belong to that
security domain in the same way a _Security setting_ belongs to a _Security group_, a _Security setting_
will also belong to the security domain assigned to the _Security group_.
Security domains can also be used to define _Security settings Authorization rules_ in which you can allow
or deny request from or to a security domain.

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
  



