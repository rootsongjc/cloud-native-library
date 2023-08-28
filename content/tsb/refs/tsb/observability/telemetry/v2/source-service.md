---
title: Telemetry Source Service
description: Service to manage the Telemetry Sources.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage the Telemetry Sources.


## Sources {#tetrateio-api-tsb-observability-telemetry-v2-sources}

The Sources service exposes methods to manage telemetry sources from resources.


### GetSource

<PanelContent>
<PanelContentCode>

rpc GetSource ([tetrateio.api.tsb.observability.telemetry.v2.GetSourceRequest](../../../../tsb/observability/telemetry/v2/source_service#tetrateio-api-tsb-observability-telemetry-v2-getsourcerequest)) returns ([tetrateio.api.tsb.observability.telemetry.v2.Source](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-source))

</PanelContentCode>



Get the details of an existing telemetry source.

</PanelContent>

### ListSources

<PanelContent>
<PanelContentCode>

rpc ListSources ([tetrateio.api.tsb.observability.telemetry.v2.ListSourcesRequest](../../../../tsb/observability/telemetry/v2/source_service#tetrateio-api-tsb-observability-telemetry-v2-listsourcesrequest)) returns ([tetrateio.api.tsb.observability.telemetry.v2.ListSourcesResponse](../../../../tsb/observability/telemetry/v2/source_service#tetrateio-api-tsb-observability-telemetry-v2-listsourcesresponse))

</PanelContentCode>



List the telemetry sources that are available for the requested parent. It will return telemetry sources that belong
to the requested parent and from all its child resources.

</PanelContent>






## GetSourceRequest {#tetrateio-api-tsb-observability-telemetry-v2-getsourcerequest}

Request to retrieve a Telemetry Sources from a parent resource.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the Telemetry Sources.

TODO(marcnavarro): Add pagination information.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListSourcesRequest {#tetrateio-api-tsb-observability-telemetry-v2-listsourcesrequest}

Request to retrieve the list of telemetry sources from a parent resource.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the parent resource to retrieve the telemetry sources.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


scopeTypes

</td>

<td>

List of [tetrateio.api.tsb.observability.telemetry.v2.SourceScopeType](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-sourcescopetype) <br/> The scope type that a telemetry source needs to match.
Telemetry sources that matches any requested scope type will be returned.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


belongTos

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Which resources the telemetry sources must belong to.
Telemetry sources that belongs to any requested resource will be returned.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


existed

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.ListSourcesRequest.TimeRange](../../../../tsb/observability/telemetry/v2/source_service#tetrateio-api-tsb-observability-telemetry-v2-listsourcesrequest-timerange) <br/> Time range during which telemetry sources must have existed. If no existed time range is provided, only the actual
available Telemetry sources will be returned. Otherwise, telemetry Sources that existed during the time range will
be returned.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### TimeRange {#tetrateio-api-tsb-observability-telemetry-v2-listsourcesrequest-timerange}

TimeRange is a closed time range. If since or until are not provided they will not be used to filter.



  
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


since

</td>

<td>

[google.protobuf.Timestamp](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Timestamp) <br/> Moment in time since we retrieve Telemetry Sources.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


until

</td>

<td>

[google.protobuf.Timestamp](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Timestamp) <br/> Moment in time until we retrieve Telemetry Sources.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ListSourcesResponse {#tetrateio-api-tsb-observability-telemetry-v2-listsourcesresponse}

List of telemetry sources from the resource.



  
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


sources

</td>

<td>

List of [tetrateio.api.tsb.observability.telemetry.v2.Source](../../../../tsb/observability/telemetry/v2/source#tetrateio-api-tsb-observability-telemetry-v2-source) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



