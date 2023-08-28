---
title: Revisioned to Revisioned
description: How to upgrade control plane clusters from revisioned to revisioned
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

Before you continue, make sure you are familiar with [Istio Isolation Boundaries](../isolation-boundaries) feature.

:::note
Revisioned to revisioned control plane upgrades can be carried out within a single isolation boundary.
:::

## Before you upgrade

Once the Istio isolation boundary feature is enabled, boundaries can be leveraged to maintain service discovery isolation, and aid in upgrades of the Istio control plane is inside the same boundary. For a given `ControlPlane` CR or Helm values that consists of a single isolation boundary:

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.0
```

You will upgrade all workloads in the `stable` revision to use `tsbVersion: 1.6.1`.

:::note Control plane upgrading strategy
TSB supports both - In-Place and Canary control plane upgrades for revisioned to revisioned upgrades.
:::

## Control plane In-Place upgrades

For in-place upgrade, you can directly update the `tsbVersion` field - leaving the revision `name` intact.

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.1
```

This would re-deploy the Istio control plane components with the TSB Istio release corresponding to `tsbVersion: 1.6.1`. This state will be reconciled by the xcp-operator-edge operator in istio-system namespace.

### Gateway upgrade

By default, gateways will be upgraded automatically to use latest `tsbVersion`. See [Gateway upgrades](./gateway-upgrade) for more details on gateway upgrade behavior.

### Application upgrade

Since the revision name does not change, no updates are required in the workload namespaces (`workload-ns` in this example). However you still need to restart the application workloads. A rolling update is preferred to avoid traffic disruptions.

```bash{promptUser:alice}
kubectl rollout restart deployment -n workload-ns
```

### VM workload upgrade

To upgrade VM workload, download latest Istio sidecar from your onboarding plane using [revisioned link](../workload_onboarding/guides/setup#installing-istio-sidecar-for-revisioned-istio) then reinstall Istio sidecar on the VM.

Then restart `onboarding-agent` running in the VM.

## Control plane Canary upgrades

For canary upgrade, you can add another revision with name `1-6-1` that has the upgraded `tsbVersion` value.

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.0
        - name: 1-6-1
          istio:
            tsbVersion: 1.6.1
```

This would deploy another istio control plane (revision `1-6-1`) with the TSB Istio release corresponding to `tsbVersion: 1.6.1`. This state will be reconciled by the xcp-operator-edge operator in istio-system namespace. You can check `istio-operator` and `istiod` deployment to verify. 

```bash{promptUser:alice}
kubectl get deployment -n istio-system | grep istio-operator
```
```bash{promptUser:alice}
# Output
istio-operator-stable         1/1     1            1           15h
istio-operator-1-6-1          1/1     1            1            2m
```

```bash{promptUser:alice}
kubectl get deployment -n istio-system | grep istiod
```
```bash{promptUser:alice}
# Output
istiod-stable          1/1     1            1           15h
istiod-1-6-1           1/1     1            1            2m
```

Note that there is a old revisioned control plane (`stable`) still deployed which manages existing sidecars and gateways.

### Gateway upgrade

To upgrade the Gateways, [update the `spec.revision`](../isolation-boundaries#gateway-deployment) in the `Ingress/Egress/Tier1Gateway` resource. This will reconcile the existing gateway pods to connect to the new revisioned Istio control plane. TSB by default configures the Gateway install resources with a `RollingUpdate` strategy that ensures zero downtime.

You can also update `spec.revision` by patching gateway CR.
```bash{promptUser:alice}
kubectl patch ingressgateway.install <name> -n <namespace> --type=json --patch '[{"op": "replace","path": "/spec/revision","value": "1-6-1"}]'; \
```

### Application upgrade

To upgrade sidecars, replace `istio.io/rev=stable` workload namespace label and apply the new revision. 

```bash{promptUser:alice}
kubectl label namespace workload-ns istio.io/rev=1-6-1 --overwrite=true
```

Then restart the application workloads. A rolling update is preferred to avoid traffic disruptions.
```bash{promptUser:alice}
kubectl rollout restart deployment -n workload-ns
```

### VM workload upgrade

To upgrade VM workload, download latest Istio sidecar from your onboarding plane using [revisioned link](../workload_onboarding/guides/setup#installing-istio-sidecar-for-revisioned-istio) then reinstall Istio sidecar on the VM.

[Update `revision` value](../isolation-boundaries#vm-workload-onboarding) in `onboarding-agent` configuration then restart `onboarding-agent`. 

## Post-upgrade cleanup 

A revision that is no longer in use can either be removed or marked "disabled" in the `ControlPlane` CR as mentioned below. Marking it disabled helps in enabling the revision back at any point in time.

<Tabs
  defaultValue="Disable"
  values={[
    {label: 'Disabling the revision', value: 'Disable'},
    {label: 'Removing the revision', value: 'Remove'},
  ]}>
  <TabItem value="Disable">

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: stable
          istio:
            tsbVersion: 1.6.0
          disable: true
        - name: 1-6-1
          istio:
            tsbVersion: 1.6.1
```

  </TabItem>
  <TabItem value="Remove">

```yaml
spec:
  ...
  components:
    xcp:
      isolationBoundaries:
      - name: global
        revisions:
        - name: 1-6-1
          istio:
            tsbVersion: 1.6.1
```

  </TabItem>
</Tabs>


:::note Stale Istio control plane components
After disabling/removing the revision under isolation boundaries, a few stale components might remain. For instance, `IstioOperator` resource, istio-operator (revisioned) deployment or istiod (revisioned) deployment.
This happens due to a race condition in removing the `IstioOperator` resource and istio-operator deployment. 
In that case, such Istio components can be removed like regular kubernetes objects using

```bash{promptUser:alice}
kubectl delete iop xcp-iop-stable -n istio-system
kubectl delete deployment istio-operator-stable -n istio-system
kubectl delete configmap istio-sidecar-injector-stable -n istio-system
kubectl delete deployment istiod-stable -n istio-system
```
:::

## Rollback from revisioned to revisioned 

This workflow is similar to upgrading from revisioned to revisioned control plane. You need to update your workloads to use old revision.
