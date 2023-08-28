---
title: IstioOperator Options
description: Configuration affecting Istio control plane installation version and shape.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

Configuration affecting Istio control plane installation version and shape.
Note: unlike other Istio protos, field names must use camelCase. This is asserted in tests.
Without camelCase, the `json` tag on the Go struct will not match the user's JSON representation.
This leads to Kubernetes merge libraries, which rely on this tag, to fail.
All other usages use jsonpb which does not use the `json` tag.





## istio.operator.v1alpha1.Affinity {#istio-operator-v1alpha1-affinity}

See k8s.io.api.core.v1.Affinity.



  
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


nodeAffinity

</td>

<td>

[istio.operator.v1alpha1.NodeAffinity](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-nodeaffinity) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


podAffinity

</td>

<td>

[istio.operator.v1alpha1.PodAffinity](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-podaffinity) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


podAntiAffinity

</td>

<td>

[istio.operator.v1alpha1.PodAntiAffinity](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-podantiaffinity) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.BaseComponentSpec {#istio-operator-v1alpha1-basecomponentspec}

Configuration for base component.



  
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

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> Selects whether this component is installed.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


k8s

</td>

<td>

[istio.operator.v1alpha1.KubernetesResourcesSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-kubernetesresourcesspec) <br/> Kubernetes resource spec.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ClientIPConfig {#istio-operator-v1alpha1-clientipconfig}

See k8s.io.api.core.v1.ClientIPConfig.



  
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


timeoutSeconds

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ComponentSpec {#istio-operator-v1alpha1-componentspec}

Configuration for internal components.



  
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

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> Selects whether this component is installed.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Namespace for the component.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hub

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Hub for the component (overrides top level hub setting).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tag

</td>

<td>

[google.protobuf.Value](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Value) <br/> Tag for the component (overrides top level tag setting).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


spec

</td>

<td>

[google.protobuf.Struct](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Struct) <br/> Arbitrary install time configuration for the component.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


k8s

</td>

<td>

[istio.operator.v1alpha1.KubernetesResourcesSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-kubernetesresourcesspec) <br/> Kubernetes resource spec.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ConfigMapKeySelector {#istio-operator-v1alpha1-configmapkeyselector}

See k8s.io.api.core.v1.ConfigMapKeySelector.



  
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


localObjectReference

</td>

<td>

[istio.operator.v1alpha1.LocalObjectReference](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-localobjectreference) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


key

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


optional

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ContainerResourceMetricSource {#istio-operator-v1alpha1-containerresourcemetricsource}

See k8s.io.api.autoscaling.v2beta2.ContainerResourceMetricSource.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


target

</td>

<td>

[istio.operator.v1alpha1.MetricTarget](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metrictarget) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


container

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ContainerResourceMetricStatus {#istio-operator-v1alpha1-containerresourcemetricstatus}

See k8s.io.api.autoscaling.v2beta2.ContainerResourceMetricStatus.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


current

</td>

<td>

[istio.operator.v1alpha1.MetricValueStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricvaluestatus) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


container

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.CrossVersionObjectReference {#istio-operator-v1alpha1-crossversionobjectreference}

See k8s.io.api.autoscaling.v2beta2.CrossVersionObjectReference.



  
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


kind

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


apiVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.DeploymentStrategy {#istio-operator-v1alpha1-deploymentstrategy}

See k8s.io.api.apps.v1.DeploymentStrategy.



  
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


type

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


rollingUpdate

</td>

<td>

[istio.operator.v1alpha1.RollingUpdateDeployment](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-rollingupdatedeployment) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.EnvVar {#istio-operator-v1alpha1-envvar}

See k8s.io.api.core.v1.EnvVar.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


valueFrom

</td>

<td>

[istio.operator.v1alpha1.EnvVarSource](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-envvarsource) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.EnvVarSource {#istio-operator-v1alpha1-envvarsource}

See k8s.io.api.core.v1.EnvVarSource.



  
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


fieldRef

</td>

<td>

[istio.operator.v1alpha1.ObjectFieldSelector](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-objectfieldselector) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


resourceFieldRef

</td>

<td>

[istio.operator.v1alpha1.ResourceFieldSelector](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-resourcefieldselector) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


configMapKeyRef

</td>

<td>

[istio.operator.v1alpha1.ConfigMapKeySelector](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-configmapkeyselector) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


secretKeyRef

</td>

<td>

[istio.operator.v1alpha1.SecretKeySelector](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-secretkeyselector) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ExecAction {#istio-operator-v1alpha1-execaction}

See k8s.io.api.core.v1.ExecAction.



  
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


command

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ExternalComponentSpec {#istio-operator-v1alpha1-externalcomponentspec}

Configuration for external components.



  
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

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> Selects whether this component is installed.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Namespace for the component.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


spec

</td>

<td>

[google.protobuf.Struct](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Struct) <br/> Arbitrary install time configuration for the component.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


chartPath

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Chart path for addon components.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


schema

</td>

<td>

[google.protobuf.Any](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Any) <br/> Optional schema to validate spec against.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


k8s

</td>

<td>

[istio.operator.v1alpha1.KubernetesResourcesSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-kubernetesresourcesspec) <br/> Kubernetes resource spec.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ExternalMetricSource {#istio-operator-v1alpha1-externalmetricsource}

See k8s.io.api.autoscaling.v2beta2.ExternalMetricSource.



  
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


metricName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


metricSelector

</td>

<td>

[k8s.io.apimachinery.pkg.apis.meta.v1.LabelSelector](#) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


targetValue

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


targetAverageValue

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


metric

</td>

<td>

[istio.operator.v1alpha1.MetricIdentifier](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricidentifier) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


target

</td>

<td>

[istio.operator.v1alpha1.MetricTarget](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metrictarget) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ExternalMetricStatus {#istio-operator-v1alpha1-externalmetricstatus}

See k8s.io.autoscaling.v2beta2.ExternalMetricStatus.



  
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


metric

</td>

<td>

[istio.operator.v1alpha1.MetricIdentifier](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricidentifier) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


current

</td>

<td>

[istio.operator.v1alpha1.MetricValueStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricvaluestatus) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.GatewaySpec {#istio-operator-v1alpha1-gatewayspec}

Configuration for gateways.



  
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

[google.protobuf.BoolValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.BoolValue) <br/> Selects whether this gateway is installed.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Namespace for the gateway.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Name for the gateway.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


label

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Labels for the gateway.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hub

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Hub for the component (overrides top level hub setting).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tag

</td>

<td>

[google.protobuf.Value](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Value) <br/> Tag for the component (overrides top level tag setting).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


k8s

</td>

<td>

[istio.operator.v1alpha1.KubernetesResourcesSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-kubernetesresourcesspec) <br/> Kubernetes resource spec.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.HPAScalingPolicy {#istio-operator-v1alpha1-hpascalingpolicy}

See k8s.io.autoscaling.v2beta2.HPAScalingPolicy.



  
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


type

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


periodSeconds

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.HPAScalingRules {#istio-operator-v1alpha1-hpascalingrules}

See k8s.io.autoscaling.v2beta2.HPAScalingRules.



  
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


stabilizationWindowSeconds

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


selectPolicy

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


policies

</td>

<td>

[istio.operator.v1alpha1.HPAScalingPolicy](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-hpascalingpolicy) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.HTTPGetAction {#istio-operator-v1alpha1-httpgetaction}

See k8s.io.api.core.v1.HTTPGetAction.



  
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


path

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

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

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


host

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


scheme

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


httpHeaders

</td>

<td>

List of [istio.operator.v1alpha1.HTTPHeader](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-httpheader) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.HTTPHeader {#istio-operator-v1alpha1-httpheader}

See k8s.io.api.core.v1.HTTPHeader.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.HorizontalPodAutoScalerBehavior {#istio-operator-v1alpha1-horizontalpodautoscalerbehavior}

See k8s.io.autoscaling.v2beta2.HorizontalPodAutoScalerBehavior.



  
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


scaleUp

</td>

<td>

[istio.operator.v1alpha1.HPAScalingRules](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-hpascalingrules) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


scaleDown

</td>

<td>

[istio.operator.v1alpha1.HPAScalingRules](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-hpascalingrules) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.HorizontalPodAutoscalerSpec {#istio-operator-v1alpha1-horizontalpodautoscalerspec}

See k8s.io.api.autoscaling.v2beta1.HorizontalPodAutoscalerSpec.



  
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


scaleTargetRef

</td>

<td>

[istio.operator.v1alpha1.CrossVersionObjectReference](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-crossversionobjectreference) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


minReplicas

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


maxReplicas

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


metrics

</td>

<td>

List of [istio.operator.v1alpha1.MetricSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricspec) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


behavior

</td>

<td>

[istio.operator.v1alpha1.HorizontalPodAutoScalerBehavior](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-horizontalpodautoscalerbehavior) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.InstallStatus {#istio-operator-v1alpha1-installstatus}

Observed state of IstioOperator



  
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


status

</td>

<td>

[istio.operator.v1alpha1.InstallStatus.Status](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-installstatus-status) <br/> Overall status of all components controlled by the operator.

* If all components have status `NONE`, overall status is `NONE`.
* If all components are `HEALTHY`, overall status is `HEALTHY`.
* If one or more components are `RECONCILING` and others are `HEALTHY`, overall status is `RECONCILING`.
* If one or more components are `UPDATING` and others are `HEALTHY`, overall status is `UPDATING`.
* If components are a mix of `RECONCILING`, `UPDATING` and `HEALTHY`, overall status is `UPDATING`.
* If any component is in `ERROR` state, overall status is `ERROR`.
* If further action is needed for reconciliation to proceed, overall status is `ACTION_REQUIRED`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


message

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Optional message providing additional information about the existing overall status.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


componentStatus

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [istio.operator.v1alpha1.InstallStatus.VersionStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-installstatus-versionstatus)> <br/> Individual status of each component controlled by the operator. The map key is the name of the component.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.InstallStatus.VersionStatus {#istio-operator-v1alpha1-installstatus-versionstatus}

VersionStatus is the status and version of a component.



  
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


version

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


status

</td>

<td>

[istio.operator.v1alpha1.InstallStatus.Status](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-installstatus-status) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


error

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.IntOrString {#istio-operator-v1alpha1-intorstring}

IntOrString is a type that can hold an int32 or a string.  When used in
JSON or YAML marshalling and unmarshalling, it produces or consumes the
inner type.  This allows you to have, for example, a JSON field that can
accept a name or number.



  
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


type

</td>

<td>

[int64](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


intVal

</td>

<td>

[google.protobuf.Int32Value](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Int32Value) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


strVal

</td>

<td>

[google.protobuf.StringValue](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.StringValue) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.IstioComponentSetSpec {#istio-operator-v1alpha1-istiocomponentsetspec}

IstioComponentSpec defines the desired installed state of Istio components.



  
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


base

</td>

<td>

[istio.operator.v1alpha1.BaseComponentSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-basecomponentspec) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


pilot

</td>

<td>

[istio.operator.v1alpha1.ComponentSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-componentspec) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


cni

</td>

<td>

[istio.operator.v1alpha1.ComponentSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-componentspec) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


istiodRemote

</td>

<td>

[istio.operator.v1alpha1.ComponentSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-componentspec) <br/> Remote cluster using an external control plane.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ingressGateways

</td>

<td>

List of [istio.operator.v1alpha1.GatewaySpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-gatewayspec) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


egressGateways

</td>

<td>

List of [istio.operator.v1alpha1.GatewaySpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-gatewayspec) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.IstioOperatorSpec {#istio-operator-v1alpha1-istiooperatorspec}

IstioOperatorSpec defines the desired installed state of Istio components.
The spec is a used to define a customization of the default profile values that are supplied with each Istio release.
Because the spec is a customization API, specifying an empty IstioOperatorSpec results in a default Istio
component values.

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: default
  hub: gcr.io/istio-testing
  tag: latest
  revision: 1-8-0
  meshConfig:
    accessLogFile: /dev/stdout
    enableTracing: true
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: true
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


profile

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Path or name for the profile e.g.

* minimal (looks in profiles dir for a file called minimal.yaml)
* /tmp/istio/install/values/custom/custom-install.yaml (local file path)

default profile is used if this field is unset.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


installPackagePath

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Path for the install package. e.g.

* /tmp/istio-installer/nightly (local file path)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hub

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Root for docker image paths e.g. `docker.io/istio`

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tag

</td>

<td>

[google.protobuf.Value](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Value) <br/> Version tag for docker images e.g. `1.7.2`

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Namespace to install control plane resources into. If unset, Istio will be installed into the same namespace
as the `IstioOperator` CR. You must also set `values.global.istioNamespace` if you wish to install Istio in
a custom namespace.
If you have enabled CNI, you must  exclude this namespace by adding it to the list `values.cni.excludeNamespaces`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


revision

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Identify the revision this installation is associated with.
This option is currently experimental.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


defaultRevision

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Identify whether this revision is the default revision for the cluster
This option is currently experimental.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


meshConfig

</td>

<td>

[google.protobuf.Struct](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Struct) <br/> Config used by control plane components internally.

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

[istio.operator.v1alpha1.IstioComponentSetSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-istiocomponentsetspec) <br/> Kubernetes resource settings, enablement and component-specific settings that are not internal to the
component.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


addonComponents

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [istio.operator.v1alpha1.ExternalComponentSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-externalcomponentspec)> <br/> Deprecated.
Users should manage the installation of addon components on their own.
Refer to samples/addons for demo installation of addon components.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


values

</td>

<td>

[google.protobuf.Struct](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Struct) <br/> Overrides for default `values.yaml`. This is a validated pass-through to Helm templates.
See the [Helm installation options](https://istio.io/v1.5/docs/reference/config/installation-options/) for schema details.
Anything that is available in `IstioOperatorSpec` should be set above rather than using the passthrough. This
includes Kubernetes resource settings for components in `KubernetesResourcesSpec`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


unvalidatedValues

</td>

<td>

[google.protobuf.Struct](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Struct) <br/> Unvalidated overrides for default `values.yaml`. Used for custom templates where new parameters are added.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.K8sObjectOverlay {#istio-operator-v1alpha1-k8sobjectoverlay}

Patch for an existing k8s resource.



  
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


apiVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Resource API version.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


kind

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Resource kind.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Name of resource.
Namespace is always the component namespace.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


patches

</td>

<td>

List of [istio.operator.v1alpha1.K8sObjectOverlay.PathValue](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-k8sobjectoverlay-pathvalue) <br/> List of patches to apply to resource.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.K8sObjectOverlay.PathValue {#istio-operator-v1alpha1-k8sobjectoverlay-pathvalue}





  
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


path

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Path of the form a.[key1:value1].b.[:value2]
Where [key1:value1] is a selector for a key-value pair to identify a list element and [:value] is a value
selector to identify a list element in a leaf list.
All path intermediate nodes must exist.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[google.protobuf.Value](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Value) <br/> Value to add, delete or replace.
For add, the path should be a new leaf.
For delete, value should be unset.
For replace, path should reference an existing node.
All values are strings but are converted into appropriate type based on schema.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.KubernetesResourcesSpec {#istio-operator-v1alpha1-kubernetesresourcesspec}

KubernetesResourcesConfig is a common set of k8s resource configs for components.



  
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


affinity

</td>

<td>

[istio.operator.v1alpha1.Affinity](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-affinity) <br/> k8s affinity.
[https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


env

</td>

<td>

List of [istio.operator.v1alpha1.EnvVar](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-envvar) <br/> Deployment environment variables.
[https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hpaSpec

</td>

<td>

[istio.operator.v1alpha1.HorizontalPodAutoscalerSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-horizontalpodautoscalerspec) <br/> k8s HorizontalPodAutoscaler settings.
[https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


imagePullPolicy

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> k8s imagePullPolicy.
[https://kubernetes.io/docs/concepts/containers/images/](https://kubernetes.io/docs/concepts/containers/images/)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


nodeSelector

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> k8s nodeSelector.
[https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


podDisruptionBudget

</td>

<td>

[istio.operator.v1alpha1.PodDisruptionBudgetSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-poddisruptionbudgetspec) <br/> k8s PodDisruptionBudget settings.
[https://kubernetes.io/docs/concepts/workloads/pods/disruptions/#how-disruption-budgets-work](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/#how-disruption-budgets-work)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


podAnnotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> k8s pod annotations.
[https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


priorityClassName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> k8s priority_class_name. Default for all resources unless overridden.
[https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


readinessProbe

</td>

<td>

[istio.operator.v1alpha1.ReadinessProbe](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-readinessprobe) <br/> k8s readinessProbe settings.
[https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
k8s.io.api.core.v1.Probe readiness_probe = 9;

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


replicaCount

</td>

<td>

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> k8s Deployment replicas setting.
[https://kubernetes.io/docs/concepts/workloads/controllers/deployment/](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


resources

</td>

<td>

[istio.operator.v1alpha1.Resources](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-resources) <br/> k8s resources settings.
[https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


service

</td>

<td>

[istio.operator.v1alpha1.ServiceSpec](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-servicespec) <br/> k8s Service settings.
[https://kubernetes.io/docs/concepts/services-networking/service/](https://kubernetes.io/docs/concepts/services-networking/service/)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


strategy

</td>

<td>

[istio.operator.v1alpha1.DeploymentStrategy](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-deploymentstrategy) <br/> k8s deployment strategy.
[https://kubernetes.io/docs/concepts/workloads/controllers/deployment/](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tolerations

</td>

<td>

List of [istio.operator.v1alpha1.Toleration](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-toleration) <br/> k8s toleration
[https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceAnnotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> k8s service annotations.
[https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


securityContext

</td>

<td>

[istio.operator.v1alpha1.PodSecurityContext](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-podsecuritycontext) <br/> k8s pod security context
[https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


volumes

</td>

<td>

List of [k8s.io.api.core.v1.Volume](#) <br/> k8s volume
[https://kubernetes.io/docs/concepts/storage/volumes/](https://kubernetes.io/docs/concepts/storage/volumes/)
Volumes defines the collection of Volume to inject into the pod.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


volumeMounts

</td>

<td>

List of [k8s.io.api.core.v1.VolumeMount](#) <br/> k8s volumeMounts
VolumeMounts defines the collection of VolumeMount to inject into containers.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


overlays

</td>

<td>

List of [istio.operator.v1alpha1.K8sObjectOverlay](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-k8sobjectoverlay) <br/> Overlays for k8s resources in rendered manifests.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.LocalObjectReference {#istio-operator-v1alpha1-localobjectreference}

See k8s.io.api.core.v1.LocalObjectReference.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.MetricIdentifier {#istio-operator-v1alpha1-metricidentifier}

See k8s.io.autoscaling.v2beta2.MetricIdentifier.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _name</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


selector

</td>

<td>

[k8s.io.apimachinery.pkg.apis.meta.v1.LabelSelector](#) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.MetricSpec {#istio-operator-v1alpha1-metricspec}

See k8s.io.autoscaling.v2beta2.MetricSpec.



  
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


type

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


object

</td>

<td>

[istio.operator.v1alpha1.ObjectMetricSource](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-objectmetricsource) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


pods

</td>

<td>

[istio.operator.v1alpha1.PodsMetricSource](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-podsmetricsource) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


resource

</td>

<td>

[istio.operator.v1alpha1.ResourceMetricSource](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-resourcemetricsource) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


containerResource

</td>

<td>

[istio.operator.v1alpha1.ContainerResourceMetricSource](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-containerresourcemetricsource) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


external

</td>

<td>

[istio.operator.v1alpha1.ExternalMetricSource](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-externalmetricsource) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.MetricStatus {#istio-operator-v1alpha1-metricstatus}

See k8s.io.autoscaling.v2beta2.MetricStatus.



  
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


type

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


object

</td>

<td>

[istio.operator.v1alpha1.ObjectMetricStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-objectmetricstatus) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


pods

</td>

<td>

[istio.operator.v1alpha1.PodsMetricStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-podsmetricstatus) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


resource

</td>

<td>

[istio.operator.v1alpha1.ResourceMetricStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-resourcemetricstatus) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


containerResource

</td>

<td>

[istio.operator.v1alpha1.ContainerResourceMetricStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-containerresourcemetricstatus) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


external

</td>

<td>

[istio.operator.v1alpha1.ExternalMetricStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-externalmetricstatus) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.MetricTarget {#istio-operator-v1alpha1-metrictarget}

See k8s.io.autoscaling.v2beta2.MetricTarget.



  
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


type

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


averageValue

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


averageUtilization

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.MetricValueStatus {#istio-operator-v1alpha1-metricvaluestatus}

See k8s.io.autoscaling.v2beta2.MetricValueStatus.



  
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


value

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


averageValue

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


averageUtilization

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.NodeAffinity {#istio-operator-v1alpha1-nodeaffinity}

See k8s.io.api.core.v1.NodeAffinity.



  
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


requiredDuringSchedulingIgnoredDuringExecution

</td>

<td>

[istio.operator.v1alpha1.NodeSelector](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-nodeselector) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


preferredDuringSchedulingIgnoredDuringExecution

</td>

<td>

List of [istio.operator.v1alpha1.PreferredSchedulingTerm](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-preferredschedulingterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.NodeSelector {#istio-operator-v1alpha1-nodeselector}

See k8s.io.api.core.v1.NodeSelector.



  
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


nodeSelectorTerms

</td>

<td>

List of [istio.operator.v1alpha1.NodeSelectorTerm](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-nodeselectorterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.NodeSelectorRequirement {#istio-operator-v1alpha1-nodeselectorrequirement}

See k8s.io.api.core.v1.NodeSelectorRequirement.



  
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


key

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


operator

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


values

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.NodeSelectorTerm {#istio-operator-v1alpha1-nodeselectorterm}

See k8s.io.api.core.v1.NodeSelectorTerm.



  
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


matchExpressions

</td>

<td>

List of [istio.operator.v1alpha1.NodeSelectorRequirement](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-nodeselectorrequirement) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


matchFields

</td>

<td>

List of [istio.operator.v1alpha1.NodeSelectorRequirement](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-nodeselectorrequirement) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ObjectFieldSelector {#istio-operator-v1alpha1-objectfieldselector}

See k8s.io.api.core.v1.ObjectFieldSelector.



  
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


apiVersion

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


fieldPath

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ObjectMeta {#istio-operator-v1alpha1-objectmeta}

From k8s.io.apimachinery.pkg.apis.meta.v1.ObjectMeta.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespace

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ObjectMetricSource {#istio-operator-v1alpha1-objectmetricsource}

See k8s.io.autoscaling.v2beta2.ObjectMetricSource.



  
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


metricName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


targetValue

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


selector

</td>

<td>

[k8s.io.apimachinery.pkg.apis.meta.v1.LabelSelector](#) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


averageValue

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


target

</td>

<td>

[google.protobuf.Value](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Value) <br/> Type changes from CrossVersionObjectReference to ResourceMetricTarget in autoscaling v2beta2/v2 compared with v2beta1
Change it to dynamic type to keep backward compatible

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


describedObject

</td>

<td>

[istio.operator.v1alpha1.CrossVersionObjectReference](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-crossversionobjectreference) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


metric

</td>

<td>

[istio.operator.v1alpha1.MetricIdentifier](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricidentifier) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ObjectMetricStatus {#istio-operator-v1alpha1-objectmetricstatus}

See k8s.io.autoscaling.v2beta2.ObjectMetricStatus.



  
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


metric

</td>

<td>

[istio.operator.v1alpha1.MetricIdentifier](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricidentifier) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


current

</td>

<td>

[istio.operator.v1alpha1.MetricValueStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricvaluestatus) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


describedObject

</td>

<td>

[istio.operator.v1alpha1.CrossVersionObjectReference](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-crossversionobjectreference) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.PodAffinity {#istio-operator-v1alpha1-podaffinity}

See k8s.io.api.core.v1.PodAffinity.



  
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


requiredDuringSchedulingIgnoredDuringExecution

</td>

<td>

List of [istio.operator.v1alpha1.PodAffinityTerm](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-podaffinityterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


preferredDuringSchedulingIgnoredDuringExecution

</td>

<td>

List of [istio.operator.v1alpha1.WeightedPodAffinityTerm](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-weightedpodaffinityterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.PodAffinityTerm {#istio-operator-v1alpha1-podaffinityterm}

See k8s.io.api.core.v1.PodAntiAffinity.



  
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


labelSelector

</td>

<td>

[k8s.io.apimachinery.pkg.apis.meta.v1.LabelSelector](#) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


namespaces

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


topologyKey

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.PodAntiAffinity {#istio-operator-v1alpha1-podantiaffinity}

See k8s.io.api.core.v1.PodAntiAffinity.



  
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


requiredDuringSchedulingIgnoredDuringExecution

</td>

<td>

List of [istio.operator.v1alpha1.PodAffinityTerm](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-podaffinityterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


preferredDuringSchedulingIgnoredDuringExecution

</td>

<td>

List of [istio.operator.v1alpha1.WeightedPodAffinityTerm](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-weightedpodaffinityterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.PodDisruptionBudgetSpec {#istio-operator-v1alpha1-poddisruptionbudgetspec}

See k8s.io.api.policy.v1beta1.PodDisruptionBudget.



  
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


minAvailable

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


selector

</td>

<td>

[k8s.io.apimachinery.pkg.apis.meta.v1.LabelSelector](#) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


maxUnavailable

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.PodSecurityContext {#istio-operator-v1alpha1-podsecuritycontext}

See k8s.io.api.core.v1.PodSecurityContext.



  
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


seLinuxOptions

</td>

<td>

[istio.operator.v1alpha1.SELinuxOptions](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-selinuxoptions) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


runAsUser

</td>

<td>

[int64](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


runAsNonRoot

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


supplementalGroups

</td>

<td>

List of [int64](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


fsGroup

</td>

<td>

[int64](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


runAsGroup

</td>

<td>

[int64](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


sysctls

</td>

<td>

List of [istio.operator.v1alpha1.Sysctl](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-sysctl) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


windowsOptions

</td>

<td>

[istio.operator.v1alpha1.WindowsSecurityContextOptions](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-windowssecuritycontextoptions) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


fsGroupChangePolicy

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


seccompProfile

</td>

<td>

[istio.operator.v1alpha1.SeccompProfile](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-seccompprofile) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.PodsMetricSource {#istio-operator-v1alpha1-podsmetricsource}

See k8s.io.autoscaling.v2beta2.PodsMetricSource.



  
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


metricName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


targetAverageValue

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


selector

</td>

<td>

[k8s.io.apimachinery.pkg.apis.meta.v1.LabelSelector](#) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


metric

</td>

<td>

[istio.operator.v1alpha1.MetricIdentifier](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricidentifier) <br/> v2beta2/v2 fields

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


target

</td>

<td>

[istio.operator.v1alpha1.MetricTarget](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metrictarget) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.PodsMetricStatus {#istio-operator-v1alpha1-podsmetricstatus}

See k8s.io.autoscaling.v2beta2.PodsMetricStatus.



  
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


metric

</td>

<td>

[istio.operator.v1alpha1.MetricIdentifier](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricidentifier) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


current

</td>

<td>

[istio.operator.v1alpha1.MetricValueStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricvaluestatus) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.PreferredSchedulingTerm {#istio-operator-v1alpha1-preferredschedulingterm}

See k8s.io.api.core.v1.PreferredSchedulingTerm.



  
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


weight

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


preference

</td>

<td>

[istio.operator.v1alpha1.NodeSelectorTerm](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-nodeselectorterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ReadinessProbe {#istio-operator-v1alpha1-readinessprobe}

See k8s.io.api.core.v1.ReadinessProbe.



  
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


exec

</td>

<td>

[istio.operator.v1alpha1.ExecAction](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-execaction) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


httpGet

</td>

<td>

[istio.operator.v1alpha1.HTTPGetAction](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-httpgetaction) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tcpSocket

</td>

<td>

[istio.operator.v1alpha1.TCPSocketAction](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-tcpsocketaction) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


initialDelaySeconds

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


timeoutSeconds

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


periodSeconds

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


successThreshold

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


failureThreshold

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ResourceFieldSelector {#istio-operator-v1alpha1-resourcefieldselector}

See k8s.io.api.core.v1..



  
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


containerName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


resource

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


divisor

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ResourceMetricSource {#istio-operator-v1alpha1-resourcemetricsource}

See k8s.io.autoscaling.v2beta2.ResourceMetricSource.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


targetAverageUtilization

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


targetAverageValue

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


target

</td>

<td>

[istio.operator.v1alpha1.MetricTarget](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metrictarget) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ResourceMetricStatus {#istio-operator-v1alpha1-resourcemetricstatus}

See k8s.io.autoscaling.v2beta2.ResourceMetricStatus.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


current

</td>

<td>

[istio.operator.v1alpha1.MetricValueStatus](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-metricvaluestatus) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.Resources {#istio-operator-v1alpha1-resources}

See k8s.io.api.core.v1.ResourceRequirements.



  
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


limits

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


requests

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.RollingUpdateDeployment {#istio-operator-v1alpha1-rollingupdatedeployment}

See k8s.io.api.apps.v1.RollingUpdateDeployment.



  
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


maxUnavailable

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


maxSurge

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.SELinuxOptions {#istio-operator-v1alpha1-selinuxoptions}

See k8s.io.api.core.v1.SELinuxOptions.



  
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


user

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


role

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


type

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


level

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.SeccompProfile {#istio-operator-v1alpha1-seccompprofile}

See k8s.io.api.core.v1.SeccompProfile.



  
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


type

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


localhostProfile

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.SecretKeySelector {#istio-operator-v1alpha1-secretkeyselector}

See k8s.io.api.core.v1.SecretKeySelector.



  
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


localObjectReference

</td>

<td>

[istio.operator.v1alpha1.LocalObjectReference](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-localobjectreference) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


key

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


optional

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ServicePort {#istio-operator-v1alpha1-serviceport}

See k8s.io.api.core.v1..



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


protocol

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

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

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


targetPort

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


nodePort

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.ServiceSpec {#istio-operator-v1alpha1-servicespec}

See k8s.io.api.core.v1.ServiceSpec.



  
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


ports

</td>

<td>

List of [istio.operator.v1alpha1.ServicePort](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-serviceport) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


selector

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


clusterIP

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


type

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


externalIPs

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


sessionAffinity

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


loadBalancerIP

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


loadBalancerSourceRanges

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


externalName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


externalTrafficPolicy

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


healthCheckNodePort

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


publishNotReadyAddresses

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


sessionAffinityConfig

</td>

<td>

[istio.operator.v1alpha1.SessionAffinityConfig](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-sessionaffinityconfig) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.SessionAffinityConfig {#istio-operator-v1alpha1-sessionaffinityconfig}

See k8s.io.api.core.v1.SessionAffinityConfig.



  
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


clientIP

</td>

<td>

[istio.operator.v1alpha1.ClientIPConfig](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-clientipconfig) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.Sysctl {#istio-operator-v1alpha1-sysctl}

See k8s.io.api.core.v1.Sysctl.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.TCPSocketAction {#istio-operator-v1alpha1-tcpsocketaction}

See k8s.io.api.core.v1.TCPSocketAction.



  
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


port

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


host

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.Toleration {#istio-operator-v1alpha1-toleration}

See k8s.io.api.core.v1.Toleration.



  
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


key

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


operator

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


value

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


effect

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


tolerationSeconds

</td>

<td>

[int64](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.WeightedPodAffinityTerm {#istio-operator-v1alpha1-weightedpodaffinityterm}

See k8s.io.api.core.v1.WeightedPodAffinityTerm.



  
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


weight

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


podAffinityTerm

</td>

<td>

[istio.operator.v1alpha1.PodAffinityTerm](../../../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-podaffinityterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## istio.operator.v1alpha1.WindowsSecurityContextOptions {#istio-operator-v1alpha1-windowssecuritycontextoptions}

See k8s.io.api.core.v1.WindowsSecurityContextOptions.



  
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


gmsaCredentialSpecName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


gmsaCredentialSpec

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


runAsUserName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  




## istio.operator.v1alpha1.InstallStatus.Status {#istio-operator-v1alpha1-installstatus-status}

Status describes the current state of a component.


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

Component is not present.

</td>
</tr>
    
<tr>
<td>


UPDATING

</td>

<td>

1

</td>

<td>

Component is being updated to a different version.

</td>
</tr>
    
<tr>
<td>


RECONCILING

</td>

<td>

2

</td>

<td>

Controller has started but not yet completed reconciliation loop for the component.

</td>
</tr>
    
<tr>
<td>


HEALTHY

</td>

<td>

3

</td>

<td>

Component is healthy.

</td>
</tr>
    
<tr>
<td>


ERROR

</td>

<td>

4

</td>

<td>

Component is in an error state.

</td>
</tr>
    
<tr>
<td>


ACTION_REQUIRED

</td>

<td>

5

</td>

<td>

Overall status only and would not be set as a component status.
Action is needed from the user for reconciliation to proceed
e.g. There are proxies still pointing to the control plane revision when try to remove an `IstioOperator` CR.

</td>
</tr>
    
</table>
  


