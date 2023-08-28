---
title: Management Plane
description: Configuration to describe a TSB management plane installation.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

ManagementPlane resource exposes a set of configurations necessary to automatically install
the Service Bridge management plane on a cluster. The installation API is an override API so any
unset fields that are not required will use sensible defaults.

Prior to creating the ManagementPlane resource, verify that the following secrets exist in the namespace
the management plane will be installed into:

  - tsb-certs
  - ldap-credentials
  - custom-host-ca (if you are using TLS connection and need a custom CA to connect to LDAP host)
  - postgres-credentials (non-demo deployments)
  - admin-credentials
  - es-certs (if your Elasticsearch is using a self-signed certificate)
  - elastic-credentials (if your Elasticsearch backend requires authentication)

A resource containing only the container registry hub will install a demo of Service Bridge, create a default
Organization and install local instances of external dependencies, such as Postgres, Elasticsearch, and LDAP server.  
Please note that these local instances are for demonstrative purposes only and should not be used in production.
Production setups should point to a user managed Postgres and Elasticsearch as well as the enterprise LDAP server.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  hub: docker.io/tetrate
  organization: tetrate
```

To move from the demo installation to production readiness, configure the top level settings
that enable TSB to connect to external dependencies. When one of these settings stanzas are added
the operator will delete the relevant demo component and configure the management plane to talk
to the dependencies described.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  hub: docker.io/tetrate
  imagePullSecrets:
  - name: my-registry-creds
  organization: tetrate
  dataStore:
    postgres:
      address: postgres:1234
  telemetryStore:
    elastic:
      host: elastic
      port: 5678
  identityProvider:
    ldap:
      host: ldap
      port: 389
      search:
        baseDN: dc=tetrate,dc=io
      iam:
        matchDN: "cn=%s,ou=People,dc=tetrate,dc=io"
        matchFilter: "(&(objectClass=person)(uid=%s))"
      sync:
        usersFilter: "(objectClass=person)"
        groupsFilter: "(objectClass=groupOfUniqueNames)"
        membershipAttribute: uniqueMember
  tokenIssuer:
    jwt:
      expiration: 1h
      issuers:
      - name: https://jwt.tetrate.io
        algorithm: RS256
        signingKey: tls.key
```

Top level settings deal with higher level concepts like persistence, but some configuration
can also be overridden per component. For example, to configure the team synchronization schedule
in the API server, set the schedule field in the apiServer component

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  hub: docker.io/tetrate
  organization: tetrate
  components:
    apiServer:
      teamSyncSchedule: 17 * * * *
  dataStore:
    postgres:
      address: postgres:1234
  telemetryStore:
    elastic:
      host: elastic
      port: 5678
  identityProvider:
    ldap:
      host: ldap
      port: 389
      search:
        baseDN: dc=tetrate,dc=io
      iam:
        matchDN: "cn=%s,ou=People,dc=tetrate,dc=io"
        matchFilter: "(&(objectClass=person)(uid=%s))"
      sync:
        usersFilter: "(objectClass=person)"
        groupsFilter: "(objectClass=groupOfUniqueNames)"
        membershipAttribute: uniqueMember
  tokenIssuer:
    jwt:
      expiration: 1h
      issuers:
      - name: https://jwt.tetrate.io
        algorithm: RS256
        signingKey: tls.key
```

To configure infrastructure specific settings such as resource limits on the deployment in
Kubernetes, set the relevant field in a component. Remember that the installation API is an
override API so if these fields are unset the operator will use sensible defaults.
Only a subset of Kubernetes configuration is available and only for individual components.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  hub: docker.io/tetrate
  organization: tetrate
  components:
    collector:
      kubeSpec:
        deployment:
          resources:
            limits:
              memory: 750Mi
            requests:
              memory: 500Mi
  dataStore:
    postgres:
      address: postgres:1234
  telemetryStore:
    elastic:
      host: elastic
      port: 5678
  identityProvider:
    ldap:
      host: ldap
      port: 389
      search:
        baseDN: dc=tetrate,dc=io
      iam:
        matchDN: "cn=%s,ou=People,dc=tetrate,dc=io"
        matchFilter: "(&(objectClass=person)(uid=%s))"
      sync:
        usersFilter: "(objectClass=person)"
        groupsFilter: "(objectClass=groupOfUniqueNames)"
        membershipAttribute: uniqueMember
  tokenIssuer:
    jwt:
      expiration: 1h
      issuers:
      - name: https://jwt.tetrate.io
        algorithm: RS256
        signingKey: tls.key
```





## ManagementPlaneComponentSet {#tetrateio-api-install-managementplane-v1alpha1-managementplanecomponentset}

The set of components that make up the management plane. Use this to override application settings
or Kubernetes settings for each individual component.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


apiServer

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.ApiServer](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-apiserver) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


iamServer

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.IamServer](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-iamserver) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


webUI

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.WebUI](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-webui) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


frontEnvoy

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.FrontEnvoy](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-frontenvoy) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


oap

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.Oap](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-oap) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


collector

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.OpenTelemetryCollector](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-opentelemetrycollector) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


xcp

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.XCP](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-xcp) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


mpc

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.MPC](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-mpc) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


defaultLogLevel

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The default log level for all components if the per component log level config is not specified.
Note that the supported log level for different components can be different. See each components'
`log_level` for more information.
TODO(incfly): define and map a few choices making sense for all components instead of pass through.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ngac

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.NGAC](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-ngac) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


internalCertProvider

</td>

<td>

[tetrateio.api.install.common.InternalCertProvider](../../../install/common/common_config#tetrateio-api-install-common-internalcertprovider) <br/> Configure the Kubernetes CSR certificate provider for TSB internal purposes like Webhook TLS certificates.
This configuration is required for kubernetes version 1.22 and above.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


defaultKubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetesspec) <br/> Configure Kubernetes default settings for all components. These settings will be merged to all components'
settings, only if the component does not define the same setting. In that case, the setting defined at the 
component level prevails over the global default.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


gitops

</td>

<td>

[tetrateio.api.install.common.GitOps](../../../install/common/common_config#tetrateio-api-install-common-gitops) <br/> Configuration for the integration of the Management Plane with Continuous Deployment pipelines.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ManagementPlaneSpec {#tetrateio-api-install-managementplane-v1alpha1-managementplanespec}

ManagementPlaneSpec defines the desired installed state of TSB management plane components.
Specifying a minimal ManagementPlaneSpec with hub set results in a demo installation.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


hub

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> TSB container hub path e.g. docker.io/tetrate.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


imagePullSecrets

</td>

<td>

List of [tetrateio.api.install.kubernetes.LocalObjectReference](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-localobjectreference) <br/> Pull secrets can be specified globally for all components, or defined into
the `kubeSpec.serviceAccount` of every component if needed. In case both
are defined, the most specific one (the one defined at the component) level
is used.

List of references to secrets in the same namespace to use for pulling any
images in pods that reference this ServiceAccount. ImagePullSecrets are
distinct from Secrets because Secrets can be mounted in the pod, but
ImagePullSecrets are only accessed by the kubelet. More info:
https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#service_account-v1-core

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


organization

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The name of the organization to be used across the management plane

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


components

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.ManagementPlaneComponentSet](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanecomponentset) <br/> The set of components that make up the management plane. Use this to override application settings
or Kubernetes settings for individual components.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


dataStore

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.ManagementPlaneSpec.DataStore](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-datastore) <br/> Configure the data store for TSB to persist its data to.
This is a mandatory setting for production. If omitted, the operator will assume
a demo installation and for your convenience install a demo grade data store.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


telemetryStore

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.ManagementPlaneSpec.TelemetryStore](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-telemetrystore) <br/> Configure the store that TSB will use to persist application telemetry data
This is a mandatory setting for production. If omitted, the operator will assume
a demo installation and for your convenience install a demo grade telemetry store.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


identityProvider

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.ManagementPlaneSpec.IdentityProvider](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-identityprovider) <br/> Configure the Identity Provider TSB will use as the source of users.
This identity provider is used for user authentication and to periodically synchronize the
information of existing users and groups into the platform.
This is a mandatory setting for production. If omitted, the operator will assume
a demo installation and for your convenience install a demo identity provider.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tokenIssuer

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.ManagementPlaneSpec.TokenIssuer](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-tokenissuer) <br/> Configure the Token Issuer TSB will use to mint tokens upon initial authentication with the
identity provider. This token is used to authenticate any subsequent internal requests in TSB.
This is a mandatory setting for production. If omitted, the operator will use an insecure default.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


meshObservability

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.ManagementPlaneSpec.MeshObservability](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-meshobservability) <br/> Configure how the mesh should be observed, which observability functionalities should be
enabled to observe your registered services in the mesh, and the store properties
that TSB will use to persist application observability data like metrics, traces,
logs.
If omitted, a demo grade mesh observability setting will be configured for your convenience.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


certIssuer

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.CertIssuer](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-certissuer) <br/> Configure a built in issuer for the TLS certificates used by TSB and the data plane.
If omitted, the certificates will need to be provided manually.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


enableWasmDownloadProxy

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When enabled, the OCI WASM extensions will be downloaded via a TSB download proxy.
The download proxy integrates with the common cloud providers to automatically leverage the cloud credentials
without requiring users to explicitly configure them in `imagePullSecrets`. If you are hosting the WASM
extensions in your cloud provider OCI registry, you may consider turning this flag on.
Default: false.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### DataStore {#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-datastore}

Configure the data store for TSB to persist its data to.
This is a mandatory setting for production. If omitted, the operator will assume
a demo installation and for your convenience install a demo grade data store.
Select one of the `DataStore` settings to see complete examples.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


postgres

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.PostgresSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-postgressettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> data_store</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### IdentityProvider {#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-identityprovider}

Configure the Identity Provider TSB will use as the source of users.
This identity provider is used for user authentication and to periodically synchronize the
information of existing users and groups into the platform.
This is a mandatory setting for production. If omitted, the operator will assume
a demo installation and for your convenience install a demo identity provider.
Select one of the `IdentityProvider` settings to see complete examples.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


oidc

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.OIDCSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-oidcsettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> identity_provider</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ldap

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.LDAPSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-ldapsettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> identity_provider</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


sync

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.ManagementPlaneSpec.IdentityProvider.OrgSyncSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-identityprovider-orgsyncsettings) <br/> This field is optional and by default organization will be synchronized using the configuration for
the Identity Provider.
However, it is possible to set specific settings for the organization synchronization by setting this field.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### OrgSyncSettings {#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-identityprovider-orgsyncsettings}





  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


azure

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.AzureSyncSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-azuresyncsettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> provider</sup>_ <br/> Synchronizes users and groups from the configured Azure Active Directory account.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ignoreOrphanUsers

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When set to true, users that are not included in any of the synchronized groups will
be ignored.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### MeshObservability {#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-meshobservability}

Configure how the mesh should be observed, which observability functionalities should be
enabled to observe your registered services in the mesh, and the store properties
that TSB will use to persist application observability data like metrics, traces,
logs.
If omitted, the operator will assume
a demo installation and for your convenience install a demo grade mesh observability
setting.
Check `MeshObservabilitySettings` to see complete examples.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


settings

</td>

<td>

[tetrateio.api.install.common.MeshObservabilitySettings](../../../install/common/common_config#tetrateio-api-install-common-meshobservabilitysettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> mesh_observability</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### TelemetryStore {#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-telemetrystore}

Configure the store that TSB will use to persist application telemetry data
This is a mandatory setting for production. If omitted, the operator will assume
a demo installation and for your convenience install a demo grade telemetry store.
Select one of the `TelemetryStore` settings to see complete examples.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


elastic

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.ElasticSearchSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-elasticsearchsettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> telemetry_store</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### TokenIssuer {#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-tokenissuer}

Configure the Token Issuer TSB will use to mint tokens upon initial authentication with the
identity provider. This token is used to authenticate any subsequent internal requests in TSB.
This is a mandatory setting for production. If omitted, the operator will use an insecure default.
Select one of the `TokenIssuer` settings to see complete examples.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


jwt

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.JWTSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-jwtsettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> token_issuer</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ApiServer {#tetrateio-api-install-managementplane-v1alpha1-apiserver}

Application and Kubernetes settings for the API server component.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesJobComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetesjobcomponentspec) <br/> Configure Kubernetes specific settings.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


teamSyncSchedule

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The schedule on which to synchronize teams with the configured identity provider
Standard five field cron format. For example, "0 * * * *" triggers the sync hourly at minute 0.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


logLevels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> The log level configuration by scopes.
Supported log level: "none", "error", "warn", "info", "debug".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## FrontEnvoy {#tetrateio-api-install-managementplane-v1alpha1-frontenvoy}

Application and Kubernetes settings for the FrontEnvoy component.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


authenticationTimeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Configure the timeout when making an authentication request to the IAM server

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Configure the management plane ingress port

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


TLSMinimumProtocolVersion

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.TLSProtocol](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-tlsprotocol) <br/> The minimum TLS protocol version to use. TLS_AUTO defaults to TLSv1_0 for servers.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


cipherSuites

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If set, only the specified cipher list will be supported when negotiating TLS 1.0-1.2 (this setting has no effect when negotiating TLS 1.3).
If the list of custom cipher suites is not set, a default list of cipher suites will be used. Please refer to the following Envoy docs for
a detailed list of the supported and default cipher suites:
https://www.envoyproxy.io/docs/envoy/v1.17.1/api-v3/extensions/transport_sockets/tls/v3/common.proto.html

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ecdhCurves

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If set, the TLS connection will only support the specified ECDH curves. If not specified, the default curves will be used.
Please refer to the following Envoy docs for a detailed list of the supported and default ECDH suites:
https://www.envoyproxy.io/docs/envoy/v1.17.1/api-v3/extensions/transport_sockets/tls/v3/common.proto.html

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


logLevels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> The log level configuration by scopes.
Supported log level: "off", "critical", "error", "warn", "info", "debug", "trace".
For detailed information, see https://www.envoyproxy.io/docs/envoy/latest/start/quick-start/run-envoy#debugging-envoy.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## IamServer {#tetrateio-api-install-managementplane-v1alpha1-iamserver}

Kubernetes settings for the IAM server component.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


logLevels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> The log level configuration by scopes.
Supported log level: "none", "error", "warn", "info", "debug".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## MPC {#tetrateio-api-install-managementplane-v1alpha1-mpc}

Kubernetes settings for the MPC component.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


logLevels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> The log level configuration by scopes.
Supported log level: "none", "error", "warn", "info", "debug".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## NGAC {#tetrateio-api-install-managementplane-v1alpha1-ngac}

Kubernetes settings for the NGAC component.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


enabled

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> NGAC is an experimental component. If enabled is false, this component will not be installed.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


logLevels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> The log level configuration by scopes.
Supported log level: "none", "error", "info", "debug".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Oap {#tetrateio-api-install-managementplane-v1alpha1-oap}

Kubernetes settings for the OAP (SkyWalking) component.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


retentionPeriodDays

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Number of days to retain metrics for. Defaults to 7 days.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


streamingLogEnabled

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Feature flag to determine whether on-demand streaming logs should be enabled.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


onDemandEnvoyMetricsEnabled

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Feature flag to determine whether on-demand envoy metrics should be enabled.
If enabled, the envoy proxy will provide a set of metrics that can be queried using the metrics service.
OAP will provide a query API that can be used to collect envoy proxy metrics for specific pods.
This is only for temporary and real-time queries that can be used, for example, for application troubleshooting use cases. These metrics are not persisted.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


storageIndexMergingEnabled

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Feature flag to determine whether metrics/meter and records should be shard into multi-physical indices, or
instead if they should be merged into a single physical index.
By default "false", metric/meter and records are sharded into multi-physical indices.
Instead of sharding, if enabled by setting it to "true", metrics/meter and records will be merged
into one physical index template `metrics-all` and `records-all`.
This feature flag must also be set on all clusters control plane manifests and have the same value as this one,
otherwise control plane observability data could be written to the wrong or not existing index.
In this storage mode, consider adjusting index settings to scale out properly based on your needs by setting
`storageSpecificIndexSettings` field.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


storageSpecificIndexSettings

</td>

<td>

List of [tetrateio.api.install.managementplane.v1alpha1.Oap.StorageIndexSetting](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-oap-storageindexsetting) <br/> Configure how many shards and replicas a concrete index template should have.
This setting is useful to scale out the indices based on your system traffic and topology. The more traffic,
relationships between services, and service's api endpoint you have more metrics/meter and records will be
generated. Specially if storage logic sharding is disabled, `metrics-all`, `records-all`, `zipkin_span`
should be adjusted based on your needs.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


logLevel

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Specifies the log level for OAP component.
Supported log level: "all", "debug", "info", "warn", "error", "fatal", "off" and "trace".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### StorageIndexSetting {#tetrateio-api-install-managementplane-v1alpha1-oap-storageindexsetting}

Configure the number of shards and replicas a concrete index template should have.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


indexName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The name of the index template that we get the settings applied.
If `storage_index_merging_enabled` is true, the following index templates can be configured:
"metrics-all", "records-all", "log", "zipkin_span"
If `storage_index_merging_enabled` is false, the following index templates can be configured:
"metrics-percent", "metrics-apdex", "ebpf_profiling_task", "metrics-statuscode", "meter-avglabeled",
"service_relation_server_side", "log", "process_traffic", "metrics-sum", "alarm_record", "service_label", "
ebpf_profiling_data", "zipkin_service_span_traffic", "service_relation_client_side", "service_traffic",
"metrics-histogram", "endpoint_traffic", "ebpf_profiling_schedule", "network_address_alias", "metrics-count",
"top_n_cache_write_command", "process_relation_client_side", "zipkin_service_traffic", "metrics-longavg",
"meter-avg", "process_relation_server_side", "top_n_cache_read_command", "instance_traffic", "zipkin_span",
"metrics-cpm", "zipkin_service_relation_traffic", "metrics-percentile", "metrics-doubleavg", "tag_autocomplete"

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


numberOfShards

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The number of shards for the index template.

</td>

<td>

int32 = {<br/>&nbsp;&nbsp;gt: `0`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


numberOfReplicas

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The number of replicas or the index template.

</td>

<td>

int32 = {<br/>&nbsp;&nbsp;gte: `0`<br/>}<br/>

</td>
</tr>
    
</table>
  


## OpenTelemetryCollector {#tetrateio-api-install-managementplane-v1alpha1-opentelemetrycollector}

Kubernetes settings for the OpenTelemetry Collector component.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


logLevel

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Specifies the log level for OTEL collector component.
Supported log level: "debug", "info", "warn", "error", "dpanic", "panic", and "fatal".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## WebUI {#tetrateio-api-install-managementplane-v1alpha1-webui}

Kubernetes settings for the WebUI component.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings
Although possible via the Kubernetes settings, the WebUI does not support multiple instances.
Therefore you should not set `replicaCount` or an `hpaSpec`

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## XCP {#tetrateio-api-install-managementplane-v1alpha1-xcp}

Application and Kubernetes settings for the XCP component.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


centralAuthModes

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.XCP.CentralAuthModes](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-xcp-centralauthmodes) <br/> Authentication modes for connections from XCP Edges to XCP Central.
If not set will default to mutual TLS only.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


configProtection

</td>

<td>

[tetrateio.api.install.common.ConfigProtection](../../../install/common/common_config#tetrateio-api-install-common-configprotection) <br/> ConfigProtection contains settings for enabling/disabling config protection
over XCP created resources.
Config protections are disabled by default.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kubeSpec

</td>

<td>

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


logLevels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Loglevel for XCP.
Supported log level: "none", "fatal", "error", "warn", "info", "debug".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### CentralAuthModes {#tetrateio-api-install-managementplane-v1alpha1-xcp-centralauthmodes}

Authentication modes for connections to XCP Central (from XCP Edges or MPC).
At least one mode must be enabled. Multiple modes can be enabled to
facilitate migration from one mode to another.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


mutualTls

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> GRPC stream is encrypted with mutual TLS

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


jwt

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> XCP Edges present a JWT bearer token in the GRPC headers

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## AzureSyncSettings {#tetrateio-api-install-managementplane-v1alpha1-azuresyncsettings}

Azure configures how users and groups are synchronized from Azure Active Directory.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


clientId

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Client ID of an Azure application that has permissions to synchronize users and teams.
The application must be registered in Azure Ad and have, at least, the
"Windows Azure Active Directory/Read directory Data" permission.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


tenantId

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The tenant id that identifies the specific Azure Active Directory to synchronize.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


environment

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Environment where the Azure Directory belongs to. The supported values are:
   * AzurePublicCloud
   * AzureUSGovernmentCloud
   * AzureChinaCloud
   * AzureGermanCloud
If not set, 'AzurePublicCloud' will be used.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


usersFilter

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If present, the value will be passed to the Microsoft Graph API when listing the users to filter
the results. See: https://docs.microsoft.com/en-us/graph/api/user-list?view=graph-rest-1.0&tabs=http

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


groupsFilter

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If present, the value will be passed to the Microsoft Graph API when listing the groups to filter
the results. See: https://docs.microsoft.com/en-us/graph/api/group-list?view=graph-rest-1.0&tabs=http

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


baseGroupName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If present, we will apply all changes under the hierarchy of the given group i.e. all descendant users 
and groups

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## CertIssuer {#tetrateio-api-install-managementplane-v1alpha1-certissuer}

Configures a built in issuer for TSB TLS certificates.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  certIssuer:
    selfSigned: {}
    tsbCerts: {}
    clusterIntermediateCAs: {}
```



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


selfSigned

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.CertIssuer.SelfSignedCertIssuer](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-certissuer-selfsignedcertissuer) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> issuer</sup>_ <br/> Additional providers such as AWS PCA or Vault can be added in the future.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tsbCerts

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.CertIssuer.TsbCertsSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-certissuer-tsbcertssettings) <br/> When set a TLS certificate will be created to expose TSB APIs.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


clusterIntermediateCAs

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.CertIssuer.ClusterIntermediateCASettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-certissuer-clusterintermediatecasettings) <br/> When set, an intermediate CA for each cluster will be created that Istio in the control plane
will use for assigning TLS certificates to each workload.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ElasticSearchSettings {#tetrateio-api-install-managementplane-v1alpha1-elasticsearchsettings}

Configure an Elasticsearch connection.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  telemetryStore:
    elastic:
      host: elastic
      port: 5678
      protocol: https
      selfSigned: true
      version: 7
```



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


host

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Elasticsearch host address (can be hostname or IP address).

</td>

<td>

string = {<br/>&nbsp;&nbsp;address: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Port Elasticsearch is listening on.

</td>

<td>

int32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


protocol

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.ElasticSearchSettings.Protocol](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-elasticsearchsettings-protocol) <br/> Protocol to communicate with Elasticsearch, defaults to https.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


selfSigned

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Use Self-Signed certificates. The Self-signed CA bundle and key must be in a secret called es-certs.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


version

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> DEPRECATED: Major version of the Elasticsearch cluster.
Currently supported Elasticsearch major versions are `6`, `7`, and `8`.

</td>

<td>

int32 = {<br/>&nbsp;&nbsp;lte: `8`<br/>&nbsp;&nbsp;gte: `6`<br/>}<br/>

</td>
</tr>
    
</table>
  


## JWTSettings {#tetrateio-api-install-managementplane-v1alpha1-jwtsettings}

Configure JWT based token issuance

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  tokenIssuer:
    jwt:
      expiration: 1h
      refreshExpiration: 720h
      tokenPruneInterval: 1h
      issuers:
      - name: https://jwt.tetrate.io
        algorithm: RS256
        signingKey: tls.key
        audiences:
        - tetrate
```



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


issuers

</td>

<td>

List of [tetrateio.api.install.managementplane.v1alpha1.JWTSettings.Issuer](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-jwtsettings-issuer) <br/> Issuers is the list of issuers supported by the JWT token issuance.
By default, the first configured issuer will be used to sign the tokens IAM issues upon successful login, but
additional ones can be configured so that the JWT authentication provider accepts those tokens as valid ones.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


expiration

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Expiration is the duration issued tokens are valid for.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


refreshExpiration

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Refresh Expiration is the duration issued refresh tokens are valid for.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tokenPruneInterval

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Token prune is the interval at which expired tokens pruned.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


signingKeysSecret

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Secret containing the signing keys used for issuing and validating tokens.

If unset will default to the "iam-signing-key" secret generated by the operator.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Issuer {#tetrateio-api-install-managementplane-v1alpha1-jwtsettings-issuer}





  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Name that uniquely identifies the issuer in the system.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


algorithm

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.JWTSettings.Issuer.Algorithm](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-jwtsettings-issuer-algorithm) <br/> Algorithm used by this issuer to sign tokens.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


signingKey

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The name of the file to use as the signing key. This key must be present in the secret
configured in "signing_keys_secret" or equivalent if using Vault.
By default, "signing_keys_secret" is set to "iam-signing-key" generated by the operator.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


audiences

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Audiences supported by this issuer. This is used on token validation. If the issuer defines no
audiences, then the 'aud' claim will not be validated.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## LDAPSettings {#tetrateio-api-install-managementplane-v1alpha1-ldapsettings}

Detail connection and query mappings for LDAP

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  identityProvider:
    ldap:
      host: ldap
      port: 389
      search:
        baseDN: dc=tetrate,dc=io
        timeout: 20s
        recursive: true
      iam:
        matchDN: "cn=%s,ou=People,dc=tetrate,dc=io"
        matchFilter: "(&(objectClass=person)(uid=%s))"
      sync:
        usersFilter: "(objectClass=person)"
        groupsFilter: "(objectClass=groupOfUniqueNames)"
        membershipAttribute: uniqueMember
```



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


host

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> LDAP server host address (can be hostname or IP address)

</td>

<td>

string = {<br/>&nbsp;&nbsp;address: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Port the LDAP server is listening on

</td>

<td>

int32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


disableTLS

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Disable secure connections to the LDAP server.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


debug

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> LDAP connection debug toggle. When enabled it will print LDAP Requests and Responses messages to the log

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


search

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.LDAPSettings.Search](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-ldapsettings-search) <br/> Configure common properties to be used when running queries against the LDAP server.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


iam

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.LDAPSettings.IAM](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-ldapsettings-iam) <br/> Configure how IAM validates credentials against the LDAP server.
The field are not exclusive; if both are configured, a direct match against the DN is attempted first
and the filter based match will be used as a fallback.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


sync

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.LDAPSettings.Sync](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-ldapsettings-sync) <br/> Sync configures how existing users and groups are retrieved from the LDAP server.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### IAM {#tetrateio-api-install-managementplane-v1alpha1-ldapsettings-iam}





  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


matchDN

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Configure how a user can be directly bound to a DN pattern.
If all users can be found with a given pattern, we can bind them directly. Otherwise, a
MatchFilter should be configured to perform a search of the DN for the given user.
In Active Directory the bind operation is directly done using the username (in the user@domain form)
so when connecting to an AD instance this should be set to just: %s.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


matchFilter

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The pattern used to search for a user DN. This will be used when the user DN cannot 
be directly resolved by matching the configured MatchDN.

Here are some example search patterns for common LDAP implementations:
- OpenLDAP: "CN=%s,CN=Users"
- Active Directory: "(&(objectClass=user)(samAccountName=%s))"

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


### Search {#tetrateio-api-install-managementplane-v1alpha1-ldapsettings-search}





  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


baseDN

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The location at which LDAP search operations will start from.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


recursive

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Recursively search the LDAP tree.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


timeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The timeout when querying the LDAP server.
If omitted, the query is bound by the timeout set by the LDAP server.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


pagesize

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Configures paginated search queries for LDAP.
 When this is set to a non-zero value, LDAP queries will run with pagination controls enabled,
 as specified in https://datatracker.ietf.org/doc/html/rfc2696.
 Note that using a paginated search may result in more queries to the LDAP backend and it
 may slow down the overall process to fetch all the results, so it is recommended to be used only
 if the amount of data to be fetched is over the limits the server is willing to accept.
 By default the value is 0, and pagination is disabled.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Sync {#tetrateio-api-install-managementplane-v1alpha1-ldapsettings-sync}





  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


usersFilter

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The LDAP filter that will be used to fetch all the users that are to be synced to TSB.
e.g. "(objectClass=user)"

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


groupsFilter

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The LDAP filter that will be used to fetch all the groups that are to be synced to TSB.
e.g. "(objectClass=group)"

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


membershipAttribute

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The name of the attribute in a Group record returned from LDAP that represents a member of the group.
e.g. "member"

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## OIDCSettings {#tetrateio-api-install-managementplane-v1alpha1-oidcsettings}

Identity provider configuration for OIDC

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  identityProvider:
    oidc:
      clientId: 50076fd0b8f911eb85290242ac130003
      scopes: ['email', 'profile']
      redirectUri: https://example.com/iam/v2/oidc/callback
      providerConfig:
        dynamic:
          configurationUri: https://accounts.google.com/.well-known/openid-configuration
      offlineAccessConfig:
        deviceCodeAuth:
          clientId: 981174759bab4dc49d0072294900eade
```



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


clientId

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The client ID from the OIDC provider's application configuration settings.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


scopes

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Scopes passed to the OIDC provider in the Authentication Request.
Required scope 'openid' is included by default, any additional scopes will be appended in the Authorization Request.
Additional scopes such as 'profile' or 'email' are generally required if user records in TSB can not be identified
with the ID Token 'sub' claim alone.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


redirectUri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The public URI where TSB is accessed. This is the location where the OIDC provider will redirect after
authentication and must be registered with the OIDC provider. TSB requires that the path matches
/iam/v2/oidc/callback. For example, if TSB is accessed via https://example.com, then this setting should be
https://example.com/iam/v2/oidc/callback and the OIDC provider application setting for the Redirect URI
must match this.

</td>

<td>

string = {<br/>&nbsp;&nbsp;uri: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


authorizationParams

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> _OPTIONAL_ <br/> Optional parameters that will be included in the authorization request to the authorization endpoint.
This provides a way to add non standard or optional query parameters to the authorization request.
Required parameters such as "client_id", "scope, "state" and "redirect_uri" will take precedence over any
parameters defined here. In other words, setting any of these parameters here will not have any effect and will
be replaced by other TSB configuration.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


maxExpirationSeconds

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> Optional max expiration time of issued tokens. When greater than 0 this sets an upper bounds on the
token expiration. If not provided or if the value is greater than the token expiration issued by the
OIDC provider then the OIDC provider expiration time takes precedence.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


providerConfig

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.OIDCSettings.ProviderSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-providersettings) <br/> _REQUIRED_ <br/> OIDC provider configuration. Either dynamic or static configuration can be used. When dynamic configuration is set
the TSB operator will configure OIDC settings discovered through the provider's configuration endpoint. If the
provider doesn't have a configuration endpoint you can set the required OIDC settings using static values.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


offlineAccessConfig

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.OIDCSettings.OfflineAccessSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-offlineaccesssettings) <br/> _OPTIONAL_ <br/> Optional OIDC settings specific to offline access. When specified these settings take precedence over
top-level OIDC settings.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### DynamicSettings {#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-dynamicsettings}

Dynamically configures OIDC client settings using values from the OIDC provider's well-known OIDC configuration
endpoint.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


configurationUri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> OIDC provider's well-known OIDC configuration URI. When set TSB will automatically configure the
OIDC client settings for the Authorization Endpoint, Token Endpoint and JWKS URI from the OIDC Provider's
configuration URI.

</td>

<td>

string = {<br/>&nbsp;&nbsp;uri: `true`<br/>}<br/>

</td>
</tr>
    
</table>
  


### OfflineAccessOverrides {#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-offlineaccessoverrides}

OIDC settings that can be used to override top-level settings for offline access.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


clientId

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> The client ID from the OIDC provider's application configuration settings.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


scopes

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Scopes passed to the OIDC provider in the Device Code request
Required scope 'openid' is included by default, any additional scopes will be appended in the Device Code
Authorization request. Additional scopes such as 'profile' or 'email' are generally required if user records in
TSB can not be identified with the ID Token 'sub' claim alone.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


skipClientIdCheck

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> Instructs JWT validation to ignore the 'aud' claim. When set to true, comparisons between the 'aud' claim in the
JWT token and the 'client_id' in the OIDC provider's configuration will be skipped.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


providerConfig

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.OIDCSettings.ProviderSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-providersettings) <br/> _OPTIONAL_ <br/> OIDC provider configuration. Either dynamic or static configuration can be used. When dynamic configuration is set
the TSB operator will configure OIDC settings discovered through the provider's configuration endpoint. If the
provider doesn't have a configuration endpoint you can set the required OIDC settings using static values.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### OfflineAccessSettings {#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-offlineaccesssettings}

Optional OIDC settings specific to offline access. When specified these settings take precedence over
top-level OIDC settings.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


deviceCodeAuth

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.OIDCSettings.OfflineAccessOverrides](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-offlineaccessoverrides) <br/> _OPTIONAL_ <br/> OIDC settings for Device Code Authorization grant used with offline access.
Any settings applied here override top-level OIDC configuration.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tokenExchange

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.OIDCSettings.OfflineAccessOverrides](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-offlineaccessoverrides) <br/> _OPTIONAL_ <br/> OIDC settings for Token Exchange grant used with offline access.
Any settings applied here override top-level OIDC configuration.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### ProviderSettings {#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-providersettings}

OIDC provider's configuration. Either dynamic or static configuration can be used. When dynamic configuration is
set the TSB operator will configure OIDC settings discovered through the provider's configuration endpoint. If the
provider doesn't have a configuration endpoint you can set the required OIDC settings using static values.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


dynamic

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.OIDCSettings.DynamicSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-dynamicsettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> provider_settings</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


static

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.OIDCSettings.StaticSettings](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-staticsettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> provider_settings</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### StaticSettings {#tetrateio-api-install-managementplane-v1alpha1-oidcsettings-staticsettings}

Allows to statically configure OIDC client settings if the OIDC provider doesn't have a configuration endpoint.



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


authorizationEndpoint

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The Authorization Endpoint for the OIDC provider.

</td>

<td>

string = {<br/>&nbsp;&nbsp;uri: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


tokenEndpoint

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The Token Endpoint for the OIDC provider.

</td>

<td>

string = {<br/>&nbsp;&nbsp;uri: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


jwksUri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> jwks_setting</sup>_ <br/> URI for the OIDC provider's JSON Web Key Sets. This can be found in the OIDC provider's configuration response.
The JWKS are used for token verification.

</td>

<td>

string = {<br/>&nbsp;&nbsp;uri: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


jwks

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> jwks_setting</sup>_ <br/> JSON string with the OIDC provider's JSON Web Key Sets. In general the URI for the Key Set is the preferred
method for configuring JWKS. This setting is provided in case the provider doesn't publish JWKS via a
public URI.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


deviceCodeEndpoint

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> The Device Code endpoint for the OIDC provider.
This is optional but required when using the Device Code authentication flow.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


introspectionEndpoint

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> The Introspection endpoint for the OIDC provider.
This is optional and used as an authentication source for the Token Exchange flow.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## PostgresSettings {#tetrateio-api-install-managementplane-v1alpha1-postgressettings}

Detail connection details for Postgres

NOTE: TSB does not make any specific schema selection. It defaults to
the `search_path` set by the user/role specified in the connection settings.
By default this will result in using the `public` schema. If you need to use a different
schema, update the `search_path` of the Postgres user accordingly.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  dataStore:
    postgres:
      address: "postgres:5432"
      sslMode: verify_full
      connectionLifetime: "8500s"
      name: tsb
```



  
<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th class="description">Description</th>
<th>Validation Rule</th>
</tr>
</thead>
    
<tr>
<td>


host

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Deprecated. Use the 'address' field instead.
Postgres host address (can be hostname or IP address).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


port

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Deprecated. Use the 'address' field instead.
Port Postgres is listening on.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


sslMode

</td>

<td>

[tetrateio.api.install.managementplane.v1alpha1.PostgresSettings.SSLMode](../../../install/managementplane/v1alpha1/spec#tetrateio-api-install-managementplane-v1alpha1-postgressettings-sslmode) <br/> For more details about each of these options please refer to https://www.postgresql.org/docs/current/libpq-ssl.html

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


connectionLifetime

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> How long a connection lives before it is killed and recreated. A value of zero means connections
are not closed due to their age.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The name of the database TSB will use in Postgres. The database needs to exist unless TSB is using the
demo installation.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


address

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The address of the database instance. E.g. my-postgres.com:5432

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


connectionIdleLifetime

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> How long an connection lives before it is killed. A value of zero means connections
are not closed due to idle time.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


connectionMaxOpen

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Maximum number of concurrent open connections. Defaults to 0 (unlimited).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


connectionIdleMaxOpen

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Maximum number of concurrent open idle connections. Defaults to 2.
A value of 0 means no idle connections are retained.
If the `connection_max_open` value is set, then this value will be adjusted automatically
in order to always be <= the `connection_max_open.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




### FlavorType {#tetrateio-api-install-managementplane-v1alpha1-managementplanespec-flavortype}

Flavor that's being deployed.
$hide_from_docs


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


TSB

</td>

<td>

0

</td>

<td>

Tetrate Service Bridge (default if unset)

</td>
</tr>
    
<tr>
<td>


TSE

</td>

<td>

1

</td>

<td>

Tetrate Service Express

</td>
</tr>
    
</table>
  



## TLSProtocol {#tetrateio-api-install-managementplane-v1alpha1-tlsprotocol}




<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


TLS_AUTO

</td>

<td>

0

</td>

<td>

Envoy will choose the optimal TLS version.

</td>
</tr>
    
<tr>
<td>


TLSv1_0

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TLSv1_1

</td>

<td>

2

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TLSv1_2

</td>

<td>

3

</td>

<td>



</td>
</tr>
    
<tr>
<td>


TLSv1_3

</td>

<td>

4

</td>

<td>



</td>
</tr>
    
</table>
  



### Protocol {#tetrateio-api-install-managementplane-v1alpha1-elasticsearchsettings-protocol}

The list of supported protocols to communicate with Elasticsearch.


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


https

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


http

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
</table>
  



#### Algorithm {#tetrateio-api-install-managementplane-v1alpha1-jwtsettings-issuer-algorithm}




<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


RS256

</td>

<td>

0

</td>

<td>

RSA / SHA-256

</td>
</tr>
    
<tr>
<td>


RS384

</td>

<td>

1

</td>

<td>

RSA / SHA-384

</td>
</tr>
    
<tr>
<td>


RS512

</td>

<td>

2

</td>

<td>

RSA / SHA-512

</td>
</tr>
    
<tr>
<td>


PS256

</td>

<td>

3

</td>

<td>

RSA-PSS / SHA-256

</td>
</tr>
    
<tr>
<td>


PS384

</td>

<td>

4

</td>

<td>

RSA-PSS / SHA-384

</td>
</tr>
    
<tr>
<td>


PS512

</td>

<td>

5

</td>

<td>

RSA-PSS / SHA-512

</td>
</tr>
    
<tr>
<td>


ES256

</td>

<td>

6

</td>

<td>

ECDSA / SHA-256

</td>
</tr>
    
<tr>
<td>


ES384

</td>

<td>

7

</td>

<td>

ECDSA / SHA-384

</td>
</tr>
    
<tr>
<td>


ES512

</td>

<td>

8

</td>

<td>

ECDSA / SHA-512

</td>
</tr>
    
<tr>
<td>


HS256

</td>

<td>

9

</td>

<td>

HMAC / SHA-256

</td>
</tr>
    
<tr>
<td>


HS384

</td>

<td>

10

</td>

<td>

HMAC / SHA-384

</td>
</tr>
    
<tr>
<td>


HS512

</td>

<td>

11

</td>

<td>

HMAC / SHA-512

</td>
</tr>
    
</table>
  



### SSLMode {#tetrateio-api-install-managementplane-v1alpha1-postgressettings-sslmode}

For more details about each of these options please refer to https://www.postgresql.org/docs/current/libpq-ssl.html


<div class="generated-table"></div>

<table>
<thead>
<tr>
<th>Field</th>
<th>Number</th>
<th class="description">Description</th>
</tr>
</thead>
    
<tr>
<td>


require

</td>

<td>

0

</td>

<td>



</td>
</tr>
    
<tr>
<td>


allow

</td>

<td>

1

</td>

<td>



</td>
</tr>
    
<tr>
<td>


prefer

</td>

<td>

2

</td>

<td>



</td>
</tr>
    
<tr>
<td>


disable

</td>

<td>

3

</td>

<td>



</td>
</tr>
    
<tr>
<td>


verify_ca

</td>

<td>

4

</td>

<td>



</td>
</tr>
    
<tr>
<td>


verify_full

</td>

<td>

5

</td>

<td>



</td>
</tr>
    
</table>
  


