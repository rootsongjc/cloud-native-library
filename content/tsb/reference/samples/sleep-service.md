---
title: Installing sleep
description: Guide on how to install the `sleep` workload that is used in various examples.
---

Sometimes it is convenient to have a workload that does nothing. In this example a container with `curl` installed is used as the base for the `sleep` service, so that testing is easier.

The `sleep` service is used in multiple examples in the TSB documentation. This document provides the basic installation procedure for this service.

Please make sure to refer to each TSB documentation for specific caveats or customizations that are required for the examples to work, as this document describes the most generic installation steps. 

The following examples assume that you have already setup TSB, and that you have onboarded Kubernetes clusters to install the `sleep` workload to.

Unless otherwise stated, the examples that use the `kubectl` command must be pointed to the same cluster. Make sure that your `kubeconfig` is pointing to the desired cluster before running these commands.

## Namespace

Unless otherwise stated, the `sleep` service is assumed to be installed in the `sleep` namespace. If not already present, this namespace must be created in the target cluster.

Run the following command to create the namespace if not already present:

```bash{promptUser: "alice"}
kubectl create namespace sleep
```

The `sleep` pod in this namespace must have an Istio sidecar proxy running in it. To automatically enable the injection of this sidecar for all pods, execute the following:

```bash{promptUser: "alice"}
kubectl label namespace sleep istio-injection=enabled --overwrite=true
```

This will let Istio know that it needs to inject the sidecar to the pod that you will create later.

## Deploy the `sleep` Pod and Service

Download the [`sleep.yaml`](../../assets/reference/sleep.yaml) manifest found in the Istio repository. 

Run the following command to deploy the `sleep` service in the `sleep` namespace:

```bash{promptUser: "alice"}
kubectl apply -n sleep -f sleep.yaml
```

## Create a `sleep` Workspace

This next step may or may not be necessary depending on the usage scenario. 
If you are creating a TSB Workspace, follow the steps below to create one.

In this example we assume that you have already created a tenant in your organization. If you have not created one, read the [examples in documentation and create one](../../quickstart/tenant).

Create a workspace for `sleep` that claims the namespace `sleep`, if you have not already done so. Create a file called `sleep-workspace.yaml` with contents similar to the sample below. Make sure to replace the organization, tenant, and cluster names to appropriate values.

:::note
If you have [installed the `demo` profile](../../setup/self_managed/demo-installation), an organization named `tetrate` and a cluster already onboarded named `demo` already exist.
:::

```
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: <organization>
  tenant: <tenant>
  name: sleep
spec:
  displayName: Sleep Workspace
  namespaceSelector:
    names:
      - "<cluster>/sleep"
```

Apply the manifest using `tctl`:

```bash{promptUser "alice"}
tctl apply -f sleep-workspace.yaml
```
