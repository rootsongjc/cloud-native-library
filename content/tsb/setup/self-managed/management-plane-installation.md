---
title: Management Plane Installation
description: Install and Set up the Tetrate Service Bridge Management Plane.
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

This page will show you how to install the Tetrate Service Bridge management
plane in a production environment.

Before you start, make sure that you've:

✓ Checked the [requirements](../requirements-and-download)<br />
✓ Checked [TSB management plane components](../components#management-plane)<br />
✓ Checked [types of certificates](../certificate/certificate-setup) and  [internal certificates requirements](../certificate/certificate-requirements)<br />
✓ Checked [firewall information](../firewall_information)<br />
✓ If you are upgrading from previous version, also check [PostgreSQL backup and restore](../../operations/postgresql)<br />
✓ [Downloaded](../requirements-and-download#download) Tetrate Service Bridge CLI (`tctl`)<br />
✓ [Synced](../requirements-and-download#sync-tetrate-service-bridge-images) the Tetrate Service Bridge images

## Management Plane Operator

To keep installation simple but still allow a lot of custom configuration
options we have created a management plane operator. The operator will run in
the cluster and bootstraps the management plane as described in a
ManagementPlane Custom Resource. It watches for changes and enacts them. To help
in creating the right Custom Resource Document (CRD) we have added the ability
to our `tctl` client to create the base manifests which you can then modify
according to your required set-up. After this you can either apply the manifests
directly to the appropriate clusters or use in your source control operated
clusters.

:::note Operators
If you would like to know more about the inner workings of Operators, and the
Operator Pattern, review the [Kubernetes documentation](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)
:::

Create the manifest allowing you to install the management plane operator
from your private Docker registry:

```bash{promptUser: alice}{outputLines:2}
tctl install manifest management-plane-operator \
  --registry <registry-location> > managementplaneoperator.yaml
```

<Tabs
  defaultValue="Default"
  values={[
    {label: 'Standard', value: 'Default'},
    {label: 'OpenShift', value: 'OC'},
]}>

  <TabItem value="Default">

The `managementplaneoperator.yaml` file created by the install manifest command
can be applied directly to the appropriate cluster by using the kubectl client:

```bash{promptUser: alice}
kubectl apply -f managementplaneoperator.yaml
```

After applying the manifest you will see the operator running in the `tsb`
namespace:

```bash{promptUser: alice}
kubectl get pod -n tsb
```

  </TabItem>
  <TabItem value="OC">

:::note RedHat Ecosystem Catalog
TSB is certified and listed on RedHat Ecosystem Catalog. TSB can be installed on
Openshift platform by following the instructions below or via [here](https://catalog.redhat.com/software/container-stacks/detail/63224dc0bc45b8cf6605f7e8).
:::

The `managementplaneoperator.yaml` file created by the install manifest command
can be applied directly to the appropriate cluster by using the `oc` client:

```bash{promptUser: alice}
oc apply -f managementplaneoperator.yaml
```

After applying the manifest you will see the operator running in the `tsb`
namespace:

```bash{promptUser: alice}
oc get pod -n tsb
```

  </TabItem>
</Tabs>

Example output:

```text
NAME                                            READY   STATUS    RESTARTS   AGE
tsb-operator-management-plane-d4c86f5c8-b2zb5   1/1     Running   0          8s
```

## Configuring Secrets

The management plane components need some secrets for both internal and external communication purposes. Following are a list of secrets that you need to create.

| Secret name | Description |
|----------------|-------------|
| `admin-credentials` | TSB will create a default admin user with name: admin and this is the password's one way hash for this special account. These credentials are kept outside of your IdP while any other credentials must be stored in your IdP. |
| `tsb-certs` | TLS certificate that has type `kubernetes.io/tls`. Must have `tls.key` and `tls.cert` value. The TLS certificates can be self signed or issued by public CA. |
| `postgres-credentials` | Contains:<br />&ensp;1. Postgres username and password. <br />&ensp;2. The CA certificate to verify Postgres connections when Postgres is configured to present a self-signed certificate. TLS verification only happens if you set `sslMode` in Postgres settings to `verify-ca` or `verify-full`. See [PostgresSettings](../../refs/install/managementplane/v1alpha1/spec#postgressettings) for more details. <br />&ensp;3. Client certificate and private key if Postgres is configured with mutual TLS. |
| `elastic-credentials` | Elasticsearch username and password. |
| `es-certs` | The CA certificate to validate Elasticsearch connections when Elasticsearch is configured to present a self-signed certificate. |
| `ldap-credentials` | Only set if using LDAP as Identity Provider (IdP). Contain LDAP `binddn` and `bindpassword`. |
| `custom-host-ca` | Only set if using LDAP as IdP. The CA certificate to validate LDAP connections when LDAP is configured to present a self-signed certificate. |
| `iam-oidc-client-secret` | Only set if using OIDC with any IdP. Contain OIDC client-secret and device-client-secret. |
| `azure-credentials` | Only set if using OIDC with Azure AD as IdP. Client secret to connect to Azure AD for team and user synchronization. |
| `xcp-central-cert` | XCP central TLS certificate. Go to [Internal certificate requirements](../certificate/certificate-requirements) for more details. |

### Using tctl to Generate Secrets

:::note
Since 1.7, TSB supports automated certificate management for TSB management plane TLS certificates, internal certificates and intermediate Istio CA certificates. Go to [Automated Certificate Management](../certificate/automated-certificate-management) for more details. This means you don't need to create `tsb-certs` and `xcp-central-cert` secrets anymore. The following example will assume that you are using automated certificate management.
:::

These secrets can be generated in the correct format by passing them as command-line flags to the `tctl` management-plane-secrets command.

<Tabs
  defaultValue="OIDC"
  values={[
    {label: 'OIDC as IdP', value: 'OIDC'},
    {label: 'LDAP as IdP', value: 'LDAP'},
]}>

  <TabItem value="OIDC">

The following command will generate `managementplane-secrets.yaml` that contains Elasticsearch, Postgres, OIDC and admin credentials along with TSB TLS certificate.

```bash{promptUser: alice}
tctl install manifest management-plane-secrets \
    --elastic-password <elastic-password> \
    --elastic-username <elastic-username> \
    --oidc-client-secret "<oidc-client-secret>" \
    --postgres-password <postgres-password> \
    --postgres-username <postgres-username> \
    --tsb-admin-password <tsb-admin-password> > managementplane-secrets.yaml
```

  </TabItem>
  <TabItem value="LDAP">

The following command will generate `managementplane-secrets.yaml` that contains Elasticsearch, Postgres, LDAP and admin credentials along with TSB TLS certificate.

```bash{promptUser: alice}
tctl install manifest management-plane-secrets \
    --elastic-password <elastic-password> \
    --elastic-username <elastic-username> \
    --ldap-bind-dn <ldap-bind-dn> \
    --ldap-bind-password <ldap-bind-password> \
    --postgres-password <postgres-password> \
    --postgres-username <postgres-username> \
    --tsb-admin-password <tsb-admin-password> > managementplane-secrets.yaml
```

  </TabItem>
</Tabs>

<br />

See the [CLI reference](../../reference/cli/reference/install#tctl-install-manifest-management-plane-secrets)
documentation for all available options such as providing CA certificates for
`Elasticsearch`, `PostgreSQL` and `LDAP`. You can also check the bundled explanation from `tctl` by running this help command:

```bash{promptUser: alice}
tctl install manifest management-plane-secrets --help
```

### Applying secrets

Once you've created your secrets manifest, you can add to source control or apply it to your cluster.

:::note Vault Injection
If you're using `Vault` injection for certain components, remove the applicable
secrets from the manifest that you've created before applying it to your
cluster.
:::

<Tabs
  defaultValue="Default"
  values={[
    {label: 'Standard', value: 'Default'},
    {label: 'OpenShift', value: 'OC'},
  ]}>
  <TabItem value="Default">

```bash{promptUser: alice}
kubectl apply -f managementplane-secrets.yaml
```

  </TabItem>
  <TabItem value="OC">

```bash{promptUser: alice}
oc apply -f managementplane-secrets.yaml
```

  </TabItem>
</Tabs>

## Management Plane Installation

Now you're ready to deploy the management plane.

To deploy the management plane you need to create a `ManagementPlane` custom
resource in the Kubernetes cluster that describes the management plane.

:::warning Organization name
Organization is a root of the TSB object hierarchy. A TSB Management plane can only have one organization.

To login with `tctl`, you will need to specify organization name and it must match with `<organization-name>` that you set in the `ManagementPlane` CR below. Organization name has to be lowercase to comply with RFC standards.

If not specified, the default value is `tetrate` and it cannot be changed after creation.
:::

Below is a [ManagementPlane](../../refs/install/managementplane/v1alpha1/spec)
custom resource (CR) that describes a basic management plane. Save this
`managementplane.yaml` and adjust it according to your needs:

<Tabs
  defaultValue="OIDC"
  values={[
    {label: 'OIDC as IdP', value: 'OIDC'},
    {label: 'LDAP as IdP', value: 'LDAP'},
  ]}>
  <TabItem value="OIDC">

The following example uses OIDC as identity provider.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
  namespace: tsb
spec:
  hub: <registry-location>
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
      protocol: <http or https. default to https if not set>
  
  # Enable automatic certificates management.
  # You can remove this field if you want to manage certificates user other methods
  # Note that you will need to provide certificates as secrets in that case.
  certIssuer:
    selfSigned: {}
    tsbCerts: {}
    clusterIntermediateCAs: {}
  
  identityProvider:
    oidc:
      clientId: <oidc-client-id>
      # authorization code flow for TSB UI login
      providerConfig:
        dynamic:
          configurationUri: <oidc-well-known-openid-configuration>
      redirectUri: <oidc-callback>
      scopes:
      - email
      - profile
      - offline_access

  components:
    internalCertProvider:
      certManager:
        managed: INTERNAL
```

If you are not using Azure AD an the OIDC Identity provider, follow the steps in [Users Synchronization](../../operations/users/user_synchronization) to see how you can create organizations and sync your users and teams into TSB

  </TabItem>
  <TabItem value="LDAP">

The following uses LDAP as the identity provider

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
  namespace: tsb
spec:
  hub: <registry-location>
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
      protocol: <http or https. default to https if not set>

  # Enable automatic certificates management.
  # You can remove this field if you want to manage certificates user other methods
  # Note that you will need to provide certificates as secrets in that case.
  certIssuer:
    selfSigned: {}
    tsbCerts: {}
    clusterIntermediateCAs: {}

  identityProvider:
    ldap:
      host: <ldap-hostname-or-ip>
      port: <ldap-port>
      search:
        baseDN: dc=tetrate,dc=io
      iam:
        matchDN: "cn=%s,ou=People,dc=tetrate,dc=io"
        matchFilter: "(&(objectClass=person)(uid=%s))"
      sync:
        usersFilter: "(objectClass=person)"
        groupsFilter: "(objectClass=groupOfUniqueNames)"
        membershipAttribute: uniqueMember

  components:
    internalCertProvider:
      certManager:
        managed: INTERNAL
```

  </TabItem>
</Tabs>


For more information on what each of these sections describes and how to
configure them, please check out the following links:

- [Data Store](../../refs/install/managementplane/v1alpha1/spec#datastore)
- [Telemetry Store](../../refs/install/managementplane/v1alpha1/spec#telemetrystore)
- [Identity Provider](../../refs/install/managementplane/v1alpha1/spec#identityprovider)
- [Token Issuer](../../refs/install/managementplane/v1alpha1/spec#tokenissuer)
- [Internal Cert Provider](../../refs/install/common/common_config#internalcertprovider)

Edit the relevant sections, save your configured custom resource to a file and
apply it to your Kubernetes cluster.

<Tabs
  defaultValue="Default"
  values={[
    {label: 'Standard', value: 'Default'},
    {label: 'OpenShift', value: 'OC'},
  ]}>
  <TabItem value="Default">

```bash{promptUser: alice}
kubectl apply -f managementplane.yaml
```

  </TabItem>
  <TabItem value="OC">

Before applying it, bear in mind that you will have to allow the service accounts
of the different management plane components to your OpenShift Authorization Policies.

```bash{promptUser: alice}
oc adm policy add-scc-to-user anyuid -n tsb -z tsb-iam
oc adm policy add-scc-to-user anyuid -n tsb -z tsb-oap
```

Now you can apply it:

```bash{promptUser: alice}
oc apply -f managementplane.yaml
```

  </TabItem>
</Tabs>

Note: TSB will automatically do this every hour, so this command only needs to
be run once after the initial installation.

### Verifying Installation

To verify your installation succeeded, log in as the admin user. Try to connect
to the TSB UI or login with the `tctl` CLI tool.

The TSB UI is reachable on port 8443 of the external IP as returned by the
following command:


<Tabs
  defaultValue="Default"
  values={[
    {label: 'Standard', value: 'Default'},
    {label: 'OpenShift', value: 'OC'},
  ]}>
  <TabItem value="Default">

```bash{promptUser: alice}
kubectl get svc -n tsb envoy
```

  </TabItem>
  <TabItem value="OC">

```bash{promptUser: alice}
oc get svc -n tsb envoy
```

  </TabItem>
</Tabs>

To configure `tctl`'s default config profile to point to your new TSB cluster do
the following:

<Tabs
  defaultValue="Default"
  values={[
    {label: 'Standard', value: 'Default'},
    {label: 'AWS', value: 'AWS'},
  ]}>
  <TabItem value="Default">

```bash{promptUser: alice}
tctl config clusters set default --bridge-address $(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):8443
```
  </TabItem>
  <TabItem value="AWS">

```bash{promptUser: alice}
tctl config clusters set default --bridge-address $(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'):8443
```

  </TabItem>
</Tabs>

Now you can log in with `tctl` and provide the organization name and admin account credentials.
The tenant field is optional and can be left blank at this point and configured later,
when tenants are added to the platform.

```bash{promptUser: alice}{outputLines: 2-5}
tctl login
Organization: tetrate
Tenant:
Username: admin
Password: *****
Login Successful!
```

Go to [Connect to TSB with tctl](../tctl_connect) for more details on how to configure tctl.
