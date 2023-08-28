---
title: Host Info
description: Information about the host the workload is running on.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Host Info specifies information about the host the workload is running on.





## Address {#tetrateio-api-onboarding-config-types-registration-v1alpha1-address}

Address specifies network address.



  
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


ip

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> IP address.

</td>

<td>

string = {<br/>&nbsp;&nbsp;ip: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


type

</td>

<td>

[tetrateio.api.onboarding.config.types.registration.v1alpha1.AddressType](../../../../../onboarding/config/types/registration/v1alpha1/hostinfo#tetrateio-api-onboarding-config-types-registration-v1alpha1-addresstype) <br/> _REQUIRED_ <br/> Address type.

</td>

<td>

enum = {<br/>&nbsp;&nbsp;not_in: `0`<br/>}<br/>

</td>
</tr>
    
</table>
  


## HostInfo {#tetrateio-api-onboarding-config-types-registration-v1alpha1-hostinfo}

HostInfo specifies information about the host the workload is running on.



  
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


addresses

</td>

<td>

List of [tetrateio.api.onboarding.config.types.registration.v1alpha1.Address](../../../../../onboarding/config/types/registration/v1alpha1/hostinfo#tetrateio-api-onboarding-config-types-registration-v1alpha1-address) <br/> _REQUIRED_ <br/> Network addresses of the host the workload is running on.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{message:{required:true}}`<br/>}<br/>

</td>
</tr>
    
</table>
  




## AddressType {#tetrateio-api-onboarding-config-types-registration-v1alpha1-addresstype}

AddressType specifies type of a network address associated with the workload.


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


UNSPECIFIED

</td>

<td>

0

</td>

<td>

Not specified.

</td>
</tr>
    
<tr>
<td>


VPC

</td>

<td>

1

</td>

<td>

IP address from the `VPC` range. Commonly referred to as `Private IP` or
`Internal IP`.

</td>
</tr>
    
<tr>
<td>


INTERNET

</td>

<td>

2

</td>

<td>

IP address from the `Internet` range. Commonly referred to as `Public IP` or
`External IP`.

</td>
</tr>
    
</table>
  


