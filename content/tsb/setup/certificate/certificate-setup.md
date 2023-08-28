---
title: Types of Certificates
description: Explains the different types of certificates used in TSB
---

:::note
Since 1.7, TSB supports automated certificate management for TSB management plane TLS certificates, internal certificates and intermediate Istio CA certificates. Go to [Automated Certificate Management](./automated-certificate-management) for more details.
:::

There are 4 types of certificates that TSB operator needs to be aware of: 

1. [TSB Internal Certificates](#tsb-internal-certificates) - Certificates that are used for TSB internal components to trust each other.
1. [Application TLS Certificates](#application-tls-certificates) - Certificates that will be available to the application user web-browser or tools.
1. [Intermediate Istio CA Certificates](#intermediate-istio-ca-certificates) - Intermediate CA certificate for issuing Istio workload leaf certificates.
1. [Workload Leaf Certificates](#workload-leaf-certificates) - Certificates issued to every proxy and gateway.

These certificates and their relation to TSB components and your application are shown in the following image

![](../../assets/setup/certificates-in-tsb.png)

## TSB Internal Certificates

TSB's global control plane (XCP) distributes configuration from the management plane to control plane clusters. XCP is composed of XCP central and XCP edge. XCP central is deployed in the management plane where TSB server interact with it through a component called MPC. XCP edge is deployed in each of the onboarded clusters where user applications run. TSB internal certificates (highlighted green in image above) are used for securing communication between XCP central, XCP edge, MPC component. TSB uses JWT with TLS for secure the communication. You will need to prepare these certificates before deploying TSB.

## Application TLS Certificates

Application TLS certificates (highlighted purple in image above) are used by client applications that should trust to access the application.

Every publicly accessible HTTPS service exposed by your application should have TLS certificates mounted as Kubernetes secrets. TLS certificates for your application must be available when the application is published.

While technically not an "application" you will also need to set up the TLS certificates for the command line tools to access the TSB Management Plane, as well as for you to access the TSB UI via a web browser. TSB TLS certificate must be available before TSB deployment.

## Intermediate Istio CA Certificates

Intermediate Istio CA certificates (highlighted cyan in image above) is mounted in `cacerts` secret on every Control Plane so that Istio workloads leaf certificates can be issued. By default `istiod` acts as a leaf certificate issuer by using Intermediate CA certificate to sign leaf certificates.

The certificate should be signed (or verifiable) by the enterprise Root CA for intra-service communication. The cluster specific Intermediate CA should be available during TSB Control Plane deployment.

For a demo example on setting up Intermediate Istio CA in multi-clusters setup, refer to [Istio documentation](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert). 

For a production environment, It is highly recommended to use production ready PKI infrastructure such as the following, and follow the industry best practices:
1. Using AWS Private CA as enterprise CA to create Intermediate CAs (not an automated process)
2. Integrate existing CA (e.g. [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/), [HashiCorp Vault](https://www.vaultproject.io/)) with [Kubernetes CSR API](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/).

Usually the enterprise security team is in charge of these types of certificates. 

## Workload Leaf Certificates

Leaf certificates (highlighted yellow in image above) are issued to every proxy and gateway (or per workload). These are short lived certificates (by default 24 hour and can be changed by setting using [`defaultWorkloadCertTTL` in `ControlPlane` CR](../../refs/install/controlplane/v1alpha1/spec#istio)).

It's important to understand that these certificates are automatically rotated and are **not** managed by TSB. Istiod is responsible for issuing and rotating the certificates using the Enterprise Intermediate certificates.
