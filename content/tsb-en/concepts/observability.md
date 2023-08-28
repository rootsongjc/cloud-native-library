---
title: Global Observability
weight: 5
description: "Global Observability in Tetrate Service Bridge (TSB)"
---

Tetrate Service Bridge (TSB) offers robust global observability capabilities that provide comprehensive insights into the entire service mesh infrastructure. TSB simplifies the process of monitoring and understanding the health and performance of services, enabling efficient operations and troubleshooting.

### Global Topology View

One of the distinctive features of TSB is its ability to provide a consolidated view of the service mesh topology across all enrolled clusters. This enables organizations to grasp the intricate relationships between applications, services, and clusters distributed across various availability zones and regions. The global topology view allows for a holistic understanding of how applications communicate and interact within the larger infrastructure context.

![](../../assets/concepts/tsb-topology.png)

### Service Metrics Overview

TSB offers a service-centric perspective that enables users to monitor the health and performance of their applications regardless of the underlying deployment details or service versions. This aggregated view simplifies the process of assessing the overall health of an application across all clusters and regions.

![](../../assets/concepts/service-details.png)

Furthermore, TSB allows users to drill down into specific aspects of service metrics, individual clusters, and even particular service instances. This granular level of observability empowers users to identify potential issues and bottlenecks with precision, facilitating effective troubleshooting and optimization.

![](../../assets/concepts/service-metrics.png)

### Envoy Metrics Analysis

TSB's global observability also extends to Envoy, the proxy responsible for routing and managing traffic within the service mesh. Users can access detailed metrics related to individual Envoy instances, allowing them to monitor performance metrics and gain insights into the behavior of specific components within the mesh.

![](../../assets/concepts/envoy-instance-metrics.png)