---
title: Installing httpbin
description: Guide on how to install the `httpbin` workload that is used in various examples.
---

[`httpbin`](https://httpbin.org) is a simple HTTP request and response service that is used for testing.

The `httpbin` service is used in many examples in the TSB documentation. This document provides the basic installation procedure for this service.

Please make sure to refer to each TSB documentation for specific caveats or customizations that are required for the examples to work, as this document describes the most generic installation steps. 

The following examples assume that you have already setup TSB, and that you have onboarded Kubernetes clusters to install the `httpbin` workload to.

Unless otherwise stated, the examples that use the `kubectl` command must be pointed to the same cluster. Make sure that your `kubeconfig` is pointing to the desired cluster before running these commands.

## Namespace

Unless otherwise stated, the `httpbin` service is assumed to be installed in the `httpbin` namespace. If not already present, this namespace must be created in the target cluster.

Run the following command to create the namespace if not already present:

```bash
kubectl create namespace httpbin
```

The `httpbin` pod in this namespace must have an Istio sidecar proxy running in it. To automatically enable the injection of this sidecar for all pods, execute the following:

```bash
kubectl label namespace httpbin istio-injection=enabled --overwrite=true
```

This will let Istio know that it needs to inject the sidecar to the pod that you will create later.

## Deploy the `httpbin` Pod and Service

Download the [`httpbin.yaml`](https://raw.githubusercontent.com/istio/istio/master/samples/httpbin/httpbin.yaml) manifest found in the Istio repository. 

Run the following command to deploy the `httpbin` service in the `httpbin` namespace:

```bash
kubectl apply -n httpbin -f httpbin.yaml
```

## Expose the `httpbin` Service

This next step may or may not be necessary depending on the usage scenario. 
If an Ingress Gateway is required, create a file called `httpbin-ingress-gateway.yaml` with the following contents.

```
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: httpbin-ingress-gateway
  namespace: httpbin
spec:
  kubeSpec:
    service:
      type: LoadBalancer
```

Then deploy it using `kubectl`:

```bash
kubectl apply -f httpbin-ingress-gateway.yaml
```

## Create Certificates

This next step may or may not be necessary depending on the usage scenario. 
If a TLS certificate is required, you can prepare them by following these steps.

Download the script [`gen-cert.sh`](../../assets/quickstart/gen-cert.sh) and execute the following to generate the necessary files. Refer to [this document](../../quickstart/ingress_gateway#certificate-for-gateway) for more details.

```bash
chmod +x ./gen-cert.sh
mkdir certs
./gen-cert.sh httpbin httpbin.tetrate.com certs
```

The above assumes that you have exposed the `httpbin` service as `httpbin.tetrate.com`. Change its value accordingly, if necessary.

Once you have the necessary files generated in the `certs` directory, create the Kubernetes secret.

```bash
kubectl -n httpbin create secret tls httpbin-certs \
  --key certs/httpbin.key \
  --cert certs/httpbin.crt
```

## Create a `httpbin` Workspace

This next step may or may not be necessary depending on the usage scenario. 
If you are creating a TSB Workspace, follow the steps below to create one.

In this example we assume that you have already created a tenant in your organization. If you have not created one, read the [examples in documentation and create one](../../quickstart/tenant).

Create a file called `httpbin-workspace.yaml` with contents similar to the sample below. Make sure to replace the organization, tenant, and cluster names to appropriate values.

:::note
If you have [installed the `demo` profile](../../setup/self_managed/demo-installation), an organization named `tetrate` and a cluster already onboarded named `demo` already exist.
:::

```
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: <organization>
  tenant: <tenant>
  name: httpbin
spec:
  displayName: Httpbin Workspace
  namespaceSelector:
    names:
      - "<cluster>/httpbin"
```

Apply the manifest using `tctl`:

```bash
tctl apply -f httpbin-workspace.yaml
```

## Create Config Groups

This next step may or may not be necessary depending on the usage scenario. 
If you are creating Config Groups for this service, follow the steps below to create them.

In this example we assume that you have already created a tenant and a workspace in your organization. If you have not created one, read the [examples in documentation and create one](../../quickstart/tenant), as well as [the instructions on creating a `httpbin` Workspace](#create-a-httpbin-workspace)

Create a file called `httpbin-groups.yaml` with contents similar to the sample below. Make sure to replace the organization, tenant, workspace, and cluster names to appropriate values.

```yaml
apiVersion: gateway.tsb.tetrate.io/v2
kind: Group
metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: httpbin
  name: httpbin-gateway
spec:
  namespaceSelector:
    names:
      - "<cluster>/httpbin"
  configMode: BRIDGED
---
apiVersion: traffic.tsb.tetrate.io/v2
kind: Group
Metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: httpbin
  name: httpbin-traffic
spec:
  namespaceSelector:
    names:
      - "<cluster>/httpbin"
  configMode: BRIDGED
---
apiVersion: security.tsb.tetrate.io/v2
kind: Group
Metadata:
  organization: <organization>
  tenant: <tenant>
  workspace: httpbin
  name: httpbin-security
spec:
  namespaceSelector:
    names:
      - "<cluster>/httpbin"
  configMode: BRIDGED
```

Apply the manifest using `tctl`:

```
tctl apply -f httpbin-groups.yaml
```

After this you should end up with 3 groups, a [Gateway Group](../../refs/tsb/gateway/v2/gateway_group) (`httpbin-gateway`), a [Traffic Group](../../refs/tsb/traffic/v2/traffic_group) (`httpbin-traffic`), and a [Security Group](../../refs/tsb/security/v2/security_group) (`httpbin-security`).

## Onboard `httpbin` Application

This next step may or may not be necessary depending on the usage scenario. 
If you are creating a TSB Application, follow the steps below to create one.

First, make sure that you have already [created the `httpbin` workspace](#create-a-httpbin-workspace).

Create an application in this workspace. Create a file called `httpbin-application.yaml` with contents similar to the sample below. Make sure to replace the organization and tenant names to appropriate values.

```
apiVersion: application.tsb.tetrate.io/v2
kind: Application
metadata:
  name: httpbin
  organization: <organization>
  tenant: <tenant>
spec:
  displayName: httpbin
  workspace: organizations/<organization>/tenants/<tenant>/workspaces/httpbin
  gatewayGroup: organizations/<organization>/tenants/<tenant>/workspaces/httpbin/gatewaygroups/httpbin-gateway
```

Apply the manifest using `tctl`:

```bash
tctl apply -f httpbin-application.yaml
```
