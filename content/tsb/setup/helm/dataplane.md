---
title: Data Plane Installation
description: How to leverage Helm to install the Data Plane element.
---

This chart installs the TSB data plane operator, which is used to manage the lifecycle of [gateways](../../refs/install/dataplane/v1alpha1/spec) such as the Ingress Gateway, Tier-1 Gateway, and Egress Gateway.

:::note
If you are using the revisioned control plane, the data plane operator is no longer required for managing Istio gateways. To learn more about the revisioned control plane, see the [Istio Isolation Boundaries](../isolation-boundaries) documentation.
:::

## Install

To install the data plane operator, run the following Helm command. Make sure to replace `<tsb-version>` and `<registry-location>` with the correct values.

```shell
helm install dp tetrate-tsb-helm/dataplane \
  --version <tsb-version> \
  --namespace istio-gateway --create-namespace \
  --set image.registry=<registry-location>
```

## Configuration

### Image configuration

This is a **required** field. Set `image.registry` to the location of your private registry where you have synced the TSB images, and set `image.tag` to the TSB version that you want to deploy. 

| Name             | Description                                  | Default value                        |
|------------------|----------------------------------------------|--------------------------------------|
| `image.registry` | Registry used to download the operator image | `containers.dl.tetrate.io` |
| `image.tag`      | The tag of the operator image                | *same as the Chart version*                       |

### Operator extended configuration

This is an **optional** field. You can customize TSB operator related resources like the deployment, the service or the service account using the following optional properties:

| Name                                       | Description                                                                      | Default value |
|--------------------------------------------|----------------------------------------------------------------------------------|---------------|
| `operator.deployment.affinity`             | Affinity configuration for the pod                                               ||
| `operator.deployment.annotations`          | Custom collection of annotations to add to the deployment                        ||
| `operator.deployment.env`                  | Custom collection of environment vars to add to the container                            ||
| `operator.deployment.podAnnotations`       | Custom collection of annotations to add to the pod                               ||
| `operator.deployment.replicaCount`         | Number of replicas managed by the deployment                                     ||
| `operator.deployment.strategy`             | Deployment strategy to use                                                       ||
| `operator.deployment.tolerations`          | Toleration collection applying to the pod scheduling                             ||
| `operator.deployment.podSecurityContext`       | [SecurityContext](../../refs/install/kubernetes/k8s#tetrateio-api-install-kubernetes-podsecuritycontext) properties to apply to the pod                              ||
| `operator.deployment.containerSecurityContext` | [SecurityContext](../../refs/install/kubernetes/k8s#tetrateio-api-install-kubernetes-securitycontext) properties to apply to the pod's containers                             ||
| `operator.service.annotations`             | Custom collection of annotations to add to the service                           ||
| `operator.serviceAccount.annotations`      | Custom collection of annotations to add to the service account                   ||
| `operator.serviceAccount.imagePullSecrets` | Collection of secrets names required to be able to pull images from the registry ||
| `operator.pullSecret`                      | A Docker JSON config string that will be stored as an image pull secret          ||
