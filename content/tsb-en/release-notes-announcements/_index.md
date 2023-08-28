---
title: "TSB 1.6 Release Notes"
description: Overview of Tetrate Service Bridge 1.6 release.
weight: 1
---

Welcome to the release notes for Tetrate Service Bridge (TSB) version 1.6. This release introduces several new capabilities that enhance availability, security, and visibility. TSB continues to provide a unified approach to connecting and securing services across diverse environments, including Kubernetes clusters, virtual machines, and bare-metal workloads.

## Key Highlights

### Cross-Cluster High Availability and Security

TSB 1.6 focuses on improving availability and security by bringing remote clusters closer together for streamlined management and scalability:

- **Cross-Cluster High Availability for All Services:** Introducing the `EastWestGateway` feature, enabling automatic service failover between clusters without the need for external gateways. Maximize service availability, simplify failover, and enhance security.
- **Cross-Cluster Identity Propagation and Security Domains:** Create scalable security policies spanning clusters, ensuring consistent access control rules for local, remote, and failover services.

### Enhanced Visibility and Troubleshooting

- **Advanced Visibility and Tracing Tools:** Empower application developers to troubleshoot performance issues in distributed applications across clusters. Utilize `tctl collect` to export runtime data for offline analysis, and `tctl troubleshoot` for in-depth investigation.

### Additional Functionality and Flexibility

- **WASM Extensions Support:** Extend the capabilities of proxies (gateways and service proxies) with custom functions using WebAssembly (WASM) extensions. Accelerate innovation, reduce costs, and enforce global application policies.

### Red Hat OpenShift Integration

- **Availability on Red Hat OpenShift:** TSB 1.6 is available on Red Hat OpenShift through the Red Hat Ecosystem Catalog. Gain observability, security, and traffic management for multi-cluster OpenShift environments.

### Future-Ready Security

- **Technical Preview: Tetrate Web Application Firewall (WAF):** Get a glimpse of Tetrate's forthcoming Web Application Firewall, providing advanced L7 protection for all services, internally and externally.

## Beneficiaries of TSB 1.6

TSB 1.6 brings benefits to various roles within your organization:

- **Platform Operators:** Efficiently manage multi-cluster platforms, improve availability, security, and visibility capabilities for platform users, and navigate heterogeneous environments with ease.
- **Service Owners:** Enhance service availability across clusters, troubleshoot performance issues remotely, and collaborate effectively with application developers.
- **Security Teams:** Apply precise security policies in a Zero Trust Architecture, ensuring accurate and consistent access control across clusters.
- **Platform Operators, Service Owners, and Security Teams:** Extend proxy capabilities with custom functions through WASM extensions.

## Notable Capabilities in TSB 1.6

### Cross-Cluster High Availability

- **EastWestGateway:** Achieve seamless, automatic service failover between clusters. Maximize availability, ensure transparency, and enhance security.

### Enhanced Troubleshooting

- **Advanced Visibility and Tracing Tools:** Empower application developers with tools to swiftly identify and resolve performance issues.

### OpenShift Compatibility

- **Certified OpenShift Compatibility:** Deploy TSB 1.6 confidently on Red Hat OpenShift using the Red Hat Ecosystem Catalog.

### WASM Extensions

- **Custom Functionality:** Leverage WebAssembly (WASM) extensions to augment application capabilities and enforce policies.

### Security and Identity

- **Security Domains and Identity Propagation:** Deploy consistent security policies and propagate service identity securely across clusters.

### Istio Enhancements

- **Segmentation and Multi-Istio Support:** Implement isolation boundaries and support for multiple Istio versions within clusters.

### Tetrate Web Application Firewall (WAF) - Technical Preview

- **Advanced L7 Protection:** Gain insights into the upcoming Tetrate Web Application Firewall for comprehensive service protection.

For a complete list of improvements, refer to the [TSB 1.6 Release Notes](./../release-notes).

## Getting Started

To start using Tetrate Service Bridge 1.6:

- Review the [Initial Requirements](./../setup/requirements-and-download) and choose the appropriate platform.
- Select a deployment option based on your needs: quick demo installation, production-ready setup, or upgrading an existing deployment.
- Reach out to Tetrate support for any assistance.

Thank you for choosing Tetrate Service Bridge!