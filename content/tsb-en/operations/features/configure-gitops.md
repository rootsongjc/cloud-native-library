---
title: GitOps
description: Configure GitOps for TSB resources
---

This document describes how to configure the
[GitOps](../../knowledge_base/gitops) integration for Tetrate Service Bridge
(TSB). 
GitOps integration in TSB allows you to integrate with the lifecycle of
application packaging and deployment and the different Continuous Deployment
(CD) Systems.

This document assumes that you already have working knowledge of configuring
GitOps CD systems, such as [FluxCD](https://fluxcd.io/) or
[ArgoCD](https://argo-cd.readthedocs.io/en/stable/).

## How it works

Once enabled in a Management Plane cluster and/or an Application cluster, the CD System will be able to apply the
TSB configurations in it, which then will be pushed to the TSB Management Plane.

![](../../assets/operations/gitops.png)

## Enabling GitOps
 
The GitOps component can be configured through `ManagementPlane` or `ControlPlane` CR or Helm values for each cluster.

:::note
When enabling GitOps in both Management Plane and Control Plane, if both planes are deployed in the same cluster, which usually done
for small environments or [demo installation](../../setup/self_managed/demo-installation), only one of both planes will effectively
being enable. Concretely, the Control Plane will be the only enabled plane. This is to avoid both planes push multiple times the same resources.
:::

Both `ManagementPlane` and `ControlPlane` CR have a component called `gitops`, setting `enabled: true` is what activates GitOps for that cluster.

```yaml
spec:
  components:
    ...
    gitops:
      enabled: true
      reconcileInterval: 600s
```

:::note
When enabling GitOps, it is highly recommended to configure user permissions in a way
that regular users only have READ access to the TSB configurations. This will help ensure
that only the configured cluster service account can manage configuration.
:::

### Enabling GitOps in the Management Plane

Following is an example of custom resource YAML that enables GitOps for a
`demo` cluster, which Management Plane is deployed in the `tsb`
namespace. If you use Helm, you can update `spec` section of the control plane Helm values.

```bash{promptUser: "alice"}
kubectl edit -n tsb managementplane/managementplane
```

```yaml
spec:
  components:
    ...
    gitops:
      enabled: true
      reconcileInterval: 600s
```

Setting `enabled: true` is what activates GitOps for the Management Plane cluster.

Every time resources are applied by the CD system to the Management Plane cluster,
the TSB GitOps component will push them to the Management Plane. Additionally,
there is a periodic reconciliation process that ensures the Management Plane cluster
remains the source of truth, and periodically pushes the information in it. The
`reconcileInterval` attribute can be used to customize the interval at which
the background reconciliation process runs. Further details and additional configuration
options can be found in the [GitOps component reference](../../refs/install/managementplane/v1alpha1/spec#gitops).

The Management Plane cluster can push the configurations to the entire organization without 
the need to grant any special permissions once GitOps is enabled in that plane.

After applying the changes to the `ManagementPlane` CR, the TSB operator will
activate the feature for the cluster and it will start reacting to the applied
TSB K8s resources.

### Enabling GitOps in the Control Plane

Following is an example of custom resource YAML that enables GitOps for a
`demo` cluster, which Control Plane is deployed in the `istio-system`
namespace. If you use Helm, you can update `spec` section of the control plane Helm values.

```bash{promptUser: "alice"}
kubectl edit -n istio-system controlplane/controlplane
```

```yaml
spec:
  components:
    ...
    gitops:
      enabled: true
      reconcileInterval: 600s
```

Setting `enabled: true` is what activates GitOps for that cluster.

Every time resources are applied by the CD system to the application cluster,
the TSB GitOps component will push them to the Management Plane. Additionally,
there is a periodic reconciliation process that ensures the application cluster
remains the source of truth, and periodically pushes the information in it. The
`reconcileInterval` attribute can be used to customize the interval at which
the background reconciliation process runs. Further details and additional configuration
options can be found in the [GitOps component reference](../../refs/install/controlplane/v1alpha1/spec#gitops).

Unlike in the Management Plane, in order to allow the Application cluster push the configurations to the
Management Plane, permissions need to be granted to the cluster service
account. This can be easily done as follows:

```bash{promptUser: "alice"}
$ tctl x gitops grant demo
```

This will grant permission to push configurations to the entire organization.
If you want to further constrain where the cluster service account can push
configurations, please take a look at the command documentation:

```bash{promptUser: "alice"}
$ tctl x gitops grant --help
```

After applying the changes to the `ControlPlane` CR, the TSB operator will
activate the feature for the cluster and it will start reacting to the applied
TSB K8s resources.

## Monitoring GitOps health

The GitOps integration provides metrics and detailed logs that can be used to monitor
the health of the different components involved in the GitOps process:

* The [GitOps metrics](../telemetry/key-metrics#gitops-operational-status) provide insights about
  the latency experienced when sending configurations to the Management Plane, error rates, etc.
* Both `tsb-operator-management-plane` and `tsb-operator-control-plane` provides the `gitops` logger that can be
  [enabled at debug level](../configure_log_levels) to get detailed log messages from the different
  components that are part of the GitOps configuration propagation.

