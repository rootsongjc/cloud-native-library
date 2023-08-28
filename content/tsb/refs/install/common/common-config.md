---
title: Common Configuration Objects
description: Common TSB configurations shared between TSB components.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Common configuration objects shared by the different install APIs.





## CertManagerSettings {#tetrateio-api-install-common-certmanagersettings}

CertManagerSettings represents the settings used for the cert-manager installation. TSB supports installing and managing
the lifecycle of the cert-manager installation.



  
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


managed

</td>

<td>

[tetrateio.api.install.common.CertManagerSettings.Managed](../../install/common/common_config#tetrateio-api-install-common-certmanagersettings-managed) <br/> Managed specifies whether TSB should manage the lifecycle of cert-manager.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


certManagerSpec

</td>

<td>

[tetrateio.api.install.common.CertManagerSettings.CertManagerSpec](../../install/common/common_config#tetrateio-api-install-common-certmanagersettings-certmanagerspec) <br/> Configure kubernetes specific settings for cert-manager.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


certManagerWebhookSpec

</td>

<td>

[tetrateio.api.install.common.CertManagerSettings.CertManagerWebhookSpec](../../install/common/common_config#tetrateio-api-install-common-certmanagersettings-certmanagerwebhookspec) <br/> Configure kubernetes specific settings for cert-manager-webhook.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


certManagerCaInjector

</td>

<td>

[tetrateio.api.install.common.CertManagerSettings.CertManagerCAInjector](../../install/common/common_config#tetrateio-api-install-common-certmanagersettings-certmanagercainjector) <br/> Configure kubernetes specific settings for cert-manager-cainjector.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


certManagerStartupapicheck

</td>

<td>

[tetrateio.api.install.common.CertManagerSettings.CertManagerStartupAPICheck](../../install/common/common_config#tetrateio-api-install-common-certmanagersettings-certmanagerstartupapicheck) <br/> Configure kubernetes specific settings for cert-manager-startupapicheck.
DEPRECATED. Startup API Check is disabled.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### CertManagerCAInjector {#tetrateio-api-install-common-certmanagersettings-certmanagercainjector}

CertManagerCAInjector represents the settings used for cert-manager CAInjector installation in the clusters.



  
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

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure kubernetes specific settings for cert-manager-cainjector.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### CertManagerSpec {#tetrateio-api-install-common-certmanagersettings-certmanagerspec}

CertManagerSpec represents the settings used for cert-manager controller installation in the clusters.



  
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

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure kubernetes specific settings for cert-manager.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### CertManagerStartupAPICheck {#tetrateio-api-install-common-certmanagersettings-certmanagerstartupapicheck}

CertManagerStartupAPICheck represents the settings used for cert-manager startup API check job installation in the clusters.
DEPRECATED. StartupAPICheck is disabled.



  
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

[tetrateio.api.install.kubernetes.KubernetesJobComponentSpec](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetesjobcomponentspec) <br/> Configure kubernetes specific settings for cert-manager-startupapicheck.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### CertManagerWebhookSpec {#tetrateio-api-install-common-certmanagersettings-certmanagerwebhookspec}

CertManagerWebhookSpec represents the settings used for cert-manager Webhook installation in the clusters.



  
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

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure kubernetes specific settings for cert-manager-webhook.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ConfigProtection {#tetrateio-api-install-common-configprotection}

ConfigProtection contains settings for enabling/disabling config protection
over XCP created resources.
Config protections are disabled by default.
Example:
```yaml
configProtection:
  enableAuthorizedUpdateDeleteOnXcpConfigs: true
  enableAuthorizedCreateUpdateDeleteOnXcpConfigs: true
  authorizedUsers:
    - user1
    - system:serviceaccount:ns1:serviceaccount-1
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


enableAuthorizedUpdateDeleteOnXcpConfigs

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When enabled, no other user or svc account except AuthorizedUsers would be allowed to delete or update
the XCP/Istio API resources created by XCP.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


enableAuthorizedCreateUpdateDeleteOnXcpConfigs

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When enabled, no other user or svc account except AuthorizedUsers would be allowed to create, delete or update
the XCP/Istio API resources. This acts as a superset of the enableAuthorizedUpdateDeleteOnXcpConfigs.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


authorizedUsers

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of usernames of authorized users or svc accounts to create/update/delete XCP configs when config protection is enabled.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## CustomCertProviderSettings {#tetrateio-api-install-common-customcertprovidersettings}

CustomCertProviderSettings represents the settings used for the custom certificate provider. Users can configure the CSR signer
required for certificate signing and point to the CA bundle to be used to validate the certificates.



  
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


csrSignerName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of Kubernetes CSR signer to be used to sign the CSR request by different TSB components for internal purposes.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


caBundleSecretName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Configure the CABundleSecretName to be used to verify the signed CSR request by different TSB components. If not specified,
TSB would use the secret with the name ca-bundle-management-plane in the management plane namespace or ca-bundle-control-plane
in the control plane namespace. The secret should contain the file ca.crt with the cert data.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## GitOps {#tetrateio-api-install-common-gitops}

The GitOps component configures the features that allow integrating the Management Plane and/or the
Control Plane cluster with Continuous Deployment pipelines.



  
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

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The GitOps component is in beta and disabled by default.
If Management and Control Planes are installed in the same cluster, Continuous Deployment Integration
should only be enabled in one of both planes. However, if the GitOps component is enabled in both planes,
only the Control Plane GitOps component will remain enabled. The Management Plane GitOps component
will not be enabled, even though it is explicitly enabled.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


reconcileInterval

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Interval at which the reconcile process will run.
The reconcile process will read all TSB CRs that exist in the cluster and
reapply them to the management plane, to make sure the cluster CRs remain
as the source of truth. Format: 1h/1m/1s/1ms. A value of 0 disables the
reconcile loop. Default: 10m.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


batchWindow

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> When configured, all admission requests will be paused for the configured duration.
Once the window interval is closed, all paused admission requests will be sent together
to the Management Plane as a single request.
Batching of requests is disabled by default and should be enabled only if there is high concurrency
and ordering of resources could be an issue. By configuring a batch window the concurrency
and ordering issues may be mitigated, although it will introduce a constant latency to all requests
of the configured time window.
When enabled, it is recommended to use a small value, for example 1 second.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


managementplaneRequestTimeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The GitOps component performs operations against the management plane through the k8s webhook.
This allows configuring the duration of each operation in order to fail early if it takes too much.
This value cannot be lower than `webhook_timeout` due to the request being tied to the ones received
by the k8s webhook.
Format: 1h/1m/1s/1m. Any value <= 0 will be reset to the default value. Default: 25s.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


reconcileRequestTimeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The GitOps component performs operations against the management plane internal reconcile loop.
This allows configuring the duration of each operation to fail early if it takes too long.
Format: 1h/1m/1s/1m. Any value <= 0 will be reset to the default value. Default: 2m.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


webhookTimeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Timeout that will be set in the k8s gitops webhook resource.
Format: 1h/1m/1s/1m. Default: 30s. Allowed values must be between 0s and 30s.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## InternalCertProvider {#tetrateio-api-install-common-internalcertprovider}

InternalCertProvider describes the certificate provider configuration for TSB internal purposes like kubernetes webhook certificate. TSB supports cert-manager out of the box.



  
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


certManager

</td>

<td>

[tetrateio.api.install.common.CertManagerSettings](../../install/common/common_config#tetrateio-api-install-common-certmanagersettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> internal_cert_provider</sup>_ <br/> Use cert-manager as the internal certificate provider

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


custom

</td>

<td>

[tetrateio.api.install.common.CustomCertProviderSettings](../../install/common/common_config#tetrateio-api-install-common-customcertprovidersettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> internal_cert_provider</sup>_ <br/> Use a custom certificate provider that accepts Kubernetes CSR

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## MeshObservabilitySettings {#tetrateio-api-install-common-meshobservabilitysettings}

Configure mesh observability.
The following examples enable the analysis and generation of RED metrics for each
endpoint of your registered services.

Notice that both, ManagementPlane and ControlPlane, need to be aligned with this configuration.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  meshObservability:
    settings:
      apiEndpointMetricsEnabled: true
```

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  meshObservability:
    settings:
      apiEndpointMetricsEnabled: true
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


apiEndpointMetricsEnabled

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Toggle to process, analyze, and generate api endpoints RED metrics.
By default `false` which means disabled.
If you want to analyze all your request and generate RED metrics for
each endpoint of your registered services in the mesh, set it to `true`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




### Managed {#tetrateio-api-install-common-certmanagersettings-managed}

If INTERNAL, TSB will install and manage cert-manager. In case a pre-existing installation is found, the operator will not install cert-manager and fail.
If EXTERNAL, TSB would rely on a pre installed cert-manager for use.
Pre installed cert-manager should support signing requests raised through Kubernetes CSR


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


AUTO

</td>

<td>

0

</td>

<td>

TSB will check if a pre-existing cert-manager installation is found in the cluster and only
install and manage cert-manager if it is not found.
The pre-installed cert-manager should support signing requests raised through Kubernetes CSR

</td>
</tr>
    
<tr>
<td>


EXTERNAL

</td>

<td>

1

</td>

<td>

EXTERNAL represents that TSB will rely on a pre installed cert-manager for use.
Pre installed cert-manager should support signing requests raised through Kubernetes CSR

</td>
</tr>
    
<tr>
<td>


INTERNAL

</td>

<td>

2

</td>

<td>

INTERNAL represents that TSB will install and manage cert-manager in the cluster.
In case a pre-existing installation is found, the operator will not install cert-manager and fail.

</td>
</tr>
    
</table>
  


