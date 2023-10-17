---
title: Understanding HA
---

# Understanding HA and DR for the Tetrate Management Plane

_This guide describes the DR scenarios and impact for the Tetrate Management Plane.  It applies to both Tetrate Service Bridge (TSB) and Tetrate Service Express (TSE)._

The design of the Tetrate Management Plane (and the distributed control plane architecture) provides the following attributes:

 - **Architecture is loosely coupled**: Tetrate architecture by design is loosely coupled and self-healing, meaning that the 'blast radius' of failures is limited, and the platform quickly settles on a good configuration when components recover.
 - **All Tetrate components are stateless and can recover from failure:** The only exceptions are the Postgres DB (configuration and audit logs) and ElasticSearch DB (metrics), plus secrets in the K8s cluster
 - **Apps and Services are not affected:** Failures in any management or control plane component do not affect the correct operation or security of applications and services running in the workload clusters.
 - **High Availability:** We recommend running workloads in a redundant, HA fashion. A redundant, HA management plane is possible, but brings limited benefits in Tetrate’s loosely-coupled architecture, at the cost of resource usage and additional complexity.




## High-Availability and DR with Tetrate

### Workloads and Dataplane HA

Tetrate can help you to manage and operate multiple production clusters across regions and clouds, to create a redundant dataplane.  Capabilities such as Tetrate's Edge and East-West gateways, plus integration with GSLB solutions such as [Amazon Route 53](https://docs.tetrate.io/service-express/integrations/route53) provide high-availability for production workloads in the event of failure in Workload clusters for any reason.

:::warning Istio multi-region DR configurations

Tetrate's solution does not rely on any of the [multi-region DR configurations](https://istio.io/latest/docs/ops/deployment/deployment-models/) for the Istio dataplane.  These are required when no higher-level control plane is in place, and they add significant complexity and additional failure scenarios.  Tetrate's Control Plane architecture means that single istio-per-cluster deployments are entirely sufficient and provide better isolation in the event of a failure.  Furthermore, smaller failure domains make progressive upgrades easier and less risky.

:::

### Management and Control Plane HA

Most components in the Tetrate Management and Control Planes can recover from failures, re-sync configuration and resume correct operations without any user interaction.

The Central Control Plane cannot operate in a redundant fashion, but achieves high availability by virtue of caching all configuration in the local Kubernetes API server (tsb namespace), and re-syncing from the Management Plane and from remote Edge Control Plane instance whenever needed.  Any failures in the Central Control Plane are quickly recovered from with no lasting effects.

The Management Plane maintains configuration and stores audit logs in a PostgreSQL database:

 - When deploying TSB, customers provide and maintain a suitable PostgreSQL instance
 - When deploying TSE, a simple PostgreSQL instance is included and is managed by TSE. This can be replaced with a customer-provided instance

Tetrate share the following advice:

 - Maintain a highly-available PostgreSQL database for Management Plane configuration
 - Maintain periodic backups of the database if necessary

For a detailed description of the various failure and recovery scenarios, read the [Failure Scenarios](scenarios) explanations.

### Management Plane DR

If redundancy of the Management Plane (separate from the database) is required, it is possible to run two Management Plane instances in an active-standby configuration, as described in the [Management Plane DR](dr-managementplane) explanation.


