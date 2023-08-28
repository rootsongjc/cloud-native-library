---
title: Cluster onboarding troubleshooting
description: How to troubleshoot control plane onboarding issues
---

This document explains most common issues when onboarding new control planes into TSB.

## Connectivity

The deployment `tsb-operator-control-plane` needs to have connectivity with the management plane URL. Communication is performed to 
the `front-envoy` component in the `tsb` namespace, which is served by the `envoy` service.

Make sure that the control plane can reach it and it's not blocked by network policies, security groups or any firewall.

## Troubleshooting

Once you've applied the [necessary secrets](../setup/helm/controlplane#secrets-configuration), installed the control plane operator 
and created the control plane CR, if there's some misconfiguration, some pods won't be able to start. Always check for `tsb-operator-control-plane` 
logs, as it will give more information about what could be wrong.

### Service account issues

If the service account to generate the tokens is not created, you'll get the following error:

```bash
error	controlplane	token rotation failed, retrying in 15m0s: secret istio-system/cluster-service-account not found: Secret "cluster-service-account" not found [scope="controlplane"]
```

Or it can also happen that it is not correctly configured:

```bash
error	controlplane	token rotation failed, retrying in 15m0s: cluster has been configured with incorrect service account secret. ControlPlane CR has cluster name "demo", but service account secret has "organizations/tetrate/clusters/not-demo" [scope="controlplane"]
```

In this example, we've created a cluster object called `demo`, but in the CP we're generating the service account for a cluster called `not-demo`. 
To fix this issue you'll need to add the cluster name and service account token to the `values.yaml` file to install the CP. First generate the token:

```bash
tctl install cluster-service-account --cluster demo > /tmp/demo.jwk
```

And then configure the `values.yaml` file with the cluster name and the JWK file:

```yaml
secrets:
  tsb:
  ...
  clusterServiceAccount:
    clusterFQN: organizations/tetrate/clusters/demo
    JWK: |
      '{{ .Secrets.ClusterServiceAccount.JWK }}'
```

The cluster name needs to match with the cluster name added in the control plane CR under `spec.managementPlane.clusterName`.

:::note
Remember to restart the `tsb-operator-control-plane` pod to generate the secrets, and once generated, restart the control plane pods.
:::

### Control plane certificate issues

If the certificate `tsb-certs` configured in the management plane don't contain the correct URI SAN which is configured in 
the control plane CR under `spec.managementPlane.host`, or both `tsb-certs` in `tsb` namespace and `mp-cert` in `istio-system` 
namespace doesn't contain the same URI SAN, or are not signed by the same root/intermediate CA you'll get the following error:

```bash
error	controlplane	token rotation failed, retrying in 7.153870785s: generate tokens: rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate is valid for demo.tsb.tetrate.io, not tsb.tetrate.io" [scope="controlplane"]
```

You can update the `mp-cert` by configuring the value `secrets.tsb.cacert` in your control plane `values.yaml` file, or update 
the `tsb-certs` by configuring the values `secrets.tsb.cert` and `secrets.tsb.key` in the management plane `values.yaml` file.

If the certificate provided in `tsb-certs` is signed by a public CA such as Digicert or Let’s Encrypt you can let the default values 
for the control plane CR, but if this certificate is signed by an internal CA or it's self signed you can get the following error:

```bash
error	controlplane	token rotation failed, retrying in 1.661766738s: generate tokens: rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: x509: certificate signed by unknown authority" [scope="controlplane"]
```

If that's the case, you'll need to modify the control plane CR to set `spec.managementPlane.selfSigned` to `true`.

:::note
Remember to restart the `tsb-operator-control-plane` pod to generate the secrets, and once generated, restart the control plane pods.
:::

### XCP connection issues

If the newly onboarded cluster it's not reporting the cluster status or new configurations applied are not being created in the cluster, 
check the `edge` pod logs in `istio-system` namespace, as even if the pod is running, it is possible that it's having some issues. For example:

```bash
warn	stream	error getting stream. retrying in 21.72809085s: rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate is valid for xcp.tetrate.io, not tsb.tetrate.io"	name=configs-4d116fd6
```

In this case the `xcp-central-cert` in `tsb` namespace is configured for `xcp.tetrate.io` but the host configured in the control plane 
CR is `tsb.tetrate.io`. To update the certificate, you'll need to update the management plane `values.yaml` [accordingly to this](../setup/helm/managementplane#xcp-secrets-configuration).

If `edge` is unable to start you can describe to pod in order to get more information. Sometimes it couldn't start due to:

```bash
  Warning  FailedMount  7m15s (x7 over 7m47s)  kubelet            MountVolume.SetUp failed for volume "xcp-central-auth-jwt" : secret "xcp-edge-central-auth-token" not found
  Warning  FailedMount  5m44s                  kubelet            Unable to attach or mount volumes: unmounted volumes=[xcp-central-auth-ca], unattached volumes=[config-map-volume xcp-central-auth-jwt xcp-central-auth-ca xcp-edge-webhook-ca kube-api-access-hxk8l webhook-certs]: timed out waiting for the condition
  Warning  FailedMount  3m26s                  kubelet            Unable to attach or mount volumes: unmounted volumes=[xcp-central-auth-ca], unattached volumes=[xcp-edge-webhook-ca kube-api-access-hxk8l webhook-certs config-map-volume xcp-central-auth-jwt xcp-central-auth-ca]: timed out waiting for the condition
  Warning  FailedMount  95s (x11 over 7m47s)   kubelet            MountVolume.SetUp failed for volume "xcp-central-auth-ca" : secret "xcp-central-ca-bundle" not found
  Warning  FailedMount  69s                    kubelet            Unable to attach or mount volumes: unmounted volumes=[xcp-central-auth-ca], unattached volumes=[kube-api-access-hxk8l webhook-certs config-map-volume xcp-central-auth-jwt xcp-central-auth-ca xcp-edge-webhook-ca]: timed out waiting for the condition
```

This error is because the secret `xcp-central-ca-bundle` in `istio-system` namespace don't exist. This secret must contain the same URI SAN and must 
be signed by the same root/intermediate CA as `xcp-central-cert` in `tsb` namespace. In order to configure this secret, you'll need to update the value 
`secrets.xcp.rootca` from your control plane `values.yaml` file.

:::note
Remember to restart the `tsb-operator-control-plane` pod to generate the secrets, and once generated, restart the edge pod.
:::
