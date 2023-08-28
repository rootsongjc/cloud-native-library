---
title: Non-revisioned to Revisioned
description: How to upgrade control plane clusters from non-revisioned to revisioned
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

Before you continue, make sure you are familiar with [Istio Isolation Boundaries](../isolation-boundaries) feature.

## Before you upgrade

Upgrading from a non-revisioned to revisioned control plane setup involves enabling the Istio isolation boundary feature.
Once enabled, a revision can be configured within the isolation boundary to which the control plane must upgrade to.
Follow the steps mentioned in [Isolation Boundaries Installation](../isolation-boundaries#installation) to deploy the control plane with isolation boundary feature enabled.

Once the Istio isolation boundary feature is enabled, you need to scale down TSB data plane operator before adding isolation boundaries in the `ControlPlane` CR. This is to avoid race condition between TSB data plane operator and TSB control plane operator to reconcile the same TSB Ingress/Egress/Tier1Gateway resources.
```bash{promptUser:alice}
kubectl scale --replicas=0 deployment tsb-operator-data-plane -n istio-gateway
```
For the same reason we must also scale down the istio-operator in the istio-gateway namespace.
```bash{promptUser:alice}
kubectl scale --replicas=0 deployment istio-operator -n istio-gateway
```
With this, also delete the webhooks that are created and managed by the tsb-operator-data-plane.
```bash{promptUser:alice}
kubectl delete validatingwebhookconfiguration tsb-operator-data-plane-egress tsb-operator-data-plane-ingress tsb-operator-data-plane-tier1; \
kubectl delete mutatingwebhookconfiguration tsb-operator-data-plane-egress tsb-operator-data-plane-ingress tsb-operator-data-plane-tier1;
```

:::note Control plane upgrade strategy
TSB only supports Canary control plane upgrades for non-revisioned to revisioned upgrades. This would mean that at a given point in time, there will be two Istio control planes deployed - a non-revisioned and a revisioned control plane.
:::

## Control plane

Configure an isolation boundary in your `ControlPlane` CR. If you use Helm, you can add isolation boundary configuration in your Helm values file. 

```yaml
spec:
  hub: <registry-location>
  telemetryStore:
    elastic:
      host: <tsb-address>
      port: <tsb-port>
      version: <elastic-version>
      selfSigned: <is-elastic-use-self-signed-certificate>
  managementPlane:
    host: <tsb-address>
    port: <tsb-port>
    clusterName: <cluster-name-in-tsb>
    selfSigned: <is-mp-use-self-signed-certificate>
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: revisioned
      centralAuthMode: 'JWT'
```

:::note `"global"` isolation boundary
Although we can deploy multiple revisioned control planes after enabling isolation boundaries support, with any boundary "name" whatsoever, but it is recommended to create 1 isolation boundary named "global" so that existing Workspaces can be considered as part of the "global" isolation boundary. Existing workspaces that are already deployed in the cluster will NOT be bound to a specific isolation boundary, therefore the "global" named isolation boundary provides a fallback for all these Workspaces that do not specify their isolation boundary.
:::

Configuring an isolation boundary in the `ControlPlane` CR will setup a revisioned control plane in the `istio-system` namespace as follows

```bash{promptUser:alice}
kubectl get deployment -n istio-system | grep istio-operator
```
```bash{promptUser:alice}
# Output
istio-operator                1/1     1            1            15h
istio-operator-revisioned     1/1     1            1            2m
```

```bash{promptUser:alice}
kubectl get deployment -n istio-system | grep istiod
```
```bash{promptUser:alice}
# Output
istiod                 1/1     1            1            15h
istiod-revisioned      1/1     1            1            2m
```

Note that there is a non-revisioned control plane still deployed which manages existing sidecars and gateways.

### Gateway upgrade

To upgrade the Gateways, [add the `spec.revision`](../isolation-boundaries#gateway-deployment) in the `Ingress/Egress/Tier1Gateway` resource. This will reconcile the existing gateway pods to connect to the revisioned Istio control plane. TSB by default configures the Gateway install resources with a `RollingUpdate` strategy that ensures zero downtime.

You can also add `spec.revision` by patching gateway CR.
```bash{promptUser:alice}
kubectl patch ingressgateway.install <name> -n <namespace> --type=json --patch '[{"op": "replace","path": "/spec/revision","value": "revisioned"}]'; \
```

### Application upgrade

To upgrade sidecars, remove `istio-injection=enabled` workload namespace label and apply `istio.io/rev` label on the workload namespace to the Istio revision. 

```bash{promptUser:alice}
kubectl label namespace workload-ns istio-injection- istio.io/rev=revisioned
```

Then restart application workloads. A rolling update is preferred to avoid traffic disruptions.
```bash{promptUser:alice}
kubectl rollout restart deployment -n workload-ns
```

### VM workload upgrade

To upgrade VM workload, download latest Istio sidecar from your onboarding plane using [revisioned link](../workload_onboarding/guides/setup#installing-istio-sidecar-for-revisioned-istio) then reinstall Istio sidecar on the VM.

Update `onboarding-agent` configuration with [`revision` value](../isolation-boundaries#vm-workload-onboarding) then restart `onboarding-agent`. Istio sidecar will connect to revisioned Istio control plane.

## Post-upgrade cleanup 

Once all sidecars have moved to the revisioned proxy and all application gateways have revisioned gateways running, and a healthy upgrade is ensured, we can proceed to cleanup the old non-revisioned resources from the cluster which are now stale.  

1. Remember that we had scaled down the TSB data plane operator and non-revision istio-operator from the istio-gateway namespace. Now the `istio-gateway` namespace itself can be safely removed, as it is not required anymore.
  ```bash{promptUser:alice}
  kubectl delete ns istio-gateway
  ```

2. Delete `IstioOperator` resource named `tsb-istiocontrolplane` from the namespace `istio-system` using `kubectl`. 
  ```bash{promptUser:alice}
  kubectl delete iop tsb-istiocontrolplane -n istio-system
  ```

3. Ensure that the `istiod` Deployment is deleted from the `istio-system` namespace by the istio-operator deployment. Then delete Istio operator deployment and kubernetes RBAC (`clusterrole` and `clusterrolebinding`)
  ```bash{promptUser:alice}
  kubectl delete clusterrole,clusterrolebinding istio-operator
  kubectl delete deployment,sa istio-operator -n istio-system
  ``` 

## Rollback from revisioned to non-revisioned 

### Before post-upgrade cleanup

- Scale up the tsb data plane operator in the istio-gateway namespace.
  ```bash{promptUser:alice}
  kubectl scale --replicas=1 deployment tsb-operator-data-plane -n istio-gateway
  ```
  With this delete the webhooks that are created and managed by the tsb-operator-control-plane.

  ```bash{promptUser:alice}
  kubectl delete validatingwebhookconfiguration tsb-operator-control-plane-egress tsb-operator-control-plane-ingress tsb-operator-control-plane-tier1; \
  kubectl delete mutatingwebhookconfiguration tsb-operator-control-plane-egress tsb-operator-control-plane-ingress tsb-operator-control-plane-tier1;
  ```

- To rollback revisioned gateways, remove `spec.revision` from the `Ingress/Egress/Tier1Gateway` TSB gateway install resources. 

  For the gateway deployment, it is preferred to configure rolling update to avoid traffic disruptions. This can be configured in the `ingress/Egress/Tier1Gateway` resource.
  This will result in gateway pods coming up and getting connected to the older non-revisioned istio control plane which is still running.

- Rollback the sidecars by changing the value of `istio.io/rev` workload namespace label to `default`
  ```bash{promptUser:alice}
  kubectl label namespace workload-ns istio.io/rev=default
  ```

  Then restart the application workloads.
  ```bash{promptUser:alice}
  kubectl rollout restart deployment -n workload-ns
  ```

- Once all data plane components are rollbacked to non-revisioned control plane, we can proceed with removing the isolation boundary from the `ControlPlane` CR. This will remove the revisioned control plane components deployed in `istio-system` namespace.

### After post-upgrade cleanup

:::warning Gateway rollbacks
Rolling back gateways from revisioned to non-revisioned control plane AFTER the post-upgrade cleanup is done, does not guarantee zero down time.
:::


- First we need to bring back the non-revisioned control plane. To get the older non-revisioned control plane, re-install TSB cluster operators with `ISTIO_ISOLATION_BOUNDARIES` disabled.
  ```
  tctl install manifest cluster-operators --registry $HUB > clusteroperators.yaml
  kubectl apply -f clusteroperators.yaml
  ```

  Deploying the operators again, will bring back the TSB data plane operator in the istio-gateway namespace. Also the non-revisioned TSB control plane operator will then reconcile the updated `ControlPlane` resource to redeploy non-revisioned Istio control plane.
  Since the isolation boundary support is removed, this will also cleanup all revisioned control plane components.

- Edit the existing `ControlPlane` CR to remove the `spec.components.xcp.isolationBoundaries`.

- To rollback revisioned gateways, remove `spec.revision` from the `Ingress/Egress/Tier1Gateway` TSB gateway install resources. 
  For the gateway deployment, it is preferred to configure rolling update to avoid traffic disruptions. This can be configured in the `ingress/Egress/Tier1Gateway` resource.
  This will result in gateway pods coming up and getting connected to the older non-revisioned istio control plane which is still running.

- Rollback the sidecars by changing the value of `istio.io/rev` workload namespace label to `default`
  ```bash{promptUser:alice}
  kubectl label namespace workload-ns istio.io/rev=default
  ```

  Then restart the application workloads.
  ```bash{promptUser:alice}
  kubectl rollout restart deployment -n workload-ns
  ```
