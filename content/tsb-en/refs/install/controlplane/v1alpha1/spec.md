---
title: Control Plane
description: Configuration to describe a TSB control plane installation.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

ControlPlane resource exposes a set of configurations necessary to automatically install
the Service Bridge control plane on a cluster. The installation API is an override API so any
unset fields that aren't required will use sensible defaults.

Prior to creating the ControlPlane resource, a cluster needs to be created in the management plane.
Control plane install scripts would create the following secrets in the Kubernetes namespace the control
plane is deployed into. Make sure they exist:

  - oap-token
  - otel-token

If your Elasticsearch backend requires authentication, ensure you create the following secret:
  - elastic-credentials 

A minimal resource must have the container registry hub, telemetryStore, and managementPlane fields set.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  hub: docker.io/tetrate
  telemetryStore:
    elastic:
      host: elastic
      port: 5678
  managementPlane:
    host: tsb.tetrate.io
    port: 8443
    clusterName: cluster
```

To configure infrastructure specific settings such as resource limits in Kubernetes,
set the relevant field in a component. Remember that the installation API is an
override API so if these fields are unset the operator will use sensible defaults.
Only a subset of Kubernetes configuration is available and only for individual components.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  hub: docker.io/tetrate
  imagePullSecrets:
  - name: my-registry-creds
  telemetryStore:
    elastic:
      host: elastic
      port: 5678
  managementPlane:
    host: tsb.tetrate.io
    port: 8443
    clusterName: cluster
  components:
    collector:
      kubeSpec:
        resources:
          limits:
            memory: 750Mi
          requests:
            memory: 500Mi
```





## ControlPlaneComponentSet {#tetrateio-api-install-controlplane-v1alpha1-controlplanecomponentset}

The set of components that make up the control plane. Use this to override application settings
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


collector

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.OpenTelemetryCollector](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-opentelemetrycollector) <br/> 

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

[tetrateio.api.install.controlplane.v1alpha1.Oap](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-oap) <br/> 

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

[tetrateio.api.install.controlplane.v1alpha1.XCP](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-xcp) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


istio

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.Istio](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-istio) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rateLimitServer

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.RateLimitServer](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-ratelimitserver) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hpaAdapter

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.HpaAdapter](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-hpaadapter) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


onboarding

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.Onboarding](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-onboarding) <br/> Workload Onboarding.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


satellite

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.Satellite](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-satellite) <br/> Satellite provide load balancing capabilities for data content before the data from Envoy reaches the SPM in Control Plane.
When envoy points the address to Satellite, it can load balance the traffic to the SPM service.

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

[tetrateio.api.install.controlplane.v1alpha1.NGAC](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-ngac) <br/> 

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

[tetrateio.api.install.common.GitOps](../../../install/common/common_config#tetrateio-api-install-common-gitops) <br/> Configuration for the integration of the Control Plane with Continuous Deployment pipelines.

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

[tetrateio.api.install.kubernetes.KubernetesSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetesspec) <br/> Configure Kubernetes default settings for all components. These settings
will be merged to all components' settings, only if the component does not
define the same setting. In that case, the setting defined at the component
level prevails over the global default.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


wasmfetcher

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.WASMFetcher](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-wasmfetcher) <br/> Configuration for the WASM Fetcher component.

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
Note that the supported log level for different components can be different.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ControlPlaneSpec {#tetrateio-api-install-controlplane-v1alpha1-controlplanespec}

ControlPlaneSpec defines the desired installed state of control plane components.
Specifying a minimal ControlPlaneSpec with hub, clusterName, and managementPlane set
will create an installation with sensible defaults.



  
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

List of [tetrateio.api.install.kubernetes.LocalObjectReference](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-localobjectreference) <br/> Pull secrets can be specified globally for all components, or defined into the `kubeSpec.serviceAccount`
of every component if needed. In case both are defined, the most specific one (the one defined at the component)
level is used.

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


components

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.ControlPlaneComponentSet](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-controlplanecomponentset) <br/> The set of components that make up the control plane. Use this to override settings for individual components.
These components assume the following secrets are present: oap-token and otel-token.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


providerSettings

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.ProviderSettings](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-providersettings) <br/> Configures Kubernetes provider specific settings.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


managementPlane

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.ManagementPlaneSettings](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-managementplanesettings) <br/> _REQUIRED_ <br/> Configure the management plane to retrieve configuration from.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


meshExpansion

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.MeshExpansionSettings](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings) <br/> Configure mesh expansion to connect workloads external to Kubernetes to the mesh.

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

[tetrateio.api.install.controlplane.v1alpha1.ControlPlaneSpec.TelemetryStore](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-controlplanespec-telemetrystore) <br/> _REQUIRED_ <br/> Configure the store that TSB will use to persist application telemetry data.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


meshObservability

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.ControlPlaneSpec.MeshObservability](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-controlplanespec-meshobservability) <br/> Configure how the mesh should be observed, which observability functionalities should be
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


tier1Cluster

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> DEPRECATED**: This should not be set through Control plane API
Instead use TSB Cluster API.
Indicates that this cluster is used for tier1 gateways.
Tier one clusters can only contain tier 1 gateways.
Non-tier1 clusters contain tier2 gateways but not tier 1.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### MeshObservability {#tetrateio-api-install-controlplane-v1alpha1-controlplanespec-meshobservability}

Configure how the mesh should be observed, which observability functionalities should be
enabled to observe your registered services in the mesh, and the store properties
that TSB will use to persist application observability data like metrics, traces,
logs.
If omitted, the operator will assume
a demo installation and for your convenience install a demo grade mesh observability
setting.
Select one of the `MeshObservability` settings to see complete examples.



  
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


demoSettings

</td>

<td>

[tetrateio.api.install.common.MeshObservabilitySettings](../../../install/common/common_config#tetrateio-api-install-common-meshobservabilitysettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> mesh_observability</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
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
  


### TelemetryStore {#tetrateio-api-install-controlplane-v1alpha1-controlplanespec-telemetrystore}

Configure the store that TSB will use to persist application telemetry data.
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

[tetrateio.api.install.controlplane.v1alpha1.ElasticSearchSettings](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-elasticsearchsettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> telemetry_store</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## HpaAdapter {#tetrateio-api-install-controlplane-v1alpha1-hpaadapter}

Kubernetes settings for the OAP (SkyWalking) HPA adapter component.



  
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
    
</table>
  


## IsolationBoundary {#tetrateio-api-install-controlplane-v1alpha1-isolationboundary}

IsolationBoundary is an isolated Istio environment which can spread across 
multiple revisioned control plane clusters.

Example:

  ```yaml
  isolationBoundaries:
  - name: prod
    revisions:
    - name: stable
      istio:
        tsbVersion: 1.6.0
  - name: staging
    revisions:
    - name: v1_6_3
      istio:
        tsbVersion: 1.6.3
    - name: v1_6_1
      istio:
        tsbVersion: 1.6.1
        disable: true
  ```

The `tsbVersion` field can be left empty, which would then default to the
current TSB released version. 

  ```yaml
  isolationBoundaries:
  - name: global
    istio:
    - revisions: stable
  ```

For instance, if isolation boundaries are being added in TSB `1.6.1`, the default
would looks something like this:

  ```yaml
  isolationBoundaries:
  - name: global
    revisions:
    - name: stable
      istio:
        tsbVersion: 1.6.1
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


name

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the IsolationBoundary.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


revisions

</td>

<td>

List of [tetrateio.api.install.controlplane.v1alpha1.IstioRevision](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-istiorevision) <br/> _REQUIRED_ <br/> Configure multiple Istio Revisions under the IsolationBoundary.
Once IstioIsolationBoundaries is enabled, for any IsolationBoundary
configured - there must be atleast one IstioRevision.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## Istio {#tetrateio-api-install-controlplane-v1alpha1-istio}

Mesh and Kubernetes settings for Istio.



  
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


tsbVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> Specifies the tsb release version. This is used by the tsb control plane
operator in determining the xcp version, which would eventually decide Istio 
version.

If not provided explicitly, this defaults to the current tsb version.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


mountInternalWasmExtensions

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When this flag is set, the TSB internal WASM extensions will be mounted into the
Sidecar, Ingress and Egress gateway pods automatically. These extensions will be loaded
as local files instead of being downloaded from a remote OCI registry or HTTP endpoint.
This is currently disabled by default, but in future releases this flag will be enabled
by default.

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

[tetrateio.api.install.kubernetes.KubernetesIstioComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetesistiocomponentspec) <br/> Configure Kubernetes specific settings.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


traceSamplingRate

</td>

<td>

[double](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The percentage of traces Envoy will sample.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


defaultWorkloadCertTTL

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The default TTL of issued workload certificates.
This sets both the default client-side CSR TTL and the default server-side
issued certificate TTL.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


maxWorkloadCertTTL

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> The maximum TTL that can be set in issued workload certificates.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


trustDomain

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The trust domain corresponds to the trust root of a system. Refer to
[SPIFFE-ID](https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE-ID#21-trust-domain).
If omitted, TSB will configure the trust domain as
`CLUSTER_NAME.tsb.local`, where `CLUSTER_NAME` is the name of the cluster
object in TSB for this control plane.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


baseOverlays

</td>

<td>

List of [istio.operator.v1alpha1.K8sObjectOverlay](../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-k8sobjectoverlay) <br/> The overlays applied to the Istio base component.
See https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#IstioComponentSetSpec.
When this is specified, the overlay in `kubeSpec.overlays` are ignored.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


pilotOverlays

</td>

<td>

List of [istio.operator.v1alpha1.K8sObjectOverlay](../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-k8sobjectoverlay) <br/> The overlays applied to the Istio pilot component.
See https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#IstioComponentSetSpec.
When this is specified, the overlay in `kubeSpec.overlays` are ignored.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


cniOverlays

</td>

<td>

List of [istio.operator.v1alpha1.K8sObjectOverlay](../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-k8sobjectoverlay) <br/> The overlays applied to the Istio CNI component.
See https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#IstioComponentSetSpec.
When this is specified, the overlay in `kubeSpec.overlays` are ignored.

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

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Specifies the global logging level settings for the Istio control plane components.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## IstioRevision {#tetrateio-api-install-controlplane-v1alpha1-istiorevision}

Istio control plane settings for a specific revision.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the IstioRevision. Must be unique at cluster level, across Isolation
Boundaries. The IstioRevision name is used to deploy revisioned Istio control-plane
components.

Notice that the value constraints here are stricter than the ones in Istio.
Apparently, Istio validation rules allow values that lead to internal failures
at runtime, e.g. values with capital letters or values longer than 56 characters.
Stricter validation rules here are meant to prevent those hidden pitfalls.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>&nbsp;&nbsp;max_len: `56`<br/>&nbsp;&nbsp;pattern: `^[a-z0-9](?:[-a-z0-9]*[a-z0-9])?$`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


istio

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.Istio](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-istio) <br/> _REQUIRED_ <br/> Istio overlay configuration for the revision. Revision specific Istio configs
will be overlayed over the common Istio configs configured in the ControlPlaneSpec.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


disable

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _OPTIONAL_ <br/> If set to `true`, Istio control plane deployment with this revision will be 
cleaned up from the cluster. This field can be used to clean up revisioned
control plane deployment while retaining the configurations in the CR. After
cleanup, it can be again set to `false` to re-deploy revisioned control plane.
By default the value is set to `false`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## NGAC {#tetrateio-api-install-controlplane-v1alpha1-ngac}

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

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> NGAC is an experimental component. If enabled is false, this component will
not be installed.

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
  


## Oap {#tetrateio-api-install-controlplane-v1alpha1-oap}

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


streamingLogEnabled

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Feature flag to determine whether on-demand streaming logs should be
enabled.

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

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Feature flag to determine whether on-demand envoy metrics should be
enabled. If enabled, the envoy proxy will provide a set of metrics that can
be queried using the metrics service. OAP will provide a query API that can
be used to collect envoy proxy metrics for specific pods. This is only for
temporary and real-time queries that can be used, for example, for
application troubleshooting use cases. These metrics are not persisted.

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
This feature flag must be set on all clusters and have the same value as the management plane's one,
otherwise control plane observability data could be written to the wrong or not existing index.
In this storage mode, user can adjust each concrete index should have to scale out by setting
`storageSpecificIndexSettings` field in the management plane install manifest.

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
  


## Onboarding {#tetrateio-api-install-controlplane-v1alpha1-onboarding}

Settings for the `Workload Onboarding` component.



  
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


operator

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.OnboardingOperator](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-onboardingoperator) <br/> Configure `Workload Onboarding Operator` component.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


repository

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.OnboardingRepository](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-onboardingrepository) <br/> Configure `Workload Onboarding Repository` component.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


plane

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.OnboardingPlane](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-onboardingplane) <br/> Configure `Workload Onboarding Plane` component.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## OnboardingOperator {#tetrateio-api-install-controlplane-v1alpha1-onboardingoperator}

Kubernetes settings for the `Workload Onboarding Operator` component.



  
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

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings.

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
  


## OnboardingPlane {#tetrateio-api-install-controlplane-v1alpha1-onboardingplane}

Configure `Workload Onboarding Plane` component.



  
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


instance

</td>

<td>

[tetrateio.api.onboarding.config.install.v1alpha1.OnboardingPlaneInstance](../../../onboarding/config/install/v1alpha1/jwt_issuer#tetrateio-api-onboarding-config-install-v1alpha1-onboardingplaneinstance) <br/> Kubernetes settings for the `Workload Onboarding Plane Instance` component.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## OnboardingRepository {#tetrateio-api-install-controlplane-v1alpha1-onboardingrepository}

Kubernetes settings for the `Workload Onboarding Repository` component.



  
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

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## OpenTelemetryCollector {#tetrateio-api-install-controlplane-v1alpha1-opentelemetrycollector}

Kubernetes settings for the OpenTelemetryCollector component.



  
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
  


## RateLimitServer {#tetrateio-api-install-controlplane-v1alpha1-ratelimitserver}

Configuration settings for the RateLimit Server



  
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


backend

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.RateLimitServer.Backend](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-ratelimitserver-backend) <br/> _REQUIRED_ <br/> Configure Database backend settings. This field must be configured by the
user.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


domain

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The domain field allows ratelimits to be namespaced to
a certain domain. To support common ratelimits across multiple clusters
set this string to a common value, across them. This assumes that the same
backend (uri) is being used.
By default the domain is set to the name of the control plane cluster.

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

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Backend {#tetrateio-api-install-controlplane-v1alpha1-ratelimitserver-backend}

External Backend Database types. This points to the backend
used by the ratelimit server as a key/value store.



  
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


redis

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.RateLimitServer.Backend.RedisSettings](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-ratelimitserver-backend-redissettings) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> backend_specifier</sup>_ <br/> Settings for redis database backend.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### RedisSettings {#tetrateio-api-install-controlplane-v1alpha1-ratelimitserver-backend-redissettings}

Configuration for the External Redis Backend Database



  
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


uri

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The Redis Database URI. The value of the URI decides the scope
for ratelimiting across multiple clusters.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_bytes: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## Route53Controller {#tetrateio-api-install-controlplane-v1alpha1-route53controller}

Kubernetes settings for the Route53 Integration Controller component.



  
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

[tetrateio.api.install.kubernetes.KubernetesComponentSpec](../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-kubernetescomponentspec) <br/> Configure Kubernetes specific settings.
*Note*: Route53 controller requires [Service Account for IAM to be created
before installing the controller](https://docs-preview.tetrate.io/service-express/tech-preview/getting-started/publish-service/#prepare-externaldns-integration-1).
Therefore the Service Account will not be managed by this kubeSpec
and all Service Account configuration in this kubeSpec will be ignored.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Satellite {#tetrateio-api-install-controlplane-v1alpha1-satellite}

Kubernetes settings for the Satellite (SkyWalking-Satellite) component.



  
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

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Satellite is an optional component. If enabled is false, this component
will not be installed.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Specifies the log level for the component.
Supported log level: "panic", "fatal", "info", "warn", "error", "debug" and "trace".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## WASMFetcher {#tetrateio-api-install-controlplane-v1alpha1-wasmfetcher}

Settings for the WASM Fetcher component.



  
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


cacheDisableInsecureRegistries

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Denies insecure registries to be used for fetching WASM modules. Defaults to `false`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


cacheExpiration

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> WASM Module cache expiration time. Defaults to `24h`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


cacheMaxRetries

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Maximum number of retries when fetching WASM modules from the OCI registry. Defaults to `5`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


cachePurgeInterval

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> WASM cache purge interval to periodically clean up the stale WASM modules. Defaults to `1h`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


cacheRequestTimeout

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Specifies the timeout used when retrieving the WASM plugin from the OCI registry. Defaults to `15s`.

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
Supported log levels: "none", "error", "info", "debug".

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## XCP {#tetrateio-api-install-controlplane-v1alpha1-xcp}

Kubernetes settings for the XCP component.



  
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


centralAuthMode

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.XCP.CentralAuthMode](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-xcp-centralauthmode) <br/> Authentication mode for connections from XCP Edges to XCP Central.
If not set will default to mutual TLS.

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


isolationBoundaries

</td>

<td>

List of [tetrateio.api.install.controlplane.v1alpha1.IsolationBoundary](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-isolationboundary) <br/> Configures Isolated Istio environments along with Istio revisions for each environment.
IsolationBoundaries can be empty when the feature flag IstioIsolationBoundaries is disabled.
Once enabled, isolation boundaries can be configured.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


enableHttpMeshInternalIdentityPropagation

</td>

<td>

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> Enables HTTP mesh internal service identity propagation across gateway hops, utilizing the propagated identity
for evaluating TSB RBAC rules. Users should enable this feature when they want to create RBAC rules around
request's origin client identity for east west traffic. The most common case for this would be when using
authorization features such as ALLOW/DENY rules mode and ServiceSecuritySettings in cross-cluster environment.
This feature is disabled by default.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


centralProvidedCaCert

</td>

<td>

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> If true, obtain the CA cert for Istio from XCP central.
To enable it, the XCP Central needs to be configured with `certIssuer.clusterIntermediateCASettings: {}`.

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
  


## EKSSettings {#tetrateio-api-install-controlplane-v1alpha1-ekssettings}

Settings specific to Elastic Kubernetes Service (EKS).



  
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


useNlbByDefault

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When true, gateways will be configured to use NLBs with cross zone load
balancing enabled when the load balancer type is not configured. When
false, no additional annotations will be added.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ProviderSettings {#tetrateio-api-install-controlplane-v1alpha1-providersettings}

Configure Kubernetes provider specific settings.

For example to configure EKS to use network load balancers (NLB) by default:

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  providerSettings:
    eks:
      useNlbByDefault: true

```

To configure Route53 the only option that you must specify is the Service Account name to use for IAM role.
You should create the Service Account before enabling the Route53 integration controller. You can do that using `eksctl`. Example:

```bash
   SA_NAME=route53-controller
   CP_NAMESPACE=istio-system
   eksctl create iamserviceaccount \
   --cluster $EKS_CLUSTER_NAME \
   --name $SA_NAME \
   --namespace $CP_NAMESPACE \
   --attach-policy-arn $POLICY_ARN \
   --approve
```

where:
* $EKS_CLUSTER_NAME is the name of the EKS cluster.
* $SA_NAME is the name of the Service Account to create.
* $CP_NAMESPACE is the namespace where the Control Plane is installed. Usually istio-system.
* $POLICY_ARN is the ARN of the policy to attach to the Service Account - the policy should allow the Service Account
  to manage Route53 resources.

More details can be found in the [Publishing a Service docs](https://docs-preview.tetrate.io/service-express/Tech-Preview/getting-started/publish-service)

After creating the Service Account you can enable the Route53 integration controller using the following configuration:

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  providerSettings:
    route53:
      serviceAccountName: $SA_NAME
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


eks

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.EKSSettings](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-ekssettings) <br/> Settings specific to EKS.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


route53

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.Route53Settings](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-route53settings) <br/> Settings specific to Route53.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Route53Settings {#tetrateio-api-install-controlplane-v1alpha1-route53settings}

Settings for integration with Route53 service.



  
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


serviceAccountName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Service account name to use for IAM role. Required.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespaceSelector

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.Route53Settings.NamespaceSelector](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-route53settings-namespaceselector) <br/> Specifies the namespace to watch.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


policy

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.Route53Settings.Policy](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-route53settings-policy) <br/> Specifies the policy to use when managing DNS records. Default: SYNC.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


domainFilter

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> List of domains to limit possible target zones by a domain suffix. Default is empty list with means consider all resources as DNS target.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


interval

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Duration of interval between individual synchronizations. Default: 60s.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ttl

</td>

<td>

[int64](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Default TTL (in seconds) value for DNS records. Default: 300.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


evaluateTargetHealth

</td>

<td>

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> Control whether to evaluate the health of a DNS target. Default: true.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


filterSettings

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.Route53Settings.FilterSettings](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-route53settings-filtersettings) <br/> Filter target settings. It filters out (removes) targets that matches any of the filters. Optional.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### FilterSettings {#tetrateio-api-install-controlplane-v1alpha1-route53settings-filtersettings}

Filter settings for route53 controller.



  
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


annotationFilter

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Filter out (remove) targets that matches annotation using label selector semantics. Optional.
*NOTE*: The annotation value currently cannot be longer thant 63 characters.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


labelFilter

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Filter out (remove) targets that matches label selector. Optional.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


excludeDomain

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Exclude subdomains. Optional.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


zoneType

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.Route53Settings.FilterSettings.AWSZoneType](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-route53settings-filtersettings-awszonetype) <br/> Filter out (removes) zones of this type. Default: none, options: none, public, private.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


zoneTagFilter

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When using the AWS provider, filter for zones with this tag. Optional, format: key=value.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


zoneIdFilter

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> When using the AWS provider, filter for zones with this ID. Optional.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### NamespaceSelector {#tetrateio-api-install-controlplane-v1alpha1-route53settings-namespaceselector}

NamespaceSelector specifies which namespaces controller will watch.



  
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


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> namespace_selector</sup>_ <br/> Specifies the namespace to watch for resources. Mutually exclusive with `ignore_namespaces`.
If not specified (""), all namespaces will be watched which is the default.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ignoreNamespaces

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> namespace_selector</sup>_ <br/> Comma separated list of namespaces to ignore when watching for DNS endpoints. When using this option remember
to include the name of the namespace in which Control Plane is installed. If Management Plane is installed in the same cluster
include the namespace name in this option as well.
Mutually exclusive with `namespace`.
Default: the namespace where the controller is running, usually `istio-system`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ElasticSearchSettings {#tetrateio-api-install-controlplane-v1alpha1-elasticsearchsettings}

Configure an Elasticsearch connection.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
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

[tetrateio.api.install.controlplane.v1alpha1.ElasticSearchSettings.Protocol](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-elasticsearchsettings-protocol) <br/> Protocol to communicate with Elasticsearch, defaults to https.

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
  


## ManagementPlaneSettings {#tetrateio-api-install-controlplane-v1alpha1-managementplanesettings}

Configure the management plane connection.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  managementPlane:
    host: tsb.tetrate.io
    port: 8443
    selfSigned: true
    clusterName: control-plane-cluster
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Management plane host address (can be hostname or IPv4/IPv6 address).

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

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Port management plane is listening on.

</td>

<td>

int32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


selfSigned

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Management plane uses a self signed or private TLS certificate.
If true, the CA bundle used to verify the MP's TLS certificate must be in
a secret `mp-certs` under the key `ca.crt`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


clusterName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> The name of the Cluster object that was created in the Management Plane representing this Control Plane
cluster.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


## MeshExpansionSettings {#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings}

Configure mesh expansion to connect workloads external to Kubernetes to the mesh.

To enable mesh expansion set it to an empty object:

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  meshExpansion: {}
```

If external workloads are unable to communicate with the default mesh expansion gateway via external IPs or hostnames,
then you must specify the gateway that enables them to do so. This custom gateway must be configured to forward this communication
to the VM gateway service:

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  meshExpansion:
    customGateway:
      host: customgateway.tetrate.io
      port: 15443
```

To automate onboarding of workloads from auto-scaling groups of VMs, you need
to enable the `Workload Onboarding Plane`.

`Workload Onboarding Agent`, a component that you install next to the workload,
will connect to the `Workload Onboarding Plane` to authenticate itself, ask
permission to join the mesh, register the workload into the mesh and retrieve
boot configuration required to start `Istio Sidecar`.

All communication between the `Workload Onboarding Agent` and the
`Workload Onboarding Plane` must occur over TLS.

Therefore, to enable `Workload Onboarding Plane` you must provide a TLS
certificate for the endpoint that exposes `Workload Onboarding API` to
`Workload Onboarding Agents`.

Make sure that TLS certificate is signed by the certificate authority known
to `Workload Onboarding Agents`.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  meshExpansion:
    onboarding:
      endpoint:
        hosts:
        - onboarding.example.org
        secretName: onboarding-tls-cert
      tokenIssuer:
        jwt:
          expiration: 1h
      localRepository: {}
```

To onboard workloads from custom on-premise environments, you can leverage support for
[OIDC ID Tokens](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).

If workloads in your custom environment can authenticate themselves by means of an
[OIDC ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDToken),
you can define a list of JWT issuers permitted by the `Workload Onboarding Plane`.

For example,

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  meshExpansion:
    onboarding:
      endpoint:
        hosts:
        - onboarding.example.org
        secretName: onboarding-tls-cert
      localRepository: {}
      workloads:
        authentication:
          jwt:
            issuers:
            - issuer: "https://mycompany.corp"
              jwksUri: "https://mycompany.corp/jwks.json"
              shortName: "mycorp"
              tokenFields:
                attributes:
                  jsonPath: .custom_attributes
```

To ensure there will be no traffic loss when an onboarded workload gets
shutdown, you can configure the time period to delay the shutdown for
after deregistering the workload from the mesh, which will give
enough time to reconfigure all affected mesh nodes to not load balance
requests to the deregistered workload before it becomes unavailable.

For example,

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  meshExpansion:
    onboarding:
      endpoint:
        hosts:
        - onboarding.example.org
        secretName: onboarding-tls-cert
      localRepository: {}
      workloads:
        deregistration:
          propagationDelay: 15s
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


customGateway

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.MeshExpansionSettings.Gateway](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-gateway) <br/> A custom mesh expansion gateway. This is required when the workload can't access the default gateway directly via the external IP or hostname.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


onboarding

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.MeshExpansionSettings.OnboardingPlane](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-onboardingplane) <br/> Configuration of the `Workload Onboarding Plane`.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Gateway {#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-gateway}

A custom mesh expansion gateway. This is required when the workload can't access the default gateway directly via the external IP or hostname.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Mesh expansion gateway host address (can be hostname or IP address).

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

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Port mesh expansion gateway is listening on.

</td>

<td>

int32 = {<br/>&nbsp;&nbsp;lte: `65535`<br/>&nbsp;&nbsp;gte: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


### OnboardingPlane {#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-onboardingplane}

Configuration of the `Workload Onboarding Plane`.



  
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


uid

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Unique identifier of this particular installation of the `Workload Onboarding Plane`.

Is used in the workload authentication flow to prevent replay attacks
that abuse compromised workload credentials intended for a different
installation of the `Workload Onboarding Plane`.

Defaults to an auto-generated UUID.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


endpoint

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.MeshExpansionSettings.OnboardingPlane.Endpoint](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-onboardingplane-endpoint) <br/> _REQUIRED_ <br/> Configuration of the endpoint exposing `Workload Onboarding API` to
`Workload Onboarding Agents`.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


tokenIssuer

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.MeshExpansionSettings.OnboardingPlane.TokenIssuer](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-onboardingplane-tokenissuer) <br/> Configuration of the built-in `Workload Onboarding Token Issuer`.

</td>

<td>

message = {<br/>&nbsp;&nbsp;required: `true`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


localRepository

</td>

<td>

[tetrateio.api.install.controlplane.v1alpha1.MeshExpansionSettings.OnboardingPlane.LocalRepository](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-onboardingplane-localrepository) <br/> Configuration of the local repository with `DEB` and `RPM` packages
of the `Workload Onboarding Agent` and `Istio Sidecar`.

Local repository is disabled by default. To enable it, set this
field to an empty value, i.e. `localRepository: {}`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


workloads

</td>

<td>

[tetrateio.api.onboarding.config.install.v1alpha1.WorkloadConfiguration](../../../onboarding/config/install/v1alpha1/workload_configuration#tetrateio-api-onboarding-config-install-v1alpha1-workloadconfiguration) <br/> Configuration of the workload handling.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


#### Endpoint {#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-onboardingplane-endpoint}

Configuration of the endpoint exposing `Workload Onboarding API` to
`Workload Onboarding Agents`.



  
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


hosts

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> List of hosts included in the TLS certificate.

</td>

<td>

repeated = {<br/>&nbsp;&nbsp;min_items: `1`<br/>&nbsp;&nbsp;items: `{string:{address:true}}`<br/>}<br/>

</td>
</tr>
    
<tr>
<td>


secretName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> _REQUIRED_ <br/> Name of the secret that holds TLS certificate chain and private key.

</td>

<td>

string = {<br/>&nbsp;&nbsp;min_len: `1`<br/>}<br/>

</td>
</tr>
    
</table>
  


#### TokenIssuer {#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-onboardingplane-tokenissuer}

Configuration of the built-in `Workload Onboarding Token Issuer`.



  
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

[tetrateio.api.install.controlplane.v1alpha1.MeshExpansionSettings.OnboardingPlane.TokenIssuer.JwtTokenIssuer](../../../install/controlplane/v1alpha1/spec#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-onboardingplane-tokenissuer-jwttokenissuer) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> token_issuer</sup>_ <br/> Configuration of the built-in JWT Token Issuer.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


##### JwtTokenIssuer {#tetrateio-api-install-controlplane-v1alpha1-meshexpansionsettings-onboardingplane-tokenissuer-jwttokenissuer}

Configuration of the built-in JWT Token Issuer.



  
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


expiration

</td>

<td>

[google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) <br/> Expiration is the duration issued tokens are valid for.
Defaults to `1h`.

</td>

<td>

duration = {<br/>&nbsp;&nbsp;required: `true`<br/>&nbsp;&nbsp;gt: `{nanos:0}`<br/>}<br/>

</td>
</tr>
    
</table>
  




### CentralAuthMode {#tetrateio-api-install-controlplane-v1alpha1-xcp-centralauthmode}

Authentication mode for connections from XCP Edges to XCP Central


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


UNKNOWN

</td>

<td>

0

</td>

<td>

Default when unset, do not use

</td>
</tr>
    
<tr>
<td>


MUTUAL_TLS

</td>

<td>

1

</td>

<td>

GRPC stream is encrypted with mutual TLS

</td>
</tr>
    
<tr>
<td>


JWT

</td>

<td>

2

</td>

<td>

XCP Edges present a JWT bearer token in the GRPC headers

</td>
</tr>
    
</table>
  



#### AWSZoneType {#tetrateio-api-install-controlplane-v1alpha1-route53settings-filtersettings-awszonetype}

AWS Route53 Zone type filters.


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


NONE

</td>

<td>

0

</td>

<td>

No filter.

</td>
</tr>
    
<tr>
<td>


PUBLIC

</td>

<td>

1

</td>

<td>

Filter public zones.

</td>
</tr>
    
<tr>
<td>


PRIVATE

</td>

<td>

2

</td>

<td>

Filter private zones.

</td>
</tr>
    
</table>
  



### Policy {#tetrateio-api-install-controlplane-v1alpha1-route53settings-policy}

Policy that defines how DNS records are managed.


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


SYNC

</td>

<td>

0

</td>

<td>

Allow full synchronization.

</td>
</tr>
    
<tr>
<td>


UPSERT_ONLY

</td>

<td>

1

</td>

<td>

Don&#39;t allow delete DNS records.

</td>
</tr>
    
<tr>
<td>


CREATE_ONLY

</td>

<td>

2

</td>

<td>

Allow only creating DNS records.

</td>
</tr>
    
</table>
  



### Protocol {#tetrateio-api-install-controlplane-v1alpha1-elasticsearchsettings-protocol}

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
  


