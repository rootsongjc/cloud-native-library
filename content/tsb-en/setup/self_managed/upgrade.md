---
title: TSB Upgrade
description: Upgrade TSB with the TSB Operator.
---

This page will walk you through how to upgrade TSB using the `tctl` CLI,
rendering the Kubernetes manifests for the different operators and applying them
to the clusters to upgrade using `kubectl`.

Before you start, make sure that you have:

✓ Checked the new version's [requirements](../requirements-and-download#requirements)<br />

The upgrade procedure between operator-based releases is fairly simple. Once the
operator pods are updated with the new release images, the newly spun up
operator pods will upgrade all the necessary components to the new version for
you.

## Create Backups

In order to make sure you can restore everything when something goes wrong, please create backups for the Management Plane and each of your clusters' local Control Planes.

### Backup the Management Plane

#### Backup the `tctl` binary

Since each new `tctl` binary potentially comes with new operators and configurations to deploy and configure TSB, you should backup the current `tctl` binary you are using. Please do this *before* syncing the new images.

Copy the `tctl` binary with version suffix (e.g. `-1.3.0`) to quickly restore the older one if needed.

```bash{promptUser: alice}
cp ~/.tctl/bin/tctl ~/.tctl/bin/tctl-{version}
```

If you have misplaced your binary, you may be able to find the right version from [this URL](https://binaries.dl.tetrate.io/public/raw/). However, it is strongly recommended that you backup your current copy to be sure.

#### Backup the ManagementPlane CR

Create a backup of the `ManagementPlane` CR by executing the following command:

```bash{promptUser: alice}
kubectl get managementplane -n tsb -o yaml > mp-backup.yaml
```

#### Backup the PostgreSQL database

[Create a backup of your PostgreSQL database](../../operations/postgresql#create-a-backup-of-tsb-configuration).

The exact procedure for connecting to the database may differ depending on your environment, please refer to the documentation for your environment.

### Backup the Control Plane Custom Resource

Create a backup of all `ControlPlane` CRs by executing the following command on each of your onboarded clusters:

```
kubectl get controlplane -n istio-system -o yaml > cp-backup.yaml
```

## Upgrade Procedure

### Download `tctl` and Sync Images

Now that you have taken backups, [download the new version's `tctl` binary](../requirements-and-download#download),
then obtain the new TSB container images.

Details on how to do this is described in the [Requirements and Download page](../requirements-and-download#sync-tetrate-service-bridge-images)

### Create the Management Plane Operator

Create the base manifest which will allow you to update the management
plane operator from your private Docker registry:

```bash{promptUser: alice}{outputLines: 2-3}
tctl install manifest management-plane-operator \
    --registry <your-docker-registry> \
    > managementplaneoperator.yaml
```

:::note Management namespace name
Starting with TSB 0.9.0 the default Management Plane namespace name is `tsb` as
opposed to `tcc` used in older versions. If you installed TSB using an earlier
version than 0.9.0, your Management Plane probably lives in the `tcc` namespace.
You will need to add a `--management-namespace tcc` flag to reflect this.
:::

:::note Customization
The managementplaneoperator.yaml file created by the install command can now be
used as a base template for your Management Plane upgrade. If your existing TSB
configuration contains specific adjustments on top of the standard configuration,
you should copy them over to the new template.
:::

Now, add the manifest to source control or apply it directly to the management
plane cluster by using the kubectl client:

```bash{promptUser: alice}
kubectl apply -f managementplaneoperator.yaml
```

After applying the manifest, you will see the new operator running in the `tsb`
namespace:

```bash{promptUser: alice}{outputLines:2-3}
kubectl get pod -n tsb
NAME                                            READY   STATUS    RESTARTS   AGE
tsb-operator-management-plane-d4c86f5c8-b2zb5   1/1     Running   0          8s
```

For more information on the manifest and how to configure it, please review the
[`ManagementPlane` CR reference](../../refs/install/managementplane/v1alpha1/spec)

### Create the Control and Data Plane operators

To deploy the new Control and Data Plane operators in your application clusters,
you must run [`tctl install manifest cluster-operators`](../../reference/cli/reference/install#tctl-install-manifest-cluster-operators)
to retrieve the Control Plane and Data Plane operator manifests for the new
version.

```bash{promptUser: alice}{outputLines: 2-3}
tctl install manifest cluster-operators \
    --registry <your-docker-registry> \
    > clusteroperators.yaml
```
:::note Customization
The clusteroperators.yaml file can now be used for your cluster upgrade. If your
existing control and Data Planes have specific adjustments on top of the
standard configuration, you should copy them over to the template.
:::

### Review tier1gateways and ingressgateways

Due to a fix introduced in [Istio 1.14](https://github.com/istio/istio/pull/36928), when both `replicaCount` and `autoscaleEnaled` are set, `replicaCount` will be ignored
and only autoscale configuration will be applied. This could lead to issues where the `tier1gateways` and `ingressgateways` scale down to 1 replica 
temporally during the upgrade until the autoscale configuration is applied.
In order to avoid this issue, you can edit the `tier1gateway` or `ingressgateway` spec and remove the `replicas` field, and since the current
deployment will be already managed by the HPA controller, then this will allow you to upgrade the pods with the desired configuration.

You can get all the `tier1gateways` or `ingressgateways` by running:
```bash
kubectl get tier1gateway.install -A
kubectl get ingressgateway.install -A
```

### Applying the Manifest

Now, add the manifest to source control or apply it directly to the appropriate
clusters by using the kubectl client:

```bash{promptUser: alice}
kubectl apply -f clusteroperators.yaml
```

For more information on each of these manifests and how to configure them,
please check out the following guides:

- [ControlPlane resource reference](../../refs/install/controlplane/v1alpha1/spec)
- [Data Plane resources reference](../../refs/install/dataplane/v1alpha1/spec)
- [Kubernetes overrides reference](../../refs/install/kubernetes/k8s)

## Rollback

In case something goes wrong and you want to rollback TSB to the previous version, you will need to rollback both the Management Plane and the Control Planes.

### Rollback the Control Plane

#### Scale down `istio-operator` and `tsb-operator`

```bash{promptUser: alice}
kubectl scale deployment \
   -l "platform.tsb.tetrate.io/component in (tsb-operator,istio)" \
   -n istio-system \
   --replicas=0
```

#### Delete the `IstioOperator` Resource

Delete the operator will require to remove the finalizer protecting the istio object with the following command:

```bash{promptUser: alice}
kubectl patch iop tsb-istiocontrolplane -n istio-system --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers", "value":""}]'


kubectl delete istiooperator -n istio-system --all
```

#### Scale down `istio-operator` and `tsb-operator` for the Data Plane operator

```bash{promptUser: alice}
kubectl scale deployment \
   -l "platform.tsb.tetrate.io/component in (tsb-operator,istio)" \
   -n istio-gateway \
   --replicas=0
```

#### Delete the `IstioOperator` Resources for the Data Plane

Since 1.5.11 the IOP containing the ingressgateways is split to have one IOP per ingressgateway. In order to rollback to the old Istio version, we 
will need to remove the finalizer protecting the istio objects and delete all the operators with the following commands:

```bash{promptUser: alice}
for iop in $(kubectl get iop -n istio-gateway --no-headers | grep -i "tsb-ingress" | awk '{print $1}'); do kubectl patch iop $iop -n istio-gateway --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers", "value":""}]'; done

kubectl delete istiooperator -n istio-gateway --all
```

### Create the Cluster Operators, and rollback the ControlPlane CR

Using the `tctl` binary from the previous version, follow [the instructions to create the cluster operators](#create-the-control-and-data-planes).

Then apply the the backup of the `ControlPlane` CR:

```
kubectl apply -f cp-backup.yaml
```

### Rollback the Management Plane

#### Scale Down Pods in Management Plane

Scale down all of the pods in the Management Plane so that the it is inactive.

```bash{promptUser: alice}
kubectl scale deployment tsb iam -n tsb --replicas=0
```

#### Restore PostgreSQL

[Restore your PostgreSQL database from your backup](../../operations/postgresql#restore-a-backup). The exact procedure for connecting to the database may differ depending on your environment, please refer to the documentation for your environment.

#### Restore `tctl` and create the Management Plane operator

Restore `tctl` from  the backup copy that you made, or [download the binary for the specific version you would like to use](https://binaries.dl.tetrate.io/public/raw/).

```bash{promptUser: alice}
mv ~/.tctl/bin/tctl-{version} ~/.tctl/bin/tctl
```

Follow the [instructions for upgrading](#create-the-management-plane-operator) to create the Management Plane operator. Then apply the backup of the `ManagementPlane` CR:

```bash{promptUser: alice}
kubectl apply -f mp-backup.yaml
```

#### Scale back the deployments

Finally, scale back the deployments.

```bash{promptUser: alice}
kubectl scale deployment tsb iam -n tsb --replicas 1
```
