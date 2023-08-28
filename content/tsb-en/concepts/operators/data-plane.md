---
title: Data Plane
description: TSB Operator, and the Data Plane Gateways lifecycle.
---

This page will introduce you to how the TSB Operator is used to manage gateway
configurations for the data plane.

The TSB Operator, configured to manage the lifecycle of the data plane gateway
components, watches for `IngressGateway`, `Tier1Gateway`, and `EgressGateway`
custom resources (CR) in all the namespaces of the cluster. The default
namespace for the Data Plane gateway components is `istio-gateway`. For details
about the custom resource API, refer to the
[Data Plane Install API Reference Docs](../../refs/install/dataplane/v1alpha1/spec).

This data plane operator watches for any changes to the Kubernetes resources it
creates. When it identifies a watch event (e.g. the deletion of the deployment),
it reconciles the change to restore the system to the desired state, i.e.
recreating the deleted deployment.

:::note Control Plane required
The TSB Operator managing the data plane gateway components requires a fully
operational control plane inside its cluster. This means that there must be a
valid TSB Operator that manages the control plane alongside a valid
`ControlPlane` CR.
:::

## Components

![drawing](../../assets/operator_data_plane.png)

These are the types of custom components you can configure and manage using the
data plane operator:

| Component     | Service              | Deployment           |
| :---          |    :----------       |          :---        |
| istio         | Istio-operator-metrics <br /> (istio proxy services as configured by the user in the application namespaces) | Istio-operator <br />(istio proxy deployments as configured by the user in the application namespaces) |

In its own namespace, the TSB Operator creates an `IstioOperator` CR named
`tsb-gateways` and deploys the Istio operator.

By default, the generated `IstioOperator` CR has the `ingressGateway` and
`egressGateway` components enabled. All other Istio components are explicitly
disabled in the CR. This configuration decouples the lifecycle of gateway
upgrades from control plane upgrades.

When users create and deploy `IngressGateway`, `Tier1Gateway`, and
`EgressGateway` CRs across the different namespaces in the cluster, the TSB
operator will translate these resources and update the IstioOperator CR named
`tsb-gateways` in the data plane gateway components namespace. The Istio
operator deployed in this same namespace will then manage the lifecycle of
ingress and egress envoy gateways on behalf of the TSB operator. These envoy
gateways form the ingress and egress to the services hosted in the TSB service
mesh.

