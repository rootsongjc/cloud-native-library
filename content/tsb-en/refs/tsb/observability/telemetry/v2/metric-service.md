---
title: Metric Service
description: Service to manage telemetry metrics.
---


import {
  PanelContent,
  PanelContentCode,
} from "@theme/Panel";


<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Service to manage telemetry metrics.


## Metrics {#tetrateio-api-tsb-observability-telemetry-v2-metrics}

The Metrics service exposes methods to manage Telemetry Metrics from Telemetry Sources.


### GetMetric

<PanelContent>
<PanelContentCode>

rpc GetMetric ([tetrateio.api.tsb.observability.telemetry.v2.GetMetricRequest](../../../../tsb/observability/telemetry/v2/metric_service#tetrateio-api-tsb-observability-telemetry-v2-getmetricrequest)) returns ([tetrateio.api.tsb.observability.telemetry.v2.Metric](../../../../tsb/observability/telemetry/v2/metric#tetrateio-api-tsb-observability-telemetry-v2-metric))

</PanelContentCode>



Get the details of an existing telemetry metric.

</PanelContent>

### ListMetrics

<PanelContent>
<PanelContentCode>

rpc ListMetrics ([tetrateio.api.tsb.observability.telemetry.v2.ListMetricsRequest](../../../../tsb/observability/telemetry/v2/metric_service#tetrateio-api-tsb-observability-telemetry-v2-listmetricsrequest)) returns ([tetrateio.api.tsb.observability.telemetry.v2.ListMetricsResponse](../../../../tsb/observability/telemetry/v2/metric_service#tetrateio-api-tsb-observability-telemetry-v2-listmetricsresponse))

</PanelContentCode>



List the telemetry metrics that are available for the requested telemetry source.

</PanelContent>






## GetMetricRequest {#tetrateio-api-tsb-observability-telemetry-v2-getmetricrequest}

Request to retrieve a telemetry metric from a parent telemetry source resource.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the telemetry metric.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListMetricsRequest {#tetrateio-api-tsb-observability-telemetry-v2-listmetricsrequest}

Request to retrieve the list of telemetry metrics from a parent telemetry source resource.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Fully-qualified name of the parent telemetry source resource to retrieve the telemetry metrics.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## ListMetricsResponse {#tetrateio-api-tsb-observability-telemetry-v2-listmetricsresponse}

List of telemetry metrics from the resource.



  
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


metrics

</td>

<td>

List of [tetrateio.api.tsb.observability.telemetry.v2.Metric](../../../../tsb/observability/telemetry/v2/metric#tetrateio-api-tsb-observability-telemetry-v2-metric) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



