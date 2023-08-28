---
title: Traffic Management
weight: 4
description: "Traffic Management and Multi-Cluster Routing in Tetrate Service Bridge (TSB)."
---

Tetrate Service Bridge (TSB) provides robust traffic management capabilities, allowing efficient control over the flow of traffic between services within its domain. TSB simplifies complex tasks such as traffic routing, staged rollouts, and migrations, enhancing the overall approach to application delivery.

This section covers essential aspects of TSB's traffic management:

## Gateways in TSB

![Basic application traffic flow in TSB.](../../assets/concepts/tsb-traffic-flow.svg)

TSB manages traffic routing using a sequence of gateways. When traffic enters your TSB environment, it traverses various gateways before reaching its intended application. The process involves:

1. **Application Edge Gateway**: Also known as the "edge gateway," this shared multi-tenant gateway facilitates cross-cluster load balancing. It directs incoming traffic to the appropriate Application Ingress Gateway.

2. **Application Ingress Gateway**: Referred to as the "app gateway," this gateway is either shared among multiple applications or dedicated to a specific application. It controls how traffic flows and interacts with your applications. Application Ingress Gateways are owned by Workspaces, offering control over traffic flow.

Deploying multiple Ingress Gateways is recommended for isolation and control of traffic. Over time, as confidence in the mesh's usage grows, consolidation onto shared Ingress Gateways can be considered.

## Intelligent Traffic Routing

TSB ensures intelligent traffic routing by leveraging information from local control planes within each cluster. It prioritizes local traffic for optimal performance and availability. Envoy's per-request capabilities enable fine-grained control over traffic routing, supporting scenarios like request stickiness, canary deployments, and distributing traffic evenly across backends.

TSB keeps track of service availability, locality, and health through local control planes. This enables the system to direct traffic to local instances whenever possible. The global control plane maintains service information across clusters, enabling seamless traffic failover and enhanced availability.

## Multi-Cluster Routing

![Creation of bar.com service in us-east propagates up to TSB then out to clusters via XCP.](../../assets/concepts/tsb-bgp.svg)

TSB excels in managing multi-cluster environments, whether in active-active or active-passive configurations. Multi-cluster management is effortless, accommodating scenarios where numerous clusters serve various teams and applications. TSB enables seamless application access across clusters using hostnames, facilitating private communication between services regardless of their cluster location.

## API Gateway Capabilities Everywhere

TSB extends API gateway functionality throughout the application traffic platform. By annotating OpenAPI specifications, developers can configure traffic flow based on their intents. TSB implements these configurations across gateways and internally within the mesh, providing flexibility in rule enforcement. This enables features such as authentication, authorization, rate limiting, WAF policies, and request transformation via WebAssembly (WASM).

## Traffic Splitting and Migrations

TSB streamlines traffic management for migrations, traffic splitting, and canary deployments. The platform empowers application developers with a simple configuration process to alter how services handle traffic. TSB ensures safety, making migrations and changes scalable and manageable. With TSB's observability capabilities, confident monitoring and rollbacks are facilitated, maintaining application availability during infrastructure transitions and updates.

## Conclusion

Tetrate Service Bridge's traffic management capabilities provide granular control over how services communicate and handle incoming requests. From its gateway hierarchy to intelligent traffic routing and multi-cluster support, TSB streamlines traffic management in complex environments, enhancing application availability and performance while simplifying deployment processes.
