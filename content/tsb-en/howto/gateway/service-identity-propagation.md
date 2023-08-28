---
title: Multicluster Access Control
description: Propagating service identities between clusters
weight: 2
---

When traffic is forwarded by a gateway, by default it takes on the identity of that gateway. This default behavior allows an administrator to easily configure access controls for all external traffic. For example, an administrator may wish to classify all gateway-sourced traffic as internet-sourced and potentially not trusted, and create access-control rules accordingly.

In a multi-cluster environment, you may wish to perform more fine-grained access control. TSB can preserve the identity of a request through gateway hops. This makes it possible to perform cross-cluster authentication, so that you can:

 - propagate the consumer identity to the remote service it has called
 - configure detailed access control between consumers and services in different TSB-managed clusters
 - apply detailed access control rules to failover targets, so that they are not exposed to too-broad a set of consumers

The examples in this documentation assume you are familiar with TSB [concepts](../../concepts), [Ingress Gateways, Tier-1 Gateways and EastWest gateways](../../concepts/terminology#gateway).

:::note GitOps
Following examples use TSB GitOps feature that allow you to apply TSB configurations using kubectl. See [Enabling GitOps](../../operations/features/configure_gitops) to enable GitOps in your TSB environment and [How GitOps works](../../howto/gitops/gitops) to understand you can leverage GitOps workflows with TSB.
:::

### What you need to know

Service identities are not propagated through gateway hops by default because when a request goes through the gateway, due to TLS termination at gateways, the request takes the identity of the gateway instead of original source.
TSB achieves identity propagation using an internal WASM extension on each gateway hop. This extension checks the validity of the client identity, and then append the clients identity to the requests XFCC header and then forwards the request.

You enable this behavior adding the `enableHttpMeshInternalIdentityPropagation` key in the `xcp` component in `ControlPlane` CR or Helm values.

You also need to add `imagePullSecret` for your TSB images registry in `ControlPlane` CR or Helm values so that required identity propagation WASM extensions can be pulled. 

```yaml
spec:
  ...
  imagePullSecrets:
  - name: gcr-secret
  components:
    xcp:
      centralAuthMode: JWT
      configProtection: {}
      enableHttpMeshInternalIdentityPropagation: true
      kubeSpec:
        ..
        ..
```

:::note
`imagePullSecret` is required since WASM image pull is not performed by Kubernetes but manually by the istio-agent in the sidecar and internal secrets used by the Kubernetes cluster to pull images can't be just leveraged.
:::

Verify that `ENABLE_HTTP_MESH_INTERNAL_IDENTITY_PROPAGATION` is then enabled in XCP edge:

```sh
kubectl get deployment edge -n istio-system -o yaml | grep ENABLE_HTTP_MESH_INTERNAL_IDENTITY_PROPAGATION -A 1
```

For assistance, check the [Troubleshooting instructions](#troubleshooting) at the end of this page.

## Use case 1: Propagating Service Identities through Tier 1 and Tier 2 gateways

Configure two clusters `cluster-1` and `cluster-2`, sharing the same root of trust.  If necessary, follow [this guide](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/) and the [repo](https://github.com/istio/istio/tree/master/tools/certs) to setup istio root and intermediate certs.

In `tier-1` cluster:
- Create a dedicated cluster for deploying `tier-1` gateway.
- Configure [`networkReachability`](./multi-cluster-traffic-shifting#network-reachability) setting to make sure reachability from `cluster-1` to `tier-1` and from `tier-1` to `cluster-2` are established.

In `cluster-1`:
- create a tenant `tenant-1` and its namespace `tenant-1-ns`, workspace `tenant-1-ws` and groups.
- deploy the [`sleep`](../../reference/samples/sleep_service#deploy-the-sleep-pod-and-service) pod, or a similar text client in the `tenant-1-ns`.

In `cluster-2`:
- create a tenant `tenant-2` and its namespace `tenant-2-ns`, workspace `tenant-2-ws` and groups.
- deploy the [`bookinfo`](../../quickstart/deploy_sample_app) app into `tenant-2-ns` and an [`ingress gateway`](../../quickstart/ingress_gateway).

Verify that a request from the `cluster-1` `sleep` pod can reach a service in the `bookinfo` app in `cluster-2` via the Tier1 gateway.  For example, you might use a command similar to the one below to invoke `curl` from the `sleep` pod against the Tier1 gateway.

```
export GATEWAY_IP=34.68.3.192   # use your Tier1 gateway IP
export POD=`kubectl get pod -n tenant-1 -l app=sleep -o jsonpath='{.items[0].metadata.name}')`
kubectl exec $POD -c sleep -- curl -sS "http://bookinfo.tetrate.io/api/v1/products" -v --resolve "bookinfo.tetrate.io:80:$GATEWAY_IP"
* Added bookinfo.tetrate.io:80:34.68.3.192 to DNS cache
* Hostname bookinfo.tetrate.io was found in DNS cache
*   Trying 34.68.3.192:80...
* Connected to bookinfo.tetrate.io (34.68.3.192) port 80 (#0)
> GET /api/v1/products HTTP/1.1
> Host: bookinfo.tetrate.io
> User-Agent: curl/7.86.0-DEV
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< content-type: application/json
< content-length: 395
< server: envoy
< date: Fri, 25 Nov 2022 04:05:03 GMT
< x-envoy-upstream-service-time: 30
<
{ [395 bytes data]
[{"id": 0, "title": "The Comedy of Errors", "descriptionHtml": "<a href=\"https://en.wikipedia.org/wiki/The_Comedy_of_Errors\">Wikipedia Summary</a>: The Comedy of Errors is one of <b>William Shakespeare's</b> early plays. It is his shortest and one of his most farcical comedies, with a major part of the humour coming from slapstick and mistaken identity, in addition to puns and word play."}]
* Connection #0 to host bookinfo.tetrate.io left intact
```

### Denying Access at a Workspace level

Apply a `deny` rule to deny communications from `tenant-1-ws` in `cluster-1` to `tenant-2-ws` in `cluster-2`:

```yaml
apiVersion: tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  name: tenant-2-wss
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: tenant-2
    tsb.tetrate.io/workspace: tenant-2-ws
spec:
  defaultSecuritySetting: 
    authenticationSettings:
      trafficMode: REQUIRED
    authorization: 
      mode: RULES
      rules:
        deny:
        - from:
            fqn: organizations/tetrate/tenants/tenant-1/workspaces/tenant-1-ws
          to:
            fqn: organizations/tetrate/tenants/tenant-2/workspaces/tenant-2-ws
```

```
kubectl apply -f tenant-2-wss.yaml
```

Test again a request from the `cluster-1` `sleep` pod to the `bookinfo` app via the Tier1 gateway.  This time, the Tier1 gateway should deny the request and return an `RBAC: access denied` message. 

### Allowing Tenant access and Denying Service access

You can also allow access at a Tenant level, and then deny access at a service level using [`ServiceSecuritySetting`](../../refs/tsb/security/v2/service_security_setting). This allows for more fine-grained security rules.

First, apply a rule to allow access at a tenant level:

```yaml
apiVersion: tsb.tetrate.io/v2
kind: TenantSetting
metadata:
  name: tenant-setting
  annotations: 
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: tenant-2
spec:
  displayName: default-setting
  defaultSecuritySetting:
    authenticationSettings:
      trafficMode: REQUIRED
    authorization:
      mode: RULES
      rules:
        allow:
        - from:
            fqn: organizations/tetrate/tenants/tenant-1
          to:
            fqn: organizations/tetrate/tenants/tenant-2
```

```sh
kubectl apply -f tenant-setting.yaml
```

Verify that the `sleep` pod in `tenant-1` can access the `bookinfo` `products` service in `tenant-2`, as above.

The security [`Group`](../../refs/tsb/security/v2/security_group) is defined as follows:

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: Group
metadata:
  name: tenant-2-sg
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: tenant-2
    tsb.tetrate.io/workspace: tenant-2-ws
spec:
  displayName: tenant-2-security-group
  namespaceSelector:
    names:
      - "cluster-2/tenant-2-ns"
  configMode: BRIDGED
```

We can then define the `deny` rule using a [`ServiceSecuritySetting`](../../refs/tsb/security/v2/service_security_setting) as follows:

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: ServiceSecuritySetting
metadata:
  name: productpage-service-ss
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: tenant-2
    tsb.tetrate.io/workspace: tenant-2-ws
    tsb.tetrate.io/securityGroup: tenant-2-sg
spec:
  service: tenant-2-ns/productpage.tenant-2-ns.svc.cluster.local
  settings:
    authorization: 
      mode: RULES
      rules:
        deny:
        - from:
            fqn: organizations/tetrate/tenants/tenant-1
          to:
            fqn: organizations/tetrate/tenants/tenant-2/workspaces/tenant-2-ws/securitygroups/tenant-2-sg
```

## Use case 2 - Propagating Service Identities in EastWest gateway failover

Review the documentation for [EastWest failover](../../howto/gateway/multi_cluster_traffic_routing_with_eastwest_gateway) before you proceed.  In this use case, we'll propagate the source identity when a service fails-over to a remote instance.  

- In `cluster-1`, create the namespaces `client-ns` belonging to tenant `Client`, and `bookinfo-ns` belonging to tenant `Bookinfo`. Deploy the `bookinfo` and `bookinfo-gateway` services into the `bookinfo-ns`.
- In `cluster-2`, create the namespace `bookinfo-ns`belonging to tenant `Bookinfo`. Deploy the `bookinfo` and `bookinfo-gateway` services into the `bookinfo-ns`.  - In TSB, configure `bookinfo-ns`/`bookinfo-gateway` for EW failover with `defaultEastWestGatewaySettings`:

```yaml
apiVersion: tsb.tetrate.io/v2
kind: WorkspaceSetting
metadata:
  name: bookinfo-ws-settings
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: Bookinfo
    tsb.tetrate.io/workspace: Bookinfo-ws
spec:
  defaultEastWestGatewaySettings:
    - workloadSelector:
        namespace: bookinfo-ns
        labels:
          app: bookinfo-gateway
```

Apply the following `allow` rule to permit communications from clients in the `Client` tenant to services in the `Bookinfo` tenant:

```yaml
apiVersion: tsb.tetrate.io/v2
kind: TenantSetting
metadata:
  name: default-setting
  annotations: 
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: Bookinfo
spec:
  displayName: default-setting
  defaultSecuritySetting:
    authenticationSettings:
      trafficMode: REQUIRED
    authorization:
      mode: RULES
      rules:
        allow:
        - from:
            fqn: organizations/tetrate/tenants/Client
          to:
            fqn: organizations/tetrate/tenants/Bookinfo
        - from:
            fqn: organizations/tetrate/tenants/Bookinfo
          to:
            fqn: organizations/tetrate/tenants/Bookinfo
```

Verify that a client in `Client` can access the bookinfo services:

```sh
kubectl exec deployment/sleep -n client-ns -c sleep -- curl -s http://productpage.bookinfo-ns:9080/api/v1/products -v
kubectl exec deployment/sleep -n client-ns -c sleep -- curl -s http://details.bookinfo-ns:9080/details/1 -v
kubectl exec deployment/sleep -n client-ns -c sleep -- curl -s http://reviews.bookinfo-ns:9080/reviews/1 -v
kubectl exec deployment/sleep -n client-ns -c sleep -- curl -s http://ratings.bookinfo-ns:9080/ratings/1 -v
```

Now apply a `deny` rule to prevent direct access to the `details`, `reviews` and `ratings` services from the `Clients` tenant.  For example, to deny access to `details`:

```yaml
apiVersion: security.tsb.tetrate.io/v2
kind: ServiceSecuritySetting
metadata:
  name: details-service-ss
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: Bookinfo
    tsb.tetrate.io/workspace: bookinfo-ws
    tsb.tetrate.io/securityGroup: bookinfo-sg
spec:
  service: bookinfo-ns/details.bookinfo-ns.svc.cluster.local
  settings:
    authorization: 
      mode: RULES
      rules:
        deny:
        - from:
            fqn: organizations/tetrate/tenants/Client
          to:
            fqn: organizations/tetrate/tenants/Bookinfo/workspaces/bookinfo-ws/securitygroups/bookinfo-sg
```

Repeat the client tests, verifying that a client can access the front-end `products` service, but none of the back-end `details`, `reviews` and `ratings` services.

Finally, scale down the `details`, `reviews` and `ratings` services to zero.  This will provoke a failover.

- Without service identity propagation, the client requests to the `details`, `reviews` and `ratings` services would now succeed because they would take on the identity of the gateway in `cluster-2` (the `Bookinfo` tenant).
- With service identity propagation, the client requests to the `details`, `reviews` and `ratings` services continue to be denied as the identity of the originator is forwarded through gateway hops.

## Troubleshooting

1. Identity propagation is enabled from TSB `ControlPlane` CR by adding `enableHttpMeshInternalIdentityPropagation` to the `xcp` component: 

  ```yaml
  spec:
    ...
    components:
      xcp:
        centralAuthMode: JWT
        configProtection: {}
        enableHttpMeshInternalIdentityPropagation: true
        kubeSpec:
          ..
          ..
  ```

  Verify that `ENABLE_HTTP_MESH_INTERNAL_IDENTITY_PROPAGATION` is enabled in XCP edge:

  ```
  kubectl get deployment edge -n istio-system -o yaml | grep ENABLE_HTTP_MESH_INTERNAL_IDENTITY_PROPAGATION -A 1
  ```

1. Ensure that `imagePullSecret` has been configured in the `ControlPlane` CR. The XCP operator will install the required WASM extension for XFCC header propagation, using the `imagePullSecret` configured in the `ControlPlane` CR.

  ```yaml
  spec:
    hub: gcr.io/sreehari-test-1  
    imagePullSecrets:
    - name: gcr-secret
    managementPlane:
      ...
    components:
      ...
  ```

1. Verify that the secret has been created in `istio-system` namespace in the control plane cluster. 

  ```
  kubectl get secrets -n istio-system | grep gcr
  
  gcr-secret        kubernetes.io/dockerconfigjson        1      6m18s
  ```
  
  Istio will use this secret to pull the `xfcc-guard` WASM extension and deploy it on the Envoy gateways. The extension provides the plugins `xfcc-extractor`, `xfcc-hasher` and `xfcc-validator`.

1. Verify that the Istio `wasmplugin` extension has been successfully installed by the XCP operator in the ControlPlane cluster. 

  ```
  kubectl get wasmplugins.extensions.istio.io -A
  
  NAMESPACE      NAME             AGE
  istio-system   xfcc-extractor   5m
  istio-system   xfcc-hasher      5m
  istio-system   xfcc-validator   5m
  ```
    
1. Verify that the WASM extensions are configured with the `imagePullSecret` configured in the `ControlPlane` CR. 

  ```
  kubectl get wasmplugins.extensions.istio.io xfcc-extractor -n istio-system -o yaml
  apiVersion: extensions.istio.io/v1alpha1
  kind: WasmPlugin
  metadata:
    annotations:
      xcp.tetrate.io/contentHash: 56e3bd2983a4582346e0b295d4795ced
      xcp.tetrate.io/created-by-installer: "true"
    creationTimestamp: "2022-11-29T09:27:56Z"
    generation: 8
    labels:
      install.xcp.tetrate.io/owner-kind: EdgeXcp
      install.xcp.tetrate.io/owner-name: edge-xcp
      install.xcp.tetrate.io/owner-version: v1alpha1
    name: xfcc-extractor
    namespace: istio-system
    ownerReferences:
    - apiVersion: install.xcp.tetrate.io/v1alpha1
      blockOwnerDeletion: true
      controller: true
      kind: EdgeXcp
      name: edge-xcp
      uid: 446c6ba1-800e-4427-89bc-8cfebb3d8d4c
    resourceVersion: "51516293"
    uid: 358b507f-2ad4-4c60-8701-975ec8c397b4
  spec:
    imagePullPolicy: IfNotPresent
    imagePullSecret: gcr-secret
    phase: AUTHZ
    pluginConfig:
      mode: extractor
    pluginName: xfcc-extractor
    priority: 10
    url: oci://gcr.io/sreehari-test-1/xcp-guard:v1.6.0-rc3
  ```
