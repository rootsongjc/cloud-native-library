---
title: "TSB Architecture"
weight: "2"
description: "An In-Depth Exploration of Tetrate Service Bridge's Architectural Components and Their Interactions."
---

This section focuses on the architecture that comprises TSB and what it entails. You will gain knowledge about the following:

- Our philosophy for reliable deployments, which serves as the driving force behind the TSB architecture
- The Data Plane, which is powered by Envoy
- The Local Control Planes, which are powered by Istio
- Tetrate Service Bridge's Global Control Plane
- Tetrate Service Bridge's Management Plane
- The importance of having a management plane
- Envoy Extensions in Tetrate Service Bridge

By the end of this section, you should have a clear understanding of each element of TSB's architecture and how they work together to assist you in managing your environment.

## Deployment Philosophy

TSB's architecture is based on a strong deployment philosophy that centers around failure domains. This approach involves identifying and isolating the sections of your infrastructure that are affected when critical systems fail. These failure domains are divided into three categories:

- **Physical Failures**: These include host failures, rack failures, hard drive failures, and resource shortages.
- **Logical Failures**: Logical failures consist of misconfigurations, security vulnerabilities, and issues related to dependencies and data.
- **Data Failures**: These involve database issues, bad updates, replication failures, and backup problems.

To create reliable systems, these failure domains are grouped into silos and replicated as independent instances. The reliability of the resulting system depends on minimizing interdependencies between replicas.

### Physical Failure Domains

In modern cloud environments, the group of physical failure domains that need to be taken into account has been condensed into a simple concept called an **[availability zone](../terminology#availability-zone)**. However, we must keep in mind that availability zones are not always completely isolated from one another, as demonstrated by cloud provider outages.

To address this, cloud providers organize multiple availability zones into a higher-level failure domain called a **[region](../terminology#region)**. While it is not uncommon for multiple availability zones in the same region to fail, it is highly unlikely for multiple regions to fail.

Therefore, with availability zones and regions as the physical failure domains to consider, we must also think about the logical failure domain.

### Logical Failure Domains

Logical failures depend largely on our own application architecture and tend to be more complicated to reason about. As application developers, the key elements to consider are our application's deployment, configuration, data, dependencies, and how it is exposed (load balancing, DNS, etc.)

In a typical microservice architecture, we design our applications to consume a cloud-provider database, run it using cloud provider primitives across availability zones in a single region (using Kubernetes, VM auto scaling groups, Container-aaS offering, and so on), and communicate with dependencies that are deployed in the same region as much as possible. When this is not possible, we rely on a global load balancing layer like DNS. This is our silo of failure domains, and we replicate it into other regions for availability, handling data replication in some way (which is a difficult problem and a common failure domain that affects all silos).

### Keeping it Local

One of the easiest ways to create isolated silos without coupled failure domains is to run independent replicas of critical services in each silo. We can say that these replicas are "local" to the silo as they share the same failure domains, including physical ones, which means they are nearby.

At Tetrate Service Bridge, we follow this "keep it local" pattern by running an instance of the Istio control plane in every compute cluster where you run applications. In other words, we deploy Istio so that its physical failure domains align with your applications'. Furthermore, we ensure that these instances are loosely coupled and do not need to communicate directly with each other, minimizing any communication they need to do outside their silo.

This means that each cluster you run is an island, and the failure of one won't cause failures in the others. Moreover, because the control plane is local to the cluster, it has knowledge of what's happening. When there is a failure, it can continue to keep its portion of the mesh behaving as best as possible with the context it has locally.

With this base primitive, we can already start to build more reliable systems by simply failing over across silos holistically. If anything is wrong in a silo, we can ship all traffic to a different silo until we've fixed the problem.

But to take it to the next level, what we'd like to do is facilitate communication across silos when *part* fails, rather than failing over the entire thing. To do this, we need to communicate across our silos.

### Facilitating Cross-Silo Communication

Keeping it local gives us a set of silos that are available but not interconnected. This results in waste and makes failover operations painful.

![Block diagram of updates flowing from K8s to TSB and then back into TSB components in remote clusters as a result.](../../assets/concepts/tsb-multicluster-block-vm.svg)

What we often want to enable is finding a healthy instance of our dependency, even if it's not in our local silo, and route requests to it. For example, if we have a bad deployment of a backend service in one cluster, we'd like the front-end to failover to the existing deployment in our second cluster. TSB facilitates cross-silo communication for applications while minimizing the configuration synchronization required across Istio control plane instances with its global control plane. It publishes the addresses of the entry points for each cluster in the mesh, as well as the set of services available in that cluster, to each Istio instance managed by TSB. When a service fails locally, or a local service needs to communicate with a remote dependency, we're able to direct that traffic to a remote cluster that has the service we need, without the application itself worrying about where the dependency lives.

{{<callout note "Comparison to the Internet">}}

We often use the internet as an example to explain our approach. You have complete knowledge of your local network and to connect to hosts on other networks, you use routes that are published by BGP. These routes provide information on which local gateway to use to forward traffic to reach a remote address. In our setup, each instance of the Istio control plane has complete knowledge of its own local cluster. The global control plane functions similar to BGP, publishing "layer 7 routes" that instruct Istio which remote Gateways (other Istio clusters in the mesh) to use to forward traffic to reach a remote service.

{{</callout>}}

## Architecture Overview

Tetrate Service Bridge's architecture is composed of four layers: the **Data Plane**, **Local Control Planes**, the **Global Control Plane**, and the **Management Plane**.

![The Tetrate Service Bridge Architecture with Local Control Planes, the Global Control Plane, and the Management Plane](../../assets/concepts/tsb-architecture.svg)

- **Data Plane**: The data plane is responsible for inbound and outbound traffic, ensuring traffic and security policies are enforced using the Envoy proxy.
- **Local Control Planes**: Local control planes are deployed within clusters and manage service mesh features, such as providing service identity, encryption, and traffic routing.
- **Global Control Plane**: The global control plane links local control planes, facilitating configuration propagation, service discovery, and disaster recovery across clusters.
- **Management Plane**: The management plane is the primary access point for users who can manage workspaces, groups, and services. This offers efficient administration and control over the environment.

## Data Plane

Istio uses an extended version of the Envoy proxy as the data plane. Envoy is a high-performance edge/middle/service proxy designed to mediate all inbound and outbound traffic for all services in the service mesh. When deployed as sidecars to applications, Envoy proxies augment those applications with traffic management, security, and observability capabilities.

Deploying Envoy as a [sidecar](../terminology#sidecar-proxy) automatically configures all inbound and outbound traffic to go through Envoy. This allows the augmentation of services to happen without requiring any re-architecting or rewriting of the application.

### Modern API Gateway, Web Application Firewall, and other "edge" functionality

With Envoy as the consistent data plane, we can deliver capabilities that were traditionally limited to the edge or DMZ anywhere in our application traffic platform. TSB combines a range of Envoy's features into an easy-to-use package, enabling API gateway features such as token validation, rate limiting, and OpenAPI-spec based configuration. It also brings WAF capabilities to the sidecar, ingress gateways, and edge load balancers. Best of all, TSB allows you to write a single policy and apply it to traffic anywhere: between external clients and your services, across clusters or data centers in your network, or even between services running on the same clusters.

### Extensions

The extension point of TSB in the data plane is WebAssembly. Envoy has several extension points, but normal Envoy extensions require rebuilding and linking the Envoy binary. WebAssembly is a sandboxing technology that can be used to extend Envoy dynamically since Istio 1.6.

The Istio documentation provides an overview of WebAssembly extensions. In TSB, better support for [WebAssembly extensions](.../howto/wasm/wasm-overview) is provided via WASM extensions and Istio's WasmPlugin resource. This helps developers build and test Envoy extensions and integrate with TSB to facilitate extension deployment.

## Local Control Planes

TSB uses Istio for the local control plane within each cluster, providing isolated failure domains with multiple Istio instances, and easy, standardized management from the TSB management plane.

As a user, you can access and control them from the management plane, which means you won't have direct interaction with the local control planes. Additionally, you only need to push a single configuration to update them all.

The local control plane is responsible for:

- Smart local load balancing
- Enforcing zero-trust within the cluster
- Enforcing authentication and authorization at a local level

The control plane is the local access point for TSB to push configurations, mine data, and make intelligent decisions based on cluster activity.

## Global Control Plane

The Global Control Plane (XCP) is part of the management plane, and as a user, you won't have direct access to the global control plane's APIs. The global control plane is responsible for:

- Service discovery between clusters
- Telemetry that is collected from the local control plane and data plane
- Disaster recovery and failover in the case of a gateway outage or cluster failure
- Authentication and Authorization for users and between applications
- Egress controls to determine what can leave the network.

![Creation of bar.com service in us-east propagates up to TSB then out to clusters via XCP.](../../assets/concepts/tsb-bgp.svg)

Global Control Plane enables clusters to communicate with each other and advertise available services.

Global Control Plane is made up of two applications, XCP Central and XCP Edge. XCP Central is deployed in the TSB Management Plane and is responsible for configuration propagation to the XCP Edge applications. XCP Edge applications are deployed in each onboarded cluster, where user applications run, for local translation of TSB configuration to Istio API.

{{<callout note "Comparison of Multi-cluster Methods">}}

Compared to other methods of building a mesh across many clusters using Istio, such as publishing Pod or VM IP address changes for every service for every cluster to all other Istio instances, TSB's method has a very low rate of change of the data that needs to be propagated, the data itself is very small, and there's no n-squared communication needs to happen across clusters, which means it's significantly easier to keep up-to-date and accurate and results in a simpler system overall. Simpler is always easier to run and more reliable. TSB's method of facilitating cross-silo communication results in a very robust and reliable runtime deployment.

{{</callout>}}

## Tetrate Service Bridge Management Plane

The TSB management plane is your main access point to everything in your mesh-managed environment.

The management plane makes it easy to manage your environment by dividing your infrastructure into logical groupings called [**workspaces**](terminology#workspace), [**groups**](terminology#group) and [**services**](terminology#service) which streamline the process of managing your environment.

All changes that impact your mesh-managed environment are handled by the management plane, including runtime actions such as traffic management, service discovery, service-to-service communication, and ingress/egress controls, as well as administrative actions like managing user access (IAM), security controls, and auditing.

## Understanding the Management Plane

In the previous page on the [Service Mesh Architecture](../service-mesh), we introduced the concepts of the data plane and control plane. Above, we introduced the idea of failure domains and why we want to deploy many instances of our local control plane. Having many local control planes naturally means we need something to help make them act as a whole, so the global control plane checks out. But why add another layer over top in the management plane?

Unlike a control plane, whose primary job is to be available, low-latency, and serve data plane configuration as quickly as possible (it changes at the speed of machines), a management plane's primary job is to facilitate user interaction with the system and the workflows between them.

The [management plane](../terminology#management-plane) is the layer that connects the runtime system to the users and teams in your organization. It's what allows you to administer a distributed system in a complex organization with many users and teams, with many different policies and interests, on the same physical infrastructure, safely. It uses Envoy, Istio, and SkyWalking to create a tool that can be used in enterprise to implement controls for regulatory requirements with confidence, maintain many unrelated teams on the same infrastructure without shared fate outages, and let teams move as fast as they want knowing it'll be safe and secure.

We'll talk about what you can do with the Tetrate Service Bridge management plane in the rest of the concepts section, from empowering application developers to manage traffic to applying global policy and managing user access with TSB's IAM system to understanding your entire infrastructure in a single pane of glass. But at a glance, it lets you:

- Control traffic flow in one place no matter where the application or its dependencies are deployed
- Manage who can change what with an advanced permission system (keep application developers from changing security settings; keep the security team from causing app outages)
- Audit every change in the system
- Understand and control traffic flow in your system: internal traffic, ingress, and egress
- Manage control plane lifecycles across your entire infrastructure

## Detailed Data Flow

This detailed, under-the-covers view of Tetrate Service Bridge's components and data flow can help you understand the pieces that make up the runtime system and how data flow between them.

![Detailed diagram of the data flow between TSB components.](../../assets/concepts/tes-architecture-detail.svg)

For a detailed description of each component, refer to [TSB components](../../setup/components). For complete list of ports used by each component, go to [Component ports](../../setup/firewall-information#tsb-components-ports).
