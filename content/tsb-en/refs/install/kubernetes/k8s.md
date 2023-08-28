---
title: Kubernetes
description: Common Kubernetes configuration shared by all components in the install API planes.
---



<!-- WARNING: This page is generated. Please take a look at extensions/plugin-service-bridge-api-docs/src/files/doc/page.ejs -->

When installing on Kubernetes, these configuration settings can be used to
override the default Kubernetes configuration. Kubernetes configuration can
be set on each component in the install API using the `kubeSpec` field.

The API allows for customization of every field in the rendered Kubernetes
manifests. The more common configuration fields, such as resources and
service type, are supported directly; and can be configured like so:

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  hub: docker.io/tetrate
  components:
    apiServer:
      kubeSpec:
        service:
          type: LoadBalancer
        deployment:
          resources:
            limits:
              memory: 750Mi
            requests:
              memory: 500Mi
```

All components have a `deployment` and `service` object. Some, such as
`apiServer`, also have a `job` object associated with them. This can be
configured in a similar manner:

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  hub: docker.io/tetrate
  components:
    apiServer:
      kubeSpec:
        job:
          podAnnotations:
            annotation-key: annotation-value
```

Not all fields in a Kubernetes manifest can be configured directly. This is
to avoid re-implementing the entire Kubernetes API within the install API.
Instead, the `kubeSpec` object provides an overlays mechanism. This field is
applied after the operator renders the initial manifests and enables support
for customization of any field in a rendered manifest.

Overlays can be applied by selecting the Kubernetes object you wish to
overlay and then describe a list of patches you wish to apply. For example,
to add a `hostPort` on port 8443 to the `frontEnvoy` component, do the
following:

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
spec:
  hub: docker.io/tetrate
  components:
    frontEnvoy:
      kubeSpec:
        overlays:
        - apiVersion: apps/v1
          kind: Deployment
          name: envoy
          patches:
          - path:
          spec.template.spec.containers.[name:envoy].ports.[containerPort:8443].hostPort
            value: 8443
```

The path refers to the location of the field in the Kubernetes object you
with to patch. The format is `a.[key1:value1].b.[:value2]`. Where
`[key1:value1]` is a selector for a key-value pair to identify a list element
and `[:value]` is a value selector to identify a list element in a leaf list.
All path intermediate nodes must exist.

Overlays are inspired by and bear a loose resemblance to
`[kustomize](https://kustomize.io/)`. We use the library from the Istio
Operator. For more examples of how to construct paths take a look at the
[tests in the
upstream](https://github.com/istio/istio/blob/master/operator/pkg/tpath/tree_test.go).





## Affinity {#tetrateio-api-install-kubernetes-affinity}

The scheduling constraints for the pod.
https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity



  
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

[tetrateio.api.install.kubernetes.NodeAffinity](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-nodeaffinity) <br/> Group of node affinity scheduling rules.
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#nodeaffinity-v1-core

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

[tetrateio.api.install.kubernetes.PodAffinity](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-podaffinity) <br/> Group of inter-pod affinity scheduling rules.
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#podaffinity-v1-core

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

[tetrateio.api.install.kubernetes.PodAntiAffinity](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-podantiaffinity) <br/> Group of inter-pod anti-affinity scheduling rules.
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#podantiaffinity-v1-core

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## CNI {#tetrateio-api-install-kubernetes-cni}

Configure Istio's CNI plugin
For further details see: https://istio.io/docs/setup/additional-setup/cni/



  
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


binaryDirectory

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Directory on the host to install the CNI binary.
Must be the same as the environment’s `--cni-bin-dir` setting (kubelet
parameter).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


configurationDirectory

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Directory on the host to install the CNI config.
Must be the same as the environment’s `--cni-conf-dir` setting (kubelet
parameter).

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


chained

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Whether to deploy the configuration file as a plugin chain or as a
standalone file in the configuration directory. Some Kubernetes flavors
(e.g. OpenShift) do not support the chain approach.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


configurationFileName

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Leave unset to auto-find the first file in the `cni-conf-dir` (as kubelet
does). Primarily used for testing install-cni plugin configuration. If set,
`install-cni` will inject the plugin configuration into this file in the
`cni-conf-dir`.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


clusterRole

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The ClusterRole Istio CNI will bind to in the ControlPlane namespace.
This is useful if you use Pod Security Policies and want to allow
`istio-cni` to run as privileged Pods.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> The revisioned istio-operator that will reconcile the Istio CNI component.
A revision can only be specified when Isolation Boundaries are enabled and
configured with at least one revision.
Revision specified here must be an enabled revision under `xcp.isolationBoundaries`.
If not provided, it defaults to the latest enabled
revision based on their corresponding tsbVersion. If multiple such revisions
are found, revision names are alphabetically sorted and the first revision
is considered as the default.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Capabilities {#tetrateio-api-install-kubernetes-capabilities}

See k8s.io.api.core.v1.Capabilities.



  
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


add

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


drop

</td>

<td>

List of [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ClientIPConfig {#tetrateio-api-install-kubernetes-clientipconfig}





  
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
  


## ConfigMapKeySelector {#tetrateio-api-install-kubernetes-configmapkeyselector}





  
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

[tetrateio.api.install.kubernetes.LocalObjectReference](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-localobjectreference) <br/> 

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
  


## ContainerPort {#tetrateio-api-install-kubernetes-containerport}

ContainerPort represents a network port in a single container.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> If specified, this must be an IANA_SVC_NAME and unique within the pod. Each
named port in a pod must have a unique name. Name for the port that can be
referred to by services.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hostPort

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Number of port to expose on the host.
If specified, this must be a valid port number, 0 < x < 65536.

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


containerPort

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Number of port to expose on the pod's IP address.
This must be a valid port number, 0 < x < 65536.

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Protocol for port. Must be UDP, TCP, or SCTP.
Defaults to "TCP".

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


hostIP

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> What host IP to bind the external port to.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## CrossVersionObjectReference {#tetrateio-api-install-kubernetes-crossversionobjectreference}





  
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
  


## Deployment {#tetrateio-api-install-kubernetes-deployment}

The Kubernetes resource configuration for all Deployments



  
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


podAnnotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Pod annotations are an unstructured key value map stored with the pod.
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

List of [tetrateio.api.install.kubernetes.EnvVar](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-envvar) <br/> Environment variables for all containers in the deployment.
https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


affinity

</td>

<td>

[tetrateio.api.install.kubernetes.Affinity](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-affinity) <br/> The scheduling constraints for the pod.
https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Number of desired pods.
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#deploymentspec-v1-apps

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

[tetrateio.api.install.kubernetes.Resources](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-resources) <br/> Compute Resources required by the primary container in the deployment
PodSpec.
https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container

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

[tetrateio.api.install.kubernetes.DeploymentStrategy](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-deploymentstrategy) <br/> The deployment strategy to use to replace existing pods with new ones.
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

List of [k8s.io.api.core.v1.Toleration](#) <br/> Tolerations are applied to pods, and allow (but do not require) the pods to
schedule onto nodes with matching taints. Taints and tolerations work
together to ensure that pods are not scheduled onto inappropriate nodes.
One or more taints are applied to a node; this marks that the node should
not accept any pods that do not tolerate the taints.
https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/

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

[tetrateio.api.install.kubernetes.HorizontalPodAutoscalerSpec](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-horizontalpodautoscalerspec) <br/> Horizontal Pod Autoscaler automatically scales the number of pods in a
deployment based on a specified metric. Kubernetes periodically adjusts the
number of replicas in a deployment to match the observed metric to the
target specified. The version of Horizontal Pod Autoscaler currently used
is
`[v2beta1](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#horizontalpodautoscaler-v2beta1-autoscaling)`.
https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


podSecurityContext

</td>

<td>

[tetrateio.api.install.kubernetes.PodSecurityContext](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-podsecuritycontext) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _podSecurityContext</sup>_ <br/> k8s pod security context
[Set the security context for a
Pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


containerSecurityContext

</td>

<td>

[tetrateio.api.install.kubernetes.SecurityContext](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-securitycontext) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _containerSecurityContext</sup>_ <br/> k8s container security context
[Set the security context for a
Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## DeploymentStrategy {#tetrateio-api-install-kubernetes-deploymentstrategy}

The deployment strategy to use to replace existing pods with new ones.
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#deploymentstrategy-v1-apps



  
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

[tetrateio.api.install.kubernetes.RollingUpdateDeployment](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-rollingupdatedeployment) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## EnvVar {#tetrateio-api-install-kubernetes-envvar}





  
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

[tetrateio.api.install.kubernetes.EnvVarSource](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-envvarsource) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## EnvVarSource {#tetrateio-api-install-kubernetes-envvarsource}





  
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

[tetrateio.api.install.kubernetes.ObjectFieldSelector](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-objectfieldselector) <br/> 

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

[tetrateio.api.install.kubernetes.ResourceFieldSelector](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-resourcefieldselector) <br/> 

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

[tetrateio.api.install.kubernetes.ConfigMapKeySelector](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-configmapkeyselector) <br/> 

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

[tetrateio.api.install.kubernetes.SecretKeySelector](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-secretkeyselector) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ExternalMetricSource {#tetrateio-api-install-kubernetes-externalmetricsource}





  
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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GlobalDeployment {#tetrateio-api-install-kubernetes-globaldeployment}

The Kubernetes resource configuration for a Deployment



  
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


podAnnotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Pod annotations are an unstructured key value map stored with the pod.
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

List of [tetrateio.api.install.kubernetes.EnvVar](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-envvar) <br/> Environment variables for all containers in the deployment.
https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


affinity

</td>

<td>

[tetrateio.api.install.kubernetes.Affinity](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-affinity) <br/> The scheduling constraints for the pod.
https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity

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

[tetrateio.api.install.kubernetes.DeploymentStrategy](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-deploymentstrategy) <br/> The deployment strategy to use to replace existing pods with new ones.
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

List of [k8s.io.api.core.v1.Toleration](#) <br/> Tolerations are applied to pods, and allow (but do not require) the pods to
schedule onto nodes with matching taints. Taints and tolerations work
together to ensure that pods are not scheduled onto inappropriate nodes.
One or more taints are applied to a node; this marks that the node should
not accept any pods that do not tolerate the taints.
https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


podSecurityContext

</td>

<td>

[tetrateio.api.install.kubernetes.PodSecurityContext](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-podsecuritycontext) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _podSecurityContext</sup>_ <br/> k8s pod security context
[Set the security context for a
Pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


containerSecurityContext

</td>

<td>

[tetrateio.api.install.kubernetes.SecurityContext](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-securitycontext) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _containerSecurityContext</sup>_ <br/> k8s container security context
[Set the security context for a
Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GlobalJob {#tetrateio-api-install-kubernetes-globaljob}

The Kubernetes resource configuration for all CronJob or Job



  
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


podAnnotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Pod annotations are an unstructured key value map stored with the pod.
https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


affinity

</td>

<td>

[tetrateio.api.install.kubernetes.Affinity](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-affinity) <br/> The scheduling constraints for the pod.
https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity

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

List of [k8s.io.api.core.v1.Toleration](#) <br/> Tolerations are applied to pods, and allow (but do not require) the pods to
schedule onto nodes with matching taints. Taints and tolerations work
together to ensure that pods are not scheduled onto inappropriate nodes.
One or more taints are applied to a node; this marks that the node should
not accept any pods that do not tolerate the taints.
https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


podSecurityContext

</td>

<td>

[tetrateio.api.install.kubernetes.PodSecurityContext](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-podsecuritycontext) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _podSecurityContext</sup>_ <br/> k8s pod security context
[Set the security context for a
Pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


containerSecurityContext

</td>

<td>

[tetrateio.api.install.kubernetes.SecurityContext](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-securitycontext) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _containerSecurityContext</sup>_ <br/> k8s container security context
[Set the security context for a
Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## GlobalService {#tetrateio-api-install-kubernetes-globalservice}

The Kubernetes resource configuration for all the Service



  
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

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Pod annotations are an unstructured key value map stored with the service.
https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## HorizontalPodAutoscalerSpec {#tetrateio-api-install-kubernetes-horizontalpodautoscalerspec}

Horizontal Pod Autoscaler automatically scales the number of pods in a
deployment based on a specified metric. Kubernetes periodically adjusts the
number of replicas in a deployment to match the observed metric to the target
specified. This mirrors the Kubernetes spec except from the top level
`scaleTargetRef` field, which we set for you. The version of Horizontal Pod
Autoscaler currently used is
`[v2beta1](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#horizontalpodautoscaler-v2beta1-autoscaling)`.
https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/



  
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


minReplicas

</td>

<td>

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Must be set in order to create the HPA resource in Kubernetes

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

[int32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Must be set in order to create the HPA resource in Kubernetes

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

List of [tetrateio.api.install.kubernetes.MetricSpec](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-metricspec) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Job {#tetrateio-api-install-kubernetes-job}

The Kubernetes resource configuration for a CronJob or Job



  
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


podAnnotations

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Pod annotations are an unstructured key value map stored with the pod.
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

List of [tetrateio.api.install.kubernetes.EnvVar](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-envvar) <br/> Environment variables for all containers in the job.
https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


affinity

</td>

<td>

[tetrateio.api.install.kubernetes.Affinity](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-affinity) <br/> The scheduling constraints for the pod.
https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity

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

List of [k8s.io.api.core.v1.Toleration](#) <br/> Tolerations are applied to pods, and allow (but do not require) the pods to
schedule onto nodes with matching taints. Taints and tolerations work
together to ensure that pods are not scheduled onto inappropriate nodes.
One or more taints are applied to a node; this marks that the node should
not accept any pods that do not tolerate the taints.
https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


podSecurityContext

</td>

<td>

[tetrateio.api.install.kubernetes.PodSecurityContext](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-podsecuritycontext) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _podSecurityContext</sup>_ <br/> k8s pod security context
[Set the security context for a
Pod](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


containerSecurityContext

</td>

<td>

[tetrateio.api.install.kubernetes.SecurityContext](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-securitycontext) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _containerSecurityContext</sup>_ <br/> k8s container security context
[Set the security context for a
Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container)

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## KubernetesComponentSpec {#tetrateio-api-install-kubernetes-kubernetescomponentspec}

KubernetesComponentSpec is a common set of Kubernetes resource configuration
for components.



  
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

[tetrateio.api.install.kubernetes.Deployment](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-deployment) <br/> Settings related to the component deployment

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

[tetrateio.api.install.kubernetes.Service](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-service) <br/> Settings related to the component service

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

[tetrateio.api.install.kubernetes.ServiceAccount](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-serviceaccount) <br/> Settings related to the component service account

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

List of [istio.operator.v1alpha1.K8sObjectOverlay](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-k8sobjectoverlay) <br/> Post-render overlays to mutate Kubernetes manifests
https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#K8sObjectOverlay

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## KubernetesIstioComponentSpec {#tetrateio-api-install-kubernetes-kubernetesistiocomponentspec}

KubernetesIstioComponentSpec is the common set of Kubernetes resource
configuration for Istio. It differs from the standard component specs in that
it supports CNI configuration.



  
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

[tetrateio.api.install.kubernetes.Deployment](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-deployment) <br/> Settings related to the component deployment

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

[tetrateio.api.install.kubernetes.Service](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-service) <br/> Settings related to the component service

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

[tetrateio.api.install.kubernetes.ServiceAccount](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-serviceaccount) <br/> Settings related to the component service account

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


CNI

</td>

<td>

[tetrateio.api.install.kubernetes.CNI](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-cni) <br/> Configure Istio's CNI plugin
For further details see: https://istio.io/docs/setup/additional-setup/cni/

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

List of [istio.operator.v1alpha1.K8sObjectOverlay](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-k8sobjectoverlay) <br/> Post-render overlays to mutate Kubernetes manifests
https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#K8sObjectOverlay

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## KubernetesJobComponentSpec {#tetrateio-api-install-kubernetes-kubernetesjobcomponentspec}

KubernetesJobComponentSpec is a common set of Kubernetes resource
configuration for components with a job associated with them.



  
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

[tetrateio.api.install.kubernetes.Deployment](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-deployment) <br/> Settings related to the component deployment

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

[tetrateio.api.install.kubernetes.Service](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-service) <br/> Settings related to the component service

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


job

</td>

<td>

[tetrateio.api.install.kubernetes.Job](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-job) <br/> Settings related to the component job or cronjob

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

[tetrateio.api.install.kubernetes.ServiceAccount](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-serviceaccount) <br/> Settings related to the component service account

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

List of [istio.operator.v1alpha1.K8sObjectOverlay](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-k8sobjectoverlay) <br/> Post-render overlays to mutate Kubernetes manifests
https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#K8sObjectOverlay

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## KubernetesSpec {#tetrateio-api-install-kubernetes-kubernetesspec}

KubernetesSpec is a common set of Kubernetes resource configuration for the
install CRs, that will be common to all of its components.



  
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

[tetrateio.api.install.kubernetes.GlobalDeployment](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-globaldeployment) <br/> Settings related to the deployments

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

[tetrateio.api.install.kubernetes.GlobalService](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-globalservice) <br/> Settings related to the service

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


account

</td>

<td>

[tetrateio.api.install.kubernetes.ServiceAccount](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-serviceaccount) <br/> Settings related to the service account

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


job

</td>

<td>

[tetrateio.api.install.kubernetes.GlobalJob](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-globaljob) <br/> Settings related to the job or cronjob

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## LocalObjectReference {#tetrateio-api-install-kubernetes-localobjectreference}

LocalObjectReference contains enough information to let you locate the
referenced object inside the same namespace.



  
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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Name of the referent.

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## MetricSpec {#tetrateio-api-install-kubernetes-metricspec}





  
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

[tetrateio.api.install.kubernetes.ObjectMetricSource](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-objectmetricsource) <br/> 

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

[tetrateio.api.install.kubernetes.PodsMetricSource](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-podsmetricsource) <br/> 

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

[tetrateio.api.install.kubernetes.ResourceMetricSource](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-resourcemetricsource) <br/> 

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

[tetrateio.api.install.kubernetes.ExternalMetricSource](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-externalmetricsource) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## MetricTarget {#tetrateio-api-install-kubernetes-metrictarget}

MetricTarget provides compatibility with k8s autoscaling/v2 API



  
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


averageUtilization

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


averageValue

</td>

<td>

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## NodeAffinity {#tetrateio-api-install-kubernetes-nodeaffinity}

Group of node affinity scheduling rules.
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#nodeaffinity-v1-core



  
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

[tetrateio.api.install.kubernetes.NodeSelector](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-nodeselector) <br/> 

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

List of [tetrateio.api.install.kubernetes.PreferredSchedulingTerm](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-preferredschedulingterm) <br/> The scheduler will prefer to schedule pods to nodes that satisfy the
affinity expressions specified by this field, but it may choose a node that
violates one or more of the expressions.
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#preferredschedulingterm-v1-core

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## NodeSelector {#tetrateio-api-install-kubernetes-nodeselector}





  
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

List of [tetrateio.api.install.kubernetes.NodeSelectorTerm](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-nodeselectorterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## NodeSelectorRequirement {#tetrateio-api-install-kubernetes-nodeselectorrequirement}





  
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
  


## NodeSelectorTerm {#tetrateio-api-install-kubernetes-nodeselectorterm}





  
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

List of [tetrateio.api.install.kubernetes.NodeSelectorRequirement](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-nodeselectorrequirement) <br/> 

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

List of [tetrateio.api.install.kubernetes.NodeSelectorRequirement](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-nodeselectorrequirement) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ObjectFieldSelector {#tetrateio-api-install-kubernetes-objectfieldselector}





  
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
  


## ObjectMetricSource {#tetrateio-api-install-kubernetes-objectmetricsource}





  
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


target

</td>

<td>

[tetrateio.api.install.kubernetes.CrossVersionObjectReference](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-crossversionobjectreference) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## PodAffinity {#tetrateio-api-install-kubernetes-podaffinity}

Group of inter-pod affinity scheduling rules.
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#podaffinity-v1-core



  
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

List of [tetrateio.api.install.kubernetes.PodAffinityTerm](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-podaffinityterm) <br/> 

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

List of [tetrateio.api.install.kubernetes.WeightedPodAffinityTerm](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-weightedpodaffinityterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## PodAffinityTerm {#tetrateio-api-install-kubernetes-podaffinityterm}





  
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
  


## PodAntiAffinity {#tetrateio-api-install-kubernetes-podantiaffinity}

Group of inter-pod anti-affinity scheduling rules.
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#podantiaffinity-v1-core



  
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

List of [tetrateio.api.install.kubernetes.PodAffinityTerm](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-podaffinityterm) <br/> 

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

List of [tetrateio.api.install.kubernetes.WeightedPodAffinityTerm](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-weightedpodaffinityterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## PodSecurityContext {#tetrateio-api-install-kubernetes-podsecuritycontext}

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

[tetrateio.api.install.kubernetes.SELinuxOptions](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-selinuxoptions) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _seLinuxOptions</sup>_ <br/> 

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _runAsUser</sup>_ <br/> 

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

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _runAsNonRoot</sup>_ <br/> 

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

List of [uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> 

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _fsGroup</sup>_ <br/> 

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _runAsGroup</sup>_ <br/> 

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

List of [tetrateio.api.install.kubernetes.Sysctl](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-sysctl) <br/> 

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

[tetrateio.api.install.kubernetes.WindowsSecurityContextOptions](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-windowssecuritycontextoptions) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _windowsOptions</sup>_ <br/> 

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _fsGroupChangePolicy</sup>_ <br/> 

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

[tetrateio.api.install.kubernetes.SeccompProfile](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-seccompprofile) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _seccompProfile</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## PodsMetricSource {#tetrateio-api-install-kubernetes-podsmetricsource}





  
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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

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
  


## PreferredSchedulingTerm {#tetrateio-api-install-kubernetes-preferredschedulingterm}





  
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

[tetrateio.api.install.kubernetes.NodeSelectorTerm](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-nodeselectorterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ResourceFieldSelector {#tetrateio-api-install-kubernetes-resourcefieldselector}





  
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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ResourceMetricSource {#tetrateio-api-install-kubernetes-resourcemetricsource}





  
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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

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

[tetrateio.api.install.kubernetes.MetricTarget](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-metrictarget) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Resources {#tetrateio-api-install-kubernetes-resources}

Mirrors k8s.io.api.core.v1.ResourceRequirements for unmarshalling.



  
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
  


## RollingUpdateDeployment {#tetrateio-api-install-kubernetes-rollingupdatedeployment}

Mirrors k8s.io.api.apps.v1.RollingUpdateDeployment for unmarshalling.



  
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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## SELinuxOptions {#tetrateio-api-install-kubernetes-selinuxoptions}

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
  


## SeccompProfile {#tetrateio-api-install-kubernetes-seccompprofile}

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
  


## SecretKeySelector {#tetrateio-api-install-kubernetes-secretkeyselector}





  
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

[tetrateio.api.install.kubernetes.LocalObjectReference](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-localobjectreference) <br/> 

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
  


## SecurityContext {#tetrateio-api-install-kubernetes-securitycontext}

See k8s.io.api.core.v1.SecurityContext.



  
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


capabilities

</td>

<td>

[tetrateio.api.install.kubernetes.Capabilities](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-capabilities) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _capabilities</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


privileged

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _privileged</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


seLinuxOptions

</td>

<td>

[tetrateio.api.install.kubernetes.SELinuxOptions](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-selinuxoptions) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _seLinuxOptions</sup>_ <br/> 

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

[tetrateio.api.install.kubernetes.WindowsSecurityContextOptions](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-windowssecuritycontextoptions) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _windowsOptions</sup>_ <br/> 

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _runAsUser</sup>_ <br/> 

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

[uint32](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _runAsGroup</sup>_ <br/> 

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

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _runAsNonRoot</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


readOnlyRootFilesystem

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _readOnlyRootFilesystem</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


allowPrivilegeEscalation

</td>

<td>

[bool](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _allowPrivilegeEscalation</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


procMount

</td>

<td>

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _procMount</sup>_ <br/> 

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

[tetrateio.api.install.kubernetes.SeccompProfile](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-seccompprofile) _<sup><a href="https://developers.google.com/protocol-buffers/docs/proto3#oneof" target="_blank">oneof</a> _seccompProfile</sup>_ <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Service {#tetrateio-api-install-kubernetes-service}

The Kubernetes resource configuration for a Service



  
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

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Pod annotations are an unstructured key value map stored with the service.
https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


ports

</td>

<td>

List of [tetrateio.api.install.kubernetes.ServicePort](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-serviceport) <br/> List of ports exposed by the component's service.
https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#serviceport-v1-core

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

[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar) <br/> Determines how the Service is exposed. Valid options are ExternalName,
ClusterIP, NodePort, and LoadBalancer.
https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types

</td>

<td>

&ndash;

</td>
</tr>
    
<tr>
<td>


labels

</td>

<td>

map<[string](https://developers.google.com/protocol-buffers/docs/proto3#scalar), [string](https://developers.google.com/protocol-buffers/docs/proto3#scalar)> <br/> Labels are an unstructured key value map stored with the deployment.
https://kubernetes.io/docs/concepts/overview/working-with-objects/labels

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## ServiceAccount {#tetrateio-api-install-kubernetes-serviceaccount}

Settings related to the component service account



  
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


imagePullSecrets

</td>

<td>

List of [tetrateio.api.install.kubernetes.LocalObjectReference](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-localobjectreference) <br/> List of references to secrets in the same namespace to use for pulling any
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
    
</table>
  


## ServicePort {#tetrateio-api-install-kubernetes-serviceport}





  
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

[istio.operator.v1alpha1.IntOrString](../../istio.io/api/operator/v1alpha1/operator#istio-operator-v1alpha1-intorstring) <br/> 

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
  


## SessionAffinityConfig {#tetrateio-api-install-kubernetes-sessionaffinityconfig}





  
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

[tetrateio.api.install.kubernetes.ClientIPConfig](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-clientipconfig) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## Sysctl {#tetrateio-api-install-kubernetes-sysctl}

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
  


## Toleration {#tetrateio-api-install-kubernetes-toleration}





  
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
  


## WeightedPodAffinityTerm {#tetrateio-api-install-kubernetes-weightedpodaffinityterm}





  
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

[tetrateio.api.install.kubernetes.PodAffinityTerm](../../install/kubernetes/k8s#tetrateio-api-install-kubernetes-podaffinityterm) <br/> 

</td>

<td>

&ndash;

</td>
</tr>
    
</table>
  


## WindowsSecurityContextOptions {#tetrateio-api-install-kubernetes-windowssecuritycontextoptions}

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
  



