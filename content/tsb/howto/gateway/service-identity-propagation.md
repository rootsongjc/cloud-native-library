---
title: Multicluster Access Control and Identity Propagation
description: Propagating service identities and enforcing access controls between clusters
weight: 2
---

When traffic is forwarded by a gateway, it typically assumes the identity of that gateway. This default behavior simplifies access control configuration for external traffic. However, in a multi-cluster environment, more granular access control is often needed. Tetrate Service Bridge (TSB) offers the capability to preserve the original identity of a request through gateway hops, allowing for cross-cluster authentication and fine-tuned access control.

This documentation explains how to enable and utilize identity propagation in TSB, enabling scenarios such as propagating consumer identities to remote services, implementing detailed access control between different clusters, and applying access control rules to failover targets.

Before proceeding, it's assumed that you are familiar with TSB [concepts](../../concepts) and terminology such as [Ingress Gateways, Tier-1 Gateways, and EastWest gateways](../../concepts/terminology#gateway).

{{<callout note "GitOps">}}
The examples in this documentation use TSB's GitOps feature, which allows you to apply TSB configurations using kubectl. To enable GitOps in your TSB environment, see [Enabling GitOps](../../operations/features/configure_gitops), and learn how GitOps workflows can be used with TSB in [How GitOps works](../../howto/gitops/gitops).
{{</callout>}}

## Enabling Identity Propagation

By default, service identities are not propagated through gateway hops due to TLS termination at the gateways. TSB achieves identity propagation using an internal WebAssembly (WASM) extension on each gateway hop. This extension validates the client identity and appends it to the requests' XFCC header, which is then forwarded.

To enable identity propagation:

1. Add the `enableHttpMeshInternalIdentityPropagation` key to the `xcp` component in the `ControlPlane` CR or Helm values:
```yaml
spec:
  ...
  components:
    xcp:
      centralAuthMode: JWT
      configProtection: {}
      enableHttpMeshInternalIdentityPropagation: true
      kubeSpec:
        ...
        ...
```

2. Configure the `imagePullSecret` for your TSB image registry in the `ControlPlane` CR or Helm values. This is necessary for the WASM extensions to be pulled:
```yaml
spec:
  ...
  imagePullSecrets:
    - name: gcr-secret
  components:
    xcp:
      ...
      ...
```

## Verifying Identity Propagation

After enabling identity propagation, you can verify its status by checking if `ENABLE_HTTP_MESH_INTERNAL_IDENTITY_PROPAGATION` is enabled in the XCP edge:

```sh
kubectl get deployment edge -n istio-system -o yaml | grep ENABLE_HTTP_MESH_INTERNAL_IDENTITY_PROPAGATION -A 1
```

## Use Case 1: Propagating Service Identities through Tier 1 and Tier 2 Gateways

In this use case, we demonstrate how to propagate service identities across clusters using Tier 1 and Tier 2 gateways.

1. Configure two clusters, `cluster-1` and `cluster-2`, sharing the same root of trust. Follow the guide [here](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/) and use [this repo](https://github.com/istio/istio/tree/master/tools/certs) to set up Istio root and intermediate certs.

2. In `tier-1` cluster:
   - Create a dedicated cluster for deploying the `tier-1` gateway.
   - Configure [`networkReachability`](./multi-cluster-traffic-shifting#network-reachability) to establish reachability between `cluster-1` and `tier-1`, and between `tier-1` and `cluster-2`.

3. In `cluster-1`:
   - Create a tenant, `tenant-1`, and its namespace, workspace, and groups.
   - Deploy the [`sleep`](../../reference/samples/sleep_service#deploy-the-sleep-pod-and-service) pod or a similar text client in the `tenant-1-ns`.

4. In `cluster-2`:
   - Create a tenant, `tenant-2`, and its namespace, workspace, and groups.
   - Deploy the [`bookinfo`](../../quickstart/deploy_sample_app) app in `tenant-2-ns` along with an [`ingress gateway`](../../quickstart/ingress_gateway).

5. Verify that a request from the `sleep` pod in `cluster-1` can reach a service in the `bookinfo` app in `cluster-2` via the Tier 1 gateway.

6. Implement access control by denying communications between workspaces or tenants at different levels using appropriate rules and settings.

## Use Case 2: Propagating Service Identities in EastWest Gateway Failover

In this use case, we focus on propagating source identities during service failover in an EastWest gateway setup.

1. In `cluster-1`, create namespaces for the `Client` and `Bookinfo` tenants. Deploy the `bookinfo` and `bookinfo-gateway` services in the `bookinfo-ns`.

2. In `cluster-2`, create the `bookinfo-ns` for the `Bookinfo` tenant. Deploy the `bookinfo` and `bookinfo-gateway` services in the `bookinfo-ns`.

3. Configure `bookinfo-ns`/`bookinfo-gateway` for EastWest failover using `defaultEastWestGatewaySettings`.

4. Implement `allow` and `deny` rules to control communications between different tenants and services.

5. Verify that clients in the `Client` tenant can access the appropriate services while enforcing access control.

6. Observe the behavior of identity propagation during service failover scenarios.

## Troubleshooting

1. Ensure that `enableHttpMeshInternalIdentityPropagation` is correctly set in the `xcp` component of the `ControlPlane` CR.

2. Verify that the `imagePullSecret` is configured in the `ControlPlane` CR to allow the necessary WASM extensions to be pulled.

3. Confirm that the required WASM extensions have been successfully installed in the Istio environment.

4. Ensure that the XFCC header propagation is functioning correctly.

5. If you encounter issues, consult the [Troubleshooting](#troubleshooting) section at the end of this page for further guidance.
