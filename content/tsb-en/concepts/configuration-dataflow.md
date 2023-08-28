---
title: Configuration Data Flow in Tetrate Service Bridge (TSB)
weight: 6
description: "The data flow of configuration within TSB."
---

Tetrate Service Bridge (TSB) employs a structured data flow mechanism to ensure that configuration changes and updates are propagated efficiently and accurately throughout the service mesh infrastructure. This intricate process involves various components, including the management plane, global control plane (XCP Central), and local control planes (XCP Edge), each playing a critical role in the configuration lifecycle.

![Simplified data flow from user input through TSB, XCP, to local control planes.](../../assets/concepts/tsb-data-flow.svg)

## Management Plane

All configuration changes in TSB originate from the management plane. Users interact with TSB configuration through a variety of interfaces, such as gRPC APIs, the TSB UI, and the `tctl` command-line interface. Configuration changes are then persisted in a database, serving as the source of truth for the entire system. The management plane pushes these changes to XCP Central for further distribution.

{{<callout note "MPC Component">}}
For legacy reasons XCP Central receives its configuration via Kubernetes CRDs. A shim server called "MPC" establishes a gRPC stream to TSB's API Server to receive configuration and push corresponding CRs into the Kubernetes cluster hosting XCP Central. MPC also sends a report of the runtime state of the system from XCP Central to TSB, to help users administer the mesh.

An upcoming release of TSB will remove this component, and TSB's API Server and XCP Central will communicate directly via gRPC.

{{</callout>}}

## Global Control Plane - XCP Central

XCP Central acts as an intermediary between the management plane and the local control planes in application clusters. It handles the distribution of runtime configuration, service discovery information, and administrative metadata. This communication occurs through gRPC streams, enabling bidirectional interaction between XCP Central and XCP Edge instances. XCP Central sends down new user configurations, while XCP Edge reports service discovery changes and administrative data. XCP Central also stores a snapshot of its local state as Kubernetes Custom Resources (CRs) within the cluster it operates in.

{{<callout note "XCP Central Data Store">}}
Today XCP Central stores a snapshot of its local state as Kubernetes CRs in the cluster it's deployed in. This is used when XCP Central cannot connect to the Management Plane and XCP Central itself needs to restart (i.e. cannot use an in-memory cache).

When XCP Central receives its configuration directly from TSB via gRPC in a future release, XCP Central will persist its configuration in a database similar to the management plane.

{{</callout>}}

## Local Control Plane - XCP Edge

XCP Edge is responsible for translating the configuration received from XCP Central into native Istio objects specific to the local cluster. It publishes these configurations into the Kubernetes API server, where Istio processes them as usual. XCP Edge also manages the exposure of services across the mesh, contributing to cross-cluster communication and functionality. The configuration information received from XCP Central is stored within the control plane namespace (`istio-system`), ensuring a local cache is available in case of lost connections.

## Detailed Data Flow

![Detailed data flow from user change down to Istio in each cluster.](../../assets/concepts/configuration-dataflow.svg)

The configuration data flow within TSB can be outlined in a series of steps:

1. User initiates configuration change via TSB UI, APIs, or CLI.
2. TSB API Server stores the configuration in its database.
3. TSB pushes the configuration to XCP Central.
4. XCP Central distributes the configuration to XCP Edge instances via gRPC.
5. XCP Edge stores incoming configuration in the control plane namespace (`istio-system`).
6. XCP Edge translates configuration into native Istio objects.
7. Istio processes the configuration and deploys it to Envoys.

Additionally, service discovery information is managed as follows:

1. XCP Edge sends service discovery updates to XCP Central.
2. XCP Central disseminates cluster state information to XCP Edge instances.
3. XCP Edge updates multi-cluster namespace configuration (`xcp-multicluster`) if necessary.
4. Istio processes the configuration and deploys it to Envoys.

## Integration with GitOps

TSB's structured configuration data flow can be seamlessly integrated into a GitOps workflow. This integration occurs through two primary scenarios:

1. Receiving Configuration from CI/CD: TSB can receive configuration updates from a CI/CD system that maintains a source of truth in a Git repository.
2. Management Plane Committing to Git: In future releases, TSB's management plane will have the capability to commit its configuration changes directly to Git, aligning with a GitOps approach.

Both scenarios enable efficient configuration management within the TSB ecosystem, enhancing the reliability and maintainability of the service mesh infrastructure.