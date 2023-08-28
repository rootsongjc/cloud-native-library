---
title: Internal Certificates Requirements
description: Requirements for certificates used for internal communication within TSB
---

Before you continue, make sure you:  <br />
✓ Understand [the 4 types of certificates](./certificate-setup) in TSB particularly [internal certificates](./certificate-setup#tsb-internal-certificates).

:::note
Please note that the certificates described here are solely used for the communication between TSB components,
and thus are not part of your workloads' certificates that are typically managed by Istio or application TLS certificates. 
:::

:::warning
In case you have installed `cert-manager` in the management plane cluster, you can use tctl
to automatically install required issuer and certificate in the management plane and create control 
plane certificate. Please see the documentations for [Management Plane Installation](../self_managed/management-plane-installation) and 
[Onboarding Clusters](../self_managed/onboarding-clusters) for more details.
:::

To use JWT authentication with regular (non-mutual) TLS, the XCP central certificate must include its address in its subject alternate names (SANs). This will either be a DNS name or an IP address.

Similar with mTLS above, XCP central in the management plane uses the certificate stored in a secret named `xcp-central-cert`
in the management plane namespace (which defaults to `tsb`). The secret must contain data for the
standard `tls.crt`, `tls.key`, and `ca.crt` fields.

Below is an example of XCP central certificate as `cert-manager` resource if you are using IP address.

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: xcp-central-cert
  namespace: tsb
spec:
  secretName: xcp-central-cert
  ipAddresses:
  - a.b.c.d  ## <--- IP Address here
  issuerRef:
    name: xcp-identity-issuer
    kind: Issuer
  duration: 30000h
```

Or, if you are using domain names, edit the field `spec.dnsNames`

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: xcp-central-cert
  namespace: tsb
spec:
  secretName: xcp-central-cert
  dnsNames:
  - example-tsb.tetrate.io ## <-- DNS name here
  issuerRef:
    name: xcp-identity-issuer
    kind: Issuer
  duration: 30000h
```

:::warning DNS name when creating certificate with tctl
If you use tctl to automatically install required issuer and certificate, XCP central cert will have `central.xcp.tetrate.io` as the DNS name.
:::
