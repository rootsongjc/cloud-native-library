---
title: Automated Certificate Management
description: Describing how to use automated certificate management for TSB 
---

TSB supports automated certificate management for TSB components. You can enable TSB to provision a self signed root CA that will be used to issue certificates such as TLS certificates for TSB management plane, [internal certificates](./certificate-requirements) for communication between control plane to management plane and intermediate CA certificates for application clusters that will be used by Istio in the cluster to issue certificates for application workloads.

:::note External Root CA
TSB's automated certificate management currently does not support using an external root CA. Support for external root CA will be added in a future release.
:::

## Enable Automated Certificate Management

To enable automated certificate management, you need to set the `certIssuer` field in the  TSB management plane CR or helm values:

```yaml
spec:
  certIssuer:
    selfSigned: {}
    tsbCerts: {}
    clusterIntermediateCAs: {}
```

The `certIssuer` field is a map of certificate issuers that you want to enable. Currently, TSB supports the following issuers:
1. `selfSigned`: This will provision a self signed root CA that will be used to issue certificates for TSB components. 
1. `tsbCerts`: This will provision TSB TLS certificates for TSB endpoint and also TSB internal certificates.
1. `clusterIntermediateCAs`: This will provision intermediate CA certificates for application clusters that will be used by Istio in the cluster to issue certificates for application workloads.

To enable automated cluster intermediate CA certificate management, you also need to set the `centralProvidedCaCert` field in the  TSB control plane CR or helm values:

```yaml
spec:
  ...
  components:
    xcp:
      ...
      centralProvidedCaCert: true
```

## Using External Certificate Management

If you want to use external certificate provisioning, you need to remove the relevant issuer from the `certIssuer` field in the TSB management plane CR or helm values to avoid conflict. For examples:

1. To use Let's Encrypt to provision TSB TLS certificate, remove `tsbCerts` from the `certIssuer` field. Note that if you disable this, then you also need to need provision TSB [internal certificates](./certificate-requirements).
1. To use AWS PCA to provision cluster intermediate CA, remove `clusterIntermediateCAs` from the `certIssuer` field and set `centralProvidedCaCert` to `false` in the  TSB control plane CR or helm values.

If you plan to use external certificate management for both `tsbCerts` and `clusterIntermediateCAs`, then you can remove the `certIssuer` field from the TSB management plane CR or helm values.

## Certificate Rotation

TSB will automatically rotate certificates for TSB components and application clusters. Cluster intermediate CA certificates will be rotated every 1 year. TSB TLS and internal certificates will be rotated every 90 days. Currently TSB don't provide a way to configure the rotation period.
