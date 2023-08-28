---
title: Condition
description: Contains details for one aspect of the current state of an API Resource.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Condition contains details for one aspect of the current state of an
API Resource.





## Condition {#tetrateio-api-onboarding-config-types-core-v1alpha1-condition}

Condition contains details for one aspect of the current state of an
`API Resource`.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Type of condition in `CamelCase` or in `foo.example.com/CamelCase`.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


status

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Status of the condition, one of `True`, `False`, `Unknown`.

</td>

<td>

string = {<br/>&nbsp;&nbsp;in: `True,False,Unknown`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


reason

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Reason contains a programmatic identifier indicating the reason for the
condition's last transition.
Producers of specific condition types may define expected values and
meanings for this field, and whether the values are considered a guaranteed
API. The value should be a `CamelCase` string.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


message

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Message is a human readable message indicating details about the
transition.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


lastTransitionTime

</td>

<td>

[google.protobuf.Timestamp](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Timestamp) <br/> LastTransitionTime is the last time the condition transitioned from one
status to another.
This should be when the underlying condition changed. If that is not known,
then using the time when the API field changed is acceptable.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


observedGeneration

</td>

<td>

[int64](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> ObservedGeneration represents the `.metadata.generation` that the condition
was set based upon.
For instance, if `.metadata.generation` is currently `12`, but the
`.status.conditions[x].observedGeneration` is `9`, the condition is out
of date with respect to the current state of the instance.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



