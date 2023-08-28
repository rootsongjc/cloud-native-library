---
title: Security
weight: 3
description: "Security Considerations in Tetrate Service Bridge (TSB) Architecture"
---

Security is a fundamental aspect woven into every layer of the Tetrate Service Bridge (TSB) architecture. TSB's approach is built on the principle of zero trust, where security is at the forefront of every feature and functionality within your mesh-managed environment. This section delves into how TSB treats security as a first-class citizen and provides comprehensive measures to safeguard your applications, support compliance efforts, and prevent outages.

In this section, you'll gain insights into the following key aspects: 

- Tenancy and Abstracted Infrastructure
- Access Control Policies
- Auditability and Logging
- Service Identities for Secure Communication

## Tenancy and Abstracted Infrastructure

TSB introduces a logical hierarchy of resources that offers an abstraction layer over your physical infrastructure. This abstraction enables security considerations and actions that go beyond individual virtual machines (VMs) or pods. TSB's management plane provides a structured framework that simplifies service configuration, making it safer and more manageable.

Instead of dealing with specific VMs or pods, changes made within TSB's management plane apply to collections of resources within your environment. This abstraction helps in better organizing your infrastructure and understanding shared resources, thus minimizing potential pitfalls associated with shared ownership.

### Resource Hierarchy

![Tetrate Service Bridge Resource Hierarchy](../../assets/operations/tsb-resources.svg)

At the core of TSB's hierarchy is the [**organization**](../terminology#organization).

#### Organizations

Each TSB installation contains a single organization, serving as a container for TSB-wide settings. The organization also encompasses teams, users, and clusters. Within the organization, resources are categorized into [**tenants**](../terminology#tenant).

#### Tenants

A tenant in TSB represents a group of individuals or teams that share resources and operate within designated workspaces. Tenancy boundaries provide access control and configuration separation. Tenants can accommodate multiple teams, such as security or development teams. The resources owned by a tenant are further divided into [**workspaces**](../terminology#workspace), which are typically associated with specific teams. Team-level permissions set on a tenant level are inherited, allowing teams to modify resources within their assigned workspaces.

#### Workspaces

Workspaces in TSB provide partitioned areas where teams manage their resources and mesh configurations exclusively. Below a workspace are [**groups**](../terminology#group), which further subdivide into physical services and eventually individual service instances.

Workspaces offer the granularity required for configuring traffic and security access policies. TSB allows setting default configurations for entire workspaces, which automatically apply to all services within those workspaces. However, overrides can be created at the group or configuration level.

## Access Control Policies

TSB enforces access control policies across two main categories: runtime access policies and user management.

### Runtime Access Policies

TSB's logical model allows flexible configuration of runtime security policies like encryption in transit (mutual TLS) and end-user authentication (e.g., JWT-based authentication). These runtime access policies utilize service identities, which are fundamental components of TSB's Zero Trust Architecture (ZTA).

User management access policies facilitate the configuration of permissions for different user roles, ensuring clear and granular access control to TSB's features.

### User Access Policies

Every resource within TSB is associated with an access policy that defines authorized access under specific conditions. TSB aligns with your organizational structure by integrating data from your corporate identity provider (e.g., LDAP) and mapping it internally using Next Generation Access Control (NGAC). This alignment results in access control policies that respect organizational boundaries and prevent users from affecting resources outside their designated scope.

TSB's user and team resources can be managed via [Teams and Users APIs](../../refs/tsb/v2/team). However, TSB's integration with identity providers like LDAP and OIDC ensures that most user data is automatically synced, reducing the need for direct interaction with these APIs.

### User Access and Resource Hierarchy

TSB's [RBAC APIs](../../refs/tsb/rbac/v2/policy_service) allow assigning permissions to users and teams within TSB's resource hierarchy. These permissions are inherited downwards in the hierarchy. Combined with TSB's sophisticated IAM system that supports custom roles and fine-grained permissions, users have extensive control over who can perform specific actions on managed infrastructure.

For instance, in regulated industries, TSB empowers central security teams to configure encryption in transit for the entire infrastructure. They can audit the entire system and control encryption settings at an organizational level. Line-of-business security teams can further configure security controls for their specific segments of the infrastructure, while application teams can focus on development without compromising security settings.

## Auditability and Logging

TSB maintains an audit trail of all changes made to controlled resources, offering robust auditability features. Every resource within TSB can be audited, providing comprehensive details such as who made changes, when, and the exact nature of modifications. This information is accessible through [TSB audit logs APIs](../../refs/audit/v1/audit).

The TSB audit logs APIs are closely linked with the permission system, ensuring that audit logs only display entries relevant to resources users have permission to access.

## Service Identities for Secure Communication

TSB relies on service identities instead of IP or network locations for enhanced network security and access control. Istio powers service identity within TSB, providing each workload with a verifiable identity for authentication and authorization at runtime. These identities, issued by Istio, are rotated at runtime to establish the basis for secure communication between workloads and encryption in transit.

TSB leverages these service identities to enable application developers and security teams to define granular access control policies. These policies dictate which services can communicate and how, while also limiting the surface area for potential attacks. By using service identities, TSB decouples access control policies from underlying network and infrastructure components, ensuring their portability across various environments such as cloud, Kubernetes, on-premises, and virtual machines.

## Conclusion

Security is a core tenet of TSB's architecture, deeply integrated into its design principles and every layer of functionality. From providing fine-grained access control through the resource hierarchy to enabling secure communication via service identities, TSB ensures a robust security posture for your mesh-managed environment. By aligning security with organizational structures and providing comprehensive audit capabilities, TSB empowers organizations to manage resources confidently, adhere to compliance requirements, and maintain a highly available and secure application landscape.
