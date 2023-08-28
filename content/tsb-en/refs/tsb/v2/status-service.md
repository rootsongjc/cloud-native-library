---
title: Status Service
description: Service to retrieve the status for TSB resources
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to retrieve the status for TSB resources


## Status {#tetrateio-api-tsb-v2-status}

The Status services exposes methods to retrieve the status for any resource managed by TSB.


### GetStatus

<PanelContent>
<PanelContentCode>

rpc GetStatus ([tetrateio.api.tsb.v2.GetStatusRequest](../../tsb/v2/status_service#tetrateio-api-tsb-v2-getstatusrequest)) returns ([tetrateio.api.tsb.v2.ResourceStatus](../../tsb/v2/status#tetrateio-api-tsb-v2-resourcestatus))

</PanelContentCode>



Given a resource fully-qualified name of a resource returns its current status.

</PanelContent>






## GetStatusRequest {#tetrateio-api-tsb-v2-getstatusrequest}

Request to retrieve the status of a resource.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the resource to retrieve the status.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  



