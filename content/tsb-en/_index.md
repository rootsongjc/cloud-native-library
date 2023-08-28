---
weight: 1
title: Tetrate Service Bridge 中文文档
summary: "Tetrate Service Bridge（TSB）文档：安装、使用和升级。"
date: '2023-08-09T12:00:00+08:00'
type: book
icon: book
icon_pack: fas
cascade:
  commentable: false
  categories: ["TSB"]
  tags: ["TSB"]
  type: book
  draft: true
---

Explore this developer hub to access comprehensive guides and documentation that will accelerate your familiarity with TSB. Whether you're an Application Developer, Platform Operator, or Security Administrator, we've tailored the content to address your needs. If you encounter any obstacles, rest assured that support is readily available.

## For Application Developers

As an Application Developer deploying applications into environments using TSB, you'll experience a simplified process. Begin by deploying your application with a [Sidecar Proxy](./concepts/terminology#sidecar-proxy). Afterward, delve into advanced configurations such as routing traffic to your application, implementing rate limiting, or partitioning traffic between VMs and Kubernetes applications for gradual modernization.

### 1. Understand Key Concepts

1. [Grasp Service Mesh Architecture](./concepts/service-mesh)
1. [Explore TSB's Architecture](./concepts/architecture)
1. [Efficient Traffic Management](./concepts/traffic-management)
1. [Global Observability with TSB](./concepts/observability)

### 2. Deploy and Configure Applications
1. [Deploy Applications with Sidecar](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/) - Familiarize yourself with Istio's troubleshooting resources if needed.
1. [Configure TSB for External Traffic](./howto/traffic/load-balance)
1. [Utilize OpenAPI Annotations](./howto/gateway/application-gateway-with-openapi-annotations)

### 3. Efficient App Management

1. [Monitor Metrics and Traces](./quickstart/observability)

### 4. Address Common Use Cases
1. [Directing Traffic to Applications](./howto/gateway/app-ingress)
1. [Implementing Rate Limiting](./howto/rate-limiting/toc)
1. [Gradual Canary Releases](./howto/traffic/canary-releases)
1. [Migrating VM Traffic to Kubernetes](./howto/traffic/migrating-VM-monoliths)
1. [Failover Across Clusters](./howto/gateway/multi-cluster-traffic-shifting#traffic-shifting)

### 5. Valuable References
1. [TSB Frequently Asked Questions](./knowledge-base/faq)
1. [Official Istio Documentation](https://istio.io/latest/docs/)

## For Platform Operators

For Platform Operators transforming clusters into a unified mesh using TSB, the journey starts with [installing TSB's management plane](./setup/self-managed/management-plane-installation). You'll also onboard application clusters for observability and control, and grasp the application deployment process through [demo application deployment](./quickstart/introduction).

### 1. Master Foundational Concepts
1. [Grasp Service Mesh Architecture](./concepts/service-mesh)
1. [Dive into TSB's Architecture](./concepts/architecture), including the management, control, and data planes
1. [Efficient Traffic Management](./concepts/traffic-management)
1. [Global Observability with TSB](./concepts/observability)
1. [Understand Configuration Dataflow](./concepts/configuration-dataflow)
1. [Hierarchy of Resource & Permissions (IAM)](./operations/users/roles-and-permissions)

### 2. Installation, Configuration, and Operations
1. [Resource Planning for TSB](./setup/resource-planning)
1. [Install TSB's Management Plane](./setup/self-managed/management-plane-installation)
    - [Set Up OIDC Login](./operations/users/oidc-azure) - Modify LDAP-based login with OIDC.
1. [Onboard Clusters for Applications](./setup/self-managed/onboarding-clusters)
1. [Deploy and Configure Ingress Proxies](./quickstart/ingress-gateway)
1. [Comprehend Certificate Requirements](./setup/certificate/certificate-requirements)
1. [Upgrade TSB Versions](./setup/self-managed/upgrade)
1. [Manage TSB ImagePullSecrets](./setup/remote-registry)
1. [Employ GitOps with the Service Mesh](./knowledge-base/gitops)
1. [Monitor Configuration Status](./troubleshooting/configuration-status)

### 3. Administration and Operation
1. [Access Management for TSB](./operations/users/roles-and-permissions)
1. [Default Log Levels for Applications and TSB](./operations/configure-log-levels)
1. [Alerting Guidelines for TSB Components](./operations/telemetry/alerting-guidelines)
1. [Troubleshooting with TSB's Debugging Container](./troubleshooting/debug-container)
1. [Implement GitOps](./howto/gitops/gitops)

### 4. Useful Resources
1. [TSB FAQ](./knowledge-base/faq)
1. [TSB Installation and OIDC Reference](./refs/install/managementplane/v1alpha1/spec#oidcsettings)
1. [Firewall Configuration for TSB Communication](./setup/firewall-information)

## For Security Administrators

The service mesh empowers security teams to implement and enforce policies centrally while maintaining developer agility.

### 1. Grasp Crucial Concepts
1. [Understand Service Mesh Architecture](./concepts/service-mesh)
1. [Explore High-Level TSB Security Overview](./concepts/security)
1. [Explore the Management Plane/Runtime Split](./concepts/architecture)

    #### Management Plane Security
    1. [IAM: Resource & Permission Hierarchy](./operations/users/roles-and-permissions)
    1. [Delve into Runtime Architecture](./concepts/architecture)
    
    #### Application Runtime Security
    1. [Understand Service Identity](./concepts/security#service-identities-at-runtime)
    1. [Implement Service-to-Service Authorization](https://istio.io/latest/docs/concepts/security/#authorization) (thin layer over TSB)
    1. [Authenticate End Users with the Mesh](./howto/gateway/end-user-auth-keycloak)
    
### 2. Implement Controls for Applications
1. [Enforce (m)TLS Everywhere](./quickstart/security#create-security-setting)
1. [Apply Service-to-Service Authentication and Authorization](./quickstart/security#create-security-setting)
1. [Manage Egress to External Services](./howto/gateway/egress-gateways)
1. [Implement End-User Authentication](./howto/gateway/end-user-auth-keycloak#enabling-authentication-and-authorization-at-ingress)
1. [Configure Envoy's External Authorization APIs](./howto/authorization/toc)

### 3. Ensure Controls are Enforced

1. [Monitor Service-Service Traffic with Global Observability](./concepts/observability)
1. [Audit Log Overview and API](./concepts/security#auditability)
   
### 4. Access Management to TSB
1. [Utilize Tenants, Workspaces, and Groups](./operations/users/roles-and-permissions#resource-model) with [Flexible RBAC](./operations/users/roles-and-permissions#access-bindings)
1. [Firewall Requirements for TSB Connectivity](./setup/firewall-information)
   
### 5. Valuable References
1. [TSB FAQ](./knowledge-base/faq)
1. [Istio Security Overview](https://istio.io/latest/docs/concepts/security/)
1. [TSB's RBAC Access Control API Reference](./refs/tsb/rbac/v2/yaml)
