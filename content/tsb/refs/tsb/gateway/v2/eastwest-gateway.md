---
title: East/West Gateway
description: Configuration for east/west gateway settings
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Configuration for east/west gateway settings





## EastWestGateway {#tetrateio-api-tsb-gateway-v2-eastwestgateway}

EastWestGateway is for configuring a gateway to handle east-west traffic of
the services that are not exposed through Ingress or Tier1 gateways (internal
services). Currently, this is restricted to specifying at Workspace level
in WorkspaceSetting.



  
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


exposedServices

</td>

<td>

List of [tetrateio.api.tsb.types.v2.ServiceSelector](../../../tsb/types/v2/types#tetrateio-api-tsb-types-v2-serviceselector) <br/> Exposed services is used to specify the match criteria to select specific services
for internal multicluster routing (east-west routing between clusters).
If it is not defined or contains no elements, all the services within the workspace
will be exposed to the configured gateway.

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
  



