---
title: Management Plane Installation
description: How to leverage Helm to install the management plane element.
---

# Management Plane Installation

This chart installs the TSB management plane operator, which also allows you to install TSB management plane components using the [TSB `ManagementPlane` CR](../../refs/install/managementplane/v1alpha1/spec) and all the required secrets to make it fully run. 

Before you start, make sure that you have checked the [Helm installation process](./helm#installation-process).

## Installation overview

1. Create a `values.yaml` file and edit it with your desired configuration. You can find more details on the available Helm configuration in the [configuration](#configuration) section below. For a full reference of the `spec` section, see the [TSB `ManagementPlane` CR](../../refs/install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanespec).

2. Use the `helm install` command to install TSB management plane. Make sure to set the `image.registry` and `version` to the correct registry location and TSB version.

3. Wait until all TSB management plane components have been deployed successfully. You can verify your installation by trying to log in to TSB UI or connect to TSB using [tctl](../tctl_connect).

## Installation

To install TSB management plane, create a `values.yaml` file with the following content and edit it according to your needs. 

```yaml
spec:
  # Set the organization name. Organization name has to be lowercase to comply with RFC standards.
  organization: <organization-name>

  dataStore:
    postgres:
      host: <postgres-hostname-or-ip>
      port: <postgres-port>
      name: <database-name>
  telemetryStore:
    elastic:
      host: <elastic-hostname-or-ip>
      port: <elastic-port>
      version: <elastic-version>
      selfSigned: <is-elastic-use-self-signed-certificate>

  # TSB support OIDC and LDAP as Identity Provider.
  # Set according to your environment.
  identityProvider:
    ...

  # Enable automatic certificates management.
  # You can remove this field if you want to manage certificates using other methods.
  # Note that you will need to provide certificates as secrets in that case.
  certIssuer:
    selfSigned: {}
    tsbCerts: {}
    clusterIntermediateCAs: {}

  # The default port for TSB Management Plane is 8443. You can change it here.
  components:
    frontEnvoy:
      port: 443
    # enable oap streaming log feature
    oap:
      streamingLogEnabled: true

secrets:
  tsb:
    adminPassword: <tsb-admin-password>

  postgres:
    username: <postgres-username>
    password: <postgres-password>

  # Depending on your IdP, you need to set required secrets here.
  ...
```

Then, use the following helm install command to install TSB management plane. This installation can take up to 10 minutes to complete. Make sure to replace `<tsb-version>` and `<registry-location>` with the correct values.

```shell
helm install mp tetrate-tsb-helm/managementplane \
  --version <tsb-version> \
  --namespace tsb  --create-namespace \
  --values values.yaml \
  --timeout 10m \
  --set image.registry=<registry-location>
```

### Non-prod external dependencies

If you omit the `dataStore`, `telemetryStore`, and `identityProvider` fields in your `values.yaml` file, TSB will install non-prod Postgres, Elasticsearch, and LDAP. Note that you still need to set correct secrets and credentials to use the storage.

:::danger 
DO NOT USE NON-PROD STORAGE AND IDENTITY PROVIDER IN PRODUCTION.
:::

Here is an example of a completed `values.yaml` file for a demo installation:
```yaml
spec:
  organization: <organization-name>

  # Enable automatic certificates management.
  certIssuer:
    selfSigned: {}
    tsbCerts: {}
    clusterIntermediateCAs: {}

secrets:
  tsb:
    adminPassword: <tsb-admin-password>

  postgres:
    username: tsb
    password: tsb-postgres-password

  ldap:
    binddn: cn=admin,dc=tetrate,dc=io
    bindpassword: admin
```

## Accessing TSB Management Plane

After completing the installation, you can access TSB management plane by log in to TSB UI or using [tctl](../tctl_connect).

## Troubleshooting

If you encounter any issues during the installation process, here are a few things to check:

- Make sure that you have entered the correct values in your `values.yaml` file.
- Verify that you are using the correct registry location and TSB version in the `helm install` command.
- If you are using a custom identity provider, make sure that you have set all of the required `secrets` in the secrets section of the `values.yaml` file.
- If you are having trouble connecting to TSB, make sure that all TSB components have been deployed successfully and that there are no errors in the logs.
- If you are using a private registry to host the TSB control plane operator image, make sure that you have authenticated with the registry and that the `image.registry` value is correct.

## Configuration

### Image configuration

This is a **required** field. Set `image.registry` to the location of your private registry where you have synced the TSB images, and set `image.tag` to the TSB version that you want to deploy. Specifying only this field will install the TSB control plane operator without installing other TSB components. 

| Name             | Description                                                                | Default value                        |
|------------------|----------------------------------------------------------------------------|--------------------------------------|
| `image.registry` | Registry used to download the operator image. Required                     | `containers.dl.tetrate.io` |
| `image.tag`      | The tag of the operator image. Required             | *same as the Chart version*                       |

### Management plane resource configuration

This is an **optional** field. You can set [TSB `ManagementPlane` CR `spec`](../../refs/install/managementplane/v1alpha1/spec##tetrateio-api-install-managementplane-v1alpha1-managementplanespec) in Helm values file to make the TSB management plane fully run.

| Name             | Description                                                                | Default value                        |
|------------------|----------------------------------------------------------------------------|--------------------------------------|
| `spec`           | Holds the `spec` section of the `ManagementPlane` CR. Optional ||

### Secrets configuration

This is an **optional** field. You can apply secrets into your cluster before installing TSB management plane or you can use Helm values to specify required secrets. Note that you can use different Helm values file if you want to separate secrets from management plane spec.

:::warning
Keep in mind that these options just help with creating secrets, and they must respect the configuration provided
in the TSB `ManagementPlane` CR, otherwise the installation will end up misconfigured.
:::

| Name                              | Description                                                                                                                                                                                                                                         | Default value |
|-----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| `secrets.keep`                    | Enabling this makes the generated secrets persist in the cluster after uninstalling the chart if they are no provided in future updates. (see [Helm doc](https://helm.sh/docs/howto/charts_tips_and_tricks/#tell-helm-not-to-uninstall-a-resource)) | `false`       |                                                                                                                                                
| `secrets.tsb.adminPassword`       | The password that is going to be configured for the `admin` user.                                                                                                                                                                                   ||
| `secrets.tsb.cert`                | The TLS certificate exposed by the management plane (front envoy).                                                                                                                                                                                  ||
| `secrets.tsb.key`                 | The key for TLS certificate exposed by the management plane (front envoy).                                                                                                                                                                          ||
| `secrets.postgres.username`       | The username used to access the Postgres database.                                                                                                                                                                                                  ||
| `secrets.postgres.password`       | The password used to access the Postgres database.                                                                                                                                                                                                  ||
| `secrets.postgres.cacert`         | The CA cert to verify TLS certificates provided by the Postgres database.                                                                                                                                                                           ||
| `secrets.postgres.clientcert`     | The client cert required to access the Postgres database.                                                                                                                                                                                           ||
| `secrets.postgres.clientkey`      | The key for the client cert required to access the Postgres database.                                                                                                                                                                               ||
| `secrets.elasticsearch.username`  | The username used to access the Elasticsearch.                                                                                                                                                                                                      ||
| `secrets.elasticsearch.password`  | The password used to access the Elasticsearch.                                                                                                                                                                                                      ||
| `secrets.elasticsearch.cacert`    | The CA cert to verify TLS certificates provided by the Elasticsearch.                                                                                                                                                                               ||
| `secrets.ldap.binddn`             | The bind DN used to read from the LDAP IDP.                                                                                                                                                                                                         ||
| `secrets.ldap.bindpassword`       | The password for the provided bind DN used to read from the LDAP IDP.                                                                                                                                                                               ||
| `secrets.ldap.cacert`             | The CA cert to verify TLS certificates provided by the LDAP IDP.                                                                                                                                                                                    ||
| `secrets.oidc.clientSecret`       | The client secret used to connect to the configured OIDC.                                                                                                                                                                                           ||
| `secrets.oidc.deviceClientSecret` | The device client secret used to connect to the configured OIDC.                                                                                                                                                                                    ||
| `secrets.azure.clientSecret`      | The client secret used to connect to the Azure OIDC.                                                                                                                                                                                               ||

#### XCP secrets configuration

XCP uses TLS and JWTs to authenticate between Edges and Central.

If `secrets.xcp.autoGenerateCerts` is **disabled**, the certificate for XCP Central and the key must be provided by the
user using `secrets.xcp.central.cert` and `secrets.xcp.central.key`.

Optionally, a CA can be provided with `secrets.xcp.rootca` to allow the MPC component to use it to verify the certs
provided by XCP Central.

If `secrets.xcp.autoGenerateCerts` is **enabled**, Cert Manager is required to provide the XCP Central certificate.

Then `secrets.xcp.rootca` and `secrets.xcp.rootcakey` will be used to create the proper Issuer and generate the
certificate for XCP Central and share the CA with MPC to allow it to verify the XCP Central generated cert.

The following properties are allowed to be used to configure the XCP authentication mode:

| Name                                        | Description                                                                                                        | Default value            |
|---------------------------------------------|--------------------------------------------------------------------------------------------------------------------|--------------------------|
| `secrets.xcp.autoGenerateCerts`             | Enabling this will auto generate the XCP Central TLS certificate. Requires cert-manager                            | `false`                  |
| `secrets.xcp.rootca`                        | The XCP components CA certificate.                                                                                 ||
| `secrets.xcp.rootcakey`                     | The XCP components Root CA certificate key.                                                                        ||
| `secrets.xcp.central.cert`                  | The XCP Central certificate for TLS.                                                                               ||
| `secrets.xcp.central.key`                   | The XCP Central certificate key for TLS.                                                                           ||
| `secrets.xcp.central.additionalDNSNames`    | Additional DNS names to be added in the XCP Central certificate when `secrets.xcp.autoGenerateCerts` is enabled    ||
| `secrets.xcp.central.additionalURIs`        | Additional URIs to be added in the XCP Central certificate when `secrets.xcp.autoGenerateCerts` is enabled         ||
| `secrets.xcp.central.additionalIPAddresses` | Additional IP addresses to be added in the XCP Central certificate when `secrets.xcp.autoGenerateCerts` is enabled ||
| `certManager.clusterResourcesNamespace`     | The namespace configured in the Cert Manager installation for cluster resources.                                   | `cert-manager`           |

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
