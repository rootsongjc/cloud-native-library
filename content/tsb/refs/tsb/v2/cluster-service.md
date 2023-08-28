---
title: Cluster Service
description: Service to manage clusters onboarded in TSB.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage clusters onboarded in TSB.


## Clusters {#tetrateio-api-tsb-v2-clusters}

The Clusters service exposes methods to manage the registration of clusters that are
managed by TSB.
Before TSB can takeover networking for a given cluster, it must be onboarded in the
platform. This onboarding process usually involves two steps:

 1. Creating the cluster object so the platform knows about it.
 2. Generate the agent tokens for the cluster, so the TSB agents installed in the
    actual cluster can talk to TSB.

Once a cluster has been onboarded into TSB, it will start receiving configuration updates
from the management plane, and the agents will keep the management updated with the
status of the cluster.


### CreateCluster

<PanelContent>
<PanelContentCode>

rpc CreateCluster ([tetrateio.api.tsb.v2.CreateClusterRequest](../../tsb/v2/cluster_service#tetrateio-api-tsb-v2-createclusterrequest)) returns ([tetrateio.api.tsb.v2.Cluster](../../tsb/v2/cluster#tetrateio-api-tsb-v2-cluster))

</PanelContentCode>

**Requires** CREATE

Creates a new cluster object in TSB. This is needed during cluster onboarding to let the
management plane know about the existence of a cluster.
Once a cluster has been created and fully onboarded, the management plane will manage the
mesh for that cluster and keep this cluster entity up to date with the information that is
reported by the cluster agents.
This method returns the created cluster, that will be continuously updated by the local
cluster agents. This entity can be monitored to have an overview of the resources (namespaces,
services, etc) that are known to be running in the cluster.

This action will also create a service account with permissions to manage this cluster.
This service account (aka cluster service account) can be used in the ControlPlane installation to
authenticate it through the ManagementPlane.

As part of the response, a template will be provided (in the field `installTemplate`) with minimum
configuration to be able to install the TSB Operator in the cluster running as ControlPlane.
This data is not stored and will be only available in the response of this action.

</PanelContent>

### GetCluster

<PanelContent>
<PanelContentCode>

rpc GetCluster ([tetrateio.api.tsb.v2.GetClusterRequest](../../tsb/v2/cluster_service#tetrateio-api-tsb-v2-getclusterrequest)) returns ([tetrateio.api.tsb.v2.Cluster](../../tsb/v2/cluster#tetrateio-api-tsb-v2-cluster))

</PanelContentCode>

**Requires** READ

Get the last known state for an onboarded cluster.
Once a cluster has been onboarded into the platform, the agents will keep it up to date with
its runtime status. Getting the cluster object will return the last known snapshot of existing
namespaces and services running in it.

</PanelContent>

### UpdateCluster

<PanelContent>
<PanelContentCode>

rpc UpdateCluster ([tetrateio.api.tsb.v2.Cluster](../../tsb/v2/cluster#tetrateio-api-tsb-v2-cluster)) returns ([tetrateio.api.tsb.v2.Cluster](../../tsb/v2/cluster#tetrateio-api-tsb-v2-cluster))

</PanelContentCode>

**Requires** WRITE

Modify an existing cluster.
Updates a cluster with the given data. Note that most of the data in the cluster is read-only and
automatically populated by the local cluster agents.

</PanelContent>

### ListClusters

<PanelContent>
<PanelContentCode>

rpc ListClusters ([tetrateio.api.tsb.v2.ListClustersRequest](../../tsb/v2/cluster_service#tetrateio-api-tsb-v2-listclustersrequest)) returns ([tetrateio.api.tsb.v2.ListClustersResponse](../../tsb/v2/cluster_service#tetrateio-api-tsb-v2-listclustersresponse))

</PanelContentCode>



Get the list of all clusters that have been onboarded into the platform.

</PanelContent>

### DeleteCluster

<PanelContent>
<PanelContentCode>

rpc DeleteCluster ([tetrateio.api.tsb.v2.DeleteClusterRequest](../../tsb/v2/cluster_service#tetrateio-api-tsb-v2-deleteclusterrequest)) returns ([google.protobuf.Empty](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Empty))

</PanelContentCode>

**Requires** DELETE

Unregisters a cluster from the platform.
Deleting a cluster will unregister it from the management plane, and the agents will stop receiving
configuration updates. Agent tokens for the cluster are revoked as well, so agents that are still
running will fail to report back cluster status to the management plane.
Note that unregistering the cluster is a management plane only operation. This does not uninstall
the agents from the local cluster. Agents will continue running and the services that are deployed
in that cluster will be able to continue operating with the last applied configuration.
Unregistering a cluster from the management plane should not generate downtime to services that are
running on that cluster.

</PanelContent>

### GenerateTokens

<PanelContent>
<PanelContentCode>

rpc GenerateTokens ([tetrateio.api.tsb.v2.GenerateTokensRequest](../../tsb/v2/cluster_service#tetrateio-api-tsb-v2-generatetokensrequest)) returns ([tetrateio.api.tsb.v2.ClusterStatus](../../tsb/v2/cluster#tetrateio-api-tsb-v2-clusterstatus))

</PanelContentCode>

**Requires** WriteCluster

Generate the tokens for the cluster agents so they can talk to the management plane.
Once a cluster object has been registered in the management plane, this method can be used to
generate the JWT tokens that need to be configured in the local cluster agents in order to let
them talk to the management plane.
These tokens contain the necessary permissions to allow the agents to download the configuration
for their cluster and to push cluster status updates to the management plane.

</PanelContent>






## CreateClusterRequest {#tetrateio-api-tsb-v2-createclusterrequest}

Request to create a cluster and register it in the management plane so configuration can
be generated for it.



  
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


parent

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource where the cluster will be created. This is the FQN of the organization or the tenant.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The short name for the resource to be created.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


cluster

</td>

<td>

[tetrateio.api.tsb.v2.Cluster](../../tsb/v2/cluster#tetrateio-api-tsb-v2-cluster) <br/> _REQUIRED_ <br/> Details of the cluster to be created.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## DeleteClusterRequest {#tetrateio-api-tsb-v2-deleteclusterrequest}

Request to delete a cluster.



  
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


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the cluster.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GenerateTokensRequest {#tetrateio-api-tsb-v2-generatetokensrequest}

Request to generate the cluster agent tokens.



  
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


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the cluster.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GetClusterRequest {#tetrateio-api-tsb-v2-getclusterrequest}

Request to retrieve a cluster.



  
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


fqn

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the cluster.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


fetchWorkloads

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Flag to fetch the workload information as well.
Note that by default workload information is not returned as it may be expensive to retrieve.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


includeInstallTemplate

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Flag to return the install template required to install this cluster.
This will generate a new API key pair for the cluster service account.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListClustersRequest {#tetrateio-api-tsb-v2-listclustersrequest}

Request to list clusters.



  
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


parent

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Parent resource to list clusters from. This is the FQN of the organization or the tenant.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


fetchWorkloads

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Flag to fetch the workload information for all the clusters as well.
Note that by default workload information is not returned as it may be expensive to retrieve.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListClustersResponse {#tetrateio-api-tsb-v2-listclustersresponse}

List of clusters that are registered in the platform.



  
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


clusters

</td>

<td>

List of [tetrateio.api.tsb.v2.Cluster](../../tsb/v2/cluster#tetrateio-api-tsb-v2-cluster) <br/> The list of clusters that are registered in the platform.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



