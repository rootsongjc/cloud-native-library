---
weight: 2
title: Concepts
description: Introduction to Tetrate Service Bridge and its concepts.
---

Welcome to the Concepts section of Tetrate Service Bridge (TSB). This section introduces you to the fundamental ideas behind TSB, its architecture, and how it works within your environment.

## How Does TSB Work?

Tetrate Service Bridge is a service mesh management plane that operates on top of your infrastructure, providing a centralized platform to manage and configure networking, security, and observability for your entire mesh-managed environment.

Here's an overview of how TSB works:

1. **Logical Views**: TSB organizes your environment by grouping resources into `services`, `workspaces`, and `groups`, making them easier to manage.

2. **Tenant-based Approach**: TSB encourages you to create `tenants` within your organization. It synchronizes user accounts and teams with your corporate directory, simplifying access management.

3. **Access Control**: TSB allows you to define fine-grained access control, providing editing rights and implementing a zero-trust approach. This enhances security and enables you to monitor activities within your environment.

4. **Audit Trail**: TSB tracks changes to services and shared resources, ensuring an audit trail of all actions, whether approved or denied.

5. **Configuration Management**: TSB lets you author configuration changes and group them into `services`, enabling you to make changes efficiently and manage them collectively.

6. **Isolated Failure Domains**: TSB creates isolated failure domains by giving each cluster its own Istio control plane and gateway. This prevents issues in one cluster from impacting others and enhances application reliability.

7. **Observability and Telemetry**: TSB provides standardized observability and telemetry tools, making it easier to identify issues and monitor your applications in near real-time.

## Key Takeaways

Tetrate Service Bridge is designed with enterprise users and experiences in mind. It offers a comprehensive platform for managing diverse environments, ensuring security, reliability, and observability. To delve deeper into TSB's architecture, refer to the next section of the documentation, or consider trying out TSB in a demo environment.
