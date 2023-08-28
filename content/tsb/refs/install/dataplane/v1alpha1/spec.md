---
title: Data Plane
description: Configuration to describe components in the TSB data plane.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

A minimal resource should have an empty spec.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo
  namespace: bookinfo
spec: {}
```

To configure infrastructure specific settings such as the service type, set
the relevant field in kubeSpec. Remember that the installation API is an
override API so if these fields are unset the operator will use sensible
defaults. Only a subset of Kubernetes configuration is available.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      type: NodePort
```

`EgressGateway` and `Tier1Gateway` are configured in the same manner.





## EgressGatewaySpec {#tetrateio-api-install-dataplane-v1alpha1-egressgatewayspec}

EgressGatewaySpec defines the desired installed state of a single egress
gateway for a given namespace in Service Bridge. Specifying a minimal
EgressGatewaySpec with a hub will create a default gateway with sensible
values.



  
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


connectionDrainDuration

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The amount of time the gateway will wait on shutdown for connections to
complete before terminating the gateway. During this drain period, no new
connections can be created but existing ones are allowed complete.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


revision

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Specifies the istio revision to reconcile with.
If specified, TSB control plane operator will reconcile this gateway only
if operator's revision matches with it. TSB data plane operator, which
would be running only when TSB control plane operator is not configured a
revision, will ignore revision field and will reconcile gateway as usual.
Internally, this revision will guide to pick matching istio control plane
for the gateway deployment
https://istio.io/latest/blog/2020/multiple-control-planes/#configuring

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## IngressGatewaySpec {#tetrateio-api-install-dataplane-v1alpha1-ingressgatewayspec}

IngressGatewaySpec defines the desired installed state of a single ingress
gateway for a given namespace in Service Bridge. Specifying a minimal
IngressGatewaySpec with a hub will create a default gateway with sensible
values.



  
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


connectionDrainDuration

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The amount of time the gateway will wait on shutdown for connections to
complete before terminating the gateway. During this drain period, no new
connections can be created but existing ones are allowed complete.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


revision

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Specifies the istio revision to reconcile with.
If specified, TSB control plane operator will reconcile this gateway only
if operator's revision matches with it. TSB data plane operator, which
would be running only when TSB control plane operator is not configured a
revision, will ignore revision field and will reconcile gateway as usual.
Internally, this revision will guide to pick matching istio control plane
for the gateway deployment
https://istio.io/latest/blog/2020/multiple-control-planes/#configuring

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


eastWestOnly

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If set to true, the ingress gateway will be configured for east west routing only.
This means that only port 15443 will be exposed.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Tier1GatewaySpec {#tetrateio-api-install-dataplane-v1alpha1-tier1gatewayspec}

Tier1GatewaySpec defines the desired installed state of a single tier 1
gateway for a given namespace in Service Bridge. Specifying a minimal
Tier1GatewaySpec with a hub will create a default gateway with sensible
values.



  
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


connectionDrainDuration

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The amount of time the gateway will wait on shutdown for connections to
complete before terminating the gateway. During this drain period, no new
connections can be created but existing ones are allowed complete.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


revision

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Specifies the istio revision to reconcile with.
If specified, TSB control plane operator will reconcile this gateway only
if operator's revision matches with it. TSB data plane operator, which
would be running only when TSB control plane operator is not configured a
revision, will ignore revision field and will reconcile gateway as usual.
Internally, this revision will guide to pick matching istio control plane
for the gateway deployment
https://istio.io/latest/blog/2020/multiple-control-planes/#configuring

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



