---
slug: helm
title: TSB Helm Charts
description: How to leverage Helm to install the different elements of TSB.
---

## Overview

This document explains how to use [Helm](https://helm.sh) Charts to install the different components of Tetrate Service Bridge (TSB). It is assumed that [Helm is already installed](https://helm.sh/docs/intro/install/) on your system.

TSB has one chart for each of its [planes](../../concepts/architecture#overall-architecture):

- [Management Plane](./managementplane): installs the TSB Management Plane operator (optionally allows to install the MP
  CR and/or the secrets).
- [Control Plane](./controlplane): installs the TSB Control Plane operator (optionally allows to install the MP CR and/or
  the secrets).
- [Data Plane](./dataplane): installs the TSB Data Plane operator.

Each chart installs the operator of the corresponding plane. Both management plane and the control plane ones also allow
creating the corresponding resource that triggers the operator (using the `spec` attribute) to deploy all the TSB components and/or the required secrets (using the `secrets` attribute) to making them properly run.

This behavior lets you choose the way to fully configure TSB and integrate with CD pipelines. You can use
helm to:

- only install the operators
- install/upgrade the plane resource (Management plane or Control plane CRs) along with the operator
- install/upgrade the secrets along with the operator
- install/upgrade all of them (operator, resource, secrets) at once

Regarding secrets, keep in mind that `helm install/upgrade` command accepts different files that can be provided by
different sources, using one of the source for the spec and another for secrets.

There is an extra configuration (`secrets.keep`) to keep the secrets installed and avoid removing them. With this,
secrets can be applied just once, and future upgrades without secrets won't remove them.

By default, Helm charts also install TSB CRDs. If you wish to skip the CRD installation step, you can pass the `--skip-crds` flag.

## Installation process

### Prerequisites

Before you start, make sure that you've:

1. Checked the [requirements](../requirements-and-download)<br />
1. Installed [Helm](https://helm.sh/docs/intro/install/) 
1. Installed [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
1. [Synced](../requirements-and-download#sync-tetrate-service-bridge-images) the Tetrate Service Bridge images

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

### Installation

Go to [Management Plane Installation](./managementplane) to install [TSB management plane components](../components#management-plane).

Go to [Control Plane Installation](./controlplane) to install [TSB control plane components](../components#control-plane) into your application clusters. This will onboard your application clusters into TSB.
 
Go to [Data Plane Installation](./dataplane) to install [TSB data plane components](../components#data-plane) that will manage gateways lifecycle into your application clusters.

:::note Revisioned Control Plane
When you use revisioned control plane, Data plane operator is not required anymore to manage Istio gateways and you can skip Data Plane Installation. To learn more about revisioned control plane, go to [Istio Isolation Boundaries](../isolation-boundaries).
:::

