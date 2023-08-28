---
title: TSB Helm Upgrade
description: Upgrade TSB with Helm.
---

This document explains how you can leverage [Helm](https://helm.sh) Charts to upgrade the different elements
of TSB. The document assumes that [Helm is already installed](https://helm.sh/docs/intro/install/) in the system.

This document only applies to TSB instances created with Helm, not to upgrade from TCTL based installations.

Before you start, make sure that you have:

✓ Checked the new version's [requirements](../requirements-and-download#requirements)<br />

## Prerequisites

1. `Helm` [installed](https://helm.sh/docs/intro/install/)
1. TSB cli `tctl` [installed](../../reference/cli/guide/index#installation)
1. `kubectl` [installed](https://kubernetes.io/docs/tasks/tools/#kubectl)
1. Credentials for Tetrate's image repository


### Configure the Helm repository

- Add the repository:
  ```shell
  helm repo add tetrate-tsb-helm 'https://charts.dl.tetrate.io/public/helm/charts/'
  helm repo update
  ```
- List the available versions:
  ```shell
  helm search repo tetrate-tsb-helm -l
  ```

### Backup the PostgreSQL database

[Create a backup of your PostgreSQL database](../../operations/postgresql#create-a-backup-of-tsb-configuration).

The exact procedure for connecting to the database may differ depending on your environment, please refer
to the documentation for your environment.

## Upgrade process

### Management Plane

Upgrade the management plane chart:

```bash
helm upgrade mp tetrate-tsb-helm/managementplane --namespace tsb -f values-mp.yaml
```

### Control Plane

Upgrade the control plane chart:

```bash
helm upgrade cp tetrate-tsb-helm/controlplane --namespace istio-system -f values-cp.yaml --set-file secrets.clusterServiceAccount.JWK=/tmp/<cluster>.jwk
```

### Data Plane

Upgrade the control plane chart:

```bash
helm upgrade dp tetrate-tsb-helm/dataplane --namespace istio-gateway -f values-dp.yaml
```

## Rollback

In case something goes wrong and you want to rollback TSB to the previous version,
you will need to rollback the Management Plane, the Control Planes and the Data Planes charts.

### Rollback the Control Plane

You can use `helm rollback` to rollback the current revision. To see the current revisions, you can run:
```bash
helm history cp -n istio-system
```

And then you can rollback to the previous revision:
```bash
helm rollback cp <REVISION> -n istio-system
```

### Rollback the Management Plane

#### Scale Down Pods in Management Plane

Scale down all of the pods that talk to Postgres in the Management Plane so that the it is inactive.

```bash
kubectl scale deployment tsb iam -n tsb --replicas=0
```

#### Restore PostgreSQL

[Restore your PostgreSQL database from your backup](../../operations/postgresql#restore-a-backup).
The exact procedure for connecting to the database may differ depending on your environment, please refer to the documentation for your environment.

#### Restore Management Plane

```bash
helm rollback mp <REVISION> -n tsb
```
