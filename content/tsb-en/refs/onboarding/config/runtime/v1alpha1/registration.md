---
title: Workload Auto Registration
description: Registry record of a workload onboarded into the mesh.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

`Workload Auto Registration` represents a registry record of a workload
onboarded into the mesh.

`Workload Auto Registration` captures essential information about the workload
allowing `Workload Onboarding Plane` to generate boot configuration for the
`Istio Sidecar` that will be started alongside this workload.

`WorkloadAutoRegistration` resource is not supposed to be edited by the users.
Instead, it gets created automatically as part of the `Workload Onboarding`
flow.

Users can introspect `WorkloadAutoRegistration` resources for the purposes of
observability and troubleshooting of `Workload Onboarding`.

To leverage k8s resource garbage collection (i.e. cascade removal),

* `WorkloadAutoRegistration` resource is owned by the
  [WorkloadGroup](https://istio.io/latest/docs/reference/config/networking/workload-group/)
  resource the workload has joined to
* `WorkloadAutoRegistration` resource owns the Istio
  [WorkloadEntry](https://istio.io/latest/docs/reference/config/networking/workload-entry/)
  resource that describes the workload to the `Istio` Control Plane.

```text
WorkloadGroup
|
| (owns)
|
└── WorkloadAutoRegistration
    |
    | (owns)
    |
    └── WorkloadEntry
```

E.g.,

```yaml
apiVersion: runtime.onboarding.tetrate.io/v1alpha1
kind: WorkloadAutoRegistration
metadata:
  namespace: bookinfo
  name: ratings-aws-aws-123456789012-ca-central-1b-ec2-i-1234567890abcdef0
  ownerReferences:
  - apiVersion: networking.istio.io/v1beta1
    blockOwnerDeletion: true
    controller: true
    kind: WorkloadGroup
    name: ratings
    uid: fb67dbad-b063-40e5-a958-098fbe7b40f4
spec:
  identity:
    aws:
      partition: aws
      account: '123456789012'
      region: ca-central-1
      zone: ca-central-1b
      ec2:
        instance_id: i-1234567890abcdef0
  registration:
    agent:
      version: '1.4.0'
    sidecar:
      istio:
        version: '1.8.5-abcd'
    host:
      addresses:
      - ip: 10.0.0.1
        type: VPC
      - ip: 1.2.3.4
        type: INTERNET
    workload:
      labels:
        cloud: aws
        class: ec2
        version: v3
    settings:
      connectedOver: INTERNET
status:
  activeAgentConnection:
    connectedTo: onboarding-plane-745bf76677-974tq
  conditions:
  - type: AgentConnected
    status: True
    reason: ConnectionEstablished
    lastTransitionTime: "2020-12-02T18:26:08Z"
```





## AgentConnection {#tetrateio-api-onboarding-config-runtime-v1alpha1-agentconnection}

AgentConnection specifies information about the persistent connection between
the `Workload Onboarding Agent` and a `Workload Onboarding Plane` instance.



  
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


connectedTo

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Identifier of the `Workload Onboarding Plane` instance the `Agent` is
connected to.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## WorkloadAutoRegistrationSpec {#tetrateio-api-onboarding-config-runtime-v1alpha1-workloadautoregistrationspec}

WorkloadAutoRegistrationSpec is the specification of the workload's
registration within the mesh.



  
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


identity

</td>

<td>

[tetrateio.api.onboarding.config.types.identity.v1alpha1.WorkloadIdentity](../../../../onboarding/config/types/identity/v1alpha1/identity#tetrateio-api-onboarding-config-types-identity-v1alpha1-workloadidentity) <br/> _REQUIRED_ <br/> Platform-specific identity of the workload.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


registration

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.Registration](../../../../onboarding/config/types/registration/v1alpha1/registration#tetrateio-api-onboarding-config-types-registration-v1alpha1-registration) <br/> _REQUIRED_ <br/> Workload registration information.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


## WorkloadAutoRegistrationStatus {#tetrateio-api-onboarding-config-runtime-v1alpha1-workloadautoregistrationstatus}

WorkloadAutoRegistrationStatus represents the current status of the
workload's registration within the mesh.



  
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


observedGeneration

</td>

<td>

[int64](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The most recent generation observed by the `WorkloadAutoRegistration`
controller.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


conditions

</td>

<td>

List of [tetrateio.api.onboarding.config.types.core.v1alpha1.Condition](../../../../onboarding/config/types/core/v1alpha1/condition#tetrateio-api-onboarding-config-types-core-v1alpha1-condition) <br/> Currently observed conditions.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;items: `{message:{required:true}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


activeAgentConnection

</td>

<td>

[tetrateio.api.onboarding.config.runtime.v1alpha1.AgentConnection](../../../../onboarding/config/runtime/v1alpha1/registration#tetrateio-api-onboarding-config-runtime-v1alpha1-agentconnection) <br/> Information about the active persistent connection between the
`Workload Onboarding Agent` and a `Workload Onboarding Plane` instance.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



