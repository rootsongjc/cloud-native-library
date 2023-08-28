---
title: Resource Consumption and Capacity Planning
description: General guidelines for capacity planning of TSB.
weight: 8
---

This document describes a conservative guideline for capacity planning of Tetrate Service Bridge (TSB) in Management and Control planes.

These parameters apply to production installations: TSB will run with minimal resources if you are using a demo-like environment.

:::note disclaimer
The resource provisioning guidelines described in this document are very conservative.

Also please be aware that the resource provisioning described in this document are applicable to _vertical_ resource scaling. Multiple replicas of the same TSB components do not share the load with each other, and therefore you cannot expect the combined resources from multiple components to have the same effect. Replicas of TSB components should only be used for high availability purposes only.
:::

## Recommended baseline production installation resource requirements

For a baseline installation of TSB with 1 registered cluster and 1 deployed service within that cluster, the following resources are recommended.

To reiterate, the amount of memory described below are very conservative. Also, the actual performance given by the number of vCPUs tend to fluctuate depending on your underlying infrastructure. You are advised to verify the results in your environment.

| Component | vCPU # | Memory MiB
| --- | :---: | :---:
| TSB server *(Management Plane)* <sup>1</sup> | 2 | 512
| XCP Central Components <sup>2</sup> | 2 | 128
| XCP Edge | 1 | 128
| Front Envoy | 1 | 50
| IAM | 1 | 128
| TSB UI | 1 | 256
| OAP | 4 | 5192
| OTEL-collector | 2 | 1024

<sup>1</sup> Including the Kubernetes operator and persistent data
reconciliation processes. <br />
<sup>2</sup> Including the Kubernetes operator.

## Recommended scaling resource parameters

The TSB stack is mostly CPU-bound. Additional clusters registered with TSB via XCP increase the
CPU utilization by ~4%.

The effect of additional registered clusters or additional deployed workload
services on memory utilisation is almost negligible. Likewise, the effect of
additional clusters or workloads on resource consumption of the majority of TSB
components is mostly negligible, with the notable exceptions of TSB, XCP Central
component, TSB UI and IAM.

:::note
Components that are part of the visibility stack (e.g. OTel/OAP, etc.) have
their resource utilisation driven by requests, thus the resource scaling should
follow the user request rate statistics. As a general rule of thumb, more than
1 vCPU is preferred. It is also important to notice that the visibility stack
performance is largely bound by Elasticsearch performance.
:::

Thus, we recommend vertically scaling the components by 1 vCPU for a number of
deployed workflows:

### Management Plane

Besides OAP, All components don't require any resource adjustment. 
Those components are architectured and tested to support very large clusters.

OAP in Management plane requires extra CPU and Memory ~ 100 millicores of CPU and 
1024 MiB of RAM per every 1000 services. E.g. 4000 services aggregated in 
TSB Management Plane from all TSB clusters would require approximately 400 millicores 
of CPU and 4096 MiB of RAM in total.

## Control Plane Resource Requirements

Following table shows typical peak resource utilization for TSB control plane with the following assumptions:
- 50 services with sidecars
- Traffic on entire cluster is 500 repository
- OAP trace sampling rate is 1% of the traffic
- Metric is captured for every request at every workload.

Note that average CPU utilization would be a fraction of the typical peak value.

| Component | Typical Peak CPU (m) | Typical Peak Memory (Mi)
| --- | :---: | :---:
| Istiod | 300m | 250Mi
| OAP | 2500m | 2500Mi
| XCP Edge | 100m | 100Mi
| Istio Operator - Control Plane | 50m | 100Mi
| Istio Operator - Data Plane | 150m | 100Mi
| TSB Control Plane Operator | 100m | 100Mi
| TSB Data Plane Operator | 150m | 100Mi
| OTEL Collector | 50m | 100Mi

## TSB/Istio Operator resource usage per Ingress Gateway

The following table shows the resources used by TSB Operator and Istio Operator per Ingress Gateways

| Ingress Gateways | TSB Operator CPU(m) | TSB Operator Mem(Mi) | Istio Operator CPU(m) | Istio Operator Mem(Mi)
| --- | :---: | :---: | :---: | :---:
| 0 | 100m | 50Mi | 10m | 45Mi
| 50 | 2600m | 125Mi | 1100m | 120Mi 
| 100 | 3500m | 200Mi | 1300m | 175Mi
| 150 | 3800m | 250Mi | 1400m | 200Mi
| 200 | 4000m | 325Mi | 1400m | 250Mi
| 250 | 4700m | 325Mi | 1750m | 300Mi
| 300 | 5000m | 475Mi | 1750m | 400Mi


## Component resource utilization

The following tables will show how the different components of TSB scale with 4000 services and peaking with 60 rpm, this is divided by information from the Management Plane, and the Control Plane.

### Management Plane

| Services | Gateways | Traffic(rpm) | Central CPU(m) | Central Mem(Mi) | MPC CPU(m) | MPC Mem(Mi) | OAP CPU(m) | OAP Mem(Mi) | Otel CPU(m) | Otel Mem(Mi) | TSB CPU(m) | TSB Mem(Mi)
| --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: 
| 0 | 0| 0 rpm| 3m|39Mi|5m|30Mi|37m|408Mi|22m|108Mi|14m|57Mi
| 400 | 2| 60 rpm|4m|42Mi|15m|31Mi|116m|736Mi|24m|123Mi|50m|63Mi
| 800 | 4|60 rpm|4m|54Mi|24m|34Mi|43m|909Mi|26m|127Mi|85m|75Mi
| 1200 | 6|60 rpm|4m|59Mi|32m|41Mi|28m|1141Mi|27m|210Mi|213m|78Mi
| 1600 |8|60 rpm|5m|63Mi|44m|48Mi|209m|1475Mi|29m|249Mi|113m|86Mi
| 2000 |10|60 rpm|5m|73Mi|41m|51Mi|51m|1655Mi|24m|319Mi|211m|91Mi
| 2400 |12|60 rpm|4m|84Mi|72m|62Mi|57m|1910Mi|29m|381Mi|227m|97Mi
| 2800 |14|60 rpm|5m|90Mi|73m|65Mi|43m|2136Mi|16m|466Mi|275m|104Mi
| 3200 |16|60 rpm|5m|106Mi|85m|78Mi|89m|2600Mi|43m|574Mi|382m|108Mi
| 3600 |18|60 rpm|5m|123Mi|94m|71Mi|245m|2772Mi|37m|578Mi|625m|115Mi
| 4000 |20|60 rpm|5m|147Mi|90m|81Mi|521m|3224Mi|15m|704Mi|508m|122Mi

:::note
IAM will peak at 5m/32Mi, LDAP at 1m/12Mi and XCP Operator at 3m and 23Mi
:::

### Control Plane

| Services | Gateways | Traffic(rpm) | Edge CPU(m) | Edge Mem(Mi) | Istiod CPU(m) | Istiod Mem(Mi) | OAP CPU(m) | OAP Mem(Mi) | Otel CPU(m) | Otel Mem(Mi)
| --- | --- | --- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|0|0|0 rpm|3m|67Mi|6m|110Mi|55m|439Mi|16m|74Mi
|400|2|60 rpm|2m|97Mi|33m|182Mi| 334m|1138Mi|18m|75Mi
|800|4|60 rpm|3m|153Mi|35m|249Mi|653m|1640Mi|21m|85Mi
|1200|6|60 rpm|3m|192Mi|68m|286Mi|815m|2238Mi|23m|164Mi
|1600|8|60 rpm|3m|238Mi|84m|324Mi|1217m|2766Mi|20m|202Mi
|2000|10|60 rpm|3m|280Mi|84m|357Mi|1364m|3351Mi|17m|267Mi
|2400|12|60 rpm|15m|270Mi|98m|370Mi|1658m|3921Mi|19m|331Mi
|2800|14|60 rpm|5m|310Mi|334m|450Mi|2062m|4493Mi|19m|406Mi
|3200|16|60 rpm|6m|352Mi|243m|470Mi|2406m|4866Mi|20m|506Mi
|3600|18|60 rpm|22m|386Mi|130m|489Mi|2606m|5346Mi|20m|512Mi
|4000|20|60 rpm|5m|501Mi|138m|523Mi|2904m|6128Mi|20m|620Mi

:::note
Metric Server will peak at 4m/24Mi, Onboarding Operator at 4m/24Mi, and XCP-Operator at 3m/22Mi
:::


