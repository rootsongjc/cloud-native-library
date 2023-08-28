---
title: Service Mesh Introduction
description: Introduction to the Service Mesh architecture and its benefits.
weight: 1
---

The Service Mesh architecture has gained widespread adoption, and Tetrate's team comprises some of the earliest engineers who developed the technologies that support this architecture. In this section, we'll provide an introduction to the architecture, its terminology, capabilities, features, and focus on Istio, the leading mesh implementation that powers Tetrate Service Bridge.

## What is a Service Mesh?

A service mesh is an infrastructure layer positioned between the components of an application and the network through a proxy. While these components are often microservices, any workload, from serverless containers to traditional n-tier applications on VMs or bare metal, can participate in the mesh. Instead of direct communication between components over the network, proxies intercept and manage that communication.

![Service Mesh architecture: control plane and data plane](../../assets/concepts/service-mesh-architecture.svg)

### The Data Plane

The proxies, referred to as "sidecar proxies," since they're deployed alongside each application instance, constitute the [**data plane**](../terminology#data-plane) of the service mesh. They handle application traffic at runtime. Tetrate Service Bridge employs [**Envoy**](../terminology#envoy) as the data plane implementation. Envoy offers a plethora of capabilities for security, traffic policy, and telemetry, including:

- Service discovery
- Resiliency mechanisms (retries, circuit breaking, outlier detection)
- Client-side load balancing
- Fine-grained L7 traffic control
- Security policy implementation per request
- Authentication, rate limiting, policy based on L7 metadata
- Workload identity with strong L7 identity
- Service-to-service authorization
- Extensibility using WASM Extensions
- Metrics, logs, and tracing

By shifting these capabilities from applications to sidecar proxies, a [**control plane**](../terminology#control-plane) can be introduced to dynamically configure the data plane, offering a range of benefits.

### The Control Plane

The control plane is responsible for runtime configuration of data plane proxies. It transforms declarative configuration from the control plane into concrete runtime configurations for Envoy. The control plane orchestrates multiple Envoy proxies, creating a cohesive *mesh*.

With a sidecar proxy for every application instance and a dynamic control plane, the service mesh provides centralized control with distributed enforcement. This level of control isn't achievable through frameworks and libraries, offering benefits such as:
1. Centralized visibility and control
2. Consistency across the entire environment
3. Efficient policy changes through code-based configuration
4. Separate lifecycle for capabilities from application lifecycle

Tetrate Service Bridge leverages [**Istio**](./terminology#istio) as its control plane to configure Envoy proxies at runtime.

## Origins of the Service Mesh

The service mesh architecture emerged concurrently at various companies in the early 2010s to address challenges in adopting a service-oriented architecture. Google's journey led to the creation of a proto-service mesh that solved problems such as shared fate outages, cost attribution, and cross-cutting feature implementation.

After experiencing the benefits of the service mesh internally, Istio was born to bring these capabilities to the world. Tetrate was founded to cater to enterprises facing similar challenges in modernization and cloud adoption.

## API Gateways and the Service Mesh

The service mesh architecture originated as a distributed API gateway, addressing cross-cutting concerns. With the prevalence of microservice architectures, internal traffic substantially outweighs external traffic. This shift, along with the move towards zero-trust security, drives the mesh to handle traffic across environments.

As a result, the API Gateway's capabilities are becoming integral to the application traffic platform, available everywhere in the platform. Other capabilities, traditionally considered "edge" appliances, are also merging into the application traffic platform.

## Istio: The Leading Mesh Implementation

The service mesh functions as the security kernel for microservices-based applications, making the choice of mesh implementation critical for application and information security. Istio, the most widely used and supported service mesh, serves as the reference implementation for microservices security standards. It aligns with NIST's guidelines and boasts active bug bounties, security audits, and CVE patches.

Istio evolves alongside the Kubernetes ecosystem, offering seamless integration and standardization. Tetrate's team, composed of early Istio contributors, chose Istio as the mesh to power Tetrate Service Bridge.

Continue reading to discover how TSB leverages Istio to unify your infrastructure into a cohesive mesh.