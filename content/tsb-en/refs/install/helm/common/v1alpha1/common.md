---
title: install/helm/common/v1alpha1/common.proto
description: install/helm/common/v1alpha1/common.proto
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->







## Image {#tetrateio-api-install-helm-common-v1alpha1-image}

Values for the TSB operator image.



  
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


registry

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Registry used to download the operator image.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The tag of the operator image.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Operator {#tetrateio-api-install-helm-common-v1alpha1-operator}

Operator values for the TSB operator application.



  
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


deployment

</td>

<td>

[tetrateio.api.install.helm.common.v1alpha1.Operator.Deployment](../../../../install/helm/common/v1alpha1/common#tetrateio-api-install-helm-common-v1alpha1-operator-deployment) <br/> Values for the TSB operator deployment.

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

[tetrateio.api.install.helm.common.v1alpha1.Operator.Service](../../../../install/helm/common/v1alpha1/common#tetrateio-api-install-helm-common-v1alpha1-operator-service) <br/> Values for the TSB operator service.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


serviceAccount

</td>

<td>

[tetrateio.api.install.helm.common.v1alpha1.Operator.ServiceAccount](../../../../install/helm/common/v1alpha1/common#tetrateio-api-install-helm-common-v1alpha1-operator-serviceaccount) <br/> Values for the TSB operator service account.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Deployment {#tetrateio-api-install-helm-common-v1alpha1-operator-deployment}

Values for the TSB operator deployment.



  
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

[tetrateio.api.install.kubernetes.Affinity](../../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-affinity) <br/> Affinity configuration for the pod.
https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


annotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Custom collection of annotations to add to the deployment.
https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/

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

List of [tetrateio.api.install.kubernetes.EnvVar](../../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-envvar) <br/> Custom collection of environment vars to add to the container.
https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/

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

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Custom collection of annotations to add to the pod.

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

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Number of replicas managed by the deployment.

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

[tetrateio.api.install.kubernetes.DeploymentStrategy](../../../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-deploymentstrategy) <br/> Deployment strategy to use.
Remove Any when working on https://github.com/tetrateio/tetrate/issues/15885
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#deploymentstrategy-v1-apps

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

List of [k8s.io.api.core.v1.Toleration](#) <br/> Toleration collection applying to the pod scheduling.
https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### Service {#tetrateio-api-install-helm-common-v1alpha1-operator-service}

Values for the TSB operator service.



  
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


annotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Custom collection of annotations to add to the service.
https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


### ServiceAccount {#tetrateio-api-install-helm-common-v1alpha1-operator-serviceaccount}

Values for the TSB operator service account.



  
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


annotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Custom collection of annotations to add to the service account.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


imagePullSecrets

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Collection of secrets names required to be able to pull images from the registry.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


pullSecret

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> A Docker config JSON to be stored in a secret to be used as an image pull secret. If this secret is provided,
it will be included in the operator service account as reference.
https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-by-providing-credentials-on-the-command-line

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


pullUsername

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Used along pull password and the provided image registry to generate a Docker config JSON that
will be stored as a pull secret.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


pullPassword

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Used along pull username and the provided image registry to generate a Docker config JSON that
will be stored as a pull secret.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  



