---
title: Control Plane Installation
description: How to leverage Helm to install the Control Plane component.
---

# Control Plane Installation

This chart installs the TSB control plane operator to onboard a cluster. Similar to [Management Plane Helm chart](./managementplane), it also allows you to install TSB control plane components using [TSB `ControlPlane` CR](../../refs/install/controlplane/v1alpha1/spec) and all the required secrets to make it fully run.

Before you start, make sure that you've:

✓ Checked the [Helm installation process](./helm#installation-process)<br />
✓ [Installed TSB management plane](./managementplane)<br />
✓ [Login to the management plane with tctl](../tctl_connect)<br />
✓ Installed [yq](https://github.com/mikefarah/yq#install). This will be used to help getting helm values from creating cluster response.

:::note isolation boundaries
TSB 1.6 introduces isolation boundaries that allows you to have multiple TSB-managed Istio environments within a Kubernetes cluster, or spanning several clusters. One of the benefits of isolation boundaries is that you can perform canary upgrades of the control plane. 

To enable isolation boundaries, you must update operator deployment with environment variable `ISTIO_ISOLATION_BOUNDARIES=true` and control plane CR to include `isolationBoundaries` field.
For more information, see [Isolation Boundaries](../isolation-boundaries).
:::

## Prerequisites

Before you begin, you will need to create a [cluster object](../../refs/tsb/v2/cluster) in TSB to represent the cluster where you will be installing the TSB control plane. Replace `<cluster-name-in-tsb>` and `<organization-name>` with the appropriate values for your environment:

```yaml
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: <cluster-name-in-tsb>
  organization: <organization-name>
spec:
  displayName: "App Cluster"
```

To create the cluster object, run the following command:

```bash{promptUser:alice}
tctl apply -f cluster.yaml -o yaml | yq .spec.installTemplate.helm > cluster-cp-values.yaml
```

The file, cluster-cp-values.yaml, comprises the default configuration for the TSB control plane operator, including any necessary secrets for authentication with the TSB management plane. To customize your installation, you may modify this file by adding any extra configuration values you need for the TSB control plane prior to proceeding to the subsequent step.

## Installation

Use the following helm install command to install TSB control plane. Make sure to replace `<tsb-version>` and `<registry-location>` with the correct values.

```bash{promptUser:alice}
helm install cp tetrate-tsb-helm/controlplane \
  --version <tsb-version> \
  --namespace istio-system --create-namespace \
  --timeout 5m \
  --values cluster-cp-values.yaml \
  --set image.registry=<registry-location>
```

Wait for the TSB control plane components to be deployed successfully. To verify that the installation was successful, you can try logging in to the TSB UI or connecting to TSB using [tctl](../tctl_connect) and checking the list of clusters to see if the cluster has been onboarded.

## Troubleshooting

If you encounter any issues during the installation process, here are a few tips for troubleshooting:

- Make sure that you have followed all of the steps in the correct order.
- Double-check the configuration values in the `cluster-cp-values.yaml` file to ensure that they are correct.
- Check the logs of the TSB control plane operator to see if there are any error messages or stack traces that can help diagnose the problem.
- If you are using a private registry to host the TSB control plane operator image, make sure that you have authenticated with the registry and that the `image.registry` value is correct.
- Check the cluster onboarding troubleshooting [guide](../../troubleshooting/cluster_onboarding).

## Configuration

### Image configuration

This is a **required** field. Set `registry` to your private registry where you have synced TSB images into and `tag` to TSB version that you want to deploy. Specifying only this field will install TSB control plane operator without installing other TSB components. 

| Name             | Description                                  | Default value                        |
|------------------|----------------------------------------------|--------------------------------------|
| `image.registry` | Registry used to download the operator image | `containers.dl.tetrate.io` |
| `image.tag`      | The tag of the operator image                | *same as the Chart version*            |

### Control Plane resource configuration

This is an **optional** field. You can set [TSB `ControlPlane` CR](../../refs/install/controlplane/v1alpha1/spec)
in Helm values file to make the TSB control plane fully run.

| Name   | Description                                                   | Default value |
|--------|---------------------------------------------------------------|---------------|
| `spec` | Holds the `spec` section of the `ControlPlane` CR ||

### Secrets configuration

This is an **optional** field. You can apply secrets into your cluster before installing TSB control plane or you can use Helm values to specify required secrets. Note that you can use different Helm values file if you want to separate secrets from control plane spec.

:::warning
Keep in mind that these options just help with creating secrets, and they must respect the configuration provided
in the TSB `ManagementPlane` CR, otherwise the installation will end up misconfigured.
:::

| Name                                       | Description                                                                                                                                                                                                                                         | Default value |
|--------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| `secrets.keep`                             | Enabling this makes the generated secrets persist in the cluster after uninstalling the chart if they are no provided in future updates. (see [Helm doc](https://helm.sh/docs/howto/charts_tips_and_tricks/#tell-helm-not-to-uninstall-a-resource)) | `false`       |
| `secrets.tsb.cacert`                       | CA certificate used to verify TLS certs exposed the Management Plane (front envoy)                                                                                                                                                                  |               |
| `secrets.elasticsearch.username`           | The username to access Elasticsearch                                                                                                                                                                                                                ||
| `secrets.elasticsearch.password`           | The password to access Elasticsearch                                                                                                                                                                                                                ||
| `secrets.elasticsearch.cacert`             | Elasticsearch CA cert TLS used by control plane to verify TLS connection                                                                                                                                                                            ||
| `secrets.oapToken`                         | JWT token used to authenticate OAP against the Management Plane                                                                                                                                                                                     ||
| `secrets.otelToken`                        | JWT token used to authenticate Otel Collector against the Management Plane                                                                                                                                                                          ||                                                                                                                                                                              ||
| `secrets.clusterServiceAccount.clusterFQN` | TSB FQN of the onboarded cluster resource. This will be generate tokens for all Control Plane agents.                                                                                                                                               ||
| `secrets.clusterServiceAccount.JWK`        | Literal JWK used to generate and sign the tokens for all the Control Plane agents.                                                                                                                                                                  ||
| `secrets.clusterServiceAccount.encodedJWK` | Base64-encoded JWK used to generate and sign the tokens for all the Control Plane agents.                                                                                                                                                           ||

#### XCP secrets configuration

XCP uses JWTs to authenticate against between Edges and Central.

If the XCP root CA (`secrets.xcp.rootca`) is provided it will be used to verify the TLS certs provided by
XCP Central.

Also `secrets.xcp.edge.token` or `secrets.clusterServiceAccount` will be required to authenticate against XCP Central.

The following are the configuration properties allowed to be used to configure XCP authentication mode:

| Name                            | Description                                                                                                                               | Default value |
|---------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| `secrets.xcp.rootca`            | CA certificate of XCP components                                                                                                          ||
| `secrets.xcp.edge.token`        | JWT token used to authenticate XCP Edge against the XCP Central                                                                           ||

### Operator extended configuration

This is an **optional** field. You can customize TSB operator related resources like the deployment, the service or the service account using the following optional properties:

| Name                                           | Description                                                                      | Default value |
|------------------------------------------------|----------------------------------------------------------------------------------|---------------|
| `operator.deployment.affinity`                 | Affinity configuration for the pod                                               ||
| `operator.deployment.annotations`              | Custom collection of annotations to add to the deployment                        ||
| `operator.deployment.env`                      | Custom collection of environment vars to add to the container                            ||
| `operator.deployment.podAnnotations`           | Custom collection of annotations to add to the pod                               ||
| `operator.deployment.replicaCount`             | Number of replicas managed by the deployment                                     ||
| `operator.deployment.strategy`                 | Deployment strategy to use                                                       ||
| `operator.deployment.tolerations`              | Toleration collection applying to the pod scheduling                             ||
| `operator.deployment.podSecurityContext`       | [SecurityContext](../../refs/install/kubernetes/k8s#tetrateio-api-install-kubernetes-podsecuritycontext) properties to apply to the pod                              ||
| `operator.deployment.containerSecurityContext` | [SecurityContext](../../refs/install/kubernetes/k8s#tetrateio-api-install-kubernetes-securitycontext) properties to apply to the pod's containers                             ||
| `operator.service.annotations`                 | Custom collection of annotations to add to the service                           ||
| `operator.serviceAccount.annotations`          | Custom collection of annotations to add to the service account                   ||
| `operator.serviceAccount.imagePullSecrets`     | Collection of secrets names required to be able to pull images from the registry ||
| `operator.pullSecret`                          | A JSON encoded Docker configuration that will be stored as an image pull secret          ||
