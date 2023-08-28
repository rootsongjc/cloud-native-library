---
title: Feature Status
description: Status of included features.
---

The following table shows existing TSB features and their current phases. This table will be updated every major or minor release. 

## Feature Phase Definitions

The following table defines maturity phase of TSB features. 

| Stages | Alpha (Technical Preview) | Beta | Stable |
| --- | --- | --- | --- |
| Features | May not contain all of the features that are planned for the final version. | Feature complete but likely to contain a number of known or unknown bugs. | Feature complete with no known bugs.
| Production usage | Should not be used in production. | Usable in production. | Dependable, production hardened.
| API |No guarantees on backward compatibility. | APIs are versioned. | Dependable, production-worthy. APIs are versioned, with automated version conversion for backward compatibility.
| Performance | Not quantified or guaranteed. | Not quantified or guaranteed. | Performance (latency/scale) is quantified, documented, with guarantees against regression.
| Documentation | Lack of documentation. | Documented. | Documented with use cases.
| Environment | Tested on single environment (EKS or GKE only). | Tested on at least two environments. (EKS, GKE, OpenShift) | Well tested on multiple environments. (AKS, EKS, GKE, MKE, OpenShift)
| Monitoring | Not all important metrics available. | Most of important metrics are available. | All of important metrics are available.

## Feature Status Table

| Area  | Description  | Status  | API | tctl | UI
| --- | --- | --- | :---: | :---: | :---:
| **Installation** |||||
| | tctl install | Stable | N | Y | N
| | Helm install | Stable | N | N | N
| | Istio isolation boundaries | Alpha | N | N | N
| **Users & Access** |||||
| | Automatic synchronization of users & teams from LDAP | Stable | Y | Y | Y
| | Automatic synchronization of users & teams from Azure AD | Stable | Y | Y | Y
| | Roles | Stable | Y | Y | Y
| | Permissions | Stable | Y | Y | Y
| | SSO with OIDC | Stable | Y | Y | Y
| **Configuration** |||||
| | Workspaces |Stable | Y | Y | Y
| | Config Groups | Stable | Y | Y | Y
| | Configuring Bridged Mode - Traffic | Stable | Y | Y | Y
| | Configuring Bridged Mode - Security | Stable | Y | Y | Y
| | Configuring Bridged Mode - Gateway | Stable | Y | Y | Y
| | Configuring Direct Mode - Traffic | Stable | Y | Y | Y
| | Configuring Direct Mode - Security | Stable | Y | Y | Y
| | Configuring Direct Mode - Gateway | Stable | Y | Y | Y
| | Configuring Direct Mode - IstioInternal | Stable | Y | Y | Y
| | Tier 1 Gateway | Stable | Y | Y | Y
| | Ingress Gateway (Tier 2) | Stable | Y | Y | Y
| | EastWest Gateway | Beta | Y | Y | Y
| | VM Gateway | Stable | Y | Y | Y
| | Egress Gateway | Beta | Y | Y | Y
| | TCP Traffic | Beta | Y | Y | Y
| | Config Status Propagation | Beta | Y | Y | Y
| | GitOps/Kubernetes CRD | Beta | N | N | N
| | Hierarchical Policies | Beta | Y | Y | Y
| | Restricted Hierarchical Policies | Beta | Y | Y | Y
| | Allow/Deny Rules | Beta | Y | Y | Y
| | Security Domain | Alpha | Y | Y | Y
| | Service Security Settings | Alpha | Y | Y | Y
| | Identity Propagation | Alpha | Y | Y | Y
| **Application** |||||
| | Application | Beta | Y | Y | Y
| | Configuring API with OpenAPI Spec | Beta | Y | Y | Y
| **API Gateway** |||||
| | Rate limit | Beta | Y | Y | Y
| | External authorization | Beta | Y | Y | Y
| | WASM Extensions | Beta | Y | Y | Y
| | WAF | Alpha | Y | Y | Y
| **Observability** |||||
| | Service Metrics | Stable | N | N | Y
| | Service Topology | Stable | N | N | Y
| | Service Tracing | Stable | N | N | Y
| **Service Registry** |||||
| | Kubernetes services | Stable | N | Y | Y
| | Istio ServiceEntries | Beta | N | Y | Y
| **VM Workloads** |||||
| | tctl based VM Onboarding | Beta | N | Y | N
| | Workload Onboarding for EC2 | Beta | N | Y | N
| | Workload Onboarding for On-Premise workload | Beta | N | Y | N
| | Workload Onboarding for ECS | Beta | N | Y | N
