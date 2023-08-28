---
title: Terminology
description: "A handy list of terms used when describing TSB and its environment."
weight: 9
---

### Tetrate Service Bridge (TSB)

#### Tetrate Service Bridge (TSB)

TSB is a service mesh management plane designed to provide centralized control over infrastructure. It maps to your organization's structure, enabling you to manage resources, access rights, networking, and security.

#### Organization

An organization represents the corporation that manages the shared infrastructure, consisting of multiple tenants and workspaces.

#### Tenant

A tenant is a subgroup within an organization, such as a team or department, that shares resources and access privileges.

#### Workspace

A workspace is a defined area where teams manage their namespaces. It isolates configurations associated with specific teams' namespaces across various clusters.

#### Service

A network-accessible destination with a unique identity and authentication.

#### Group

Logical grouping of resources within a workspace, categorized as gateway, traffic, or security groups.

#### Application

A logical grouping of services that expose APIs, managed within a tenant's workspace. It enables developers to configure service behavior and access conditions.

#### Application API

A set of endpoints exposed by an application, enabling developers to configure behavior using OpenAPI documents.

#### User

An entity, including humans and non-person entities, associated with TSB. Users can be organized into teams and assigned access via RBAC.

#### Team

A group of users assigned access to resources using RBAC. Teams are recommended for access assignment, enhancing security.

### Architectural Components

#### Management Plane

The primary interface to configure networking, security, and observability within TSB's environment.

#### Global Control Plane / XCP

Part of the management plane, responsible for multi-cluster features and state management.

#### Control Plane

Local Istio service mesh deployed in each cluster to manage networking, traffic routing, and security within the cluster.

#### Data Plane

Powered by Envoy, facilitates data transfer between services using sidecar proxies.

#### Sidecar Proxy

Envoy instance deployed alongside applications, handling traffic management, security, and observability.

#### Load Balancer

Distributes incoming requests among servers based on availability and capacity.

#### Gateway

A load balancer at the edge of a mesh, used for incoming/outgoing HTTP/TCP connections.

#### Service Registry

Central point listing every service within TSB's onboarded clusters.

#### Front Envoy (Envoy Gateway)

Envoy gateway accepting incoming traffic to TSB components.

### Other Terminology

#### Kubernetes

An open-source container orchestration platform.

#### Cluster

A set of compute nodes containing Kubernetes pods, VMs, or bare-metal resources.

#### Namespace

Kubernetes grouping of resources, logically organizing containers, pods, or nodes.

#### Failure Domain

A portion of the environment prone to failure when a critical component experiences issues.

#### Silo

A group of failure domains forming a unit for reasoning and replication.

#### Availability Zone

Isolated location in a cloud provider's region for deploying resources, subject to correlated failure modes.

#### Region

Physical locations encompassing data centers, containing availability zones.

### OSS Projects

#### Istio

An open-source service mesh providing network automation and flexibility.

#### Envoy

An L7 proxy and communications system for modern architectures.

#### SkyWalking

An observability application platform and APM tool offering distributed tracing and metrics aggregation.

#### Next Generation Access Control (NGAC)

A graph-based access control system enhancing traditional ABAC.
