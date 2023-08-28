---
title: Metric
description: A metric is a measurement about a service, captured at runtime.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

A metric is a measurement about a service, captured at runtime. Logically, the moment of capturing one of
these measurements is known as a metric event which consists not only of the measurement itself, but the time
that it was captured and associated metadata..

The key aspects of a metric are the measure, the metric type, the metric origin, and the metric detect point:
- The measure describes the type and unit of a metric event also known as measurement.
- The metric type is the aggregation over time applied to the measurements.
- The metric origin tells from where the metric measurements come from.
- The detect point is the point from which the metric is observed, in service, server side, or client side.
It is useful to differentiate between metrics that observe a concrete service (often self observing), or metrics that
focus on service to service communications.

An TSB controlled (is part of the mesh and has a proxy we can configure) service has several metrics available
which leverages a consistent monitoring of services.
Some of them cover what is known as the RED metrics set, which are a set of very useful metrics for
HTTP/RPC request based services. RED stands for:
- Rate (R): The number of requests per second.
- Errors (E): The number of failed requests.
- Duration (D): The amount of time to process a request.

To understand a bit better which metrics are available given a concrete telemetry source, let's assume we have
deployed the classic Istio [bookinfo demo application](https://istio.io/latest/docs/examples/bookinfo/).
Let's see some RED based metrics available for an observed and managed service by TSB, for instance the review
service using the GLOBAL scoped telemetry source.

The following metric is the number of request per minute that the reviews service is handling at a GLOBAL scope:
```yaml
apiVersion: observability.telemetry.tsb.tetrate.io/v2
kind: Metric
metadata:
  organization: myorg
  service: reviews.bookinfo
  source: reviews
  name: service_cpm
spec:
  observedResource: organizations/myorg/services/reviews.bookinfo
  measure:
    type: REQUESTS
    unit: "{request}"
  metricType:
    type: CPM
  origin: MESH_OBSERVED
  detectPoint: SERVER_SIDE
```

The metric for the average duration of the handled request by the reviews service at a GLOBAL scope:
```yaml
apiVersion: observability.telemetry.tsb.tetrate.io/v2
kind: Metric
metadata:
  organization: myorg
  service: reviews.bookinfo
  source: reviews
  name: service_resp_time
spec:
  observedResource: organizations/myorg/services/reviews.bookinfo
  measure:
    type: LATENCY
    unit: ms
  metricType:
    type: AVERAGE
  origin: MESH_OBSERVED
  detectPoint: SERVER_SIDE
```

The metric for the errors of the handled request by the reviews at a GLOBAL scope. In this case the number of errors
are expresses as a percentage of the total number of handled requests:
```yaml
apiVersion: observability.telemetry.tsb.tetrate.io/v2
kind: Metric
metadata:
  organization: myorg
  service: reviews.bookinfo
  source: reviews
  name: service_sla
spec:
  observedResource: organizations/myorg/services/reviews.bookinfo
  measure:
    type: STATUS
    unit: NUMBER
  metricType:
    type: PERCENT
  origin: MESH_OBSERVED
  detectPoint: SERVER_SIDE
```
Using a different telemetry source for the same metric will gives a different view of the same observed measurements.
For instance, if we want to know how many requests per minute subset v1 from the reviews is handling, we need to use
the same metric but from a different telemetry source, in this case reviews-v1:
```yaml
apiVersion: observability.telemetry.tsb.tetrate.io/v2
kind: Metric
metadata:
  organization: myorg
  service: reviews.bookinfo
  source: reviews-v1
  name: service_cpm
spec:
  observedResource: organizations/myorg/services/reviews.bookinfo
  measure:
    type: REQUESTS
    unit: NUMBER
  metricType:
    type: CPM
  origin: MESH_OBSERVED
  detectPoint: SERVER_SIDE
```

The duration or latency measurements can also be aggregated in different percentiles over time.
The duration percentiles for the handled request by the reviews at a GLOBAL scope:
```yaml
apiVersion: observability.telemetry.tsb.tetrate.io/v2
kind: Metric
metadata:
  organization: myorg
  service: reviews.bookinfo
  source: reviews
  name: service_percentile
spec:
  observedResource: organizations/myorg/services/reviews.bookinfo
  measure:
    type: LATENCY
    unit: ms
  metricType:
    type: PERCENTILE
    labels:
    - key: "0"
      value: "p50"
    - key: "1"
      value: "p75"
    - key: "2"
      value: "p90"
    - key: "3"
      value: "p05"
    - key: "4"
      value: "p99"
  origin: MESH_OBSERVED
  detectPoint: SERVER_SIDE
```





## Measure {#tetrateio-api-tsb-observability-telemetry-v2-measure}

A measure represents the name and unit of a measurement.
For example, request latency in ms and the number of errors are examples of measures to collect from a server. In
this case latency would be the type and ms (millisecond) is the unit.



  
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


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The name of the measure. For instance latency in ms. More reference values can be found at
MeshControlledMeasureNames.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


unit

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The unit of measure, which follow the [unified code for units of measure](https://ucum.org/ucum.html).
For COUNTABLE measures, as number of requests or network packets, SHOULD use the default unit, the unity, and
[annotations](https://ucum.org/ucum.html#para-curly) with curly braces to give additional meaning.
For example {requests}, {packets}, {errors}, {faults}, etc.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Metric {#tetrateio-api-tsb-observability-telemetry-v2-metric}

A metric is a measurement about a service, captured at runtime. Logically, the moment of capturing one of
these measurements is known as a metric event which consists not only of the measurement itself, but the time
that it was captured and associated metadata.

Application and request metrics are important indicators of availability and performance.
Custom metrics can provide insights into how availability indicators impact user experience or the business.
Collected data can be used to alert of an outage or trigger scheduling decisions to scale up a deployment
automatically upon high demand.



  
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


observedResource

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OUTPUT_ONLY_ <br/> Which concrete TSB resource in the configuration hierarchy this metric observes and belongs to.
For instance, a metric can observe a service, a concrete service workload (pod or Vm), or a gateway,
or a workspace, or any other resource in the configuration hierarchy.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


measure

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.Measure](../../../../tsb/observability/telemetry/v2/metric#tetrateio-api-tsb-observability-telemetry-v2-measure) <br/> Measure describes the name and unit of a metric event also know as measurement.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


type

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.MetricType](../../../../tsb/observability/telemetry/v2/metric#tetrateio-api-tsb-observability-telemetry-v2-metrictype) <br/> The type of aggregation over time applied to the measurements.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


origin

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.MetricOrigin](../../../../tsb/observability/telemetry/v2/metric#tetrateio-api-tsb-observability-telemetry-v2-metricorigin) <br/> From where the metric measurements come from.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


detectionPoint

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.MetricDetectionPoint](../../../../tsb/observability/telemetry/v2/metric#tetrateio-api-tsb-observability-telemetry-v2-metricdetectionpoint) <br/> From which detection point the metric is observed, server side or client side.
It is useful to differentiate between metrics that observe a concrete service (often self observing),
or metrics that focus on service to service communications.
In service to service observed metrics, the observation can be done at the client or the server side.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## MetricType {#tetrateio-api-tsb-observability-telemetry-v2-metrictype}

Metric types are the aggregation function applied to the measurements that took place over a period of time.
Some metric types like LABELED_COUNTER and PERCENTILE also additionally aggregated over the set of defined labels.



  
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


name

</td>

<td>

[tetrateio.api.tsb.observability.telemetry.v2.MetricType.Type](../../../../tsb/observability/telemetry/v2/metric#tetrateio-api-tsb-observability-telemetry-v2-metrictype-type) <br/> The type of metric

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


labels

</td>

<td>

List of [tetrateio.api.tsb.observability.telemetry.v2.MetricType.Label](../../../../tsb/observability/telemetry/v2/metric#tetrateio-api-tsb-observability-telemetry-v2-metrictype-label) <br/> The labels associated with the metric type.
Some aggregation function are not just applied over time. LABELED_COUNTER and PERCENTILE metric types also
aggregate over their labels. For instance, a PERCENTILE metric type over the latency, will aggregate the measured
latency over the different defined percentiles, p50, p75, p90, p95, and p99.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Label {#tetrateio-api-tsb-observability-telemetry-v2-metrictype-label}

Label of metric type. Also seen a other dimensions of aggregation besides the time interval on which measurements
are aggregated over.



  
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


key

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The label key.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The label value, for instance p50, or p75.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




### MeshControlledMeasureNames {#tetrateio-api-tsb-observability-telemetry-v2-measure-meshcontrolledmeasurenames}

The name of measures available for a controlled service in the mesh.


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


INVALID_MEASURE_TYPE

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


COUNTABLE

</td>

<td>

1

</td>

<td>

Represents discrete instances of a countable quantity. And integer count of something SHOULD use the default
unit, the unity. Countable is a generalized measure name that can be used for many common countable quantities.
Because of the generalized name, [annotations](https://ucum.org/ucum.html#para-curly) with curly braces to give
additional meaning.
Networks packets, system paging faults are countable measures examples.

</td>
</tr>
    
<tr>
<td>


REQUESTS

</td>

<td>

2

</td>

<td>

Requests is a specialized countable measure that represents the number of requests.

</td>
</tr>
    
<tr>
<td>


LATENCY

</td>

<td>

3

</td>

<td>

The time taken by each request.

</td>
</tr>
    
<tr>
<td>


STATUS

</td>

<td>

4

</td>

<td>

The success or failure of a request.

</td>
</tr>
    
<tr>
<td>


HTTP_RESPONSE_CODE

</td>

<td>

5

</td>

<td>

The response code of the HTTP response, and if this request is the HTTP call. E.g. 200, 404, 302

</td>
</tr>
    
<tr>
<td>


RPC_RESPONSE_CODE

</td>

<td>

6

</td>

<td>

The value of the rpc response code.

</td>
</tr>
    
<tr>
<td>


SIDECAR_INTERNAL_ERROR_CODE

</td>

<td>

7

</td>

<td>

The sidecar/gateway proxy internal error code. The value is based on the implementation.

</td>
</tr>
    
<tr>
<td>


SIDECAR_RETRY_EXCEEDED

</td>

<td>

8

</td>

<td>

The sidecar/gateway proxy internal error code. The value is based on the implementation.

</td>
</tr>
    
<tr>
<td>


TCP_INFO_RECEIVED_BYTES

</td>

<td>

9

</td>

<td>

The received bytes of the TCP traffic, if this request is a TCP call.

</td>
</tr>
    
<tr>
<td>


TCP_INFO_SEND_BYTES

</td>

<td>

10

</td>

<td>

The sent bytes of the TCP traffic, if this request is a TCP call.

</td>
</tr>
    
<tr>
<td>


MTLS_IN_USE

</td>

<td>

11

</td>

<td>

If mutual tls is in use in the connections between services.

</td>
</tr>
    
<tr>
<td>


SIDECAR_HEAP_MEMORY_USED

</td>

<td>

12

</td>

<td>

Current reserved heap size in bytes. New Envoy process heap size on hot restart.

</td>
</tr>
    
<tr>
<td>


SIDECAR_MEMORY_ALLOCATED

</td>

<td>

14

</td>

<td>

Current amount of allocated memory in bytes. Total of both new and old Envoy processes on hot restart.

</td>
</tr>
    
<tr>
<td>


SIDECAR_PHYSICAL_MEMORY

</td>

<td>

15

</td>

<td>

Current estimate of total bytes of the physical memory. New Envoy process physical memory size on hot restart.

</td>
</tr>
    
<tr>
<td>


SIDECAR_TOTAL_CONNECTIONS

</td>

<td>

16

</td>

<td>

Total connections of both new and old Envoy processes.

</td>
</tr>
    
<tr>
<td>


SIDECAR_PARENT_CONNECTIONS

</td>

<td>

17

</td>

<td>

Total connections of the old Envoy process on hot restart.

</td>
</tr>
    
<tr>
<td>


SIDECAR_WORKER_THREADS

</td>

<td>

18

</td>

<td>

Number of worker threads.

</td>
</tr>
    
<tr>
<td>


SIDECAR_BUG_FAILURES

</td>

<td>

19

</td>

<td>

Number of envoy bug failures detected in a release build.
File or report the issue if this increments as this may be serious.

</td>
</tr>
    
</table>
  



## MetricDetectionPoint {#tetrateio-api-tsb-observability-telemetry-v2-metricdetectionpoint}

From which detection point the metric is observed.


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


INVALID_METRIC_DETECTION_POINT

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


IN_SERVICE

</td>

<td>

1

</td>

<td>

Self observability metrics uses in service detect point.

</td>
</tr>
    
<tr>
<td>


CLIENT_SIDE

</td>

<td>

2

</td>

<td>

Client side is how the client is observing the metric. When service A calls service B, service A acts
as a client side.

</td>
</tr>
    
<tr>
<td>


SERVER_SIDE

</td>

<td>

3

</td>

<td>

Server side is how the server is observing the metric. When service A calls service B, service B
acts as the server side.

</td>
</tr>
    
</table>
  



## MetricOrigin {#tetrateio-api-tsb-observability-telemetry-v2-metricorigin}

From where the metric measurements come from.


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


INVALID_METRIC_ORIGIN

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


MESH_CONTROLLED

</td>

<td>

1

</td>

<td>

The metrics origin is from a TSB configured mesh, capturing the metrics from the
sidecar&#39;s available observability.

</td>
</tr>
    
<tr>
<td>


AGENT_OBSERVED

</td>

<td>

2

</td>

<td>

An agent which can be standalone or service with automatically instrumentation via byte code injection.
Currently not available. Part of hybrid observability.

</td>
</tr>
    
<tr>
<td>


MESH_IMPORTED

</td>

<td>

3

</td>

<td>

Other known mesh generated metrics that are not configured and handled by TSB.
Currently not available. Part of hybrid observability.

</td>
</tr>
    
<tr>
<td>


EXTERNAL_IMPORTED

</td>

<td>

4

</td>

<td>

External captured metrics that are either imported into TSB observability stack or queried at runtime.
Currently not available. Part of hybrid observability.

</td>
</tr>
    
</table>
  



### Type {#tetrateio-api-tsb-observability-telemetry-v2-metrictype-type}




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


INVALID_METRIC_TYPE

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


GAUGE

</td>

<td>

1

</td>

<td>

Is the last seen measurement over a period of time.

</td>
</tr>
    
<tr>
<td>


COUNTER

</td>

<td>

2

</td>

<td>

Is the sum of number of measurement over a period of time. Used in number of request style of metrics.

</td>
</tr>
    
<tr>
<td>


AVERAGE

</td>

<td>

3

</td>

<td>

Average function applied to the measurements. Used in Duration/latency style of metrics.

</td>
</tr>
    
<tr>
<td>


PERCENT

</td>

<td>

4

</td>

<td>

Percentage function applied to a given observed value over the total observer values.
Used in SLA style of metrics, for example the percentage of errored responses over the total server responses.

</td>
</tr>
    
<tr>
<td>


APDEX

</td>

<td>

5

</td>

<td>

Application Performance Index monitors end-user satisfaction.
[Apdex score](https://www.tetrate.io/blog/the-apdex-score-for-measuring-service-mesh-health)

</td>
</tr>
    
<tr>
<td>


HEATMAPS

</td>

<td>

6

</td>

<td>

Heat maps are a three dimensional visualization, using x and y coordinates for two dimensions, and color
intensity for the third. They can reveal detail that summary statistics, such as line charts of averages,
can miss. Latency measurements can be aggregated using Heatmaps/histograms. One dimension is often time, the
other is the latency, and the third one (the intensity) is the frequency of that latency in the given time range.

</td>
</tr>
    
<tr>
<td>


LABELED_COUNTER

</td>

<td>

7

</td>

<td>

Is the sum of number of measurement over time grouped by concrete label values. Used for counting responses by
their http response code for instance.

</td>
</tr>
    
<tr>
<td>


PERCENTILE

</td>

<td>

8

</td>

<td>

This is a specific subtype of LABELED_COUNTER. Used in duration/latency style metrics.

</td>
</tr>
    
<tr>
<td>


CPM

</td>

<td>

10

</td>

<td>

Calls per minute used. Used in requests per minute, or in 5xx http errors per minute, 4xx http errors per
minute, among other metrics.

</td>
</tr>
    
<tr>
<td>


MAX

</td>

<td>

11

</td>

<td>

Selects the highest measurement over a period of time. Envoy max allocated style metrics.

</td>
</tr>
    
</table>
  


