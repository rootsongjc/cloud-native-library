---
title: Security Context of TSB Components
description: Guide on configuring security context for TSB components
---

In Kubernetes, a [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) defines privilege and access control settings for a Pod or Container. It provides the ability to set many security-relevant parameters.

Tetrate Service Bridge (TSB) installation API provides the ability to configure security context for TSB components. The following sections describe how to configure security context for TSB components.

## Operator Security Context

TSB uses [operators](../concepts/operators) to manage the lifecycle of TSB components. You can configure the security context for operators by setting the `operator.deployment.podSecurityContext` and `operator.deployment.containerSecurityContext` field in the TSB install custom resources or Helm values file. The following example can be used for the management plane, control plane, and data plane operator.

```yaml
operator:
  deployment:
    podAnnotations:
      security-check: runtime/default
    podSecurityContext:
      fsGroup: 1000
      supplementalGroups:
      - 1000
    containerSecurityContext:
      runAsNonRoot: true
      readOnlyRootFilesystem: true
      runAsUser: 1000
      runAsGroup: 1000
      privileged: false
      allowPrivilegeEscalation: false
```

## Components Security Context

To configure the security context for TSB management plane or control plane [components](../setup/components), you have options to set `defaultKubeSpec` that will be used for all components, or set the security context in each component `kubeSpec` individually. The following example shows how to set the security context for all components and an individual component in the TSB install custom resources or Helm values file. 

Note that in `defaultKubeSpec`, you can also set security context for TSB components that runs as Kubernetes job.

```yaml
spec:
  components:
    # defaultKubeSpec will be used for all components
    defaultKubeSpec:
      deployment:
        pod_annotations:
          security-check: runtime/default
        podSecurityContext:
          fsGroup: 1000
          supplementalGroups:
          - 1000
        containerSecurityContext:
          runAsNonRoot: true
          readOnlyRootFilesystem: true
          runAsUser: 1000
          runAsGroup: 1000
          privileged: false
          allowPrivilegeEscalation: false
  oap:
    # security context for individual component
    kubeSpec:
      deployment:
        pod_annotations:
          security-check: runtime/default
        podSecurityContext:
          fsGroup: 2000
          supplementalGroups:
          - 2000
        containerSecurityContext:
          runAsNonRoot: true
          readOnlyRootFilesystem: true
          runAsUser: 2000
          runAsGroup: 2000
          privileged: false
          allowPrivilegeEscalation: false
```

## Gateway Security Context

To configure TSB [gateway](../refs/install/dataplane/v1alpha1/spec) security context, you can set `kubeSpec.deployment.podSecurityContext` or `kubeSpec.deployment.containerSecurityContext` field in TSB gateway installation custom resource.

```yaml
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: bookinfo-gw
  namespace: bookinfo-gw
spec:
  kubeSpec:
    service:
      type: LoadBalancer
    deployment:
      pod_annotations:
        security-check: runtime/default
      podSecurityContext:
        fsGroup: 1000
        supplementalGroups:
        - 1000
      containerSecurityContext:
        runAsNonRoot: true
        readOnlyRootFilesystem: true
        runAsUser: 1000
        runAsGroup: 1000
        privileged: false
        allowPrivilegeEscalation: false
```

## OpenShift Security Context

When deploying Tetrate Service Bridge (TSB) on OpenShift, especially from OpenShift Container Platform (OCP) version 4.12 and onwards, you should be aware of certain caveats. In these versions, OpenShift has enhanced the enforcement of User/Group and some other properties on a per-namespace basis.

If you, as a platform owner, try to update these properties, this could result in compatibility issues with the TSB due to these enhanced security enforcements. If the Security Context Constraints (SCCs) that come packaged with the TSB become incompatible with these updated properties, the TSB may become invalid.

Therefore, ensure that any changes to these properties align with the TSB requirements. If conflicts arise, it may necessitate updating the TSB or adjusting the SCC to permit the required permissions for the TSB.
