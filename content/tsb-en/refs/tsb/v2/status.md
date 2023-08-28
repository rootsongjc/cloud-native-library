---
title: Status
description: Status API for TSB resources
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Each resource in TSB is able to provide a status to let the user know it's
current integrity.
Some resources, like configurations for ingress, traffic and security, are
not immediately applied as soon as TSB accepts any modification from user.
In these cases, the status will provide enough information to know when it
is really applying to the affected workloads.
This allows any user or CI/CD process to poll the status of any desired
resource and proceed accordingly.

There are two types of resources, the ones that aggregate the status of
children resources and the ones that do not. Check the documentation for the
different details object types for further information.

As an example, lets say the user pushes an `IngressGateway` configuration.
`IngressGateway` does not aggregate status of children resources, but the
other way around: its parent resource `GatewayGroup` does aggregate its
status.

When the requests succeeds in TSB server, that resource's status will reach
the `ACCEPTED` status with a TSB_ACCEPTED event in its configEvents details:

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: ResourceStatus
metadata:
  name: bookinfo-gateway
  organization: my-org
  tenant: my-tenant
  workspace: bookinfo-ws
  gatewaygroup: bookinfo-gw-group
spec:
  status: ACCEPTED
  configEvents:
    events:
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-01-11T10:11:41.784168161Z"
      type: TSB_ACCEPTED
```

Then, when pushed to MPC it succeeds and stays in `ACCEPTED` status, and the
event list reflects the new event data, which will become:

```yaml
// omiting the rest of the fields for simplicity
spec:
  status: ACCEPTED
  configEvents:
    events:
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-01-11T10:11:43.264330637Z"
      type: MPC_ACCEPTED
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-01-11T10:11:41.784168161Z"
      type: TSB_ACCEPTED
```

Later on, if there is an error in the MPC underlying layers such as XCP
Central, a new event will be propagated and appended to the resource status
that will change to status `FAILED` with the corresponding message.

```yaml
# omiting the rest of the fields for simplicity
spec:
  status: FAILED
  message: "IngressGateway.xcp.tetrate.io \"INVALID-96010ce1d9b7df5c\" is invalid: metadata.name:
    Invalid value: \"INVALID-96010ce1d9b7df5c\": a DNS-1123 subdomain must consist of lower case alphanumeric characters,
    '-' or '.', and must start and end with an alphanumeric character
    (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')"
  configEvents:
    events:
    - etag: '"sMlEWPbvm6M="'
      message: "IngressGateway.xcp.tetrate.io \"INVALID-96010ce1d9b7df5c\" is invalid: metadata.name:
        Invalid value: \"INVALID-96010ce1d9b7df5c\": a DNS-1123 subdomain must consist of lower case alphanumeric characters,
        '-' or '.', and must start and end with an alphanumeric character
        (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')"
      reason: "ValidationFailed"
      timestamp: "2022-01-11T10:11:43.444335769Z"
      type: XCP_REJECTED
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-01-11T10:11:43.264330637Z"
      type: MPC_ACCEPTED
    - etag: '"sMlEWPbvm6M="'
      timestamp: "2022-01-11T10:11:41.784168161Z"
      type: TSB_ACCEPTED
```

Another example of a status of a resource that aggregates its children
status could be the following:

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: ResourceStatus
metadata:
  name: bookinfo
  organization: tetrate
  tenant: tetrate
  workspace: bookinfo
spec:
  aggregatedStatus:
    configEvents:
      events:
      - etag: '"XAdtTSjZGic="'
        timestamp: "2022-01-11T16:50:15.571985056Z"
        type: XCP_ACCEPTED
      - etag: '"XAdtTSjZGic="'
        timestamp: "2022-01-11T16:50:15.545956009Z"
        type: MPC_ACCEPTED
      - etag: '"XAdtTSjZGic="'
        timestamp: "2022-01-11T16:50:13.547777908Z"
        type: TSB_ACCEPTED
  status: ACCEPTED
```
In case of errors, the children_errors map would be filled.

Finally, an example of a status of a non-configurable resource like a `Tenant`
would not have any details. This kind of resources don't aggregate status either.
This kind of resource will reach the `READY` status once it's request has
been processed by the TSB server.

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: ResourceStatus
metadata:
  name: tetrate
  organization: tetrate
spec:
  status: READY
```





## AggregatedStatus {#tetrateio-api-tsb-v2-aggregatedstatus}

`AggregatedStatus` is used by resources with children to aggregate both the
sequence of events and the status of its children resources.



  
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


configEvents

</td>

<td>

[tetrateio.api.tsb.v2.ConfigEvents](../../tsb/v2/status#tetrateio-api-tsb-v2-configevents) <br/> `ConfigEvents` is the list of resource events that occurred during the
lifecycle of the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


children

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [tetrateio.api.tsb.v2.AggregatedStatus.ChildStatus](../../tsb/v2/status#tetrateio-api-tsb-v2-aggregatedstatus-childstatus)> <br/> Map of children resource FQNs to their status.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


childrenStatus

</td>

<td>

[tetrateio.api.tsb.v2.AggregatedStatus.ChildStatus](../../tsb/v2/status#tetrateio-api-tsb-v2-aggregatedstatus-childstatus) <br/> Children status is a status summary of all the children statuses. If all
of them are READY, `children_status` will be READY as well. If any is not
READY, the worst status will be used for `children_status`

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### ChildStatus {#tetrateio-api-tsb-v2-aggregatedstatus-childstatus}

`ChildStatus` contains the status details for a particular child resource,
and a human-friendly message further describing the status if it is an
errored one.



  
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


status

</td>

<td>

[tetrateio.api.tsb.v2.ResourceStatus.Status](../../tsb/v2/status#tetrateio-api-tsb-v2-resourcestatus-status) <br/> Current status of the child resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


message

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Contains the human-friendly message describing the status of the child resource.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ConfigEvents {#tetrateio-api-tsb-v2-configevents}

`ConfigEvents` provides a way to notify the status of a configuration
propagation as a sequence of events.



  
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


events

</td>

<td>

List of [tetrateio.api.tsb.v2.ConfigEvents.Event](../../tsb/v2/status#tetrateio-api-tsb-v2-configevents-event) <br/> Sequence of events occurred under the configuration propagation flow.
It's ordered by event timestamp, newest first.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### EdgeConfigState {#tetrateio-api-tsb-v2-configevents-edgeconfigstate}





  
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


status

</td>

<td>

[tetrateio.api.tsb.v2.ConfigEvents.EdgeConfigStatus](../../tsb/v2/status#tetrateio-api-tsb-v2-configevents-edgeconfigstatus) <br/> Edge level config status.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


reason

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Accompanying reason when status is not `APPLIED`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Event {#tetrateio-api-tsb-v2-configevents-event}

Single `Event` event occurred in the configuration propagation flow.



  
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


type

</td>

<td>

[tetrateio.api.tsb.v2.ConfigEvents.EventType](../../tsb/v2/status#tetrateio-api-tsb-v2-configevents-eventtype) <br/> Type of the event.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


reason

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Optional code that extends the type of the occurred event.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


message

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Optional message describing the reason in a human readable way.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


timestamp

</td>

<td>

[google.protobuf.Timestamp](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Timestamp) <br/> Time of the event occurrence.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


etag

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The etag of the resource which configuration triggered this event.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


edgesState

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [tetrateio.api.tsb.v2.ConfigEvents.EdgeConfigState](../../tsb/v2/status#tetrateio-api-tsb-v2-configevents-edgeconfigstate)> <br/> Stores the `edge cluster name` to `EdgeConfigState` mapping. `EdgeConfigState` holds the
[status + reason] for a resource config that is being applied at edges.
Reason accompanying the Status is useful for pin-pointed debugging at edge level.
For instance, a config whose config status is something other than `APPLIED` is
accompanied by a reason telling why an error occurred while applying the config.
This will help in debugging issues at an edge.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ResourceStatus {#tetrateio-api-tsb-v2-resourcestatus}

`ResourceStatus` provides the current status of any TSB resource.



  
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


status

</td>

<td>

[tetrateio.api.tsb.v2.ResourceStatus.Status](../../tsb/v2/status#tetrateio-api-tsb-v2-resourcestatus-status) <br/> Current status of the resource.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


message

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> User friendly message adding details of the status.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


configEvents

</td>

<td>

[tetrateio.api.tsb.v2.ConfigEvents](../../tsb/v2/status#tetrateio-api-tsb-v2-configevents) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> details</sup>_ <br/> For resources without children resources, it provides the sequence of
events that happened during the resource status lifecycle.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


aggregatedStatus

</td>

<td>

[tetrateio.api.tsb.v2.AggregatedStatus](../../tsb/v2/status#tetrateio-api-tsb-v2-aggregatedstatus) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> details</sup>_ <br/> For resources with children, it provides both the sequence of resource
events and the children status.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




### EdgeConfigStatus {#tetrateio-api-tsb-v2-configevents-edgeconfigstatus}




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


UNKNOWN

</td>

<td>

0

</td>

<td>

`UNKNOWN` indicates an undefined status. Either the edge has not reported
the status for the config or it is not available due to some delays or something else.
This is a catch-all when we don&#39;t know what to do.

</td>
</tr>
    
<tr>
<td>


APPLIED

</td>

<td>

1

</td>

<td>

`APPLIED` indicates that the config has been successfully applied at the edge.

</td>
</tr>
    
<tr>
<td>


ERRORED

</td>

<td>

2

</td>

<td>

`ERRORED` indicates that some error occurred while applying config at an edge. This will be
accompanied by a message which specifies the reason for the error.

</td>
</tr>
    
<tr>
<td>


IGNORED

</td>

<td>

3

</td>

<td>

`IGNORED` indicates that the config was ignored because of some misconfiguration in config yaml.
For instance, applying `DIRECT` mode config within `BRIDGED` mode group.

</td>
</tr>
    
</table>
  



### EventType {#tetrateio-api-tsb-v2-configevents-eventtype}

Simple `Status` of the current resource. It's a projection of its details
(events, etc.) that allows to easily know the status of the resource
without requiring to check the details.


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


INVALID

</td>

<td>

0

</td>

<td>

INVALID is the zero value and should never be reached.

</td>
</tr>
    
<tr>
<td>


TSB_ACCEPTED

</td>

<td>

1

</td>

<td>

TSB_ACCEPTED happens when the configuration has been validated and
persisted by TSB. Note that there is no TSB_REJECTED because in case of
an obvious syntax error, the client requests for the API will fail
directly. The configuration will not be persisted and therefore no
config status will be associated with it.

</td>
</tr>
    
<tr>
<td>


MPC_ACCEPTED

</td>

<td>

2

</td>

<td>

MPC_ACCEPTED happens when MPC receives the configuration from TSB.
Note that there is no MPC_REJECTED because it&#39;s just a pass-through
to XCP.

</td>
</tr>
    
<tr>
<td>


XCP_ACCEPTED

</td>

<td>

3

</td>

<td>

XCP_ACCEPTED happens when XCP validates the configuration and the XCP
resource is properly created.

</td>
</tr>
    
<tr>
<td>


XCP_REJECTED

</td>

<td>

4

</td>

<td>

XCP_REJECTED happens when XCP reports that the configuration is not
valid.

</td>
</tr>
    
<tr>
<td>


MPC_FAILED

</td>

<td>

5

</td>

<td>

MPC_FAILED happens when MPC fails to process some configuration received
from TSB. These failures are prior to sending the translated
configurations to XCP.

</td>
</tr>
    
<tr>
<td>


XCP_UNKNOWN

</td>

<td>

6

</td>

<td>

XCP_UNKNOWN happens when XCP reports that all edges are in UNKNOWN
state.

</td>
</tr>
    
<tr>
<td>


XCP_PARTIALLY_APPLIED

</td>

<td>

7

</td>

<td>

XCP_PARTIAL happens when XCP reports that at least one edge is in
APPLIED state, and the rest are UNKNOWN.

</td>
</tr>
    
<tr>
<td>


XCP_APPLIED

</td>

<td>

8

</td>

<td>

XCP_APPLIED happens when XCP reports that every edge is in APPLIED
state.

</td>
</tr>
    
<tr>
<td>


XCP_ERRORED

</td>

<td>

9

</td>

<td>

XCP_ERRORED happens when XCP reports that any edge is in ERRORED state.

</td>
</tr>
    
<tr>
<td>


XCP_IGNORED

</td>

<td>

10

</td>

<td>

XCP_IGNORED happens when XCP reports that the config is IGNORED by all the edges.
One of the cases where configs are ignored is when a BRIDGED mode config object
like IngressGateway is part of a gateway group configured for the DIRECT mode
and vice versa. More generally, this happens when there is a mismatch between
the mode where a config is valid and the mode configured for the group.

</td>
</tr>
    
<tr>
<td>


MPC_DIRTY

</td>

<td>

11

</td>

<td>

MPC_DIRTY happens when a resource that is dependent on others
have not reached the desired status (even when they are not FAILED).
For instance, when a resource configuration affected by a STRICTER propagation
strategy gets superseded (fully or partially) by a stricter resource configuration higher up
in the hierarchy. Concretely, if a security group&#39;s security settings (which
is in ACCEPTED configuration state) is affected
by a STRICTER propagation strategy, and for instance an organization&#39;s
default security settings (a resource higher up in the hierarchy)
has been updated to restrict more the previously set authorization policy, then
the previously ACCEPTED security group&#39;s security settings (a resource lower in
the hierarchy) will become DIRTY if it is not stricter.

</td>
</tr>
    
</table>
  



### Status {#tetrateio-api-tsb-v2-resourcestatus-status}

Simple `Status` of the current resource. It's a projection of its details
(events, etc.) that allows to easily know the status of the resource
without requiring to check the details.


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


INVALID

</td>

<td>

0

</td>

<td>

INVALID status should never be reached.
It indicates some problem occurred with the resource status, and would
need to contact the admin to troubleshoot it.
It&#39;s the default value but it&#39;s always expected to have one of the other
values.

</td>
</tr>
    
<tr>
<td>


ACCEPTED

</td>

<td>

1

</td>

<td>

ACCEPTED is reached when the provided configuration has been validated
and persisted by the TSB server.

</td>
</tr>
    
<tr>
<td>


READY

</td>

<td>

2

</td>

<td>

READY is reached when the resource is ready to be used.
Non-configurable resources, like Organizations, Tenants or Users, will
be ready as soon they are created.
The configurable ones are ready when its configuration has been
propagated to all the clusters.

</td>
</tr>
    
<tr>
<td>


FAILED

</td>

<td>

3

</td>

<td>

FAILED is reached in different situations, such as when:
- a resource configuration triggered some internal error.
- an offending resource affects the correct behaviour of the configuration.
The `message` and `details` fields of the `ResourceStatus` provides the
root cause of the error.

</td>
</tr>
    
<tr>
<td>


DIRTY

</td>

<td>

4

</td>

<td>

DIRTY is reached when the resources that are dependent on others
have not reached the desired status (even when they are not FAILED).
For example, an `API` resource that caused the creation of an `IngressGateway`
could reach this status if the `IngressGateway` has been modified or removed directly.

</td>
</tr>
    
<tr>
<td>


PARTIAL

</td>

<td>

5

</td>

<td>

PARTIAL is reached for those resources that are dependent on other resources statuses,
and not all the resources share the same status.

</td>
</tr>
    
</table>
  


