---
title: Workload Registration
description: Information sent by the Workload Onboarding Agent to the Workload Onboarding Plane to register the workload in the mesh.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Workload Registration specifies information sent by the Workload Onboarding Agent to the Workload Onboarding Plane
to register the workload in the mesh.





## AgentInfo {#tetrateio-api-onboarding-config-types-registration-v1alpha1-agentinfo}

AgentInfo specifies information about the `Workload Onboarding Agent`
installed alongside the workload.



  
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


version

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Version of the `Workload Onboarding Agent`.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## IstioSidecarInfo {#tetrateio-api-onboarding-config-types-registration-v1alpha1-istiosidecarinfo}

IstioInfo specifies information about the `Istio Sidecar` installed
alongside the workload.



  
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


version

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Version of the `Istio Sidecar`.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


revision

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Istio revision the pre-installed `Istio Sidecar` corresponds to.

E.g., `canary`, `alpha`, etc.

If omitted, it is assumed that the pre-installed `Istio Sidecar`
corresponds to the `default` Istio revision.

Notice that the value constraints here are stricter than the ones in Istio.
Apparently, Istio validation rules allow values that lead to internal failures
at runtime, e.g. values with capital letters or values longer than 56 characters.
Stricter validation rules here are meant to prevent those hidden pitfalls.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>&nbsp;&nbsp;max_len: `56`<br/>&nbsp;&nbsp;pattern: `^[a-z0-9](?:[-a-z0-9]*[a-z0-9])?$`<br/>&nbsp;&nbsp;ignore_empty: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## Registration {#tetrateio-api-onboarding-config-types-registration-v1alpha1-registration}

Registration specifies information sent by the `Workload Onboarding Agent`
to the `Workload Onboarding Plane` to register the workload in the mesh.



  
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


agent

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.AgentInfo](../../../../../onboarding/config/types/registration/v1alpha1/registration#tetrateio-api-onboarding-config-types-registration-v1alpha1-agentinfo) <br/> _REQUIRED_ <br/> Information about the `Workload Onboarding Agent` installed alongside
the workload.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


sidecar

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.SidecarInfo](../../../../../onboarding/config/types/registration/v1alpha1/registration#tetrateio-api-onboarding-config-types-registration-v1alpha1-sidecarinfo) <br/> _REQUIRED_ <br/> Information about the sidecar installed alongside the workload.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


host

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.HostInfo](../../../../../onboarding/config/types/registration/v1alpha1/hostinfo#tetrateio-api-onboarding-config-types-registration-v1alpha1-hostinfo) <br/> _REQUIRED_ <br/> Information about the host the workload is running on.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


workload

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.WorkloadInfo](../../../../../onboarding/config/types/registration/v1alpha1/registration#tetrateio-api-onboarding-config-types-registration-v1alpha1-workloadinfo) <br/> Information about the workload.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


settings

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.Settings](../../../../../onboarding/config/types/registration/v1alpha1/registration#tetrateio-api-onboarding-config-types-registration-v1alpha1-settings) <br/> Registration settings.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Settings {#tetrateio-api-onboarding-config-types-registration-v1alpha1-settings}

Settings specifies registration settings.



  
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


connectedOver

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.AddressType](../../../../../onboarding/config/types/registration/v1alpha1/hostinfo#tetrateio-api-onboarding-config-types-registration-v1alpha1-addresstype) <br/> ConnectedOver specifies how the workload is connected to the mesh, i.e.
over `VPC` or over `Internet`.
When unspecified, workload is assumed connected to the mesh over `VPC`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## SidecarInfo {#tetrateio-api-onboarding-config-types-registration-v1alpha1-sidecarinfo}

SidecarInfo specifies information about the sidecar installed alongside
the workload.



  
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


istio

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.IstioSidecarInfo](../../../../../onboarding/config/types/registration/v1alpha1/registration#tetrateio-api-onboarding-config-types-registration-v1alpha1-istiosidecarinfo) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> kind</sup>_ <br/> Information about the `Istio Sidecar` installed alongside the workload.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## WorkloadInfo {#tetrateio-api-onboarding-config-types-registration-v1alpha1-workloadinfo}

WorkloadInfo specifies information about the workload.



  
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


labels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Labels associated with the workload.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



