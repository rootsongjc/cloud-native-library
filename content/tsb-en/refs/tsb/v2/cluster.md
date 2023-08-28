---
title: Clusters
description: Configuration for onboarding clusters.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Each Kubernetes cluster managed by Service Bridge should be
onboarded first before configurations can be applied to the
services in the cluster. Onboarding a cluster is a two step
process. First, create a cluster object under the appropriate
tenant. Once a cluster object is created, its status field should
provide the set of join tokens that will be used by the Service
Bridge agent on the cluster to talk to Service Bridge management
plane. The second step is to deploy the Service Bridge agent on the
cluster with the join tokens and deploy Istio on the cluster. The
following example creates a cluster named c1 under the tenant
mycompany, indicating that the cluster is deployed on a network
"vpc-01" corresponding to the AWS VPC where it resides.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: c1
  organization: myorg
  labels:
    env: uat-demo
spec:
  tokenTtl: "1h"
  network: vpc-01
```

Note that configuration profiles such as traffic, security and
gateway groups will flow to the Bridge agents in the cluster as
long their requested cluster exists in the Service Bridge
hierarchy.





## Cluster {#tetrateio-api-tsb-v2-cluster}

A Kubernetes cluster managing both pods and VMs.



  
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


tokenTtl

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Lifetime of the tokens. Defaults to 1hr.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


network

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The network (e.g., VPC) where this cluster is present. All
clusters within the same network will be assumed to be reachable
for the purposes of multi-cluster routing. In addition, networks
marked as reachable from one another in SystemSettings will also
be used for multi-cluster routing.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tier1Cluster

</td>

<td>

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> Indicates whether this cluster is hosting a tier1 gateway or not.
Tier1 clusters cannot host other gateways or workloads. Defaults
to false if not specified.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


locality

</td>

<td>

[tetrateio.api.tsb.v2.Locality](../../tsb/v2/cluster#tetrateio-api-tsb-v2-locality) <br/> Deprecated. For backward compatibility, still honoured but will be ignored
in future releases, so better not to set it. Locality of the service
endpoints will be dynamically discovered by the xcp-edge

Location information about the cluster which can be used for routing.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


trustDomain

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Trust domain for this cluster, used for multi-cluster routing.
It must be unique for every cluster and should match the one configured in
the local control plane. This value is optional, and will be updated by the
local control plane agents. However, it is recommended to set it, if known,
so that multi-cluster routing works without having to wait for the local
control planes to update it.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespaceScope

</td>

<td>

[tetrateio.api.tsb.v2.NamespaceScoping](../../tsb/v2/cluster#tetrateio-api-tsb-v2-namespacescoping) <br/> Configure the default scoping of namespaces in this cluster.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


state

</td>

<td>

[tetrateio.api.tsb.v2.Cluster.State](../../tsb/v2/cluster#tetrateio-api-tsb-v2-cluster-state) <br/> _OUTPUT_ONLY_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceAccount

</td>

<td>

[tetrateio.api.tsb.v2.ServiceAccount](../../tsb/v2/team#tetrateio-api-tsb-v2-serviceaccount) <br/> _OUTPUT_ONLY_ <br/> The service account created with permissions to manage the current cluster.
The service account is not stored and it is only returned in the `ClusterCreate` response.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


installTemplate

</td>

<td>

[tetrateio.api.tsb.v2.Cluster.InstallTemplate](../../tsb/v2/cluster#tetrateio-api-tsb-v2-cluster-installtemplate) <br/> _OUTPUT_ONLY_ <br/> Template to be used to install this TSB cluster in the k8s cluster

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### InstallTemplate {#tetrateio-api-tsb-v2-cluster-installtemplate}

InstallTemplate provides templates ready to be used in the ControlPlane (cluster onboard) installation.



  
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


message

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> can provide useful information to the user

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


helm

</td>

<td>

[tetrateio.api.install.helm.controlplane.v1alpha1.Values](../../install/helm/controlplane/v1alpha1/values#tetrateio-api-install-helm-controlplane-v1alpha1-values) <br/> _OUTPUT_ONLY_ <br/> valid values.yaml to be used with controlplane helm chart.
This field is an alpha API, so future versions could include breaking changes.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### State {#tetrateio-api-tsb-v2-cluster-state}

State represents the cluster info learned from the onboarded cluster



  
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


lastSyncTime

</td>

<td>

[google.protobuf.Timestamp](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Timestamp) <br/> last time xcp edge(cp) synced with central(mp) in the UTC format

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


provider

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> cluster provider. Ex: GKE, EKS, AKS

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


istioVersions

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> This shows currently running istio versions in the cluster.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xcpVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> xcp-edge version which is running at the cluster

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tsbCpVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> TSB controlplane version

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


discoveredLocality

</td>

<td>

[tetrateio.api.tsb.v2.Locality](../../tsb/v2/cluster#tetrateio-api-tsb-v2-locality) <br/> Discovered locality is the locality/region of the cluster as discovered by the xcp
from the k8s endpoints

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ClusterStatus {#tetrateio-api-tsb-v2-clusterstatus}

The status message for a cluster resource contains the set of join
tokens that should be used by Service Bridge's agents on the
cluster.



  
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


tokens

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Tokens for various agents.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Locality {#tetrateio-api-tsb-v2-locality}

The region the cluster resides. Used for failover based routing when
configured in the workspace or global settings.



  
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


region

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The geographic location of the cluster.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## NamespaceScoping {#tetrateio-api-tsb-v2-namespacescoping}

Configure the default scoping of namespaces in this cluster.



  
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


scope

</td>

<td>

[tetrateio.api.tsb.v2.NamespaceScoping.Scope](../../tsb/v2/cluster#tetrateio-api-tsb-v2-namespacescoping-scope) <br/> Default scope for namespaces in this cluster (global, local)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


exceptions

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Namespaces to be excluded form the default scope.
If the scope is set to global, this list will contain namespaces that are
considered local. If the scope is set to local, this list will contain
namespaces that are considered global.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Port {#tetrateio-api-tsb-v2-service-port}





  
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


number

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> A valid non-negative integer port number.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Name assigned to the port.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kubernetesNodePort

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Indicates the node port attached to a physical deployment on a kubernetes
cluster.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Workload {#tetrateio-api-tsb-v2-workload}

Info about individual workload implementing the service.



  
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


address

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Routable address of the workload.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Instance name of the workload.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


isVm

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Indicates whether the workload is kubernetes endpoint or vm.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


proxy

</td>

<td>

[tetrateio.api.tsb.v2.Workload.Proxy](../../tsb/v2/cluster#tetrateio-api-tsb-v2-workload-proxy) <br/> Proxy details.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Proxy {#tetrateio-api-tsb-v2-workload-proxy}

Info about proxy attached to a workload.



  
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


controlPlaneAddress

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Address/service of control plane entity controlling the proxy
like istiod.istio-system.svc:15012.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


envoyVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Envoy version of the proxy.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


istioVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Istio version of the proxy.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


status

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Sync status for each xDS component.
For example:
status["CDS"] = "SYNCED"
XDS components are: LDS, RDS, EDS CDS and SRDS.
Refer to Envoy go-control-plane ConfigStatus for possible status values
values:
https://github.com/envoyproxy/go-control-plane/blob/main/envoy/service/status/v3/csds.pb.go

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




### Scope {#tetrateio-api-tsb-v2-namespacescoping-scope}




<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


GLOBAL

</td>

<td>

0

</td>

<td>

Global configures namespaces in this cluster to be considered global.
Namespaces that exist in other clusters with the same name will be
considered to be the same logical namespace.

</td>
</tr>
    
<tr>
<td>


LOCAL

</td>

<td>

1

</td>

<td>

Configures local scoping for namespaces, so that namespaces with the same
name in different clusters will not be considered the same logical
namespace.

</td>
</tr>
    
</table>
  


